import 'package:flutter/material.dart';
import 'package:farm/screens/splash/splash_screen.dart';
import 'package:farm/screens/onboarding/onboarding_screen.dart';
import 'package:farm/screens/auth/user_type_screen.dart';
import 'package:farm/screens/auth/auth_screen.dart';
import 'package:farm/screens/home/home_screen.dart';
import 'package:farm/screens/crops/crops_screen.dart';
import 'package:farm/screens/crops/crop_form_screen.dart';
import 'package:farm/screens/iot/iot_dashboard_screen.dart';
import 'package:farm/screens/irrigation/irrigation_screen.dart';
import 'package:farm/screens/irrigation/irrigation_config_screen.dart';
import 'package:farm/screens/finance/finance_screen.dart';
import 'package:farm/screens/market/market_screen.dart';
import 'package:farm/screens/weather/weather_screen.dart';
import 'package:farm/screens/weather/weather_history_screen.dart';
import 'package:farm/screens/irrigation/irrigation_history_screen.dart';
import 'package:farm/screens/robot/robot_control_screen.dart';
import 'package:farm/screens/robot/disease_history_screen.dart';
import 'package:farm/screens/agribot/agribot_screen.dart';
import 'package:farm/screens/market/market_product_form_screen.dart';
import 'package:farm/models/market_product.dart';
import 'package:farm/models/irrigation_config.dart';
import 'package:farm/screens/market/supplier_market_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const SplashScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/user-type': (context) => const UserTypeScreen(),
  '/auth': (context) => const AuthScreen(),
  '/home': (context) => const HomeScreen(),
  '/crops': (context) => const CropsScreen(),
  '/crops/add': (context) => const CropFormScreen(),
  '/crops/edit': (context) {
    final crop = ModalRoute.of(context)?.settings.arguments;
    return CropFormScreen(crop: crop);
  },
  '/iot': (context) => const IoTDashboardScreen(),
  '/irrigation': (context) => const IrrigationScreen(),
  '/irrigation/config': (context) {
    final config =
        ModalRoute.of(context)?.settings.arguments as IrrigationConfig?;
    return IrrigationConfigScreen(config: config);
  },
  '/finance': (context) => const FinanceScreen(),
  '/market': (context) => const MarketScreen(),
  '/weather': (context) => const WeatherScreen(),
  '/weather/history': (context) => const WeatherHistoryScreen(),
  '/irrigation/history': (context) => const IrrigationHistoryScreen(),
  '/robot': (context) => const RobotControlScreen(),
  '/disease-history': (context) => const DiseaseHistoryScreen(),
  '/agribot': (context) => const AgribotScreen(),
  '/market/add': (context) {
    final product =
        ModalRoute.of(context)?.settings.arguments as MarketProduct?;
    return MarketProductFormScreen(product: product);
  },
  '/supplier-market': (context) => const SupplierMarketScreen(),
};
