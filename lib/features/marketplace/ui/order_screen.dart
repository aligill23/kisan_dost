import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '/services/notification_service.dart';
import 'package:kisan_dost/models/notification_model.dart';

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const OrderScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  int _totalPrice = 0;

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مقدار درج کریں',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'پتہ درج کریں',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final stock = widget.productData['stock'] ?? 0;
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'صرف $stock ${widget.productData['unit'] ?? 'یونٹ'} دستیاب ہیں',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      //   SharedPreferences se credentials
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final phone = prefs.getString('phoneNumber') ?? '';

      // ignore: use_build_context_synchronously
      final profileVM = context.read<ProfileViewModel>();
      final profile = profileVM.currentUser;

      await FirebaseFirestore.instance.collection('orders').add({
        'productId': widget.productId,
        'productName': widget.productData['name'],
        'productPrice': widget.productData['price'],
        'productImage': widget.productData['imageUrl'] ?? '',
        'dealerId': widget.productData['dealerId'],
        'dealerName': widget.productData['dealerName'],
        'dealerPhone': widget.productData['dealerPhone'] ?? '',
        'buyerId': userId, //   Fixed
        'buyerName': profile?.name ?? '',
        'buyerPhone': phone, //   Fixed
        'buyerDistrict': profile?.district ?? '',
        'buyerTehsil': profile?.tehsil ?? '',
        'quantity': _quantityController.text.trim(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'totalPrice': _totalPrice,
        'quantityNum': qty,
      });
      await NotificationService.sendNotification(
        userId: widget.productData['dealerId'] ?? '',
        role: 'dealer',
        type: NotificationType.orderPlaced, //   was: 'order_status'
        title: 'ایک نیا آرڈر آ گیا 🛒',
        message:
            '${profile?.name ?? 'ایک کسان'} نے ${widget.productData['name']} کا آرڈر دیا ہے',
        referenceId: '',
        referenceType: 'order',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess() {
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F3D1A), AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'آرڈر دے دیا گیا!',
                style: TextStyle(
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
              const Text(
                'آپ کا آرڈر کامیابی سے دے دیا گیا ہے',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ڈیلر جلد آپ سے رابطہ کرے گا',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryGreen,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F3D1A), AppTheme.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ٹھیک ہے',
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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: AppTheme.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F3D1A), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'آرڈر دیں',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'آرڈر کی تفصیل درج کریں',
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

                  // Product Summary Card
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
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: (widget.productData['imageUrl']?.isNotEmpty ==
                                  true)
                              ? Image.network(
                                  widget.productData['imageUrl'],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imgPlaceholder(),
                                )
                              : _imgPlaceholder(),
                        ),

                        // Product Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.productData['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.productData['price']} روپے '
                                  '${widget.productData['unit'] ?? 'فی بوری'}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.productData['dealerName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGrey,
                                    height: 1.4,
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
                  const SizedBox(height: 16),

                  // Buyer Info Card
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'آپ کی معلومات',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(width: 8),
                            // ignore: prefer_const_constructors
                            Icon(
                              Icons.person_outline,
                              color: AppTheme.primaryGreen,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'نام',
                                value: profile?.name ?? '',
                                icon: Icons.badge_outlined,
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                label: 'موبائل',
                                value: profile?.phone ?? '',
                                icon: Icons.phone_outlined,
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                label: 'ضلع',
                                value: profile?.district ?? '',
                                icon: Icons.location_on_outlined,
                              ),
                              const _RowDivider(),
                              _InfoRow(
                                label: 'تحصیل',
                                value: profile?.tehsil ?? '',
                                icon: Icons.place_outlined,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Details Card
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
                        // Quantity
                        // ignore: prefer_const_constructors
                        _FormLabel(text: 'مقدار *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          onChanged: (val) {
                            setState(() {
                              final qty = int.tryParse(val) ?? 0;
                              final price = widget.productData['price'] ?? 0;
                              _totalPrice = qty * (price as num).toInt();
                            });
                          },
                          decoration: _inputDeco(
                            hint: 'مثال: 2',
                            icon: Icons.scale_outlined,
                            suffix: widget.productData['unit'] ?? 'بوری',
                          ),
                        ),
                        if (_totalPrice > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F3D1A),
                                  AppTheme.primaryGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PKR $_totalPrice',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Text(
                                  'کل رقم',
                                  style: TextStyle(
                                    fontFamily: 'Nastaleeq',
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.8,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Address
                        // ignore: prefer_const_constructors
                        _FormLabel(text: 'مکمل پتہ *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'گھر کا پتہ یا گاؤں کا نام',
                            icon: Icons.home_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notes
                        // ignore: prefer_const_constructors
                        _FormLabel(text: 'اضافی نوٹ (اختیاری)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'کوئی خاص بات درج کریں',
                            icon: Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F3D1A),
                                AppTheme.primaryGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: const Text(
                              'آرڈر دیں',
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
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppTheme.primaryGreen,
        size: 36,
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        color: AppTheme.textGrey,
        fontSize: 13,
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
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
            height: 1.5,
          ),
          textDirection: TextDirection.rtl,
        ),
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
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: AppTheme.textGrey),
          ],
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
    );
  }
}
