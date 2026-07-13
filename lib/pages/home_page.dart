import 'package:flutter/material.dart';

import '../data/scenario_repository.dart';
import '../models/scenario.dart';
import '../services/interview_service.dart';
import 'chat_page.dart';
import 'scenario_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.interviewService,
  });

  final InterviewService interviewService;

  @override
  Widget build(BuildContext context) {
    final scenarios = const ScenarioRepository().getScenarios();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OfferLab'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: scenarios.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _HomeSummary(scenarioCount: scenarios.length);
          }

          final scenario = scenarios[index - 1];
          return _ScenarioPreviewCard(
            scenario: scenario,
            onTap: () async {
              final selectedMode = await Navigator.of(context).push<InterviewMode>(
                MaterialPageRoute(
                  builder: (_) => ScenarioDetailPage(scenario: scenario),
                ),
              );

              if (!context.mounted || selectedMode == null) {
                return;
              }

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    scenario: scenario,
                    mode: selectedMode,
                    service: interviewService,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeSummary extends StatelessWidget {
  const _HomeSummary({
    required this.scenarioCount,
  });

  final int scenarioCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI 面试与职场沟通陪练 App',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              '已加载 $scenarioCount 个本地练习场景',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '从场景选择、模拟对话到反馈回看，当前版本已经能完整演示 OfferLab 的 MVP 闭环。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SummaryBadge(
                  icon: Icons.topic_outlined,
                  label: '本地场景',
                ),
                _SummaryBadge(
                  icon: Icons.chat_bubble_outline,
                  label: 'AI 流式对话',
                ),
                _SummaryBadge(
                  icon: Icons.insights_outlined,
                  label: '反馈可回看',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioPreviewCard extends StatelessWidget {
  const _ScenarioPreviewCard({
    required this.scenario,
    required this.onTap,
  });

  final Scenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      key: Key('scenario-card-${scenario.id}'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.title,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scenario.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DifficultyBadge(difficulty: scenario.difficulty),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scenario.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${scenario.roleName} · ${scenario.roleTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '查看详情',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final ScenarioDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = switch (difficulty) {
      ScenarioDifficulty.beginner => (
          const Color(0xFF123227),
          const Color(0xFF8DE5BF),
        ),
      ScenarioDifficulty.intermediate => (
          const Color(0xFF3A2B12),
          const Color(0xFFF1C87A),
        ),
      ScenarioDifficulty.advanced => (
          const Color(0xFF402021),
          const Color(0xFFFFAAA7),
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          difficulty.label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
