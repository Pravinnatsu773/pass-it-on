import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/google_sign_in_button.dart';
import '../cubit/auth_cubit.dart';
import '../../../main/presentation/pages/main_layout_page.dart';
import 'profile_setup_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      throw Exception('Test crash from Measure onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayoutPage()),
            );
          } else if (state is AuthProfileIncomplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // App Logo/Name
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(
                      //   Icons.eco_outlined,
                      //   color: Color(0xFF0F4C3A),
                      //   size: 28,
                      // ),
                      // SizedBox(width: 8),
                      Text(
                        'PassItOn',
                        style: TextStyle(
                          color: Color(0xFF0F4C3A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Image section with Rehomed badge
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset('assets/images/pass-it-on.png'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Active in your area pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4F8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF1E5B6E),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Active in Your Area',
                            style: TextStyle(
                              color: Color(0xFF1E5B6E),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title text
                  const Text(
                    'Give more,\nwaste less.',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F4C3A),
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Join your neighborhood giveaway community and pass on the items you no longer need.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5A5A5A),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Google Sign In Button
                  GoogleSignInButton(
                    isLoading: isLoading,
                    onPressed: () {
                      context.read<AuthCubit>().signInWithGoogle();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
