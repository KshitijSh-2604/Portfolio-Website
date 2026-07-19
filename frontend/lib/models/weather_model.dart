import 'package:flutter/material.dart';

enum WeatherCondition {
  clear,
  sunny,
  clouds,
  sunnyClouds,
  rain,
  heavyRain,
  drizzle,
  thunderstorm,
  rainThunder,
  snow,
  mist,
  haze,
  fog,
  unknown,
}

class WeatherModel {
  final WeatherCondition condition;
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String location;

  WeatherModel({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    this.location = "Delhi",
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final condStr = (json['condition'] as String? ?? 'Clear').toLowerCase();
    final desc = (json['description'] as String? ?? '').toLowerCase();
    
    WeatherCondition cond;
    if (condStr.contains('thunder')) {
      cond = desc.contains('rain') ? WeatherCondition.rainThunder : WeatherCondition.thunderstorm;
    } else if (condStr.contains('rain')) {
      cond = desc.contains('heavy') ? WeatherCondition.heavyRain : WeatherCondition.rain;
    } else if (condStr.contains('drizzle')) {
      cond = WeatherCondition.drizzle;
    } else if (condStr.contains('snow')) {
      cond = WeatherCondition.snow;
    } else if (condStr.contains('clear')) {
      cond = desc.contains('cloud') ? WeatherCondition.sunnyClouds : WeatherCondition.sunny;
    } else if (condStr.contains('cloud')) {
      cond = WeatherCondition.clouds;
    } else if (condStr.contains('mist')) {
      cond = WeatherCondition.mist;
    } else if (condStr.contains('haze')) {
      cond = WeatherCondition.haze;
    } else if (condStr.contains('fog')) {
      cond = WeatherCondition.fog;
    } else {
      cond = WeatherCondition.unknown;
    }

    return WeatherModel(
      condition: cond,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 30,
      feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 30,
      description: json['description'] as String? ?? 'clear sky',
      icon: json['icon'] as String? ?? '01d',
      humidity: json['humidity'] as int? ?? 50,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 2.0,
      location: json['location'] as String? ?? "Delhi",
    );
  }

  // Theme colors derived from weather condition
  List<Color> get backgroundGradient {
    switch (condition) {
      case WeatherCondition.sunny:
        return [
          const Color(0xFFF2994A), // Muted Orange
          const Color(0xFFE2B04E), // Muted Gold
          const Color(0xFF1E293B), // Dark Navy bottom to ground the layout
        ];
      case WeatherCondition.clear:
        return [
          const Color(0xFF0F0C29), // Deep Midnight
          const Color(0xFF302B63), // Royal Blue
          const Color(0xFF24243E), // Galactic Purple
        ];
      case WeatherCondition.sunnyClouds:
        return [
          const Color(0xFF4CA1AF), // Daylight Blue
          const Color(0xFFC4E0E5), // Soft Sky
          const Color(0xFFFFFFFF), // Bright White
        ];
      case WeatherCondition.rain:
        return [
          const Color(0xFF0F2027), // Deepest Storm
          const Color(0xFF203A43), // Stormy Grey-Blue
          const Color(0xFF2C5364), // Dark Ocean
        ];
      case WeatherCondition.drizzle:
        return [
          const Color(0xFF606C88), // Soft Slate
          const Color(0xFF3F4C6B), // Misty Blue
          const Color(0xFF2C3E50), // Grounded Grey
        ];
      case WeatherCondition.heavyRain:
      case WeatherCondition.rainThunder:
        return [
          const Color(0xFF0F2027), // Deep Grey
          const Color(0xFF203A43), // Muddy Teal
          const Color(0xFF2C5364), // Dark Water
        ];
      case WeatherCondition.thunderstorm:
        return [
          const Color(0xFF000000), // Pure Black
          const Color(0xFF141E30), // Deepest Navy
          const Color(0xFF31003E), // Electric Purple
        ];
      case WeatherCondition.clouds:
        return [
          const Color(0xFF1F1C2C), // Dusk
          const Color(0xFF312E4A), // Steel Cloud
          const Color(0xFF4C4A6E), // Soft Lavender
        ];
      case WeatherCondition.snow:
        return [
          const Color(0xFF83A4D4), // Deep Frost
          const Color(0xFFB6FBFF), // Light Snow
          const Color(0xFF2C3E50), // Cold Anchor
        ];
      case WeatherCondition.mist:
        return [
          const Color(0xFF203A43), // Deep Teal
          const Color(0xFF2C5364), // Cold Grey
          const Color(0xFF0F2027), // Deepest Grey
        ];
      case WeatherCondition.haze:
        return [
          const Color(0xFF3E5151), // Dusty Slate
          const Color(0xFFDECBA4), // Warm Sand
          const Color(0xFF3E5151), // Dusty Slate
        ];
      case WeatherCondition.fog:
        return [
          const Color(0xFF606C88), // Dense Blue-Grey
          const Color(0xFF3F4C6B), // Stormy Grey
          const Color(0xFF232526), // Charcoal
        ];
      case WeatherCondition.unknown:
        return [
          const Color(0xFF0A0A14),
          const Color(0xFF12121E),
          const Color(0xFF1A1A2E),
        ];
    }
  }

  Color get accentColor {
    switch (condition) {
      case WeatherCondition.sunny:
        return const Color(0xFFFF6D00); // Vibrant Orange
      case WeatherCondition.clear:
        return const Color(0xFFFFD600); // Amber Gold
      case WeatherCondition.sunnyClouds:
        return const Color(0xFF03A9F4); // Sky Blue
      case WeatherCondition.rain:
        return const Color(0xFF00E5FF); // Vibrant Cyan for Rain
      case WeatherCondition.drizzle:
        return const Color(0xFF90A4AE); // Muted Blue-Grey for Drizzle
      case WeatherCondition.heavyRain:
        return const Color(0xFF00B0FF); // Deep Blue
      case WeatherCondition.thunderstorm:
      case WeatherCondition.rainThunder:
        return const Color(0xFFE040FB); // Magenta
      case WeatherCondition.clouds:
        return const Color(0xFFCFD8DC); // Cool Silver
      case WeatherCondition.snow:
        return const Color(0xFFE1F5FE); // Frost Blue
      case WeatherCondition.mist:
      case WeatherCondition.haze:
      case WeatherCondition.fog:
        return const Color(0xFFB0BEC5); // Fog Silver
      case WeatherCondition.unknown:
        return const Color(0xFF7C4DFF);
    }
  }

  bool get isLightBackground {
    // Sunny, SunnyClouds, Snow and Haze are light backgrounds
    return condition == WeatherCondition.sunny ||
           condition == WeatherCondition.sunnyClouds || 
           condition == WeatherCondition.snow ||
           condition == WeatherCondition.haze;
  }

  Color get primaryTextColor => isLightBackground ? const Color(0xFF000000) : Colors.white;
  Color get secondaryTextColor => isLightBackground ? const Color(0xFF1E293B) : Colors.white70;
  Color get tertiaryTextColor => isLightBackground ? const Color(0xFF475569) : Colors.white54;
  Color get glassColor => isLightBackground ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.04);
  Color get glassBorderColor => isLightBackground ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.08);

  Color get onAccentColor {
    return accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  String get weatherEmoji {
    switch (condition) {
      case WeatherCondition.sunny: return '☀️';
      case WeatherCondition.clear: return '🌙';
      case WeatherCondition.clouds: return '☁️';
      case WeatherCondition.sunnyClouds: return '🌤️';
      case WeatherCondition.rain: return '🌧️';
      case WeatherCondition.heavyRain: return '⛈️';
      case WeatherCondition.drizzle: return '🌦️';
      case WeatherCondition.thunderstorm: return '🌩️';
      case WeatherCondition.rainThunder: return '⛈️';
      case WeatherCondition.snow: return '❄️';
      case WeatherCondition.mist: return '🌫️';
      case WeatherCondition.haze: return '🌁';
      case WeatherCondition.fog: return '🌫️';
      case WeatherCondition.unknown: return '🌤️';
    }
  }

  WeatherModel copyWith({
    WeatherCondition? condition,
    double? temperature,
    double? feelsLike,
    String? description,
    String? icon,
    int? humidity,
    double? windSpeed,
    String? location,
  }) {
    return WeatherModel(
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      location: location ?? this.location,
    );
  }
}
