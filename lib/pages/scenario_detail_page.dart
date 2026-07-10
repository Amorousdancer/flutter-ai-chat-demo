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

    return Scaffold(
      appBar: AppBar(
        title: Text(scenario.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            scenario.subtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: '练习目标',
            child: Text(scenario.description),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'AI 扮演角色',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.roleName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(scenario.roleTitle),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: '练习模式',
            child: ModeSelector(
              selectedMode: _selectedMode,
              onModeSelected: (mode) {
                setState(() {
                  _selectedMode = mode;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _InfoSection(
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
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
            child,
          ],
        ),
      ),
    );
  }
}
