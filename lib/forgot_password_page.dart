import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailStudentController = TextEditingController();
  final _emailTeacherController = TextEditingController();
  bool _isLoading = false;

  // Track which tabs have successfully sent a reset email
  bool _studentEmailSent = false;
  bool _teacherEmailSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailStudentController.dispose();
    _emailTeacherController.dispose();
    super.dispose();
  }

  Future<void> _sendReset(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(email: email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      if (_tabController.index == 0) {
        setState(() => _studentEmailSent = true);
      } else {
        setState(() => _teacherEmailSent = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFEFF6FF),
            ],
            stops: [0.0, 0.5, 1.0],
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF7C3AED),
                        Color(0xFFA78BFA),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
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
                              'We will send a reset link to your email',
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
                          Tab(icon: Icon(Icons.school_rounded), text: 'Student'),
                          Tab(icon: Icon(Icons.person_rounded), text: 'Teacher'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildResetForm(
                            emailController: _emailStudentController,
                            roleColor: const Color(0xFF4F46E5),
                            emailSent: _studentEmailSent,
                          ),
                          _buildResetForm(
                            emailController: _emailTeacherController,
                            roleColor: const Color(0xFF7C3AED),
                            emailSent: _teacherEmailSent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Remember your password? ",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildResetForm({
    required TextEditingController emailController,
    required Color roleColor,
    required bool emailSent,
  }) {
    if (emailSent) {
      // Success state
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check your inbox!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A password reset link has been sent to ${emailController.text.trim()}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in the email to set a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: () => setState(() {
                  if (_tabController.index == 0) {
                    _studentEmailSent = false;
                    _emailStudentController.clear();
                  } else {
                    _teacherEmailSent = false;
                    _emailTeacherController.clear();
                  }
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Use a different email'),
              ),
            ],
          ),
        ),
      );
    }

    // Input state
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'How to reset your password:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Enter your registered email address'),
                const SizedBox(height: 8),
                _buildStep('2', 'Click "Send Reset Link"'),
                const SizedBox(height: 8),
                _buildStep('3', 'Open the email and click the reset link'),
                const SizedBox(height: 8),
                _buildStep('4', 'Set your new password on the page that opens'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Email field
          TextField(
            controller: emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_rounded),
              hintText: 'Enter your registered email',
            ),
          ),
          const SizedBox(height: 24),
          // Send button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _sendReset(emailController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                disabledBackgroundColor: roleColor.withAlpha(150),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withAlpha(200),
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isLoading ? 'Sending...' : 'SEND RESET LINK',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.blue[800],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
