import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/level.dart';
import '../../services/http/api_utils.dart';
import '../../state/providers.dart';
import '../assessments/daily_exam_screen.dart';
import '../assessments/exam_attempt_screen.dart';
import '../assessments/quiz_attempt_screen.dart';

class LevelDetailScreen extends StatelessWidget {
  const LevelDetailScreen({
    super.key,
    required this.level,
    required this.currentLevel,
  });

  final Level level;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final status = computeLevelStatus(level: level, currentLevel: currentLevel);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(level.title, textDirection: TextDirection.rtl),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المحتوى'),
              Tab(text: 'الامتحانات'),
              Tab(text: 'التقدّم'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ContentTab(level: level, status: status),
            _ExamsTab(level: level, status: status, currentLevel: currentLevel),
            _ProgressTab(level: level, status: status),
          ],
        ),
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab({required this.level, required this.status});
  final Level level;
  final LevelUiStatus status;

  @override
  Widget build(BuildContext context) {
    final items = _contentFor(level.order);

    if (status == LevelUiStatus.locked) {
      return _LockedBody(title: 'المحتوى مقفول', subtitle: 'ارجع لصفحة المستويات وشوف سبب القفل.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(item, textDirection: TextDirection.rtl),
            subtitle: Text('قريباً: فتح الدروس من الـ API', textDirection: TextDirection.rtl),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً: شاشة الدرس')),
              );
            },
          ),
        );
      },
    );
  }

  List<String> _contentFor(int order) {
    // Placeholder sections — next patch will load them from backend.
    switch (order) {
      case 0:
        return const ['Networking Basics', 'Linux Intro', 'Cyber Hygiene', 'Mini Labs'];
      case 1:
        return const ['Linux CLI', 'Windows Basics', 'Networking Practice', 'Daily Quizzes'];
      case 2:
        return const ['Blue Team Basics', 'Logs & SIEM', 'Incident Response', 'Hands-on'];
      case 3:
        return const ['Threat Hunting', 'Hardening', 'Detection Engineering', 'Projects'];
      case 4:
        return const ['Choose Track', 'Track Modules', 'Track Labs', 'Mid Assessments'];
      case 5:
        return const ['Capstone', 'Final Review', 'Mock Final', 'Final Exam'];
      default:
        return const ['Content'];
    }
  }
}

class _ExamsTab extends ConsumerStatefulWidget {
  const _ExamsTab({required this.level, required this.status, required this.currentLevel});
  final Level level;
  final LevelUiStatus status;
  final int currentLevel;

  @override
  ConsumerState<_ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends ConsumerState<_ExamsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quizzes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(quizApiProvider);
      final list = await api.listByLevel(widget.level.id);
      setState(() {
        _quizzes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiUtils.humanizeDioError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == LevelUiStatus.locked) {
      return _LockedBody(title: 'الامتحانات مقفولة', subtitle: 'هذا المستوى لسه ما انفتح.');
    }

    final isCurrent = widget.level.id == widget.currentLevel;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isCurrent)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('ملاحظة', textDirection: TextDirection.rtl),
              subtitle: const Text(
                'الامتحان النهائي واختبار اليوم متاحين فقط لمستواك الحالي. تقدر تشوف الكويزات.',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.quiz_rounded),
            title: const Text('اختبار اليوم', textDirection: TextDirection.rtl),
            subtitle: Text(
              isCurrent ? '5 أسئلة – تسليم واحد' : 'مقفول (ليس مستواك الحالي)',
              textDirection: TextDirection.rtl,
            ),
            enabled: isCurrent,
            onTap: isCurrent
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DailyExamScreen()),
                    )
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختبار اليوم متاح فقط لمستواك الحالي.')),
                    );
                  },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: const Text('الامتحان النهائي', textDirection: TextDirection.rtl),
            subtitle: Text(
              isCurrent ? 'ابدأ المحاولة ثم سلّم الإجابات' : 'مقفول (ليس مستواك الحالي)',
              textDirection: TextDirection.rtl,
            ),
            enabled: isCurrent,
            onTap: isCurrent
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExamAttemptScreen(levelTitle: widget.level.title, levelId: widget.level.id),
                      ),
                    )
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الامتحان النهائي متاح فقط لمستواك الحالي.')),
                    );
                  },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'الكويزات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                textDirection: TextDirection.rtl,
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
        else if (_error != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline_rounded),
              title: const Text('تعذّر تحميل الكويزات', textDirection: TextDirection.rtl),
              subtitle: Text(_error!, textDirection: TextDirection.rtl),
              trailing: const Icon(Icons.refresh_rounded),
              onTap: _load,
            ),
          )
        else if (_quizzes.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_rounded),
              title: const Text('لا يوجد كويزات حالياً', textDirection: TextDirection.rtl),
              subtitle: const Text('رح تظهر هون أول ما تنضاف على السيرفر.', textDirection: TextDirection.rtl),
            ),
          )
        else
          ..._quizzes.map((q) {
            final id = (q['id'] as num?)?.toInt() ?? 0;
            final title = (q['title'] ?? 'Quiz').toString();
            final desc = (q['description'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.list_alt_rounded),
                  title: Text(title, textDirection: TextDirection.rtl),
                  subtitle: desc.trim().isEmpty
                      ? const Text('اضغط لبدء الكويز', textDirection: TextDirection.rtl)
                      : Text(desc, textDirection: TextDirection.rtl, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: id <= 0
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => QuizAttemptScreen(quizId: id, quizTitle: title)),
                          ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.level, required this.status});
  final Level level;
  final LevelUiStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (status == LevelUiStatus.locked) {
      return _LockedBody(title: 'التقدّم غير متاح', subtitle: 'هذا المستوى مقفول حالياً.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخّص التقدّم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: status == LevelUiStatus.completed ? 1.0 : 0.35,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 10),
                Text(
                  status == LevelUiStatus.completed ? 'مكتمل 100%' : 'قريباً: تقدّم حقيقي من الـ API',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 46, color: cs.error.withOpacity(0.9)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
