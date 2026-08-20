// lib/screens/settings/backup_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/backup_service.dart';
import '../../core/database/local_database.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Tela de backup/restauro — acessível via sidebar. Não depende de
/// nenhum Provider: o BackupService não tem estado entre chamadas, só
/// lê/escreve a base de dados diretamente quando acionado.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService(LocalDatabase.instance);

  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  bool _isSharing = false;

  /// Último backup criado nesta sessão. A partilha é uma ação totalmente
  /// à parte da criação — só fica disponível depois de existir um
  /// ficheiro para partilhar, e nunca é acionada automaticamente.
  File? _lastBackupFile;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(loc.backupRestoreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            colorScheme: colorScheme,
            icon: Icons.backup_outlined,
            title: loc.backupSectionTitle,
            description: loc.backupSectionDescription,
            button: FilledButton.icon(
              onPressed: _isCreatingBackup ? null : _handleCreateBackup,
              icon: _isCreatingBackup
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_outlined),
              label: Text(loc.createBackupButton),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            colorScheme: colorScheme,
            icon: Icons.ios_share_outlined,
            title: loc.shareSectionTitle,
            description: _lastBackupFile == null
                ? loc.shareSectionDescriptionEmpty
                : loc.shareSectionDescriptionReady(
                    _lastBackupFile!.uri.pathSegments.last,
                  ),
            button: OutlinedButton.icon(
              onPressed: (_lastBackupFile == null || _isSharing)
                  ? null
                  : _handleShareBackup,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              label: Text(loc.shareBackupButton),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            colorScheme: colorScheme,
            icon: Icons.restore_outlined,
            title: loc.restoreSectionTitle,
            description: loc.restoreSectionDescription,
            button: OutlinedButton.icon(
              onPressed: _isRestoring ? null : _handleRestoreBackup,
              icon: _isRestoring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_open_outlined),
              label: Text(loc.restoreBackupButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String description,
    required Widget button,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: button),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Criar backup
  // -------------------------------------------------------------------

  Future<void> _handleCreateBackup() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _isCreatingBackup = true);
    try {
      final file = await _backupService.exportToFile();
      if (!mounted) return;
      setState(() => _lastBackupFile = file);
      _showSnackBar(loc.backupCreatedMessage(file.path));
    } on BackupException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(loc.backupFailedMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  // -------------------------------------------------------------------
  // Partilhar backup (opcional, totalmente à parte da criação)
  // -------------------------------------------------------------------

  Future<void> _handleShareBackup() async {
    final loc = AppLocalizations.of(context)!;
    final file = _lastBackupFile;
    if (file == null) return;

    setState(() => _isSharing = true);
    try {
      await _backupService.shareBackupFile(file);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(loc.shareFailedMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // -------------------------------------------------------------------
  // Restaurar backup
  // -------------------------------------------------------------------

  Future<void> _handleRestoreBackup() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await _confirmRestore(loc);
    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final payload = await _backupService.pickBackupFile();
      if (payload == null) {
        // Utilizador cancelou o seletor de ficheiros — nada a fazer.
        return;
      }

      final result = await _backupService.mergeBackup(payload);
      if (!mounted) return;
      _showSnackBar(
        loc.restoreSuccessMessage(
          result.insertedRows,
          result.updatedRows,
          result.skippedRows,
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(loc.restoreFailedMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<bool?> _confirmRestore(AppLocalizations loc) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.restoreConfirmTitle)),
          ],
        ),
        content: Text(loc.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.restoreConfirmButton),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}