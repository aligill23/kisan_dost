import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/r2_upload_service.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _unitController;
  late TextEditingController _stockController;
  String? _selectedCategory;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'کھاد',
    'بیج',
    'کیڑے مار دوا',
    'سپرے',
    'زرعی آلات',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.productData['name'] ?? '');
    _priceController = TextEditingController(
        text: widget.productData['price']?.toString() ?? '');
    _descController =
        TextEditingController(text: widget.productData['description'] ?? '');
    _unitController =
        TextEditingController(text: widget.productData['unit'] ?? '');
    _stockController = TextEditingController(
        text: widget.productData['stock']?.toString() ?? '0');
    _selectedCategory = widget.productData['category'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تصویر تبدیل کریں',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'گیلری',
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        setState(() => _newImageFile = File(picked.path));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'کیمرہ',
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (picked != null) {
                        setState(() => _newImageFile = File(picked.path));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نام اور قیمت ضروری ہے',
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
      String imageUrl = widget.productData['imageUrl'] ?? '';

      // Upload new image if selected
      if (_newImageFile != null) {
        final newUrl = await R2UploadService.uploadProductImage(
          _newImageFile!,
          onProgress: (p) {
            setState(() => _uploadProgress = p);
          },
        );
        if (newUrl != null) imageUrl = newUrl;
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _nameController.text.trim(),
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'unit': _unitController.text.trim(),
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'پروڈکٹ اپ ڈیٹ ہو گیا  ',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.productData['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: const Color(0xFF0D3B8E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B8E), Color(0xFF1565C0)],
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
                          'پروڈکٹ ترمیم کریں',
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
                          'معلومات تبدیل کریں',
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

                  // ── Image Section ──────────────
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Show new or existing image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: _newImageFile != null
                                ? Image.file(
                                    _newImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : existingImageUrl.isNotEmpty
                                    ? Image.network(
                                        existingImageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, prog) {
                                          if (prog == null) return child;
                                          return Container(
                                            color: const Color(0xFF1565C0)
                                                .withValues(alpha: 0.08),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF1565C0),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            _imgPlaceholder(),
                                      )
                                    : _imgPlaceholder(),
                          ),

                          // Camera overlay button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'تصویر تبدیل کریں',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // New image badge
                          if (_newImageFile != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'نئی تصویر ✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Form Card ──────────────────
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
                        // Name
                        _FormLabel(text: 'پروڈکٹ کا نام *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'پروڈکٹ کا نام',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Category
                        _FormLabel(text: 'قسم'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          textDirection: TextDirection.rtl,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategory = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price
                        _FormLabel(text: 'قیمت (روپے) *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'قیمت',
                            icon: Icons.attach_money_outlined,
                          ).copyWith(
                            prefixIcon: const Center(
                              widthFactor: 1.0,
                              child: Text(
                                'PKR',
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Unit
                        _FormLabel(text: 'اکائی'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _unitController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'مثال: فی بوری، فی کلو',
                            icon: Icons.scale_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stock
                        _FormLabel(text: 'دستیاب مقدار'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'دستیاب یونٹس',
                            icon: Icons.inventory_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        _FormLabel(text: 'تفصیل (اختیاری)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'پروڈکٹ کے بارے میں لکھیں',
                            icon: Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save Button ────────────────
                  _isLoading
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: _newImageFile != null
                                  ? _uploadProgress
                                  : null,
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.2),
                              color: const Color(0xFF1565C0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _newImageFile != null
                                  ? 'تصویر اپلوڈ ہو رہی ہے...'
                                  : 'محفوظ ہو رہا ہے...',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textGrey,
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
                                Color(0xFF0D3B8E),
                                Color(0xFF1565C0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0)
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: const Text(
                              'محفوظ کریں',
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
      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Color(0xFF1565C0),
            ),
            SizedBox(height: 8),
            Text(
              'تصویر شامل کریں',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1565C0),
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
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
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}

// ── Form Label ────────────────────────────────────
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

// ── Image Source Button ───────────────────────────
class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0),
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
