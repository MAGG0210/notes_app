import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------- 初始化 ----------
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  // ---------- 认证 ----------
  bool get isLoggedIn => _client.auth.currentSession != null;
  String? get userId => _client.auth.currentUser?.id;
  String? get email => _client.auth.currentUser?.email;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ---------- 账户 ----------
  /// 修改密码（需已登录）
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// 发送重置密码邮件（忘记密码流程）
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ---------- 笔记 CRUD ----------
  /// 拉取正常笔记（排除回收站），置顶优先，再按更新时间倒序。
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final res = await _client
        .from('notes')
        .select()
        .isFilter('deleted_at', null)
        .order('pinned', ascending: false)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// 拉取回收站里的笔记（已软删除），按删除时间倒序。
  Future<List<Map<String, dynamic>>> fetchTrash() async {
    final res = await _client
        .from('notes')
        .select()
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
    bool pinned = false,
  }) async {
    final res = await _client.from('notes').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'pinned': pinned,
    }).select().single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
    List<String> tags = const [],
    bool pinned = false,
  }) async {
    // updated_at 由数据库触发器自动更新，客户端不手动传
    await _client.from('notes').update({
      'title': title,
      'content': content,
      'tags': tags,
      'pinned': pinned,
    }).eq('id', id);
  }

  /// 软删除：笔记移入回收站（不物理删除）
  Future<void> deleteNote(String id) async {
    await _client.from('notes').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// 恢复：从回收站还原笔记
  Future<void> restoreNote(String id) async {
    await _client.from('notes').update({'deleted_at': null}).eq('id', id);
  }

  /// 永久删除：从回收站彻底清除
  Future<void> purgeNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  // ---------- 实时同步 ----------
  /// 订阅 notes 表变化，返回可取消的订阅流。
  /// 任何端增删改笔记，这里都会收到通知，实现多端实时互通。
  RealtimeChannel subscribeNotes({
    required void Function() onChanged,
    String? forUserId,
  }) {
    final channel = _client.channel('notes-changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notes',
      callback: (payload) {
        // 可选：只响应当前用户的笔记变化
        final newUserId = payload.newRecord['user_id']?.toString();
        final oldUserId = payload.oldRecord['user_id']?.toString();
        if (forUserId != null &&
            newUserId != forUserId &&
            oldUserId != forUserId) {
          return;
        }
        onChanged();
      },
    ).subscribe();

    return channel;
  }
}
