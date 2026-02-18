import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs
  static const Color primaryColor = Color(0xFF2E7D32); // Vert
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Color(0xFFE8F5E9); // Beige/vert clair
  static const Color beigeColor = Color(0xFFEEE0C9);  // Beige clair
  static const Color darkBeigeColor = Color(0xFFD4B499);  // Beige plus sombre
  static const Color buttonColor = Color(0xFF4CAF50); // Couleur du bouton "Accéder"
  
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          elevation: 0,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(
          color: Colors.black87,
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // IconButton Theme
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(buttonColor),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return beigeColor; // Utiliser la couleur beige pour le switch activé
          }
          return Colors.grey[300]; // Couleur par défaut pour le switch désactivé
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor; // Couleur du bouton quand activé
          }
          return Colors.grey[400]; // Couleur du bouton quand désactivé
        }),
      ),
    );
  }

  // Styles réutilisables
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
    );
  }

  static BoxDecoration get whiteCardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static TextStyle get titleStyle {
    return const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }

  static TextStyle get subtitleStyle {
    return const TextStyle(
      fontSize: 14,
      color: Colors.black54,
    );
  }

  // Style pour les icônes circulaires
  static BoxDecoration get circleIconDecoration {
    return const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    );
  }
}

// Extension pour les couleurs personnalisées
class _CustomTheme extends ThemeExtension<_CustomTheme> {
  final Color featureCardColor;
  final Color featureCardTextColor;
  final Color weatherCardColor;
  final Color weatherTextColor;

  _CustomTheme({
    required this.featureCardColor,
    required this.featureCardTextColor,
    required this.weatherCardColor,
    required this.weatherTextColor,
  });

  @override
  ThemeExtension<_CustomTheme> copyWith({
    Color? featureCardColor,
    Color? featureCardTextColor,
    Color? weatherCardColor,
    Color? weatherTextColor,
  }) {
    return _CustomTheme(
      featureCardColor: featureCardColor ?? this.featureCardColor,
      featureCardTextColor: featureCardTextColor ?? this.featureCardTextColor,
      weatherCardColor: weatherCardColor ?? this.weatherCardColor,
      weatherTextColor: weatherTextColor ?? this.weatherTextColor,
    );
  }

  @override
  ThemeExtension<_CustomTheme> lerp(_CustomTheme? other, double t) {
    if (other is! _CustomTheme) return this;
    return _CustomTheme(
      featureCardColor: Color.lerp(featureCardColor, other.featureCardColor, t)!,
      featureCardTextColor: Color.lerp(featureCardTextColor, other.featureCardTextColor, t)!,
      weatherCardColor: Color.lerp(weatherCardColor, other.weatherCardColor, t)!,
      weatherTextColor: Color.lerp(weatherTextColor, other.weatherTextColor, t)!,
    );
  }
}