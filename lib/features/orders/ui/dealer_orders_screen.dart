import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '/services/notification_service.dart';
import 'package:kisan_dost/models/notification_model.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
              '  آرڈر مکمل - اسٹاک اپ ڈیٹ ہو گیا',
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

  // ── Print / Save PDF (image-based, correct Nastaliq shaping) ──
  Future<void> _printOrder(BuildContext context) async {
    try {
      final captured = await _captureReceiptImage(context);

      final pdf = pw.Document();
      final image = pw.MemoryImage(captured.bytes);

      // Size the PDF page to match the receipt's own aspect ratio, so the
      // image fills the whole page instead of shrinking inside A5 with
      // blank margins (that letterboxing was making the text look smaller).
      const targetWidthPt = 380.0; // ~ A5 width in points, tweak as needed
      final aspect = captured.height / captured.width;
      final pageFormat = PdfPageFormat(
        targetWidthPt,
        targetWidthPt * aspect,
        marginAll: 0,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'KisanDost_Order_$id.pdf',
      );
    } catch (e) {
      debugPrint('Print error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('پرنٹ میں خرابی: $e', textDirection: TextDirection.rtl),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Renders the receipt off-screen with Flutter's own text engine (correct
  // Nastaliq shaping) and captures it as a PNG to embed in the PDF, along
  // with its pixel dimensions so the PDF page can match its aspect ratio.
  Future<({Uint8List bytes, double width, double height})> _captureReceiptImage(
      BuildContext context) async {
    final repaintKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000, // keep it off-screen but still laid out & painted
        top: 0,
        child: Material(
          color: Colors.white,
          child: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: 560,
              child: _ReceiptContent(data: data, orderId: id),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Let it lay out and paint at least one full frame before capturing.
    await Future.delayed(const Duration(milliseconds: 300));

    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final uiImage = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);

    entry.remove();

    return (
      bytes: byteData!.buffer.asUint8List(),
      width: uiImage.width.toDouble(),
      height: uiImage.height.toDouble(),
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
            value.isEmpty ? '-' : value,
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

// ── Receipt Content (rendered off-screen, captured to image for PDF) ──
class _ReceiptContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderId;

  const _ReceiptContent({required this.data, required this.orderId});

  String _s(dynamic v) =>
      (v == null || v.toString().trim().isEmpty) ? '-' : v.toString().trim();

  @override
  Widget build(BuildContext context) {
    final totalPrice = data['totalPrice'] ?? 0;
    final unitPrice = data['productPrice'] ?? 0;
    final qty = data['quantity'] ?? '';
    final qtyNum = data['quantityNum'] ?? 0;
    final calculatedTotal = totalPrice > 0 ? totalPrice : unitPrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('کسان دوست',
                      style: TextStyle(
                          fontFamily: 'Noto',
                          fontSize: 34,
                          color: Colors.white,
                          height: 1.8)),
                  const SizedBox(height: 4),
                  const Text('آرڈر رسید',
                      style: TextStyle(
                          fontFamily: 'Noto',
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.6)),
                  const SizedBox(height: 4),
                  const Text('KISSANDOST.PK',
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('آرڈر کی تفصیل'),
            const Divider(color: Colors.black),
            _row('پروڈکٹ', _s(data['productName'])),
            _row('قسم', _s(data['productCategory'])),
            _row('فی یونٹ قیمت', 'PKR $unitPrice'),
            _row('مقدار', qty.toString()),
            if (qtyNum > 0) _row('یونٹس', qtyNum.toString()),
            const SizedBox(height: 8),
            _sectionTitle('خریدار کی معلومات'),
            const Divider(color: Colors.black),
            _row('نام', _s(data['buyerName'])),
            _row('موبائل', _s(data['buyerPhone'])),
            _row('ضلع', _s(data['buyerDistrict'])),
            _row('تحصیل', _s(data['buyerTehsil'])),
            if (_s(data['address']) != '-') _row('پتہ', _s(data['address'])),
            if (_s(data['notes']) != '-') _row('نوٹس', _s(data['notes'])),
            const SizedBox(height: 8),
            _sectionTitle('ڈیلر کی معلومات'),
            const Divider(color: Colors.black),
            _row('ڈیلر نام', _s(data['dealerName'])),
            _row('دکان', _s(data['dealerShop'])),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PKR $calculatedTotal',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text('کل رقم',
                      style: TextStyle(
                          fontFamily: 'Noto',
                          fontSize: 26,
                          color: Colors.white,
                          height: 1.8)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('شکریہ - کسان دوست',
                  style: TextStyle(
                      fontFamily: 'Noto',
                      fontSize: 18,
                      color: Colors.black,
                      height: 1.6)),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('KISSANDOST.PK',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
            const Center(
              child: Text('Pakpattan, Punjab, Pakistan',
                  style: TextStyle(fontSize: 13, color: Colors.black)),
            ),
            const Center(
              child: Text('support@kissandost.pk',
                  style: TextStyle(fontSize: 13, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title,
            style: const TextStyle(
                fontFamily: 'Noto',
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontFamily: 'Noto',
                      fontSize: 18,
                      color: Colors.black,
                      height: 1.6),
                  textAlign: TextAlign.left),
            ),
            const SizedBox(width: 12),
            Text('$label:',
                style: const TextStyle(
                    fontFamily: 'Noto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.6)),
          ],
        ),
      );
}
