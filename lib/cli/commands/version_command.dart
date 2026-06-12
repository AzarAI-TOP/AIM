import 'dart:convert';

import '../aim_command.dart';
import '../cli_context.dart';

class VersionCommand extends AimCommand {
  VersionCommand(super.ctx) {
    argParser.addOption(
      'set',
      help: 'Switch the active version to the given AppImage filename.',
      valueHelp: 'filename',
    );
    addJsonFlag();
  }

  @override
  String get name => 'version';

  @override
  String get description => 'List or switch the active version of an app.';

  @override
  String get invocation => 'aim version <name> [--set <filename>]';

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

    final target = argResults!['set'] as String?;
    if (target != null) {
      if (!app.versions.contains(target)) {
        throw CliError(
          "Version '$target' not found for ${app.name}. "
          "Available: ${app.versions.join(', ')}",
        );
      }
      await ctx.applyIntegration(app.copyWith(selectedVersion: target));
      ctx.term.success('${app.name} now uses ${ctx.term.bold(target)}');
      return 0;
    }

    if (jsonOutput) {
      ctx.term.out(const JsonEncoder.withIndent('  ').convert({
        'name': app.name,
        'selectedVersion': app.selectedVersion,
        'versions': app.versions,
      }));
      return 0;
    }

    final t = ctx.term;
    for (final v in app.versions) {
      final active = v == app.selectedVersion;
      t.out('${active ? t.green('●') : t.gray('○')} $v');
    }
    return 0;
  }
}
