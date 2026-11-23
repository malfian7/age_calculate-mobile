import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/age.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import '../ui/neu.dart';
import '../ui/overlays.dart';
import '../ui/widgets.dart';

/// Tab 2 — "Difference" (Figma "PM / 05 Age Difference"). Names are editable text fields.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  static const _rel = ['Person 1', 'Person 2'];
  final List<TextEditingController> _names = [TextEditingController(text: 'Anita'), TextEditingController(text: 'Dimas')];
  final List<YMD> _births = [const YMD(1998, 8, 14), const YMD(2001, 1, 26)];

  @override
  void dispose() {
    for (final n in _names) {
      n.dispose();
    }
    super.dispose();
  }

  String _name(int i) => _names[i].text.trim().isEmpty ? _rel[i] : _names[i].text.trim();

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      final tn = _names[0].text;
      _names[0].text = _names[1].text;
      _names[1].text = tn;
      final tb = _births[0];
      _births[0] = _births[1];
      _births[1] = tb;
    });
  }

  String _summary(BirthCompare d, String older, String younger) => d.same
      ? '${_name(0)} and ${_name(1)} were born on the same day — Age Calculate'
      : '$older is ${ageText(d.years, d.months, d.days)} older than $younger (a difference of ${fmtInt(d.totalDays)} ${pluralize(d.totalDays, 'day')}) — Age Calculate';

  void _share(String text, String subtitle) {
    showOptionRow(context, title: 'Share result', subtitle: subtitle, options: [
      SheetOption('copy', 'Copy', () => copyToClipboard(context, text, description: 'Age difference result copied')),
      SheetOption('share', 'Send to…', () => shareText(context, text)),
    ]);
  }

  void _save() {
    final app = context.read<AppState>();
    for (var i = 0; i < 2; i++) {
      app.add(name: _name(i), category: 'Friends', birth: _births[i]);
    }
    context.read<ToastController>().show('Saved', description: '2 people added to history');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final today = YMD.today();
    final future = _births.indexWhere((b) => b > today);
    final diff = future == -1 ? compareBirths(_births[0], _births[1]) : null;
    final older = diff == null ? '' : _name(diff.olderIsA ? 0 : 1);
    final younger = diff == null ? '' : _name(diff.olderIsA ? 1 : 0);

    Widget person(int i) => Neu(
          radius: 24, raised: Elev.md, padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListenableBuilder(listenable: _names[i], builder: (_, __) => AcAvatar(_name(i), size: 44)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('NAME', style: Tx.label(11, Tx.w7, c.ink2, 0.05)), Tag(_rel[i])]),
                      const SizedBox(height: 6),
                      AcTextField(
                        controller: _names[i], hint: 'Name of ${_rel[i].toLowerCase()}', maxLength: 24, height: 44, fontSize: 15, trailingIcon: 'edit', selectAllOnFocus: true,
                        semanticsLabel: 'Name of ${_rel[i].toLowerCase()}', textInputAction: TextInputAction.done, onChanged: (_) => setState(() {}),
                      ),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const SectionLabel('Date of birth'),
              const SizedBox(height: 8),
              DateRow(label: 'Date of birth for ${_name(i)}', value: _births[i], maxYear: today.y, onPick: (d) => setState(() => _births[i] = d)),
              const SizedBox(height: 12),
              Neu(
                radius: 14, inset: Elev.iSm, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text('Current age', style: Tx.label(12, Tx.w7, c.ink2))),
                  Text(_births[i] > today ? '—' : () {
                    final d = diffYMD(_births[i], today);
                    return ageShort(d.years, d.months, d.days);
                  }(), style: Tx.num(13, Tx.w8, c.accent)),
                ]),
              ),
            ],
          ),
        );

    return ListView(
      padding: tabScreenPadding(context),
      children: [
        const Stagger(index: 0, child: ScreenTitle(title: 'Age difference', subtitle: 'Compare two dates of birth.')),
        const SizedBox(height: 14),
        Stagger(index: 1, child: person(0)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: NeuIconButton(icon: 'refresh', label: 'Swap person 1 and person 2', size: 44, color: c.accent, onPressed: _swap)),
        ),
        Stagger(index: 2, child: person(1)),
        const SizedBox(height: 14),
        Stagger(
          index: 3,
          child: NeuCard(
            padding: const EdgeInsets.all(22),
            semanticsLabel: 'Age difference result',
            child: diff == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(children: [
                      const Well(icon: 'users', size: 52, iconSize: 24),
                      const SizedBox(height: 12),
                      Text('Waiting for two dates of birth', style: Tx.h4(c.ink)),
                      const SizedBox(height: 6),
                      Text("${_name(future)}'s date of birth is in the future.", textAlign: TextAlign.center, style: Tx.bodyS(c.ink2)),
                    ]),
                  )
                : _DiffResult(diff: diff, older: older, younger: younger, olderName: _name(diff.olderIsA ? 0 : 1), a: _births[0], b: _births[1], today: today, onShare: () => _share(_summary(diff, older, younger), diff.same ? 'Born on the same day' : ageText(diff.years, diff.months, diff.days)), onSave: _save),
          ),
        ),
      ],
    );
  }
}

