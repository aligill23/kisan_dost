import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../services/r2_upload_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // ── State ─────────────────────────────────────
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _userId = '';

  // Existing subscription
  String _subStatus = ''; // '', pending, active, rejected
  String _subDocId = '';
  DateTime? _subExpiry;
  DateTime? _subCreatedAt;

  // Form
  final _txCtrl = TextEditingController();
  File? _receiptFile;
  double _uploadProgress = 0;
  final _picker = ImagePicker();

  // ── Payment method selection ───────────────────
  // 'jazzcash' | 'easypaisa' | 'bank'
  String _selectedMethod = 'jazzcash';

  static const String _jazzCashNumber = '03266621834';
  static const String _easyPaisaNumber = '03266621834';
  static const String _bankAccountNumber = '0020105778240018';
  static const String _bankName = 'Allied Bank';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _txCtrl.dispose();
    super.dispose();
  }

  // ── Load existing subscription ────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      _userId = uid ?? prefs.getString('userId') ?? '';

      if (_userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Check existing subscription
      final query = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final status = data['status'] ?? '';
        _subDocId = query.docs.first.id;
        _subStatus = status;

        // Parse expiry
        final expStr = data['subscriptionExpiryDate'] ?? '';
        if (expStr.isNotEmpty) {
          try {
            _subExpiry = DateTime.parse(expStr);
          } catch (_) {}
        }

        // Parse createdAt
        final cat = data['createdAt'];
        if (cat != null) {
          _subCreatedAt = (cat as Timestamp).toDate();
        }
      }
    } catch (e) {
      debugPrint('Load subscription error: $e');
    }

    setState(() => _isLoading = false);
  }

  // ── Submit new subscription ───────────────────
  Future<void> _submit() async {
    if (_txCtrl.text.trim().isEmpty) {
      _showError('ٹرانزیکشن ID درج کریں');
      return;
    }

    // ✅ Double check — koi pending/active nahi
    if (_subStatus == 'pending' || _subStatus == 'active') {
      _showError('آپ کی سبسکرپشن پہلے سے موجود ہے');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';

      // Upload receipt if selected
      String receiptUrl = '';
      if (_receiptFile != null) {
        setState(() => _uploadProgress = 0);
        final url = await R2UploadService.uploadImage(
          file: _receiptFile!,
          folder: 'receipts',
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        receiptUrl = url ?? '';
      }

      // ✅ Create ONE subscription document
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': _userId,
        'phone': phone,
        'transactionId': _txCtrl.text.trim(),
        'receiptUrl': receiptUrl,
        'paymentMethod': _selectedMethod,
        'plan': 'standard',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ درخواست بھیج دی گئی — ایڈمن منظور کرے گا',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => _isSubmitting = false);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF6A1B9A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4A0080),
                      Color(0xFF6A1B9A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'سبسکرپشن',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'ماہانہ PKR 2,000',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // ── ACTIVE ──────────────────────────────────
    if (_subStatus == 'active') {
      return _StatusCard(
        icon: Icons.verified,
        iconColor: AppTheme.primaryGreen,
        bgColor: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
        title: 'سبسکرپشن فعال ہے! ✅',
        subtitle: _subExpiry != null
            ? 'میعاد: ${_subExpiry!.day}/${_subExpiry!.month}/${_subExpiry!.year}'
            : 'آپ کی سبسکرپشن فعال ہے',
        statusLabel: 'فعال',
        statusColor: AppTheme.primaryGreen,
        extra: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تمام سہولیات دستیاب ہیں',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── PENDING ──────────────────────────────────
    if (_subStatus == 'pending') {
      return _StatusCard(
        icon: Icons.hourglass_top,
        iconColor: Colors.orange,
        bgColor: Colors.orange.withValues(alpha: 0.06),
        borderColor: Colors.orange.withValues(alpha: 0.3),
        title: 'درخواست زیر غور ہے',
        subtitle: _subCreatedAt != null
            ? 'بھیجی گئی: ${_subCreatedAt!.day}/${_subCreatedAt!.month}/${_subCreatedAt!.year}'
            : 'آپ کی درخواست موصول ہو گئی',
        statusLabel: 'زیر التواء',
        statusColor: Colors.orange,
        extra: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'ایڈمن آپ کی درخواست چیک کر رہا ہے',
                    style: TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 14,
                      color: Colors.orange,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '24-48 گھنٹوں میں منظور ہو جائے گی',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── REJECTED — Show form again ────────────────
    // ── NO SUBSCRIPTION or REJECTED — Show Form ──
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rejected notice
        if (_subStatus == 'rejected')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'پچھلی درخواست مسترد ہوئی',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'نئی ادائیگی کر کے دوبارہ درخواست دیں',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // ── Payment Method Card (matches reference UI) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ادائیگی کریں',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),

              // JazzCash
              _PaymentMethodTile(
                title: 'JazzCash',
                number: _jazzCashNumber,
                iconBg: const Color(0xFFE8272E),
                iconWidget: const Text(
                  'JC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                selected: _selectedMethod == 'jazzcash',
                onTap: () => setState(() => _selectedMethod = 'jazzcash'),
              ),
              const SizedBox(height: 10),

              // EasyPaisa
              _PaymentMethodTile(
                title: 'EasyPaisa',
                number: _easyPaisaNumber,
                iconBg: const Color(0xFF1BA146),
                iconWidget: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
                selected: _selectedMethod == 'easypaisa',
                onTap: () => setState(() => _selectedMethod = 'easypaisa'),
              ),
              const SizedBox(height: 10),

              // Bank Transfer
              _PaymentMethodTile(
                title: 'بینک ٹرانسفر',
                subtitle: _bankName,
                number: _bankAccountNumber,
                iconBg: const Color(0xFF6A1B9A),
                iconWidget: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 18,
                ),
                selected: _selectedMethod == 'bank',
                onTap: () => setState(() => _selectedMethod = 'bank'),
              ),
              const SizedBox(height: 14),

              // Amount row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'PKR 2,000',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'رقم',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Form Card ─────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ادائیگی کی تصدیق',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),

              // Transaction ID
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ٹرانزیکشن ID *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _txCtrl,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'مثال: TXN123456789',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.receipt_outlined,
                    color: Color(0xFF6A1B9A),
                    size: 20,
                  ),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF6A1B9A),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Receipt upload
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'رسید کی تصویر (اختیاری)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setState(() => _receiptFile = File(picked.path));
                  }
                },
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _receiptFile != null
                          ? const Color(0xFF6A1B9A)
                          : AppTheme.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: _receiptFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(
                            _receiptFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color(0xFF6A1B9A),
                              size: 32,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'رسید کی تصویر شامل کریں',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textGrey,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Submit Button ──────────────────────
        _isSubmitting
            ? Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    color: const Color(0xFF6A1B9A),
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'درخواست بھیجی جا رہی ہے...',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A0080),
                      Color(0xFF6A1B9A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'درخواست بھیجیں',
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
    );
  }
}

// ── Status Card Widget ────────────────────────────
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final Widget? extra;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
              height: 1.8,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          if (extra != null) extra!,
        ],
      ),
    );
  }
}

// ── Payment Method Tile (selectable, shows full number) ──
class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String number;
  final Color iconBg;
  final Widget iconWidget;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    this.subtitle,
    required this.number,
    required this.iconBg,
    required this.iconWidget,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF6A1B9A) : AppTheme.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF6A1B9A) : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? const Color(0xFF6A1B9A) : AppTheme.borderLight,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),

            // Text (name + full number)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle != null ? '$title • $subtitle' : title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Icon badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
          ],
        ),
      ),
    );
  }
}
