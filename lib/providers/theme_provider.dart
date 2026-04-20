import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeColor { blue, purple, green, orange, teal, rose }

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  AppThemeColor _themeColor = AppThemeColor.blue;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;
  AppThemeColor get teacherThemeColor => _themeColor;
  AppThemeColor get themeColor => _themeColor;

  static const lightGradients = <AppThemeColor, List<Color>>{
    AppThemeColor.blue: [
      Color(0xFF1E3A8A),
      Color(0xFF2563EB),
      Color(0xFF3B82F6),
    ],
    AppThemeColor.purple: [
      Color(0xFF3B0764),
      Color(0xFF7C3AED),
      Color(0xFF8B5CF6),
    ],
    AppThemeColor.green: [
      Color(0xFF064E3B),
      Color(0xFF059669),
      Color(0xFF10B981),
    ],
    AppThemeColor.orange: [
      Color(0xFF7C2D12),
      Color(0xFFEA580C),
      Color(0xFFF97316),
    ],
    AppThemeColor.teal: [
      Color(0xFF134E4A),
      Color(0xFF0F766E),
      Color(0xFF14B8A6),
    ],
    AppThemeColor.rose: [
      Color(0xFF881337),
      Color(0xFFBE123C),
      Color(0xFFF43F5E),
    ],
  };

  static const themeColorNames = <AppThemeColor, String>{
    AppThemeColor.blue: 'Ocean Blue',
    AppThemeColor.purple: 'Purple',
    AppThemeColor.green: 'Emerald',
    AppThemeColor.orange: 'Sunset',
    AppThemeColor.teal: 'Teal',
    AppThemeColor.rose: 'Rose',
  };

  List<Color> get teacherGradientColors {
    if (_isDarkMode) {
      return const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)];
    }
    return lightGradients[_themeColor]!;
  }

  List<Color> get gradientColors => teacherGradientColors;

  Color get teacherAccentColor =>
      _isDarkMode ? const Color(0xFF818CF8) : lightGradients[_themeColor]![1];

  Color get teacherAccentStrongColor =>
      _isDarkMode ? const Color(0xFF6366F1) : lightGradients[_themeColor]![2];

  Color get accentColor => teacherAccentColor;

  ThemeProvider() {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    final colorIndex = _prefs.getInt('themeColor') ?? 0;
    _themeColor = AppThemeColor
        .values[colorIndex.clamp(0, AppThemeColor.values.length - 1)];
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setTeacherThemeColor(AppThemeColor color) {
    _themeColor = color;
    _prefs.setInt('themeColor', color.index);
    notifyListeners();
  }

  void setThemeColor(AppThemeColor color) {
    setTeacherThemeColor(color);
  }

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4F46E5),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6366F1),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6366F1)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: const Color(0xFF1E293B),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
