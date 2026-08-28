import 'package:flutter/material.dart';

/// 云笔记品牌视觉体系
/// 设计语言：Apple Design Awards 风格 —— 柔和渐变 + 玻璃质感 + 极简卡片
/// 配色：暖白书写背景 + 青蓝→靛蓝品牌渐变
class AppColors {
  // 品牌色
  static const primary = Color(0xFF5B67F1); // 靛蓝
  static const primaryLight = Color(0xFF8B93F7);
  static const primaryDeep = Color(0xFF4F46E5);
  static const teal = Color(0xFF06B6D4); // 青

  // 品牌渐变
  static const gradient = LinearGradient(
    colors: [Color(0xFF5B67F1), Color(0xFF7C6CF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientTeal = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF5B67F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSoft = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 亮色
  static const bgLight = Color(0xFFFAF9F6); // 暖白书写背景
  static const surfaceLight = Colors.white;
  static const textLight = Color(0xFF1A1B25);
  static const textLightSecondary = Color(0xFF6B7280);
  static const dividerLight = Color(0xFFECEAE4);

  // 暗色
  static const bgDark = Color(0xFF12141B);
  static const surfaceDark = Color(0xFF1B1E27);
  static const textDark = Color(0xFFF3F4F6);
  static const textDarkSecondary = Color(0xFF9CA3AF);
  static const dividerDark = Color(0xFF2A2E3A);
}

class AppTheme {
  /// 亮色主题
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.surfaceLight,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: scheme,
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontSize: 22,
            fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIconColor: Colors.grey.shade500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AppColors.dividerLight),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerLight),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textLightSecondary,
      ),
    );
  }

  /// 暗色主题
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: AppColors.surfaceDark,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: scheme,
      textTheme: _textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: Colors.grey.shade500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dividerDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AppColors.dividerDark),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerDark),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textDarkSecondary,
      ),
    );
  }

  static TextTheme _textTheme() {
    const base = TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
    );
    return base;
  }
}

/// 渐变按钮（用于主 CTA，如登录按钮）
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  final double height;
  final BorderRadius borderRadius;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.loading = false,
    this.gradient = AppColors.gradient,
    this.height = 52,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: enabled ? gradient : AppColors.gradientSoft,
            borderRadius: borderRadius,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: borderRadius,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : child,
            ),
          ),
        ),
      ),
    );
  }
}
