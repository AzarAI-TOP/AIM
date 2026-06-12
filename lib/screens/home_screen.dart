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
  final TextEditingController _searchController = TextEditingController();
  List<AppInfo> _apps = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _refreshApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshApps() async {
    setState(() => _loading = true);
    try {
      final apps = await _appImageService.loadApps();
      if (!mounted) return;
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

  List<AppInfo> get _filteredApps {
    if (_query.isEmpty) return _apps;
    return _apps
        .where((a) => a.name.toLowerCase().contains(_query))
        .toList(growable: false);
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
            messenger.showSnackBar(
              const SnackBar(content: Text('安装成功')),
            );
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
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(appInfo: app)),
    );
    await _refreshApps();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AIM',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            Text(
              'AppImage 管理器',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _refreshApps,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _apps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索应用',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('安装 AppImage'),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_apps.isEmpty) {
      return _EmptyState(onAdd: _showAddDialog);
    }

    final apps = _filteredApps;
    if (apps.isEmpty) {
      return Center(
        child: Text(
          '没有匹配 "$_query" 的应用',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshApps,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return AppListItem(app: app, onTap: () => _openDetail(app));
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '还没有管理任何 AppImage',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮安装你的第一个 AppImage 应用',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('安装 AppImage'),
            ),
          ],
        ),
      ),
    );
  }
}
