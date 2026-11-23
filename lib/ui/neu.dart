import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/tokens.dart';
import 'icons.dart';

/// (offset, blur) pair — the same numbers as the Figma elevation styles.
typedef Sh = (double, double);

abstract final class Elev {
  static const Sh xs = (3, 6), sm = (4, 8), btn = (5, 10), md = (6, 12), base = (8, 16), card = (10, 22), lg = (14, 28);
  static const Sh iXs = (2, 4), iSm = (3, 6), iMd = (4, 8), iDeep = (6, 12), iLg = (8, 16);
}

List<BoxShadow> raisedShadows(AcColors c, Sh e, [double k = 1]) {
  final d = e.$1 * k, b = e.$2 * k;
  return [
    BoxShadow(color: c.shLight, offset: Offset(-d, -d), blurRadius: b),
    BoxShadow(color: c.shDark, offset: Offset(d, d), blurRadius: b),
  ];
}

/// Purple glow under the primary button.
List<BoxShadow> glowShadows(AcColors c) => [
      BoxShadow(color: c.shLight, offset: const Offset(-6, -6), blurRadius: 12),
      BoxShadow(color: c.dark ? const Color(0x990A0628) : const Color(0x705B3BE0), offset: const Offset(6, 10), blurRadius: 20),
    ];

/// Flutter has no inset shadows, so draw them: blur the "frame" around the shape, clipped to the shape.
class InsetPainter extends CustomPainter {
  InsetPainter({required this.radius, required this.e, required this.dark, required this.light, this.opacity = 1});
  final double radius;
  final Sh e;
  final Color dark, light;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final (d, b) = e;
    canvas.save();
    canvas.clipRRect(rrect);
    void cast(Offset off, Color col) {
      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rrect.outerRect.inflate(b * 2 + d * 2 + 4))
        ..addRRect(rrect.shift(off));
      canvas.drawPath(path, Paint()..color = col.withValues(alpha: col.a * opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, b / 2));
    }

    cast(Offset(d, d), dark);
    cast(Offset(-d, -d), light);
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetPainter o) => o.radius != radius || o.e != e || o.dark != dark || o.light != light || o.opacity != opacity;
}

/// The neumorphic surface. `raised` = outer shadow pair, `inset` = inner shadow pair.
/// With both (or a glow + inset) it is pressable: `t` 0 → raised, 1 → inset, cross-faded.
class Neu extends StatelessWidget {
  const Neu({
    super.key, this.radius = R.r24, this.raised, this.inset, this.t = 0, this.color, this.gradient, this.padding, this.child, this.width, this.height,
    this.glow = const [], this.insetDark, this.insetLight, this.border, this.alignment, this.clip = false, this.constraints,
  });
  final double radius;
  final Sh? raised, inset;
  final double t;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final Widget? child;
  final double? width, height;
  final List<BoxShadow> glow;
  final Color? insetDark, insetLight;
  final BoxBorder? border;
  final AlignmentGeometry? alignment;
  final bool clip;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final pressable = inset != null && (raised != null || glow.isNotEmpty);
    final k = pressable ? 1 - t : 1.0;
    final shadows = <BoxShadow>[
      if (raised != null && k > 0) ...raisedShadows(c, raised!, k),
      for (final g in glow) k >= 1 ? g : g.scale(k),
    ];
    final insetOpacity = inset == null ? 0.0 : (pressable ? t : 1.0);

    Widget content = child ?? const SizedBox.shrink();
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (alignment != null) content = Align(alignment: alignment!, child: content);
    if (clip) content = ClipRRect(borderRadius: BorderRadius.circular(radius), child: content);
    if (inset != null) {
      content = CustomPaint(
        painter: InsetPainter(radius: radius, e: inset!, dark: insetDark ?? c.shInset, light: insetLight ?? c.shLight, opacity: insetOpacity),
        child: content,
      );
    }
    Widget w = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows.isEmpty ? null : shadows,
        border: border,
      ),
      child: content,
    );
    if (width != null || height != null || constraints != null) {
      w = ConstrainedBox(
        constraints: (constraints ?? const BoxConstraints()).tighten(width: width, height: height),
        child: w,
      );
    }
    return w;
  }
}

