import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/pakistan_locations.dart';
import '../../../features/auth/viewmodels/profile_viewmodel.dart';
import '../../../shared/widgets/location_dropdown.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  File? _newProfileImage;
  final ImagePicker _picker = ImagePicker();

  String _province = '';
  String _district = '';
  String _tehsil = '';
  bool _initialized = false;

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _newProfileImage = File(picked.path));

      // Upload immediately
      if (!mounted) return;
      final vm = context.read<ProfileViewModel>();
      final url = await vm.uploadProfileImageAndGetUrl(File(picked.path));

      if (!mounted) return;
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vm.errorMessage ?? 'تصویر اپ لوڈ نہیں ہو سکی',
              textDirection: TextDirection.rtl,
            ),
          ), // Text
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<ProfileViewModel>().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _businessNameController.text = user.shopName;
        _addressController.text = user.address;
        _villageController.text = user.village;
        _province = user.province;
        _district = user.district;
        _tehsil = user.tehsil;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام درج کریں', textDirection: TextDirection.rtl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vm = context.read<ProfileViewModel>();
    final user = vm.currentUser;

    //   CRITICAL FIX -Get role from SharedPreferences
    // Never trust user?.role -it might be null!
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? user?.role ?? '';

    //   NEVER save role if it's empty
    if (role.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('خرابی: کردار نہیں ملا', textDirection: TextDirection.rtl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'role': role, // ← Now safe -from SharedPrefs
      'province': _province,
      'district': _district,
      'tehsil': _tehsil,
    };

    if (role == 'farmer') {
      data['village'] = _villageController.text.trim();
    } else if (role == 'arhti') {
      data['shopName'] = _businessNameController.text.trim();
      data['marketAddress'] = _addressController.text.trim();
    } else if (role == 'dealer') {
      data['businessName'] = _businessNameController.text.trim();
      data['shopAddress'] = _addressController.text.trim();
    }

    final success = await vm.saveProfile(data);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'پروفائل اپ ڈیٹ ہو گئی',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'خرابی ہوئی',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.currentUser;
    final role = user?.role ?? 'farmer';

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text(
          'پروفائل ترمیم کریں',
          style: TextStyle(fontSize: 20, height: 1.5),
          textDirection: TextDirection.rtl,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: vm.isUploadingImage ? null : _pickProfileImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          image: _newProfileImage != null
                              ? DecorationImage(
                                  image: FileImage(_newProfileImage!),
                                  fit: BoxFit.cover,
                                )
                              : (user?.profileImage != null &&
                                      user!.profileImage!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(user.profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_newProfileImage == null &&
                                (user?.profileImage == null ||
                                    user!.profileImage!.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 44,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      if (vm.isUploadingImage)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: vm.imageUploadProgress > 0
                                ? vm.imageUploadProgress
                                : null,
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            backgroundColor: Colors.black26,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: vm.isUploadingImage ? null : _pickProfileImage,
                  child: Text(
                    vm.isUploadingImage
                        ? 'اپ لوڈ ہو رہا ہے...'
                        : 'تصویر تبدیل کریں',
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              _label('آپ کا نام'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(hintText: 'پورا نام'),
              ),
              const SizedBox(height: 16),

              // Role specific
              if (role == 'arhti') ...[
                _label('دکان کا نام'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _businessNameController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                  decoration:
                      const InputDecoration(hintText: 'دکان / فرم کا نام'),
                ),
                const SizedBox(height: 16),
              ],

              if (role == 'dealer') ...[
                _label('کاروبار کا نام'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _businessNameController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'کاروبار کا نام'),
                ),
                const SizedBox(height: 16),
              ],

              // Location
              LocationDropdowns(
                onChanged: (p, d, t) {
                  setState(() {
                    _province = p;
                    _district = d;
                    _tehsil = t;
                  });
                },
                initialProvince: _province,
                initialDistrict: _district,
                initialTehsil: _tehsil,
              ),
              const SizedBox(height: 16),

              // Village
              if (role == 'farmer') ...[
                _label('گاؤں کا نام (اختیاری)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _villageController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'گاؤں یا محلہ'),
                ),
                const SizedBox(height: 16),
              ],

              // Address
              if (role == 'arhti' || role == 'dealer') ...[
                _label(role == 'arhti' ? 'منڈی پتہ' : 'دکان کا پتہ'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(hintText: 'مکمل پتہ'),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'محفوظ کریں',
                        style: TextStyle(fontSize: 20, height: 1.5),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
        height: 1.5,
      ),
      textDirection: TextDirection.rtl,
    );
  }
}
