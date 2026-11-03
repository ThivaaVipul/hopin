import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The Board look (docs/PLAN.md, Look): the bus's own destination board, a
/// green-black board with amber lettering. Widgets take colours from here and
/// text styles from the theme, never hard-coded.
@immutable
class HopinColors extends ThemeExtension<HopinColors> {
  const HopinColors({
    required this.page,
    required this.board,
    required this.onBoard,
    required this.onBoardMuted,
    required this.amber,
    required this.onAmber,
    required this.amberDim,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.urgent,
    required this.onBoardUrgent,
  });

  /// The page behind everything that isn't a board.
  final Color page;

  /// Sheets, bars, chips and tiles.
  final Color board;
  final Color onBoard;
  final Color onBoardMuted;

  /// The board's lettering: Sinhala names, progress, the alert.
  final Color amber;
  final Color onAmber;

  /// An unlit board light.
  final Color amberDim;

  /// Text straight on the page.
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color urgent;

  /// Warnings on the board, lighter than [urgent] so they stay readable there.
  final Color onBoardUrgent;

  static const light = HopinColors(
    page: Color(0xFFF2F4F1),
    board: Color(0xFF18241F),
    onBoard: Color(0xFFEEF2EC),
    onBoardMuted: Color(0xFF93A39A),
    amber: Color(0xFFFFB020),
    onAmber: Color(0xFF18241F),
    amberDim: Color(0xFF3A3D2C),
    ink: Color(0xFF18241F),
    inkMuted: Color(0xFF5B6660),
    line: Color(0xFFD5DBD6),
    urgent: Color(0xFFE5484D),
    onBoardUrgent: Color(0xFFFF7A7D),
  );

  static const dark = HopinColors(
    page: Color(0xFF0F1714),
    board: Color(0xFF1C2A24),
    onBoard: Color(0xFFEEF2EC),
    onBoardMuted: Color(0xFF8A9A91),
    amber: Color(0xFFFFB020),
    onAmber: Color(0xFF14201B),
    amberDim: Color(0xFF34382A),
    ink: Color(0xFFEEF2EC),
    inkMuted: Color(0xFF8A9A91),
    line: Color(0xFF26332D),
    urgent: Color(0xFFFF6B6E),
    onBoardUrgent: Color(0xFFFF7A7D),
  );

  @override
  HopinColors copyWith({
    Color? page,
    Color? board,
    Color? onBoard,
    Color? onBoardMuted,
    Color? amber,
    Color? onAmber,
    Color? amberDim,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? urgent,
    Color? onBoardUrgent,
  }) => HopinColors(
    page: page ?? this.page,
    board: board ?? this.board,
    onBoard: onBoard ?? this.onBoard,
    onBoardMuted: onBoardMuted ?? this.onBoardMuted,
    amber: amber ?? this.amber,
    onAmber: onAmber ?? this.onAmber,
    amberDim: amberDim ?? this.amberDim,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    line: line ?? this.line,
    urgent: urgent ?? this.urgent,
    onBoardUrgent: onBoardUrgent ?? this.onBoardUrgent,
  );

  @override
  HopinColors lerp(HopinColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return HopinColors(
      page: mix(page, other.page),
      board: mix(board, other.board),
      onBoard: mix(onBoard, other.onBoard),
      onBoardMuted: mix(onBoardMuted, other.onBoardMuted),
      amber: mix(amber, other.amber),
      onAmber: mix(onAmber, other.onAmber),
      amberDim: mix(amberDim, other.amberDim),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      line: mix(line, other.line),
      urgent: mix(urgent, other.urgent),
      onBoardUrgent: mix(onBoardUrgent, other.onBoardUrgent),
    );
  }
}

/// Shared timings and curves, so motion feels like one app.
@immutable
class HopinMotion extends ThemeExtension<HopinMotion> {
  const HopinMotion({
    this.quick = const Duration(milliseconds: 150),
    this.base = const Duration(milliseconds: 240),
    this.slow = const Duration(milliseconds: 420),
    this.ease = Curves.easeOutCubic,
  });

  /// Small state changes: a pressed button, a colour.
  final Duration quick;

  /// Things that move: a sheet, a page.
  final Duration base;

  /// Moments: the board lighting up.
  final Duration slow;
  final Curve ease;

  @override
  HopinMotion copyWith({
    Duration? quick,
    Duration? base,
    Duration? slow,
    Curve? ease,
  }) => HopinMotion(
    quick: quick ?? this.quick,
    base: base ?? this.base,
    slow: slow ?? this.slow,
    ease: ease ?? this.ease,
  );

  @override
  HopinMotion lerp(HopinMotion? other, double t) {
    if (other == null) return this;
    Duration mix(Duration a, Duration b) => Duration(
      microseconds: lerpDouble(a.inMicroseconds, b.inMicroseconds, t)!.round(),
    );
    return HopinMotion(
      quick: mix(quick, other.quick),
      base: mix(base, other.base),
      slow: mix(slow, other.slow),
      ease: t < 0.5 ? ease : other.ease,
    );
  }
}

/// Type roles: Barlow Semi Condensed for numbers and headings (signage),
/// Barlow for text. Tamil falls back to Anek Tamil and Sinhala to Noto Sans
/// Sinhala, so mixed lines render without switching families by hand.
const _text = 'Barlow';
const _display = 'Barlow Semi Condensed';
const sinhalaFamily = 'Noto Sans Sinhala';
const _fallback = ['Anek Tamil', sinhalaFamily];

ThemeData hopinTheme(Brightness brightness) {
  final c = brightness == Brightness.light
      ? HopinColors.light
      : HopinColors.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.amber,
    onPrimary: c.onAmber,
    secondary: c.board,
    onSecondary: c.onBoard,
    surface: c.page,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    outline: c.line,
    error: c.urgent,
    onError: c.page,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.page,
    fontFamily: _text,
    fontFamilyFallback: _fallback,
    extensions: [c, const HopinMotion()],
  );
  TextStyle? display(TextStyle? style, FontWeight weight) => style?.copyWith(
    fontFamily: _display,
    fontFamilyFallback: _fallback,
    fontWeight: weight,
  );
  final t = base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink);
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.board,
      contentTextStyle: t.bodyLarge?.copyWith(
        color: c.onBoard,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    textTheme: t.copyWith(
      displayLarge: display(t.displayLarge, FontWeight.w700),
      displayMedium: display(t.displayMedium, FontWeight.w700),
      displaySmall: display(t.displaySmall, FontWeight.w700),
      headlineLarge: display(t.headlineLarge, FontWeight.w700),
      headlineMedium: display(t.headlineMedium, FontWeight.w700),
      headlineSmall: display(t.headlineSmall, FontWeight.w600),
      titleLarge: display(t.titleLarge, FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    ),
  );
}

extension HopinTheme on BuildContext {
  HopinColors get colors => Theme.of(this).extension<HopinColors>()!;
  HopinMotion get motion => Theme.of(this).extension<HopinMotion>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
