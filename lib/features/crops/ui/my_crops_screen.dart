import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../crops/ui/crop_post_screen.dart';

class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  String _userId = '';

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

  String _cropStatus(Map<String, dynamic> data) {
    final status = data['status'] ?? 'active';
    final expiresAt = data['expiresAt'];
    if (expiresAt != null) {
      final expiry = (expiresAt as Timestamp).toDate();
      if (expiry.isBefore(DateTime.now())) return 'expired';
    }
    return status;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'دستیاب';
      case 'inactive':
        return 'غیر فعال';
      case 'expired':
        return 'میعاد ختم';
      default:
        return 'دستیاب';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.primaryGreen;
      case 'inactive':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final time = (timestamp as Timestamp).toDate();
      return '${time.day}/${time.month}/${time.year}';
    } catch (_) {
      return '';
    }
  }

  String _daysRemaining(dynamic expiresAt) {
    if (expiresAt == null) return '';
    try {
      final expiry = (expiresAt as Timestamp).toDate();
      final diff = expiry.difference(DateTime.now()).inDays;
      if (diff < 0) return 'میعاد ختم';
      if (diff == 0) return 'آج ختم';
      return '$diff دن باقی';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.darkGreen,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'میری فصلیں',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            Text(
                              'آپ کی تمام فصل پوسٹس',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          _userId.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('crops')
                      .where('userId', isEqualTo: _userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _emptyState(context),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final id = docs[index].id;
                            final status = _cropStatus(data);

                            return _MyCropCard(
                              data: data,
                              id: id,
                              status: status,
                              statusLabel: _statusLabel(status),
                              statusColor: _statusColor(status),
                              postDate: _formatDate(data['createdAt']),
                              daysRemaining: _daysRemaining(data['expiresAt']),
                              onToggle: () async {
                                final newStatus =
                                    status == 'active' ? 'inactive' : 'active';
                                await FirebaseFirestore.instance
                                    .collection('crops')
                                    .doc(id)
                                    .update({'status': newStatus});
                              },
                              onDelete: () => _confirmDelete(context, id),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'فصل حذف کریں؟',
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
                'کیا آپ واقعی یہ فصل حذف کرنا چاہتے ہیں؟',
                style: TextStyle(
                  fontSize: 13,
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
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('نہیں',
                          style: TextStyle(color: AppTheme.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حذف کریں',
                          style: TextStyle(color: Colors.white)),
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
      await FirebaseFirestore.instance.collection('crops').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('فصل حذف ہو گئی', textDirection: TextDirection.rtl),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Image.asset(
            'assets/images/my_crop_posts.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.grass_outlined,
              size: 80,
              color: AppTheme.textGrey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ابھی کوئی فصل نہیں',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'اپنی فصل پوسٹ کریں اور آڑھتیوں تک پہنچیں',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3D1A), AppTheme.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CropPostScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'فصل پوسٹ کریں',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MyCropCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final String postDate;
  final String daysRemaining;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MyCropCard({
    required this.data,
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.postDate,
    required this.daysRemaining,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Crop Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 110,
                  height: 150,
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, prog) {
                            if (prog == null) return child;
                            return Container(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status + Crop Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          Text(
                            data['cropType'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'روپے/من',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['expectedPrice']?.toString() ?? '0',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Quantity
                      _InfoRow(
                        icon: Icons.scale_outlined,
                        text: 'مقدار: ${data['quantity']}',
                      ),
                      const SizedBox(height: 4),

                      // District
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: data['district'] ?? '',
                      ),
                      const SizedBox(height: 4),

                      // Date
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: postDate,
                      ),
                      const SizedBox(height: 4),

                      // Days Remaining
                      if (daysRemaining.isNotEmpty)
                        _InfoRow(
                          icon: Icons.timer_outlined,
                          text: daysRemaining,
                          color: status == 'expired'
                              ? Colors.red
                              : AppTheme.textGrey,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Actions
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Delete
                Expanded(
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'حذف کریں',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Toggle
                Expanded(
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: status == 'active'
                              ? [Colors.orange, Colors.orange.shade700]
                              : [
                                  const Color(0xFF0F3D1A),
                                  AppTheme.primaryGreen
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == 'active'
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status == 'active' ? 'غیر فعال کریں' : 'فعال کریں',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
      child: const Icon(Icons.grass, color: AppTheme.primaryGreen, size: 44),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color = AppTheme.textGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            height: 1.4,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 12, color: color),
      ],
    );
  }
}
