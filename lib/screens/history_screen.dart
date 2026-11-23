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
import 'hitung_screen.dart';

/// Tab 3 — "History" (Figma "PM / 06 History"). Swipe a row left to delete (commit at 40 %), long-press for actions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _q = TextEditingController();
  String _cat = 'All';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _matches(HistoryEntry e) {
    if (_cat != 'All' && e.category != _cat) return false;
    final n = _q.text.trim().toLowerCase();
    if (n.isEmpty) return true;
    return e.name.toLowerCase().contains(n) || formatMedium(e.birth).toLowerCase().contains(n) || kMonths[e.birth.m - 1].toLowerCase().contains(n) || '${e.birth.y}'.contains(n);
  }

  Future<void> _clearAll() async {
    final ok = await confirmDialog(context, title: 'Clear all history?', message: 'Data is stored only on this device and cannot be recovered.');
    if (!ok || !mounted) return;
    context.read<AppState>().clearHistory();
    context.read<ToastController>().show('Deleted', description: 'All history deleted from this device');
  }

  void _removeWithUndo(HistoryEntry e) {
    final app = context.read<AppState>();
    final removed = app.remove(e.id);
    HapticFeedback.mediumImpact();
    context.read<ToastController>().show(
          'Deleted',
          description: '${e.name} removed from history',
          actionLabel: 'Undo',
          onAction: removed == null ? null : () => app.insertAt(removed.$1, removed.$2),
        );
  }

  void _actions(HistoryEntry e) {
    final d = diffYMD(e.birth, YMD.today());
    final text = '${e.name}: ${ageText(d.years, d.months, d.days)} (born ${formatMedium(e.birth)}) — Age Calculate';
    showOptionRow(context, title: e.name, subtitle: '${formatMedium(e.birth)} · ${ageText(d.years, d.months, d.days)}', options: [
      SheetOption('copy', 'Copy age', () => copyToClipboard(context, text, description: "${e.name}'s age copied")),
      SheetOption('share', 'Send to…', () => shareText(context, text)),
      SheetOption('trash', 'Delete', () => _removeWithUndo(e), danger: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final app = context.watch<AppState>();
    final all = app.history;
    final rows = all.where(_matches).toList();

    return ListView(
      padding: tabScreenPadding(context),
      children: [
        Stagger(
          index: 0,
          child: ScreenTitle(
            title: 'History',
            subtitle: '${all.length} saved ${pluralize(all.length, 'calculation')}',
            trailing: NeuIconButton(icon: 'trash', label: 'Clear all history', size: 44, color: c.err, onPressed: all.isEmpty ? null : _clearAll, haptic: Haptic.light),
          ),
        ),
        const SizedBox(height: 14),
        Stagger(index: 1, child: AcTextField(controller: _q, hint: 'Search name or date...', leadingIcon: 'search', height: 50, fontSize: 14, semanticsLabel: 'Search history', onChanged: (_) => setState(() {}), textInputAction: TextInputAction.search)),
        const SizedBox(height: 12),
        Stagger(
          index: 2,
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [for (final k in ['All', ...kCategories]) Padding(padding: const EdgeInsets.only(right: 10), child: Center(child: NeuChip(label: k, toggle: true, active: _cat == k, onTap: () => setState(() => _cat = k))))],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          _Empty(noData: all.isEmpty, query: _q.text.trim(), category: _cat, onReset: () => setState(() {
                _q.clear();
                _cat = 'All';
              }))
        else
          for (final (i, e) in rows.indexed)
            Padding(
              key: ValueKey(e.id),
              padding: const EdgeInsets.only(top: 10),
              child: Stagger(index: 3 + i, child: _HistoryItem(entry: e, onOpen: () => openEntry(context, e), onLongPress: () => _actions(e), onDismissed: () => _removeWithUndo(e))),
            ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.entry, required this.onOpen, required this.onLongPress, required this.onDismissed});
  final HistoryEntry entry;
  final VoidCallback onOpen, onLongPress, onDismissed;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final d = diffYMD(entry.birth, YMD.today());
    final short = '${d.years}y ${d.months}mo';
    return Dismissible(
      key: ValueKey('dismiss-${entry.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      movementDuration: Motion.base,
      resizeDuration: Motion.base,
      onDismissed: (_) => onDismissed(),
      background: DecoratedBox(
        decoration: BoxDecoration(color: c.errBg, borderRadius: BorderRadius.circular(22)),
        child: Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 24), child: AcIcon('trash', color: c.err))),
      ),
      child: NeuPressable(
        radius: 22, label: '${entry.name}, born ${formatMedium(entry.birth)}, age $short', hint: 'Tap to open. Swipe left to delete.',
        onTap: onOpen, onLongPress: onLongPress, haptic: Haptic.selection,
        builder: (ctx, t) => Neu(
          radius: 22, raised: Elev.sm, inset: Elev.iMd, t: t, padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Row(children: [
            AcAvatar(entry.name, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.label(15, Tx.w8, c.ink)),
                Text(formatShort(entry.birth), style: Tx.label(12, Tx.w6, c.ink2)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(short, style: Tx.num(13, Tx.w8, c.accent)),
          ]),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.noData, required this.query, required this.category, required this.onReset});
  final bool noData;
  final String query, category;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 44, 8, 0),
      child: Column(
        children: [
          Neu(radius: 999, raised: Elev.base, width: 72, height: 72, child: Center(child: AcIcon('clock', size: 28, color: c.accent))),
          const SizedBox(height: 18),
          Text(noData ? 'No history yet' : 'No results', style: Tx.h4(c.ink)),
          const SizedBox(height: 8),
          Text(
            noData ? "Calculate someone's age, then choose Save. The data is stored only on this device." : 'No history matches ${query.isNotEmpty ? '“$query”' : category}. Change your search or choose “All”.',
            textAlign: TextAlign.center, style: Tx.bodyS(c.ink2).copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          if (noData) ...[
            NeuButton(label: 'Calculate your first age', icon: 'zap', onPressed: () => context.read<TabNav>().go(0)),
            const SizedBox(height: 6),
            NeuButton(label: 'Load sample data', kind: BtnKind.ghost, onPressed: () => context.read<AppState>().restoreDemo()),
          ] else
            NeuButton(label: 'Reset search', kind: BtnKind.ghost, onPressed: onReset),
        ],
      ),
    );
  }
}
