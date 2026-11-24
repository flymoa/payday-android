import 'design_tokens.dart';
import 'localization.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand.dart';

/// One cold-launch sequence; navigating, changing theme or resuming never replays it.
class PaydayOpening extends StatefulWidget {
  const PaydayOpening({super.key, required this.child});
  final Widget child;
  static const duration = Duration(milliseconds: 1600);
  @override
  State<PaydayOpening> createState() => _PaydayOpeningState();
}

class _PaydayOpeningState extends State<PaydayOpening>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this, duration: PaydayOpening.duration,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });
  bool _started = false, _finished = false, _reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) _controller.duration = const Duration(milliseconds: 150);
    _controller.forward();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(animation: _controller, builder: (context, _) {
      final t = _finished ? 1.0 : _controller.value;
      final reveal = _reduced ? t : Curves.easeInOutCubic.transform(_phase(t, .85, 1));
      final text = _reduced ? 1.0 : _ease(_phase(t, .46, .74));
      return Stack(fit: StackFit.expand, children: [
        IgnorePointer(ignoring: !_finished,
          child: ExcludeSemantics(excluding: !_finished,
            child: Opacity(opacity: reveal, child: widget.child))),
        if (!_finished) Positioned.fill(child: AbsorbPointer(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark),
            child: Opacity(opacity: 1 - reveal,
              child: Material(key: const ValueKey('payday-opening-overlay'),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Semantics(label: 'Payday. ${tr(context,paydaySlogan)}',
                  child: ExcludeSemantics(child: Center(child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: SizedBox(width: 280, height: 276, child: Stack(children: [
                      Positioned(top: 0, left: 0, right: 0, height: 230,
                        child: RepaintBoundary(child: CustomPaint(
                          key: const ValueKey('payday-opening-mark'),
                          painter: PaydayOpeningPainter(progress: _reduced ? 1 : t, dark: dark)))),
                      Positioned(top: 198, left: 8, right: 8,
                        child: Opacity(opacity: text,
                          child: Transform.translate(offset: Offset(0, _reduced ? 0 : 8 * (1 - text)),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              LText('Payday', style: TextStyle(fontFamily: 'Bricolage',
                                fontSize: 35, fontWeight: FontWeight.w800, letterSpacing: -1.4,
                                color: dark ? paydaySand : paydayEmerald)),
                              const SizedBox(height: 8),
                              FittedBox(fit: BoxFit.scaleDown, child: LText(paydaySlogan,
                                maxLines: 1, style: TextStyle(fontFamily: 'DMSans', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: dark ? paydaySand : paydayEmerald))),
                            ])))),
                    ])),
                  )))),
              ),
            ),
          ),
        )),
      ]);
    });
  }
}

double _phase(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);
double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();

/// Matches the approved preview. At rest it uses exactly the launcher mark's geometry.
class PaydayOpeningPainter extends CustomPainter {
  const PaydayOpeningPainter({required this.progress, required this.dark});
  final double progress;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final appear = _ease(_phase(progress, 0, .34));
    final settle = _ease(_phase(progress, .12, .55));
    final dot = _phase(progress, .20, .62);
    final pulse = _phase(progress, .48, .88);
    canvas.save();
    canvas.scale(size.width / 280, size.height / 230);
    canvas.translate(140, 110 + 10 * (1 - appear));
    canvas.scale(.92 + .08 * appear);
    if (pulse > 0 && pulse < 1) {
      canvas.drawCircle(Offset.zero, 56 + 35 * pulse, Paint()
        ..style = PaintingStyle.stroke ..strokeWidth = 1
        ..color = (dark ? PaydayColors.darkOpeningMark : paydayEmerald)
          .withValues(alpha: .17 * math.sin(math.pi * pulse)));
    }
    canvas.rotate(-.035 * (1 - settle));
    canvas.scale(1.12);
    canvas.translate(-50, -50);
    canvas.saveLayer(const Rect.fromLTWH(-5, -5, 110, 110), Paint()..color = Colors.white.withValues(alpha: appear));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(paydayMarkCorner)), Paint()..color = paydayEmerald);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 100 * (1 - appear), 100, 100));
    final p = Paint()..color = paydaySand;
    canvas.drawRect(const Rect.fromLTWH(25, 19, 16, 62), p);
    canvas.drawPath(Path()..moveTo(25, 19)..lineTo(53, 19)..cubicTo(85, 19, 85, 63, 53, 63)..lineTo(25, 63)..close(), p);
    canvas.drawCircle(const Offset(52, 41), 7, Paint()..color = paydayEmerald);
    canvas.restore();
    if (progress > .20) {
      final eased = _ease(dot);
      final bounce = math.sin(dot * math.pi * 2) * math.pow(1 - dot, 2) * 7;
      final x = 88 + (57 - 88) * eased, y = 15 + (75.5 - 15) * eased - bounce;
      final width = 11 + 15 * _ease(_phase(dot, .60, 1));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - width / 2, y - 5.5, width, 11), const Radius.circular(5.5)),
        Paint()..color = paydaySaffron.withValues(alpha: _ease(_phase(progress, .20, .30))));
    }
    canvas.restore();
    canvas.restore();
  }
  @override
  bool shouldRepaint(PaydayOpeningPainter old) => old.progress != progress || old.dark != dark;
}

