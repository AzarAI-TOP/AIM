import '../aim_command.dart';
import '../cli_context.dart';

class InstallCommand extends AimCommand {
  InstallCommand(super.ctx);

  @override
  String get name => 'install';

  @override
  String get description => 'Install one or more AppImage files.';

  @override
  String get invocation => 'aim install <path> [<path>...]';

  @override
  Future<int> run() async {
    final paths = argResults!.rest;
    if (paths.isEmpty) {
      throw CliError('No file specified. Usage: $invocation');
    }

    var failures = 0;
    for (final path in paths) {
      try {
        await ctx.appImageService.addAppImage(path);
        ctx.term.success('Installed ${ctx.term.bold(path)}');
      } catch (e) {
        ctx.term.failure('Failed to install $path: $e');
        failures++;
      }
    }
    return failures == 0 ? 0 : 1;
  }
}
