import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {

  static ThemeData lightTheme = ThemeData(

    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    colorSchemeSeed: AppColors.primary,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),

    inputDecorationTheme: InputDecorationTheme(

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),

    ),

    elevatedButtonTheme: ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        minimumSize: const Size(double.infinity, 55),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

      ),

    ),

  );

}