import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/age.dart';
import '../core/tokens.dart';
import '../state/stores.dart';
import 'icons.dart';
import 'neu.dart';

// ====================================================================================================== page route
/// Push: the new page slides in from the right while the old one drifts −30 % and dims 8 % (320 ms, standard curve).
/// Pop: the reverse in 280 ms. Reduced motion → plain cross-fade.
class AcPageRoute<T> extends PageRoute<T> {
  AcPageRoute({required this.builder, super.settings});
  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => Motion.moderate;
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);
  @override
  bool get opaque => true;
  @override
  bool get barrierDismissible => false;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (context.reduceMotion) return FadeTransition(opacity: animation, child: child);
    final enter = CurvedAnimation(parent: animation, curve: Motion.drawer, reverseCurve: Motion.drawer);
    final cover = CurvedAnimation(parent: secondaryAnimation, curve: Motion.drawer, reverseCurve: Motion.drawer);
    return AnimatedBuilder(
      animation: Listenable.merge([enter, cover]),
      child: child,
      builder: (ctx, child) {
        final w = MediaQuery.sizeOf(ctx).width;
        final e = enter.value, k = cover.value;
        final dx = (1 - e) * w - k * w * 0.3;
        // the page covered by a newer one recedes slightly (scale 0.96) and dims; the incoming page has a soft left-edge shadow
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: 1 - 0.04 * k,
                child: Opacity(
                  opacity: (0.4 + 0.6 * e).clamp(0.0, 1.0).toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(boxShadow: e < 1 ? [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.18 * (1 - e)), blurRadius: 28, offset: const Offset(-8, 0))] : const []),
                    child: child,
                  ),
                ),
              ),
            ),
            if (k > 0) Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: 0.08 * k)))),
          ],
        );
      },
    );
  }
}

// ====================================================================================================== sheets
Future<R?> showAcSheet<R>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ac.scrim,
    elevation: 0,
    useSafeArea: false,
    sheetAnimationStyle: context.reduceMotion
        ? const AnimationStyle(duration: Duration(milliseconds: 120), reverseDuration: Duration(milliseconds: 120))
        : AnimationStyle(duration: Motion.moderate, reverseDuration: const Duration(milliseconds: 240), curve: Motion.drawer, reverseCurve: Motion.exit),
    builder: builder,
  );
}

