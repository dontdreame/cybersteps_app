import 'package:flutter/material.dart';

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({
    super.key,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.passed,
    this.subtitle,
    this.extraLines = const [],
  });

  final String title;
  final String? subtitle;
  final int score;
  final int maxScore;
  final bool passed;
  final List<String> extraLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, textDirection: TextDirection.rtl),
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: (passed ? cs.tertiary : cs.error).withOpacity(0.12),
                          child: Icon(
                            passed ? Icons.verified_rounded : Icons.close_rounded,
                            color: passed ? cs.tertiary : cs.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passed ? 'ناجح ✅' : 'راسب ❌',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                textDirection: TextDirection.rtl,
                              ),
                              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'النتيجة: $score / $maxScore',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: pct,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    if (extraLines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...extraLines.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $t', textDirection: TextDirection.rtl),
                        ),
                      ),
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
