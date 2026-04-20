import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/navigation_helper.dart';
import 'package:vehicle_registration_app/screens/booking_dashboard_screen.dart';
import 'package:vehicle_registration_app/screens/homescreen.dart';
import 'package:vehicle_registration_app/screens/otp_verification_screen.dart';
import 'package:vehicle_registration_app/screens/register_password_screen.dart';
import 'package:vehicle_registration_app/screens/staff_home_screen.dart';
import 'package:vehicle_registration_app/screens/vehicle_management_screen.dart';
import 'package:vehicle_registration_app/screens/add_vehicle_screen.dart';
import 'package:vehicle_registration_app/screens/appointment_chat_screen.dart';
import 'package:vehicle_registration_app/screens/order_tracking_screen.dart';
import 'package:vehicle_registration_app/screens/orders_screen.dart';
import 'package:vehicle_registration_app/models/saved_session.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'screens/loginscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (chứa GOOGLE_MAPS_API_KEY và các key khác)

  NavigationHelper.navigatorKey = GlobalKey<NavigatorState>();
  SavedSession? session;
  try {
    await AuthStorage.init();
    session = await AuthStorage.getSavedSession();
    if (session != null) {
      ApiClient.instance.setAuthToken(session.token);
    }
  } catch (_) {
    // MissingPluginException khi hot restart sau khi thêm shared_preferences: cần stop app rồi Run lại.
    session = null;
  }
  runApp(MyApp(initialRoute: session?.route ?? '/login'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = '/login'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationHelper.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/staffHome': (context) => const StaffHomeScreen(),
        '/bookingDashBoard': (context) => const BookingDashboardScreen(),
        '/vehicleManagement': (context) => const VehicleManagementScreen(),
        '/addVehicle': (context) => const AddVehicleScreen(),
        '/appointmentChat': (context) => const AppointmentChatScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/orderTracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final map = args is Map ? Map<String, dynamic>.from(args as Map) : null;
          return OrderTrackingScreen(
            orderId: map?['orderId']?.toString() ?? '29A-12345',
            stationName: map?['stationName']?.toString() ?? 'TT Đăng kiểm 29-03D',
            stationAddress: map?['stationAddress']?.toString() ?? 'Số 8 Phạm Hùng, Cầu Giấy, HN',
            appointmentDate: map?['appointmentDate']?.toString() ?? '15/02/2026',
            appointmentTime: map?['appointmentTime']?.toString() ?? '09:00 - 10:00',
            completedSteps: map?['completedSteps'] is int ? map!['completedSteps'] as int : 2,
            staffPhone: map?['staffPhone']?.toString(),
          );
        },
        '/otp': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final map = args is Map ? Map<String, dynamic>.from(args as Map) : null;
          final phone = map?['phone']?.toString() ?? '';
          final purpose = map?['purpose']?.toString() ?? 'register';
          return OTPVerificationScreen(phoneNumber: phone, purpose: purpose);
        },
        '/registerPassword': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final map = args is Map ? Map<String, dynamic>.from(args as Map) : null;
          final phone = map?['phone']?.toString() ?? '';
          final otpCode = map?['otp_code']?.toString() ?? '';
          return RegisterPasswordScreen(phoneNumber: phone, otpCode: otpCode);
        },
      },
    );
  }
}
