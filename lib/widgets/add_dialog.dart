import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddDialog extends StatelessWidget {
  final Future<void> Function(String path) onAdded;

  const AddDialog({super.key, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.download_for_offline_outlined),
      title: const Text('安装 AppImage'),
      content: Text(
        '选择一个 .AppImage 文件，AIM 会将其复制到 ~/AppImages 并提取图标。',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('选择文件'),
          onPressed: () async {
            final navigator = Navigator.of(context);
            FilePickerResult? result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['AppImage'],
            );
            if (result != null && result.files.single.path != null) {
              final path = result.files.single.path!;
              await onAdded(path);
              navigator.pop();
            }
          },
        ),
      ],
    );
  }
}
