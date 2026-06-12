import 'package:args/command_runner.dart';
import 'cli_context.dart';

/// Base class for all `aim` subcommands. Provides shared [CliContext] access
/// and a convenience getter for the common `--json` flag.
abstract class AimCommand extends Command<int> {
  final CliContext ctx;

  AimCommand(this.ctx);

  /// Adds a `--json` flag for machine-readable output.
  void addJsonFlag() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output as JSON for scripting.',
    );
  }

  bool get jsonOutput => argParser.options.containsKey('json')
      ? argResults!['json'] as bool
      : false;
}
