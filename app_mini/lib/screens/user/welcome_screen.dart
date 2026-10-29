//lib/screens/user/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:mini/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/database/backup_service.dart';
import '../../core/database/local_database.dart';
import '../../providers/business_unit_provider.dart';
import '../../providers/user_provider.dart';

/* First screen on a fresh install: lets the user restore an existing backup or start a new account. */
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _backupService = BackupService(LocalDatabase.instance);

  bool _isRestoring = false;

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isRestoring = true);

    try {
      final preview = await _backupService.pickAndInspectBackup();
      if (preview == null || !mounted) return;

      final confirmed = await _confirmRestore(l10n, preview);
      if (confirmed != true) return;

      await _backupService.restoreIntoEmptyDatabase(preview.payload);
      if (!mounted) return;

      /* The restore wrote straight to the database, bypassing the providers, so their in-memory state must be reloaded. */
      await context.read<UserProvider>().loadUser();
      if (!mounted) return;
      await context.read<BusinessUnitProvider>().loadUnits();
      if (!mounted) return;

      _showSnackBar(l10n.restoreFreshSuccessMessage);
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on BackupException catch (error) {
      if (!mounted) return;
      _showSnackBar(_messageFor(error, l10n), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(l10n.restoreFailedMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _messageFor(BackupException error, AppLocalizations l10n) {
    switch (error.code) {
      case BackupErrorCode.invalidFile:
        return l10n.backupErrorInvalidFile;
      case BackupErrorCode.unrecognized:
        return l10n.backupErrorUnrecognized;
      case BackupErrorCode.noUser:
        return l10n.backupErrorNoUser;
      case BackupErrorCode.noStore:
        return l10n.backupErrorNoStore;
      case BackupErrorCode.newerVersion:
        return l10n.backupErrorNewerVersion;
      case BackupErrorCode.integrity:
        return l10n.backupErrorIntegrity;
      case null:
        return error.message;
    }
  }

  Future<bool?> _confirmRestore(AppLocalizations l10n, BackupPreview preview) {
    final generatedAt = preview.generatedAt;
    final dateText = generatedAt == null
        ? '-'
        : MaterialLocalizations.of(context)
            .formatShortDate(generatedAt.toLocal());

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.restorePreviewTitle),
        content: Text(
          l10n.restorePreviewSummary(
            preview.reference,
            dateText,
            preview.userName,
            preview.storeCount,
            preview.saleCount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.restorePreviewConfirmButton),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Image.asset('assets/icone.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.welcomeToMiniTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isRestoring ? null : _handleRestore,
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_outlined),
                  label: Text(l10n.welcomeRestoreButton),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isRestoring
                      ? null
                      : () => Navigator.of(context).pushNamed('/onboarding'),
                  child: Text(l10n.welcomeCreateNewButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}