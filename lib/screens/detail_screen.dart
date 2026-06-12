import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/appimage_service.dart';
import '../services/desktop_service.dart';

class DetailScreen extends StatefulWidget {
  final AppInfo appInfo;

  const DetailScreen({super.key, required this.appInfo});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late AppInfo _app;
  final AppImageService _appImageService = AppImageService();
  final DesktopService _desktopService = DesktopService();
  final TextEditingController _descController = TextEditingController();
  final FocusNode _descFocusNode = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _app = widget.appInfo;
    _descController.text = _app.description;
    _descFocusNode.addListener(_onDescriptionFocusChange);
  }

  @override
  void dispose() {
    _descFocusNode.removeListener(_onDescriptionFocusChange);
    _descFocusNode.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onDescriptionFocusChange() {
    if (!_descFocusNode.hasFocus) {
      _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    _saving = true;
    try {
      _app = _app.copyWith(description: _descController.text);

      await _appImageService.saveMetadata(_app);

      if (_app.generateDesktopFile) {
        await _desktopService.createDesktopEntry(_app);
      } else {
        await _desktopService.removeDesktopEntry(_app);
      }

      await _desktopService.updateBinLink(_app);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存设置失败: $e')),
        );
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _uninstall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('确认卸载'),
        content: Text('确定要删除 ${_app.name} 的所有数据吗?此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('卸载'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appImageService.deletePackage(_app);

      await _desktopService.removeDesktopEntry(_app);
      final appWithoutLink = _app.copyWith(generateLink: false);
      await _desktopService.updateBinLink(appWithoutLink);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('卸载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_app.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 24),
          _Section(
            title: '描述',
            child: TextField(
              controller: _descController,
              focusNode: _descFocusNode,
              decoration: const InputDecoration(
                hintText: '为这个应用添加描述',
                border: InputBorder.none,
              ),
              maxLines: 3,
              onSubmitted: (_) => _descFocusNode.unfocus(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '系统集成',
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('创建可执行链接'),
                  subtitle: const Text('在 ~/.local/bin 中创建命令行链接'),
                  value: _app.generateLink,
                  onChanged: (val) {
                    setState(() => _app = _app.copyWith(generateLink: val));
                    _saveSettings();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('创建桌面入口'),
                  subtitle: const Text('生成 .desktop 文件以显示在应用菜单'),
                  value: _app.generateDesktopFile,
                  onChanged: (val) {
                    setState(
                      () => _app = _app.copyWith(generateDesktopFile: val),
                    );
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '当前版本',
            child: DropdownButtonFormField<String>(
              initialValue:
                  _app.selectedVersion.isNotEmpty ? _app.selectedVersion : null,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none),
              items: _app.versions.map<DropdownMenuItem<String>>((ver) {
                return DropdownMenuItem(value: ver, child: Text(ver));
              }).toList(),
              onChanged: (val) {
                setState(() => _app = _app.copyWith(selectedVersion: val ?? ''));
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _uninstall,
            icon: const Icon(Icons.delete_forever),
            label: const Text('卸载应用'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _app.iconPath.isNotEmpty
              ? Image.file(
                  File(_app.iconPath),
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _iconPlaceholder(theme),
                )
              : _iconPlaceholder(theme),
        ),
        const SizedBox(height: 12),
        Text(_app.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '${_app.versions.length} 个版本',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _iconPlaceholder(ThemeData theme) {
    return Container(
      width: 96,
      height: 96,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.apps,
        size: 56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Section({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}
