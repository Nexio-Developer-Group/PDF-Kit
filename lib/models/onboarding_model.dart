import 'package:flutter/cupertino.dart';

class OnboardingPageModel {
  final String title;
  final String subtitle;
  final Widget content; // your visualization widget

  OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.content,
  });
}
