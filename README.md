<p align="center">
  <h1 align="center">AIM</h1>
  <p align="center"><strong>A</strong>dvanced app<strong>I</strong>mage <strong>M</strong>anager</p>
</p>

AIM is a Flutter desktop application for managing [AppImage](https://appimage.org/) applications on Linux. It keeps your AppImages organized, creates desktop entries so they appear in your application launcher, and generates shell shortcuts — all from a clean graphical interface.

## Features

- **Add & Organize** — Browse and install AppImage files into a managed directory (`~/AppImages/<name>/`). AIM derives the application name and tracks multiple versions side by side.
- **Desktop Integration** — Toggle `.desktop` entry generation so installed apps appear in your system application menu.
- **Shell Shortcuts** — Opt into a `~/.local/bin` symlink for direct terminal access.
- **Version Management** — Keep multiple versions of the same application and switch between them from a dropdown.
- **Icon Extraction** — Automatically extracts application icons from AppImage Type 2 files.
- **Metadata Persistence** — Per-application YAML metadata files keep state consistent across restarts.
- **Command-Line Interface** — A `gh`-style `aim` CLI for managing AppImages from the terminal or scripts, with `--json` output for automation.

## Requirements

- **Linux** — AIM relies on freedesktop.org paths (`~/.local/share/applications`, `~/.local/bin`) and AppImage runtime extraction.
- **Flutter SDK** `>=3.10.7` — See the [Flutter Linux install guide](https://docs.flutter.dev/get-started/install/linux).

## Installation

Pre-built packages are attached to each [GitHub release](https://github.com/AzarAI-TOP/AIM/releases). They install the GUI to `/opt/aim` (launchable from your application menu) and the `aim` CLI to `/usr/bin/aim`. No Flutter SDK required.

**Debian / Ubuntu (`.deb`)**

```bash
sudo apt install ./aim_<version>_amd64.deb
```

**Fedora / RHEL / openSUSE (`.rpm`)**

```bash
sudo dnf install ./aim-<version>-1.*.x86_64.rpm
```

**Other distros (`.tar.gz`)**

```bash
tar xzf aim-<version>-linux-x86_64.tar.gz
cd aim-<version>-linux-x86_64
./install.sh      # copies into /opt and /usr (uses sudo); ./uninstall.sh reverts
```

After installing, launch **AIM** from your application menu, or run `aim --help` in a terminal.

## Building from Source

```bash
# Clone the repository
git clone https://github.com/AzarAI-TOP/AIM.git
cd AIM

# Install dependencies
flutter pub get

# Run on Linux
flutter run -d linux

# Build a release binary
flutter build linux
```

The binary is output to `build/linux/x64/release/bundle/aim`.

### Building Release Packages

```bash
packaging/build-release.sh        # builds .deb, .rpm and .tar.gz into dist/
```

Requires `flutter`, `dart`, `tar`, and (for the respective formats) `dpkg-deb` or `ar`, and `rpmbuild`.

## Usage

1. Launch AIM. An empty list is shown on first run.
2. Press the **+** FAB and select an `.AppImage` file.
3. Tap an application to open its detail screen:
   - Edit the description.
   - Toggle desktop entry and shell symlink creation.
   - Switch between installed versions.
4. Changes are saved automatically as you edit. Use the uninstall button to remove an app and all its data.

### Command-Line Interface

AIM ships with a `gh`-style CLI that shares the same managed directory and metadata as the GUI. Run it during development with `dart run bin/aim.dart`, or compile a standalone binary:

```bash
dart compile exe bin/aim.dart -o aim
./aim --help
```

Commands:

```bash
aim list                          # List managed apps (alias: ls)
aim install <path> [<path>...]    # Install one or more AppImage files
aim info <name>                   # Show details for an app (alias: view)
aim remove <name> [--yes]         # Uninstall an app and its data (alias: rm)
aim version <name>                # List versions, ● marks the active one
aim version <name> --set <file>   # Switch the active version
aim link <name> [--enable|--disable]      # Show/toggle the ~/.local/bin symlink
aim desktop <name> [--enable|--disable]   # Show/toggle the .desktop entry
```

`list`, `info`, and `version` accept `--json` for machine-readable output. Color is emitted only when stdout is a terminal and `NO_COLOR` is unset.

```bash
aim list --json
aim info Obsidian --json
```

### Directory Layout

```
~/AppImages/
└── MyApp/
    ├── MyApp-1.0.0.AppImage
    ├── MyApp-2.1.0.AppImage
    ├── icon.png
    └── metadata.yaml
```

## Development

```bash
flutter analyze          # Static analysis
flutter test             # Run tests
```

## License

MIT
