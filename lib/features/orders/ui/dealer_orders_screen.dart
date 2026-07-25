import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart'; //
import 'package:pdf/pdf.dart'; //
import 'package:pdf/widgets.dart' as pw; //
import '../../../core/theme/app_theme.dart';
import '/services/notification_service.dart';
import 'package:kisan_dost/models/notification_model.dart';
import 'package:flutter/services.dart';

class DealerOrdersScreen extends StatefulWidget {
  const DealerOrdersScreen({super.key});

  @override
  State<DealerOrdersScreen> createState() => _DealerOrdersScreenState();
}

class _DealerOrdersScreenState extends State<DealerOrdersScreen> {
  String _dealerId = '';
  String _selectedFilter = 'سب';

  final List<String> _filters = [
    'سب',
    'زیر التواء',
    'مکمل',
  ];

  @override
  void initState() {
    super.initState();
    _loadDealerId();
  }

  Future<void> _loadDealerId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _dealerId = prefs.getString('userId') ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    colors: [
                      Color(0xFF0D3B8E),
                      Color(0xFF1565C0),
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
                        const Text(
                          'میرے آرڈرز',
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
                          'تمام آرڈرز یہاں ہیں',
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

          // ── Filter Chips ───────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final selected = filter == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            color: selected ? Colors.white : AppTheme.textGrey,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Orders List ────────────────────────
          _dealerId.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('dealerId', isEqualTo: _dealerId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SliverFillRemaining(
                        child: _emptyState(),
                      );
                    }

                    var docs = snapshot.data!.docs;

                    // Apply filter
                    if (_selectedFilter == 'زیر التواء') {
                      docs = docs
                          .where(
                              (d) => (d.data() as Map)['status'] == 'pending')
                          .toList();
                    } else if (_selectedFilter == 'مکمل') {
                      docs = docs
                          .where(
                              (d) => (d.data() as Map)['status'] == 'completed')
                          .toList();
                    }

                    if (docs.isEmpty) {
                      return SliverFillRemaining(
                        child: _emptyState(),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final id = docs[index].id;
                            return _DealerOrderCard(
                              data: data,
                              id: id,
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  },
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 50,
              color: const Color(0xFF1565C0).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ابھی کوئی آرڈر نہیں',
            style: TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 20,
              color: AppTheme.textGrey,
              height: 1.8,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          const Text(
            'جب کسان آرڈر کریں گے یہاں دکھے گا',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ── Dealer Order Card ─────────────────────────────
class _DealerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const _DealerOrderCard({
    required this.data,
    required this.id,
  });

  // ── Complete Order + Update Stock ─────────────
  Future<void> _completeOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'آرڈر مکمل کریں؟',
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
                'مکمل کرنے پر اسٹاک خود بخود کم ہو جائے گا',
                style: TextStyle(
                  fontSize: 12,
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
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('نہیں'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      child: const Text(
                        'مکمل کریں',
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

    if (confirm != true) return;

    try {
      final productId = data['productId'] ?? '';
      final qty = data['quantityNum'] ?? 0;

      // Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .update({'status': 'completed'});

      //   Decrease stock + increase soldUnits
      if (productId.isNotEmpty && qty > 0) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({
          'stock': FieldValue.increment(-qty),
          'soldUnits': FieldValue.increment(qty),
        });
      }
      NotificationService.sendNotification(
        userId: data['buyerId'] ?? '',
        role: 'farmer',
        type: NotificationType.orderDelivered,
        title: 'آرڈر مکمل ہو گیا!  ',
        message: '${data['productName']} کا آرڈر مکمل ہو گیا',
        referenceId: id,
        referenceType: 'order',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '  آرڈر مکمل — اسٹاک اپ ڈیٹ ہو گیا',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Delete Order ──────────────────────────────
  Future<void> _deleteOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 14),
              const Text(
                'آرڈر حذف کریں؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
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
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('نہیں'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                        'حذف کریں',
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

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('orders').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'آرڈر حذف ہو گیا',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Print / Save PDF ──────────────────────────
  // ✅ FIXED: loads the Urdu font (JameelNoriNastleeq) before building the PDF
  // and uses it for every Urdu text run, with RTL text direction throughout.
  Future<void> _printOrder(BuildContext context) async {
    // ✅ Load the Urdu font — must match the asset path in pubspec.yaml
    final fontData = await rootBundle.load(
      'assets/fonts/JameelNoriNastleeq.TTF',
    );
    final urduFont = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    final totalPrice = data['totalPrice'] ?? 0;
    final unitPrice = data['productPrice'] ?? 0;
    final qty = data['quantity'] ?? '';
    final qtyNum = data['quantityNum'] ?? 0;
    final calculatedTotal = totalPrice > 0 ? totalPrice : unitPrice;

    // ✅ Urdu text style helper
    pw.TextStyle urduStyle({
      double fontSize = 12,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor color = PdfColors.black,
    }) {
      return pw.TextStyle(
        font: urduFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        // ✅ RTL direction for the whole page
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.05, 0.24, 0.54),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'کسان دوست',
                      style: urduStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'آرڈر رسید',
                      style: urduStyle(
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'KisanDost Tech — Pakpattan',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Details
              pw.Text(
                'آرڈر کی تفصیل',
                style: urduStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.4, 0.4, 0.4),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              _urduRow('پروڈکٹ', data['productName'] ?? '', urduFont),
              _urduRow('قسم', data['productCategory'] ?? '—', urduFont),
              _urduRow('فی یونٹ قیمت', 'PKR $unitPrice', urduFont),
              _urduRow('مقدار', qty.toString(), urduFont),
              if (qtyNum > 0) _urduRow('یونٹس', qtyNum.toString(), urduFont),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Buyer Details
              pw.Text(
                'خریدار کی معلومات',
                style: urduStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.4, 0.4, 0.4),
                ),
              ),
              pw.SizedBox(height: 8),

              _urduRow('نام', data['buyerName'] ?? '', urduFont),
              _urduRow('موبائل', data['buyerPhone'] ?? '', urduFont),
              _urduRow('ضلع', data['buyerDistrict'] ?? '', urduFont),
              _urduRow('تحصیل', data['buyerTehsil'] ?? '', urduFont),
              if ((data['address'] ?? '').isNotEmpty)
                _urduRow('پتہ', data['address'], urduFont),
              if ((data['notes'] ?? '').isNotEmpty)
                _urduRow('نوٹس', data['notes'], urduFont),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Dealer Details
              pw.Text(
                'ڈیلر کی معلومات',
                style: urduStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.4, 0.4, 0.4),
                ),
              ),
              pw.SizedBox(height: 8),

              _urduRow('ڈیلر نام', data['dealerName'] ?? '', urduFont),
              _urduRow('دکان', data['dealerShop'] ?? '—', urduFont),

              pw.SizedBox(height: 20),

              // Total Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.18, 0.49, 0.12),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PKR $calculatedTotal',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'کل رقم',
                      style: urduStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Footer
              pw.Center(
                child: pw.Text(
                  'شکریہ — کسان دوست',
                  style: urduStyle(
                    fontSize: 11,
                    color: const PdfColor(0.5, 0.5, 0.5),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'kisandost.com | Pakpattan, Punjab',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: const PdfColor(0.6, 0.6, 0.6),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'KisanDost_${data['productName'] ?? 'Receipt'}.pdf',
    );
  }

  // ✅ Updated row helper — takes the loaded Urdu font so labels/values render
  pw.Widget _urduRow(String label, String value, pw.Font urduFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Value — left side
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
              style: pw.TextStyle(
                font: urduFont,
                fontSize: 11,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(width: 12),
          // Label — right side
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              font: urduFont,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor(0.4, 0.4, 0.4),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final statusColor =
        isCompleted ? AppTheme.primaryGreen : const Color(0xFFE65100);
    final statusLabel = isCompleted ? 'مکمل' : 'زیر التواء';

    final totalPrice = data['totalPrice'] ?? 0;
    final unitPrice = data['productPrice'] ?? 0;
    final qty = data['quantity'] ?? '';
    final qtyNum = data['quantityNum'] ?? 0;
    final calculatedTotal = totalPrice > 0 ? totalPrice : unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card Header ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.pending,
                        size: 13,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                Text(
                  data['productName'] ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Buyer + Product Info ─────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'خریدار',
                            value: data['buyerName'] ?? '',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'موبائل',
                            value: data['buyerPhone'] ?? '',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'ضلع',
                            value: data['buyerDistrict'] ?? '',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.home_outlined,
                            label: 'پتہ',
                            value: data['address'] ?? '',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.scale_outlined,
                            label: 'مقدار',
                            value: qty.toString(),
                          ),
                          if (qtyNum > 0) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.format_list_numbered,
                              label: 'یونٹس',
                              value: qtyNum.toString(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Product Image
                    if ((data['productImage'] ?? '').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['productImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF1565C0),
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 14),

                // ── Total Checkout ───────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [
                              const Color(0xFF0F3D1A),
                              AppTheme.primaryGreen,
                            ]
                          : [
                              const Color(0xFF0D3B8E),
                              const Color(0xFF1565C0),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PKR $calculatedTotal',
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
                      if (qtyNum > 0 && unitPrice > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$qtyNum × PKR $unitPrice',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              'تفصیل',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Action Buttons ───────────────
                Row(
                  children: [
                    // Delete Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _deleteOrder(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'حذف',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Print Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _printOrder(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1565C0).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'پرنٹ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.print_outlined,
                                color: Color(0xFF1565C0),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Complete Button (pending only)
                    if (!isCompleted)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _completeOrder(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F3D1A),
                                  AppTheme.primaryGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'مکمل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (isCompleted)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'مکمل',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryGreen,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
          ),
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
            Icon(
              icon,
              size: 13,
              color: const Color(0xFF1565C0),
            ),
          ],
        ),
      ],
    );
  }
}
