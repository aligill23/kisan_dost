// lib/features/notifications/ui/notification_screen.dart
//
// DESIGN: WhatsApp-style grouped notification list
// Groups shown as expandable sections
// Each group has unread badge
// Tap on notification → deep link navigation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_model.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'ابھی';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} منٹ پہلے';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} گھنٹے پہلے';
    }
    if (diff.inDays == 1) return 'کل';
    if (diff.inDays < 7) {
      return '${diff.inDays} دن پہلے';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _onTapNotification(
    BuildContext ctx,
    NotificationModel n,
    NotificationViewModel vm,
  ) {
    vm.markAsRead(n.notificationId);
    if (n.deepLink.isNotEmpty) {
      Navigator.of(ctx).pushNamed(n.deepLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: const Color(0xFF0F3D1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (vm.unreadCount > 0)
                TextButton(
                  onPressed: vm.markAllAsRead,
                  child: const Text(
                    'سب پڑھے',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F3D1A),
                      Color(0xFF1B5E20),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'اطلاعات',
                              style: TextStyle(
                                fontFamily: 'Nastaleeq',
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            if (vm.unreadCount > 0)
                              Text(
                                '${vm.unreadCount} نئی اطلاعات',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Group Filter Chips ───────────────
          if (vm.activeGroups.length > 1)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      // "All" chip
                      _GroupChip(
                        label: 'سب',
                        isSelected: vm.activeGroupFilter == null,
                        count: vm.unreadCount,
                        color: AppTheme.primaryGreen,
                        onTap: vm.clearFilter,
                      ),
                      ...vm.activeGroups.map((g) {
                        final count = vm.unreadPerGroup[g] ?? 0;
                        return _GroupChip(
                          label: NotificationModel.labelFor(g),
                          isSelected: vm.activeGroupFilter == g,
                          count: count,
                          color: Colors.blueGrey,
                          onTap: () => vm.filterByGroup(g),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

          // ── Notifications ────────────────────
          if (vm.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const _SkeletonNotification(),
                childCount: 5,
              ),
            )
          else if (vm.notifications.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final n = vm.notifications[i];

                    // Show date separator
                    final showDate = i == 0 ||
                        !_sameDay(
                          vm.notifications[i - 1].createdAt,
                          n.createdAt,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _DateSeparator(date: n.createdAt),
                        _NotificationCard(
                          notification: n,
                          timeAgo: _timeAgo(n.createdAt),
                          onTap: () => _onTapNotification(ctx, n, vm),
                        ),
                      ],
                    );
                  },
                  childCount: vm.notifications.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ── Group Filter Chip ─────────────────────────────
class _GroupChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Notification Card ─────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;
    final color = NotificationModel.colorFor(n.type);
    final icon = NotificationModel.iconFor(n.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: isUnread
              ? Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isUnread ? 0.07 : 0.03),
              blurRadius: isUnread ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isUnread ? color : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        // Title
                        Flexible(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                              height: 1.3,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Message
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnread
                            ? const Color(0xFF444444)
                            : Colors.grey.shade500,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),

                    // Metadata chips (e.g., price,
                    // order ID, crop name)
                    if (n.metadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: n.metadata.entries
                            .where((e) =>
                                e.value.toString().isNotEmpty &&
                                e.key != 'internal')
                            .take(3)
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    e.value.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],

                    // Deep link indicator
                    if (n.deepLink.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'دیکھیں',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Separator ────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime? date;
  const _DateSeparator({this.date});

  String _label() {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date!);
    if (diff.inDays == 0) return 'آج';
    if (diff.inDays == 1) return 'کل';
    return '${date!.day}/${date!.month}/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 44,
              color: AppTheme.primaryGreen.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'کوئی اطلاع نہیں',
            style: TextStyle(
              fontFamily: 'Nastaleeq',
              fontSize: 20,
              color: Color(0xFF888888),
              height: 1.8,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          const Text(
            'نئی اطلاعات یہاں دکھیں گی',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton Loading ──────────────────────────────
class _SkeletonNotification extends StatefulWidget {
  const _SkeletonNotification();

  @override
  State<_SkeletonNotification> createState() => _SkeletonNotificationState();
}

class _SkeletonNotificationState extends State<_SkeletonNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: _anim.value * 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
