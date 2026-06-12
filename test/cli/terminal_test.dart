import 'package:aim/cli/terminal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Terminal styling', () {
    test('returns plain text when color is disabled', () {
      final t = Terminal(useColor: false);
      expect(t.bold('hi'), 'hi');
      expect(t.green('ok'), 'ok');
      expect(t.red('no'), 'no');
      expect(t.gray('dim'), 'dim');
    });

    test('wraps text in ANSI codes when color is enabled', () {
      final t = Terminal(useColor: true);
      expect(t.bold('hi'), '\x1b[1mhi\x1b[0m');
      expect(t.green('ok'), '\x1b[32mok\x1b[0m');
    });
  });

  group('Terminal.renderTable', () {
    final t = Terminal(useColor: false);

    test('aligns columns by widest cell', () {
      final lines = t.renderTable(
        ['NAME', 'VERSIONS'],
        [
          ['Obsidian', '1'],
          ['VeryLongAppName', '12'],
        ],
      );

      expect(lines, hasLength(3));
      // Header padded to the width of the widest first-column cell + 2 spaces.
      expect(lines[0], 'NAME             VERSIONS');
      expect(lines[1], 'Obsidian         1');
      expect(lines[2], 'VeryLongAppName  12');
    });

    test('does not pad the final column', () {
      final lines = t.renderTable(['A', 'B'], [
        ['x', 'y'],
      ]);
      expect(lines[1].endsWith('y'), isTrue);
    });

    test('handles an empty row set', () {
      final lines = t.renderTable(['A', 'B'], []);
      expect(lines, hasLength(1));
      expect(lines.first, 'A  B');
    });
  });
}
