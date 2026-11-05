import 'package:flutter/material.dart';

/// One clock per loading section. Placeholder painters repaint without rebuilding.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({
    super.key,
    required this.child,
    this.label = 'Loading',
    this.enabled = true,
    this.placeholdersOnly = true,
  });
  final bool placeholdersOnly;
  final bool enabled;
  final Widget child;
  final String label;
  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.enabled ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SkeletonShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled &&
          !MediaQuery.disableAnimationsOf(context) &&
          TickerMode.valuesOf(context).enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _SkeletonClock(animation: _controller, child: widget.child);
    return Semantics(
      container: true,
      liveRegion: widget.enabled,
      label: widget.enabled ? widget.label : null,
      child: widget.placeholdersOnly && widget.enabled
          ? ExcludeSemantics(child: IgnorePointer(child: content))
          : content,
    );
  }
}

class _SkeletonClock extends InheritedWidget {
  const _SkeletonClock({required this.animation, required super.child});
  final Animation<double> animation;
  @override
  bool updateShouldNotify(_SkeletonClock oldWidget) =>
      animation != oldWidget.animation;
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.shape = BoxShape.rectangle,
  });
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final BoxShape shape;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animation = context
        .dependOnInheritedWidgetOfExactType<_SkeletonClock>()
        ?.animation;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SkeletonPainter(
          animation,
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.09),
            scheme.surface,
          ),
          Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.035),
            scheme.surface,
          ),
          borderRadius,
          shape,
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(
    this.animation,
    this.base,
    this.highlight,
    this.radius,
    this.shape,
  ) : super(repaint: animation);
  final Animation<double>? animation;
  final Color base;
  final Color highlight;
  final BorderRadius radius;
  final BoxShape shape;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final progress = animation?.value ?? 0.5;
    final center = -2 + progress * 4;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(center - 1, 0),
        end: Alignment(center + 1, 0),
        colors: [base, highlight, base],
        stops: const [0.15, 0.5, 0.85],
      ).createShader(rect);
    if (shape == BoxShape.circle) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRRect(radius.toRRect(rect), paint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      animation != oldDelegate.animation ||
      base != oldDelegate.base ||
      highlight != oldDelegate.highlight ||
      radius != oldDelegate.radius ||
      shape != oldDelegate.shape;
}
