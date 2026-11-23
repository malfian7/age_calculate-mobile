import 'package:flutter/material.dart';
import '../core/age.dart';
import '../core/tokens.dart';
import '../ui/confetti.dart';
import '../ui/icons.dart';
import '../ui/logo.dart';
import '../ui/neu.dart';
import '../ui/overlays.dart';
import '../ui/ring.dart';
import '../ui/widgets.dart';

/// Result of one calculation (Figma "PM / 04 Result"). Opened from the calculator, or from a history row (then [name] is set).
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, this.name});
  final AgeResult result;
  final String? name;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _captureKey = GlobalKey();

  AgeResult get r => widget.result;

  void _share() {
    final text = shareSummary(r, name: widget.name);
    showOptionRow(
      context,
      title: 'Share result',
      subtitle: ageText(r.years, r.months, r.days),
      options: [
        SheetOption('copy', 'Copy', () => copyToClipboard(context, text, description: 'Age result copied')),
        SheetOption('share', 'Send to…', () => shareText(context, text)),
        SheetOption('smartphone', 'Image', () => shareBoundaryAsImage(context, _captureKey, text: text)),
        SheetOption('bookmark', 'Save', _save),
      ],
    );
  }

  void _save() => showSaveSheet(context, birth: r.birth, initialName: widget.name ?? '');

  void _openNext() {
    showAcSheet<void>(context, builder: (ctx) => _NextBirthdaySheet(result: r));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final mq = MediaQuery.of(context);
    final n = r.next;
    final name = widget.name;

    return Scaffold(
      backgroundColor: c.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, mq.padding.top + 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeuIconButton(icon: 'chevL', label: 'Back', size: 44, onPressed: () => Navigator.of(context).maybePop()),
                    Semantics(header: true, child: Text('Age result', style: Tx.h4(c.ink))),
                    NeuIconButton(icon: 'share', label: 'Share result', size: 44, onPressed: _share),
                  ],
                ),
              ),
              Expanded(
                child: ResultMotion(
                  builder: (ctx, p) {
                    int k(int v) => (v * p).round();
                    return ListView(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 120 + mq.padding.bottom),
                      children: [
                        RepaintBoundary(
                          key: _captureKey,
                          child: ColoredBox(
                            color: c.surface,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  if (name != null) ...[Tag(name), const SizedBox(height: 14)],
                                  AgeRing(
                                    size: 212, progress: n.progress * p,
                                    semanticLabel: 'Age ${ageText(r.years, r.months, r.days)}',
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Text(fmtInt(k(r.years)), style: Tx.num(68, Tx.w8, c.ink, -0.04, 64)),
                                      Text('YEARS', style: Tx.label(12, Tx.w7, c.ink2, 0.12)),
                                    ]),
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Born on ${formatLong(r.birth)}', textAlign: TextAlign.center, style: Tx.label(13, Tx.w6, c.ink2)),
                                  const SizedBox(height: 14),
                                  YmdWells(years: k(r.years), months: k(r.months), days: k(r.days)),
                                  const SizedBox(height: 14),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                    LogoMark(size: 18), const SizedBox(width: 8), const Wordmark(size: 13),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Stagger(index: 1, child: Row(children: [
                          Expanded(child: StatTile(icon: 'sun', label: 'Total days', value: fmtInt(k(r.totalDays)))),
                          const SizedBox(width: 12),
                          Expanded(child: StatTile(icon: 'clock', label: 'Total hours', value: fmtInt(k(r.totalHours)), accent: true)),
                        ])),
                        const SizedBox(height: 12),
                        Stagger(index: 2, child: Row(children: [
                          Expanded(child: StatTile(icon: 'layers', label: 'Total weeks', value: fmtInt(k(r.totalWeeks)))),
                          const SizedBox(width: 12),
                          Expanded(child: StatTile(icon: 'calendar', label: 'Total months', value: fmtInt(k(r.totalMonths)))),
                        ])),
                        const SizedBox(height: 14),
                        Stagger(
                          index: 3,
                          child: NeuPressable(
                            radius: 22, label: n.isToday ? '${ordinal(n.age)} birthday is today' : '${fmtInt(n.daysToNext)} ${pluralize(n.daysToNext, 'day')} to go until the ${ordinal(n.age)} birthday',
                            hint: 'Tap to see details', onTap: _openNext, haptic: Haptic.selection,
                            builder: (ctx, t) => Neu(
                              radius: 22, inset: Elev.iMd, padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Row(children: [
                                const Well(icon: 'gift', size: 42, iconSize: 22, filled: true),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${ordinal(n.age)} birthday', style: Tx.label(12, Tx.w7, c.ink2)),
                                    Text(n.isToday ? 'Today!' : '${fmtInt(n.daysToNext)} ${pluralize(n.daysToNext, 'day')} to go', style: Tx.num(17, Tx.w8, c.accent)),
                                  ]),
                                ),
                                AcIcon('chevR', color: c.ink3),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Stagger(
                          index: 4,
                          child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            _Pill(icon: 'star', label: r.zodiac.name, active: true),
                            _Pill(label: generationShort(r.birth.y)),
                            _Pill(label: 'Born on a ${r.bornOn}'),
                          ]),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          // rare delight: confetti only when the birthday is today
          if (n.isToday) const Positioned.fill(child: ConfettiBurst()),
          // swipe in from the left edge to go back
          Positioned(
            left: 0, top: 0, bottom: 0, width: 20,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) > 300) Navigator.of(context).maybePop();
              },
            ),
          ),
          // action bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.surface.withValues(alpha: 0), c.surface, c.surface], stops: const [0, 0.28, 1])),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 12 + mq.padding.bottom),
                child: Row(children: [
                  Expanded(child: NeuButton(label: 'Save', icon: 'bookmark', kind: BtnKind.secondary, block: true, onPressed: _save)),
                  const SizedBox(width: 12),
                  Expanded(child: NeuButton(label: 'Share', icon: 'share', block: true, onPressed: _share)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon, this.active = false});
  final String label;
  final String? icon;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final fg = active ? Colors.white : c.accentStrong;
    final inner = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[AcIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
      Text(label, style: Tx.label(13, Tx.w7, fg)),
    ]);
    const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 9);
    return active
        ? Neu(radius: 999, padding: pad, gradient: P.gradient, glow: glowShadows(c), child: inner)
        : Neu(radius: 999, padding: pad, raised: Elev.xs, child: inner);
  }
}

