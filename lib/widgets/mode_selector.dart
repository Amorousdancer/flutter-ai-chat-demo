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
    const modes = InterviewMode.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes
          .map(
            (mode) => ChoiceChip(
              label: Text(mode.label),
              selected: mode == selectedMode,
              onSelected: (_) => onModeSelected(mode),
            ),
          )
          .toList(),
    );
  }
}
