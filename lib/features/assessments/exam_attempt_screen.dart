import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/http/api_utils.dart';
import '../../state/providers.dart';
import 'assessment_result_screen.dart';

class ExamAttemptScreen extends ConsumerStatefulWidget {
  const ExamAttemptScreen({
    super.key,
    required this.levelTitle,
    this.levelId,
  });

  final String levelTitle;
  final int? levelId;

  @override
  ConsumerState<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends ConsumerState<ExamAttemptScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _start;
  final Map<int, String> _selected = {};

  Timer? _timer;
  int _secondsLeft = 0;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startExam() async {
    setState(() {
      _loading = true;
      _error = null;
      _start = null;
      _selected.clear();
    });

    try {
      final api = ref.read(examApiProvider);
      final data = await api.start(levelId: widget.levelId);
      final exam = (data['exam'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final tl = (exam['timeLimitMins'] as num?)?.toInt() ?? 30;
      _secondsLeft = tl * 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _secondsLeft = (_secondsLeft - 1).clamp(0, 1 << 30);
        });
      });

      setState(() {
        _start = data;
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
    if (_start == null) return;
    final exam = (_start!['exam'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final questions = (_start!['questions'] as List?) ?? const [];
    final examId = (exam['id'] as num?)?.toInt() ?? 0;
    final token = (_start!['examSessionToken'] ?? '').toString();

    if (examId <= 0 || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر بدء الامتحان. جرّب مرة ثانية.')),
      );
      return;
    }

    if (_selected.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لازم تجاوب كل الأسئلة (${_selected.length}/${questions.length}).')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(examApiProvider);
      final answers = _selected.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();
      final res = await api.submit(
        examId: examId,
        examSessionToken: token,
        answers: answers,
      );

      final totalScore = (res['totalScore'] as num?)?.toInt() ?? 0;
      final fullMark = (res['fullMark'] as num?)?.toInt() ?? 0;
      final passed = (res['passed'] as bool?) ?? false;
      final rewardPoints = (res['rewardPoints'] as num?)?.toInt();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssessmentResultScreen(
            title: 'نتيجة الامتحان النهائي',
            subtitle: widget.levelTitle,
            score: totalScore,
            maxScore: fullMark,
            passed: passed,
            extraLines: [
              if (rewardPoints != null) 'نقاط مكتسبة: $rewardPoints',
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

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = r.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الامتحان النهائي', textDirection: TextDirection.rtl),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _fmt(_secondsLeft),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _secondsLeft <= 30 ? cs.error : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorBody(message: _error!, onRetry: _startExam)
                : _ExamBody(
                    start: _start!,
                    selected: _selected,
                    onPick: (qid, opt) => setState(() => _selected[qid] = opt),
                    submitting: _submitting,
                  ),
      ),
      bottomNavigationBar: _start == null
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
                          'تسليم الامتحان',
                          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800),
                          textDirection: TextDirection.rtl,
                        ),
                ),
              ),
            ),
    );
  }
}

class _ExamBody extends StatelessWidget {
  const _ExamBody({
    required this.start,
    required this.selected,
    required this.onPick,
    required this.submitting,
  });

  final Map<String, dynamic> start;
  final Map<int, String> selected;
  final void Function(int questionId, String option) onPick;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final exam = (start['exam'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final title = (exam['title'] ?? '').toString();
    final questions = (start['questions'] as List?)?.cast<Map>() ?? const [];

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
                  Text(
                    title.isNotEmpty ? title : 'امتحان',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جاوب كل الأسئلة وبعدين اضغط “تسليم الامتحان”.',
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
        final text = (q['question'] ?? '').toString();
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
                  text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                ...opts.entries.map(
                  (e) => RadioListTile<String>(
                    value: e.key,
                    groupValue: sel,
                    onChanged: submitting ? null : (v) => v == null ? null : onPick(qid, v),
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
              'تعذّر تحميل الامتحان',
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
