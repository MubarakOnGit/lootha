
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'providers/dashboard_provider.dart';
import 'services/services.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'firebase_options.dart'; // Will error until config is added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Add Firebase Configuration
  try {
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform, 
     );
  } catch(e) {
     debugPrint("Firebase init failed (expected if no config): $e");
     // We can't proceed easily without firebase for this app structure
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Room Money Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          // User is logged in. 
          // Ideally check Role here. For MVP, assuming Admin for now or fetch member doc.
          // We can fetch the Member model to decide screen.
          return const AdminDashboard(); 
        }
        
        return const LoginScreen();
      },
    );
  }
}

