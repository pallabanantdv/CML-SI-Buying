import '../widgets/app_svg_icon.dart';

class BottomNavigationItem {
  const BottomNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final AppIconName icon;
  final AppIconName selectedIcon;
}
