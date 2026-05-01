import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../themes/app_themes.dart';
import 'authentication/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('user-info').doc(uid).get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);
      if (mounted) {
        setState(() {
          _userInfo = results[0].data();
          _userData = results[1].data();
          _notificationsEnabled =
              (_userInfo?['notificationsEnabled'] as bool?) ?? false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('user-info')
          .doc(uid)
          .update({'notificationsEnabled': value});
    } catch (_) {
      if (mounted) setState(() => _notificationsEnabled = !value);
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = AppThemes.getThemeForTimeOfDay();
    final isDark = themeData.theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54;
    final accentColor =
        isDark ? Colors.blue.shade300 : Colors.blue.shade700;

    final user = FirebaseAuth.instance.currentUser;
    final firstName = _userInfo?['firstName'] as String? ?? '';
    final lastName = _userInfo?['lastName'] as String? ?? '';
    final username = _userInfo?['username'] as String? ??
        _userData?['username'] as String? ??
        '';
    final email =
        _userData?['email'] as String? ?? user?.email ?? '';
    final phone = _userData?['phone'] as String? ?? '';
    final createdAt =
        (_userInfo?['createdAt'] as Timestamp?)?.toDate();
    final memberSince = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt)
        : '—';
    final birthDate =
        (_userInfo?['birthDate'] as Timestamp?)?.toDate();
    final birthdayStr = birthDate != null
        ? DateFormat('MMMM d, yyyy').format(birthDate)
        : null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.88),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.55), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.person_rounded, size: 58, color: accentColor),
            ),
            const SizedBox(height: 14),
            Text(
              firstName.isEmpty && lastName.isEmpty
                  ? 'Your Name'
                  : '$firstName $lastName',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (username.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@$username',
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
            ],
            const SizedBox(height: 30),

            // Account section
            _SectionCard(
              title: 'Account',
              isDark: isDark,
              accentColor: accentColor,
              children: [
                if (phone.isNotEmpty)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone,
                    isDark: isDark,
                    onTap: () => _copyToClipboard(phone, 'Phone'),
                  ),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email.isEmpty ? '—' : email,
                  isDark: isDark,
                  onTap: email.isNotEmpty
                      ? () => _copyToClipboard(email, 'Email')
                      : null,
                ),
                if (username.isNotEmpty)
                  _InfoRow(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: '@$username',
                    isDark: isDark,
                  ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member since',
                  value: memberSince,
                  isDark: isDark,
                ),
                if (birthdayStr != null)
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Birthday',
                    value: birthdayStr,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Preferences section
            _SectionCard(
              title: 'Preferences',
              isDark: isDark,
              accentColor: accentColor,
              children: [
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  value: _notificationsEnabled,
                  isDark: isDark,
                  onChanged: _toggleNotifications,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Security section
            _SectionCard(
              title: 'Security',
              isDark: isDark,
              accentColor: accentColor,
              children: [
                _TapRow(
                  icon: Icons.lock_reset_outlined,
                  label: 'Change Password',
                  isDark: isDark,
                  onTap: _sendPasswordReset,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _logout,
              ),
            ),
            const SizedBox(height: 20),
            Text('Stellar v1.0.0',
                style: TextStyle(color: mutedColor, fontSize: 12)),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

// --- Section card ---
class _SectionCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color accentColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.88);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: dividerColor,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Info row (display only, optional copy on tap) ---
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white : Colors.black87;
    final valueColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54;
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black45;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 14, color: valueColor),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Toggle row ---
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.white : Colors.black87;
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: labelColor),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// --- Tappable action row ---
class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _TapRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : Colors.black87;
    final iconColor = color.withValues(alpha: 0.65);
    final chevronColor =
        isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black38;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: chevronColor),
          ],
        ),
      ),
    );
  }
}
