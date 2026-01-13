import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/level.dart';
import '../../state/providers.dart';
import '../../services/levels/levels_api.dart';

import 'level_detail_screen.dart';

class LevelsScreen extends ConsumerStatefulWidget {
  const LevelsScreen({super.key});

  static const String routeName = 'levels';
  static const String routePath = '/levels';

  @override
  ConsumerState<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends ConsumerState<LevelsScreen> {
  bool _loading = true;
  String? _error;
  LevelsOverviewResponse? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider);
    final me = session.me;
    if (me == null) {
      setState(() {
        _loading = false;
        _error = 'لم يتم تحميل بيانات الطالب بعد. جرّب تحديث الصفحة.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = LevelsApi(session.dio);
      final data = await api.fetchOverview();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل المستويات. تأكد من الاتصال ثم حاول مرة ثانية.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final me = session.me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستويات', textDirection: TextDirection.rtl),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: SafeArea(
        child: me == null
            ? _EmptyState(
                title: 'لا يوجد مستخدم مسجّل',
                subtitle: 'سجّل دخول أولاً ثم ارجع لهاي الصفحة.',
                onRetry: _load,
              )
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _EmptyState(
                        title: 'صار في مشكلة',
                        subtitle: _error!,
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _HeaderCard(
                              currentOrder: _data?.currentLevelOrder ?? (me.levelId ?? 0),
                              nextUnlockStatus: _data?.nextUnlockStatus ?? const <String, dynamic>{},
                            ),
                            const SizedBox(height: 12),
                            ...(_buildLevelCards(
                              context: context,
                              levels: _data?.levels ?? _fallbackLevels(me.levelId ?? 0),
                              currentOrder: _data?.currentLevelOrder ?? (me.levelId ?? 0),
                            )),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
      ),
    );
  }

  List<Widget> _buildLevelCards({
    required BuildContext context,
    required List<Level> levels,
    required int currentOrder,
  }) {
    return levels.map((level) {
      final status = level.effectiveStatus(currentLevel: currentOrder);
      final isLocked = status == 'LOCKED';

      return Card(
        child: ListTile(
          title: Text(
            level.title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            level.description ?? 'المستوى رقم ${level.order}',
            textDirection: TextDirection.rtl,
          ),
          trailing: _StatusChip(status: status),
          onTap: () {
            if (isLocked) {
              final reason = defaultLockReason(level: level, currentLevel: currentOrder);
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => _LockedReasonSheet(
                  title: level.title,
                  reason: reason,
                ),
              );
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LevelDetailScreen(levelId: level.id),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  List<Level> _fallbackLevels(int currentOrder) {
    // In case the backend endpoint isn't deployed yet, we still show something.
    return List.generate(6, (i) {
      final order = i;
      return Level(
        id: order,
        order: order,
        title: 'Level $order',
        description: 'مستوى $order',
      );
    });
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.currentOrder,
    required this.nextUnlockStatus,
  });

  final int currentOrder;
  final Map<String, dynamic> nextUnlockStatus;

  @override
  Widget build(BuildContext context) {
    final paid = nextUnlockStatus['paid'] == true;
    final passedExam = nextUnlockStatus['passedExam'] == true;
    final canUnlock = nextUnlockStatus['canUnlockNextLevel'] == true;
    final reason = (nextUnlockStatus['reason'] ?? '').toString();

    String arReason(String r) {
      switch (r) {
        case 'missing_payment':
          return 'ناقصك الدفع لفتح المستوى القادم.';
        case 'missing_exam':
          return 'ناقصك نجاح الامتحان النهائي للمستوى الحالي.';
        case 'not_eligible':
          return 'لسه غير مؤهل لفتح المستوى القادم.';
        case 'no_next_level':
          return 'أنت بأعلى مستوى.';
        default:
          return '';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ملخص القفل/الفتح',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _kv('المستوى الحالي', 'Level $currentOrder'),
            _kv('الدفع', paid ? 'تم' : 'غير مكتمل'),
            _kv('النهائي', passedExam ? 'ناجح' : 'غير ناجح'),
            _kv('فتح المستوى القادم', canUnlock ? 'مؤهل (استخدم الموقع/endpoint للفتح)' : 'غير مؤهل'),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                arReason(reason),
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(v)),
          const SizedBox(width: 10),
          Text(k, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (status) {
      case 'COMPLETED':
        label = 'مكتمل';
        icon = Icons.check_circle;
        break;
      case 'AVAILABLE':
        label = 'متاح';
        icon = Icons.play_circle_fill;
        break;
      default:
        label = 'مقفول';
        icon = Icons.lock;
        break;
    }

    return Chip(
      label: Text(label, textDirection: TextDirection.rtl),
      avatar: Icon(icon, size: 18),
    );
  }
}

class _LockedReasonSheet extends StatelessWidget {
  const _LockedReasonSheet({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('تمام', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}
