import 'package:flutter/material.dart';

import '../data/scenario_repository.dart';
import '../models/scenario.dart';
import 'chat_page.dart';
import 'scenario_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 面试与职场沟通陪练 App',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '已加载 ${scenarios.length} 个本地练习场景',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
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

class _ScenarioPreviewCard extends StatelessWidget {
  const _ScenarioPreviewCard({
    required this.scenario,
    required this.onTap,
  });

  final Scenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scenario.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(scenario.difficulty.label),
                ],
              ),
              const SizedBox(height: 8),
              Text(scenario.subtitle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scenario.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '${scenario.roleName} · ${scenario.roleTitle}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    '查看详情',
                    style: Theme.of(context).textTheme.labelLarge,
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
