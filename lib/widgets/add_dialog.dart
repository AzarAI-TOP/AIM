import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddDialog extends StatelessWidget {
  final Future<void> Function(String path) onAdded;

  const AddDialog({super.key, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('安装 AppImage'),
      content: const Text('请选择要添加的 AppImage 文件'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
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
          child: const Text('选择文件'),
        ),
      ],
    );
  }
}
