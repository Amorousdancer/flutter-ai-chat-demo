import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../services/practice_store.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String _nickname = '候选人同学';
  static const String _appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: AnimatedBuilder(
        animation: PracticeStore.instance,
        builder: (context, _) {
          final latestRecord = PracticeStore.instance.latestRecord;
          final subtitle = latestRecord == null
              ? '先完成一轮练习，统计会自动更新。'
              : '最近练习：${_formatDate(latestRecord.completedAt)} · ${latestRecord.mode.label}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                _nickname,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatPanel(
                    label: '累计练习',
                    value: '${PracticeStore.instance.totalPractices}',
                  ),
                  _StatPanel(
                    label: '平均得分',
                    value: '${PracticeStore.instance.averageScore} 分',
                  ),
                  _StatPanel(
                    label: '最高得分',
                    value: '${PracticeStore.instance.bestScore} 分',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                '关于应用',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const _InfoLine(
                label: '定位',
                value: 'AI 模拟面试与职场对话练习 Demo',
              ),
              const _InfoLine(
                label: '当前能力',
                value: '本地场景、本地 mock 对话、练习反馈、历史记录',
              ),
              const _InfoLine(
                label: '记录方式',
                value: '练习记录当前仅保存在运行内存中，重启后会清空',
              ),
              const SizedBox(height: 28),
              Text(
                '版本信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const _InfoLine(
                label: '应用版本',
                value: _appVersion,
              ),
              const _InfoLine(
                label: '构建阶段',
                value: 'OfferLab MVP / 本地演示版',
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 156,
        maxWidth: 240,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
