import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/tokens.dart';
import 'screens/shell.dart';
import 'screens/splash_onboarding.dart';
import 'state/stores.dart';
import 'ui/overlays.dart';

class AgeCalculateApp extends StatefulWidget {
  const AgeCalculateApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<AgeCalculateApp> createState() => _AgeCalculateAppState();
}

class _AgeCalculateAppState extends State<AgeCalculateApp> {
  late final AppState _app = AppState(widget.prefs);

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _app),
        ChangeNotifierProvider(create: (_) => CalcState()),
        ChangeNotifierProvider(create: (_) => ToastController()),
        ChangeNotifierProvider(create: (_) => TabNav()),
        ChangeNotifierProvider(create: (_) => BootState()),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          title: 'Age Calculate',
          debugShowCheckedModeBanner: false,
          themeMode: app.themeMode,
          theme: buildTheme(AcColors.light),
          darkTheme: buildTheme(AcColors.darkTheme),
          scrollBehavior: const AcScrollBehavior(),
          locale: const Locale('en', 'US'),
          supportedLocales: const [Locale('en', 'US')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          builder: (ctx, child) {
            final dark = Theme.of(ctx).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent,
                statusBarIconBrightness: dark ? Brightness.light : Brightness.dark, statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark, systemNavigationBarContrastEnforced: false,
              ),
              child: ToastHost(bottomInset: 92, child: child!),
            );
          },
          home: const AppRoot(),
        ),
      ),
    );
  }
}

/// One scroll feel everywhere: iOS-style rubber-band overscroll (no Android glow), content always draggable,
/// and mouse / trackpad / stylus can drag-scroll too.
class AcScrollBehavior extends MaterialScrollBehavior {
  const AcScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.trackpad};
}

enum _Phase { splash, onboarding, shell }

/// splash → (first launch ? onboarding : home with a brief skeleton). Phases cross-fade in 300 ms.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  _Phase _phase = _Phase.splash;

  void _afterSplash() {
    final app = context.read<AppState>();
    if (!app.onboarded) {
      setState(() => _phase = _Phase.onboarding);
      return;
    }
    _enterShell(skeleton: true);
  }

  void _enterShell({bool skeleton = false}) {
    final boot = context.read<BootState>();
    setState(() => _phase = _Phase.shell);
    if (skeleton) {
      boot.set(true);
      Future<void>.delayed(context.reduceMotion ? const Duration(milliseconds: 250) : const Duration(milliseconds: 700), () => boot.set(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, const Duration(milliseconds: 300)),
      switchInCurve: Motion.out,
      switchOutCurve: Motion.standard,
      // the arriving phase fades up from 97 % so splash → onboarding → home feels like one continuous move
      transitionBuilder: (child, anim) => context.reduceMotion
          ? FadeTransition(opacity: anim, child: child)
          : FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(anim), child: child)),
      child: switch (_phase) {
        _Phase.splash => SplashScreen(key: const ValueKey('splash'), onDone: _afterSplash),
        _Phase.onboarding => OnboardingScreen(
            key: const ValueKey('onboarding'),
            onDone: () {
              context.read<AppState>().completeOnboarding();
              _enterShell();
            },
          ),
        _Phase.shell => const HomeShell(key: ValueKey('shell')),
      },
    );
  }
}
