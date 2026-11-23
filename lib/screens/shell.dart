import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import '../ui/icons.dart';
import '../ui/neu.dart';
import 'compare_screen.dart';
import 'history_screen.dart';
import 'hitung_screen.dart';
import 'settings_screen.dart';

const _tabs = [('home', 'Calculate'), ('users', 'Difference'), ('clock', 'History'), ('sliders', 'Settings')];

/// Four tabs with a floating neumorphic tab bar. Switching cross-fades the content (200 ms); the active tab is a pressed-in pill.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: Motion.base, value: 1);
  late final Animation<double> _fadeCurve = CurvedAnimation(parent: _fade, curve: Motion.standard);
  int _last = 0;
  double _dir = 1; // +1 = moved to a tab on the right, -1 = left

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<TabNav>();
    final tab = nav.index;
    if (tab != _last) {
      _dir = tab > _last ? 1 : -1;
      _last = tab;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fade.forward(from: 0);
        });
      }
    }
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 12.0) + 4;

    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.go(0);
      },
      child: Scaffold(
        backgroundColor: context.ac.surface,
        body: Stack(
          children: [
            // cross-fade plus a 14 px drift in the direction of travel (spatial consistency with the tab bar)
            FadeTransition(
              opacity: _fadeCurve,
              child: AnimatedBuilder(
                animation: _fadeCurve,
                child: IndexedStack(index: tab, children: const [HitungScreen(), CompareScreen(), HistoryScreen(), SettingsScreen()]),
                builder: (_, child) => Transform.translate(offset: Offset(_dir * 14 * (1 - _fadeCurve.value), 0), child: child),
              ),
            ),
            Positioned(left: 16, right: 16, bottom: bottom, child: _AcTabBar(index: tab, onTap: nav.go)),
          ],
        ),
      ),
    );
  }
}

class _AcTabBar extends StatelessWidget {
  const _AcTabBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Semantics(
      container: true, label: 'Main navigation',
      child: Neu(
        radius: 30, raised: Elev.base, height: 72, padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Stack(
          children: [
            // the active "pressed-in" pill glides to the chosen tab (200 ms, standard curve)
            Positioned.fill(
              child: AnimatedAlign(
                duration: Motion.of(context, Motion.base), curve: Motion.standard,
                alignment: Alignment(-1 + 2 * index / (_tabs.length - 1), 0),
                child: FractionallySizedBox(widthFactor: 1 / _tabs.length, child: const Neu(radius: 22, inset: Elev.iMd, height: 54)),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true, selected: i == index, label: _tabs[i].$2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i != index) haptic(Haptic.selection);
                          onTap(i);
                        },
                        child: SizedBox(
                          height: 72,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSlide(
                                  offset: i == index ? const Offset(0, -0.04) : Offset.zero, duration: Motion.of(context, Motion.base), curve: Motion.out,
                                  child: AnimatedScale(
                                    scale: i == index ? 1.14 : 1, duration: Motion.of(context, Motion.base), curve: Motion.spring,
                                    child: AcIcon(_tabs[i].$1, size: 24, color: i == index ? c.accent : c.ink3),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: Motion.of(context, Motion.base), curve: Motion.out,
                                  style: Tx.label(11, Tx.w7, i == index ? c.accentStrong : c.ink3),
                                  child: Text(_tabs[i].$2, maxLines: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
