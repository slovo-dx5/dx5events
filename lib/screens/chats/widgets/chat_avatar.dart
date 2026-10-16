import 'package:flutter/material.dart';

import '../../../constants.dart';

/// Initials avatar for a chat partner. The colour is derived from the name so
/// it stays stable across rebuilds.
class ChatInitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const ChatInitialsAvatar({super.key, required this.name, this.radius = 18});

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = predefinedColors;
    final color = colors.isEmpty
        ? kPrimaryColor
        : colors[name.trim().toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b) % colors.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
