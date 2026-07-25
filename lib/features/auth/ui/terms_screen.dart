import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_hasScrolledToBottom) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= maxScroll - 100) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'براہ کرم شرائط و ضوابط سے اتفاق کریں',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);
    setState(() => _isLoading = false);

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F3D1A), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'شرائط و ضوابط',
                      style: TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'کسان دوست ایپ استعمال کرنے سے پہلے براہ کرم یہ شرائط پڑھیں',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  _TermsSection(
                    number: '۱',
                    title: 'قبولیت کی شرائط',
                    content:
                        'کسان دوست ایپ استعمال کرکے، آپ ان شرائط و ضوابط سے اتفاق کرتے ہیں۔ اگر آپ ان شرائط سے متفق نہیں ہیں، تو براہ کرم ایپ استعمال نہ کریں۔ یہ شرائط وقتاً فوقتاً تبدیل ہوسکتی ہیں اور تبدیلیاں فوری طور پر نافذ ہوں گی۔',
                  ),
                  _TermsSection(
                    number: '۲',
                    title: 'خدمات کا دائرہ کار',
                    content:
                        'کسان دوست ایپ پاکستانی کسانوں، آڑھتیوں اور زرعی ڈیلروں کے لیے ایک ڈیجیٹل پلیٹ فارم ہے جہاں:\n\n• کسان اپنی فصلیں پوسٹ کر سکتے ہیں\n• آڑھتی فصلیں خرید سکتے ہیں\n• ڈیلر زرعی مصنوعات فروخت کر سکتے ہیں\n• منڈی ریٹس دیکھی جا سکتی ہیں\n• زراعت سے متعلق رہنمائی حاصل کی جا سکتی ہے',
                  ),
                  _TermsSection(
                    number: '۳',
                    title: 'رجسٹریشن اور اکاؤنٹ',
                    content:
                        'ایپ استعمال کرنے کے لیے آپ کو اپنا موبائل نمبر اور درست معلومات فراہم کرنا ضروری ہے۔ آپ اپنے اکاؤنٹ کی سیکیورٹی کے ذمہ دار ہیں۔ کسی بھی غیر مجاز استعمال کی فوری اطلاع دی جائے۔ جھوٹی یا غلط معلومات فراہم کرنا سختی سے منع ہے۔',
                  ),
                  _TermsSection(
                    number: '۴',
                    title: 'سبسکرپشن اور ادائیگی',
                    content:
                        'آڑھتی اور ڈیلر کے لیے سبسکرپشن پلان دستیاب ہیں:\n\n• سٹینڈرڈ پلان: 2000 روپے ماہانہ\n• فیچرڈ پلان: 5000 روپے ماہانہ\n\nادائیگی JazzCash، EasyPaisa یا بینک ٹرانسفر کے ذریعے کی جا سکتی ہے۔ ادائیگی کی تصدیق کے بعد سبسکرپشن فعال ہوگی۔ ادائیگی واپس نہیں ہوگی سوائے خاص حالات کے۔',
                  ),
                  _TermsSection(
                    number: '۵',
                    title: 'ممنوعہ سرگرمیاں',
                    content:
                        'درج ذیل سرگرمیاں سختی سے منع ہیں:\n\n• جھوٹی یا گمراہ کن معلومات پوسٹ کرنا\n• دوسرے صارفین کو ہراساں کرنا\n• غیر قانونی مصنوعات یا خدمات کی پیشکش\n• ایپ کے نظام کو نقصان پہنچانا\n• دوسروں کی ذاتی معلومات کا غلط استعمال\n• فرضی اکاؤنٹ بنانا\n• منڈی ریٹس میں ہیرا پھیری',
                  ),
                  _TermsSection(
                    number: '۶',
                    title: 'ذاتی معلومات اور رازداری',
                    content:
                        'آپ کی ذاتی معلومات محفوظ رکھی جائیں گی۔ ہم آپ کا موبائل نمبر، نام، ضلع اور کاروباری معلومات جمع کرتے ہیں۔ یہ معلومات صرف ایپ کی خدمات بہتر بنانے کے لیے استعمال ہوتی ہیں۔ آپ کی اجازت کے بغیر تیسرے فریق کو نہیں دی جائیں گی سوائے قانونی تقاضوں کے۔',
                  ),
                  _TermsSection(
                    number: '۷',
                    title: 'مواد کی ذمہ داری',
                    content:
                        'ایپ پر پوسٹ کردہ تمام مواد کی ذمہ داری پوسٹ کرنے والے کی ہے۔ کسان دوست اس بات کا یقین دلاتا ہے کہ:\n\n• فصل کی قیمتیں درست ہوں\n• پروڈکٹ کی معلومات صحیح ہو\n• تصاویر اصل مصنوعات کی ہوں\n\nغلط معلومات پوسٹ کرنے پر اکاؤنٹ بند کیا جا سکتا ہے۔',
                  ),
                  _TermsSection(
                    number: '۸',
                    title: 'لین دین کی ذمہ داری',
                    content:
                        'کسان دوست صرف ایک پلیٹ فارم ہے۔ کسانوں، آڑھتیوں اور ڈیلروں کے درمیان لین دین کی ذمہ داری متعلقہ فریقوں کی ہے۔ خرید و فروخت میں کسی بھی تنازعے کی صورت میں کسان دوست ثالثی کی کوشش کرے گا لیکن قانونی ذمہ داری نہیں لیتا۔',
                  ),
                  _TermsSection(
                    number: '۹',
                    title: 'خدمات کا معطل ہونا',
                    content:
                        'کسان دوست حق محفوظ رکھتا ہے کہ:\n\n• کسی بھی وقت خدمات معطل کرے\n• قوانین کی خلاف ورزی پر اکاؤنٹ بند کرے\n• سبسکرپشن کا حق مسترد کرے\n• ایپ میں بغیر اطلاع تبدیلیاں کرے',
                  ),
                  _TermsSection(
                    number: '۱۰',
                    title: 'قانون اور دائرہ اختیار',
                    content:
                        'یہ شرائط و ضوابط پاکستانی قانون کے تحت ہیں۔ کسی بھی تنازعے کی صورت میں پاکستانی عدالتوں کا دائرہ اختیار ہوگا۔ ہماری خدمات پاکستان کے اندر دستیاب ہیں۔',
                  ),
                  _TermsSection(
                    number: '۱۱',
                    title: 'رابطہ کریں',
                    content:
                        'کسی بھی سوال یا شکایت کے لیے ہم سے رابطہ کریں:\n\nای میل: support@kisandost.pk\nواٹس ایپ: 0326-6621834\n\nہم 24 گھنٹوں میں جواب دینے کی کوشش کریں گے۔',
                  ),

                  const SizedBox(height: 20),

                  // Scroll hint
                  if (!_hasScrolledToBottom)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'شرائط پڑھنے کے لیے نیچے سکرول کریں',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.keyboard_arrow_down,
                              color: AppTheme.primaryGreen, size: 18),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Agreement Checkbox
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _agreed
                            ? AppTheme.primaryGreen.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _agreed
                              ? AppTheme.primaryGreen
                              : AppTheme.borderLight,
                          width: _agreed ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _agreed
                                  ? AppTheme.primaryGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _agreed
                                    ? AppTheme.primaryGreen
                                    : AppTheme.borderLight,
                                width: 1.5,
                              ),
                            ),
                            child: _agreed
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'میں نے تمام شرائط و ضوابط پڑھ لی ہیں اور میں ان سے متفق ہوں',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: _agreed ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _agreed
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF0F3D1A),
                                  AppTheme.primaryGreen
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade400,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _agreed ? AppTheme.buttonShadow : [],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'قبول کریں اور جاری رکھیں',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nastaleeq',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'Nastaleeq',
                fontSize: 15,
                color: AppTheme.textMedium,
                height: 2.0,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
