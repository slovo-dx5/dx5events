import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constants.dart';
import '../services/session_ratings.dart';

/// Star rating for one session (and its speakers, when it has any).
///
/// Opens with [show]; resolves to true once the rating reached Directus.
class RatingDialog extends StatefulWidget {
  final int attendeeID;
  final RateableItem item;

  const RatingDialog({required this.attendeeID, required this.item, super.key});

  static Future<bool> show(BuildContext context,
      {required int attendeeID, required RateableItem item}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(attendeeID: attendeeID, item: item),
    );
    return ok ?? false;
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _sessionRating = 0;
  int _speakerRating = 0;
  bool _submitting = false;
  final TextEditingController _sessionComment = TextEditingController();
  final TextEditingController _speakerComment = TextEditingController();

  bool get _hasSpeakers => widget.item.speakerNames.trim().isNotEmpty;

  @override
  void dispose() {
    _sessionComment.dispose();
    _speakerComment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sessionRating == 0) {
      Fluttertoast.showToast(msg: 'Tap the stars to rate the session');
      return;
    }
    setState(() => _submitting = true);
    try {
      await SessionRatingService.instance.submit(
        item: widget.item,
        attendeeId: widget.attendeeID,
        sessionRating: _sessionRating,
        speakerRating: _hasSpeakers ? _speakerRating : 0,
        sessionComment: _sessionComment.text,
        speakerComment: _hasSpeakers ? _speakerComment.text : '',
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Thanks! Your rating has been recorded');
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[RatingDialog] submit failed: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      Fluttertoast.showToast(
          backgroundColor: kLogoutRed,
          msg: 'Could not send your rating. Check your internet and try again.');
    }
  }

  Widget _stars(int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final on = i < value;
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
          icon: Icon(on ? Icons.star : Icons.star_border,
              color: on ? kIconPurple : Colors.grey, size: 36),
          onPressed: _submitting ? null : () => setState(() => onChanged(i + 1)),
        );
      }),
    );
  }

  Widget _comment(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      enabled: !_submitting,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
        fontSize: 15, color: kIconPurple, fontWeight: FontWeight.bold);
    return AlertDialog(
      title: Text(widget.item.title.trim(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SESSION RATING', style: label),
            _stars(_sessionRating, (v) => _sessionRating = v),
            const SizedBox(height: 8),
            _comment(_sessionComment, 'Your thoughts on this session (optional)'),
            if (_hasSpeakers) ...[
              const SizedBox(height: 16),
              const Text('SPEAKER RATING', style: label),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.item.speakerNames,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
              _stars(_speakerRating, (v) => _speakerRating = v),
              const SizedBox(height: 8),
              _comment(_speakerComment, 'Comments on the speakers (optional)'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit', style: TextStyle(color: kIconPurple)),
        ),
      ],
    );
  }
}
