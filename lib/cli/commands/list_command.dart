import 'dart:convert';

import '../aim_command.dart';

class ListCommand extends AimCommand {
  ListCommand(super.ctx) {
    addJsonFlag();
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List all managed AppImage applications.';

  @override
  List<String> get aliases => ['ls'];

  @override
  Future<int> run() async {
    final apps = await ctx.loadApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (jsonOutput) {
      final data = apps
          .map((a) => {
                'name': a.name,
                'selectedVersion': a.selectedVersion,
                'versions': a.versions,
                'generateLink': a.generateLink,
                'generateDesktopFile': a.generateDesktopFile,
              })
          .toList();
      ctx.term.out(const JsonEncoder.withIndent('  ').convert(data));
      return 0;
    }

    if (apps.isEmpty) {
      ctx.term.out('No AppImages managed yet. Add one with: aim install <path>');
      return 0;
    }

    final rows = apps
        .map((a) => [
              a.name,
              a.selectedVersion.isEmpty ? '-' : a.selectedVersion,
              a.versions.length.toString(),
              a.generateLink ? ctx.term.green('on') : ctx.term.gray('off'),
              a.generateDesktopFile
                  ? ctx.term.green('on')
                  : ctx.term.gray('off'),
            ])
        .toList();

    ctx.term.table(
      ['NAME', 'VERSION', 'VERSIONS', 'LINK', 'DESKTOP'],
      rows,
    );
    return 0;
  }
}
