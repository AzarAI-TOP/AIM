import 'package:flutter/material.dart';
import '../services/appimage_service.dart';
import '../models/app_info.dart';
import '../widgets/add_dialog.dart';
import '../widgets/app_list_item.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppImageService _appImageService = AppImageService();
  List<AppInfo> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshApps();
  }

  Future<void> _refreshApps() async {
    setState(() => _loading = true);
    try {
      final apps = await _appImageService.loadApps();
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载应用列表失败: $e')),
      );
    }
  }

  void _showAddDialog() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AddDialog(
        onAdded: (path) async {
          try {
            await _appImageService.addAppImage(path);
            await _refreshApps();
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('添加应用失败: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _openDetail(AppInfo app) async {
    final returned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(appInfo: app),
      ),
    );

    // If the detail screen indicated changes were made (returned true),
    // or the app was uninstalled, refresh from disk.
    // We always refresh to pick up any changes saved by the detail screen.
    if (returned == true || returned == null) {
      await _refreshApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.1,
            alignment: Alignment.center,
            child: const Text(
              'AIM',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _loading
                ? const CircularProgressIndicator()
                : ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index];
                      return AppListItem(
                        app: app,
                        onTap: () => _openDetail(app),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
