import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import '../ui/neu.dart';
import '../ui/overlays.dart';
import '../ui/widgets.dart';

/// Tab 4 — "Settings" (Figma "PM / 07 Settings"): no profile, no account — only theme, reminders and local data.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final app = context.watch<AppState>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget row({required String icon, required String title, required String desc, Widget? trailing}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Well(icon: icon, size: 42, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Tx.label(15, Tx.w7, c.ink)),
                const SizedBox(height: 1),
                Text(desc, style: Tx.label(12, Tx.w5, c.ink3).copyWith(height: 1.35)),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing],
          ]),
        );

    Widget card(String title, List<Widget> children, int i) => Stagger(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NeuCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), radius: 26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(padding: const EdgeInsets.only(left: 2, bottom: 4), child: Semantics(header: true, child: Text(title, style: Tx.h4(c.ink).copyWith(fontSize: 16)))),
                ...children,
              ]),
            ),
          ),
        );

    return ListView(
      padding: tabScreenPadding(context),
      children: [
        const Stagger(index: 0, child: ScreenTitle(title: 'Settings')),
        const SizedBox(height: 16),
        card('Appearance', [
          row(icon: dark ? 'moon' : 'sun', title: 'Theme', desc: 'Follow the system setting, or choose your own.'),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: NeuSegmented<ThemeMode>(
              label: 'Theme', value: app.themeMode, onChanged: app.setThemeMode,
              items: const [(ThemeMode.system, 'System'), (ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')],
            ),
          ),
        ], 1),
        card('Reminders', [
          row(
            icon: 'bell', title: 'Mark upcoming birthdays', desc: 'The bell icon gets a dot when a birthday in your history is within the next 7 days.',
            trailing: NeuToggle(value: app.reminders, onChanged: app.setReminders, label: 'Mark upcoming birthdays'),
          ),
        ], 2),
        card('Data & privacy', [
          row(icon: 'lock', title: 'Stored on this device', desc: 'Dates of birth are never sent anywhere. No account, no trackers.', trailing: Text('${app.history.length} saved', style: Tx.label(12, Tx.w6, c.ink3))),
          row(
            icon: 'refresh', title: 'Load sample data', desc: 'Replaces your history with seven examples for trying out search and filters.',
            trailing: NeuButton(
              label: 'Load', size: BtnSize.sm, kind: BtnKind.secondary,
              onPressed: () {
                app.restoreDemo();
                context.read<ToastController>().show('Sample data loaded', description: '7 entries added to history');
              },
            ),
          ),
          row(
            icon: 'trash', title: 'Clear all history', desc: 'Deletes every saved calculation. This cannot be undone.',
            trailing: NeuButton(
              label: 'Delete', size: BtnSize.sm, kind: BtnKind.secondary, danger: true,
              onPressed: app.history.isEmpty
                  ? null
                  : () async {
                      final ok = await confirmDialog(context, title: 'Clear all history?', message: 'Data is stored only on this device and cannot be recovered.');
                      if (!ok || !context.mounted) return;
                      app.clearHistory();
                      context.read<ToastController>().show('Deleted', description: 'All history deleted from this device');
                    },
            ),
          ),
        ], 3),
        card('About', [
          row(icon: 'info', title: 'Age Calculate', desc: 'Calculate age with precision: years, months, days, even hours.', trailing: Text('v1.0.0', style: Tx.label(12, Tx.w6, c.ink3))),
        ], 4),
      ],
    );
  }
}
