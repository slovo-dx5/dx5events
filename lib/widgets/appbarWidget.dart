import 'package:flutter/material.dart';

import '../constants.dart';
class AppBarWithGradient extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  final Color gradientBegin;
  final Color gradientEnd;

  const AppBarWithGradient({
    required this.title,
    required this.gradientBegin,
    required this.gradientEnd,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:   BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            gradientBegin, // Left side color
            gradientEnd, // Right side color
          ],
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent, // Make the AppBar transparent
        elevation: 0, // Remove shadow
        title: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Text(title),
        ),
        centerTitle: true,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Default AppBar height
}