import 'package:flutter/material.dart';

class GuideSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const GuideSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A1A),
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'فصل تلاش کریں...',
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade400,
            height: 1.5,
          ),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF2E7D32),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
