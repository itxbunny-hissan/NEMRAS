import 'package:flutter/rendering.dart';

/// Corner radii from `NEMRAS_UI_Design.html`. `--radius` and `--radius-sm` are
/// declared as tokens there; the rest are the recurring literals used by
/// individual components.
abstract final class NemrasRadii {
  /// `.tag`
  static const double tag = 6;

  /// `.hd-nav-item`, `.hd-nav-item .badge`
  static const double badge = 8;

  /// `--radius-sm`, `.icon-btn`
  static const double small = 10;

  /// `.btn`, `.input`, `.alert-box`, `.perm-item`
  static const double control = 12;

  /// `.kpi`, `.scan-frame`
  static const double metric = 14;

  /// `--radius`, `.card`, `.chs`
  static const double card = 18;

  /// `.risk-pill`, `.chip`
  static const double pill = 20;

  static const BorderRadius tagBorder = BorderRadius.all(Radius.circular(tag));
  static const BorderRadius badgeBorder =
      BorderRadius.all(Radius.circular(badge));
  static const BorderRadius smallBorder =
      BorderRadius.all(Radius.circular(small));
  static const BorderRadius controlBorder =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius metricBorder =
      BorderRadius.all(Radius.circular(metric));
  static const BorderRadius cardBorder =
      BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBorder =
      BorderRadius.all(Radius.circular(pill));
}
