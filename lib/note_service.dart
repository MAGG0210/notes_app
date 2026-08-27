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

  // ---------- 笔记 CRUD ----------
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final res = await _client
        .from('notes')
        .select()
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>> createNote({required String title, required String content}) async {
    final res = await _client.from('notes').insert({
      'user_id': userId,
      'title': title,
      'content': content,
    }).select().single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    await _client.from('notes').update({
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteNote(String id) async {
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
