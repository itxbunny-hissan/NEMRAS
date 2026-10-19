/// Spacing scale used across NEMRAS, derived from the padding and gap values
/// in `NEMRAS_UI_Design.html`.
abstract final class NemrasSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double s = 8;
  static const double m = 10;
  static const double l = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double xxxl = 18;
  static const double huge = 20;
  static const double section = 24;

  /// `.card` padding.
  static const double cardPadding = xxl;

  /// `.app-body` padding.
  static const double screenPadding = xxl;

  /// `.app-body` gap between stacked cards.
  static const double stackGap = xl;

  /// `.app-top` horizontal padding.
  static const double barPadding = xxxl;

  /// `.field` bottom margin.
  static const double fieldGap = xl;

  /// `.card-title` bottom margin.
  static const double titleGap = m;
}
