import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../utils/social_text_parser.dart';
import '../hashtag_feed_screen.dart';

/// Renders post/comment text with tappable #hashtags and @mentions.
///
/// Hashtags open the [HashtagFeedScreen]. Mentions invoke [onMentionTap] (the
/// caller decides how to resolve a name → profile); if none is provided the
/// mention is still styled but inert.
class SocialRichText extends StatelessWidget {
  final String text;
  final int? maxLines;
  final TextStyle? baseStyle;
  final void Function(String mention)? onMentionTap;

  const SocialRichText({
    super.key,
    required this.text,
    this.maxLines,
    this.baseStyle,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ??
        DefaultTextStyle.of(context).style.copyWith(fontSize: 14);
    final linkStyle = base.copyWith(
      color: kPrimaryColor,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in SocialTextParser.tokenPattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      final token = m.group(0)!; // includes leading # or @
      final value = m.group(1)!; // without the symbol
      final isHashtag = token.startsWith('#');
      spans.add(TextSpan(
        text: token,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isHashtag) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => HashtagFeedScreen(tag: value.toLowerCase()),
              ));
            } else {
              onMentionTap?.call(value);
            }
          },
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
