import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../../models/user_model.dart';
import '../../../services/subscription_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSubscribed = false;
  File? _newProfileImage; // ← ADD
  final ImagePicker _picker = ImagePicker(); // ← ADD

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserProfile();
    });
  }

  Future<void> _checkSubscription() async {
    final active = await SubscriptionService.isSubscriptionActive();
    if (mounted) setState(() => _isSubscribed = active);
  }

  // ← ADD THIS METHOD
  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      print(' Image picked: ${picked.path}');
      setState(() => _newProfileImage = File(picked.path));

      if (!mounted) return;
      final vm = context.read<ProfileViewModel>();

      print('⏳ Starting upload...');
      final success = await vm.uploadProfileImageAndGetUrl(File(picked.path));
      print('Upload result: $success');
      print('Error: ${vm.errorMessage}');
    } else {
      print(' No image picked');
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'arhti':
        return const Color(0xFFE65100);
      case 'dealer':
        return const Color(0xFF1565C0);
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = profileVM.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: profileVM.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : user == null
              ? _buildEmpty(context, authVM)
              : _buildProfile(context, user, authVM, profileVM),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    UserModel user,
    AuthViewModel authVM,
    ProfileViewModel profileVM, // ← ADD profileVM param
  ) {
    final roleColor = _getRoleColor(user.role);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: roleColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    roleColor.withValues(alpha: 0.9),
                    roleColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // ── Avatar ──────────────────────
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _newProfileImage != null
                                  ? Image.file(
                                      _newProfileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : user.profileImage.isNotEmpty
                                      ? Image.network(
                                          user.profileImage,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, prog) {
                                            if (prog == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person,
                                            size: 44,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 44,
                                          color: Colors.white,
                                        ),
                            ),
                          ),

                          // Upload progress overlay
                          if (profileVM.isUploadingImage)
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: profileVM.imageUploadProgress,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),

                          // Camera icon
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: roleColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),

                    // Role + Subscription Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSubscribed)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'پریمیم',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.workspace_premium,
                                    size: 12, color: Colors.black87),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.roleLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => ProfileViewModel(),
                    child: const EditProfileScreen(),
                  ),
                ),
              ).then((_) {
                context.read<ProfileViewModel>().loadUserProfile();
                _checkSubscription();
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 12, top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ترمیم',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(
                  title: 'موبائل نمبر',
                  icon: Icons.phone_outlined,
                  color: roleColor,
                  child: Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 1.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _InfoCard(
                  title: 'ذاتی معلومات',
                  icon: Icons.person_outline,
                  color: roleColor,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'نام',
                        value: user.name,
                        icon: Icons.badge_outlined,
                      ),
                      if (user.shopName.isNotEmpty) ...[
                        const _Divider(),
                        _InfoRow(
                          label:
                              user.role == 'arhti' ? 'آڑھت کا نام' : 'کاروبار',
                          value: user.shopName,
                          icon: Icons.business_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _InfoCard(
                  title: 'لوکیشن',
                  icon: Icons.location_on_outlined,
                  color: roleColor,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'صوبہ',
                        value: user.province,
                        icon: Icons.map_outlined,
                      ),
                      const _Divider(),
                      _InfoRow(
                        label: 'ضلع',
                        value: user.district,
                        icon: Icons.location_city_outlined,
                      ),
                      const _Divider(),
                      _InfoRow(
                        label: 'تحصیل',
                        value: user.tehsil,
                        icon: Icons.place_outlined,
                      ),
                      if (user.village.isNotEmpty) ...[
                        const _Divider(),
                        _InfoRow(
                          label: 'گاؤں',
                          value: user.village,
                          icon: Icons.home_outlined,
                        ),
                      ],
                      if (user.address.isNotEmpty) ...[
                        const _Divider(),
                        _InfoRow(
                          label: 'پتہ',
                          value: user.address,
                          icon: Icons.store_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _InfoCard(
                  title: 'اکاؤنٹ',
                  icon: Icons.account_circle_outlined,
                  color: roleColor,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'کردار',
                        value: user.roleLabel,
                        icon: Icons.people_outline,
                      ),
                      const _Divider(),
                      _InfoRow(
                        label: 'سبسکرپشن',
                        value: _isSubscribed ? 'فعال' : 'غیر فعال',
                        icon: Icons.workspace_premium_outlined,
                        valueColor: _isSubscribed
                            ? AppTheme.primaryGreen
                            : Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => Dialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.logout,
                                    color: Colors.red, size: 30),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'لاگ آؤٹ کریں؟',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textGrey,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('نہیں'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'لاگ آؤٹ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await authVM.signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لاگ آؤٹ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.logout, color: Colors.red, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, AuthViewModel authVM) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          const Text(
            'پروفائل نہیں ملی',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await authVM.signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('لاگ آؤٹ', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textDark,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGrey,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: AppTheme.textGrey),
          ],
        ),
      ],
    );
  }
}

// ── Divider ───────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
