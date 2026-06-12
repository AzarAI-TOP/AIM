import '../../models/app_info.dart';
import 'toggle_command.dart';

class DesktopCommand extends ToggleCommand {
  DesktopCommand(super.ctx);

  @override
  String get name => 'desktop';

  @override
  String get description =>
      'Show or toggle the .desktop application menu entry for an app.';

  @override
  String get featureName => 'Desktop entry';

  @override
  bool currentValue(AppInfo app) => app.generateDesktopFile;

  @override
  AppInfo withValue(AppInfo app, bool value) =>
      app.copyWith(generateDesktopFile: value);
}
