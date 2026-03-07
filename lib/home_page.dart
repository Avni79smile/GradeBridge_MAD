import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cgpa_page.dart';
import 'percentage_page.dart';
import 'sgpa_page.dart';
import 'pages/analytics_page.dart';
import 'pages/what_if_analysis_page.dart';
import 'pages/settings_page.dart';
import 'providers/calculation_history_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimations = List.generate(
      7,
      (index) => Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.12).clamp(0.0, 1.0),
            (0.6 + (index * 0.12)).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animationController.forward();

    // Load calculations on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalculationHistoryProvider>().loadCalculations();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getCgpaStanding(double cgpa) {
    if (cgpa >= 9.0) return 'Outstanding';
    if (cgpa >= 8.0) return 'Excellent';
    if (cgpa >= 7.0) return 'Very Good';
    if (cgpa >= 6.0) return 'Good Standing';
    if (cgpa >= 5.0) return 'Average';
    if (cgpa >= 4.0) return 'Pass';
    return 'Needs Improvement';
  }

  void _showProfileSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Profile Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9A7), Color(0xFF00D9B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9A7).withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  user?.name ?? 'Student',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Student',
                    style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Email info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_rounded,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'Not provided',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Security Options
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Login Options',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Biometric Toggle
                      if (authProvider.isBiometricAvailable)
                        _buildSecurityToggle(
                          icon: Icons.fingerprint_rounded,
                          label: 'Biometric Login',
                          subtitle: 'Use fingerprint or face to login',
                          value: authProvider.isBiometricEnabled,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          onChanged: (value) async {
                            await authProvider.setBiometricEnabled(value);
                          },
                        ),
                      if (authProvider.isBiometricAvailable)
                        const SizedBox(height: 12),
                      // PIN Toggle
                      _buildSecurityToggle(
                        icon: Icons.pin_rounded,
                        label: 'PIN Login',
                        subtitle: authProvider.isPinEnabled
                            ? 'PIN is set up'
                            : 'Set up a 4-digit PIN',
                        value: authProvider.isPinEnabled,
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                        onChanged: (value) {
                          if (value) {
                            Navigator.pop(ctx);
                            _showSetPinDialog(context);
                          } else {
                            authProvider.removePin();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Member since
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Member Since',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(user?.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showLogoutConfirmation(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSecurityToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Color color,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ],
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final pinControllers = List.generate(4, (_) => TextEditingController());
    final pinFocusNodes = List.generate(4, (_) => FocusNode());
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.pin_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Set PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create a 4-digit PIN for quick login',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: pinControllers[index],
                    focusNode: pinFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        pinFocusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        pinFocusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (var c in pinControllers) {
                c.dispose();
              }
              for (var n in pinFocusNodes) {
                n.dispose();
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinControllers.map((c) => c.text).join();
              if (pin.length != 4) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Please enter 4 digits')),
                );
                return;
              }

              for (var c in pinControllers) {
                c.dispose();
              }
              for (var n in pinFocusNodes) {
                n.dispose();
              }

              Navigator.pop(ctx);

              final success = await authProvider.setPin(pin);
              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('PIN set successfully!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Set PIN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final List<Color> gradientColors = themeProvider.isDarkMode
            ? [
                const Color(0xFF1E3A8A), // Dark blue
                const Color(0xFF2563EB), // Medium blue
                const Color(0xFF3B82F6), // Light blue
              ]
            : [
                const Color(0xFFEFF6FF), // Very light blue
                const Color(0xFFDEEDFF), // Light blue
                const Color(0xFFBFDBFE), // Lighter blue
              ];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Custom AppBar with controls
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final userName =
                                authProvider.currentUser?.name ?? 'Student';
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome, $userName',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Student Dashboard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return IconButton(
                            icon: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => themeProvider.toggleTheme(),
                          );
                        },
                      ),
                      // Profile Avatar
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final user = authProvider.currentUser;
                          final initial = user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'S';
                          return GestureDetector(
                            onTap: () => _showProfileSheet(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C9A7),
                                    Color(0xFF00D9B8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withAlpha(100),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Main content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Top stats cards
                      Row(
                        children: [
                          // CGPA Card
                          Expanded(
                            child: Consumer<CalculationHistoryProvider>(
                              builder: (context, provider, _) {
                                final cgpaCalcs = provider
                                    .getCalculationsByType('CGPA');
                                final latestCgpa = cgpaCalcs.isNotEmpty
                                    ? cgpaCalcs.last.result
                                    : null;
                                final cgpaStr = latestCgpa != null
                                    ? latestCgpa.toStringAsFixed(2)
                                    : '--';
                                final subtitle = latestCgpa != null
                                    ? _getCgpaStanding(latestCgpa)
                                    : 'No calculations yet';
                                return _buildTopCard(
                                  title: 'CGPA',
                                  value: cgpaStr,
                                  subtitle: subtitle,
                                  icon: Icons.school_rounded,
                                  color: const Color(0xFF3B82F6),
                                  index: 0,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CGPAPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // History Card
                          Expanded(
                            child: Consumer<CalculationHistoryProvider>(
                              builder: (context, provider, _) {
                                return _buildTopCard(
                                  title: 'History',
                                  value: '${provider.calculations.length}',
                                  subtitle: 'Calculations Saved',
                                  icon: Icons.history_rounded,
                                  color: const Color(0xFF10B981),
                                  index: 1,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AnalyticsPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Calculator cards grid - 2 columns
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildAnimatedCard(
                                2,
                                'Percentage',
                                'Calculate',
                                Icons.percent_rounded,
                                const Color(0xFFF59E0B),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PercentagePage(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAnimatedCard(
                                3,
                                'SGPA',
                                'Calculate',
                                Icons.school_rounded,
                                const Color(0xFFEC4899),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SGPAPage(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Analytics and What-If cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedCard(
                              4,
                              'Analytics',
                              'Performance Stats',
                              Icons.trending_up_rounded,
                              const Color(0xFF06B6D4),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnimatedCard(
                              5,
                              'What-If',
                              'GPA Predictor',
                              Icons.help_outline_rounded,
                              const Color(0xFFD946EF),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WhatIfAnalysisPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Settings card
                      _buildAnimatedCard(
                        6,
                        'Settings',
                        'Customize App',
                        Icons.settings_rounded,
                        const Color(0xFF64748B),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 20),
                      // Bottom action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('Export to PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(200),
                                foregroundColor: const Color(0xFF1E3A8A),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WhatIfAnalysisPage(),
                                ),
                              ),
                              icon: const Icon(Icons.calculate_rounded),
                              label: const Text('What-If'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withAlpha(30),
          highlightColor: color.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withAlpha(240), color.withAlpha(200)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Decorative circles - top right
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Decorative circles - small
                  Positioned(
                    top: 30,
                    right: 40,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 30,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, size: 28, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(60),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(240),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
    int index,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withAlpha(30),
          highlightColor: color.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withAlpha(240), color.withAlpha(200)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
            ),
            child: Stack(
              children: [
                // Decorative circles - top right
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Decorative circles - bottom right
                Positioned(
                  top: 50,
                  right: -60,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Decorative circles - bottom left
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Small decorative circles
                Positioned(
                  top: 30,
                  right: 30,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  right: 40,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 40,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(220),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
