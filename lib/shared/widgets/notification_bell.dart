// lib/shared/widgets/notification_bell.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;
  final double size;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.size = 22,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  String _userId = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shake = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.15),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.15, end: -0.15),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.15, end: 0.1),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _shakeCtrl,
      curve: Curves.easeInOut,
    ));
    _loadUserId();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userId = prefs.getString('userId') ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return _buildBell(context, 0);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        // Shake on new notification
        if (count > _prevCount && _prevCount != 0) {
          _shakeCtrl.forward(from: 0);
        }
        _prevCount = count;

        return _buildBell(context, count);
      },
    );
  }

  Widget _buildBell(BuildContext context, int count) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.rotate(
        angle: _shake.value,
        child: child,
      ),
      child: GestureDetector(
        //   GoRouter — works with your setup
        onTap: () => context.push('/notifications'),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  count > 0
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  color: widget.iconColor,
                  size: widget.size,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: count > 9 ? 4 : 0,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
