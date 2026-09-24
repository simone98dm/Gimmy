import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/fit/fit_file_picker.dart';
import '../../../data/fit/fit_parse_exception.dart';
import '../../../data/fit/fit_workout_parser.dart';
import '../../../data/models/plan.dart';
import '../../../data/storage/plan_repository.dart';
import '../../../data/storage/settings_repository.dart';
import '../../../core/logging/app_log.dart';

part 'import_event.dart';
part 'import_state.dart';

/// Drives the Import page: pick a file, validate it, preview it, save it.
///
/// Nothing is written until the user confirms, and a rejected file writes
/// nothing at all — the plan only reaches [PlanRepository] on [ImportConfirmed].
class ImportBloc extends Bloc<ImportEvent, ImportState> {
  ImportBloc({
    required FitFilePicker pickFile,
    required PlanRepository planRepository,
    required SettingsRepository settingsRepository,
    DateTime Function() now = DateTime.now,
  }) : _pickFile = pickFile,
       _planRepository = planRepository,
       _settingsRepository = settingsRepository,
       _now = now,
       super(const ImportState()) {
    on<ImportFileRequested>(_onFileRequested);
    on<ImportConfirmed>(_onConfirmed);
    on<ImportReset>(_onReset);
  }

  final FitFilePicker _pickFile;
  final PlanRepository _planRepository;
  final SettingsRepository _settingsRepository;
  final DateTime Function() _now;

  Future<void> _onFileRequested(
    ImportFileRequested event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportState(status: ImportStatus.parsing));

    final PickedFitFile? picked;
    try {
      picked = await _pickFile();
    } on Object catch (error, stackTrace) {
      emit(
        ImportState(
          status: ImportStatus.failure,
          errorMessage: FitParseFailure.unreadable.message,
        ),
      );
      addError(error, stackTrace);
      return;
    }

    // Cancelling is not a failure; go back to where we were.
    if (picked == null) {
      AppLog.info('import', 'picker cancelled');
      emit(const ImportState());
      return;
    }
    AppLog.info('import', 'picked ${picked.name} (${picked.bytes.length} B)');

    try {
      final plan = FitWorkoutParser.parse(
        bytes: picked.bytes,
        filename: picked.name,
        planId: _newPlanId(),
        importedAt: _now(),
      );
      AppLog.info('import', 'parsed "${plan.name}": ${plan.stepCount} steps');
      emit(
        ImportState(
          status: ImportStatus.preview,
          plan: plan,
          filename: picked.name,
        ),
      );
    } on FitParseException catch (error) {
      // Expected for the wrong kind of file: the user sees why, so a warning.
      AppLog.warning('import', 'rejected ${picked.name}', error.message);
      emit(
        ImportState(
          status: ImportStatus.failure,
          filename: picked.name,
          errorMessage: error.message,
        ),
      );
    } on Object catch (error, stackTrace) {
      // The parser is defensive, but a malformed file finding a new path
      // through it must still not take the app down.
      emit(
        ImportState(
          status: ImportStatus.failure,
          filename: picked.name,
          errorMessage: FitParseFailure.corrupt.message,
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _onConfirmed(
    ImportConfirmed event,
    Emitter<ImportState> emit,
  ) async {
    final plan = state.plan;
    if (plan == null) return;

    emit(
      ImportState(
        status: ImportStatus.saving,
        plan: plan,
        filename: state.filename,
      ),
    );

    try {
      await _planRepository.save(plan);

      final settings = await _settingsRepository.load();
      await _settingsRepository.save(settings.copyWith(activePlanId: plan.id));

      AppLog.info('import', 'saved "${plan.name}" as the active plan');
      emit(
        ImportState(
          status: ImportStatus.saved,
          plan: plan,
          filename: state.filename,
        ),
      );
    } on Object catch (error, stackTrace) {
      // Leave storage as it was and let the user try again.
      await _planRepository.clear();
      emit(
        ImportState(
          status: ImportStatus.failure,
          filename: state.filename,
          errorMessage: 'The plan could not be saved. Try importing it again.',
        ),
      );
      addError(error, stackTrace);
    }
  }

  void _onReset(ImportReset event, Emitter<ImportState> emit) {
    emit(const ImportState());
  }

  String _newPlanId() => 'plan-${_now().microsecondsSinceEpoch}';
}
