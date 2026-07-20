import 'package:flutter/material.dart';

class AppErrorDialog extends StatelessWidget {
  const AppErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.suggestion,
    this.icon = Icons.warning_amber_rounded,
    this.iconColor,
    this.buttonText = 'Got It',
    this.onPressed,
  });

  final String title;
  final String message;
  final String? suggestion;
  final IconData icon;
  final Color? iconColor;
  final String buttonText;
  final VoidCallback? onPressed;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? suggestion,
    IconData icon = Icons.warning_amber_rounded,
    Color? iconColor,
    String buttonText = 'Got It',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AppErrorDialog(
        title: title,
        message: message,
        suggestion: suggestion,
        icon: icon,
        iconColor: iconColor,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = iconColor ?? theme.colorScheme.error;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (suggestion != null && suggestion!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPressed != null) onPressed!();
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
