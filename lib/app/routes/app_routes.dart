import 'package:flutter/material.dart';

class AppRoutes {
  /// Push a new screen onto the navigation stack
  static void push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Replace the current screen with a new one
  static void pushReplacement(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Push a new screen and remove all previous screens from the stack
  static void pushAndRemoveUntil(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (Route<dynamic> route) => false,
    );
  }

  /// Pop the current screen
  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Pop back to the first/root screen
  static void popToFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
