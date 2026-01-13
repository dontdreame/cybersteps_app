import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/level.dart';
import '../../state/providers.dart';
import '../../services/levels/levels_api.dart';

class LevelDetailScreen extends ConsumerStatefulWidget {
  const LevelDetailScreen({super.key, required this.levelId});

  final int levelId;

  @override
  ConsumerState<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends ConsumerState<LevelDetailScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  LevelDetailResponse? _data;

  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = LevelsApi(session.dio);
      final data = await api.fetchLevelDetail(widget.levelId);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل تفاصيل المستوى.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          d?.level.title ?? 'المستوى',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'المحتوى'),
            Tab(text: 'الامتحانات'),
            Tab(text: 'التقدّم'),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : d == null
                    ? _ErrorState(message: 'لا توجد بيانات', onRetry: _load)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _ContentTab(level: d.level, tpl: d.studyPlanTemplate),
                          _ExamsTab(level: d.level, exams: d.exams, quizzes: d.quizzes),
                          _ProgressTab(level: d.level),
                        ],
                      ),
      ),
    );
  }
}

class _ContentTab extends StatelessWidget {
  const _ContentTab({required this.level, required this.tpl});

  final Level level;
  final Map<String, dynamic>? tpl;

  @override
  Widget build(BuildContext context) {
    final status = level.status ?? 'LOCKED';
    final locked = status == 'LOCKED';

    if (locked) {
      return _LockedPanel(title: level.title, reason: level.lockedReason ?? 'المستوى مقفول.');
    }

    if (tpl == null) {
      return const _InfoPanel(
        title: 'لا يوجد محتوى جاهز بعد',
        body: 'رح نربط المحتوى التفصيلي في باتش قادم، لكن القفل/الفتح والـ UI جاهزين.',
      );
    }

    final weeks = (tpl!['weeks'] is List) ? (tpl!['weeks'] as List) : const [];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  (tpl!['title'] ?? 'خطة الدراسة').toString(),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'نسخة: ${(tpl!['version'] ?? '').toString()}',
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...weeks.map((w) => _WeekTile(week: Map<String, dynamic>.from(w as Map))).toList(),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({required this.week});
  final Map<String, dynamic> week;

  @override
  Widget build(BuildContext context) {
    final days = (week['days'] is List) ? (week['days'] as List) : const [];
    final weekNum = (week['weekNumber'] ?? '').toString();
    final title = (week['title'] ?? 'الأسبوع $weekNum').toString();

    return Card(
      child: ExpansionTile(
        title: Text(title, textDirection: TextDirection.rtl),
        subtitle: Text('أيام: ${days.length}', textDirection: TextDirection.rtl),
        children: days
            .map((d) => _DayTile(day: Map<String, dynamic>.from(d as Map)))
            .toList(),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});
  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final dayNum = (day['dayNumber'] ?? '').toString();
    final title = (day['title'] ?? 'اليوم $dayNum').toString();
    final desc = (day['description'] ?? '').toString();

    final tasks = (day['tasksJson'] is List) ? (day['tasksJson'] as List) : const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (desc.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(desc, textDirection: TextDirection.rtl),
              ],
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                const Text('لا يوجد مهام لهذا اليوم.', textDirection: TextDirection.rtl)
              else
                ...tasks.map((t) => _TaskRow(task: Map<String, dynamic>.from(t as Map))).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final title = (task['title'] ?? 'Task').toString();
    final type = (task['type'] ?? '').toString();
    final minutes = task['minutes'];
    final points = task['points'];

    String meta = '';
    if (type.isNotEmpty) meta += type;
    if (minutes != null) meta += (meta.isEmpty ? '' : ' • ') + '${minutes.toString()} دقيقة';
    if (points != null) meta += (meta.isEmpty ? '' : ' • ') + '${points.toString()} نقطة';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, textDirection: TextDirection.rtl),
                if (meta.isNotEmpty)
                  Text(meta, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.check_box_outline_blank),
        ],
      ),
    );
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab({
    required this.level,
    required this.exams,
    required this.quizzes,
  });

  final Level level;
  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> quizzes;

  @override
  Widget build(BuildContext context) {
    final status = level.status ?? 'LOCKED';
    final locked = status == 'LOCKED';

    if (locked) {
      return _LockedPanel(title: level.title, reason: level.lockedReason ?? 'المستوى مقفول.');
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            title: const Text('امتحانات', textDirection: TextDirection.rtl),
            trailing: Text('${exams.length}'),
          ),
        ),
        ...exams.map((e) => _ExamTile(item: e, icon: Icons.assignment)).toList(),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: const Text('كويزات', textDirection: TextDirection.rtl),
            trailing: Text('${quizzes.length}'),
          ),
        ),
        ...quizzes.map((q) => _ExamTile(item: q, icon: Icons.quiz)).toList(),
        const SizedBox(height: 12),
        const _InfoPanel(
          title: 'ملاحظة',
          body: 'تشغيل الامتحان/الكويز فعلياً وربطه بواجهة الحل رح يكون في باتش الامتحانات.',
        ),
      ],
    );
  }
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.item, required this.icon});
  final Map<String, dynamic> item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? 'عنصر').toString();
    final passing = item['passingScore'];
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, textDirection: TextDirection.rtl),
        subtitle: passing != null ? Text('النجاح: ${passing.toString()}%', textDirection: TextDirection.rtl) : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('قريباً')),
          );
        },
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final status = level.status ?? 'LOCKED';
    final locked = status == 'LOCKED';

    if (locked) {
      return _LockedPanel(title: level.title, reason: level.lockedReason ?? 'المستوى مقفول.');
    }

    return const _InfoPanel(
      title: 'التقدّم',
      body: 'رح نربط التقدّم الحقيقي (محاولات الامتحانات/الكويزات والنقاط) في باتش لاحق.',
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 42),
            const SizedBox(height: 12),
            Text(title, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(reason, textDirection: TextDirection.rtl, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, textDirection: TextDirection.rtl, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textDirection: TextDirection.rtl, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
