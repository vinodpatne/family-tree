import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/app_config.dart';
import '../../state/providers.dart';
import '../../utils/gis_helper.dart';

import '../../widgets/app_error_dialog.dart';

final _googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? AppConfig.googleClientId : null,
  scopes: ['email', 'profile'],
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final userInfo = await signInWithGISWeb(AppConfig.googleClientId);
        if (userInfo != null && userInfo['email'] != null) {
          final email = userInfo['email'] as String;
          final name = userInfo['name'] as String?;
          final avatarUrl = userInfo['picture'] as String?;
          final googleId = userInfo['sub'] as String?;

          await ref.read(repositoryProvider).signInWithGoogle(
            idToken: null,
            email: email,
            name: name,
            avatarUrl: avatarUrl,
            googleId: googleId,
          );
          if (mounted) context.go('/');
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign in was cancelled or incomplete.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.disconnect();
        } else {
          try {
            await _googleSignIn.disconnect();
          } catch (_) {}
        }
        final account = await _googleSignIn.signIn();
        if (account != null) {
          final auth = await account.authentication;
          final idToken = auth.idToken;
          await ref.read(repositoryProvider).signInWithGoogle(
            idToken: idToken,
            email: account.email,
            name: account.displayName,
            avatarUrl: account.photoUrl,
            googleId: account.id,
          );
          if (mounted) context.go('/');
          return;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign in was cancelled.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } on MissingPluginException catch (e) {
      debugPrint('MissingPluginException: $e');
      if (mounted) {
        _showRestartRequiredDialog();
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup_closed') ||
          errStr.contains('popup window closed') ||
          errStr.contains('closed by user') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled') ||
          errStr.contains('user_closed') ||
          errStr.contains('access_denied') ||
          errStr.contains('dismissed')) {
        debugPrint('User closed Google sign-in window.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in window was closed. Click button to try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('Authentication Notice: $e');
        if (mounted) {
          _showAuthErrorDialog(e.toString());
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRestartRequiredDialog() {
    AppErrorDialog.show(
      context,
      title: 'Application Restart Needed',
      message: 'Google Sign-In plugin was newly added to the project.',
      suggestion: 'Please restart the running app process in your terminal to complete registration.',
      icon: Icons.published_with_changes_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      buttonText: 'Got It',
    );
  }

  void _showAuthErrorDialog(String error) {
    final errLower = error.toLowerCase();
    String userFriendlyMsg = 'Could not complete Google Sign-In.';
    String? suggestion = 'Please check your connection and ensure the backend service is running.';

    if (errLower.contains('socketexception') ||
        errLower.contains('connection refused') ||
        errLower.contains('failed to connect') ||
        errLower.contains('networkerror')) {
      userFriendlyMsg = 'Unable to connect to the authentication service.';
      suggestion = 'Please ensure the backend server is running and accessible.';
    } else if (errLower.contains('401') || errLower.contains('unauthorized')) {
      userFriendlyMsg = 'Google authentication was not authorized.';
      suggestion = 'Please check your account permissions and try logging in again.';
    }

    AppErrorDialog.show(
      context,
      title: 'Sign In Notice',
      message: userFriendlyMsg,
      suggestion: suggestion,
      icon: Icons.lock_clock_outlined,
      buttonText: 'Try Again',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Tooltip(
              message: 'Toggle theme (${themeMode.name})',
              child: IconButton.filledTonal(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                },
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.family_restroom, size: 72, color: Colors.indigo),
                      const SizedBox(height: 16),
                      Text(
                        'Family Tree',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your Google Account to access your family tree.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131314) : Colors.white,
                                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1F1F1F),
                                  side: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8E918F) : const Color(0xFF747775),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 1,
                                ),
                                onPressed: _handleGoogleSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoogleLogo(),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1F1F1F),
                                      ),
                                    ),
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
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - 2);

    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = 3.5;
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = 3.5;
    final greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = 3.5;
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = 3.5;

    canvas.drawArc(rect, -0.4, 1.8, false, redPaint);
    canvas.drawArc(rect, 1.4, 1.2, false, yellowPaint);
    canvas.drawArc(rect, 2.6, 1.4, false, greenPaint);
    canvas.drawArc(rect, 4.0, 1.8, false, bluePaint);

    final linePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = 3.5;
    canvas.drawLine(Offset(cx, cy), Offset(size.width - 1, cy), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
