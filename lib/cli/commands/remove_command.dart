import 'dart:io';

import '../aim_command.dart';
import '../cli_context.dart';

class RemoveCommand extends AimCommand {
  RemoveCommand(super.ctx) {
    argParser.addFlag(
      'yes',
      abbr: 'y',
      negatable: false,
      help: 'Skip the confirmation prompt.',
    );
  }

  @override
  String get name => 'remove';

  @override
  String get description => 'Uninstall an application and delete all its data.';

  @override
  List<String> get aliases => ['rm'];

  @override
  String get invocation => 'aim remove <name> [--yes]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw CliError('No app specified. Usage: $invocation');
    }
    final name = rest.first;
    final app = await ctx.findApp(name);
    if (app == null) {
      throw CliError("No app named '$name'. Run 'aim list' to see managed apps.");
    }

    if (!(argResults!['yes'] as bool)) {
      stdout.write('Delete all data for ${ctx.term.bold(app.name)}? [y/N] ');
      final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
      if (answer != 'y' && answer != 'yes') {
        ctx.term.out('Aborted.');
        return 0;
      }
    }

    await ctx.appImageService.deletePackage(app);
    await ctx.desktopService.removeDesktopEntry(app);
    await ctx.desktopService.updateBinLink(app.copyWith(generateLink: false));

    ctx.term.success('Removed ${ctx.term.bold(app.name)}');
    return 0;
  }
}
