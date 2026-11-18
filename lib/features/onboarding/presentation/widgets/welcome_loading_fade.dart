import 'package:flutter/material.dart';

class WelcomeLoadingFade extends StatefulWidget {
  const WelcomeLoadingFade({super.key, required this.child});

  final Widget child;

  @override
  State<WelcomeLoadingFade> createState() => _WelcomeLoadingFadeState();
}

class _WelcomeLoadingFadeState extends State<WelcomeLoadingFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = _controller
      .drive(CurveTween(curve: Curves.easeInOut))
      .drive(Tween<double>(begin: 1, end: 0.45));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: RepaintBoundary(child: widget.child),
  );
}
