/// Parsing helpers for hashtags and @mentions in post/comment text.
class SocialTextParser {
  SocialTextParser._();

  /// Matches `#hashtag` (letters/numbers/underscore) not preceded by a word char.
  static final RegExp hashtagPattern = RegExp(r'(?<![\w#])#(\w{1,50})');

  /// Matches `@mention` token (letters/numbers/._ ) not preceded by a word char.
  static final RegExp mentionPattern = RegExp(r'(?<![\w@])@([\w][\w.]{0,50})');

  /// Combined pattern used by the renderer to split text into runs.
  static final RegExp tokenPattern =
      RegExp(r'(?<![\w#@])[#@](\w[\w.]{0,50})');

  /// Lowercased, de-duplicated hashtags (without the leading #).
  static List<String> extractHashtags(String text) {
    final tags = <String>{};
    for (final m in hashtagPattern.allMatches(text)) {
      final t = m.group(1);
      if (t != null && t.isNotEmpty) tags.add(t.toLowerCase());
    }
    return tags.toList();
  }

  /// Raw mention tokens (without the leading @), order preserved, de-duplicated.
  static List<String> extractMentions(String text) {
    final seen = <String>{};
    final out = <String>[];
    for (final m in mentionPattern.allMatches(text)) {
      final t = m.group(1);
      if (t != null && t.isNotEmpty && seen.add(t.toLowerCase())) out.add(t);
    }
    return out;
  }
}
