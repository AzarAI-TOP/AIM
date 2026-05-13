import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_info.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;

  const AppListItem({super.key, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(),
      title: Text(app.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildIcon() {
    if (app.iconPath.isEmpty) return const Icon(Icons.apps, size: 40);
    return Image.file(
      File(app.iconPath),
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.apps, size: 40),
    );
  }
}
