import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_page.dart';
import 'teacher_home.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Student controllers
  final _nameStudentController = TextEditingController();
  final _emailStudentController = TextEditingController();
  final _passwordStudentController = TextEditingController();
  final _confirmPasswordStudentController = TextEditingController();

  // Teacher controllers
  final _nameTeacherController = TextEditingController();
  final _emailTeacherController = TextEditingController();
  final _passwordTeacherController = TextEditingController();
  final _confirmPasswordTeacherController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameStudentController.dispose();
    _emailStudentController.dispose();
    _passwordStudentController.dispose();
    _confirmPasswordStudentController.dispose();
    _nameTeacherController.dispose();
    _emailTeacherController.dispose();
    _passwordTeacherController.dispose();
    _confirmPasswordTeacherController.dispose();
    super.dispose();
  }

  void _handleStudentSignUp() async {
    if (_nameStudentController.text.isEmpty ||
        _emailStudentController.text.isEmpty ||
        _passwordStudentController.text.isEmpty ||
        _confirmPasswordStudentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_passwordStudentController.text !=
        _confirmPasswordStudentController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_passwordStudentController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signUp(
      name: _nameStudentController.text.trim(),
      email: _emailStudentController.text.trim(),
      password: _passwordStudentController.text,
      role: 'student',
    );

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
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

  void _handleTeacherSignUp() async {
    if (_nameTeacherController.text.isEmpty ||
        _emailTeacherController.text.isEmpty ||
        _passwordTeacherController.text.isEmpty ||
        _confirmPasswordTeacherController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_passwordTeacherController.text !=
        _confirmPasswordTeacherController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_passwordTeacherController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signUp(
      name: _nameTeacherController.text.trim(),
      email: _emailTeacherController.text.trim(),
      password: _passwordTeacherController.text,
      role: 'teacher',
    );

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
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
                              'Create Account',
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
                              'Choose your role and sign up',
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
                          // Student Sign Up
                          _buildSignUpForm(
                            nameController: _nameStudentController,
                            emailController: _emailStudentController,
                            passwordController: _passwordStudentController,
                            confirmPasswordController:
                                _confirmPasswordStudentController,
                            onSignUp: _handleStudentSignUp,
                            roleColor: const Color(0xFF4F46E5),
                            isLoading: _isLoading,
                          ),
                          // Teacher Sign Up
                          _buildSignUpForm(
                            nameController: _nameTeacherController,
                            emailController: _emailTeacherController,
                            passwordController: _passwordTeacherController,
                            confirmPasswordController:
                                _confirmPasswordTeacherController,
                            onSignUp: _handleTeacherSignUp,
                            roleColor: const Color(0xFF7C3AED),
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
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

  Widget _buildSignUpForm({
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required VoidCallback onSignUp,
    required Color roleColor,
    required bool isLoading,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Name Field
          TextField(
            controller: nameController,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_rounded),
              hintText: 'Enter your full name',
            ),
          ),
          const SizedBox(height: 14),
          // Email Field
          TextField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_rounded),
              hintText: 'Enter your email',
            ),
          ),
          const SizedBox(height: 14),
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
              hintText: 'At least 6 characters',
            ),
          ),
          const SizedBox(height: 14),
          // Confirm Password Field
          TextField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              hintText: 'Re-enter your password',
            ),
          ),
          const SizedBox(height: 24),
          // Sign Up Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSignUp,
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
                        Icon(Icons.person_add_rounded, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'SIGN UP',
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
      ),
    );
  }
}
