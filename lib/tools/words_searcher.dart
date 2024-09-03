class WordsSearcher {
  late final String pattern;

  WordsSearcher(String wordsToSearch) {
    // Matches MyString and OtherString in any order: ^(?=.*\bMyString\b)(?=.*\bOtherString\b).*$
    // 1. ^ asserts the start of the expression to be matched.
    // 2. (?=.*\bMyString\b) is the first positive lookahead saying that what follows must match .*\bMyString\b.
    // 3. .* means any character zero or more times.
    // 4. \b means any word boundary (white space, start of expression, end of expression, etc.).
    // 5. MyString is literally those characters in a row (the same for OtherString in the next positive lookahead).
    // 6. $ asserts the end of the expression to me matched.
    // Special RegExp characters which requires \ escape in searched string ., +, *, ?, ^, $, (, ), [, ], {, }, |, \
    pattern = r'^' +
        wordsToSearch
            .replaceAll(r'\', r'\\')
            .replaceAll('.', r'\.')
            .replaceAll('+', r'\+')
            .replaceAll('*', r'\*')
            .replaceAll('?', r'\?')
            .replaceAll('^', r'\^')
            .replaceAll(r'$', r'\$')
            .replaceAll('(', r'\(')
            .replaceAll(')', r'\)')
            .replaceAll('[', r'\[)')
            .replaceAll(']', r'\])')
            .replaceAll('{', r'\{)')
            .replaceAll('}', r'\})')
            .replaceAll('|', r'\|)')
            .split(' ')
            .map((e) => '(?=.*$e)')
            .join() +
        r'.*$';
  }

  bool searchIn(String source, [bool caseSensitive = false]) =>
      source.replaceAll(RegExp('[\n\r]'), ' ').contains(RegExp(pattern, caseSensitive: caseSensitive));

  static bool search(String wordsToSearch, String source) => WordsSearcher(wordsToSearch).searchIn(source);
}
