import 'package:flutter/material.dart';
import 'note_service.dart';

/// 账户管理：查看邮箱、修改密码
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmCtrl.text;
    if (newPass.length < 6) {
      setState(() { _error = '密码至少 6 位'; _success = null; });
      return;
    }
    if (newPass != confirm) {
      setState(() { _error = '两次输入的密码不一致'; _success = null; });
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await NoteService.instance.updatePassword(newPass);
      if (mounted) {
        _newPassCtrl.clear();
        _confirmCtrl.clear();
        setState(() {
          _loading = false;
          _success = '密码修改成功';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '修改失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = NoteService.instance.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('账户')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('登录邮箱'),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 24),
          const Text('修改密码',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码（至少 6 位）',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '确认新密码',
              prefixIcon: Icon(Icons.lock_reset),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Colors.red.shade400)),
          if (_success != null)
            Text(_success!, style: TextStyle(color: Colors.green.shade600)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _changePassword,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('确认修改'),
          ),
        ],
      ),
    );
  }
}
