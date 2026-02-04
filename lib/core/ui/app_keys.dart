import 'package:flutter/material.dart';

final rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final filesNavKey = GlobalKey<NavigatorState>(debugLabel: 'files');
final settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();
