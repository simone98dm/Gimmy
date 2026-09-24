import '../models/plan.dart';
import 'document_store.dart';
import 'open_document_store.dart';
import '../../core/logging/app_log.dart';

/// Stores the one active plan.
///
/// Importing replaces whatever was there, so there is a single document rather
/// than a collection. If a plan library is ever wanted, this becomes a list and
/// the settings' `activePlanId` starts earning its keep.
class PlanRepository {
  PlanRepository({DocumentStore? store})
    : _store = store ?? openDocumentStore('plan.json');

  final DocumentStore _store;

  Future<Plan?> load() async {
    final document = await _store.read();
    if (document == null) return null;

    try {
      return Plan.fromJson(document as Map<String, dynamic>);
    } on Object catch (error) {
      // Written by an older or newer build, or hand-edited. Better to start
      // from the import screen than to crash on launch.
      AppLog.warning('storage', 'stored plan unreadable, discarding it', error);
      await _store.delete();
      return null;
    }
  }

  Future<void> save(Plan plan) => _store.write(plan.toJson());

  Future<void> clear() => _store.delete();
}
