import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_page.dart';
import 'teacher_home.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  final _emailStudentController = TextEditingController();
  final _passwordStudentController = TextEditingController();
  final _emailTeacherController = TextEditingController();
  final _passwordTeacherController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMeStudent = true;
  bool _rememberMeTeacher = true;

  // PIN controllers
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();

      // Wait for auth provider to initialize if not ready
      if (!authProvider.isInitialized) {
        await authProvider.init();
      }

      debugPrint(
        'Checking remember me: ${authProvider.rememberMe}, email: ${authProvider.rememberedEmail}',
      );

      if (authProvider.rememberMe && authProvider.rememberedEmail != null) {
        if (authProvider.rememberedRole == 'student') {
          _emailStudentController.text = authProvider.rememberedEmail!;
          _passwordStudentController.text =
              authProvider.rememberedPassword ?? '';
          _rememberMeStudent = true;
        } else if (authProvider.rememberedRole == 'teacher') {
          _emailTeacherController.text = authProvider.rememberedEmail!;
          _passwordTeacherController.text =
              authProvider.rememberedPassword ?? '';
          _rememberMeTeacher = true;
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailStudentController.dispose();
    _passwordStudentController.dispose();
    _emailTeacherController.dispose();
    _passwordTeacherController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var n in _pinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _handleStudentLogin() async {
    if (_emailStudentController.text.isEmpty ||
        _passwordStudentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      email: _emailStudentController.text.trim(),
      password: _passwordStudentController.text,
      role: 'student',
    );

    if (result.success) {
      // Always save credentials so silent re-login works on session expiry.
      // The checkbox only controls whether fields are pre-filled on next visit.
      await authProvider.setRememberMe(
        _rememberMeStudent,
        email: _emailStudentController.text.trim(),
        password: _passwordStudentController.text,
        role: 'student',
      );
    }

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  void _handleTeacherLogin() async {
    if (_emailTeacherController.text.isEmpty ||
        _passwordTeacherController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      email: _emailTeacherController.text.trim(),
      password: _passwordTeacherController.text,
      role: 'teacher',
    );

    if (result.success) {
      // Always save credentials so silent re-login works on session expiry.
      await authProvider.setRememberMe(
        _rememberMeTeacher,
        email: _emailTeacherController.text.trim(),
        password: _passwordTeacherController.text,
        role: 'teacher',
      );
    }

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHome()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  void _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.authenticateWithBiometric();

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      if (mounted) {
        if (result.user!.role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  void _showPinLoginDialog() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isPinEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PIN login is not enabled. Please login with email first and enable PIN from your profile.',
          ),
        ),
      );
      return;
    }

    // Clear PIN fields
    for (var c in _pinControllers) {
      c.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.pin_rounded,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Enter PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your 4-digit PIN to login',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _pinControllers[index],
                    focusNode: _pinFocusNodes[index],
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
                          color: Color(0xFF4F46E5),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _pinFocusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                      // Auto submit when all digits entered
                      if (index == 3 && value.isNotEmpty) {
                        _submitPin(ctx);
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitPin(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitPin(BuildContext dialogContext) async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete PIN')),
      );
      return;
    }

    Navigator.pop(dialogContext);
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.authenticateWithPin(pin);

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      if (mounted) {
        if (result.user!.role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFEFF6FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4F46E5),
                        const Color(0xFF7C3AED),
                        const Color(0xFFA78BFA),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(10),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose your role and login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withAlpha(220),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Quick Login Options
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final showQuickLogin =
                            authProvider.isBiometricEnabled ||
                            authProvider.isPinEnabled;
                        if (!showQuickLogin) return const SizedBox.shrink();

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Quick Login',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (authProvider.isBiometricEnabled)
                                  _buildQuickLoginButton(
                                    icon: Icons.fingerprint_rounded,
                                    label: 'Biometric',
                                    color: const Color(0xFF10B981),
                                    onTap: _isLoading
                                        ? null
                                        : _handleBiometricLogin,
                                  ),
                                if (authProvider.isBiometricEnabled &&
                                    authProvider.isPinEnabled)
                                  const SizedBox(width: 16),
                                if (authProvider.isPinEnabled)
                                  _buildQuickLoginButton(
                                    icon: Icons.pin_rounded,
                                    label: 'PIN',
                                    color: const Color(0xFF6366F1),
                                    onTap: _isLoading
                                        ? null
                                        : _showPinLoginDialog,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.school_rounded),
                            text: 'Student',
                          ),
                          Tab(
                            icon: Icon(Icons.person_rounded),
                            text: 'Teacher',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Student Login
                          _buildLoginForm(
                            emailController: _emailStudentController,
                            passwordController: _passwordStudentController,
                            onLogin: _handleStudentLogin,
                            roleColor: const Color(0xFF4F46E5),
                            isLoading: _isLoading,
                            rememberMe: _rememberMeStudent,
                            onRememberMeChanged: (value) {
                              setState(
                                () => _rememberMeStudent = value ?? false,
                              );
                            },
                          ),
                          // Teacher Login
                          _buildLoginForm(
                            emailController: _emailTeacherController,
                            passwordController: _passwordTeacherController,
                            onLogin: _handleTeacherLogin,
                            roleColor: const Color(0xFF7C3AED),
                            isLoading: _isLoading,
                            rememberMe: _rememberMeTeacher,
                            onRememberMeChanged: (value) {
                              setState(
                                () => _rememberMeTeacher = value ?? false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm({
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required VoidCallback onLogin,
    required Color roleColor,
    required bool isLoading,
    required bool rememberMe,
    required ValueChanged<bool?> onRememberMeChanged,
  }) {
    return Column(
      children: [
        // Email Field
        TextField(
          controller: emailController,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_rounded),
            hintText: 'Enter your email',
          ),
        ),
        const SizedBox(height: 16),
        // Password Field
        TextField(
          controller: passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            hintText: 'Enter your password',
          ),
        ),
        const SizedBox(height: 8),
        // Remember Me and Forgot Password Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me Checkbox
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: onRememberMeChanged,
                    activeColor: roleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Remember Me',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            // Forgot Password
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              disabledBackgroundColor: roleColor.withAlpha(150),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withAlpha(200),
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLoginButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
