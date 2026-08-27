import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'note_service.dart';
import 'auth_page.dart';
import 'notes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NoteService.init();
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云笔记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8DEF)),
        useMaterial3: true,
      ),
      home: const RootPage(),
    );
  }
}

/// 根据登录状态切换：未登录 -> 登录页；已登录 -> 笔记列表
/// 监听 Supabase 认证状态流，任何端登录/登出都会实时反映。
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const NotesPage();
        }
        return const AuthPage();
      },
    );
  }
}
