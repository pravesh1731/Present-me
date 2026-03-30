// Helpers
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void pushSlide(BuildContext context, Widget page) {
  Navigator.of(context).pop();
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: offset, child: child),
        );
      },
    ),
  );
}


void placeholder(BuildContext context, String message) {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}