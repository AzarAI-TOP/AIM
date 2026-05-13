import 'package:flutter/material.dart';
import '../services/appimage_service.dart';
import '../models/app_info.dart';
import '../widgets/add_dialog.dart';
import '../widgets/app_list_item.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
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
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(appInfo: app),
                            ),
                          );
                          await _refreshApps();
                        },
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
