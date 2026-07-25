import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'farmer',
      'title': 'کسان',
      'description': 'اپنی فصلیں پوسٹ کریں، بہترین قیمت حاصل کریں',
      'image': 'assets/images/farmer.png',
      'color': Color(0xFF2E7D32),
    },
    {
      'role': 'arhti',
      'title': 'آڑھتی',
      'description': 'فصلیں خریدیں اور کسانوں سے رابطہ کریں',
      'image': 'assets/images/arhti.png',
      'color': Color(0xFF1565C0),
    },
    {
      'role': 'dealer',
      'title': 'ڈیلر / کمپنی',
      'description': 'زرعی مصنوعات فروخت کریں اور کسانوں تک پہنچیں',
      'image': 'assets/images/dealer.png',
      'color': Color(0xFF6A1B9A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Banner
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF0F7F0),
                          Color(0xFFFFFFFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: AppTheme.textDark),
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                          // Logo Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(5),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'کسان دوست',
                                style: TextStyle(
                                  fontFamily: 'Nastaleeq',
                                  fontSize: 22,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  height: 1.8,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Hero Image
                          Image.asset(
                            'assets/images/role_selection_banner.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),

                          // Title
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Text(
                                  'اپنا کردار منتخب کریں',
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
                                SizedBox(height: 4),
                                Text(
                                  'اپنے مطابق کردار منتخب کریں اور کسان دوست کے ساتھ جڑیں',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textGrey,
                                    height: 1.6,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Role Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _roles.map((role) {
                        final isSelected = _selectedRole == role['role'];
                        return _RoleCard(
                          role: role,
                          isSelected: isSelected,
                          onTap: () => setState(
                              () => _selectedRole = role['role'] as String),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  // Privacy note
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'آپ کا ڈیٹا محفوظ اور خفیہ رکھا جائے گا',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.shield_outlined,
                          color: AppTheme.primaryGreen,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedRole != null ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.darkGreen,
                            AppTheme.primaryGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow:
                            _selectedRole != null ? AppTheme.buttonShadow : [],
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedRole == null
                            ? null
                            : () async {
                                await context
                                    .read<AuthViewModel>()
                                    .setUserRole(_selectedRole!);

                                if (!context.mounted) return;

                                //   Route based on role
                                if (_selectedRole == 'farmer') {
                                  context.go('/profile-setup');
                                } else {
                                  // dealer or arhti → business setup
                                  context.go('/business-setup');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'جاری رکھیں',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = role['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Person Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(
                width: 100,
                height: 100,
                child: Image.asset(
                  role['image'] as String,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    child: Icon(
                      Icons.person,
                      color: color,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          role['title'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : AppTheme.textDark,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? color : AppTheme.borderLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check : Icons.arrow_back_ios_new,
                            color:
                                isSelected ? Colors.white : AppTheme.textGrey,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
