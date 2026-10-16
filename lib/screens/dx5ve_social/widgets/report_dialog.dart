import 'package:flutter/material.dart';

import '../../../constants.dart';

const List<String> kReportReasons = [
  'Spam or misleading',
  'Harassment or bullying',
  'Hate speech',
  'Nudity or sexual content',
  'Violence',
  'Other',
];

/// Presents the report reasons and returns the chosen reason (or null).
Future<String?> showReportDialog(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Report — why?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ...kReportReasons.map((r) => ListTile(
                  leading: const Icon(Icons.flag_outlined, color: kCIOPink),
                  title: Text(r),
                  onTap: () => Navigator.of(ctx).pop(r),
                )),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
