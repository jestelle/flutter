// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect, VoidCallback;

import 'animation.dart';
import 'animations.dart';
import 'curves.dart';

/// An object that can produce a value of type T given an [Animation] as input.
abstract class Animatable<T> {
  const Animatable();

  /// The current value of this object for the given animation.
  T evaluate(Animation<double> animation);

  /// Returns a new Animation that is driven by the given animation but that
  /// takes on values determined by this object.
  Animation<T> animate(Animation<double> parent) {
    return new _AnimatedEvaluation<T>(parent, this);
  }

  /// Returns a new Animatable whose value is determined by first evaluating
  /// the given parent and then evaluating this object.
  Animatable<T> chain(Animatable<double> parent) {
    return new _ChainedEvaluation<T>(parent, this);
  }
}

class _AnimatedEvaluation<T> extends Animation<T> with AnimationWithParentMixin<double> {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  /// The animation from which this value is derived.
  final Animation<double> parent;

  final Animatable<T> _evaluatable;

  T get value => _evaluatable.evaluate(parent);
}

class _ChainedEvaluation<T> extends Animatable<T> {
  _ChainedEvaluation(this._parent, this._evaluatable);

  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;

  T evaluate(Animation<double> animation) {
    double value = _parent.evaluate(animation);
    return _evaluatable.evaluate(new AlwaysStoppedAnimation(value));
  }
}

/// A linear interpolation between a beginning and ending value.
class Tween<T extends dynamic> extends Animatable<T> {
  Tween({ this.begin, this.end });

  /// The value this variable has at the beginning of the animation.
  T begin;

  /// The value this variable has at the end of the animation.
  T end;

  /// Returns the value this variable has at the given animation clock value.
  T lerp(double t) => begin + (end - begin) * t;

  /// Returns the interpolated value for the current value of the given animation.
  T evaluate(Animation<double> animation) {
    if (end == null)
      return begin;
    double t = animation.value;
    if (t == 0.0)
      return begin;
    if (t == 1.0)
      return end;
    return lerp(t);
  }
}

/// An interpolation between two colors.
///
/// This class specializes the interpolation of Tween<Color> to be
/// appropriate for colors.
class ColorTween extends Tween<Color> {
  ColorTween({ Color begin, Color end }) : super(begin: begin, end: end);

  Color lerp(double t) => Color.lerp(begin, end, t);
}

/// An interpolation between two sizes.
///
/// This class specializes the interpolation of Tween<Size> to be
/// appropriate for rectangles.
class SizeTween extends Tween<Size> {
  SizeTween({ Size begin, Size end }) : super(begin: begin, end: end);

  Size lerp(double t) => Size.lerp(begin, end, t);
}

/// An interpolation between two rectangles.
///
/// This class specializes the interpolation of Tween<Rect> to be
/// appropriate for rectangles.
class RectTween extends Tween<Rect> {
  RectTween({ Rect begin, Rect end }) : super(begin: begin, end: end);

  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

/// An interpolation between two integers.
///
/// This class specializes the interpolation of Tween<int> to be
/// appropriate for integers by interpolating between the given begin and end
/// values and then rounding the result to the nearest integer.
class IntTween extends Tween<int> {
  IntTween({ int begin, int end }) : super(begin: begin, end: end);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  int lerp(double t) => (begin + (end - begin) * t).round();
}

/// Transforms the value of the given animation by the given curve.
///
/// This class differs from [CurvedAnimation] in that [CurvedAnimation] applies
/// a curve to an existing [Animation] object whereas [CurveTween] can be
/// chained with another [Tween] prior to receiving the underlying [Animation].
class CurveTween extends Animatable<double> {
  CurveTween({ this.curve });

  /// The curve to use when transforming the value of the animation.
  Curve curve;

  double evaluate(Animation<double> animation) {
    double t = animation.value;
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }
}
