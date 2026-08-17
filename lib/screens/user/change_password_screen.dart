import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Lets the user change their password, verifying the current one first.
/// On success, forces an automatic logout — the user must log back in
/// with the new password immediately.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<UserProvider>().changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    if (!success) {
      final error = context.read<UserProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? AppLocalizations.of(context)!.couldNotChangePassword),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.passwordChanged)),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.changePasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.confirmCurrentPasswordPrompt,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.currentPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppLocalizations.of(context)!.currentPasswordRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.newPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.newPasswordRequired;
                    }
                    if (value.length < 6) {
                      return AppLocalizations.of(context)!.newPasswordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.confirmNewPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return AppLocalizations.of(context)!.passwordsDoNotMatchDot;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.changePasswordButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}