import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/http/api_utils.dart';
import '../../state/providers.dart';
import 'assessment_result_screen.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  const QuizAttemptScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final int quizId;
  final String quizTitle;

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _quiz;

  final Map<int, String> _selected = {}; // questionId -> 'A'|'B'|'C'|'D'

  bool _submitting = false;

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
      final data = await api.getQuiz(widget.quizId);
      setState(() {
        _quiz = data;
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
    if (_quiz == null) return;

    final qs = (_quiz!['questions'] as List?) ?? const [];
    final qCount = qs.length;
    if (qCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد أسئلة لهذا الكويز.')),
      );
      return;
    }

    if (_selected.length < qCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لازم تجاوب كل الأسئلة (${_selected.length}/$qCount).')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(quizApiProvider);
      final answers = _selected.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();
      final res = await api.submit(quizId: widget.quizId, answers: answers);

      final score = (res['score'] as num?)?.toInt() ?? 0;
      final maxScore = (res['maxScore'] as num?)?.toInt() ?? 0;
      final passed = (res['passed'] as bool?) ?? false;
      final attemptId = (res['attemptId'] as num?)?.toInt();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssessmentResultScreen(
            title: 'نتيجة الكويز',
            subtitle: widget.quizTitle,
            score: score,
            maxScore: maxScore,
            passed: passed,
            extraLines: [
              if (attemptId != null) 'رقم المحاولة: $attemptId',
            ],
          ),
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
        title: Text(widget.quizTitle, textDirection: TextDirection.rtl),
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
                : _QuizBody(
                    quiz: _quiz!,
                    selected: _selected,
                    onPick: (qid, opt) => setState(() => _selected[qid] = opt),
                    onSubmit: _submitting ? null : _submit,
                    submitting: _submitting,
                  ),
      ),
      bottomNavigationBar: _quiz == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'تسليم الكويز',
                          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800),
                          textDirection: TextDirection.rtl,
                        ),
                ),
              ),
            ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.quiz,
    required this.selected,
    required this.onPick,
    required this.onSubmit,
    required this.submitting,
  });

  final Map<String, dynamic> quiz;
  final Map<int, String> selected;
  final void Function(int questionId, String option) onPick;
  final VoidCallback? onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final questions = (quiz['questions'] as List?)?.cast<Map>() ?? const [];

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
                    'تعليمات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جاوب كل الأسئلة وبعدين اضغط “تسليم الكويز”.',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          );
        }

        final q = questions[i - 1].cast<String, dynamic>();
        final qid = (q['id'] as num?)?.toInt() ?? 0;
        final title = (q['question'] ?? '').toString();
        final sel = selected[qid];

        final opts = <String, String>{
          'A': (q['optionA'] ?? '').toString(),
          'B': (q['optionB'] ?? '').toString(),
          'C': (q['optionC'] ?? '').toString(),
          'D': (q['optionD'] ?? '').toString(),
        };

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
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                ...opts.entries.map(
                  (e) => RadioListTile<String>(
                    value: e.key,
                    groupValue: sel,
                    onChanged: submitting
                        ? null
                        : (v) {
                            if (v != null) onPick(qid, v);
                          },
                    title: Text(e.value, textDirection: TextDirection.rtl),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
            Text(
              'تعذّر تحميل الكويز',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textDirection: TextDirection.rtl,
            ),
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
