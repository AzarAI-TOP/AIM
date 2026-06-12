import 'dart:io';

/// ANSI styling helpers and table rendering for the `aim` CLI.
///
/// Colors are automatically disabled when stdout is not a terminal or when the
/// `NO_COLOR` environment variable is set (https://no-color.org), mirroring how
/// tools like `gh` behave in pipelines.
class Terminal {
  final bool useColor;

  Terminal({bool? useColor})
      : useColor = useColor ??
            (stdout.hasTerminal &&
                !Platform.environment.containsKey('NO_COLOR'));

  static const _reset = '\x1b[0m';

  String _wrap(String text, String code) =>
      useColor ? '$code$text$_reset' : text;

  String bold(String t) => _wrap(t, '\x1b[1m');
  String dim(String t) => _wrap(t, '\x1b[2m');
  String green(String t) => _wrap(t, '\x1b[32m');
  String red(String t) => _wrap(t, '\x1b[31m');
  String yellow(String t) => _wrap(t, '\x1b[33m');
  String cyan(String t) => _wrap(t, '\x1b[36m');
  String gray(String t) => _wrap(t, '\x1b[90m');

  void out(String message) => stdout.writeln(message);
  void err(String message) => stderr.writeln(message);

  /// Prints a green check mark followed by [message], gh-style.
  void success(String message) => out('${green('✓')} $message');

  /// Prints a red cross followed by [message] to stderr.
  void failure(String message) => err('${red('✗')} $message');

  void info(String message) => out('${cyan('•')} $message');

  /// Renders [rows] as a left-aligned, space-padded table with a bold header
  /// and prints it.
  void table(List<String> headers, List<List<String>> rows) {
    for (final line in renderTable(headers, rows)) {
      out(line);
    }
  }

  /// Pure table renderer: returns the table as a list of lines.
  ///
  /// Column widths are computed from the visible cell lengths so alignment is
  /// correct even when the header is bold. Note: cells are assumed to be
  /// un-styled; only the header receives styling here.
  List<String> renderTable(List<String> headers, List<List<String>> rows) {
    final widths = [for (final h in headers) h.length];
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (row[i].length > widths[i]) widths[i] = row[i].length;
      }
    }

    String renderRow(List<String> cells, {bool header = false}) {
      final buf = StringBuffer();
      for (var i = 0; i < cells.length; i++) {
        final cell = cells[i];
        final padded =
            i == cells.length - 1 ? cell : cell.padRight(widths[i] + 2);
        buf.write(header ? bold(padded) : padded);
      }
      return buf.toString();
    }

    return [
      renderRow(headers, header: true),
      for (final row in rows) renderRow(row),
    ];
  }
}
