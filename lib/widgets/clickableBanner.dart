import 'package:flutter/material.dart';
import 'dart:math';

import '../helpers/helper_functions.dart';

class ClickableBannerWidget extends StatefulWidget {
  final String assetPath;

  const ClickableBannerWidget({required this.assetPath, Key? key}) : super(key: key);

  @override
  _ClickableBannerWidgetState createState() => _ClickableBannerWidgetState();
}

class _ClickableBannerWidgetState extends State<ClickableBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 10).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_controller);

    // Repeatedly start shaking every 5 seconds
    Future.delayed(const Duration(seconds: 5), _startShaking);
  }

  void _startShaking() {
    if (mounted) {
      _controller.forward().then((_) {
        _controller.reverse();
      }).then((_) {
        Future.delayed(const Duration(seconds: 20), _startShaking);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openBannerURL();
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animation.value * (Random().nextBool() ? 1 : -1), 0),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            height: MediaQuery.of(context).size.height * 0.22,
            width: MediaQuery.of(context).size.width,
            child: Image.asset(widget.assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

Widget clickableWidget({required BuildContext context, required String assetPath}) {
  return ClickableBannerWidget(assetPath: assetPath);
}
