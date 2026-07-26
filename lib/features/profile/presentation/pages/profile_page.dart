import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/presentation/pages/landing_page.dart';
import 'privacy_policy_page.dart';
import 'about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    }
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Name',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F4C3A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F6F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your new name',
                      hintStyle: TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFF8B8B8B),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      context.read<AuthCubit>().updateProfile(name: newName);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C3A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Semantics(header: true, child: Text(title)),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 24.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF5A5A5A),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required Widget leading,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTop ? 16 : 0),
          bottom: Radius.circular(isBottom ? 16 : 0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: onTap != null,
          label: title,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isTop ? 16 : 0),
              bottom: Radius.circular(isBottom ? 16 : 0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(child: leading),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                  ),
                  if (trailing != null) ExcludeSemantics(child: trailing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBFA),
        body: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              String name = 'Loading...';
              String? photoUrl;

              if (state is AuthAuthenticated) {
                name = state.userModel.name;
                photoUrl = state.userModel.photoUrl ?? state.user.photoURL;
              } else if (state is AuthProfileIncomplete) {
                name = state.user.displayName ?? 'No Name';
                photoUrl = state.user.photoURL;
              }

              return ListView(
                primary: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                children: [
                  // Removed Header
                  const SizedBox(height: 24),

                  // Profile Card
                  Semantics(
                    button: true,
                    label: 'Edit Profile',
                    child: GestureDetector(
                      onTap: () => _showEditNameDialog(context, name),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: photoUrl != null
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1C1E),
                                    ),
                                  ),
                                  // const SizedBox(height: 4),
                                  // const Text(
                                  //   'Community Hero • 42 Items Passed',
                                  //   style: TextStyle(
                                  //     fontSize: 13,
                                  //     color: Color(0xFF5A5A5A),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            ExcludeSemantics(
                              child: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF0F4C3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SECURITY & DATA SECTION
                  _buildSectionHeader('SECURITY & DATA'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          isTop: true,
                          leading: _buildIconContainer(
                            Icons.lock_outline,
                            const Color(0xFFFCECD9),
                            const Color(0xFF9E5C1B),
                          ),
                          title: 'Privacy Policy',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 64),
                        _buildListTile(
                          isBottom: true,
                          leading: _buildIconContainer(
                            Icons.logout,
                            const Color(0xFFFBE4E4),
                            const Color(0xFFB3261E),
                          ),
                          title: 'Logout',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                  'Are you sure you want to log out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFF5A5A5A),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              context.read<AuthCubit>().logout();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // ABOUT SECTION
                  _buildSectionHeader('ABOUT'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          isTop: true,
                          leading: _buildIconContainer(
                            Icons.info_outline,
                            const Color(0xFFA5E6C9),
                            const Color(0xFF0F4C3A),
                          ),
                          title: 'About PassItOn',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AboutPage()),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildListTile(
                          isBottom: true,
                          leading: _buildIconContainer(
                            Icons.history,
                            const Color(0xFFA5E6C9),
                            const Color(0xFF0F4C3A),
                          ),
                          title: 'Version',
                          trailing: Text(
                            _appVersion,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
