import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/sample_plan.dart';

void main() {
  final plan = buildSamplePlan(id: 'plan-1', importedAt: DateTime(2026, 9, 25));

  test('shows every step type the runner can play', () {
    expect(plan.steps.map((s) => s.type).toSet(), StepType.values.toSet());
  });

  test('carries a form tip, so the tip card is part of the tour', () {
    expect(plan.steps.any((s) => s.notes != null), isTrue);
  });

  test('is marked as the sample, and a real import is not', () {
    expect(plan.isSample, isTrue);

    final imported = Plan(
      id: 'plan-2',
      name: 'Mine',
      sourceFilename: 'mine.fit',
      importedAt: DateTime(2026, 9, 25),
      steps: plan.steps,
    );
    expect(imported.isSample, isFalse);
  });

  test('survives a storage round trip still marked as the sample', () {
    expect(Plan.fromJson(plan.toJson()).isSample, isTrue);
  });
}
