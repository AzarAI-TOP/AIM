import 'dart:io';

import 'package:aim/cli/aim_runner.dart';

/// Entry point for the `aim` command-line interface.
///
/// Run during development with:  `dart run bin/aim.dart <command>`
/// Or compile a standalone binary: `dart compile exe bin/aim.dart -o aim`
Future<void> main(List<String> args) async {
  final exitCode = await AimCommandRunner().run(args);
  exit(exitCode);
}
