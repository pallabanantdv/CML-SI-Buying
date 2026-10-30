import 'package:flutter/material.dart';

/// Preserves each shell navigator while animating the active branch change.
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
  static const _duration = Duration(milliseconds: 280);

  late final AnimationController _controller;
  late final Animation<double> _progress;
  late int _activeIndex;
  int? _previousIndex;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;

    _previousIndex = _activeIndex;
    _activeIndex = widget.currentIndex;
    if (_reduceMotion) {
      _previousIndex = null;
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      setState(() => _previousIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          _buildBranch(index),
      ],
    ),
  );

  Widget _buildBranch(int index) {
    final isActive = index == _activeIndex;
    final isPrevious = index == _previousIndex && !isActive;
    final isVisible = isActive || isPrevious;
    final child = TickerMode(enabled: isActive, child: widget.children[index]);

    if (!isVisible) return Offstage(offstage: true, child: child);
    if (isPrevious) {
      final exitSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.025, 0),
      ).animate(_progress);
      return FadeTransition(
        opacity: ReverseAnimation(_progress),
        child: SlideTransition(position: exitSlide, child: child),
      );
    }

    final enterSlide = Tween<Offset>(
      begin: const Offset(0.025, 0),
      end: Offset.zero,
    ).animate(_progress);
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(position: enterSlide, child: child),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }
}
