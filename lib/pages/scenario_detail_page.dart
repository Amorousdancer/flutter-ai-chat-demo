import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../widgets/mode_selector.dart';

class ScenarioDetailPage extends StatefulWidget {
  const ScenarioDetailPage({
    super.key,
    required this.scenario,
  });

  final Scenario scenario;

  @override
  State<ScenarioDetailPage> createState() => _ScenarioDetailPageState();
}

class _ScenarioDetailPageState extends State<ScenarioDetailPage> {
  InterviewMode _selectedMode = InterviewMode.supportive;

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(scenario.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OverviewPanel(
            scenario: scenario,
            selectedMode: _selectedMode,
          ),
          const SizedBox(height: 20),
          _DetailSection(
            title: '练习目标',
            child: Text(scenario.description),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'AI 扮演角色',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.roleName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(scenario.roleTitle),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: '练习模式',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModeSelector(
                  selectedMode: _selectedMode,
                  onModeSelected: (mode) {
                    setState(() {
                      _selectedMode = mode;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _modeHint(_selectedMode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: '开场问题预览',
            child: Text(scenario.openingPrompt),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('start-practice-button'),
            onPressed: () {
              Navigator.of(context).pop(_selectedMode);
            },
            child: Text('开始 ${_selectedMode.label}'),
          ),
        ],
      ),
    );
  }

  String _modeHint(InterviewMode mode) {
    switch (mode) {
      case InterviewMode.supportive:
        return '适合先热身，重点是把结构和表达稳定下来。';
      case InterviewMode.pressure:
        return '适合演练高压追问，重点是结果表达和说服力。';
      case InterviewMode.deepDive:
        return '适合复盘细节，重点是决策过程和反思能力。';
    }
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.scenario,
    required this.selectedMode,
  });

  final Scenario scenario;
  final InterviewMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.subtitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(scenario.difficulty.label),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(selectedMode.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
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
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
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
            child,
          ],
        ),
      ),
    );
  }
}
