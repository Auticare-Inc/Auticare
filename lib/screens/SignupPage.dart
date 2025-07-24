import 'package:autismapp/cubits/authState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/authCubit.dart';
import '../models/FirestoreDatabase.dart';
import 'utilities/textField.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final caregiverEmailController = TextEditingController();
  final caregiverNameController = TextEditingController();
  final childNameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool registerPressed = false;

  @override
  void initState() {
    super.initState();
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

  void register()async{

    setState(() {
    registerPressed = true;
    });
    final String email = emailController.text.trim();
    final String pw = passwordController.text;
    final String name = nameController.text;
    final String confirmPw = confirmPasswordController.text;
    final String caregiverEmail = caregiverEmailController.text;
    final String caregiverName = caregiverNameController.text;
    final String childName = childNameController.text;

    // authCubit
    final authCubit = context.read<Authcubit>();
    // ensure fields are filled up
    if (email.isNotEmpty && pw.isNotEmpty && name.isNotEmpty && confirmPw.isNotEmpty) {
      if (pw == confirmPw) {
        await authCubit.register(email, pw, name,caregiverEmail,caregiverName,childName);
        await Firestoredatabase.createCaregiverDetails(
          childName: childName,
          caregiverEmail: caregiverEmail, 
          caregiverName: caregiverName, 
          caregiverType: null,
          caregiverContact: null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Passwords don\'t match'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter required fields"),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    caregiverEmailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     resizeToAvoidBottomInset: false,
  //     body: Container(
  //       decoration: const BoxDecoration(
  //         gradient: LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [
  //             Color(0xFFE3F2FD),
  //             Colors.white,
  //             Color(0xFFF3E5F5),
  //           ],
  //         ),
  //       ),
  //       child: Stack(
  //         children: [
  //           // Decorative floating elements
  //           Positioned(
  //             top: 80,
  //             left: 30,
  //             child: Container(
  //               width: 60,
  //               height: 60,
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.shade200.withOpacity(0.3),
  //                 borderRadius: BorderRadius.circular(30),
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             bottom: 150,
  //             right: 40,
  //             child: Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: Colors.purple.shade200.withOpacity(0.3),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             top: 200,
  //             right: 20,
  //             child: Container(
  //               width: 30,
  //               height: 30,
  //               decoration: BoxDecoration(
  //                 color: Colors.green.shade200.withOpacity(0.3),
  //                 borderRadius: BorderRadius.circular(15),
  //               ),
  //             ),
  //           ),
            
  //           SafeArea(
  //             child: FadeTransition(
  //               opacity: _fadeAnimation,
  //               child: SlideTransition(
  //                 position: _slideAnimation,
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 32),
  //                   child: Column(
  //                     children: [
  //                       const SizedBox(height: 20),
  //                       // Header with logo
  //                       _buildHeader(),
  //                       const SizedBox(height: 40),
                        
  //                       // Main form container
  //                       Expanded(
  //                         child: SingleChildScrollView(
  //                           child: Column(
  //                             children: [
  //                               _buildFormSection(),
  //                               const SizedBox(height: 32),
  //                               _buildSignupButton(),
  //                               const SizedBox(height: 40),
  //                               _buildBrandFooter(),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        child: Stack(
          children: [
            // Decorative floating elements
            Positioned(
              top: 80,
              left: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: 40,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple.shade200.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 20,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green.shade200.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Header with logo
                        _buildHeader(),
                        const SizedBox(height: 40),
                        
                        // Main form container
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildFormSection(),
                                const SizedBox(height: 32),
                                _buildSignupButton(),
                                const SizedBox(height: 40),
                                _buildBrandFooter(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo section
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              child: const Icon(
                Icons.shield,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'CareConnect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Title and subtitle
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Join our caring community and start your journey',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        
        // Login link
        Row(
          children: [
            Text(
              'Already have an account?',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            GestureDetector(
              onTap: () => context.goNamed('loginPage'),
              child: const Text(
                ' Sign in',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildEnhancedTextField(
            controller: nameController,
            hintText: 'Full Name',
            icon: Icons.person_outline,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),

          _buildEnhancedTextField(
            controller: childNameController,
            hintText: 'Child\'s Name',
            icon: Icons.person_outline,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          
          _buildEnhancedTextField(
            controller: emailController,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          
          _buildEnhancedTextField(
            controller: passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            color: Colors.purple,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          
          _buildEnhancedTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock_outline,
            color: Colors.purple,
            obscureText: true,
          ),
          const SizedBox(height: 20),

          _buildEnhancedTextField(
            controller: caregiverNameController,
            hintText: 'Caregiver Name (Optional)',
            icon: Icons.supervised_user_circle,
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          
          _buildEnhancedTextField(
            controller: caregiverEmailController,
            hintText: 'Caregiver Email (Optional)',
            icon: Icons.supervisor_account_outlined,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color color,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: color,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return BlocListener<Authcubit,AuthState>(listener:(context,state){
      if(state is Authloading && registerPressed){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loading...'),
            backgroundColor: Colors.blue.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
      } else if(state is Authenticated && registerPressed){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Authenticated'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
        );
        setState(() {
        registerPressed = false; 
      });
        context.goNamed('loginPage');
      } else if(state is AuthError && registerPressed){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$state.message'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
        );
        setState(() {
        registerPressed = false; 
      });
      }
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: ()=> register(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    )
    );
  }

  

  Widget _buildBrandFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CareConnect',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The smart way to care',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}