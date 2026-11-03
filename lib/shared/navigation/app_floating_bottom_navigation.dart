import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../widgets/app_svg_icon.dart';
import 'bottom_navigation_item.dart';

/// Reference-inspired orbit silhouette. Routing belongs to the shell adapter.
class AppFloatingBottomNavigation extends StatelessWidget {
  const AppFloatingBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCreatePurchase,
  }) : assert(items.length == 4),
       assert(selectedIndex >= 0 && selectedIndex < items.length);

  final List<BottomNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCreatePurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: scheme.surface,
          elevation: 5,
          shadowColor: scheme.shadow.withValues(alpha: 0.18),
          shape: const _OrbitNavigationShape(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var index = 0; index < 2; index++)
                  Expanded(child: _destination(context, index, duration)),
                SizedBox(
                  width: 80,
                  child: Center(
                    child: Semantics(
                      container: true,
                      button: true,
                      label: 'New purchase',
                      onTap: onCreatePurchase,
                      child: ExcludeSemantics(
                        child: Tooltip(
                          message: 'New purchase',
                          child: Material(
                            color: scheme.primary,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onCreatePurchase,
                              child: SizedBox.square(
                                dimension: 56,
                                child: Center(
                                  child: AppSvgIcon(
                                    icon: AppIconName.add,
                                    size: 28,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (var index = 2; index < items.length; index++)
                  Expanded(child: _destination(context, index, duration)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int index, Duration duration) {
    final item = items[index];
    final selected = selectedIndex == index;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : context.appColors.textSecondary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      onTap: () => onDestinationSelected(index),
      child: ExcludeSemantics(
        child: Tooltip(
          message: item.label,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => onDestinationSelected(index),
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TweenAnimationBuilder<Color?>(
                      duration: duration,
                      tween: ColorTween(end: color),
                      builder: (context, value, _) => AppSvgIcon(
                        icon: selected ? item.selectedIcon : item.icon,
                        size: 23,
                        color: value,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? color : color.withValues(alpha: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two capsules blend through curved necks into the central action's orbit.
class _OrbitNavigationShape extends ShapeBorder {
  const _OrbitNavigationShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final c = rect.width / 2;
    final w = rect.width;
    return (Path()
          ..moveTo(31, 3)
          ..lineTo(c - 46, 3)
          ..cubicTo(c - 39, 3, c - 37, 15, c - 29, 16)
          ..arcToPoint(Offset(c + 29, 16), radius: const Radius.circular(34))
          ..cubicTo(c + 37, 15, c + 39, 3, c + 46, 3)
          ..lineTo(w - 31, 3)
          ..arcToPoint(Offset(w - 31, 65), radius: const Radius.circular(31))
          ..lineTo(c + 46, 65)
          ..cubicTo(c + 39, 65, c + 37, 53, c + 29, 52)
          ..arcToPoint(Offset(c - 29, 52), radius: const Radius.circular(34))
          ..cubicTo(c - 37, 53, c - 39, 65, c - 46, 65)
          ..lineTo(31, 65)
          ..arcToPoint(const Offset(31, 3), radius: const Radius.circular(31))
          ..close())
        .shift(rect.topLeft);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
}
