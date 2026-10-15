import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Result of importing/merging a backup, so the UI can show the user what actually happened.
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

/* Machine-readable reason for a backup failure, so the UI can show a localized message instead of the English fallback in
[BackupException.message]. */
enum BackupErrorCode {
  invalidFile,
  unrecognized,
  noUser,
  noStore,
  newerVersion,
  integrity,
}

/// Thrown when a backup file isn't in a shape this app can read, or when merging it would break referential integrity.
class BackupException implements Exception {
  BackupException(this.message, {this.code});
  final String message;
  final BackupErrorCode? code;

  @override
  String toString() => 'BackupException: $message';
}

/* Summary of a validated backup, shown to the user for confirmation before a first-launch restore. Carries the decoded
payload so the file is read only once. */
class BackupPreview {
  const BackupPreview({
    required this.payload,
    required this.reference,
    required this.generatedAt,
    required this.userName,
    required this.storeCount,
    required this.saleCount,
  });

  final Map<String, dynamic> payload;
  final String reference;
  final DateTime? generatedAt;
  final String userName;
  final int storeCount;
  final int saleCount;
}
/*Full-database backup/restore for the offline app.

The backup is a single `.json` file with every row of every table plus a small metadata header (format version, schema version,
generation timestamp, human-readable reference). Since the app is  fully offline, this file is also the only way to move data between
devices or recover from data loss — the user is expected to save it somewhere outside the device (cloud drive, email, USB...) via the
system share sheet.

Table/column introspection is dynamic (`sqlite_master` + `PRAGMA table_info`) instead of hardcoded here, so this service
doesn't need editing every time a future migration adds/removes a table or column.*/
class BackupService {
  BackupService(this._localDatabase);

  final LocalDatabase _localDatabase;

  static const String _formatVersion = '1';

  /// Name of the folder created inside Downloads (or the platform equivalent) the first time a backup is generated.
  static const String _backupFolderName = 'Mini Backups';

