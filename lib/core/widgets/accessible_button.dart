import 'package:flutter/material.dart';

/// A foundational button that enforces accessibility standards.
/// It wraps the button in a [Semantics] widget to provide clear context to 
/// screen readers (like TalkBack or VoiceOver) and ensures the tap target 
/// is at least 48x48 logical pixels.
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? semanticHint;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticHint,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: label,
      hint: semanticHint ?? 'Double tap to activate',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48.0, // Minimum height for accessibility
          minWidth: 48.0,  // Minimum width for accessibility
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  // Use TextScaler to ensure text inside button scales properly
                  textScaler: MediaQuery.textScalerOf(context), 
                ),
        ),
      ),
    );
  }
}
