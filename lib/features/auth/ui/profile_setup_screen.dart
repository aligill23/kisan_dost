import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/location_dropdown.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'profile_success_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/device_blocked_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _notesController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  File? _profileImage;
  String _province = '';
  String _district = '';
  String _tehsil = '';

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _notesController.dispose();
    _referralController.dispose();
    _profileImage = null;
    super.dispose();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'arhti':
        return 'آڑھتی';
      case 'dealer':
        return 'ڈیلر / کمپنی';
      default:
        return 'کسان';
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'arhti':
        return 'آپ آڑھتی کے طور پر رجسٹر ہو رہے ہیں';
      case 'dealer':
        return 'آپ ڈیلر کے طور پر رجسٹر ہو رہے ہیں';
      default:
        return 'آپ کسان کے طور پر رجسٹر ہو رہے ہیں';
    }
  }

  String _getBusinessLabel(String role) {
    switch (role) {
      case 'arhti':
        return 'آڑھت کا نام';
      case 'dealer':
        return 'دکان یا کمپنی کا نام';
      default:
        return 'فارم کا نام';
    }
  }

  String _getBusinessHint(String role) {
    switch (role) {
      case 'arhti':
        return 'آڑھت کا نام درج کریں';
      case 'dealer':
        return 'دکان یا کمپنی کا نام';
      default:
        return 'فارم یا زمین کا نام';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'arhti':
        return Icons.balance_outlined;
      case 'dealer':
        return Icons.store_outlined;
      default:
        return Icons.grass_outlined;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'arhti':
        return const Color(0xFF1565C0);
      case 'dealer':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primaryGreen;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_province.isEmpty || _district.isEmpty || _tehsil.isEmpty) {
      _showError('براہ کرم مکمل لوکیشن منتخب کریں');
      return;
    }

    final role = context.read<AuthViewModel>().userRole ?? 'farmer';
    final vm = context.read<ProfileViewModel>();
    final authVM = context.read<AuthViewModel>();

    //  NAYA -is device pe pehle se koi doosra account to nahi
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final existingUserId = await authVM.findAccountUsingThisDevice();
    if (existingUserId != null && existingUserId != currentUid) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
        );
      }
      return;
    }

    // ── Referral validation ───────────────────────
    final code = _referralController.text.trim();
    if (code.isNotEmpty) {
      _showLoadingDialog('ریفرل کوڈ چیک ہو رہا ہے...');

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final isValid = await vm.validateReferralCode(
        userId: uid,
        code: code,
      );

      if (mounted) Navigator.pop(context);

      if (!isValid) {
        if (!mounted) return;
        _showError(vm.referralError ?? 'غلط ریفرل کوڈ');
        return;
      }

      if (mounted) {
        _showSuccessDialog(vm.validatedAmbassadorName ?? '');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    }

    // ── Profile Image Upload ──────────────────────
    //  YE MISSING THA -Ab add ho gaya
    String profileImageUrl = '';
    if (_profileImage != null) {
      _showLoadingDialog('تصویر اپلوڈ ہو رہی ہے...');

      final imageUrl = await vm.uploadProfileImageAndGetUrl(
        _profileImage!,
      );

      if (mounted) Navigator.pop(context);

      if (imageUrl != null) {
        profileImageUrl = imageUrl;
      }
    }

    // ── Build data map ────────────────────────────
    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'role': role,
      'province': _province,
      'district': _district,
      'tehsil': _tehsil,
      'notes': _notesController.text.trim(),
      //  Profile image URL add karo
      if (profileImageUrl.isNotEmpty) 'profileImage': profileImageUrl,
    };

    if (role == 'farmer') {
      data['village'] = _villageController.text.trim();
      data['farmName'] = _businessNameController.text.trim();
    } else if (role == 'arhti') {
      data['shopName'] = _businessNameController.text.trim();
      data['marketAddress'] = _addressController.text.trim();
    } else if (role == 'dealer') {
      data['businessName'] = _businessNameController.text.trim();
      data['shopAddress'] = _addressController.text.trim();
    }

    final success = await vm.saveProfile(data);
    if (!mounted) return;

    if (success) {
      //  NAYA -profile save hote hi device register/check karein
      final authVM = context.read<AuthViewModel>();
      final userId = authVM.userId ?? '';
      final deviceResult = await authVM.checkDeviceSecurity(userId);
      if (!mounted) return;

      if (deviceResult == DeviceCheckResult.blockedDifferentDevice) {
        // Is device pe pehle se koi account hai -block karo, profile-success mat dikhao
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeviceBlockedScreen()),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSuccessScreen()),
      );
    } else {
      _showError(vm.errorMessage ?? 'خرابی ہوئی');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Loading Dialog ────────────────────────────
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ریفرل کوڈ چیک ہو رہا ہے',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "براہ کرم انتظار کریں...",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Success Dialog ────────────────────────────
  void _showSuccessDialog(String ambassadorName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.primaryGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ریفرل کوڈ درست ہے!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              if (ambassadorName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '$ambassadorName کا شکریہ',
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().userRole ?? 'farmer';
    final vm = context.watch<ProfileViewModel>();
    final roleColor = _getRoleColor(role);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'پروفائل مکمل کریں',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'کسان دوست پر اپنی شناخت بنائیں',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getRoleLabel(role),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              Text(
                                _getRoleDescription(role),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGrey,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              role == 'farmer'
                                  ? 'assets/images/farmer_icon.png'
                                  : role == 'arhti'
                                      ? 'assets/images/arhti.png'
                                      : 'assets/images/dealer.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                _getRoleIcon(role),
                                color: roleColor,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile Photo
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final XFile? picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 400,
                            maxHeight: 400,
                            imageQuality: 80,
                          );
                          if (picked != null) {
                            setState(() => _profileImage = File(picked.path));
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: FileImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 52,
                                      color: AppTheme.primaryGreen,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تصویر اپلوڈ کریں',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 24),

                    // Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          _FieldLabel(text: 'پورا نام *'),
                          const SizedBox(height: 8),
                          _CustomField(
                            controller: _nameController,
                            hint: 'اپنا مکمل نام درج کریں',
                            icon: Icons.person_outline,
                            validator: (val) => val == null || val.isEmpty
                                ? 'نام ضروری ہے'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Business Name
                          _FieldLabel(text: '${_getBusinessLabel(role)} *'),
                          const SizedBox(height: 8),
                          _CustomField(
                            controller: _businessNameController,
                            hint: _getBusinessHint(role),
                            icon: Icons.business_outlined,
                            validator: (val) => val == null || val.isEmpty
                                ? 'نام ضروری ہے'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Location
                          LocationDropdowns(
                            onChanged: (p, d, t) {
                              setState(() {
                                _province = p;
                                _district = d;
                                _tehsil = t;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Village (farmer only)
                          if (role == 'farmer') ...[
                            _FieldLabel(text: 'گاؤں کا نام (اختیاری)'),
                            const SizedBox(height: 8),
                            _CustomField(
                              controller: _villageController,
                              hint: 'گاؤں یا محلہ',
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Address (arhti/dealer)
                          if (role == 'arhti' || role == 'dealer') ...[
                            _FieldLabel(
                              text: role == 'arhti'
                                  ? 'منڈی پتہ *'
                                  : 'دکان کا پتہ *',
                            ),
                            const SizedBox(height: 8),
                            _CustomField(
                              controller: _addressController,
                              hint: 'مکمل پتہ درج کریں',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'پتہ ضروری ہے'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Notes
                          _FieldLabel(
                              text: 'اپنے بارے میں مزید بتائیں (اختیاری)'),
                          const SizedBox(height: 8),
                          _CustomField(
                            controller: _notesController,
                            hint:
                                'مثلاً آپ کون سی فصلیں اگاتے ہیں یا کس علاقے میں کام کرتے ہیں',
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── REFERRAL CARD ─────────────────────────────
                    Consumer<ProfileViewModel>(
                      builder: (_, vm, __) => Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: vm.referralValid
                                ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                                : vm.referralError != null
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                            width: vm.referralValid ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: vm.referralValid
                                  ? AppTheme.primaryGreen
                                      .withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Header ──────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.04),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'ریفرل کوڈ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                            height: 1.5,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        Text(
                                          'اختیاری -صرف کسانوں کیلئے',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            height: 1.4,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.card_giftcard_outlined,
                                      color: AppTheme.primaryGreen,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Body ────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Subtitle
                                  const Text(
                                    'اگر کسی کسان دوست ایمبیسیڈر نے آپ کو ایپ کے بارے میں بتایا ہے تو ان کا ریفرل کوڈ درج کریں۔',
                                    style: TextStyle(
                                      fontFamily: 'Nastaleeq',
                                      fontSize: 13,
                                      color: AppTheme.textGrey,
                                      height: 1.8,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 14),

                                  // ── Input Field ──────────────────
                                  TextFormField(
                                    controller: _referralController,
                                    textAlign: TextAlign.center,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    enabled: !vm.isValidatingReferral,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 8,
                                      color: vm.referralValid
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textDark,
                                    ),
                                    onChanged: (_) {
                                      if (vm.referralValid ||
                                          vm.referralError != null) {
                                        vm.clearReferral();
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'KD4837',
                                      hintStyle: TextStyle(
                                        fontSize: 20,
                                        letterSpacing: 6,
                                        color: Colors.grey.shade300,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      filled: true,
                                      fillColor: vm.isValidatingReferral
                                          ? Colors.grey.shade50
                                          : vm.referralValid
                                              ? AppTheme.primaryGreen
                                                  .withValues(alpha: 0.04)
                                              : const Color(0xFFF8FAF8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: vm.referralValid
                                              ? AppTheme.primaryGreen
                                                  .withValues(alpha: 0.4)
                                              : vm.referralError != null
                                                  ? Colors.red
                                                      .withValues(alpha: 0.4)
                                                  : Colors.grey.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: AppTheme.primaryGreen
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryGreen,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 18,
                                      ),
                                      // Suffix -check / error only (loading dialog covers the spinner state)
                                      suffixIcon: vm.referralValid
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppTheme.primaryGreen,
                                              size: 24,
                                            )
                                          : vm.referralError != null
                                              ? const Icon(
                                                  Icons.cancel_rounded,
                                                  color: Colors.red,
                                                  size: 24,
                                                )
                                              : null,
                                    ),
                                  ),

                                  // ── Success Message ───────────────
                                  if (vm.referralValid &&
                                      !vm.isValidatingReferral) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.primaryGreen
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'ریفرل کوڈ درست ہے!',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.primaryGreen,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.5,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                Text(
                                                  'ریفرل کوڈ کامیابی سے استعمال ہوا -${vm.validatedAmbassadorName ?? ''} کا شکریہ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    height: 1.4,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.verified_rounded,
                                              color: AppTheme.primaryGreen,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // ── Error Message ─────────────────
                                  if (vm.referralError != null &&
                                      !vm.isValidatingReferral) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              Colors.red.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  '❌ غلط ریفرل کوڈ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.5,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                Text(
                                                  vm.referralError!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                    height: 1.4,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Retry suggestion
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        'کوڈ درست کریں یا خالی چھوڑ کر آگے بڑھیں',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
                                          height: 1.5,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Submit Button
                    vm.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.darkGreen,
                                  AppTheme.primaryGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _submit(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                'معلومات محفوظ کریں',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
        height: 1.5,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _CustomField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