enum Haptic { none, selection, light, medium, heavy }

void haptic(Haptic h) {
  switch (h) {
    case Haptic.none:
      break;
    case Haptic.selection:
      HapticFeedback.selectionClick();
    case Haptic.light:
      HapticFeedback.lightImpact();
    case Haptic.medium:
      HapticFeedback.mediumImpact();
    case Haptic.heavy:
      HapticFeedback.heavyImpact();
  }
}

/// Press feedback shared by every tappable thing: scale 0.98 (80 ms down, 120 ms up), raised → inset via `t`,
/// a visible focus ring for keyboard / switch-access users, semantics, and an optional haptic tick.
class NeuPressable extends StatefulWidget {
  const NeuPressable({
    super.key, required this.builder, this.onTap, this.onLongPress, this.label, this.radius = R.r20, this.scaleDown = 0.98, this.haptic = Haptic.selection,
    this.selected, this.minSize = 0, this.isButton = true, this.hint,
  });
  final Widget Function(BuildContext context, double t) builder;
  final VoidCallback? onTap, onLongPress;
  final String? label, hint;
  final double radius, scaleDown, minSize;
  final Haptic haptic;
  final bool? selected;
  final bool isButton;

  @override
  State<NeuPressable> createState() => _NeuPressableState();
}

class _NeuPressableState extends State<NeuPressable> {
  bool _down = false, _focus = false;

  void _set(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_down != v) setState(() => _down = v);
  }

  void _tap() {
    haptic(widget.haptic);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduce = context.reduceMotion;
    Widget body = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _down ? 1 : 0),
      duration: reduce ? Duration.zero : (_down ? Motion.press : Motion.fast),
      curve: Motion.out,
      builder: (ctx, t, _) {
        final inner = widget.builder(ctx, t);
        return Transform.scale(
          scale: reduce ? 1 : 1 - (1 - widget.scaleDown) * t,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              inner,
              if (_focus)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.radius),
                        border: Border.all(color: ctx.ac.dark ? P.p300 : P.p500, width: 2),
                        boxShadow: [BoxShadow(color: (ctx.ac.dark ? P.p300 : P.p500).withValues(alpha: 0.33), spreadRadius: 4)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null ? null : _tap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              haptic(Haptic.light);
              widget.onLongPress!();
            },
      child: body,
    );
    body = FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
        _tap();
        return null;
      })},
      child: body,
    );
    if (widget.minSize > 0) {
      body = ConstrainedBox(constraints: BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize), child: Center(widthFactor: 1, heightFactor: 1, child: body));
    }
    return Semantics(
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      hint: widget.hint,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- spinner

class AcSpinner extends StatefulWidget {
  const AcSpinner({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  State<AcSpinner> createState() => _AcSpinnerState();
}

class _AcSpinnerState extends State<AcSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? context.ac.accent;
    return Semantics(
      label: 'Loading',
      child: RotationTransition(turns: _c, child: CustomPaint(size: Size.square(widget.size), painter: _SpinnerPainter(col))),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.125;
    final rect = Offset(sw / 2, sw / 2) & Size(size.width - sw, size.height - sw);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = color.withValues(alpha: 0.3));
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, p..color = color);
  }

  @override
  bool shouldRepaint(_SpinnerPainter o) => o.color != color;
}

// ---------------------------------------------------------------------------------------------------------------- buttons

enum BtnKind { primary, secondary, ghost }
enum BtnSize { sm, md, lg }

