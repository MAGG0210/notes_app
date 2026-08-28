import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局主题模式存储：跟随系统 / 亮色 / 暗色
/// 通过 ValueNotifier 通知界面实时切换。
class ThemeStore {
  static const _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.system);

  static ThemeMode get current => notifier.value;

  /// 应用启动时读取本地偏好
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
    notifier.value = mode;
  }

  /// 切换主题并持久化
  static Future<void> set(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
