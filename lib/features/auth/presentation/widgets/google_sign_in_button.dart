import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: 'Continue with Google',
      hint: 'Double tap to sign in with your Google account',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48.0,
          minWidth: double.infinity,
        ),
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading 
              ? const SizedBox.shrink() 
              : const FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 20),
          label: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  'Continue with Google',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.onBackground,
          ),
        ),
      ),
    );
  }
}
