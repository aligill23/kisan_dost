import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/announcement_service.dart';

class AnnouncementPopup {
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      debugPrint('🔔 AnnouncementPopup: showIfNeeded called');

      final model = await AnnouncementService.getActive();

      debugPrint('🔔 Model returned: ${model != null ? "YES" : "NULL"}');

      if (model == null) {
        debugPrint('❌ Model is null — not showing');
        return;
      }

      // ✅ SharedPrefs check
      final prefs = await SharedPreferences.getInstance();
      final key = 'ann_${model.imageUrl.hashCode}';
      final lastShown = prefs.getString(key) ?? '';
      final today = DateTime.now().toIso8601String().substring(0, 10);

      debugPrint('🔔 Key: $key');
      debugPrint('🔔 Last shown: $lastShown');
      debugPrint('🔔 Today: $today');

      // ✅ TEMPORARILY remove cache check
      // Har baar show karo debug ke liye
      // if (lastShown == today) {
      //   debugPrint('❌ Already shown today');
      //   return;
      // }

      await prefs.setString(key, today);

      debugPrint('✅ Showing popup now!');

      if (!context.mounted) {
        debugPrint('❌ Context not mounted!');
        return;
      }

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'close',
        barrierColor: Colors.black.withValues(alpha: 0.75),
        transitionDuration: const Duration(milliseconds: 350),
        transitionBuilder: (ctx, anim, _, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          );
        },
        pageBuilder: (ctx, _, __) => _ImagePopup(model: model),
      );
    } catch (e) {
      debugPrint('❌ AnnouncementPopup ERROR: $e');
    }
  }
}

class _ImagePopup extends StatelessWidget {
  final AnnouncementModel model;
  const _ImagePopup({required this.model});

  @override
  Widget build(BuildContext context) {
    debugPrint('🖼️ Building popup widget');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: model.imageUrl,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width - 56,
                  placeholder: (_, __) => AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) {
                    debugPrint('❌ Image load failed!');
                    return AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
