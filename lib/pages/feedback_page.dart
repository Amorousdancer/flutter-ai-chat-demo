import 'package:flutter/material.dart';

import '../models/feedback_result.dart';
import '../models/practice_record.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({
    super.key,
    required this.feedback,
    required this.record,
  });

  final FeedbackResult feedback;
  final PracticeRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习反馈'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.score} 分',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(feedback.summary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FeedbackSection(
            title: '做得不错',
            items: feedback.strengths,
          ),
          const SizedBox(height: 16),
          _FeedbackSection(
            title: '继续改进',
            items: feedback.improvements,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '优化回答示例',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(feedback.optimizedReply),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              Text('• $item'),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