class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key, required this.label, this.onPressed, this.kind = BtnKind.primary, this.size = BtnSize.md, this.icon, this.iconRight = false,
    this.loading = false, this.loadingLabel = 'Calculating…', this.block = false, this.haptic = Haptic.light, this.semanticsLabel, this.danger = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final BtnSize size;
  final String? icon;
  final bool iconRight, loading, block, danger;
  final String loadingLabel;
  final Haptic haptic;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final disabled = onPressed == null && !loading;
    final (padV, padH, minH, fs, r, gap, isz) = switch (size) {
      BtnSize.sm => (10.0, 18.0, 40.0, 13.0, 14.0, 8.0, 18.0),
      BtnSize.md => (15.0, 26.0, 50.0, 15.0, 18.0, 10.0, 20.0),
      BtnSize.lg => (18.0, 32.0, 60.0, 16.0, 18.0, 10.0, 22.0),
    };
    final isPrimary = kind == BtnKind.primary;
    final fg = disabled ? c.ink3 : (isPrimary ? Colors.white : (danger ? c.err : (kind == BtnKind.ghost ? c.accent : c.accentStrong)));

    Widget row(String text, {bool spinner = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (spinner) AcSpinner(size: isz, color: fg) else if (icon != null && !iconRight) AcIcon(icon!, size: isz, color: fg),
            if (spinner || icon != null && !iconRight) SizedBox(width: gap),
            Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.label(fs, Tx.w7, fg))),
            if (!spinner && icon != null && iconRight) SizedBox(width: gap),
            if (!spinner && icon != null && iconRight) AcIcon(icon!, size: isz, color: fg),
          ],
        );

    return NeuPressable(
      radius: r,
      haptic: haptic,
      label: semanticsLabel ?? (loading ? loadingLabel : label),
      onTap: loading || disabled ? null : onPressed,
      builder: (ctx, t) {
        // both labels share one cell: the button never changes width while loading
        final content = Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: loading ? 0 : 1, child: row(label)),
            if (loading) row(loadingLabel, spinner: true),
          ],
        );
        final padding = EdgeInsets.symmetric(vertical: padV, horizontal: padH);
        Widget btn;
        if (isPrimary && !disabled) {
          btn = Neu(
            radius: r, constraints: BoxConstraints(minHeight: minH), padding: padding,
            gradient: LinearGradient.lerp(P.gradient, P.gradientPress, t)!,
            glow: glowShadows(c), inset: Elev.iMd, t: t,
            insetDark: const Color(0xAB2A1869), insetLight: const Color(0x30FFFFFF),
            child: content,
          );
        } else if (kind == BtnKind.ghost) {
          btn = Neu(
            radius: r, constraints: BoxConstraints(minHeight: minH), padding: padding,
            color: c.accentSoft.withValues(alpha: t), child: content,
          );
        } else if (disabled) {
          btn = Neu(radius: r, constraints: BoxConstraints(minHeight: minH), padding: padding, inset: Elev.iXs, child: content);
        } else {
          btn = Neu(radius: r, constraints: BoxConstraints(minHeight: minH), padding: padding, raised: Elev.btn, inset: Elev.iMd, t: t, child: content);
        }
        btn = Opacity(opacity: disabled ? 0.7 : 1, child: btn);
        return block ? SizedBox(width: double.infinity, child: btn) : btn;
      },
    );
  }
}