class _DiffResult extends StatelessWidget {
  const _DiffResult({required this.diff, required this.older, required this.younger, required this.olderName, required this.a, required this.b, required this.today, required this.onShare, required this.onSave});
  final BirthCompare diff;
  final String older, younger, olderName;
  final YMD a, b, today;
  final VoidCallback onShare, onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final olderBirth = diff.olderIsA ? a : b;
    final youngerBirth = diff.olderIsA ? b : a;
    final frac = diff.same ? 1.0 : (daysBetween(youngerBirth, today) / (daysBetween(olderBirth, today) == 0 ? 1 : daysBetween(olderBirth, today))).clamp(0.05, 1.0).toDouble();

    Widget bar(String name, double w, bool strong) => Row(children: [
          SizedBox(width: 56, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.label(12, Tx.w7, c.ink2))),
          const SizedBox(width: 10),
          Expanded(
            child: Neu(
              radius: 8, inset: Elev.iXs, height: 16, clip: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: w), duration: Motion.of(context, Motion.slow), curve: Motion.out,
                  builder: (_, v, __) => FractionallySizedBox(widthFactor: v.clamp(0.0, 1.0).toDouble(), child: DecoratedBox(decoration: BoxDecoration(gradient: strong ? P.gradient : null, color: strong ? null : P.p300, borderRadius: BorderRadius.circular(8)), child: const SizedBox(height: 16))),
                ),
              ),
            ),
          ),
        ]);

    Widget well(String v, String l, {bool accent = false}) => Expanded(
          child: Neu(
            radius: 18, inset: Elev.iMd, padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(v, maxLines: 1, style: Tx.num(22, Tx.w8, accent ? c.accent : c.ink, -0.02))),
              const SizedBox(height: 2),
              Text(l.toUpperCase(), style: Tx.label(11, Tx.w7, c.ink2, 0.05)),
            ]),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Tag('Difference'),
        const SizedBox(height: 12),
        Text(diff.same ? 'Born on the same day' : ageText(diff.years, diff.months, diff.days), style: Tx.h2(c.ink).copyWith(fontSize: 26, height: 1.14), semanticsLabel: diff.same ? 'Born on the same day' : 'Difference of ${ageText(diff.years, diff.months, diff.days)}'),
        const SizedBox(height: 8),
        Text(
          diff.same ? '$older and $younger were born on the same date.' : '$older is older than $younger. Total ${fmtInt(diff.totalDays)} ${pluralize(diff.totalDays, 'day')}, or ${fmtInt(diff.totalWeeks)} ${pluralize(diff.totalWeeks, 'week')}.',
          style: Tx.label(13, Tx.w6, c.ink2).copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        bar(older, 1, true),
        const SizedBox(height: 10),
        bar(younger, frac, false),
        const SizedBox(height: 16),
        Row(children: [well(fmtInt(diff.totalMonths), 'Months'), const SizedBox(width: 10), well(fmtInt(diff.totalWeeks), 'Weeks')]),
        const SizedBox(height: 10),
        Row(children: [well(fmtInt(diff.totalDays), 'Days'), const SizedBox(width: 10), well(fmtInt(diff.totalHours), 'Hours', accent: true)]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: NeuButton(label: 'Share', icon: 'share', block: true, onPressed: onShare)),
          const SizedBox(width: 12),
          Expanded(child: NeuButton(label: 'Save', icon: 'bookmark', kind: BtnKind.secondary, block: true, onPressed: onSave)),
        ]),
      ],
    );
  }
}
