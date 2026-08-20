//lib/core/database/backup_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/local_database.dart';

/// Result of importing/merging a backup, so the UI can show the user
/// what actually happened.
class BackupMergeResult {
  const BackupMergeResult({
    required this.insertedRows,
    required this.updatedRows,
    required this.skippedRows,
  });

  final int insertedRows;
  final int updatedRows;
  final int skippedRows;

  int get totalRowsProcessed => insertedRows + updatedRows + skippedRows;
}

/// Thrown when a backup file isn't in a shape this app can read, or when
/// merging it would break referential integrity.
class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// Full-database backup/restore for the offline app.
///
/// The backup is a single `.json` file with every row of every table
/// plus a small metadata header (format version, schema version,
/// generation timestamp, human-readable reference). Since the app is
/// fully offline, this file is also the only way to move data between
/// devices or recover from data loss — the user is expected to save it
/// somewhere outside the device (cloud drive, email, USB...) via the
/// system share sheet.
///
/// Table/column introspection is dynamic (`sqlite_master` +
/// `PRAGMA table_info`) instead of hardcoded here, so this service
/// doesn't need editing every time a future migration adds/removes a
/// table or column.
class BackupService {
  BackupService(this._localDatabase);

  final LocalDatabase _localDatabase;

  static const String _formatVersion = '1';

  /// Nome da pasta criada dentro de Downloads (ou equivalente, consoante
  /// a plataforma) na primeira vez que um backup é gerado.
  static const String _backupFolderName = 'Mini Backups';

  // ============================================================
  // EXPORT
  // ============================================================

  /// Builds the backup payload as a plain Dart map (JSON-serializable).
  Future<Map<String, dynamic>> buildBackupPayload() async {
    final db = await _localDatabase.database;
    final tableNames = await _userTableNames(db);

    final tables = <String, dynamic>{};
    for (final table in tableNames) {
      tables[table] = await db.query(table);
    }

    final generatedAt = DateTime.now().toUtc();
    return {
      'backup_format_version': _formatVersion,
      'app_schema_version': _localDatabase.schemaVersion,
      'generated_at': generatedAt.toIso8601String(),
      // Referência legível para o utilizador distinguir backups a olho
      // nu, num explorador de ficheiros ou ao escolher qual restaurar.
      'backup_reference': _buildReference(generatedAt),
      'tables': tables,
    };
  }

  /// Grava o backup em `Downloads/$_backupFolderName` (ou equivalente na
  /// plataforma), criando a pasta na primeira vez. O nome do ficheiro é
  /// baseado apenas na data — um backup gerado no mesmo dia substitui o
  /// anterior automaticamente, sem acumular ficheiros. A referência
  /// completa (com hora) fica guardada dentro do próprio JSON, em
  /// `backup_reference`, para identificação precisa do conteúdo.
  Future<File> exportToFile() async {
    final payload = await buildBackupPayload();
    final dir = await _resolveBackupDirectory();
    final fileName = 'mini_backup_${_dayStamp(DateTime.now())}.json';
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file;
  }

