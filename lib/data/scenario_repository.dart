import '../models/scenario.dart';
import 'seed_data.dart';

class ScenarioRepository {
  const ScenarioRepository();

  List<Scenario> getScenarios() {
    return List<Scenario>.unmodifiable(seedScenarios);
  }

  Scenario? getScenarioById(String scenarioId) {
    for (final scenario in seedScenarios) {
      if (scenario.id == scenarioId) {
        return scenario;
      }
    }

    return null;
  }
}
