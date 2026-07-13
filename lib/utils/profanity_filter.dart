/// Lightweight, local profanity check used before a post/comment is submitted.
///
/// This is a client-side first line of defence only — server-side moderation
/// (reports + admin hide/delete) remains the source of truth. Keep [_blocklist]
/// configurable; it is deliberately small and can be expanded or later fetched
/// from Directus without changing callers.
class ProfanityFilter {
  ProfanityFilter._();

  /// Base list of disallowed terms (lowercase, no spaces). Extend as needed.
  static final Set<String> _blocklist = {
    'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'cunt', 'dick', 'pussy',
    'nigger', 'nigga', 'faggot', 'retard', 'slut', 'whore', 'motherfucker',
  };

  /// Allow the blocklist to be extended at runtime (e.g. from a remote config).
  static void addTerms(Iterable<String> terms) {
    _blocklist.addAll(terms.map((t) => t.toLowerCase().trim()).where((t) => t.isNotEmpty));
  }

  static final RegExp _wordSplit = RegExp(r"[^a-zA-Z0-9']+");

  /// Normalizes common letter→symbol substitutions (l33t speak) so simple
  /// evasions like "sh!t" / "f_u_c_k" are still caught.
  static String _normalize(String word) {
    final lower = word.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      switch (ch) {
        case '@':
          buffer.write('a');
          break;
        case '0':
          buffer.write('o');
          break;
        case '1':
        case '!':
        case '|':
          buffer.write('i');
          break;
        case '3':
          buffer.write('e');
          break;
        case '4':
          buffer.write('a');
          break;
        case '5':
        case '\$':
          buffer.write('s');
          break;
        case '7':
          buffer.write('t');
          break;
        case '_':
        case '-':
        case '.':
        case '*':
          break; // strip separators used to break up words
        default:
          buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// True if [text] contains any blocked term.
  static bool containsProfanity(String text) {
    if (text.trim().isEmpty) return false;
    for (final raw in text.split(_wordSplit)) {
      if (raw.isEmpty) continue;
      if (_blocklist.contains(_normalize(raw))) return true;
    }
    return false;
  }

  /// Returns [text] with any blocked term replaced by asterisks of equal length.
  static String mask(String text) {
    if (text.trim().isEmpty) return text;
    return text.replaceAllMapped(RegExp(r"[a-zA-Z0-9@!|\$_\-.*']+"), (m) {
      final word = m.group(0)!;
      if (_blocklist.contains(_normalize(word))) {
        return '*' * word.length;
      }
      return word;
    });
  }
}
