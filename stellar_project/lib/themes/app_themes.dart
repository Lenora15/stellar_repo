// This file contains all of the themes for different times of day for the app. 
// for clerificaton purposes, images used in these themes are AI generated and not created by the developers of this app.
import 'package:flutter/material.dart';

class AppThemeData {
  final ThemeData theme;
  final String backgroundImage;
  AppThemeData({required this.theme, required this.backgroundImage});
}

// Themes. pulling images from another file as the main background image
//themes will also include text at the top of the screen with a greeting and date. 

class AppThemes{
  static final morning = AppThemeData(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    ),
    backgroundImage: 'lib/themes/images/morning.jpg',
  );
  static final afternoon = AppThemeData(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: Brightness.light,
      ),
    ),
    backgroundImage: 'lib/themes/images/afternoon.jpg',
  );
  static final evening = AppThemeData(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      ),
    ),
    backgroundImage: 'lib/themes/images/evening.jpg',
  );
  static final night = AppThemeData(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
    ),
    backgroundImage: 'lib/themes/images/night.jpg',
  );

  // depending on the time of day, the app's theme will change,
  // for example morning might be a series of light blues

  static AppThemeData getThemeForTimeOfDay() {
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute;

      if ((hour > 5 || (hour == 5 && minute >= 1)) && (hour < 12 || (hour == 12 && minute == 0))) {
        return morning;
      } 
      else if ((hour > 12 || (hour == 12 && minute >= 1)) && (hour < 17 || (hour == 17 && minute == 0))) {
        return afternoon;
      } 
      else if ((hour > 17 || (hour == 17 && minute >= 1)) && (hour < 21 || (hour == 21 && minute == 0))) {
        return evening;
      } 
      else {
        return night;
      }
    }
}