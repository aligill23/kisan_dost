import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/pakistan_locations.dart';
import '../../../services/r2_upload_service.dart';
import '../../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../../shared/widgets/location_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _yearsController = TextEditingController();

  String _province = '';
  String _district = '';
  String _tehsil = '';

  File? _logoFile;
  File? _bannerFile;
  double _logoProgress = 0.0;
  double _bannerProgress = 0.0;
  bool _isLoading = false;
  String _loadingMessage = '';

  final ImagePicker _picker = ImagePicker();
  List<String> _selectedCategories = [];

  // Categories based on role
  List<String> get _dealerCategories => [
        'کھاد',
        'بیج',
        'کیڑے مار دوا',
        'زرعی مشینری',
        'آبپاشی کا سامان',
        'دیگر',
      ];

  List<String> get _arhtiCategories => [
        'گندم',
        'چاول',
        'کپاس',
        'گنا',
        'مکئی',
        'دیگر',
      ];

  String get _role => context.read<AuthViewModel>().userRole ?? 'dealer';

  bool get _isDealer => _role == 'dealer';

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  // ── Image Pickers ─────────────────────────────
  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  Future<void> _pickBanner() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      setState(() => _bannerFile = File(picked.path));
    }
  }

  // ── Validation ────────────────────────────────
  bool _validate() {
    if (_logoFile == null) {
      _showError('لوگو تصویر لازمی ہے');
      return false;
    }
    if (_businessNameController.text.trim().isEmpty) {
      _showError('کاروبار کا نام لازمی ہے');
      return false;
    }
    if (_ownerNameController.text.trim().isEmpty) {
      _showError('مالک کا نام لازمی ہے');
      return false;
    }
    if (_district.isEmpty) {
      _showError('ضلع منتخب کریں');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Save Business ─────────────────────────────
  Future<void> _saveBusiness() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'لوگو اپلوڈ ہو رہا ہے...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';

      //   FIX — use Firebase Auth uid instead of phone digits
      var authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        authUser = cred.user;
      }
      final docId = authUser?.uid ?? '';

      if (docId.isEmpty) {
        throw Exception('Unable to resolve user identifier');
      }

      // Upload logo
      final logoUrl = await R2UploadService.uploadProfilePhoto(
        _logoFile!,
        onProgress: (p) {
          setState(() => _logoProgress = p);
        },
      );

      setState(() => _loadingMessage = 'بینر اپلوڈ ہو رہا ہے...');

      // Upload banner (optional)
      String bannerUrl = '';
      if (_bannerFile != null) {
        final url = await R2UploadService.uploadImage(
          file: _bannerFile!,
          folder: 'banners',
          onProgress: (p) {
            setState(() => _bannerProgress = p);
          },
        );
        bannerUrl = url ?? '';
      }

      setState(() => _loadingMessage = 'معلومات محفوظ ہو رہی ہیں...');

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'phone': phone,
        'role': _role,
        'name': _ownerNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'province': _province,
        'district': _district,
        'tehsil': _tehsil,
        'logoUrl': logoUrl ?? '',
        'profileImage': logoUrl ?? '',
        'bannerUrl': bannerUrl,
        'categories': _selectedCategories,
        'yearsInBusiness': int.tryParse(_yearsController.text) ?? 0,
        'verified': false,
        'subscriptionStatus': 'inactive',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save session
      await prefs.setString('userId', docId);
      await prefs.setBool('isLoggedIn', true);
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isDealer
                        ? [
                            const Color(0xFF0D3B8E),
                            const Color(0xFF1565C0),
                          ]
                        : [
                            const Color(0xFF3E2000),
                            const Color(0xFFE65100),
                          ],
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isDealer ? 'ڈیلر پیج بن گیا!' : 'آڑھت پیج بن گیا!',
                style: const TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _businessNameController.text.trim(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDealer
                      ? const Color(0xFF1565C0)
                      : const Color(0xFFE65100),
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDealer
                        ? [
                            const Color(0xFF0D3B8E),
                            const Color(0xFF1565C0),
                          ]
                        : [
                            const Color(0xFF3E2000),
                            const Color(0xFFE65100),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ڈیش بورڈ پر جائیں',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeColor =
        _isDealer ? const Color(0xFF1565C0) : const Color(0xFFE65100);

    final gradientColors = _isDealer
        ? [const Color(0xFF0D3B8E), const Color(0xFF1565C0)]
        : [const Color(0xFF3E2000), const Color(0xFFE65100)];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: gradientColors[0],
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDealer
                                  ? Icons.store_outlined
                                  : Icons.business_outlined,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isDealer ? 'ڈیلر بزنس پیج' : 'آڑھت بزنس پیج',
                              style: const TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              'اپنا پروفیشنل پیج بنائیں',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // ── Banner Section ───────────
                      _SectionTitle(
                        title: 'کاروبار کی بینر تصویر',
                        subtitle: '(اختیاری)',
                        color: themeColor,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickBanner,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: _bannerFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(
                                        _bannerFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'تبدیل کریں',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: themeColor.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'بینر تصویر شامل کریں',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textGrey,
                                        height: 1.5,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Text(
                                      '(اختیاری)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGrey
                                            .withValues(alpha: 0.6),
                                        height: 1.4,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Logo Section ─────────────
                      _SectionTitle(
                        title: 'لوگو / پروفائل تصویر',
                        subtitle: '(لازمی)',
                        color: themeColor,
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: themeColor.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: _logoFile != null
                                        ? themeColor
                                        : Colors.red.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: _logoFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _logoFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 36,
                                        color:
                                            themeColor.withValues(alpha: 0.6),
                                      ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
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
                      const SizedBox(height: 20),

                      // ── Form Card ─────────────────
                      Container(
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Business Name
                            _FormLabel(
                              text: _isDealer
                                  ? 'کاروبار کا نام *'
                                  : 'آڑھت کا نام *',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _businessNameController,
                              hint: _isDealer
                                  ? 'مثال: گل زرعی اسٹور'
                                  : 'مثال: گل کمیشن ایجنسی',
                              icon: Icons.business_outlined,
                              themeColor: themeColor,
                            ),
                            const SizedBox(height: 16),

                            // Owner Name
                            _FormLabel(
                              text: 'مالک کا نام *',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _ownerNameController,
                              hint: 'مثال: محمد احمد',
                              icon: Icons.person_outline,
                              themeColor: themeColor,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _FormLabel(
                              text: 'تعارف (اختیاری)',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _descController,
                              hint: _isDealer
                                  ? 'اپنے کاروبار کے بارے میں لکھیں'
                                  : 'اپنی آڑھت کے بارے میں لکھیں',
                              icon: Icons.info_outline,
                              themeColor: themeColor,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            // WhatsApp
                            _FormLabel(
                              text: 'واٹس ایپ نمبر',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _whatsappController,
                              hint: '03001234567',
                              icon: Icons.phone_outlined,
                              themeColor: themeColor,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Years in Business
                            _FormLabel(
                              text: 'تجربہ (سال)',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _yearsController,
                              hint: 'مثال: 5',
                              icon: Icons.calendar_today_outlined,
                              themeColor: themeColor,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Location ──────────────────
                      Container(
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              title: 'مقام',
                              color: themeColor,
                            ),
                            const SizedBox(height: 12),
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

                            // Address
                            _FormLabel(
                              text: _isDealer ? 'دکان کا پتہ' : 'منڈی پتہ',
                              color: themeColor,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _addressController,
                              hint: _isDealer
                                  ? 'مکمل دکان کا پتہ'
                                  : 'غلہ منڈی کا پتہ',
                              icon: Icons.location_on_outlined,
                              themeColor: themeColor,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Categories ────────────────
                      Container(
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              title: _isDealer
                                  ? 'مصنوعات کی اقسام'
                                  : 'خریدی جانے والی فصلیں',
                              color: themeColor,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_isDealer
                                      ? _dealerCategories
                                      : _arhtiCategories)
                                  .map((cat) {
                                final selected =
                                    _selectedCategories.contains(cat);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selected) {
                                        _selectedCategories.remove(cat);
                                      } else {
                                        _selectedCategories.add(cat);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? themeColor
                                          : themeColor.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? themeColor
                                            : themeColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: selected
                                                ? Colors.white
                                                : themeColor,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        if (selected) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Submit Button ─────────────
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saveBusiness,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            _isDealer
                                ? Icons.store_outlined
                                : Icons.business_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: Text(
                            _isDealer ? 'ڈیلر پیج بنائیں' : 'آڑھت پیج بنائیں',
                            style: const TextStyle(
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
            ],
          ),

          // ── Loading Overlay ────────────────────
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: themeColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color themeColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: themeColor, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAF8),
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
          borderSide: BorderSide(color: themeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool required;

  const _SectionTitle({
    required this.title,
    required this.color,
    this.subtitle,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: required ? Colors.red : AppTheme.textGrey,
              height: 1.4,
            ),
          ),
        if (subtitle != null) const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Icon(Icons.circle, color: color, size: 8),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _FormLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
        height: 1.5,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