  String _dayStamp(DateTime date) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${pad(date.month)}-${pad(date.day)}';
  }

  /// Resolve (e cria, se necessário) a pasta onde os backups são
  /// gravados, consoante a plataforma.
  Future<Directory> _resolveBackupDirectory() async {
    if (kIsWeb) {
      throw BackupException(
        'Backup em ficheiro não é suportado na versão web.',
      );
    }

    if (Platform.isAndroid) {
      return _resolveAndroidDownloadsDirectory();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloads = await getDownloadsDirectory();
      if (downloads == null) {
        throw BackupException('Não foi possível localizar a pasta Downloads.');
      }
      return _ensureSubfolder(downloads);
    }

    // iOS e outras plataformas sem uma pasta "Downloads" pública
    // acessível à app: usa o armazenamento próprio da app.
    final appDir = await getApplicationDocumentsDirectory();
    return _ensureSubfolder(appDir);
  }

  Future<Directory> _resolveAndroidDownloadsDirectory() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    if (!status.isGranted) {
      throw BackupException(
        'Permissão de armazenamento negada. Não é possível guardar o '
        'backup em Downloads sem esta permissão.',
      );
    }

    final dir = Directory('/storage/emulated/0/Download/$_backupFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _ensureSubfolder(Directory parent) async {
    final dir = Directory(
      '${parent.path}${Platform.pathSeparator}$_backupFolderName',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Abre o menu de partilha do sistema para o utilizador enviar o
  /// backup para onde quiser guardá-lo (Drive, email, WhatsApp, USB...).
  Future<void> shareBackupFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Backup — ${file.uri.pathSegments.last}',
    );
  }

  String _buildReference(DateTime utc) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return 'BKP-${utc.year}${pad(utc.month)}${pad(utc.day)}-'
        '${pad(utc.hour)}${pad(utc.minute)}${pad(utc.second)}';
  }

  // ============================================================
  // IMPORT / MERGE
  // ============================================================

  /// Deixa o utilizador escolher um ficheiro `.json` de backup e
  /// devolve o conteúdo já validado, ou `null` se cancelar.
  Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final raw = await File(path).readAsString();
    return _decodeAndValidate(raw);
  }

  Map<String, dynamic> _decodeAndValidate(String raw) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException(
        'O ficheiro selecionado não é um backup JSON válido.',
      );
    }
    if (decoded['backup_format_version'] != _formatVersion ||
        decoded['tables'] is! Map) {
      throw BackupException('Este ficheiro não é um backup reconhecido.');
    }
    return decoded;
  }

  /// Faz o merge de [backupPayload] na base de dados atual: para cada
  /// linha, ganha a versão mais recente — quer já exista na app, quer
  /// venha do backup — comparando `updated_at` (ou `created_at` como
  /// fallback, nas tabelas sem `updated_at`). Linhas que só existem no
  /// backup são inseridas; linhas que só existem localmente ficam como
  /// estão (o merge nunca apaga dados locais).
  Future<BackupMergeResult> mergeBackup(
    Map<String, dynamic> backupPayload,
  ) async {
    final tablesJson = backupPayload['tables'] as Map<String, dynamic>;
    final db = await _localDatabase.database;

    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    await db.transaction((txn) async {
      // Mesma abordagem já usada nas migrações da LocalDatabase:
      // desliga a verificação de FKs enquanto as linhas entram por
      // ordem arbitrária, e valida tudo de uma vez no fim.
      await txn.execute('PRAGMA foreign_keys = OFF');

      final knownTables = await _userTableNames(txn);

      for (final tableName in tablesJson.keys) {
        if (!knownTables.contains(tableName)) {
          // Backup de uma versão da app com uma tabela que já não
          // existe (ou ainda não existe) aqui — ignora em vez de
          // falhar a restauração toda.
          continue;
        }

        final pkColumn = await _primaryKeyColumn(txn, tableName);
        if (pkColumn == null) continue; // sem PK fiável para merge

        final timestampColumn = await _mergeTimestampColumn(txn, tableName);
        final rows =
            (tablesJson[tableName] as List).cast<Map<String, dynamic>>();

        for (final backupRow in rows) {
          final pkValue = backupRow[pkColumn];
          if (pkValue == null) {
            skipped++;
            continue;
          }

          final existing = await txn.query(
            tableName,
            where: '$pkColumn = ?',
            whereArgs: [pkValue],
            limit: 1,
          );

          if (existing.isEmpty) {
            await txn.insert(
              tableName,
              backupRow,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            inserted++;
            continue;
          }

          final isBackupNewer = timestampColumn == null
              ? false // sem timestamp para comparar -> mantém o local
              : _isNewer(
                  backupRow[timestampColumn] as String?,
                  existing.first[timestampColumn] as String?,
                );

          if (isBackupNewer) {
            await txn.update(
              tableName,
              backupRow,
              where: '$pkColumn = ?',
              whereArgs: [pkValue],
            );
            updated++;
          } else {
            skipped++;
          }
        }
      }

      final fkViolations = await txn.rawQuery('PRAGMA foreign_key_check');
      if (fkViolations.isNotEmpty) {
        throw BackupException(
          'A fusão do backup violaria a integridade dos dados. '
          'Nenhuma alteração foi aplicada.',
        );
      }

      await txn.execute('PRAGMA foreign_keys = ON');
    });

    return BackupMergeResult(
      insertedRows: inserted,
      updatedRows: updated,
      skippedRows: skipped,
    );
  }

  /// `true` quando [backupValue] é mais recente que [localValue].
  /// Valores em falta/ilegíveis são tratados com cautela — nunca
  /// sobrescreve dados locais com algo que não se consegue comparar.
  bool _isNewer(String? backupValue, String? localValue) {
    if (backupValue == null) return false;
    final backupTime = DateTime.tryParse(backupValue);
    if (backupTime == null) return false;
    if (localValue == null) return true;
    final localTime = DateTime.tryParse(localValue);
    if (localTime == null) return true;
    return backupTime.isAfter(localTime);
  }

  // ============================================================
  // SCHEMA INTROSPECTION HELPERS
  // ============================================================

  Future<List<String>> _userTableNames(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' "
      "AND name NOT LIKE 'android_metadata'",
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<String?> _primaryKeyColumn(DatabaseExecutor db, String table) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    for (final column in columns) {
      if ((column['pk'] as int? ?? 0) == 1) {
        return column['name'] as String;
      }
    }
    return null;
  }

  /// Prefere `updated_at`; recorre a `created_at` nas tabelas que não
  /// distinguem edição de criação (ex.: `sale_payment`, que é um
  /// registo de evento imutável).
  Future<String?> _mergeTimestampColumn(
    DatabaseExecutor db,
    String table,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final names = columns.map((c) => c['name'] as String).toSet();
    if (names.contains('updated_at')) return 'updated_at';
    if (names.contains('created_at')) return 'created_at';
    return null;
  }
}