import 'package:flutter/material.dart';

class AppHeaderTitle extends StatelessWidget {
  const AppHeaderTitle({super.key, required this.title});

  final String title;

  static const _logoAsset = 'assets/images/CAML Logo.jpg.jpeg';

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          _logoAsset,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
