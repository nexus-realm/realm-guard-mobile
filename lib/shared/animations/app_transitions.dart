import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class AppTransitions {
  static const Duration duration = Duration(milliseconds: 280);
  static const Curve inCurve = Curves.easeOutCubic;
  static const Curve outCurve = Curves.easeInCubic;
  static const Offset slideBeginOffset = Offset(0, 0.04);

  static Widget fadeSlide({
    required Widget child,
    required Animation<double> animation,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: slideBeginOffset,
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }

  static CustomTransitionPage<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: inCurve,
          reverseCurve: outCurve,
        );

        return fadeSlide(child: pageChild, animation: curvedAnimation);
      },
    );
  }
}

