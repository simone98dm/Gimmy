/// The color themes the user can pick in Settings. Each one supplies a full
/// light and dark palette; light / dark / system is chosen separately.
///
/// The enum `name` is what gets persisted, so renaming a value loses the
/// user's choice — add, don't rename.
enum GimmyThemeId {
  hackerGreen('Hacker Green'),
  sophisticatedBlue('Sophisticated Blue');

  const GimmyThemeId(this.label);

  final String label;

  static const fallback = GimmyThemeId.hackerGreen;

  /// Unknown or missing names (a file from a newer build) fall back quietly.
  static GimmyThemeId fromName(String? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => fallback);
}
