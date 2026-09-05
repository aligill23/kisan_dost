import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../services/r2_upload_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // ── State ─────────────────────────────────
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitLock = false;
  String _userId = '';
  String _userName = '';

  // Subscription
  String _subStatus = '';
  String _subDocId = '';
  DateTime? _subExpiry;
  DateTime? _subCreatedAt;

  // Form
  final _txCtrl = TextEditingController();
  File? _receiptFile;
  double _uploadProgress = 0;
  final _picker = ImagePicker();
  String _selectedMethod = 'jazzcash';

  // ── Constants ─────────────────────────────
  static const _jazz = '03266621834';
  static const _easy = '03266621834';
  static const _bank = 'PK81ABPA0020105778240018';
  static const _bankName = 'الائیڈ بینک';
  static const _accountTitle = 'Wajahat Ali';
  static const _green = Color(0xFF1B8A3D);
  static const _darkGreen = Color(0xFF0E5F28);

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

  // ── Load Data ─────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      _userId = uid ?? prefs.getString('userId') ?? '';
      _userName = prefs.getString('userName') ?? '';

      if (_userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: _userId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get(),
        FirebaseFirestore.instance.collection('users').doc(_userId).get(),
      ]);

      final subQuery = results[0] as QuerySnapshot;
      final userDoc = results[1] as DocumentSnapshot;

      // Users doc — subscriptionStatus
      if (userDoc.exists) {
        final ud = userDoc.data() as Map<String, dynamic>;
        final userSubStatus = ud['subscriptionStatus'] ?? '';

        if (userSubStatus == 'active') {
          _subStatus = 'active';
          final exp = ud['subscriptionExpiry'];
          if (exp != null) {
            _subExpiry = (exp as dynamic).toDate();
          }
        }

        if (_userName.isEmpty) {
          _userName = ud['name'] ?? '';
        }
      }

      // Subscriptions collection
      if (subQuery.docs.isNotEmpty) {
        final data = subQuery.docs.first.data() as Map<String, dynamic>;
        final status = data['status'] ?? '';

        if (status == 'active' || _subStatus != 'active') {
          _subStatus = status;
          _subDocId = subQuery.docs.first.id;

          final expStr = data['subscriptionExpiryDate'] ?? '';
          if (expStr.isNotEmpty) {
            try {
              _subExpiry = DateTime.parse(expStr);
            } catch (_) {}
          }

          final cat = data['createdAt'];
          if (cat != null) {
            _subCreatedAt = (cat as dynamic).toDate();
          }
        }
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Submit ────────────────────────────────
  Future<void> _submit() async {
    if (_submitLock || _isSubmitting) return;
    _submitLock = true;

    try {
      if (_txCtrl.text.trim().isEmpty) {
        _showError('ٹرانزیکشن ID درج کریں');
        return;
      }

      if (_subStatus == 'pending' || _subStatus == 'active') {
        _showError('آپ کی درخواست پہلے سے موجود ہے');
        return;
      }

      setState(() => _isSubmitting = true);

      // Firestore check before submit
      final existing = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: _userId)
          .where('status', whereIn: ['pending', 'active'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _subStatus = existing.docs.first.data()['status'];
          _subDocId = existing.docs.first.id;
          _isSubmitting = false;
        });
        _showError('آپ کی درخواست پہلے سے موجود ہے');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';

      // Upload receipt
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

      // Final double check
      final check2 = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', isEqualTo: _userId)
          .where('status', whereIn: ['pending', 'active'])
          .limit(1)
          .get();

      if (check2.docs.isNotEmpty) {
        setState(() => _isSubmitting = false);
        _showError('درخواست پہلے سے جمع ہو چکی ہے');
        await _loadData();
        return;
      }

      // Submit
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

      await _loadData();

      if (mounted) {
        _showSuccessSubmitDialog();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      _submitLock = false;
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Success Submit Dialog ─────────────────
  void _showSuccessSubmitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: _green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'درخواست بھیج دی گئی!',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _green,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ایڈمن آپ کی ادائیگی چیک کر کے 24-48 گھنٹوں میں منظور کرے گا',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ٹھیک ہے',
                    style: TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_darkGreen, _green],
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
                          size: 30,
                        ),
                        const SizedBox(height: 4),
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
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _green,
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
    // ── ACTIVE ────────────────────────────────
    if (_subStatus == 'active') {
      return _buildActiveCard();
    }

    // ── PENDING ───────────────────────────────
    if (_subStatus == 'pending') {
      return _buildPendingCard();
    }

    // ── FORM ──────────────────────────────────
    return _buildForm();
  }

  // ── Active Card ───────────────────────────
  Widget _buildActiveCard() {
    final expDay = _subExpiry?.day ?? '';
    final expMonth = _subExpiry?.month ?? '';
    final expYear = _subExpiry?.year ?? '';

    return Column(
      children: [
        // Green verified banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_darkGreen, _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.verified,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _userName.isNotEmpty
                    ? 'مبارک ہو، $_userName!'
                    : 'سبسکرپشن فعال ہے',
                style: const TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'آپ کی سبسکرپشن فعال ہے',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Expiry card
        if (_subExpiry != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _green.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expiry date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$expDay/$expMonth/$expYear',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                    Text(
                      'میعاد ختم',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'فعال',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 14,
                          color: _green,
                          fontWeight: FontWeight.bold,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.circle,
                        color: _green,
                        size: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Features list
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'آپ کو یہ سہولیات مل رہی ہیں',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              _featureRow('کسانوں سے رابطہ'),
              _featureRow('بزنس پیج'),
              _featureRow('آرڈر مینجمنٹ'),
              _featureRow('پروڈکٹ لسٹنگ'),
              _featureRow('ترجیحی سپورٹ'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 10),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: _green,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending Card ──────────────────────────
  Widget _buildPendingCard() {
    return Column(
      children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'زیر التواء',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'درخواست زیر غور ہے',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ایڈمن آپ کی ادائیگی چیک کر رہا ہے',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submitted info
        if (_subCreatedAt != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_subCreatedAt!.day}/${_subCreatedAt!.month}/${_subCreatedAt!.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'درخواست کی تاریخ',
                  style: TextStyle(
                    fontFamily: 'Nastaleeq',
                    fontSize: 14,
                    color: AppTheme.textGrey,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Timeline
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'اگلے مراحل',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 14),
              _timelineStep(
                '1',
                'درخواست موصول',
                true,
                Colors.orange,
              ),
              _timelineStep(
                '2',
                'ادائیگی کی تصدیق',
                false,
                Colors.orange,
              ),
              _timelineStep(
                '3',
                'سبسکرپشن فعال',
                false,
                _green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineStep(
    String num,
    String text,
    bool done,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 14,
              color: done ? AppTheme.textDark : Colors.grey.shade400,
              fontWeight: done ? FontWeight.bold : FontWeight.normal,
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  done ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? color : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check, color: color, size: 14)
                  : Text(
                      num,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ──────────────────────────────────
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rejected notice
        if (_subStatus == 'rejected') ...[
          Container(
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
                Icon(Icons.cancel_outlined, color: Colors.red, size: 32),
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
          const SizedBox(height: 16),
        ],

        // ── Step 1: Payment ────────────────────
        _stepHeader('1', 'ادائیگی کریں'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Account title
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _accountTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Text(
                        'اکاؤنٹ ٹائٹل',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 11,
                          color: AppTheme.textGrey,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: _green,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // JazzCash
              _PaymentTile(
                title: 'JazzCash',
                number: _jazz,
                iconBg: const Color(0xFFE8272E),
                iconLabel: 'JC',
                selected: _selectedMethod == 'jazzcash',
                onTap: () => setState(() => _selectedMethod = 'jazzcash'),
              ),
              const SizedBox(height: 10),

              // EasyPaisa
              _PaymentTile(
                title: 'EasyPaisa',
                number: _easy,
                iconBg: const Color(0xFF1BA146),
                iconIcon: Icons.account_balance_wallet,
                selected: _selectedMethod == 'easypaisa',
                onTap: () => setState(() => _selectedMethod = 'easypaisa'),
              ),
              const SizedBox(height: 10),

              // Bank
              _PaymentTile(
                title: 'بینک ٹرانسفر • $_bankName',
                number: _bank,
                iconBg: _darkGreen,
                iconIcon: Icons.account_balance,
                selected: _selectedMethod == 'bank',
                onTap: () => setState(() => _selectedMethod = 'bank'),
              ),
              const SizedBox(height: 14),

              // Amount
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _darkGreen,
                      _green,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PKR 2,000',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'کل رقم — ماہانہ',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Step 2: Transaction ID ─────────────
        _stepHeader('2', 'ٹرانزیکشن ID درج کریں'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ادائیگی کے بعد ملنے والا نمبر درج کریں',
                style: TextStyle(
                  fontFamily: 'Nastaleeq',
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _txCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'TXN123456789',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade300,
                    letterSpacing: 2,
                  ),
                  prefixIcon: const Icon(
                    Icons.tag,
                    color: _green,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2FBF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _green,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Step 3: Receipt ────────────────────
        _stepHeader('3', 'رسید کی تصویر (اختیاری)'),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () async {
            final picked = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (picked != null) {
              setState(() => _receiptFile = File(picked.path));
            }
          },
          child: Container(
            width: double.infinity,
            // ✅ Fixed height — image sai dikhegi
            height: _receiptFile != null ? 220 : 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _receiptFile != null ? _green : Colors.grey.shade200,
                width: _receiptFile != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                ),
              ],
            ),
            child: _receiptFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.file(
                          _receiptFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Change button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'تبدیل کریں',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _receiptFile = null),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _green,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'رسید کی تصویر شامل کریں',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 14,
                          color: AppTheme.textDark,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'گیلری سے منتخب کریں',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Submit ─────────────────────────────
        _isSubmitting
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      color: _green,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _uploadProgress > 0
                        ? 'رسید اپلوڈ ہو رہی ہے... ${(_uploadProgress * 100).toInt()}%'
                        : 'درخواست بھیجی جا رہی ہے...',
                    style: const TextStyle(
                      fontFamily: 'Nastaleeq',
                      fontSize: 14,
                      color: AppTheme.textGrey,
                      height: 1.8,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_darkGreen, _green],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _submitLock) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'درخواست بھیجیں',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Step Header ───────────────────────────
  Widget _stepHeader(String num, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nastaleeq',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            height: 1.8,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _green,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payment Tile ──────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final String title;
  final String number;
  final Color iconBg;
  final String? iconLabel;
  final IconData? iconIcon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.title,
    required this.number,
    required this.iconBg,
    this.iconLabel,
    this.iconIcon,
    required this.selected,
    required this.onTap,
  });

  static const _green = Color(0xFF1B8A3D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _green : AppTheme.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _green : Colors.transparent,
                border: Border.all(
                  color: selected ? _green : AppTheme.borderLight,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: iconLabel != null
                  ? Text(
                      iconLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : Icon(
                      iconIcon,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
