import '../../models/app_info.dart';
import 'toggle_command.dart';

class LinkCommand extends ToggleCommand {
  LinkCommand(super.ctx);

  @override
  String get name => 'link';

  @override
  String get description =>
      'Show or toggle the ~/.local/bin executable symlink for an app.';

  @override
  String get featureName => 'Bin link';

  @override
  bool currentValue(AppInfo app) => app.generateLink;

  @override
  AppInfo withValue(AppInfo app, bool value) =>
      app.copyWith(generateLink: value);
}
