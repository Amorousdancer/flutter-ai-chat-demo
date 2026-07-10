import 'package:flutter/material.dart';

import '../models/practice_record.dart';
import '../models/scenario.dart';
import '../services/practice_store.dart';

class PracticeHistoryPage extends StatelessWidget {
  const PracticeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习记录'),
      ),
      body: AnimatedBuilder(
        animation: PracticeStore.instance,
        builder: (context, _) {
          final records = PracticeStore.instance.records;
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '最近练习',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('完成一轮练习后，这里会显示你的历史记录。'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                child: ListTile(
                  title: Text(record.scenarioTitle),
                  subtitle: Text(record.summary),
                  trailing: Text('${record.score} 分'),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _PracticeRecordSheet(record: record),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PracticeRecordSheet extends StatelessWidget {
  const _PracticeRecordSheet({required this.record});

  final PracticeRecord record;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          record.scenarioTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('${record.score} 分 · ${record.mode.label}'),
        const SizedBox(height: 16),
        Text(record.summary),
        const SizedBox(height: 16),
        Text(
          '关键片段',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(record.highlightQuote),
        const SizedBox(height: 16),
        Text(
          '继续改进',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final item in record.improvements) ...[
          Text('• $item'),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text(
          '优化回答示例',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(record.optimizedReply),
      ],
    );
  }
}