class _NextBirthdaySheet extends StatelessWidget {
  const _NextBirthdaySheet({required this.result});
  final AgeResult result;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final n = result.next;
    return AcSheetFrame(
      title: '${ordinal(n.age)} birthday',
      subtitle: formatLong(n.date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text(n.isToday ? 'Today!' : fmtInt(n.daysToNext), style: Tx.num(n.isToday ? 44 : 64, Tx.w8, c.accent, -0.04))),
          if (!n.isToday) Center(child: Text(n.daysToNext == 1 ? 'day to go' : 'days to go', style: Tx.label(13, Tx.w6, c.ink2))),
          const SizedBox(height: 16),
          Row(children: [
            for (final (v, l) in [('${n.until.months}', 'Months'), ('${n.until.days}', 'Days'), (fmtInt(n.daysToNext * 24), 'Hours')]) ...[
              Expanded(
                child: Neu(
                  radius: 16, inset: Elev.iSm, padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(children: [Text(v, style: Tx.num(18, Tx.w8, c.accent)), Text(l.toUpperCase(), style: Tx.label(11, Tx.w7, c.ink3, 0.04))]),
                ),
              ),
              if (l != 'Hours') const SizedBox(width: 12),
            ],
          ]),
          const SizedBox(height: 22),
          Text('Milestone numbers', style: Tx.h4(c.ink).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          for (final m in result.milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Neu(
                radius: 18, raised: m.past ? null : Elev.xs, inset: m.past ? Elev.iSm : null, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 28, height: 28, alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: m.past ? P.gradient : null, color: m.past ? null : c.surface),
                    child: AcIcon(m.past ? 'check' : 'flag', size: 16, color: m.past ? Colors.white : c.ink3, strokeWidth: m.past ? 3 : 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m.label, style: Tx.label(15, Tx.w8, c.ink))),
                  Text(m.past ? 'Achieved' : formatMedium(m.date), style: Tx.label(12, Tx.w6, m.past ? c.okText : c.ink2)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
