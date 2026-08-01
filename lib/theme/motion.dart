import 'package:flutter/animation.dart';

/// Tokens de mouvement Glance. Trois durées suffisent : micro-états,
/// swaps de sous-arbres, et surfaces (modales, toasts).
/// Curves volontairement limitées à la famille easeOut — pas de bounce ni
/// d'overshoot dans cette app.
const kMotionFast = Duration(milliseconds: 150); // coches, segments, busy/label
const kMotionBase = Duration(milliseconds: 200); // swaps, reveals, onglets
const kMotionSlow = Duration(milliseconds: 260); // modales, toasts

const kCurveOut = Curves.easeOut; // micro-états
const kCurveOutCubic = Curves.easeOutCubic; // déplacements, tailles, entrées
