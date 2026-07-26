import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../../../main/presentation/pages/main_layout_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from current user if available
    final cubit = context.read<AuthCubit>();
    if (cubit.state is AuthProfileIncomplete) {
      final user = (cubit.state as AuthProfileIncomplete).user;
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().completeProfile(
        name: _nameController.text.trim(),
        imageFile: _selectedImage,
      );
    }
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
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          _isLoading = state is AuthLoading;
          final currentUser = (state is AuthProfileIncomplete) ? state.user : null;
          final photoUrl = currentUser?.photoURL;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Header similar to LandingPage
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco_outlined, color: Color(0xFF0F4C3A), size: 28),
                        SizedBox(width: 8),
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
                    const SizedBox(height: 48),
                    // Title
                    const Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F4C3A),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Semantics(
                      button: true,
                      label: 'Pick profile picture',
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 64,
                                  backgroundColor: const Color(0xFFE8F4F8),
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null) as ImageProvider?,
                                  child: _selectedImage == null && photoUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Color(0xFF1E5B6E))
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA5E6C9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Color(0xFF0F4C3A), size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ExcludeSemantics(
                      child: const Text(
                        'Tap to change picture',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Semantics(
                        label: 'Full Name',
                        child: TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E5B6E)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C3A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Complete Setup',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
