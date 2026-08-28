import 'package:flutter/material.dart';
import 'note_service.dart';
import 'app_theme.dart';

/// 回收站：展示已软删除的笔记，支持恢复 / 永久删除
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});
  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notes = await NoteService.instance.fetchTrash();
      if (mounted) {
        setState(() {
          _notes = notes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败: $e';
        });
      }
    }
  }

  Future<void> _restore(Map<String, dynamic> note) async {
    try {
      await NoteService.instance.restoreNote(note['id'] as String);
      if (mounted) {
        setState(() => _notes.removeWhere((n) => n['id'] == note['id']));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已恢复')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    }
  }

  Future<void> _purge(Map<String, dynamic> note) async {
    final title = (note['title'] ?? '无标题').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('永久删除？'),
        content: Text('「$title」将被彻底删除，无法恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await NoteService.instance.purgeNote(note['id'] as String);
      if (mounted) {
        setState(() => _notes.removeWhere((n) => n['id'] == note['id']));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已永久删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.gradientSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('回收站是空的',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, i) {
        final note = _notes[i];
        final title = (note['title'] ?? '无标题').toString();
        final content = (note['content'] ?? '').toString();
        final deleted = _formatTime(note['deleted_at']?.toString());
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty)
                  Text(content,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                if (deleted.isNotEmpty)
                  Text('删除于 $deleted',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: '恢复',
                  color: Colors.blue.shade400,
                  onPressed: () => _restore(note),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  tooltip: '永久删除',
                  color: Colors.red.shade400,
                  onPressed: () => _purge(note),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
