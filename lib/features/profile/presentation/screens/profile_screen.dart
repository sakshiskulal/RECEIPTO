import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';
import 'package:receipto/core/services/app_lock_provider.dart';
import 'package:receipto/core/services/app_lock_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _cloudBackupEnabled = true;

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final lockNotifier = ref.read(appLockProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 24),

              // User Profile Info Card
              _buildUserProfileCard(context),
              const SizedBox(height: 20),

              // Stat totals grid
              _buildStatsGrid(context),
              const SizedBox(height: 24),

              // Security & App Lock section
              _buildSectionHeader(context, 'Security & App Lock'),
              const SizedBox(height: 12),

              _buildToggleSetting(
                title: 'Enable App Lock',
                subtitle: lockState.isEnabled
                    ? 'App lock active with custom PIN'
                    : 'Require custom PIN on launch',
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.primary,
                value: lockState.isEnabled,
                onChanged: (val) async {
                  if (val) {
                    // Enabling: Prompt to create 4-digit PIN first
                    _showSetupCustomPinDialog(context);
                  } else {
                    // Disabling: Require authentication first
                    _promptPinOrBiometricToDisable(context);
                  }
                },
              ),
              const SizedBox(height: 12),

              if (lockState.isEnabled) ...[
                if (lockState.isBiometricAvailable)
                  _buildToggleSetting(
                    title: 'Use Fingerprint / Face Unlock',
                    subtitle: 'Quick biometric unlock option',
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.secondary,
                    value: lockState.isBiometricEnabled,
                    onChanged: (val) async {
                      await lockNotifier.setBiometricEnabled(val);
                    },
                  ),
                if (lockState.isBiometricAvailable) const SizedBox(height: 12),

                _buildActionSetting(
                  title: 'Change App PIN',
                  subtitle: 'Update your 4-digit PIN',
                  icon: Icons.key_outlined,
                  iconColor: AppColors.tertiary,
                  onTap: () {
                    _showPinChangeDialog(context);
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Account & Backup section
              _buildSectionHeader(context, 'Account & Backup'),
              const SizedBox(height: 12),

              // Settings Toggles & Actions
              _buildToggleSetting(
                title: 'Cloud Backup',
                subtitle: 'Last synced 2m ago',
                icon: Icons.cloud_done_outlined,
                iconColor: AppColors.primary,
                value: _cloudBackupEnabled,
                onChanged: (val) {
                  setState(() {
                    _cloudBackupEnabled = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildActionSetting(
                title: 'Export Data',
                subtitle: 'PDF, Excel, or CSV',
                icon: Icons.ios_share,
                iconColor: AppColors.secondary,
                onTap: () {
                  // Export action
                },
              ),
              const SizedBox(height: 12),
              _buildActionSetting(
                title: 'Test Notification',
                subtitle: 'Trigger a test local notification',
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.primary,
                onTap: () async {
                  await ref.read(notificationServiceProvider).showNotification(
                        id: 999,
                        title: 'Receipto Test',
                        body: 'This is a test warranty reminder notification.',
                      );
                },
              ),
              const SizedBox(height: 12),
              _buildActionSetting(
                title: 'Send Test Email',
                subtitle: 'Send a test email to your address',
                icon: Icons.email_outlined,
                iconColor: AppColors.secondary,
                onTap: () async {
                  final user = ref.read(firebaseAuthServiceProvider).currentUser;
                  if (user != null && user.email != null && user.email!.isNotEmpty) {
                    try {
                      await ref.read(emailServiceProvider).sendTestEmail(
                            recipientEmail: user.email!,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test email sent successfully!')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email failed: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No logged-in user email found.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionSetting(
                title: 'Run Warranty Engine',
                subtitle: 'Trigger background scanning immediately',
                icon: Icons.play_arrow_outlined,
                iconColor: AppColors.tertiary,
                onTap: () async {
                  final user = ref.read(firebaseAuthServiceProvider).currentUser;
                  if (user != null) {
                    try {
                      await ref.read(reminderEngineProvider).checkWarrantyReminders(
                            user.uid,
                            user.email,
                            user.displayName,
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Warranty engine run completed! Check console logs.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Engine failed: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No logged-in user found.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionSetting(
                title: 'Recycle Bin',
                subtitle: 'View and restore deleted receipts',
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.primary,
                onTap: () {
                  context.push('/profile/recycle-bin');
                },
              ),
              const SizedBox(height: 32),

              // Logout Action button
              _buildLogoutButton(context),
              const SizedBox(height: 24),

              // Footer app info
              _buildFooter(context),

              // Bottom navbar margin spacer
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupCustomPinDialog(BuildContext context) {
    String pin = '';
    String confirmPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Create App PIN',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a 4-digit security PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => pin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(hintText: 'PIN', counterText: ''),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm 4-digit PIN:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => confirmPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(hintText: 'Confirm PIN', counterText: ''),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (pin.length != 4) {
                  setDialogState(() => error = 'PIN must be 4 digits.');
                  return;
                }
                if (pin != confirmPin) {
                  setDialogState(() => error = 'PINs do not match.');
                  return;
                }
                // Save custom PIN hash first, then set app_lock_enabled = true ONLY AFTER confirmation!
                await ref.read(appLockProvider.notifier).setCustomPin(pin);
                await ref.read(appLockProvider.notifier).setAppLockEnabled(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom PIN set and App Lock enabled!')),
                  );
                }
              },
              child: const Text('Enable Lock', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _promptPinOrBiometricToDisable(BuildContext context) async {
    final lockState = ref.read(appLockProvider);
    final lockService = ref.read(appLockServiceProvider);

    if (lockState.isBiometricEnabled && lockState.isBiometricAvailable) {
      final bioSuccess = await lockService.authenticateBiometricsOnly(
        reason: 'Scan fingerprint or face to disable App Lock',
      );
      if (bioSuccess) {
        await ref.read(appLockProvider.notifier).setAppLockEnabled(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock disabled successfully.')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    // PIN prompt
    String enteredPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Disable App Lock',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your 4-digit PIN to disable lock:',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                onChanged: (val) => enteredPin = val,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: const InputDecoration(counterText: ''),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final valid = await lockService.verifyCustomPin(enteredPin);
                if (valid) {
                  await ref.read(appLockProvider.notifier).setAppLockEnabled(false);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Lock disabled.')),
                    );
                  }
                } else {
                  setDialogState(() => error = 'Incorrect PIN.');
                }
              },
              child: const Text('Disable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinChangeDialog(BuildContext context) {
    String currentPin = '';
    String newPin = '';
    String confirmNewPin = '';
    String error = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lg,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            'Change App PIN',
            style: GoogleFonts.hankenGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => currentPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                const SizedBox(height: 10),
                Text('New 4-digit PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => newPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                const SizedBox(height: 10),
                Text('Confirm New PIN:', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) => confirmNewPin = val,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, letterSpacing: 6),
                  decoration: const InputDecoration(counterText: ''),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final lockService = ref.read(appLockServiceProvider);
                final validCurrent = await lockService.verifyCustomPin(currentPin);
                if (!validCurrent) {
                  setDialogState(() => error = 'Current PIN is incorrect.');
                  return;
                }
                if (newPin.length != 4) {
                  setDialogState(() => error = 'New PIN must be 4 digits.');
                  return;
                }
                if (newPin != confirmNewPin) {
                  setDialogState(() => error = 'New PINs do not match.');
                  return;
                }
                await ref.read(appLockProvider.notifier).setCustomPin(newPin);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN updated successfully!')),
                  );
                }
              },
              child: const Text('Update PIN', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Receipto',
          style: Theme.of(context).textTheme.headlineMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                image: DecorationImage(
                  image: NetworkImage(
                    hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // User Profile card containing verified badge and premium status
  Widget _buildUserProfileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email available';

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Centered Verified Avatar stack
            Stack(
              alignment: Alignment.center,
              children: [
                // Avatar Box
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(
                        hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Verified Shield Badge overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.verified_user,
                      color: AppColors.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile info text labels
            Text(
              name,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              email,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),

            // Premium Member tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlueCyan,
                borderRadius: AppRadius.full,
              ),
              child: Text(
                'PREMIUM MEMBER',
                style: GoogleFonts.inter(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Stats summary grid row
  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        _buildStatBox(context, '1.2k', 'Receipts', AppColors.primary),
        const SizedBox(width: 12),
        _buildStatBox(context, '98%', 'Accuracy', AppColors.tertiary),
        const SizedBox(width: 12),
        _buildStatBox(context, '24', 'Reports', AppColors.secondary),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segment section label header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.geist(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          height: 1.0,
        ),
      ),
    );
  }

  // Toggle Switch setting widget
  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.onSurfaceVariant,
            inactiveTrackColor: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }

  // Action Navigate setting widget
  Widget _buildActionSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(firebaseAuthServiceProvider).signOut();
        },
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withValues(alpha: 0.85),
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Footer label info
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Receipto v2.4.0-pro',
          style: AppFonts.geist(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.normal,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Encrypted End-to-End',
          style: AppFonts.geist(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.normal,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
