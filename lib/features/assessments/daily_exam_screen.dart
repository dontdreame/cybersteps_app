import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/http/api_utils.dart';
import '../../state/providers.dart';

class DailyExamScreen extends ConsumerStatefulWidget {
  const DailyExamScreen({super.key});

  @override
  ConsumerState<DailyExamScreen> createState() => _DailyExamScreenState();
}

class _DailyExamScreenState extends ConsumerState<DailyExamScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _exam;

  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _exam = null;
      _controllers.clear();
    });

    try {
      final api = ref.read(dailyExamApiProvider);
      final data = await api.getToday();
      final qs = (data['questions'] as List?)?.cast<Map>() ?? const [];
      for (final q in qs) {
        final id = (q['id'] ?? '').toString();
        _controllers[id] = TextEditingController();
      }
      setState(() {
        _exam = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiUtils.humanizeDioError(e);
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_exam == null) return;
    final qs = (_exam!['questions'] as List?)?.cast<Map>() ?? const [];
    if (qs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد أسئلة لامتحان اليوم.')),
      );
      return;
    }

    final answers = <Map<String, dynamic>>[];
    for (final q in qs) {
      final qid = (q['id'] ?? '').toString();
      final text = _controllers[qid]?.text.trim() ?? '';
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لازم تجاوب كل الأسئلة.')),
        );
        return;
      }
      answers.add({'questionId': qid, 'answerText': text});
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(dailyExamApiProvider);
      await api.submitToday(answers: answers);
      final result = await api.getResult();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _DailyExamResultScreen(result: result),
        ),
      );
    } catch (e) {
      final msg = ApiUtils.humanizeDioError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار اليوم', textDirection: TextDirection.rtl),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorBody(message: _error!, onRetry: _load)
                : _DailyExamBody(exam: _exam!, controllers: _controllers),
      ),
      bottomNavigationBar: _exam == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'تسليم اختبار اليوم',
                          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800),
                          textDirection: TextDirection.rtl,
                        ),
                ),
              ),
            ),
    );
  }
}

class _DailyExamBody extends StatelessWidget {
  const _DailyExamBody({required this.exam, required this.controllers});

  final Map<String, dynamic> exam;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ymd = (exam['dateYmd'] ?? '').toString();
    final deadline = (exam['deadlineAt'] ?? '').toString();
    final questions = (exam['questions'] as List?)?.cast<Map>() ?? const [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  if (ymd.isNotEmpty)
                    Text('تاريخ اليوم: $ymd', textDirection: TextDirection.rtl),
                  if (deadline.isNotEmpty)
                    Text(
                      'الموعد النهائي: $deadline',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                      textDirection: TextDirection.rtl,
                    ),
                ],
              ),
            ),
          );
        }

        final q = questions[i - 1].cast<String, dynamic>();
        final qid = (q['id'] ?? '').toString();
        final prompt = (q['prompt'] ?? '').toString();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سؤال ${i - 1}',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Text(prompt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), textDirection: TextDirection.rtl),
                const SizedBox(height: 10),
                TextField(
                  controller: controllers[qid],
                  minLines: 3,
                  maxLines: 6,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'اكتب إجابتك هنا...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyExamResultScreen extends StatelessWidget {
  const _DailyExamResultScreen({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final submission = (result['submission'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final total = (submission['totalScore'] as num?)?.toInt() ?? 0;
    final max = (submission['maxScore'] as num?)?.toInt() ?? 100;
    final ymd = (submission['dateYmd'] ?? result['dateYmd'] ?? '').toString();
    final overall = (submission['overallFeedback'] as Map?)?.cast<String, dynamic>();
    final overallText = overall?['overallFeedback']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة اختبار اليوم', textDirection: TextDirection.rtl),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ymd.isNotEmpty)
                      Text('تاريخ: $ymd', style: TextStyle(color: cs.onSurface.withOpacity(0.7)), textDirection: TextDirection.rtl),
                    const SizedBox(height: 6),
                    Text('النتيجة: $total / $max', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), textDirection: TextDirection.rtl),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: max <= 0 ? 0 : (total / max).clamp(0.0, 1.0),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    if (overallText != null && overallText.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('ملاحظات:', style: TextStyle(fontWeight: FontWeight.w900), textDirection: TextDirection.rtl),
                      const SizedBox(height: 6),
                      Text(overallText, textDirection: TextDirection.rtl),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('رجوع', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: cs.error),
            const SizedBox(height: 10),
            Text('تعذّر تحميل اختبار اليوم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textDirection: TextDirection.rtl),
            const SizedBox(height: 6),
            Text(message, textDirection: TextDirection.rtl, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}
