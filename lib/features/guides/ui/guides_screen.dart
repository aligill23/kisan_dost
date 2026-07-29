import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:kisan_dost/features/guides/ui/guide_detail_screen.dart';
import 'widgets/guide_search_bar.dart';
import 'widgets/crop_guide_card.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'تمام';

  static const List<String> _categories = [
    'تمام',
    'ربیع',
    'خریف',
    'سبزیاں',
    'چارہ',
  ];

  static const List<Map<String, dynamic>> _guides = [
    {
      'title': 'گندم',
      'subtitle': 'کاشت سے کٹائی تک مکمل رہنمائی',
      'season': 'ربیع',
      'readingMinutes': 8,
      'category': 'ربیع',
      'sections': [
        {
          'title': '🌱 زمین کی تیاری',
          'points': [
            'زمین کو دو سے تین بار ہل چلائیں',
            'آخری ہل سے پہلے کھاد ملائیں',
            'زمین ہموار اور بھربھری ہونی چاہیے',
            'پچھلی فصل کی جڑیں نکال دیں',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'پہلا پانی بوائی کے فوری بعد',
            'دوسرا پانی 3 ہفتے بعد',
            'پھول آنے پر پانی ضروری ہے',
            'کٹائی سے 2 ہفتے پہلے پانی بند کریں',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 2 بوری فی ایکڑ',
            'DAP: 1 بوری فی ایکڑ بوائی پر',
            'پوٹاش زمین کے مطابق',
            'پتوں پر سپرے بھی فائدہ مند',
          ],
        },
        {
          'title': '🐛 بیماریاں اور علاج',
          'points': [
            'زنگ کے لیے فنگس سائیڈ سپرے',
            'سنڈی کے لیے کلوروپائریفاس',
            'پیلے رنگ کی بیماری: زنک سپرے',
            'ماہر سے مشورہ ضروری ہے',
          ],
        },
        {
          'title': '✂ کٹائی',
          'points': [
            'گندم پکنے پر سنہری رنگ ہو جاتی ہے',
            'مشین سے کٹائی بہترین ہے',
            'کٹائی کے بعد فوری سکھائیں',
            'نمی 12 فیصد سے کم ہونی چاہیے',
          ],
        },
      ],
    },
    {
      'title': 'دھان',
      'subtitle': 'پنیری سے گاہی تک مکمل رہنمائی',
      'season': 'خریف',
      'readingMinutes': 10,
      'category': 'خریف',
      'sections': [
        {
          'title': '🌱 پنیری تیاری',
          'points': [
            'بیج کو 24 گھنٹے پانی میں بھگوئیں',
            'پنیری کے لیے الگ کیاری بنائیں',
            'ایک ماہ میں پنیری تیار ہوتی ہے',
            'پنیری 20 سے 25 سینٹی میٹر ہو',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'کھیت میں ہر وقت پانی رکھیں',
            'کٹائی سے 2 ہفتے پہلے پانی بند',
            'پانی کی کمی پیداوار کم کرتی ہے',
            'نہری پانی بہترین ہے',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 3 بوری فی ایکڑ',
            'DAP: 1 بوری بوائی پر',
            'زنک سلفیٹ ضرور ڈالیں',
            'کھاد تین حصوں میں ڈالیں',
          ],
        },
        {
          'title': '🐛 بیماریاں',
          'points': [
            'بلاسٹ بیماری سے بچاؤ',
            'تنے کی سنڈی: فیپرونل سپرے',
            'بھورا پودا: کیڑے مار دوا',
            'ماہر زراعت سے رابطہ کریں',
          ],
        },
      ],
    },
    {
      'title': 'کپاس',
      'subtitle': 'سفید سونے کی کاشت کی مکمل رہنمائی',
      'season': 'خریف',
      'readingMinutes': 12,
      'category': 'خریف',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'اپریل سے مئی بوائی کا بہترین وقت',
            'قطار سے قطار 75 سینٹی میٹر',
            'بیج کو فنگس سائیڈ لگائیں',
            'زمین میں نمی ہونی چاہیے',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'پہلا پانی بوائی کے 3 ہفتے بعد',
            'گرمی میں 10 دن بعد پانی',
            'پھول پر پانی بہت ضروری',
            'کل 6 سے 8 پانی کافی ہیں',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 3 بوری فی ایکڑ',
            'پوٹاش پیداوار بڑھاتی ہے',
            'بور آنے پر فولیئر سپرے',
            'زیادہ یوریا نقصاندہ ہے',
          ],
        },
        {
          'title': '🐛 سنڈی کا علاج',
          'points': [
            'امریکن سنڈی سب سے خطرناک',
            'ہفتہ وار پھیروموں ٹریپ چیک کریں',
            'حیاتیاتی کنٹرول بہترین ہے',
            'سپرے صبح یا شام کریں',
          ],
        },
      ],
    },
    {
      'title': 'گنا',
      'subtitle': 'میٹھی فصل کی کاشت اور نگہداشت',
      'season': 'خریف',
      'readingMinutes': 9,
      'category': 'خریف',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'فروری سے مارچ بہترین وقت',
            'آنکھوں والے ٹکڑے لگائیں',
            'قطاروں میں 90 سینٹی میٹر فاصلہ',
            'ایک ایکڑ کے لیے 40 من بیج',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'ابتدا میں 15 دن بعد پانی',
            'گرمی میں 7 دن بعد پانی',
            'کل 20 سے 25 پانی درکار',
            'بارش میں پانی بند کریں',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 4 بوری فی ایکڑ',
            'DAP: 2 بوری بوائی پر',
            'پوٹاش: 1 بوری',
            'تین مرحلوں میں کھاد دیں',
          ],
        },
      ],
    },
    {
      'title': 'مکئی',
      'subtitle': 'ربیع اور خریف دونوں موسم کی فصل',
      'season': 'خریف',
      'readingMinutes': 7,
      'category': 'خریف',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'فروری یا جولائی میں بوائی',
            'قطار سے قطار 75 سینٹی میٹر',
            'بیج سے بیج 20 سینٹی میٹر',
            'ہائبرڈ بیج زیادہ پیداوار دیتا ہے',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'بوائی کے وقت نمی ضروری',
            'پھول آنے پر پانی نہ چھوڑیں',
            'کل 5 سے 7 پانی کافی',
            'زیادہ پانی نقصاندہ ہے',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 2 بوری فی ایکڑ',
            'DAP: 1 بوری',
            'زنک سلفیٹ فائدہ مند',
            'دو مرحلوں میں کھاد دیں',
          ],
        },
      ],
    },
    {
      'title': 'سرسوں',
      'subtitle': 'تیل والی فصل کی مکمل رہنمائی',
      'season': 'ربیع',
      'readingMinutes': 6,
      'category': 'ربیع',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'اکتوبر میں بوائی بہترین ہے',
            'قطار سے قطار 45 سینٹی میٹر',
            'بیج کی مقدار: 2 کلو فی ایکڑ',
            'زمین میں نمی ضروری',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'کل 3 سے 4 پانی کافی',
            'پھول آنے پر پانی ضروری',
            'کٹائی سے قبل پانی بند',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 1.5 بوری فی ایکڑ',
            'DAP: 1 بوری بوائی پر',
            'گندھک پیداوار بڑھاتی ہے',
          ],
        },
      ],
    },
    {
      'title': 'آلو',
      'subtitle': 'سبزیوں کے بادشاہ کی کاشت',
      'season': 'ربیع',
      'readingMinutes': 8,
      'category': 'سبزیاں',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'اکتوبر سے نومبر بوائی کا وقت',
            'بیج آلو چھوٹے اور صحت مند ہوں',
            'قطار سے قطار 60 سینٹی میٹر',
            'بیج کو پھپھوند کش لگائیں',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'پہلا پانی بوائی کے فوری بعد',
            'ہر 10 سے 12 دن بعد پانی',
            'کٹائی سے 2 ہفتے پہلے پانی بند',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 2 بوری فی ایکڑ',
            'DAP: 2 بوری بوائی پر',
            'پوٹاش: 1 بوری',
          ],
        },
      ],
    },
    {
      'title': 'ٹماٹر',
      'subtitle': 'تازہ سبزی کی کامیاب کاشت',
      'season': 'خریف',
      'readingMinutes': 7,
      'category': 'سبزیاں',
      'sections': [
        {
          'title': '🌱 پنیری اور بوائی',
          'points': [
            'پنیری نرسری میں تیار کریں',
            'پنیری 6 ہفتے میں تیار ہوتی ہے',
            'قطار سے قطار 60 سینٹی میٹر',
            'شام کے وقت پنیری لگائیں',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'گرمی میں 5 دن بعد پانی',
            'پھل آنے پر باقاعدہ پانی',
            'پانی کی کمی پھل کو متاثر کرتی ہے',
          ],
        },
        {
          'title': '🐛 بیماریاں',
          'points': [
            'بلائٹ بیماری سے بچاؤ',
            'سفید مکھی کنٹرول ضروری',
            'کیڑے مار دوا سپرے کریں',
          ],
        },
      ],
    },
    {
      'title': 'پیاز',
      'subtitle': 'قیمتی نقد آور فصل کی رہنمائی',
      'season': 'ربیع',
      'readingMinutes': 7,
      'category': 'سبزیاں',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'اکتوبر سے نومبر بوائی',
            'پنیری سے کاشت بہتر ہے',
            'قطار سے قطار 15 سینٹی میٹر',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'کل 8 سے 10 پانی درکار',
            'پتے گرنے پر پانی بند کریں',
            'زیادہ پانی نقصاندہ',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 1.5 بوری فی ایکڑ',
            'DAP: 1 بوری',
            'پوٹاش: پیاز کا سائز بڑا کرتی ہے',
          ],
        },
      ],
    },
    {
      'title': 'چارہ',
      'subtitle': 'جانوروں کے لیے سبز چارے کی کاشت',
      'season': 'ربیع',
      'readingMinutes': 5,
      'category': 'چارہ',
      'sections': [
        {
          'title': '🌱 بوائی',
          'points': [
            'ستمبر سے اکتوبر بہترین وقت',
            'برسیم یا جوار چارے کے لیے موزوں',
            'زمین میں نمی ضروری',
          ],
        },
        {
          'title': '💧 آبپاشی',
          'points': [
            'باقاعدہ پانی پیداوار بڑھاتا ہے',
            'ہر کٹائی کے بعد پانی دیں',
          ],
        },
        {
          'title': '🧪 کھاد',
          'points': [
            'یوریا: 1 بوری فی ایکڑ',
            'DAP: 1 بوری',
            'کھاد کٹائی کے بعد دیں',
          ],
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredGuides {
    return _guides.where((g) {
      final matchesSearch = _searchQuery.isEmpty ||
          (g['title'] as String).contains(_searchQuery) ||
          (g['subtitle'] as String).contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == 'تمام' || g['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────
          _PremiumHeader(),

          // ── Scrollable content ──────────────────────────────────
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Search bar
                GuideSearchBar(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),

                // Category chips
                _CategoryChips(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelected: (c) => setState(() => _selectedCategory = c),
                ),
                const SizedBox(height: 16),

                // Crop count label
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    '${_filteredGuides.length} فصلیں دستیاب ہیں',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Guide cards
                ..._filteredGuides.map(
                  (guide) => CropGuideCard(
                    guide: guide,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuideDetailScreen(guide: guide),
                      ),
                    ),
                  ),
                ),

                if (_filteredGuides.isEmpty) _EmptyState(query: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Premium header (replaces AppBar) ─────────────────────────────────────────
class _PremiumHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search hint icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فصلوں کی رہنمائی',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'محکمہ زراعت پنجاب کی جدید سفارشات',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Back button (only show when there is a route to pop)
              Builder(builder: (ctx) {
                if (!Navigator.canPop(ctx)) return const SizedBox(width: 40);
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL feel
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF2E7D32).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF2E7D32),
                  height: 1.3,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'کوئی فصل نہیں ملی',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          if (query.isNotEmpty)
            Text(
              '"$query" کے لیے کوئی نتیجہ نہیں',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
        ],
      ),
    );
  }
}
