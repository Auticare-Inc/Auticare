import 'package:autismapp/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.favorite,
      title: "Welcome to AutiCare",
      subtitle: "Supporting your child's journey with love and understanding",
      color: Colors.blue,
    ),
    OnboardingStep(
      icon: Icons.shield,
      title: "Safe & Secure Monitoring",
      subtitle: "Privacy-first approach to child safety",
      color: Colors.green,
    ),
    OnboardingStep(
      icon: Icons.people,
      title: "Family Connection",
      subtitle: "Stay connected with loved ones",
      color: Colors.purple,
    ),
    OnboardingStep(
      icon: Icons.analytics,
      title: "Insightful Analytics",
      subtitle: "Data-driven care decisions",
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.goNamed('signupPage');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // void _getStarted() {
  //   context.goNamed('signupPage');
  // }

  // void _skip() {
  //   context.goNamed('signupPage');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
              Color(0xFFF3E5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_steps[index]);
                  },
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AutiCare',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: ()=> context.goNamed('signupPage'),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: index == _currentPage ? 24 : 8,
            decoration: BoxDecoration(
              color: index == _currentPage
                  ? Colors.blue
                  : index < _currentPage
                      ? Colors.green
                      : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage(OnboardingStep step) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(step),
              const SizedBox(height: 40),
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                step.subtitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: step.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 40),
              _buildFeatureCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(OnboardingStep step) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: step.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: step.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureCard(Icons.security, 'Secure', 'End-to-end encryption'),
        _buildFeatureCard(Icons.favorite, 'Caring', 'Designed with love'),
        _buildFeatureCard(Icons.people, 'Connected', 'Family network'),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: _currentPage > 0 ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          Text(
            '${_currentPage + 1} / ${_steps.length}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(_currentPage < _steps.length - 1
                ? Icons.chevron_right
                : Icons.arrow_forward),
            label: Text(_currentPage < _steps.length - 1 ? 'Next' : 'Get Started'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage < _steps.length - 1
                  ? Colors.blue
                  : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}