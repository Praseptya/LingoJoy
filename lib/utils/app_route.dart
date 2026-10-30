import 'package:flutter/material.dart';

Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      );
    },
  );
}

Future<T?> smoothPush<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(context, smoothRoute<T>(page));
}

Future<T?> smoothReplace<T>(BuildContext context, Widget page) {
  return Navigator.pushReplacement<T, T>(context, smoothRoute<T>(page));
}

Future<T?> smoothClearAndPush<T>(BuildContext context, Widget page) {
  return Navigator.pushAndRemoveUntil<T>(
    context,
    smoothRoute<T>(page),
    (route) => false,
  );
}
