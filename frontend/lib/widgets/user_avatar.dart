import 'package:flutter/material.dart';
import '../models/user.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 18.0,
    this.onTap,
  });

  static String getInitials(String? name, String? email) {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) {
      final parts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
        return parts.first[0].toUpperCase();
      }
    }
    final cleanEmail = email?.trim() ?? '';
    if (cleanEmail.isNotEmpty) {
      return cleanEmail[0].toUpperCase();
    }
    return '?';
  }

  static Color getAvatarColor(String seed) {
    if (seed.isEmpty) return const Color(0xFF1A73E8);
    final colors = const [
      Color(0xFF1A73E8), // Google Blue
      Color(0xFFD93025), // Google Red
      Color(0xFFF9AB00), // Google Yellow/Orange
      Color(0xFF188038), // Google Green
      Color(0xFFA142F4), // Purple
      Color(0xFFE52592), // Pink
      Color(0xFF007B83), // Teal
    ];
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[400],
        child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
      );
    }

    final avatarUrl = user!.avatarUrl;
    final hasUrl = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final initials = getInitials(user!.name, user!.email);
    final bgColor = getAvatarColor(user!.email.isNotEmpty ? user!.email : user!.name);

    Widget avatarWidget;
    if (hasUrl) {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.9,
          ),
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }
    return avatarWidget;
  }
}
