import 'package:flutter/material.dart';

/// 航班打卡主题色 —— 对齐旧 web 前端的设计 token
class AppColors {
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF2563EB);
  static const primaryBg = Color(0xFFEFF6FF);
  static const accent = Color(0xFF93C5FD);
  static const accentLight = Color(0xFFDBEAFE);

  static const bg = Color(0xFFF0F4F8);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textLight = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // 排行榜用色
  static const lbFirst = Color(0xFF93C5FD);
  static const lbSecond = Color(0xFFBFDBFE);
  static const lbThird = Color(0xFFC4B5FD);
  static const lbFourth = Color(0xFFA5B4FC);
  static const lbFifth = Color(0xFFBAE6FD);
}

/// 主题里的尺寸用移动端基准值写死（ThemeData 在 GetMaterialApp.theme
/// 时构造，那时还没有 BuildContext）。需要响应式的样式请在 widget 里用
/// `context.r.xxx` 覆盖（这些 token 仍会被 widget 级样式覆盖）。
class _Baseline {
  // 移动端基准值，对应 iPhone 14 (390x844)
  static const double gap = 16.0;
  static const double gapSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double textMd = 15.0;
  static const double textLg = 17.0;
  static const double buttonH = 52.0;
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      fontFamily: 'PingFang SC',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: _Baseline.textLg,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusLg),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _Baseline.gap,
          vertical: _Baseline.gapSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textLight),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(_Baseline.buttonH),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: _Baseline.textMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          ),
        ),
      ),
    );
  }
}