import 'package:flutter/material.dart';

import '../../../models/social_post_model.dart';

/// Shows the 5 reaction types and returns the chosen one (or null if dismissed).
Future<String?> showReactionPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ReactionType.all.map((type) {
              return InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => Navigator.of(ctx).pop(type),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ReactionType.emojiFor(type),
                          style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(ReactionType.labelFor(type),
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
