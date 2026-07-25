import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/pakistan_locations.dart';

class LocationDropdowns extends StatefulWidget {
  final Function(String province, String district, String tehsil) onChanged;
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialTehsil;

  const LocationDropdowns({
    super.key,
    required this.onChanged,
    this.initialProvince,
    this.initialDistrict,
    this.initialTehsil,
  });

  @override
  State<LocationDropdowns> createState() => _LocationDropdownsState();
}

class _LocationDropdownsState extends State<LocationDropdowns> {
  String? _province;
  String? _district;
  String? _tehsil;

  List<String> _districts = [];
  List<String> _tehsils = [];

  @override
  @override
  void initState() {
    super.initState();

    if (widget.initialProvince != null && widget.initialProvince!.isNotEmpty) {
      final districts = PakistanLocations.getDistricts(widget.initialProvince!);
      if (PakistanLocations.provinces.keys.contains(widget.initialProvince)) {
        _province = widget.initialProvince;
        _districts = districts;
      }
    }

    if (widget.initialDistrict != null &&
        widget.initialDistrict!.isNotEmpty &&
        _districts.contains(widget.initialDistrict)) {
      _district = widget.initialDistrict;
      _tehsils = PakistanLocations.getTehsils(_district!);
    }

    if (widget.initialTehsil != null &&
        widget.initialTehsil!.isNotEmpty &&
        _tehsils.contains(widget.initialTehsil)) {
      _tehsil = widget.initialTehsil;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('صوبہ'),
        const SizedBox(height: 8),
        _buildDropdown(
          hint: 'صوبہ منتخب کریں',
          value: _province,
          items: PakistanLocations.provinces.keys.toList(),
          onChanged: (val) {
            setState(() {
              _province = val;
              _district = null;
              _tehsil = null;
              _districts = PakistanLocations.getDistricts(val!);
              _tehsils = [];
            });
            _notify();
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('ضلع'),
        const SizedBox(height: 8),
        _buildDropdown(
          hint: 'ضلع منتخب کریں',
          value: _district,
          items: _districts,
          onChanged: _province == null
              ? null
              : (val) {
                  setState(() {
                    _district = val;
                    _tehsil = null;
                    _tehsils = PakistanLocations.getTehsils(val!);
                  });
                  _notify();
                },
        ),
        const SizedBox(height: 16),
        _buildLabel('تحصیل'),
        const SizedBox(height: 8),
        _buildDropdown(
          hint: 'تحصیل منتخب کریں',
          value: _tehsil,
          items: _tehsils,
          onChanged: _district == null
              ? null
              : (val) {
                  setState(() => _tehsil = val);
                  _notify();
                },
        ),
      ],
    );
  }

  void _notify() {
    widget.onChanged(
      _province ?? '',
      _district ?? '',
      _tehsil ?? '',
    );
  }

  Widget _buildLabel(String text) {
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onChanged == null
            ? AppTheme.borderLight.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: AppTheme.textGrey,
              fontSize: 15,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
