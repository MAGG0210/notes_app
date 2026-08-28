import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'note_service.dart';

/// 新建 / 编辑笔记页面
class NoteEditPage extends StatefulWidget {
  final Map<String, dynamic>? note; // null = 新建
  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _tagCtrl;
  late List<String> _tags;
  late bool _pinned;
  bool _previewMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.note?['content'] ?? '');
    _tagCtrl = TextEditingController();
    _tags = List<String>.from(
        (widget.note?['tags'] as List?)?.map((e) => e.toString()) ?? []);
    _pinned = widget.note?['pinned'] == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().replaceAll('#', '');
    if (tag.isEmpty) return;
    if (_tags.contains(tag)) {
      _tagCtrl.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final title = _titleCtrl.text.trim().isEmpty
        ? '无标题'
        : _titleCtrl.text.trim();
    final content = _contentCtrl.text;
    try {
      if (widget.note == null) {
        await NoteService.instance.createNote(
            title: title, content: content, tags: _tags, pinned: _pinned);
      } else {
        await NoteService.instance.updateNote(
            id: widget.note!['id'] as String,
            title: title,
            content: content,
            tags: _tags,
            pinned: _pinned);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _delete() async {
    if (widget.note == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除笔记？'),
        content: const Text('将移入回收站，可在回收站恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('删除')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await NoteService.instance.deleteNote(widget.note!['id'] as String);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _saving ? null : _delete,
            ),
          IconButton(
            icon: Icon(_previewMode
                ? Icons.edit_outlined
                : Icons.visibility_outlined),
            tooltip: _previewMode ? '编辑模式' : 'Markdown 预览',
            onPressed: _saving ? null : () => setState(() {
                  _previewMode = !_previewMode;
                }),
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            tooltip: '保存',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // 置顶开关
          SwitchListTile(
            dense: true,
            secondary: Icon(
              Icons.push_pin_outlined,
              color: _pinned ? Colors.orange.shade600 : null,
            ),
            title: const Text('置顶笔记'),
            value: _pinned,
            onChanged: _saving
                ? null
                : (v) => setState(() => _pinned = v),
          ),
          const Divider(height: 1),
          // 标签输入区
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._tags.map((t) => InputChip(
                      label: Text('#$t'),
                      visualDensity: VisualDensity.compact,
                      onDeleted: _saving ? null : () => _removeTag(t),
                    )),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _tagCtrl,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      hintText: '添加标签后回车',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // 正文区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: '标题',
                      border: InputBorder.none,
                    ),
                  ),
                  Expanded(
                    child: _previewMode
                        ? SingleChildScrollView(
                            child: MarkdownBody(data: _contentCtrl.text),
                          )
                        : TextField(
                            controller: _contentCtrl,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: '支持 Markdown 语法…',
                              border: InputBorder.none,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
