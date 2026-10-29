import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.caption,
  });
  final IconData icon;
  final String title;
  final String value;
  final String? caption;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (caption != null)
            Text(caption!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
