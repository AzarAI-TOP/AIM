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
      _app.description = _descController.text;
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
        title: const Text("确认卸载"),
        content: Text('确定要删除 ${_app.name} 的所有数据吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == false) return;

    try {
      // Delete the package directory first. If this fails, desktop entry
      // and symlink remain intact so the app is still usable.
      await _appImageService.deletePackage(_app);

      await _desktopService.removeDesktopEntry(_app);
      _app.generateLink = false;
      await _desktopService.updateBinLink(_app);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_app.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_app.iconPath.isNotEmpty)
              Image.file(
                File(_app.iconPath),
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.apps, size: 100),
              )
            else
              const Icon(Icons.apps, size: 100),
            const SizedBox(height: 16),

            Text(_app.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              focusNode: _descFocusNode,
              decoration: const InputDecoration(
                labelText: '应用描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (_) {
                _descFocusNode.unfocus();
              },
            ),
            const SizedBox(height: 24),

            CheckboxListTile(
              title: const Text('在 ~/.local/bin 中创建可执行链接文件'),
              value: _app.generateLink,
              onChanged: (val) {
                setState(() => _app.generateLink = val ?? false);
                _saveSettings();
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              title: const Text('创建 .desktop 桌面入口文件'),
              value: _app.generateDesktopFile,
              onChanged: (val) {
                setState(() => _app.generateDesktopFile = val ?? true);
                _saveSettings();
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _app.selectedVersion.isNotEmpty ? _app.selectedVersion : null,
              items: _app.versions.map<DropdownMenuItem<String>>((ver) {
                return DropdownMenuItem(value: ver, child: Text(ver));
              }).toList(),
              onChanged: (val) {
                setState(() => _app.selectedVersion = val ?? '');
                _saveSettings();
              },
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton.icon(
                label: const Text('卸载应用'),
                icon: const Icon(Icons.delete_forever),
                onPressed: _uninstall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
