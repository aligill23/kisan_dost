import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/r2_upload_service.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = '';
  final _txnController = TextEditingController();
  File? _receiptFile;
  bool _isLoading = false;
  bool _submitted = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _receiptFile = File(picked.path));
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedPlan.isEmpty) {
      _showError('براہ کرم پلان منتخب کریں');
      return;
    }
    if (_receiptFile == null && _txnController.text.trim().isEmpty) {
      _showError('Transaction ID یا رسید ضروری ہے');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? receiptUrl;

      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';
      final userId = prefs.getString('userId') ?? '';
      debugPrint('DEBUG phone: $phone');
      debugPrint('DEBUG userId: $userId');

      if (_receiptFile != null) {
        receiptUrl = await R2UploadService.uploadReceipt(
          _receiptFile!,
          onProgress: (p) {
            setState(() {});
          },
        );
      }

      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': userId,
        'phone': phone,
        'plan': _selectedPlan,
        'transactionId': _txnController.text.trim(),
        'receiptUrl': receiptUrl ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'کاپی ہو گیا',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F7),
        elevation: 0,
        title: const Text(
          'سبسکرپشن پلان',
          style: TextStyle(
            fontSize: 20,
            height: 1.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'سبسکرپشن پلان',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'خریداروں اور کسانوں تک بہتر رسائی حاصل کریں',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Who Needs Subscription
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'یہ سبسکرپشن کن کیلئے ضروری ہے؟',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 14),
                    _roleRow(Icons.storefront_rounded, 'آڑھتی / کمپنی',
                        const Color(0xFFD08700)),
                    const SizedBox(height: 10),
                    _roleRow(Icons.science_outlined, 'سپرے اور کھاد ڈیلر',
                        const Color(0xFF6A1B9A)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'کسانوں کیلئے مفت ہے',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.eco_rounded,
                              color: AppTheme.primaryGreen, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Plan Selection Title
              _SectionTitle(
                icon: Icons.fact_check_outlined,
                text: 'پلان منتخب کریں',
              ),
              const SizedBox(height: 14),

              // Standard Plan
              _PlanCard(
                title: 'Standard Plan',
                icon: Icons.verified_rounded,
                price: '2000',
                priceUnit: 'روپے / ماہ',
                features: const [
                  'فصلوں تک رسائی',
                  'کسان رابطہ معلومات',
                  'مارکیٹ پلیس رسائی',
                  'آرڈر وصول کریں',
                  'ضلع بھر میں نمائش',
                ],
                isSelected: _selectedPlan == 'standard',
                isFeatured: false,
                color: AppTheme.primaryGreen,
                onTap: () => setState(() => _selectedPlan = 'standard'),
              ),
              const SizedBox(height: 16),

              // Featured Plan
              _PlanCard(
                title: 'Featured Boost Plan',
                icon: Icons.auto_awesome_rounded,
                price: '5000',
                priceUnit: 'روپے / ماہ',
                features: const [
                  'Standard کی تمام سہولیات',
                  'لسٹنگ کو نمایاں کریں',
                  'ترجیحی نمائش',
                  'ہوم پیج پر نمایاں جگہ',
                  'زیادہ آرڈرز کے امکانات',
                  'Featured Seller Badge',
                ],
                isSelected: _selectedPlan == 'featured',
                isFeatured: true,
                color: const Color(0xFF6A1B9A),
                onTap: () => setState(() => _selectedPlan = 'featured'),
              ),
              const SizedBox(height: 28),

              // Payment Methods
              _SectionTitle(
                icon: Icons.credit_card_rounded,
                text: 'ادائیگی کا طریقہ',
              ),
              const SizedBox(height: 14),

              _PaymentCard(
                name: 'EasyPaisa',
                number: '0326-6621834 Wajahat Ali',
                color: const Color(0xFF00A651),
                icon: Icons.smartphone_rounded,
                onCopy: () => _copyToClipboard('03266621834'),
              ),
              const SizedBox(height: 12),
              _PaymentCard(
                name: 'JazzCash',
                number: '0326-6621834 Wajahat Ali',
                color: const Color(0xFFE63946),
                icon: Icons.smartphone_rounded,
                onCopy: () => _copyToClipboard('03266621834'),
              ),
              const SizedBox(height: 12),
              _PaymentCard(
                name: 'Allied Bank',
                number: '021876659834 Wajahat Ali',
                color: const Color(0xFF1565C0),
                icon: Icons.account_balance_rounded,
                onCopy: () => _copyToClipboard('021876659834'),
              ),
              const SizedBox(height: 28),

              // Instructions
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'ادائیگی کی ہدایات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            color: AppTheme.primaryGreen,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _stepRow('1', 'اپنی پسند کا پلان منتخب کریں'),
                    _stepRow('2',
                        'EasyPaisa، JazzCash یا Mashreq Bank سے ادائیگی کریں'),
                    _stepRow('3', 'Transaction ID درج کریں یا رسید اپلوڈ کریں'),
                    _stepRow(
                        '4', 'ہماری ٹیم تصدیق کے بعد سبسکرپشن فعال کرے گی'),
                    _stepRow('5', 'تصدیق مکمل ہونے پر آپ کو اطلاع دی جائے گی',
                        isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Receipt Upload
              _SectionTitle(
                icon: Icons.receipt_long_outlined,
                text: 'ادائیگی کا ثبوت',
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickReceipt,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _receiptFile != null
                          ? AppTheme.primaryGreen
                          : AppTheme.borderLight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_receiptFile != null
                                ? AppTheme.primaryGreen
                                : Colors.black)
                            .withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _receiptFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _receiptFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                size: 30,
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Transaction Screenshot Upload کریں',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textGrey,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'JPG • PNG • PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Transaction ID
              _SectionTitle(
                icon: Icons.tag_rounded,
                text: 'Transaction ID',
                size: 16,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: TextFormField(
                  controller: _txnController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Transaction ID درج کریں',
                    hintTextDirection: TextDirection.rtl,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    hintStyle: TextStyle(
                      color: AppTheme.textGrey.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'تصدیق کیلئے جمع کروائیں',
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_back_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleRow(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textDark,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ],
    );
  }

  Widget _stepRow(String number, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Section title with leading icon badge
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final double size;

  const _SectionTitle({
    required this.icon,
    required this.text,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 16),
        ),
      ],
    );
  }
}

// Plan Card Widget
class _PlanCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String price;
  final String priceUnit;
  final List<String> features;
  final bool isSelected;
  final bool isFeatured;
  final Color color;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.icon,
    required this.price,
    required this.priceUnit,
    required this.features,
    required this.isSelected,
    required this.isFeatured,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star_rounded,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 3),
                              Text(
                                'سب سے مقبول',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      // Selection indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? color : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? color
                                : AppTheme.borderLight.withValues(alpha: 0.8),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 15)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceUnit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.check_circle_rounded,
                            color: color,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? color : Colors.white,
                        foregroundColor: isSelected ? Colors.white : color,
                        elevation: 0,
                        side: BorderSide(
                          color: color.withValues(alpha: isSelected ? 0 : 0.4),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSelected ? 'منتخب کیا گیا' : 'یہ پلان منتخب کریں',
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          if (isSelected) ...const [
                            SizedBox(width: 6),
                            Icon(Icons.check_rounded, size: 17),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Card Widget
class _PaymentCard extends StatelessWidget {
  final String name;
  final String number;
  final Color color;
  final IconData icon;
  final VoidCallback onCopy;

  const _PaymentCard({
    required this.name,
    required this.number,
    required this.color,
    required this.icon,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Copy Button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      'کاپی',
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Account Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
        ],
      ),
    );
  }
}

// Success Screen
class _SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen,
                      size: 68,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'درخواست موصول ہو گئی',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'آپ کی ادائیگی کی تفصیلات موصول ہو چکی ہیں۔ تصدیق کے بعد سبسکرپشن فعال کر دی جائے گی۔',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.7,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'واپس جائیں',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
