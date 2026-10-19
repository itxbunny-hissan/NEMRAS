import 'package:flutter/material.dart';

import 'colors.dart';

/// Elevation tokens from `NEMRAS_UI_Design.html`.
///
/// The reference is a bordered design rather than a shadowed one: `.card` uses
/// a 1px border and no shadow, and opts into [card] only via `.card.elevated`.
///
/// CSS blur radii are carried over directly as [BoxShadow.blurRadius]. The two
/// units are not strictly equivalent, so these are a close visual match rather
/// than an exact conversion.
abstract final class NemrasShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  /// `.card.elevated`
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.04),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.05),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// `--shadow`
  static const List<BoxShadow> standard = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.06),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.08),
      offset: Offset(0, 8),
      blurRadius: 28,
    ),
  ];

  /// `--shadow-lg`
  static const List<BoxShadow> large = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.10),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color.fromRGBO(11, 31, 42, 0.14),
      offset: Offset(0, 20),
      blurRadius: 60,
    ),
  ];

  /// The shadow colour the tokens above are tinted with.
  static const Color tint = NemrasColors.ink;
}
