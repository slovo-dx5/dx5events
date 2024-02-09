import 'package:flutter/material.dart';
import 'package:sa3_liquid/liquid/plasma/plasma.dart';

import '../constants.dart';
import 'breathing_animation.dart';

class CoolBackground extends StatelessWidget {
  const CoolBackground(
      {this.disableAnimation = false, this.purchased = false, super.key});
  final bool disableAnimation;
  final bool purchased;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Container(
            decoration:  const BoxDecoration(
              gradient: LinearGradient(
                tileMode: TileMode.mirror,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kCIOPink,
                  kCIOPurple,
                ],
                stops: [
                  0,
                  1,
                ],
              ),
              backgroundBlendMode: BlendMode.srcOver,
            ),
            child: const PlasmaRenderer(
              type: PlasmaType.infinity,
              particles: 9,
              color: Color(0x44ffffff),
              blur: 0.27,
              size: 0.9,
              speed: 1.7,
              offset: 0,
              blendMode: BlendMode.lighten,
              particleType: ParticleType.atlas,
              variation1: 0.31,
              variation2: 0.3,
              variation3: 0.13,
              rotation: 1,
            ),
          )),
    );
    // Widget background = Container(
    //   decoration: BoxDecoration(
    //     gradient: LinearGradient(
    //       tileMode: TileMode.mirror,
    //       begin: Alignment.topRight,
    //       end: Alignment.bottomLeft,
    //       colors: [
    //         dynamicPastel(
    //             context,
    //             Theme.of(context).brightness == Brightness.light
    //                 ? Theme.of(context).colorScheme.primary
    //                 : Theme.of(context).colorScheme.tertiary,
    //             amountDark: 0,
    //             amountLight: 0.4),
    //         dynamicPastel(
    //             context,
    //             Theme.of(context).brightness == Brightness.light
    //                 ? Theme.of(context).colorScheme.primaryContainer
    //                 : Theme.of(context).colorScheme.primary,
    //             amountDark: 0,
    //             amountLight: 0.4),
    //         dynamicPastel(
    //             context,
    //             Theme.of(context).brightness == Brightness.light
    //                 ? Theme.of(context).colorScheme.primary
    //                 : Theme.of(context).colorScheme.tertiary,
    //             amountDark: 0,
    //             amountLight: 0.4),
    //       ],
    //       stops: disableAnimation
    //           ? [0, 0.4, 2.5]
    //           : [
    //         0,
    //         0.3,
    //         1.3,
    //       ],
    //     ),
    //     backgroundBlendMode: BlendMode.srcOver,
    //   ),
    //   child: disableAnimation
    //       ? Container()
    //       : PlasmaRenderer(
    //     type: PlasmaType.infinity,
    //     particles: 10,
    //     color: Theme.of(context).brightness == Brightness.light
    //         ?Color(0x28B4B4B4)
    //         : Color(0x44B6B6B6),
    //     blur: 0.5,
    //     size: 0.7,
    //     speed: Theme.of(context).brightness == Brightness.light ? 4 : 3,
    //     offset: 1,
    //     blendMode: BlendMode.plus,
    //     particleType: ParticleType.atlas,
    //     variation1: 0,
    //     variation2: 1,
    //     variation3: 2,
    //     rotation: 0,
    //   ),
    // );
    // if (disableAnimation) {
    //   return BreathingWidget(
    //     curve: Curves.easeInBack,
    //     duration: Duration(milliseconds: 3000),
    //     endScale: 1.7,
    //     child: background,
    //   );
    // } else {
    //   return background;
    // }
  }
}


Color lightenPastel(Color color, {double amount = 0.5}) {
  return Color.alphaBlend(
    kCIOPink.withOpacity(amount),
    color,
  );
}

Color dynamicPastel(
    BuildContext context,
    Color color, {
      double amount = 0.1,
      bool inverse = false,
      double? amountLight,
      double? amountDark,
    }) {
  if (amountLight == null) {
    amountLight = amount;
  }
  if (amountDark == null) {
    amountDark = amount;
  }
  if (inverse) {
    if (Theme.of(context).brightness == Brightness.light) {
      return darkenPastel(color, amount: amountDark);
    } else {
      return lightenPastel(color, amount: amountLight);
    }
  } else {
    if (Theme.of(context).brightness == Brightness.light) {
      return lightenPastel(color, amount: amountLight);
    } else {
      return darkenPastel(color, amount: amountDark);
    }
  }
}

Color darkenPastel(Color color, {double amount = 0.1}) {
  return Color.alphaBlend(
    Colors.black.withOpacity(amount),
    color,
  );
}