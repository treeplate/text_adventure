class WordIterator {
  final List<String> characters;
  int index = 0;
  String getWord() {
    StringBuffer buf = StringBuffer();
    while (!complete && characters[index] != ' ') {
      buf.write(characters[index]);
      index++;
    }
    if (!complete) index++;
    return buf.toString();
  }

  void ungetWord() {
    index--;
    index--;
    while (index >= 0 && characters[index] != ' ') {
      index--;
    }
    index++;
  }

  String getRemainder() {
    StringBuffer buf = StringBuffer();
    while (!complete) {
      buf.write(characters[index]);
      index++;
    }
    return buf.toString();
  }

  String getUntilKeywords(List<String> keywords) {
    StringBuffer buf = StringBuffer();
    StringBuffer wordBuf = StringBuffer();
    while (!complete) {
      if (characters[index] == ' ') {
        if (keywords.contains(wordBuf.toString())) {
          index -= wordBuf.toString().length;
          return buf.toString();
        }
        if (!buf.toString().endsWith(' ') && buf.isNotEmpty) {
          buf.write(' ');
        }
        buf.write(wordBuf.toString());
        wordBuf = StringBuffer();
      } else {
        wordBuf.write(characters[index]);
      }
      index++;
    }
    if (keywords.contains(wordBuf.toString())) {
      index -= wordBuf.toString().length;
      return buf.toString();
    }
    if (!buf.toString().endsWith(' ')) {
      buf.write(' ');
    }
    buf.write(wordBuf.toString());
    return buf.toString();
  }

  bool get complete => index >= characters.length;

  WordIterator(String str) : characters = str.split('');
}
