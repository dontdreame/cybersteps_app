import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../ui/components/cs_button.dart';
import '../levels/levels_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final me = session.me;

    Future<void> refresh() => ref.read(authSessionProvider).refreshMe();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم', textDirection: TextDirection.rtl),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: session.isMeLoading ? null : () => refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'تسجيل خروج',
            onPressed: session.isBusy ? null : () => ref.read(authSessionProvider).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (session.isBusy && me == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (me == null)
                _ErrorState(
                  message: session.meError ?? 'تعذر تحميل بيانات الطالب.',
                  onRetry: session.isMeLoading ? null : () => refresh(),
                )
              else ...[
                _HeaderCard(
                  name: me.fullName,
                  level: me.levelId ?? 0,
                ),
                const SizedBox(height: 12),
                _StatsRow(
                  points: me.pointsForDashboard,
                  pendingPoints: me.pendingPoints,
                  spendablePoints: me.spendablePoints,
                  warnings: me.warningCount,
                ),
                const SizedBox(height: 16),
                const Text(
                  'التنقّل السريع',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                CsButton(
                  label: 'المستويات',
                  icon: Icons.layers_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LevelsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                CsButton(
                  label: 'الامتحانات',
                  icon: Icons.quiz_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('قريباً: صفحة الامتحانات')),
                    );
                  },
                ),
                if (session.meError != null) ...[
                  const SizedBox(height: 14),
                  _SoftWarningBanner(
                    text: 'ملاحظة: آخر تحديث للبيانات فشل. اسحب للتحديث أو اضغط تحديث.',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.level});

  final String name;
  final int level;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Icons.person_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المستوى الحالي: $level',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.points,
    this.pendingPoints,
    this.spendablePoints,
    this.warnings,
  });

  final int points;
  final int? pendingPoints;
  final int? spendablePoints;
  final int? warnings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'النقاط',
            value: '$points',
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 12),
        if (warnings != null)
          Expanded(
            child: _StatCard(
              title: 'التحذيرات',
              value: '$warnings',
              icon: Icons.warning_rounded,
            ),
          )
        else
          Expanded(
            child: _StatCard(
              title: 'الحالة',
              value: 'ممتاز',
              icon: Icons.verified_rounded,
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftWarningBanner extends StatelessWidget {
  const _SoftWarningBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 46),
          const SizedBox(height: 10),
          Text(
            'خطأ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 14),
          CsButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
