import 'package:flutter/material.dart';

import '../../core/navigation/app_transition_config.dart';

/// Branch navigators stay mounted; only the active branch paints or accepts input.
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });
  final int currentIndex;
  final List<Widget> children;
  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTransitionConfig.bottomNavigation,
    value: 1,
  );
  late final Animation<double> _opacity = _controller
      .drive(CurveTween(curve: AppTransitionConfig.curve))
      .drive(Tween(begin: AppTransitionConfig.initialTabOpacity, end: 1.0));
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    if (_reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var index = 0; index < widget.children.length; index++)
        Offstage(
          offstage: index != widget.currentIndex,
          child: TickerMode(
            enabled: index == widget.currentIndex,
            child: IgnorePointer(
              ignoring: index != widget.currentIndex,
              child: ExcludeFocus(
                excluding: index != widget.currentIndex,
                child: FadeTransition(
                  opacity: _opacity,
                  child: RepaintBoundary(child: widget.children[index]),
                ),
              ),
            ),
          ),
        ),
    ],
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
