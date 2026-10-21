import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand.dart';

/// A single cold-launch sequence. Keeping this above the Navigator means that
/// page changes, theme toggles and resuming the app do not restart the intro.
class PaydayOpening extends StatefulWidget {
  const PaydayOpening({super.key, required this.child});
  final Widget child;
  static const duration = Duration(seconds: 2);

  @override
  State<PaydayOpening> createState() => _PaydayOpeningState();
}

class _PaydayOpeningState extends State<PaydayOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PaydayOpening.duration,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });
  bool _started = false;
  bool _finished = false;
  bool _reduced = false;
  static final _icon = MemoryImage(base64Decode(paydayIconBase64));

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double phase(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);
  double smooth(double t, double start, double end) =>
      Curves.easeOutCubic.transform(phase(t, start, end));

  /// Crop the original full lockup instead of retyping its custom wordmark,
  /// gold triangle or slogan. Both themes use the approved source artwork.
  Widget brandPart(ImageProvider image, {required bool slogan}) => SizedBox(
    width: 220,
    height: slogan ? 24 : 44,
    child: ClipRect(child: OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 330, maxWidth: 330, minHeight: 102, maxHeight: 102,
      child: Transform.translate(
        offset: Offset(-103, slogan ? -72 : -26),
        child: Image(image: image, width: 330, height: 102,
          fit: BoxFit.fill, filterQuality: FilterQuality.high,
          excludeFromSemantics: true),
      ),
    )),
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final image = dark ? PaydayBrand.dark : PaydayBrand.light;
    final teal = dark ? const Color(0xff62D5C9) : const Color(0xff087F7C);
    return AnimatedBuilder(animation: _controller, builder: (context, _) {
      final t = _controller.value;
      final exit = _reduced ? t : phase(t, .79, 1);
      final homeReveal = Curves.easeInOutCubic.transform(exit);
      final icon = smooth(t, 0, .33);
      final word = smooth(t, .13, .46);
      final slogan = smooth(t, .34, .59);
      final pulse = phase(t, 0, .85);
      final pulseOpacity = _reduced ? 0.0 : math.sin(math.pi * pulse);
      final glint = phase(t, .325, .65);
      return Stack(fit: StackFit.expand, children: [
        IgnorePointer(ignoring: !_finished,
          child: ExcludeSemantics(excluding: !_finished, child: Opacity(opacity: homeReveal,
            child: Transform.translate(
              offset: Offset(0, _reduced ? 0 : 7 * (1 - homeReveal)),
              child: widget.child,
            ),
          )),
        ),
        if (!_finished) Positioned.fill(child: AbsorbPointer(child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Opacity(opacity: 1 - homeReveal,
            child: Material(key: const ValueKey('payday-opening-overlay'), color: background,
              child: Semantics(label: 'PAYDAY. Every dirham, in control.',
                child: ExcludeSemantics(child: Center(child: Stack(
                  alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    if (!_reduced) Transform.translate(
                      offset: const Offset(0, -25),
                      child: Opacity(opacity: pulseOpacity,
                        child: Transform.scale(scale: .6 + .55 * pulse,
                          child: SizedBox(width: 280, height: 280,
                            child: Stack(alignment: Alignment.center, children: [
                              DecoratedBox(decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  teal.withValues(alpha: dark ? .23 : .21),
                                  teal.withValues(alpha: dark ? .16 : .15),
                                  teal.withValues(alpha: .08),
                                  teal.withValues(alpha: 0),
                                ], stops: const [0, .28, .45, .7]),
                              ), child: const SizedBox.expand()),
                              Container(width: 220, height: 220,
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                  border: Border.all(width: 1.5,
                                    color: teal.withValues(alpha: dark ? .28 : .22)))),
                              Container(width: 262, height: 262,
                                decoration: BoxDecoration(shape: BoxShape.circle,
                                  border: Border.all(width: 1,
                                    color: teal.withValues(alpha: dark ? .13 : .08)))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -11 - (_reduced ? 0 : 8 * homeReveal)),
                      child: SizedBox(width: 250, child: Column(
                        mainAxisSize: MainAxisSize.min, children: [
                          Opacity(opacity: _reduced ? 1 : icon,
                            child: Transform.translate(
                              offset: Offset(0, _reduced ? 0 : 13 * (1-icon) - 2 * math.sin(math.pi*icon)),
                              child: Transform.rotate(angle: _reduced ? 0 : -.05236 * (1-icon),
                                child: Transform.scale(scale: _reduced ? 1 : .92 + .08 * icon + .018 * math.sin(math.pi*icon),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(25),
                                    child: Image(image: _icon, width: 112, height: 112,
                                      filterQuality: FilterQuality.high)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Opacity(opacity: _reduced ? 1 : word,
                            child: Transform.translate(offset: Offset(0, _reduced ? 0 : 5 * (1-word)),
                              child: ClipRect(clipper: _WordReveal(_reduced ? 1 : word),
                                child: Stack(children: [
                                  brandPart(image, slogan: false),
                                  if (!_reduced && glint > 0 && glint < 1)
                                    Opacity(opacity: .4 * math.sin(math.pi*glint),
                                      child: ShaderMask(blendMode: BlendMode.srcIn,
                                        shaderCallback: (rect) => LinearGradient(
                                          begin: Alignment(-3+6*glint, -1),
                                          end: Alignment(-1+6*glint, 1),
                                          colors: const [Colors.transparent, Color(0xffF0CA94), Colors.white, Colors.transparent],
                                          stops: const [0, .35, .5, 1],
                                        ).createShader(rect),
                                        child: brandPart(image, slogan: false),
                                      ),
                                    ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Opacity(opacity: _reduced ? 1 : slogan,
                            child: Transform.translate(
                              offset: Offset(0, _reduced ? 0 : 5*(1-slogan)),
                              child: brandPart(image, slogan: true),
                            ),
                          ),
                        ],
                      )),
                    ),
                  ],
                ))),
              ),
            ),
          ),
        ))),
      ]);
    });
  }
}

class _WordReveal extends CustomClipper<Rect> {
  const _WordReveal(this.progress);
  final double progress;
  @override Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width*progress, size.height);
  @override bool shouldReclip(_WordReveal oldClipper) => oldClipper.progress != progress;
}
