import 'package:args/command_runner.dart';

import 'cli_context.dart';
import 'commands/desktop_command.dart';
import 'commands/info_command.dart';
import 'commands/install_command.dart';
import 'commands/link_command.dart';
import 'commands/list_command.dart';
import 'commands/remove_command.dart';
import 'commands/version_command.dart';

const aimVersion = '1.0.0';

/// gh-style command runner for the `aim` CLI. Wires up every subcommand and
/// handles the top-level `--version` flag and error reporting.
class AimCommandRunner extends CommandRunner<int> {
  final CliContext ctx;

  AimCommandRunner({CliContext? context})
      : ctx = context ?? CliContext(),
        super('aim', 'Advanced appImage Manager — manage AppImages from the terminal.') {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the aim version.',
    );

    addCommand(ListCommand(ctx));
    addCommand(InstallCommand(ctx));
    addCommand(RemoveCommand(ctx));
    addCommand(InfoCommand(ctx));
    addCommand(VersionCommand(ctx));
    addCommand(LinkCommand(ctx));
    addCommand(DesktopCommand(ctx));
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevel = parse(args);
      if (topLevel['version'] as bool) {
        ctx.term.out('aim $aimVersion');
        return 0;
      }
      return await runCommand(topLevel) ?? 0;
    } on UsageException catch (e) {
      ctx.term.err(e.toString());
      return 64; // EX_USAGE
    } on CliError catch (e) {
      ctx.term.failure(e.message);
      return 1;
    }
  }
}
