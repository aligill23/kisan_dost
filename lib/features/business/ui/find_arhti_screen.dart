import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import 'business_page_screen.dart';

class FindArhtiScreen extends StatefulWidget {
  const FindArhtiScreen({super.key});

  @override
  State<FindArhtiScreen> createState() => _FindArhtiScreenState();
}

class _FindArhtiScreenState extends State<FindArhtiScreen> {
  String _searchQuery = '';
  String _selectedDistrict = 'سب';
  String _selectedCrop = 'سب';
  bool _verifiedOnly = false;

  final List<String> _crops = [
    'سب',
    'گندم',
    'چاول',
    'کپاس',
    'گنا',
    'مکئی',
    'دیگر',
  ];

  final List<String> _districts = [
    'سب',
    'پاکپتن',
    'ساہیوال',
    'فیصل آباد',
    'لاہور',
    'ملتان',
    'گوجرانوالہ',
    'شیخوپورہ',
    'سیالکوٹ',
    'بہاولپور',
    'رحیم یار خان',
    'ڈیرہ غازی خان',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF3E2000),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3E2000),
                      Color(0xFFE65100),
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
                          'آڑھتی تلاش کریں',
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
                          'اپنے علاقے کے آڑھتی تلاش کریں',
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

          // ── Search + Filters ───────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'آڑھت کا نام تلاش کریں',
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFE65100),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // District Filter
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: 'ضلع',
                          value: _selectedDistrict,
                          items: _districts,
                          color: const Color(0xFFE65100),
                          onChanged: (val) =>
                              setState(() => _selectedDistrict = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'فصل',
                          value: _selectedCrop,
                          items: _crops,
                          color: const Color(0xFFE65100),
                          onChanged: (val) =>
                              setState(() => _selectedCrop = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Verified Toggle
                  GestureDetector(
                    onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _verifiedOnly
                            ? Colors.lightBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _verifiedOnly
                              ? Colors.lightBlue
                              : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'صرف تصدیق شدہ آڑھتی',
                            style: TextStyle(
                              fontSize: 13,
                              color: _verifiedOnly
                                  ? Colors.lightBlue
                                  : AppTheme.textGrey,
                              fontWeight: _verifiedOnly
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _verifiedOnly
                                ? Icons.verified
                                : Icons.verified_outlined,
                            color: _verifiedOnly
                                ? Colors.lightBlue
                                : AppTheme.textGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Arhti List ─────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'arhti')
                .where('businessName', isNotEqualTo: '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE65100),
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

              // Search filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                      (data['businessName'] ?? '').toString().toLowerCase();
                  final owner =
                      (data['ownerName'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      owner.contains(_searchQuery);
                }).toList();
              }

              // District filter
              if (_selectedDistrict != 'سب') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['district'] == _selectedDistrict;
                }).toList();
              }

              // Crop filter
              if (_selectedCrop != 'سب') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final cats = List<String>.from(data['categories'] ?? []);
                  return cats.contains(_selectedCrop);
                }).toList();
              }

              // Verified filter
              if (_verifiedOnly) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['verified'] == true;
                }).toList();
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
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      return _ArhtiCard(
                        data: data,
                        userId: id,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessPageScreen(
                              userId: id,
                            ),
                          ),
                        ),
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
              color: const Color(0xFFE65100).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              size: 50,
              color: const Color(0xFFE65100).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'کوئی آڑھتی نہیں ملا',
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
            'مختلف فلٹر آزمائیں',
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

// ── Arhti Card ────────────────────────────────────
class _ArhtiCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onTap;

  const _ArhtiCard({
    required this.data,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final businessName = data['businessName'] ?? '';
    final ownerName = data['ownerName'] ?? data['name'] ?? '';
    final logoUrl = data['logoUrl'] ?? data['profileImage'] ?? '';
    final district = data['district'] ?? '';
    final description = data['description'] ?? '';
    final categories = List<String>.from(data['categories'] ?? []);
    final years = data['yearsInBusiness'] ?? 0;
    final verified = data['verified'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE65100).withValues(alpha: 0.12),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Name + verified
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              businessName,
                              style: const TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            if (verified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.lightBlue,
                                size: 16,
                              ),
                            ],
                          ],
                        ),

                        // Owner
                        Text(
                          ownerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),

                        // Badges row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // District badge
                            if (district.isNotEmpty)
                              _Badge(
                                icon: Icons.location_on_outlined,
                                text: district,
                                color: const Color(0xFFE65100),
                              ),
                            const SizedBox(width: 6),

                            // Years badge
                            if (years > 0)
                              _Badge(
                                icon: Icons.calendar_today_outlined,
                                text: '$years سال',
                                color: AppTheme.primaryGreen,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE65100).withValues(alpha: 0.1),
                      border: Border.all(
                        color: const Color(0xFFE65100).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.business,
                                color: Color(0xFFE65100),
                                size: 32,
                              ),
                            )
                          : const Icon(
                              Icons.business,
                              color: Color(0xFFE65100),
                              size: 32,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Card Body ────────────────────────
            if (description.isNotEmpty || categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Description
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description.length > 80
                            ? '${description.substring(0, 80)}...'
                            : description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ],

                    // Categories
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: categories
                            .take(4)
                            .map((cat) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryGreen,
                                      height: 1.4,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

            // ── View Profile Button ───────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE65100).withValues(alpha: 0.1),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'پروفائل دیکھیں',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFE65100),
                    size: 12,
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

// ── Filter Dropdown ───────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Color color;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: color),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        color: item == value ? color : AppTheme.textDark,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

// ── Badge Widget ──────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 3),
          Icon(icon, size: 11, color: color),
        ],
      ),
    );
  }
}
