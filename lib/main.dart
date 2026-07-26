import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/landing_page.dart';
import 'features/home/data/repositories/product_repository.dart';
import 'features/home/presentation/cubit/product_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'core/network/connectivity_provider.dart';
import 'core/storage/sync_queue.dart';
import 'core/services/sync_service.dart';
import 'package:measure_flutter/measure_flutter.dart';

void main() async {
  Provider.debugCheckInvalidValueType = null;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  
  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  await Measure.instance.init(
    () => runApp(const MeasureWidget(child: MyApp())),
    config: const MeasureConfig(
      enableLogging: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => ConnectivityProvider()),
        RepositoryProvider(create: (context) => SyncQueue()),
        RepositoryProvider(
          create: (context) {
             final syncService = SyncService(
                connectivityProvider: context.read<ConnectivityProvider>(),
                syncQueue: context.read<SyncQueue>(),
                firestore: FirebaseFirestore.instance,
             );
             return syncService;
          }
        ),
        RepositoryProvider(create: (context) => ProductRepository(
          syncQueue: context.read<SyncQueue>(),
          connectivityProvider: context.read<ConnectivityProvider>(),
        )),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              authRepository: context.read<AuthRepository>(),
            )..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => ProductCubit(
              productRepository: context.read<ProductRepository>(),
            )..loadFeed(), // Start loading feed immediately
          ),
        ],
        child: MaterialApp(
          title: 'Pass It On',
          theme: AppTheme.lightTheme,
          home: const LandingPage(),
        ),
      ),
    );
  }
}
