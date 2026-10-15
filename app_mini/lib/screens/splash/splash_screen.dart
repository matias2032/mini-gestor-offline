import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini/l10n/app_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/business_unit_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/license/license_service.dart';

/* Persists where the user was, so the app can resume there after the OS
kills the process while it is in the background. */
class ResumeState {
  /* Within this window after leaving the app, it resumes directly on the last
  screen. After it, the user goes through login as usual. */
  static const Duration resumeWindow = Duration(minutes: 5);

  static const _routeKey = 'resume_last_route';
  static const _pausedAtKey = 'resume_paused_at';

  static Future<void> saveRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routeKey, route);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_routeKey);
    await prefs.remove(_pausedAtKey);
  }

  static Future<void> markPaused() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pausedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  /* Returns the route to resume, or null when the app must start normally. */
  static Future<String?> routeToResume() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_routeKey);
    final pausedAt = prefs.getInt(_pausedAtKey);
    if (route == null || pausedAt == null) return null;
    final elapsed = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(pausedAt));
    return elapsed <= resumeWindow ? route : null;
  }
}

/* Records the last named route. Login and onboarding clear the saved route,
so logging out can never be bypassed by a resume. */
class ResumeRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _track(previousRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    // Unnamed routes (dialogs, detail screens) are ignored; '/' is the splash itself.
    if (name == null || name == '/') return;
    if (name == '/login' ||
        name == '/onboarding' ||
        name == '/welcome' ||
        name == '/activate') {
      ResumeState.clear();
    } else {
      ResumeState.saveRoute(name);
    }
  }
}

/* Stamps the moment the app leaves the foreground. */
class ResumeLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) ResumeState.markPaused();
  }
}


/* Picks which "convoy" of 4 tips the splash shows on this launch. Never
repeats the convoy shown on the previous launch. Tip texts live in the .arb
files (splashTip1..splashTip24); convoy N uses tips 4N+1 .. 4N+4. */
class SplashTips {
  static const int convoyCount = 6;
  static const int tipsPerConvoy = 4;
  static const _lastConvoyKey = 'splash_last_convoy';

  static Future<int> pickConvoy() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastConvoyKey);
    final random = Random();

    var next = random.nextInt(convoyCount);
    if (next == last) {
      // Jumps 1..5 positions ahead, so it can never land on `last` again.
      next = (next + 1 + random.nextInt(convoyCount - 1)) % convoyCount;
    }

    await prefs.setInt(_lastConvoyKey, next);
    return next;
  }

  static List<String> tipsFor(int convoy, AppLocalizations l10n) {
    final all = [
      l10n.splashTip1, l10n.splashTip2, l10n.splashTip3, l10n.splashTip4,
      l10n.splashTip5, l10n.splashTip6, l10n.splashTip7, l10n.splashTip8,
      l10n.splashTip9, l10n.splashTip10, l10n.splashTip11, l10n.splashTip12,
      l10n.splashTip13, l10n.splashTip14, l10n.splashTip15, l10n.splashTip16,
      l10n.splashTip17, l10n.splashTip18, l10n.splashTip19, l10n.splashTip20,
      l10n.splashTip21, l10n.splashTip22, l10n.splashTip23, l10n.splashTip24,
    ];
    final start = convoy * tipsPerConvoy;
    return all.sublist(start, start + tipsPerConvoy);
  }
}

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
  int? _convoy;

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

    _loadConvoy();
    _startLoading();
  }

  Future<void> _loadConvoy() async {
    final convoy = await SplashTips.pickConvoy();
    if (!mounted) return;
    setState(() => _convoy = convoy);
  }

  Future<void> _startLoading() async {
    final userProvider = context.read<UserProvider>();
    final businessUnitProvider = context.read<BusinessUnitProvider>();

    // Fetch user details concurrently while running the progress indicator animation.
    final loadUserFuture = userProvider.loadUser();

    // Decided first: a resume start skips the simulated progress below.
    final resumeRoute = await ResumeState.routeToResume();

    if (resumeRoute == null) {
      // Simulated loading progress running across 5 seconds (50 steps * 100ms).
      const totalSteps = 50;
      const stepDuration = Duration(milliseconds: 100);

      for (var i = 1; i <= totalSteps; i++) {
        await Future.delayed(stepDuration);

        if (!mounted) return;

        setState(() {
          _progress = i / totalSteps;
        });
      }
    }

    // Await completion of database initialization before navigation.
    await loadUserFuture;

    if (!mounted) return;

    final isLicensed = await LicenseService().hasValidLicense();
    if (!mounted) return;

    if (!isLicensed) {
      Navigator.of(context).pushReplacementNamed('/activate');
      return;
    }

    if (!userProvider.hasUser) {
      Navigator.of(context).pushReplacementNamed('/welcome');
      return;
    }

    if (resumeRoute != null) {
      // Stores must be loaded before the restored screen queries its data.
      await businessUnitProvider.loadUnits();
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacementNamed(resumeRoute ?? '/login');
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

    // Until the convoy is picked (a few ms), fall back to the generic text.
    final convoy = _convoy;
    final String message;
    if (convoy == null) {
      message = l10n.splashLoading;
    } else {
      final tips = SplashTips.tipsFor(convoy, l10n);
      final tipIndex = (_progress * SplashTips.tipsPerConvoy)
          .floor()
          .clamp(0, SplashTips.tipsPerConvoy - 1);
      message = tips[tipIndex];
    }

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

                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      message,
                      key: ValueKey(message),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      _SplashProgressBar(progress: _progress),

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


/* Animated progress bar for the splash: eased fill, theme gradient, a sweeping
highlight and a glowing knob at the leading edge. */
class _SplashProgressBar extends StatefulWidget {
  const _SplashProgressBar({required this.progress});

  final double progress;

  @override
  State<_SplashProgressBar> createState() => _SplashProgressBarState();
}

class _SplashProgressBarState extends State<_SplashProgressBar>
    with SingleTickerProviderStateMixin {
  static const double _barHeight = 10;
  static const double _knobSize = 22;
  static const double _shineWidth = 60;

  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.progress),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final fillWidth = trackWidth * value;
            final knobLeft =
                (fillWidth - _knobSize / 2).clamp(0.0, trackWidth - _knobSize);

            return SizedBox(
              height: _knobSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Container(
                    height: _barHeight,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  // Gradient fill with the sweeping highlight
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: fillWidth,
                      height: _barHeight,
                      child: Stack(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.tertiary,
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                          AnimatedBuilder(
                            animation: _shineController,
                            builder: (context, _) {
                              final sweep = (fillWidth + _shineWidth) *
                                      _shineController.value -
                                  _shineWidth;
                              return Positioned(
                                left: sweep,
                                top: 0,
                                bottom: 0,
                                width: _shineWidth,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.4),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Knob at the leading edge
                  Positioned(
                    left: knobLeft,
                    child: Container(
                      width: _knobSize,
                      height: _knobSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}