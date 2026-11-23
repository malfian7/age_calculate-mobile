import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/age.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import '../ui/icons.dart';
import '../ui/neu.dart';
import '../ui/overlays.dart';
import '../ui/widgets.dart';
import 'result_screen.dart';

/// Opens the full result for a saved person.
void openEntry(BuildContext context, HistoryEntry e) {
  final r = computeAge(e.birth, YMD.today());
  Navigator.of(context).push(AcPageRoute<void>(builder: (_) => ResultScreen(result: r, name: e.name)));
}

/// Tab 1 — "Calculate" (Figma "PM / 02 Calculator").
class HitungScreen extends StatefulWidget {
  const HitungScreen({super.key});
  @override
  State<HitungScreen> createState() => _HitungScreenState();
}

class _HitungScreenState extends State<HitungScreen> with SingleTickerProviderStateMixin {
  // error shake: ±8 px, three swings, 240 ms, once per failed attempt
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  double get _dx {
    final t = _shake.value;
    if (t == 0 || t == 1) return 0;
    const pts = [0.0, -8.0, 8.0, -6.0, 6.0, -3.0, 0.0];
    final x = t * (pts.length - 1);
    final i = x.floor().clamp(0, pts.length - 2).toInt();
    return pts[i] + (pts[i + 1] - pts[i]) * (x - i);
  }

  Future<void> _calculate() async {
    final calc = context.read<CalcState>();
    final nav = Navigator.of(context);
    final res = await calc.calculate();
    if (!mounted) return;
    if (res == null) {
      HapticFeedback.heavyImpact();
      if (!context.reduceMotion) _shake.forward(from: 0);
      return;
    }
    nav.push(AcPageRoute<void>(builder: (_) => ResultScreen(result: res)));
  }

