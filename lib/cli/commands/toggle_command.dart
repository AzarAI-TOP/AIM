import '../../models/app_info.dart';
import '../aim_command.dart';
import '../cli_context.dart';

/// Base class for commands that flip a single boolean integration flag on an
/// app (e.g. the `~/.local/bin` symlink or the `.desktop` entry).
abstract class ToggleCommand extends AimCommand {
  ToggleCommand(super.ctx) {
    argParser.addFlag('enable', negatable: false, help: 'Turn $featureName on.');
    argParser.addFlag('disable', negatable: false, help: 'Turn $featureName off.');
  }

  /// Human-readable feature name used in help text and output.
  String get featureName;

  /// Reads the current value of the flag from [app].
  bool currentValue(AppInfo app);

  /// Returns a copy of [app] with the flag set to [value].
  AppInfo withValue(AppInfo app, bool value);

  @override
  String get invocation => 'aim $name <name> [--enable | --disable]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw CliError('No app specified. Usage: $invocation');
    }
    final appName = rest.first;
    final app = await ctx.findApp(appName);
    if (app == null) {
      throw CliError(
        "No app named '$appName'. Run 'aim list' to see managed apps.",
      );
    }

    final enable = argResults!['enable'] as bool;
    final disable = argResults!['disable'] as bool;
    if (enable && disable) {
      throw CliError('Cannot use --enable and --disable together.');
    }

    if (!enable && !disable) {
      // No flag: report current state.
      ctx.term.out(
        '$featureName for ${app.name}: '
        '${currentValue(app) ? ctx.term.green('on') : ctx.term.gray('off')}',
      );
      return 0;
    }

    final value = enable;
    await ctx.applyIntegration(withValue(app, value));
    ctx.term.success(
      '$featureName ${value ? 'enabled' : 'disabled'} for ${ctx.term.bold(app.name)}',
    );
    return 0;
  }
}
