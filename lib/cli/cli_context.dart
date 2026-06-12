import '../models/app_info.dart';
import '../services/appimage_service.dart';
import '../services/desktop_service.dart';
import 'terminal.dart';

/// Shared services and helpers available to every CLI command.
class CliContext {
  final AppImageService appImageService;
  final DesktopService desktopService;
  final Terminal term;

  CliContext({
    AppImageService? appImageService,
    DesktopService? desktopService,
    Terminal? term,
  })  : appImageService = appImageService ?? AppImageService(),
        desktopService = desktopService ?? DesktopService(),
        term = term ?? Terminal();

  Future<List<AppInfo>> loadApps() => appImageService.loadApps();

  /// Finds a managed app by [name], case-insensitively. Returns null if absent.
  Future<AppInfo?> findApp(String name) async {
    final apps = await loadApps();
    final lower = name.toLowerCase();
    for (final app in apps) {
      if (app.name.toLowerCase() == lower) return app;
    }
    return null;
  }

  /// Persists [app] and reconciles its system integration (desktop entry and
  /// `~/.local/bin` symlink), matching the behaviour of the GUI detail screen.
  Future<void> applyIntegration(AppInfo app) async {
    await appImageService.saveMetadata(app);
    if (app.generateDesktopFile) {
      await desktopService.createDesktopEntry(app);
    } else {
      await desktopService.removeDesktopEntry(app);
    }
    await desktopService.updateBinLink(app);
  }
}

/// Thrown by commands to signal a user-facing error with a non-zero exit code.
class CliError implements Exception {
  final String message;
  CliError(this.message);
  @override
  String toString() => message;
}
