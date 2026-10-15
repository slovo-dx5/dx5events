import 'package:flutter/material.dart';

import '../../../widgets/profile_initials_widget.dart';

/// Round avatar for an inbox row: the person's photo when known, with their
/// initials underneath as the placeholder / fallback.
class InboxAvatar extends StatelessWidget {
  final String name;
  final String? photoId;
  final double size;

  const InboxAvatar({super.key, required this.name, this.photoId, this.size = 52});

  static const _palette = <Color>[
    Color(0xFF44A0D3),
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFFD81B60),
    Color(0xFF5C6BC0),
  ];

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    if (parts.length == 1) return first;
    return first + parts.last.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.36,
        ),
      ),
    );
    final photo = photoId;
    if (photo == null) return initials;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          initials,
          ClipOval(
            child: FittedBox(
              fit: BoxFit.cover,
              child: AttendeeProfilePicWidget(profileID: photo),
            ),
          ),
        ],
      ),
    );
  }
}