class AcSheetFrame extends StatelessWidget {
  const AcSheetFrame({super.key, required this.child, this.title, this.subtitle, this.onClose});
  final Widget child;
  final String? title, subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Semantics(
        scopesRoute: true, namesRoute: true, label: title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, -10), blurRadius: 30)],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: c.dark ? c.line : P.p200, borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 16),
                  if (title != null)
                    Stagger(
                      index: 1, rise: 10,
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title!, style: Tx.h3(c.ink).copyWith(fontSize: 20, height: 1.3)),
                            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle!, style: Tx.bodyS(c.ink2))),
                          ]),
                        ),
                        NeuIconButton(icon: 'x', label: 'Close', size: 40, small: true, onPressed: onClose ?? () => Navigator.of(context).maybePop()),
                      ],
                    ),
                    ),
                  if (title != null) const SizedBox(height: 16),
                  Stagger(index: 2, rise: 14, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- date wheels
Future<YMD?> pickDate(BuildContext context, {required String title, required YMD initial, int? maxYear}) {
  return showAcSheet<YMD>(context, builder: (_) => _DateSheet(title: title, initial: initial, maxYear: maxYear ?? (YMD.today().y + 100)));
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.title, required this.initial, required this.maxYear});
  final String title;
  final YMD initial;
  final int maxYear;
  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  static const double _itemH = 46;
  late int _d, _m, _y;
  late final FixedExtentScrollController _dc, _mc, _yc;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _y = i.y.clamp(kMinYear, widget.maxYear).toInt();
    _m = i.m;
    _d = math.min(i.d, daysInMonth(_y, _m));
    _dc = FixedExtentScrollController(initialItem: _d - 1);
    _mc = FixedExtentScrollController(initialItem: _m - 1);
    _yc = FixedExtentScrollController(initialItem: _y - kMinYear);
  }

  @override
  void dispose() {
    _dc.dispose();
    _mc.dispose();
    _yc.dispose();
    super.dispose();
  }

  void _clampDay() {
    final dim = daysInMonth(_y, _m);
    if (_d > dim) {
      _d = dim;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dc.hasClients) _dc.animateToItem(dim - 1, duration: Motion.fast, curve: Motion.out);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final dim = daysInMonth(_y, _m);
    final yearCount = widget.maxYear - kMinYear + 1;
    return AcSheetFrame(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Neu(
            radius: 24, inset: Elev.iMd, height: 184, clip: true,
            child: Stack(
              children: [
                Positioned(
                  left: 10, right: 10, top: 69, height: _itemH,
                  child: DecoratedBox(decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(16))),
                ),
                Row(
                  children: [
                    Expanded(flex: 22, child: _Wheel(label: 'Day', controller: _dc, count: dim, selected: _d - 1, text: (i) => '${i + 1}', onChanged: (i) => setState(() => _d = i + 1))),
                    Expanded(
                      flex: 42,
                      child: _Wheel(label: 'Month', controller: _mc, count: 12, selected: _m - 1, text: (i) => kMonths[i], onChanged: (i) {
                        setState(() {
                          _m = i + 1;
                          _clampDay();
                        });
                      }),
                    ),
                    Expanded(
                      flex: 28,
                      child: _Wheel(label: 'Year', controller: _yc, count: yearCount, selected: _y - kMinYear, text: (i) => '${kMinYear + i}', onChanged: (i) {
                        setState(() {
                          _y = kMinYear + i;
                          _clampDay();
                        });
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: NeuButton(label: 'Cancel', kind: BtnKind.secondary, size: BtnSize.lg, block: true, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 14),
              Expanded(child: NeuButton(label: 'Select Date', size: BtnSize.lg, block: true, onPressed: () => Navigator.of(context).pop(YMD(_y, _m, _d)))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.label, required this.controller, required this.count, required this.selected, required this.text, required this.onChanged});
  final String label;
  final FixedExtentScrollController controller;
  final int count, selected;
  final String Function(int) text;
  final ValueChanged<int> onChanged;

  void _step(int by) {
    final next = (selected + by).clamp(0, count - 1).toInt();
    controller.animateToItem(next, duration: Motion.fast, curve: Motion.out);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Semantics(
      label: label, value: text(selected),
      onIncrease: selected < count - 1 ? () => _step(1) : null,
      onDecrease: selected > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 46,
          diameterRatio: 100,
          perspective: 0.0001,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) {
            HapticFeedback.selectionClick(); // the "tick" on every row
            onChanged(i);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (ctx, i) {
              final dist = (i - selected).abs();
              final isSel = dist == 0;
              return Center(
                child: Text(
                  text(i), maxLines: 1,
                  style: Tx.num(isSel ? 22 : 17, isSel ? Tx.w8 : Tx.w5, isSel ? c.accentStrong : c.ink3).copyWith(
                    color: (isSel ? c.accentStrong : c.ink3).withValues(alpha: isSel ? 1 : math.max(0.25, 1 - dist * 0.35)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- text field
class AcTextField extends StatefulWidget {
  const AcTextField({super.key, required this.controller, this.hint, this.maxLength, this.invalid = false, this.trailingIcon, this.onChanged, this.onSubmitted, this.autofocus = false, this.height = 52, this.fontSize = 16, this.semanticsLabel, this.selectAllOnFocus = false, this.textInputAction, this.keyboardType, this.leadingIcon});
  final TextEditingController controller;
  final String? hint, semanticsLabel, trailingIcon, leadingIcon;
  final int? maxLength;
  final bool invalid, autofocus, selectAllOnFocus;
  final ValueChanged<String>? onChanged, onSubmitted;
  final double height, fontSize;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  @override
  State<AcTextField> createState() => _AcTextFieldState();
}

class _AcTextFieldState extends State<AcTextField> {
  final FocusNode _focus = FocusNode();
  bool _has = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && widget.selectAllOnFocus) {
        widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
      }
      setState(() => _has = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final ring = widget.invalid ? c.err : (c.dark ? P.p300 : P.p500);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast), curve: Motion.out,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: (_has || widget.invalid) ? ring.withValues(alpha: 0.28) : Colors.transparent, spreadRadius: 4)]),
        child: Neu(
          radius: 18, inset: Elev.iMd, height: widget.height, padding: const EdgeInsets.symmetric(horizontal: 18),
          border: Border.all(color: (_has || widget.invalid) ? ring : Colors.transparent, width: 2),
          child: Row(
            children: [
              if (widget.leadingIcon != null) ...[AcIcon(widget.leadingIcon!, size: 22, color: c.ink3), const SizedBox(width: 12)],
              Expanded(
                child: Semantics(
                  textField: true, label: widget.semanticsLabel,
                  child: TextField(
                    controller: widget.controller, focusNode: _focus, autofocus: widget.autofocus, onChanged: widget.onChanged, onSubmitted: widget.onSubmitted,
                    textInputAction: widget.textInputAction, keyboardType: widget.keyboardType, cursorColor: c.accent, autocorrect: false, enableSuggestions: false,
                    inputFormatters: [if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength)],
                    style: Tx.label(widget.fontSize, Tx.w8, c.ink, -0.01),
                    decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: Tx.label(widget.fontSize, Tx.w6, c.ink3)),
                  ),
                ),
              ),
              if (widget.trailingIcon != null) ...[const SizedBox(width: 10), AcIcon(widget.trailingIcon!, size: 20, color: c.accent)],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- save sheet
Future<void> showSaveSheet(BuildContext context, {required YMD birth, String initialName = ''}) async {
  await showAcSheet<void>(context, builder: (_) => _SaveSheet(birth: birth, initialName: initialName));
}

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({required this.birth, required this.initialName});
  final YMD birth;
  final String initialName;
  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  String _cat = 'Friends';
  bool _touched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _touched = true);
      HapticFeedback.mediumImpact();
      return;
    }
    context.read<AppState>().add(name: n, category: _cat, birth: widget.birth);
    context.read<ToastController>().show('Saved', description: '$n added to history');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final bad = _touched && _name.text.trim().isEmpty;
    return AcSheetFrame(
      title: 'Save to history',
      subtitle: 'Born ${formatMedium(widget.birth)}. Stored only on this device.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NAME', style: Tx.label(12, Tx.w7, c.ink2, 0.05)),
          const SizedBox(height: 8),
          AcTextField(
            controller: _name, hint: 'e.g. Mom', maxLength: 30, invalid: bad, autofocus: true, semanticsLabel: 'Name',
            textInputAction: TextInputAction.done, onSubmitted: (_) => _submit(), onChanged: (_) => setState(() {}),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.base), curve: Motion.out,
            child: bad ? Padding(padding: const EdgeInsets.only(top: 8), child: Text('Add a name so it is easy to find later', style: Tx.label(12, Tx.w6, c.err))) : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 18),
          Text('CATEGORY', style: Tx.label(12, Tx.w7, c.ink2, 0.05)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final k in kCategories) NeuChip(label: k, toggle: true, active: _cat == k, onTap: () => setState(() => _cat = k))]),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: NeuButton(label: 'Cancel', kind: BtnKind.secondary, size: BtnSize.lg, block: true, onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 14),
              Expanded(child: NeuButton(label: 'Save', icon: 'check', size: BtnSize.lg, block: true, onPressed: _submit)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------- generic option sheet
class SheetOption {
  const SheetOption(this.icon, this.label, this.onTap, {this.danger = false});
  final String icon, label;
  final VoidCallback onTap;
  final bool danger;
}

/// Row of round options (share sheet) — Copy · Send to… · Image · Save.
Future<void> showOptionRow(BuildContext context, {required String title, String? subtitle, required List<SheetOption> options}) {
  return showAcSheet<void>(context, builder: (ctx) {
    final c = ctx.ac;
    return AcSheetFrame(
      title: title, subtitle: subtitle,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final o in options)
            Expanded(
              child: NeuPressable(
                radius: 22, label: o.label, haptic: Haptic.light,
                onTap: () {
                  Navigator.of(ctx).pop();
                  o.onTap();
                },
                builder: (_, t) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Neu(radius: 22, width: 64, height: 64, raised: Elev.btn, inset: Elev.iMd, t: t, child: Center(child: AcIcon(o.icon, color: o.danger ? c.err : c.accent))),
                    const SizedBox(height: 8),
                    Text(o.label, textAlign: TextAlign.center, style: Tx.label(12, Tx.w7, c.ink2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  });
}

// ====================================================================================================== dialog
/// Confirmation dialog: scrim fades in (200 ms), the panel scales 0.96 → 1 + fades (240 ms). Close is 160 ms.
Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirmLabel = 'Delete', String cancelLabel = 'Cancel', String icon = 'trash'}) async {
  final res = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close dialog',
    barrierColor: context.ac.scrim,
    transitionDuration: context.reduceMotion ? const Duration(milliseconds: 120) : const Duration(milliseconds: 280),
    pageBuilder: (ctx, a, b) {
      final c = ctx.ac;
      return Material(
        type: MaterialType.transparency,
        child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Semantics(
                scopesRoute: true, namesRoute: true, explicitChildNodes: true, label: title,
                child: Neu(
                  radius: 30, raised: Elev.lg, padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [Well(icon: icon, size: 48, iconSize: 22, color: c.err), const SizedBox(width: 14), Expanded(child: Text(title, style: Tx.h4(c.ink)))]),
                      const SizedBox(height: 12),
                      Text(message, style: Tx.bodyS(c.ink2).copyWith(height: 1.5)),
                      const SizedBox(height: 22),
                      Row(children: [
                        Expanded(child: NeuButton(label: cancelLabel, kind: BtnKind.secondary, block: true, onPressed: () => Navigator.of(ctx).pop(false))),
                        const SizedBox(width: 12),
                        Expanded(child: NeuButton(label: confirmLabel, icon: icon, block: true, haptic: Haptic.medium, onPressed: () => Navigator.of(ctx).pop(true))),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      );
    },
    transitionBuilder: (ctx, a, b, child) {
      if (ctx.reduceMotion) return FadeTransition(opacity: a, child: child);
      final enter = CurvedAnimation(parent: a, curve: Motion.out, reverseCurve: Motion.exit);
      return FadeTransition(
        opacity: enter,
        child: AnimatedBuilder(
          animation: enter,
          child: child,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 18 * (1 - enter.value)),
            child: Transform.scale(scale: 0.93 + 0.07 * enter.value, child: child),
          ),
        ),
      );
    },
  );
  return res ?? false;
}

// ====================================================================================================== toasts
/// Mounted once above the Navigator. Enter: rises 24 px + fades (320 ms, ease-out). Exit: fades (160 ms).
class ToastHost extends StatelessWidget {
  const ToastHost({super.key, required this.child, this.bottomInset = 0});
  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final toasts = context.watch<ToastController>();
    return Stack(
      children: [
        child,
        Positioned(
          left: 16, right: 16, bottom: bottomInset + MediaQuery.viewPaddingOf(context).bottom + 12,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final t in toasts.items) _ToastView(key: ValueKey(t.id), item: t)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({super.key, required this.item});
  final ToastItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final ok = item.kind == ToastKind.ok;
    final reduce = context.reduceMotion;
    return AnimatedSlide(
      offset: item.open || reduce ? Offset.zero : const Offset(0, 0.6),
      duration: item.open ? const Duration(milliseconds: 360) : const Duration(milliseconds: 160),
      curve: Motion.out,
      child: AnimatedScale(
        scale: item.open || reduce ? 1 : 0.94,
        duration: item.open ? const Duration(milliseconds: 360) : const Duration(milliseconds: 160),
        curve: Motion.out,
        child: AnimatedOpacity(
        opacity: item.open ? 1 : 0,
        duration: item.open ? Motion.moderate : const Duration(milliseconds: 160),
        curve: Motion.out,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Semantics(
            liveRegion: true, container: true, label: '${item.title}. ${item.description ?? ''}',
            child: Neu(
              radius: 22, raised: Elev.md, padding: const EdgeInsets.fromLTRB(14, 12, 16, 12), constraints: const BoxConstraints(maxWidth: 420),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(color: ok ? c.ok : c.err, shape: BoxShape.circle), child: AcIcon(ok ? 'check' : 'info', size: 18, color: Colors.white, strokeWidth: 3)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Tx.label(14, Tx.w7, c.ink)),
                        if (item.description != null) Text(item.description!, style: Tx.label(12, Tx.w5, c.ink2)),
                      ],
                    ),
                  ),
                  if (item.actionLabel != null) ...[
                    const SizedBox(width: 12),
                    NeuPressable(
                      radius: 12, minSize: 44, label: item.actionLabel, haptic: Haptic.light,
                      onTap: () {
                        item.onAction?.call();
                        context.read<ToastController>().dismiss(item.id);
                      },
                      builder: (_, t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(item.actionLabel!, style: Tx.label(14, Tx.w8, c.accent))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
