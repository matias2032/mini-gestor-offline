import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini/l10n/app_localizations.dart';

import '../../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _startLoading();
  }

  Future<void> _startLoading() async {
    final userProvider = context.read<UserProvider>();

    // Carrega os dados do utilizador enquanto a barra anima.
    final loadUserFuture = userProvider.loadUser();

    // Simulação visual de carregamento durando exatamente 5 segundos (50 passos x 100ms = 5000ms).
    const totalSteps = 50;
    const stepDuration = Duration(milliseconds: 100);

    for (var i = 1; i <= totalSteps; i++) {
      await Future.delayed(stepDuration);

      if (!mounted) return;

      setState(() {
        _progress = i / totalSteps;
      });
    }

    // Garante que o carregamento da base de dados foi concluído.
    await loadUserFuture;

    if (!mounted) return;

    if (userProvider.hasUser) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icone.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Mini',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.splashLoading,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '${(_progress * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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