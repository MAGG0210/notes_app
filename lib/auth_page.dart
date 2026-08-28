import 'package:flutter/material.dart';
import 'note_service.dart';
import 'app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await NoteService.instance.signIn(email, pass);
      } else {
        await NoteService.instance.signUp(email, pass);
        // 若 Supabase 开了邮箱确认，会提示；这里按已注册处理
        if (mounted) {
          setState(() {
            _error = '注册成功，请登录（若开启邮箱验证请先验证邮箱）';
            _isLogin = true;
            _loading = false;
          });
        }
        return;
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().contains('Invalid login credentials')
              ? '邮箱或密码错误'
              : e.toString().contains('already registered')
                  ? '该邮箱已注册，请直接登录'
                  : '操作失败：$e';
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请先输入邮箱');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await NoteService.instance.resetPassword(email);
      if (mounted) {
        setState(() => _loading = false);
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('重置密码邮件已发送'),
            content: const Text('请前往邮箱查收重置邮件，按邮件提示完成密码重置。'),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('知道了')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '发送失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(
                  colors: [Color(0xFF1B1E3A), Color(0xFF12141B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : AppColors.gradientSoft,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 品牌图标（渐变块）
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sticky_note_2_rounded,
                            color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(_isLogin ? '登录云笔记' : '注册账号',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text('三端互通 · 云备份 · 精致书写',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          child: const Text('忘记密码？'),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.red.shade400, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    GradientButton(
                      loading: _loading,
                      onPressed: _submit,
                      child: Text(
                          _isLogin ? '登 录' : '注 册',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      }),
                      child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
