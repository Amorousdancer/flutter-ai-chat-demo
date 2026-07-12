import 'package:flutter/material.dart';

import '../models/scenario.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final InterviewMode selectedMode;
  final ValueChanged<InterviewMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InterviewMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<InterviewMode>(
          value: InterviewMode.supportive,
          label: Text('友好模式'),
        ),
        ButtonSegment<InterviewMode>(
          value: InterviewMode.pressure,
          label: Text('压力模式'),
        ),
        ButtonSegment<InterviewMode>(
          value: InterviewMode.deepDive,
          label: Text('深挖模式'),
        ),
      ],
      selected: {selectedMode},
      onSelectionChanged: (selection) {
        onModeSelected(selection.first);
      },
    );
  }
}
