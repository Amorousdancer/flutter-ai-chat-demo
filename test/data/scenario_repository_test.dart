import 'package:flutter_test/flutter_test.dart';
import 'package:offer_lab/data/scenario_repository.dart';

void main() {
  const repository = ScenarioRepository();

  test('returns seeded scenarios', () {
    final scenarios = repository.getScenarios();

    expect(scenarios.length, greaterThanOrEqualTo(4));
    expect(scenarios.first.id, 'flutter-dev');
  });

  test('finds a scenario by id', () {
    final scenario = repository.getScenarioById('salary-negotiation');

    expect(scenario, isNotNull);
    expect(scenario?.title, '薪资谈判');
  });
}
