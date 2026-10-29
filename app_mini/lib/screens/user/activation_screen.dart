import 'package:flutter/material.dart';
import 'package:mini/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/license/license_service.dart';
import '../../providers/user_provider.dart';

/* Shown while the device has no valid license. */
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _licenseService = LicenseService();
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isActivating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    try {
      await _licenseService.activate(_codeController.text);
      if (!mounted) return;

      final hasUser = context.read<UserProvider>().hasUser;
      Navigator.of(context).pushNamedAndRemoveUntil(
        hasUser ? '/login' : '/welcome',
        (_) => false,
      );
    } on LicenseException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error.code, l10n));
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  String _messageFor(LicenseErrorCode code, AppLocalizations l10n) {
    switch (code) {
      case LicenseErrorCode.invalidCode:
        return l10n.activationErrorInvalidCode;
      case LicenseErrorCode.alreadyUsed:
        return l10n.activationErrorAlreadyUsed;
      case LicenseErrorCode.revoked:
        return l10n.activationErrorRevoked;
      case LicenseErrorCode.rateLimited:
        return l10n.activationErrorRateLimited;
      case LicenseErrorCode.network:
        return l10n.activationErrorNetwork;
      case LicenseErrorCode.deviceUnavailable:
        return l10n.activationErrorDevice;
      case LicenseErrorCode.invalidResponse:
        return l10n.activationErrorGeneric;
    }
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
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.asset('assets/icone.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.activationTitle,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.activationSubtitle,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _codeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.activationCodeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.activationCodeRequired
                      : null,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isActivating ? null : _submit,
                    child: _isActivating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.activationButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}