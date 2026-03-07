import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'teacher_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeInOutQuad),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      _navigateBasedOnAuth();
    });
  }

  void _navigateBasedOnAuth() async {
    final authProvider = context.read<AuthProvider>();

    // Wait for auth provider to initialize (max 2 seconds additional wait)
    int attempts = 0;
    while (!authProvider.isInitialized && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      // User is logged in, navigate based on role
      if (authProvider.currentUser!.role == 'teacher') {
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
    } else {
      // Not logged in, go to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B).withAlpha(230),
              const Color(0xFF312E81).withAlpha(200),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated floating circles background
            Positioned(
              top: -150,
              left: -100,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      sin(_animationController.value * 2 * 3.14) * 30,
                      cos(_animationController.value * 2 * 3.14) * 30,
                    ),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4F46E5).withAlpha(40),
                            const Color(0xFF4F46E5).withAlpha(10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      -sin(_animationController.value * 2 * 3.14) * 20,
                      -cos(_animationController.value * 2 * 3.14) * 20,
                    ),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7C3AED).withAlpha(30),
                            const Color(0xFF7C3AED).withAlpha(5),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo with glassmorphism
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4F46E5).withAlpha(80),
                            const Color(0xFF7C3AED).withAlpha(60),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withAlpha(76),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withAlpha(50),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withAlpha(30),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.trending_up_rounded,
                          size: 70,
                          color: Colors.white.withAlpha(240),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Animated text content
                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'GradeBridge',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF4F46E5).withAlpha(100),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Animated underline
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.4,
                                  0.8,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 120,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4F46E5),
                                    const Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your Academic Companion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(200),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  // Animated loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withAlpha(200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