  void _openBirthdays() {
    final app = context.read<AppState>();
    final today = YMD.today();
    final list = [for (final e in app.history) (e, nextBirthday(e.birth, today))]..sort((a, b) => a.$2.daysToNext.compareTo(b.$2.daysToNext));
    showAcSheet<void>(context, builder: (ctx) {
      final c = ctx.ac;
      return AcSheetFrame(
        title: 'Upcoming birthdays',
        child: list.isEmpty
            ? Text('No history yet. Save a calculation to see their birthday here.', style: Tx.bodyS(c.ink2))
            : Column(children: [
                if (!app.reminders)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Reminders are turned off in Settings. You can still view this list.', style: Tx.bodyS(c.ink2))),
                for (final (e, n) in list.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      const Well(icon: 'gift', size: 42, iconSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.name, style: Tx.label(15, Tx.w8, c.ink)),
                          Text('${formatMedium(n.date)} · ${ordinal(n.age)}', style: Tx.label(12, Tx.w6, c.ink2)),
                        ]),
                      ),
                      Tag(n.isToday ? 'Today' : '${fmtInt(n.daysToNext)} ${pluralize(n.daysToNext, 'day')}', accent: n.daysToNext <= 7),
                    ]),
                  ),
              ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final calc = context.watch<CalcState>();
    final app = context.watch<AppState>();
    final boot = context.watch<BootState>();
    final today = YMD.today();

    if (boot.skeleton) return const _HitungSkeleton();

    final soon = app.reminders && app.history.any((e) => nextBirthday(e.birth, today).daysToNext <= 7);
    final err = calc.error;
    final recents = app.history.take(3).toList();
    final errorField = switch (err?.field) {
      AgeErrorField.day => DateField.day,
      AgeErrorField.month => DateField.month,
      AgeErrorField.year => DateField.year,
      _ => null,
    };

    return ListView(
      padding: tabScreenPadding(context),
      children: [
        Stagger(
          index: 0,
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Age Calculate', style: Tx.label(13, Tx.w6, c.ink2)),
                  Semantics(header: true, child: Text('Calculate age', style: Tx.h2(c.ink))),
                ]),
              ),
              NeuIconButton(icon: 'bell', label: soon ? 'Upcoming birthdays, one within 7 days' : 'Upcoming birthdays', size: 44, dot: soon, onPressed: _openBirthdays),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Stagger(
          index: 1,
          child: NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Date of birth'),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(offset: Offset(_dx, 0), child: child),
                  child: DateRow(label: 'Date of birth', value: calc.birth, maxYear: today.y, onPick: calc.setBirth, errorField: errorField),
                ),
                const SizedBox(height: 14),
                const SectionLabel('Calculate age on'),
                const SizedBox(height: 8),
                DateRow(label: 'Calculate age on', value: calc.ref, disabled: calc.useToday, onPick: calc.setRef),
                const SizedBox(height: 14),
                Row(children: [
                  NeuToggle(value: calc.useToday, onChanged: calc.loading ? null : calc.setUseToday, label: "Use today's date"),
                  const SizedBox(width: 8),
                  Expanded(child: Text(calc.useToday ? "Use today's date · ${formatMedium(today)}" : "Use today's date", style: Tx.label(13, Tx.w6, c.ink2))),
                ]),
                AnimatedSize(
                  duration: Motion.of(context, Motion.base), curve: Motion.out, alignment: Alignment.topCenter,
                  child: err == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Padding(padding: const EdgeInsets.only(top: 1), child: AcIcon('info', size: 16, color: c.err)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(err.message, style: Tx.label(12, Tx.w6, c.err))),
                            ]),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                NeuButton(label: 'Calculate Age', icon: 'zap', size: BtnSize.lg, block: true, loading: calc.loading, onPressed: _calculate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Stagger(
          index: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recently calculated', style: Tx.h4(c.ink).copyWith(fontSize: 16)),
              NeuPressable(
                radius: 12, minSize: 44, label: 'See all history', haptic: Haptic.selection, onTap: () => context.read<TabNav>().go(2),
                builder: (_, t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('See all', style: Tx.label(13, Tx.w7, c.accent))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (recents.isEmpty)
          Stagger(index: 3, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No saved calculations yet. Calculate an age, then choose Save.', style: Tx.bodyS(c.ink2))))
        else
          for (final (i, e) in recents.indexed)
            Stagger(
              index: 3 + i,
              child: Padding(padding: const EdgeInsets.only(top: 10), child: RecentRow(entry: e, onTap: () => openEntry(context, e))),
            ),
      ],
    );
  }
}

class RecentRow extends StatelessWidget {
  const RecentRow({super.key, required this.entry, required this.onTap});
  final HistoryEntry entry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final d = diffYMD(entry.birth, YMD.today());
    final short = '${d.years}y ${d.months}mo';
    return NeuPressable(
      radius: 20, label: '${entry.name}, $short', hint: 'Open result', onTap: onTap,
      builder: (ctx, t) => Neu(
        radius: 20, inset: Elev.iSm, padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          AcAvatar(entry.name, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.label(14, Tx.w7, c.ink))),
          const SizedBox(width: 8),
          Text(short, style: Tx.num(13, Tx.w8, c.accent)),
        ]),
      ),
    );
  }
}

/// Page-shaped placeholders — same grid as the screen so nothing jumps when content lands.
class _HitungSkeleton extends StatelessWidget {
  const _HitungSkeleton();
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    Widget field() => Neu(radius: 18, inset: Elev.iMd, height: 52);
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: tabScreenPadding(context),
        children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Bone(w: 90, h: 12), SizedBox(height: 8), Bone(w: 160, h: 28, r: 10)])),
            const Bone(w: 44, h: 44, circle: true),
          ]),
          const SizedBox(height: 18),
          NeuCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Bone(w: 110, h: 11),
              const SizedBox(height: 8),
              Row(children: [SizedBox(width: 66, child: field()), const SizedBox(width: 10), Expanded(child: field()), const SizedBox(width: 10), SizedBox(width: 92, child: field())]),
              const SizedBox(height: 14),
              const Bone(w: 120, h: 11),
              const SizedBox(height: 8),
              Row(children: [SizedBox(width: 66, child: field()), const SizedBox(width: 10), Expanded(child: field()), const SizedBox(width: 10), SizedBox(width: 92, child: field())]),
              const SizedBox(height: 14),
              const Bone(h: 60, r: 18),
            ]),
          ),
          const SizedBox(height: 18),
          const Bone(w: 130, h: 16),
          for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(top: 10), child: Neu(radius: 20, inset: Elev.iSm, height: 58, color: c.surface)),
        ],
      ),
    );
  }
}
