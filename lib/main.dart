
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'providers/dashboard_provider.dart';
import 'services/services.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/member_dashboard.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data!;
          
          // Role Based Routing
          // We need to wait for DashboardProvider to load members to find "me".
          // Or we can use a FutureBuilder here to fetch the single member doc.
          // Using Consumer<DashboardProvider> is easier if it's already fetching.
          
          return Consumer<DashboardProvider>(
            builder: (context, provider, child) {
               if (provider.isLoading) {
                 return const Scaffold(body: Center(child: CircularProgressIndicator()));
               }
               
                // Find me
               try {
                 if (provider.members.isEmpty) {
                    // Bootstrap: First user is Admin
                    return const AdminDashboard();
                 }
                 
                 final me = provider.members.firstWhere((m) => m.email == user.email);
                 if (me.role == 'admin') {
                   return AdminDashboard();
                 } else {
                   return MemberDashboard();
                 }
               } catch (e) {
                 // Member not found or logic error.
                 return MemberDashboard();
               }
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}

