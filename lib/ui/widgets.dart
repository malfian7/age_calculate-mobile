import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/age.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import 'icons.dart';
import 'neu.dart';
import 'overlays.dart';

// ====================================================================================================== date row
enum DateField { day, month, year }

/// Three tappable boxes (day · month ▾ · year ▾) that all open the same wheel sheet.
/// Dates always come from the wheels, so they are always real calendar dates.
class DateRow extends StatelessWidget {
  const DateRow({super.key, required this.label, required this.value, required this.onPick, this.maxYear, this.disabled = false, this.errorField});
  final String label;
  final YMD value;
  final ValueChanged<YMD> onPick;
  final int? maxYear;
  final bool disabled;
  final DateField? errorField;

  Future<void> _open(BuildContext context) async {
    final picked = await pickDate(context, title: label, initial: value, maxYear: maxYear);
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    Widget box(DateField f, String text, String semantic, {bool chevron = false}) {
      final c = context.ac;
      final invalid = errorField == f;
      return NeuPressable(
        radius: 18, label: '$label, $semantic $text', hint: disabled ? null : 'Tap to choose a date', onTap: disabled ? null : () => _open(context), haptic: Haptic.selection,
        builder: (ctx, t) => Opacity(
          opacity: disabled ? 0.6 : 1,
          child: Neu(
            radius: 18, inset: Elev.iMd, height: 52, padding: EdgeInsets.symmetric(horizontal: chevron ? 14 : 16),
            border: Border.all(color: invalid ? c.err : Colors.transparent, width: 2),
            child: Row(
              children: [
                Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.num(15, Tx.w6, disabled ? c.ink2 : c.ink))),
                if (chevron) AcIcon('chevD', size: 20, color: disabled ? c.ink3 : c.accent),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(width: 66, child: box(DateField.day, '${value.d}', 'day')),
        const SizedBox(width: 10),
        Expanded(child: box(DateField.month, kMonths[value.m - 1], 'month', chevron: true)),
        const SizedBox(width: 10),
        SizedBox(width: 92, child: box(DateField.year, '${value.y}', 'year', chevron: true)),
      ],
    );
  }
}

// ====================================================================================================== bits
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: Tx.label(11, Tx.w7, context.ac.ink2, 0.05));
}

/// Stat tile: well + caps label, big value (Figma "StatTile").
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.label, required this.value, this.accent = false});
  final String icon, label, value;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Semantics(
      container: true, label: '$label $value',
      child: Neu(
        radius: 20, raised: Elev.btn, padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              AcIcon(icon, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.label(11, Tx.w7, c.ink2, 0.04))),
            ]),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, maxLines: 1, style: Tx.num(22, Tx.w8, accent ? c.accent : c.ink, -0.02))),
          ],
        ),
      ),
    );
  }
}

/// Three inset wells: years · months · days.
class YmdWells extends StatelessWidget {
  const YmdWells({super.key, required this.years, required this.months, required this.days});
  final int years, months, days;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    Widget cell(int v, String l) => Expanded(
          child: Neu(
            radius: 20, inset: Elev.iMd, padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$v', style: Tx.num(28, Tx.w8, c.accent, -0.02)),
              const SizedBox(height: 4),
              Text(l.toUpperCase(), style: Tx.label(12, Tx.w7, c.ink2, 0.05)),
            ]),
          ),
        );
    return Semantics(
      container: true, label: 'Age breakdown: ${ageText(years, months, days)}',
      child: ExcludeSemantics(child: Row(children: [cell(years, 'Years'), const SizedBox(width: 12), cell(months, 'Months'), const SizedBox(width: 12), cell(days, 'Days')])),
    );
  }
}

/// Large screen title used by the tab screens.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(title, style: Tx.h2(c.ink))),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: Tx.label(13, Tx.w6, c.ink2))),
          ]),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Horizontal padding + the room the floating tab bar needs at the bottom.
EdgeInsets tabScreenPadding(BuildContext context, {double top = 12}) {
  final pad = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(20, pad.top + top, 20, 112 + pad.bottom);
}

// ====================================================================================================== share helpers
String shareSummary(AgeResult r, {String? name}) =>
    '${name != null ? '$name: ' : ''}Age ${ageText(r.years, r.months, r.days)} — born ${formatMedium(r.birth)}, calculated on ${formatMedium(r.ref)} (Age Calculate)';

/// iPad needs an anchor rectangle for the share popover; a 1×1 spot at the bottom centre works on every device.
Rect shareOrigin(BuildContext context) {
  final s = MediaQuery.sizeOf(context);
  return Rect.fromLTWH(s.width / 2, s.height - 1, 1, 1);
}

Future<void> copyToClipboard(BuildContext context, String text, {String title = 'Copied', String? description}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) context.read<ToastController>().show(title, description: description ?? 'Copied to clipboard');
}

Future<void> shareText(BuildContext context, String text) async {
  final toast = context.read<ToastController>();
  final origin = shareOrigin(context);
  try {
    await Share.share(text, sharePositionOrigin: origin);
  } catch (_) {
    toast.show("Couldn't open the share menu", description: 'Try copying the result and pasting it manually', kind: ToastKind.err);
  }
}

/// Renders the boundary to a PNG in the temp folder and opens the system share sheet with it.
Future<void> shareBoundaryAsImage(BuildContext context, GlobalKey boundaryKey, {String? text}) async {
  final toast = context.read<ToastController>();
  final origin = shareOrigin(context);
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('no boundary');
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('no bytes');
    final bytes = data.buffer.asUint8List();
    final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}age-calculate-${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: text, sharePositionOrigin: origin);
  } catch (_) {
    toast.show("Couldn't create the image", description: 'Try again, or share as text', kind: ToastKind.err);
  }
}