  // Export

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
      // Human-readable reference so the user can tell backups apart at a glance, in a file explorer or when picking which one to restore.
      'backup_reference': _buildReference(generatedAt),
      'tables': tables,
    };
  }

  /* Writes the backup to `Downloads/$_backupFolderName` (or the platform equivalent), creating the folder the first time. The file
  name is based on the date alone — a backup generated on the same day automatically replaces the previous one, so files don't pile
  up. The full reference (with time) is kept inside the JSON itself, in `backup_reference`, for precise identification of the content.*/

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

  /// Resolves (and creates, if needed) the folder where backups are written, depending on the platform.
  Future<Directory> _resolveBackupDirectory() async {
    if (kIsWeb) {
      throw BackupException(
        'File backup is not supported on the web version.',
      );
    }

    if (Platform.isAndroid) {
      return _resolveAndroidDownloadsDirectory();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloads = await getDownloadsDirectory();
      if (downloads == null) {
        throw BackupException('Could not locate the Downloads folder.');
      }
      return _ensureSubfolder(downloads);
    }

    // iOS and other platforms without a public "Downloads" folder accessible to the app: use the app's own storage instead.
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
        'Storage permission denied. The backup cannot be saved to '
        'Downloads without this permission.',
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

  /// Opens the system share sheet so the user can send the backup wherever they want to keep it (Drive, email, WhatsApp, USB...).
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


  // Import/ Merge

  /// Lets the user pick a backup `.json` file and returns the already validated content, or `null` if they cancel.
  
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
        'The selected file is not a valid JSON backup.',
        code: BackupErrorCode.invalidFile,
      );
    }
    if (decoded['backup_format_version'] != _formatVersion ||
        decoded['tables'] is! Map) {
      throw BackupException(
        'This file is not a recognized backup.',
        code: BackupErrorCode.unrecognized,
      );
    }
    return decoded;
  }

  /* Merges [backupPayload] into the current database: for each row, the most recent version wins — whether it already exists in the
  app or comes from the backup — by comparing `updated_at` (or `created_at` as a fallback, on tables without `updated_at`). Rows
  that only exist in the backup are inserted; rows that only exist locally are left untouched (the merge never deletes local data).*/

  Future<BackupMergeResult> mergeBackup(
    Map<String, dynamic> backupPayload,
  ) async {
    final tablesJson = backupPayload['tables'] as Map<String, dynamic>;
    final db = await _localDatabase.database;

    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    await db.transaction((txn) async {
      /* Disable FK checks while rows are inserted in arbitrary order (the backup may list tables out of dependency order); validate
      everything at once at the end.*/
      await txn.execute('PRAGMA foreign_keys = OFF');

      final knownTables = await _userTableNames(txn);

      for (final tableName in tablesJson.keys) {
        if (!knownTables.contains(tableName)) {
          // Backup from an app version with a table that no longer (or doesn't yet) exist here — skip it instead of failing the whole restore.

          continue;
        }

        final pkColumn = await _primaryKeyColumn(txn, tableName);
        if (pkColumn == null) continue; // no reliable PK to merge on

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
              ? false // no timestamp to compare -> keep the local row
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
          'Merging this backup would violate data integrity. '
          'No changes were applied.',
          code: BackupErrorCode.integrity,
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

  /* `true` when [backupValue] is more recent than [localValue]. Missing/unreadable values are treated cautiously — local data is
  never overwritten with something that can't be compared.*/
  bool _isNewer(String? backupValue, String? localValue) {
    if (backupValue == null) return false;
    final backupTime = DateTime.tryParse(backupValue);
    if (backupTime == null) return false;
    if (localValue == null) return true;
    final localTime = DateTime.tryParse(localValue);
    if (localTime == null) return true;
    return backupTime.isAfter(localTime);
  }


  // First-launch restore

  /* Picks a backup file and validates it for a first-launch restore. Returns `null` if the user cancels the picker. */
  Future<BackupPreview?> pickAndInspectBackup() async {
    final payload = await pickBackupFile();
    if (payload == null) return null;
    return inspectBackup(payload);
  }

  /* Checks that [payload] can bring up a working installation on its own: it must carry the single user row (with a password
  hash, otherwise nobody could log in) and at least one active store, and must not come from a newer schema than this app. */
  BackupPreview inspectBackup(Map<String, dynamic> payload) {
    final backupSchema = payload['app_schema_version'];
    if (backupSchema is int && backupSchema > _localDatabase.schemaVersion) {
      throw BackupException(
        'This backup was created by a newer version of the app.',
        code: BackupErrorCode.newerVersion,
      );
    }

    final tables = payload['tables'] as Map<String, dynamic>;

    final users = _rowsOf(tables, 'user');
    final hasValidUser = users.length == 1 &&
        users.first['id_user'] == 1 &&
        (users.first['password_hash'] as String?)?.isNotEmpty == true;
    if (!hasValidUser) {
      throw BackupException(
        'This backup has no usable account data.',
        code: BackupErrorCode.noUser,
      );
    }

    final activeStores =
        _rowsOf(tables, 'business_unit').where((r) => r['deleted'] == 0);
    if (activeStores.isEmpty) {
      throw BackupException(
        'This backup has no active stores.',
        code: BackupErrorCode.noStore,
      );
    }

    return BackupPreview(
      payload: payload,
      reference: (payload['backup_reference'] as String?) ?? '-',
      generatedAt: DateTime.tryParse(payload['generated_at'] as String? ?? ''),
      userName: users.first['name'] as String,
      storeCount: activeStores.length,
      saleCount: _rowsOf(tables, 'sale').length,
    );
  }

  /* Loads [payload] into an empty database. Unlike [mergeBackup] there is nothing to compare: every row is inserted as-is, in
  schema order so foreign keys are satisfied as rows go in. All-or-nothing: any failure rolls the transaction back and leaves
  the database empty. */
  Future<void> restoreIntoEmptyDatabase(Map<String, dynamic> payload) async {
    final tablesJson = payload['tables'] as Map<String, dynamic>;
    final db = await _localDatabase.database;

    await db.transaction((txn) async {
      final existingUsers =
          Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM user'));
      if ((existingUsers ?? 0) > 0) {
        throw StateError('Cannot restore into a database that already has data.');
      }

      for (final tableName in await _userTableNames(txn)) {
        for (final row in _rowsOf(tablesJson, tableName)) {
          await txn.insert(tableName, row);
        }
      }

      final fkViolations = await txn.rawQuery('PRAGMA foreign_key_check');
      if (fkViolations.isNotEmpty) {
        throw BackupException(
          'The backup data is inconsistent. Nothing was restored.',
          code: BackupErrorCode.integrity,
        );
      }
    });
  }

  List<Map<String, dynamic>> _rowsOf(Map<String, dynamic> tables, String name) {
    final raw = tables[name];
    return raw is List ? raw.cast<Map<String, dynamic>>() : const [];
  }

  // Schema Inspection Helpers

  Future<List<String>> _userTableNames(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' "
      "AND name NOT LIKE 'android_metadata' "
      'ORDER BY rowid',
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

  /* Prefers `updated_at`; falls back to `created_at` on tables that don't distinguish edits from creation (e.g. `sale_payment`, which
  is an immutable event record).*/
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