class NeuIconButton extends StatelessWidget {
  const NeuIconButton({super.key, required this.icon, required this.label, this.onPressed, this.size = 48, this.active = false, this.color, this.dot = false, this.small = false, this.haptic = Haptic.selection});
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool active, dot, small;
  final Color? color;
  final Haptic haptic;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final disabled = onPressed == null;
    return NeuPressable(
      radius: size / 2, scaleDown: 0.96, minSize: 44, haptic: haptic, label: label, selected: active ? true : null, onTap: onPressed,
      builder: (ctx, t) {
        final col = disabled ? c.ink3 : (color ?? (active ? c.accent : c.ink2));
        return Opacity(
          opacity: disabled ? 0.6 : 1,
          child: SizedBox(
            width: size, height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Neu(
                  radius: size / 2, width: size, height: size,
                  raised: small ? Elev.xs : Elev.btn, inset: active ? Elev.iMd : (small ? Elev.iSm : Elev.iMd), t: active ? 1 : t,
                  child: Center(child: AcIcon(icon, size: size < 44 ? 20 : 24, color: col)),
                ),
                if (dot)
                  Positioned(
                    top: size * 0.19, right: size * 0.23,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(gradient: P.gradient, shape: BoxShape.circle, border: Border.all(color: c.surface, width: 2)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NeuChip extends StatelessWidget {
  const NeuChip({super.key, required this.label, this.active = false, this.icon, this.onTap, this.toggle = false});
  final String label;
  final bool active, toggle;
  final String? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final disabled = onTap == null;
    return NeuPressable(
      radius: 999, scaleDown: 0.97, minSize: 44, label: label, selected: toggle ? active : null, onTap: onTap,
      builder: (ctx, t) {
        final fg = disabled ? c.ink3 : (active ? Colors.white : c.accentStrong);
        final inner = Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[AcIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
          Text(label, style: Tx.label(13, Tx.w7, fg)),
        ]);
        const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 9);
        return Opacity(
          opacity: disabled ? 0.55 : 1,
          child: active
              ? Neu(radius: 999, padding: pad, gradient: P.gradient, glow: glowShadows(c), child: inner)
              : Neu(radius: 999, padding: pad, raised: Elev.xs, inset: Elev.iSm, t: t, child: inner),
        );
      },
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.accent = false});
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return DecoratedBox(
      decoration: BoxDecoration(color: accent ? null : c.accentSoft, gradient: accent ? P.gradient : null, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(label.toUpperCase(), style: Tx.label(11, Tx.w7, accent ? Colors.white : c.accent, 0.06)),
      ),
    );
  }
}

class AcAvatar extends StatelessWidget {
  const AcAvatar(this.name, {super.key, this.size = 44});
  final String name;
  final double size;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    String first(String w) => String.fromCharCode(w.runes.first);
    final a = first(parts.first);
    final b = parts.length > 1 ? first(parts.last) : (parts.first.runes.length > 1 ? String.fromCharCode(parts.first.runes.elementAt(1)) : '');
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: BoxDecoration(gradient: P.gradient, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x545B3BE0), offset: Offset(0, 4), blurRadius: 8)]),
        child: Text(initials(name), style: Tx.label(size * 0.34, Tx.w8, Colors.white, 0.01)),
      ),
    );
  }
}

/// Inset "well" holding an icon.
class Well extends StatelessWidget {
  const Well({super.key, required this.icon, this.size = 38, this.iconSize = 20, this.color, this.filled = false});
  final String icon;
  final double size, iconSize;
  final Color? color;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    if (filled) {
      return Container(width: size, height: size, alignment: Alignment.center, decoration: BoxDecoration(gradient: P.gradient, borderRadius: BorderRadius.circular(size * 0.34)), child: AcIcon(icon, size: iconSize, color: Colors.white));
    }
    return Neu(radius: size * 0.34, width: size, height: size, inset: Elev.iSm, child: Center(child: AcIcon(icon, size: iconSize, color: color ?? c.accent)));
  }
}

class NeuCard extends StatelessWidget {
  const NeuCard({super.key, this.child, this.padding = const EdgeInsets.all(20), this.radius = R.r28, this.raised = Elev.base, this.semanticsLabel});
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Sh raised;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) {
    final w = Neu(radius: radius, raised: raised, padding: padding, child: child);
    return semanticsLabel == null ? w : Semantics(container: true, label: semanticsLabel, child: w);
  }
}

// ---------------------------------------------------------------------------------------------------------------- toggle

