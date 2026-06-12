import 'package:aim/cli/aim_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AimCommandRunner', () {
    test('registers all expected subcommands', () {
      final runner = AimCommandRunner();
      expect(
        runner.commands.keys,
        containsAll(<String>[
          'list',
          'install',
          'remove',
          'info',
          'version',
          'link',
          'desktop',
        ]),
      );
    });

    test('exposes list and remove aliases', () {
      final runner = AimCommandRunner();
      // Aliases are registered as keys in the commands map.
      expect(runner.commands.containsKey('ls'), isTrue);
      expect(runner.commands.containsKey('rm'), isTrue);
      expect(runner.commands.containsKey('view'), isTrue);
    });
  });
}
