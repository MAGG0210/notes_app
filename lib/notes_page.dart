import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'note_service.dart';
import 'note_edit_page.dart';
import 'theme_store.dart';

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
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _activeTag;

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
    _searchCtrl.dispose();
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
          // 若当前筛选的标签已不存在，清除筛选
          if (_activeTag != null &&
              !_allTags.contains(_activeTag)) {
            _activeTag = null;
          }
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

  // ---------- 搜索 / 筛选 ----------
  List<String> get _allTags {
    final set = <String>{};
    for (final n in _notes) {
      final tags = (n['tags'] as List?)?.map((e) => e.toString()) ?? const [];
      set.addAll(tags);
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _filteredNotes {
    final q = _search.trim().toLowerCase();
    return _notes.where((n) {
      if (_activeTag != null) {
        final tags =
            (n['tags'] as List?)?.map((e) => e.toString()) ?? const <String>[];
        if (!tags.contains(_activeTag)) return false;
      }
      if (q.isNotEmpty) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        final content = (n['content'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !content.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ---------- 复制 / 导出 ----------
  Future<void> _copyNote(Map<String, dynamic> note) async {
    final text = _noteToText(note);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制到剪贴板')));
    }
  }

  Future<void> _exportNote(Map<String, dynamic> note) async {
    final title = (note['title'] ?? '云笔记').toString();
    final text = _noteToText(note);
    await Share.share(text, subject: title);
  }

  String _noteToText(Map<String, dynamic> note) {
    final title = (note['title'] ?? '').toString().trim();
    final content = (note['content'] ?? '').toString();
    final tags = (note['tags'] as List?)?.map((e) => e.toString()) ?? const [];
    final tagStr =
        tags.isEmpty ? '' : '\n\n标签：${tags.map((t) => '#$t').join(' ')}';
    if (title.isEmpty) return content;
    return '$title\n\n$content$tagStr';
  }

  // ---------- 时间格式化 ----------
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
              if (v == 'theme_light') ThemeStore.set(ThemeMode.light);
              if (v == 'theme_dark') ThemeStore.set(ThemeMode.dark);
              if (v == 'theme_system') ThemeStore.set(ThemeMode.system);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'theme_light', child: Text('外观：亮色')),
              PopupMenuItem(value: 'theme_dark', child: Text('外观：暗色')),
              PopupMenuItem(value: 'theme_system', child: Text('外观：跟随系统')),
              PopupMenuDivider(),
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
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索笔记…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // 标签筛选栏
          if (_allTags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('全部'),
                      visualDensity: VisualDensity.compact,
                      selected: _activeTag == null,
                      onSelected: (_) => setState(() => _activeTag = null),
                    ),
                  ),
                  ..._allTags.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('#$t'),
                          visualDensity: VisualDensity.compact,
                          selected: _activeTag == t,
                          onSelected: (_) =>
                              setState(() => _activeTag = _activeTag == t ? null : t),
                        ),
                      )),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
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
    final notes = _filteredNotes;
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _notes.isEmpty
                  ? '还没有笔记，点右下角 + 新建'
                  : '没有匹配的笔记',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, i) => _buildNoteCard(notes[i]),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = (note['title'] ?? '无标题').toString();
    final content = (note['content'] ?? '').toString();
    final updated = _formatTime(note['updated_at']?.toString());
    final pinned = note['pinned'] == true;
    final tags = (note['tags'] as List?)?.map((e) => e.toString()) ?? const [];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: pinned
            ? Icon(Icons.push_pin, color: Colors.orange.shade600, size: 20)
            : null,
        title: Text(title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              Text(content, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 6,
                  children: tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('#$t',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer)),
                          ))
                      .toList(),
                ),
              ),
            if (updated.isNotEmpty)
              Text(updated,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: '更多',
          onSelected: (v) {
            if (v == 'copy') _copyNote(note);
            if (v == 'export') _exportNote(note);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copy', child: Text('复制')),
            PopupMenuItem(value: 'export', child: Text('导出/分享')),
          ],
        ),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => NoteEditPage(note: note)),
          );
          if (changed == true) _load();
        },
      ),
    );
  }
}