class NeuToggle extends StatefulWidget {
  const NeuToggle({super.key, required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  @override
  State<NeuToggle> createState() => _NeuToggleState();
}

class _NeuToggleState extends State<NeuToggle> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final on = widget.value;
    final enabled = widget.onChanged != null;
    final d = Motion.of(context, Motion.base);
    final thumbW = _down ? 30.0 : 24.0;
    return Semantics(
      toggled: on, enabled: enabled, label: widget.label, onTap: enabled ? () => widget.onChanged!(!on) : null,
      child: FocusableActionDetector(
        enabled: enabled,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onChanged?.call(!on);
          return null;
        })},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: enabled ? () { haptic(Haptic.selection); widget.onChanged!(!on); } : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: SizedBox(
              width: 56, height: 44,
              child: Center(
                child: SizedBox(
                  width: 56, height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Neu(radius: 16, width: 56, height: 32, inset: Elev.iSm),
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: on ? 1 : 0, duration: d, curve: Motion.out,
                          child: Neu(radius: 16, gradient: P.gradient, inset: Elev.iSm, insetDark: const Color(0x552A1869), insetLight: const Color(0x22FFFFFF)),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: d, curve: Motion.out, top: 4, left: on ? 56 - 4 - thumbW : 4, width: thumbW, height: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: P.gradEnd.withValues(alpha: 0.33), offset: const Offset(0, 3), blurRadius: 6)]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------- segmented

class NeuSegmented<V> extends StatelessWidget {
  const NeuSegmented({super.key, required this.value, required this.items, required this.onChanged, this.label});
  final V value;
  final List<(V, String)> items;
  final ValueChanged<V> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    final idx = items.indexWhereValue(value);
    final n = items.length;
    return Semantics(
      container: true, label: label,
      child: Neu(
        radius: 20, inset: Elev.iMd, padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: Motion.of(context, Motion.base), curve: Motion.out,
                alignment: Alignment(n == 1 ? 0 : -1 + 2 * idx / (n - 1), 0),
                child: FractionallySizedBox(widthFactor: 1 / n, child: Neu(radius: 15, raised: Elev.sm, height: 44)),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true, selected: i == idx, label: items[i].$2, onTap: () => onChanged(items[i].$1),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () { if (i != idx) haptic(Haptic.selection); onChanged(items[i].$1); },
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.of(context, Motion.base), curve: Motion.out,
                              style: Tx.label(13, Tx.w7, i == idx ? c.accent : c.ink3),
                              child: Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis),
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

extension _IndexWhereValue<V> on List<(V, String)> {
  int indexWhereValue(V v) {
    final i = indexWhere((e) => e.$1 == v);
    return i < 0 ? 0 : i;
  }
}

// ---------------------------------------------------------------------------------------------------------------- skeleton

/// One shimmer for a whole subtree: bones are flat boxes, the highlight sweeps across all of them (1400 ms, linear).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.p);
  final double p;
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * p, 0, 0);
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _started = false;
    } else if (!_started) {
      _c.repeat();
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hi = context.ac.skeletonHi;
    return Semantics(
      label: 'Loading page', container: true,
      child: AnimatedBuilder(
        animation: _c,
        child: ExcludeSemantics(child: widget.child),
        builder: (ctx, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            colors: [hi.withValues(alpha: 0), hi.withValues(alpha: 0.7), hi.withValues(alpha: 0)],
            stops: const [0.0, 0.5, 1.0],
            transform: _SlideGradient(_c.value * 2 - 1),
          ).createShader(rect),
          child: child,
        ),
      ),
    );
  }
}

class Bone extends StatelessWidget {
  const Bone({super.key, this.w, this.h = 14, this.r = 8, this.circle = false});
  final double? w;
  final double h, r;
  final bool circle;
  @override
  Widget build(BuildContext context) => Container(
        width: w, height: h,
        decoration: BoxDecoration(color: context.ac.skeleton, borderRadius: circle ? null : BorderRadius.circular(r), shape: circle ? BoxShape.circle : BoxShape.rectangle),
      );
}

// ---------------------------------------------------------------------------------------------------------------- stagger

/// Entrance: fade + rise 12 px, `index` × 40 ms apart (max 6), 480 ms ease-out. Plays once.
class Stagger extends StatefulWidget {
  const Stagger({super.key, required this.index, required this.child, this.rise = 12});
  final int index;
  final double rise;
  final Widget child;
  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * math.min(widget.index, 6)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: Motion.out);
    return FadeTransition(
      opacity: a,
      child: AnimatedBuilder(animation: a, child: widget.child, builder: (_, child) => Transform.translate(offset: Offset(0, widget.rise * (1 - a.value)), child: child)),
    );
  }
}
