import 'package:coligan_water/views/customer_page.dart';
import 'package:flutter/material.dart';
import 'package:coligan_water/auth.service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'data/_sharedPrefs.dart';
import 'views/login_page.dart';
import 'views/home_page.dart';
import 'location_service.dart';
import 'package:provider/provider.dart';

AuthService appAuth = new AuthService();
final sharedPrefs = SharedPrefs();
void main() async {
  // Set default home.

  // Get result of the login function.
  //bool _result = await appAuth.login();

  // Run app!
  WidgetsFlutterBinding.ensureInitialized();
  await sharedPrefs.init();
  Widget _defaultHome = new LoginScreen();

  if (sharedPrefs.token != "") {
    _defaultHome = new MyApp();
  }

  runApp(new MaterialApp(
    title: 'App',
    home: _defaultHome,
    routes: <String, WidgetBuilder>{
      // Set routes for using the Navigator.
      '/home': (BuildContext context) => new MyApp(),
      '/login': (BuildContext context) => new LoginScreen(),
      '/customer': (BuildContext context) => new CustomerPage(),
    },
  ));
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true;
}
// runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserLocation>(
        initialData: UserLocation(latitude: 0, longitude: 0),
        create: (context) => LocationService().locationStream,
        child: MaterialApp(
          title: 'Flutter Maps',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MapView(),
        ));
  }
}
