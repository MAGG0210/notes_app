import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'note_service.dart';
import 'note_edit_page.dart';

/// 笔记列表页：Realtime 订阅任何端的变化，实时刷新。
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final notes = await NoteService.instance.fetchNotes();
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

  void _subscribe() {
    final uid = NoteService.instance.userId;
    _channel = NoteService.instance.subscribeNotes(
      forUserId: uid,
      onChanged: () {
        // 防抖：多条变更合并为一次刷新
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), _load);
      },
    );
  }

  Future<void> _signOut() async {
    await NoteService.instance.signOut();
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云笔记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '手动刷新',
            onPressed: _load,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('退出登录')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditPage()),
          );
          if (changed == true) _load();
        },
        child: const Icon(Icons.add),
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
            Icon(Icons.notes, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('还没有笔记，点右下角 + 新建',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notes.length,
        itemBuilder: (context, i) {
          final note = _notes[i];
          final title = (note['title'] ?? '无标题').toString();
          final content = (note['content'] ?? '').toString();
          final updated = _formatTime(note['updated_at']?.toString());
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (content.isNotEmpty)
                    Text(content,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (updated.isNotEmpty)
                    Text(updated,
                        style: TextStyle(fontSize: 12,
                            color: Colors.grey.shade500)),
                ],
              ),
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NoteEditPage(note: note)),
                );
                if (changed == true) _load();
              },
            ),
          );
        },
      ),
    );
  }
}
