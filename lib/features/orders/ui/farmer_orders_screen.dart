import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  String _userId = '';
  String _selectedFilter = 'سب';

  final List<String> _filters = [
    'سب',
    'زیر التواء',
    'مکمل',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userId = prefs.getString('userId') ?? '');
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
            backgroundColor: AppTheme.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F3D1A),
                      Color(0xFF1B5E20),
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
                          'آپ کے تمام آرڈرز یہاں ہیں',
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
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryGreen
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
          _userId.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('buyerId', isEqualTo: _userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
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
                            return _FarmerOrderCard(data: data);
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 50,
              color: AppTheme.primaryGreen.withValues(alpha: 0.5),
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
            'مارکیٹ پلیس سے آرڈر کریں',
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

// ── Farmer Order Card ─────────────────────────────
class _FarmerOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FarmerOrderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final statusColor =
        isCompleted ? AppTheme.primaryGreen : const Color(0xFFE65100);
    final statusLabel = isCompleted ? 'مکمل' : 'زیر التواء';
    final statusIcon = isCompleted ? Icons.check_circle : Icons.pending;

    final totalPrice = data['totalPrice'] ?? 0;
    final unitPrice = data['productPrice'] ?? 0;
    final qty = data['quantity'] ?? '';

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
                // Status Badge
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
                      Icon(statusIcon, size: 13, color: statusColor),
                    ],
                  ),
                ),

                // Product Name
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

          // ── Card Body ────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Product Image + Info Row
                Row(
                  children: [
                    // Info
                    Expanded(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.scale_outlined,
                            label: 'مقدار',
                            value: qty.toString(),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.monetization_on_outlined,
                            label: 'فی یونٹ',
                            value: '$unitPrice روپے',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.store_outlined,
                            label: 'ڈیلر',
                            value: data['dealerName'] ?? '',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.home_outlined,
                            label: 'پتہ',
                            value: data['address'] ?? '',
                          ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['productImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppTheme.primaryGreen,
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

                // ── Total Price ──────────────────
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
                              const Color(0xFF5D3A00),
                              const Color(0xFFE65100),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalPrice > 0 ? 'PKR $totalPrice' : 'PKR $unitPrice',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'کل رقم',
                        style: TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),

                // ── Completed Banner ─────────────
                if (isCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'آرڈر مکمل ہو گیا',
                          style: TextStyle(
                            fontFamily: 'Nastaleeq',
                            fontSize: 14,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            height: 1.8,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryGreen,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Pending Note ─────────────────
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE65100).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      'ڈیلر جلد رابطہ کرے گا',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 13,
                        color: Color(0xFFE65100),
                        height: 1.8,
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
    );
  }
}

// ── Info Row Widget ───────────────────────────────
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
              color: AppTheme.primaryGreen,
            ),
          ],
        ),
      ],
    );
  }
}
