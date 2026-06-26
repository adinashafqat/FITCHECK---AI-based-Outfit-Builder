import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator_web/geolocator_web.dart';

class AppColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFFB6C1);
  static const Color surface = Color(0xFF2D2D44);
  static const Color textDark = Color(0xFFE6E6FA);
  static const Color textLight = Color(0xFFB0B0D0);
  static const Color danger = Color(0xFFFF6B8B);
  static const Color success = Color(0xFF4DB6AC);
  static const Color warning = Color(0xFFFFD166);
}

class AICommentService {
  static String getWeatherComment(String weatherMode, double? temperature) {
    switch (weatherMode) {
      case 'Summer':
        return _getSummerComment(temperature);
      case 'Winter':
        return _getWinterComment(temperature);
      case 'All Year':
        return _getAllYearComment(temperature);
      default:
        return 'Enjoy your day! 👕';
    }
  }

  static String _getSummerComment(double? temp) {
    final comments = [
      if (temp != null && temp >= 30)
        "🔥 Scorching hot! Choose lightweight, breathable fabrics like cotton or linen.",
      if (temp != null && temp >= 25)
        "☀️ It's hot! Opt for short sleeves, shorts, and light colors to stay cool.",
      if (temp != null && temp >= 20)
        "🌤️ Warm and sunny! Perfect for t-shirts and summer dresses.",
      "😎 Beat the heat! Don't forget sunscreen and a hat!",
      "👕 Light layers are your best friend in this weather!",
      "🎽 Stay cool with moisture-wicking fabrics today!",
      "🕶️ Sunglasses are a must! Protect those eyes from the sun.",
      "👟 Choose breathable footwear to keep your feet cool!",
    ];
    return _getRandomComment(comments);
  }

  static String _getWinterComment(double? temp) {
    final comments = [
      if (temp != null && temp <= 0)
        "❄️ Freezing cold! Layer up with thermal wear, heavy coats, and don't forget gloves!",
      if (temp != null && temp <= 5)
        "🥶 Very chilly! Time for sweaters, jackets, and warm accessories.",
      if (temp != null && temp <= 10)
        "🧥 Cold outside! Perfect weather for cozy layers and warm fabrics.",
      "🧣 Stay warm! Layer up with thermal tops and cozy sweaters.",
      "🧤 Don't forget your hat and gloves - it's cold out there!",
      "🧦 Warm socks are essential for this chilly weather!",
      "🧥 A good jacket will keep you comfortable all day!",
      "🔥 Cozy sweaters and thick fabrics are perfect today!",
    ];
    return _getRandomComment(comments);
  }

  static String _getAllYearComment(double? temp) {
    final comments = [
      if (temp != null && temp >= 20)
        "😊 Pleasant weather! Light layers would work perfectly today.",
      if (temp != null && temp <= 15)
        "🌥️ Mildly cool! A light jacket or sweater would be comfortable.",
      "✨ Perfect weather to wear whatever you like!",
      "🌈 Mix and match your favorite pieces today!",
      "👚 Comfort is key in this pleasant weather!",
      "👖 Versatile weather means more outfit options!",
      "🎯 Express your style without weather constraints!",
      "👗 Wear what makes you feel confident and comfortable!",
    ];
    return _getRandomComment(comments);
  }

  static String _getRandomComment(List<String> comments) {
    if (comments.isEmpty) return "Enjoy your outfit! 👕";
    final random = comments..shuffle();
    return random.first;
  }

  static String getDailyFashionTip() {
    final tips = [
      "Mix textures for a more interesting outfit!",
      "Balance loose tops with fitted bottoms",
      "Don't be afraid to experiment with colors",
      "Accessories can transform a simple outfit",
      "Layering adds depth and versatility",
      "Fit is more important than following trends",
      "Sunglasses instantly elevate any look",
      "Tailored pieces always look polished",
      "A statement accessory can be a conversation starter",
      "Comfort doesn't have to mean sacrificing style",
    ];
    final random = tips..shuffle();
    return random.first;
  }

}

class WeatherService {
  static const String _apiKey = '686539a2cc674ca0990143012252212';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  static Future<WeatherData?> getCurrentWeather(String? city) async {
    try {
      String location = city ?? 'London';

      final response = await http.get(
          Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$location')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData(
          temperature: data['current']['temp_c'].toDouble(),
          condition: data['current']['condition']['text'],
          location: data['location']['name'],
          iconUrl: 'https:${data['current']['condition']['icon']}',
        );
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }

  static Future<WeatherData?> getWeatherByCity(String city) async {
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$city')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData(
          temperature: data['current']['temp_c'].toDouble(),
          condition: data['current']['condition']['text'],
          location: data['location']['name'],
          iconUrl: 'https:${data['current']['condition']['icon']}',
        );
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    return null;
  }

  static String getWeatherModeFromTemperature(double tempCelsius) {
    if (tempCelsius >= 25) {
      return 'Summer';
    } else if (tempCelsius <= 10) {
      return 'Winter';
    } else {
      return 'All Year';
    }
  }
}

class WeatherData {
  final double temperature;
  final String condition;
  final String location;
  final String iconUrl;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.iconUrl,
  });
}

extension WeatherFiltering on DatabaseService {
  Future<void> updateAndApplyWeatherFilter() async {
    try {
      final savedCity = getPreferredCity();
      final weatherData = await WeatherService.getCurrentWeather(savedCity);
      if (weatherData != null) {
        final weatherMode = WeatherService.getWeatherModeFromTemperature(weatherData.temperature);
        await setWeatherMode(weatherMode);

        await _box.put('current_weather_$uid', {
          'temperature': weatherData.temperature,
          'condition': weatherData.condition,
          'location': weatherData.location,
          'iconUrl': weatherData.iconUrl,
          'mode': weatherMode,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Failed to update weather filter: $e');
    }
  }

  String getEffectiveWeatherMode() {
    final storedMode = getWeatherMode();

    if (storedMode == 'All Year') {
      final weatherData = _box.get('current_weather_$uid');
      if (weatherData != null && weatherData is Map) {
        return weatherData['mode'] ?? 'All Year';
      }
    }
    return storedMode;
  }

  List<Map<dynamic, dynamic>> getWeatherFilteredItems() {
    final allItems = getUserItems();
    final effectiveMode = getEffectiveWeatherMode();

    return allItems.where((item) {
      final season = item['season'] ?? 'All Year';

      if (effectiveMode == 'Summer') {
        return season != 'Winter';
      } else if (effectiveMode == 'Winter') {
        return season != 'Summer';
      } else {
        return true;
      }
    }).toList();
  }

  WeatherData? getStoredWeatherData() {
    final data = _box.get('current_weather_$uid');
    if (data != null && data is Map) {
      return WeatherData(
        temperature: data['temperature']?.toDouble() ?? 20.0,
        condition: data['condition'] ?? 'Unknown',
        location: data['location'] ?? 'Unknown',
        iconUrl: data['iconUrl'] ?? '',
      );
    }
    return null;
  }

  bool isItemSuitableForWeather(Map item) {
    final effectiveMode = getEffectiveWeatherMode();
    final season = item['season'] ?? 'All Year';

    if (effectiveMode == 'Summer') {
      return season != 'Winter';
    } else if (effectiveMode == 'Winter') {
      return season != 'Summer';
    } else {
      return true;
    }
  }

  String getWeatherAIComment() {
    final weatherData = getStoredWeatherData();
    final effectiveMode = getEffectiveWeatherMode();

    return AICommentService.getWeatherComment(
      effectiveMode,
      weatherData?.temperature,
    );
  }

  String getDailyFashionTip() {
    return AICommentService.getDailyFashionTip();
  }

}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Platform not supported');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5QnxbZlWtBN0rA4F_-ofMprqlcungNZs',
    appId: '1:440680002716:web:f6d9b16ca06070210ba959',
    messagingSenderId: '440680002716',
    projectId: 'fir-99003',
    storageBucket: 'fir-99003.firebasestorage.app',
    authDomain: 'fir-99003.firebaseapp.com',
  );
}

class AuthService {
  final _auth = FirebaseAuth.instance;
  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('Login successful: ${userCredential.user?.email}');
    } on FirebaseAuthException catch (e) {
      print('Login Firebase error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code);
    } catch (e) {
      print('Login general error: $e');
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await res.user!.updateDisplayName(name);
      print('Signup successful: ${res.user?.email}');
    } on FirebaseAuthException catch (e) {
      print('Signup Firebase error: ${e.code} - ${e.message}');
      throw _getErrorMessage(e.code);
    } catch (e) {
      print('Signup general error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

class DatabaseService {
  final String uid;
  DatabaseService(this.uid);

  final Box _box = Hive.box('closet_box');

  Future<void> addItem(String name, String category, String season, XFile image) async {
    String imagePath = image.path;

    final item = {
      'uid': uid,
      'name': name,
      'category': category,
      'season': season,
      'imageUrl': imagePath,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _box.add(item);
  }

  Future<void> deleteItem(int index) async {
    await _box.deleteAt(index);
  }

  List<Map<dynamic, dynamic>> getUserItems() {
    final List<dynamic> allData = _box.values.toList();
    List<Map<dynamic, dynamic>> userItems = [];

    for (int i = 0; i < allData.length; i++) {
      final item = allData[i];
      if (item is Map) {
        final map = item;
        if (map['uid'] == uid && map.containsKey('category')) {
          map['key'] = _box.keyAt(i);
          if (!map.containsKey('season')) {
            map['season'] = 'All Year';
          }
          userItems.add(map);
        }
      }
    }
    return userItems;
  }

  Future<void> setWeatherMode(String mode) async {
    await _box.put('weather_mode_$uid', mode);
  }

  String getWeatherMode() {
    return _box.get('weather_mode_$uid', defaultValue: 'All Year');
  }

  Future<void> saveProfilePic(XFile image) async {
    await _box.put('profile_pic_$uid', image.path);
  }

  String? getProfilePic() {
    return _box.get('profile_pic_$uid');
  }

  Future<void> setPreferredCity(String city) async {
    await _box.put('preferred_city_$uid', city);
  }

  String? getPreferredCity() {
    return _box.get('preferred_city_$uid');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('closet_box');
  runApp(const FitCheckApp());
}

class FitCheckApp extends StatelessWidget {
  const FitCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).copyWith(
          bodyLarge: const TextStyle(color: AppColors.textDark),
          bodyMedium: const TextStyle(color: AppColors.textDark),
          displayLarge: const TextStyle(color: AppColors.textDark),
          displayMedium: const TextStyle(color: AppColors.textDark),
          displaySmall: const TextStyle(color: AppColors.textDark),
          titleLarge: const TextStyle(color: AppColors.textDark),
          titleMedium: const TextStyle(color: AppColors.textDark),
          titleSmall: const TextStyle(color: AppColors.textDark),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: AppColors.accent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: const TextStyle(color: AppColors.textLight),
          hintStyle: const TextStyle(color: AppColors.textLight),
          floatingLabelStyle: const TextStyle(color: AppColors.primary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.poppins(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData) return const MainApp();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'FitCheck',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Style your perfect look',
                  style: GoogleFonts.poppins(
                    color: AppColors.textLight,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextField(
                  controller: _email,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      try {
                        await AuthService().login(_email.text.trim(), _pass.text.trim());
                      } catch (e) {
                        setState(() => _errorMessage = e.toString());
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                      'Log In',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: Text(
                    "Create Account",
                    style: GoogleFonts.poppins(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    try {
                      await AuthService().signup(_name.text.trim(), _email.text.trim(), _pass.text.trim());
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _errorMessage = e.toString());
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _index = 0;
  final _screens = const [HomeDashboard(), MyClosetScreen(), OutfitBuilderScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          height: 70,
          destinations: [
            _buildNavItem(Icons.wb_sunny_rounded, 'Weather'),
            _buildNavItem(Icons.checkroom_rounded, 'Closet'),
            _buildNavItem(Icons.auto_awesome_rounded, 'Builder'),
            _buildNavItem(Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return NavigationDestination(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.textLight,
          size: 24,
        ),
      ),
      selectedIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      label: label,
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;
  String _weatherMode = 'All Year';
  final TextEditingController _cityController = TextEditingController();
  String _aiComment = '';
  String _fashionTip = '';

  @override
  void initState() {
    super.initState();
    _initializeWeather();
  }

  Future<void> _initializeWeather() async {
    final user = FirebaseAuth.instance.currentUser!;
    final db = DatabaseService(user.uid);

    await db.updateAndApplyWeatherFilter();

    final effectiveMode = db.getEffectiveWeatherMode();
    final storedWeather = db.getStoredWeatherData();

    setState(() {
      _weatherMode = effectiveMode;
      _weatherData = storedWeather;
      _aiComment = db.getWeatherAIComment();
      _fashionTip = db.getDailyFashionTip();
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = DatabaseService(user.uid);

      final savedCity = db.getPreferredCity();
      final weather = await WeatherService.getCurrentWeather(savedCity);

      if (weather != null) {
        final mode = WeatherService.getWeatherModeFromTemperature(weather.temperature);
        await db.setWeatherMode(mode);

        setState(() {
          _weatherData = weather;
          _weatherMode = mode;
          _aiComment = db.getWeatherAIComment();
        });
      }
    } catch (e) {
      print('Weather fetch error: $e');
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _fetchWeatherByCity(String city) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = DatabaseService(user.uid);

      await db.setPreferredCity(city);

      final weather = await WeatherService.getWeatherByCity(city);

      if (weather != null) {
        final mode = WeatherService.getWeatherModeFromTemperature(weather.temperature);
        await db.setWeatherMode(mode);

        setState(() {
          _weatherData = weather;
          _weatherMode = mode;
          _aiComment = db.getWeatherAIComment();
        });
      }
    } catch (e) {
      print('Weather fetch error: $e');
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _updateWeatherMode(String mode) async {
    final user = FirebaseAuth.instance.currentUser!;
    final db = DatabaseService(user.uid);

    await db.setWeatherMode(mode);

    if (mode == 'All Year') {
      await _fetchWeather();
    } else {
      setState(() {
        _weatherMode = mode;
        _aiComment = db.getWeatherAIComment();
      });
    }
  }

  bool _isItemSuitableForWeather(Map item, String weatherMode) {
    final season = item['season'] ?? 'All Year';

    if (weatherMode == 'Summer') {
      return season != 'Winter';
    } else if (weatherMode == 'Winter') {
      return season != 'Summer';
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = DatabaseService(user.uid);

    return ValueListenableBuilder(
      valueListenable: Hive.box('closet_box').listenable(),
      builder: (context, Box box, _) {
        final allItems = db.getUserItems();
        final profilePath = db.getProfilePic();

        final filteredItems = allItems.where((item) => _isItemSuitableForWeather(item, _weatherMode)).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.surface, AppColors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Vibe",
                              style: GoogleFonts.poppins(
                                color: AppColors.textLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Hi, ${user.displayName?.split(' ')[0] ?? 'Fashionista'}",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_weatherData != null)
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                    child: _weatherData!.iconUrl.contains('http')
                                        ? Image.network(_weatherData!.iconUrl)
                                        : Icon(Icons.cloud, size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_weatherData!.location} • ${_weatherData!.temperature.toStringAsFixed(0)}°C • Mode: $_weatherMode',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage: profilePath != null
                              ? NetworkImage(profilePath) as ImageProvider
                              : null,
                          backgroundColor: AppColors.surface,
                          child: profilePath == null
                              ? Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 28,
                          )
                              : null,
                        ),
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _weatherMode == 'Summer'
                            ? [const Color(0xFFFF6B95), const Color(0xFF845EC2)]
                            : (_weatherMode == 'Winter'
                            ? [const Color(0xFF4CC9F0), const Color(0xFF4361EE)]
                            : [AppColors.primary, AppColors.secondary]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_weatherData != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: Center(
                                      child: _weatherData!.iconUrl.contains('http')
                                          ? Image.network(_weatherData!.iconUrl)
                                          : Icon(Icons.cloud, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _weatherData!.location,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${_weatherData!.temperature.toStringAsFixed(1)}°C • ${_weatherData!.condition}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _fetchWeather,
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _cityController,
                                      style: GoogleFonts.poppins(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Enter city name',
                                        hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.2),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        if (_cityController.text.isNotEmpty) {
                                          _fetchWeatherByCity(_cityController.text);
                                          _cityController.clear();
                                        }
                                      },
                                      icon: const Icon(Icons.search, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else if (_isLoadingWeather)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Text(
                                "Weather Service",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _fetchWeather,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.textDark,
                                ),
                                child: Text('Get Weather'),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        Text(
                          "Select Weather Mode:",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _WeatherButton(
                              icon: Icons.wb_sunny_rounded,
                              label: "Hot",
                              isSelected: _weatherMode == 'Summer',
                              onTap: () => _updateWeatherMode('Summer'),
                            ),
                            _WeatherButton(
                              icon: Icons.ac_unit_rounded,
                              label: "Cold",
                              isSelected: _weatherMode == 'Winter',
                              onTap: () => _updateWeatherMode('Winter'),
                            ),
                            _WeatherButton(
                              icon: Icons.filter_hdr_rounded,
                              label: "Auto",
                              isSelected: _weatherMode == 'All Year',
                              onTap: () => _updateWeatherMode('All Year'),
                            ),
                          ],
                        ),

                        if (_weatherData != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              'Filtering: ${filteredItems.length} of ${allItems.length} items suitable',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Style Assistant",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (_aiComment.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _weatherMode == 'Summer'
                                        ? Icons.wb_sunny_rounded
                                        : _weatherMode == 'Winter'
                                        ? Icons.ac_unit_rounded
                                        : Icons.filter_hdr_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _aiComment,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        if (_fashionTip.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(
                                color: AppColors.textLight,
                                height: 1,
                              ),
                              const SizedBox(height: 15),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _fashionTip,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.textDark,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser!;
                              final db = DatabaseService(user.uid);
                              setState(() {
                                _aiComment = db.getWeatherAIComment();
                                _fashionTip = db.getDailyFashionTip();
                              });
                            },
                            icon: Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              "New Tip",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recently Added",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            "Filtered for $_weatherMode weather",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "See All",
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 160,
                  child: filteredItems.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checkroom_rounded,
                          size: 60,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No suitable clothes for $_weatherMode weather!",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Add more $_weatherMode items ",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredItems.length > 5 ? 5 : filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 15),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['name'],
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              item['season'] ?? 'All Year',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard(
                        value: allItems.length.toString(),
                        label: "Total Clothes",
                        icon: Icons.checkroom_rounded,
                        color: AppColors.primary,
                      ),
                      _buildStatCard(
                        value: filteredItems
                            .where((item) => item['category'] == 'Top')
                            .length
                            .toString(),
                        label: "Suitable Tops",
                        icon: Icons.face_retouching_natural_rounded,
                        color: AppColors.accent,
                      ),
                      _buildStatCard(
                        value: filteredItems
                            .where((item) => item['category'] == 'Bottom')
                            .length
                            .toString(),
                        label: "Suitable Bottoms",
                        icon: Icons.airline_seat_legroom_reduced_rounded,
                        color: AppColors.secondary,
                      ),
                      _buildStatCard(
                        value: filteredItems.length.toString(),
                        label: "Suitable Items",
                        icon: _weatherMode == 'Summer'
                            ? Icons.wb_sunny
                            : (_weatherMode == 'Winter'
                            ? Icons.ac_unit
                            : Icons.filter_hdr),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        )
    );
  }
}

class _WeatherButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeatherButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.textDark : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppColors.textDark : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MyClosetScreen extends StatefulWidget {
  const MyClosetScreen({super.key});
  @override
  State<MyClosetScreen> createState() => _MyClosetScreenState();
}

class _MyClosetScreenState extends State<MyClosetScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Closet",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: Hive.box('closet_box').listenable(),
              builder: (context, Box box, _) {
                final db = DatabaseService(user.uid);
                final effectiveMode = db.getEffectiveWeatherMode();
                final filteredItems = db.getWeatherFilteredItems();
                final allItems = db.getUserItems();

                return Text(
                  "${filteredItems.length} of ${allItems.length} items suitable for $effectiveMode",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, size: 28),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddClothingScreen()),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('closet_box').listenable(),
        builder: (context, Box box, _) {
          final db = DatabaseService(user.uid);
          final filteredItems = db.getWeatherFilteredItems();
          final displayItems = _selectedCategory == 'All'
              ? filteredItems
              : filteredItems.where((i) => i['category'] == _selectedCategory).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Top', 'Bottom', 'Shoes', 'Accessory'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          elevation: isSelected ? 3 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: displayItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checkroom_rounded,
                        size: 80,
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No items found",
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder(
                        valueListenable: Hive.box('closet_box').listenable(),
                        builder: (context, Box box, _) {
                          final db = DatabaseService(user.uid);
                          final effectiveMode = db.getEffectiveWeatherMode();
                          return Text(
                            "No $effectiveMode items in ${
                                _selectedCategory == 'All' ? 'your closet' : _selectedCategory.toLowerCase()
                            } category",
                            style: GoogleFonts.poppins(
                              color: AppColors.textLight.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: displayItems.length,
                    itemBuilder: (context, i) {
                      final data = displayItems[i];

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            data['imageUrl'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'],
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            data['season'] == 'Summer'
                                                ? Icons.wb_sunny
                                                : (data['season'] == 'Winter'
                                                ? Icons.ac_unit
                                                : Icons.filter_hdr),
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            data['season'] ?? 'All Year',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline_rounded,
                                              size: 12,
                                              color: AppColors.warning,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: () => Hive.box('closet_box').delete(data['key']),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});
  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = DatabaseService(user.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Mix & Match",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('closet_box').listenable(),
        builder: (context, Box box, _) {
          final weatherMode = db.getEffectiveWeatherMode();
          final filteredItems = db.getWeatherFilteredItems();

          final tops = filteredItems.where((i) => i['category'] == 'Top').toList();
          final bottoms = filteredItems.where((i) => i['category'] == 'Bottom').toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: weatherMode == 'Summer'
                        ? [const Color(0xFFFF6B95).withOpacity(0.3), const Color(0xFF845EC2).withOpacity(0.3)]
                        : (weatherMode == 'Winter'
                        ? [const Color(0xFF4CC9F0).withOpacity(0.3), const Color(0xFF4361EE).withOpacity(0.3)]
                        : [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.3)]),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      weatherMode == 'All Year'
                          ? "Showing all outfits"
                          : "Automatically filtered for $weatherMode weather",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${tops.length} tops • ${bottoms.length} bottoms",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary.withOpacity(0.1), AppColors.background],
                    ),
                  ),
                  child: tops.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checkroom_rounded,
                          size: 60,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No suitable tops",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Add more $weatherMode tops to your closet",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Center(
                    child: SizedBox(
                      height: 400,
                      child: PageView.builder(
                        controller: PageController(
                          viewportFraction: 0.7,
                        ),
                        itemCount: tops.length,
                        itemBuilder: (context, index) => _buildSwipeCard(tops[index], 'Top'),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                color: AppColors.surface,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.secondary.withOpacity(0.1), AppColors.background],
                    ),
                  ),
                  child: bottoms.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.airline_seat_legroom_reduced_rounded,
                          size: 60,
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "No suitable bottoms",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Add more $weatherMode bottoms to your closet",
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Center(
                    child: SizedBox(
                      height: 400,
                      child: PageView.builder(
                        controller: PageController(
                          viewportFraction: 0.7,
                        ),
                        itemCount: bottoms.length,
                        itemBuilder: (context, index) => _buildSwipeCard(bottoms[index], 'Bottom'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwipeCard(Map item, String type) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              color: Colors.white,
              child: Center(
                child: Image.network(
                  item['imageUrl'],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        item['season'] == 'Summer'
                            ? Icons.wb_sunny
                            : (item['season'] == 'Winter' ? Icons.ac_unit : Icons.filter_hdr),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['season'] ?? 'All Year',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});
  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final name = TextEditingController();
  String category = 'Top';
  String season = 'All Year';
  XFile? image;
  final picker = ImagePicker();

  Future<void> pickImage(ImageSource src) async {
    final picked = await picker.pickImage(source: src);
    if (picked != null) setState(() => image = picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "New Item",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => pickImage(ImageSource.gallery),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Tap to add photo",
                      style: GoogleFonts.poppins(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Image.network(
                    image!.path,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: name,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: category,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
              ),
              dropdownColor: AppColors.surface,
              items: ['Top', 'Bottom', 'Shoes', 'Accessory']
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => category = v.toString()),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: season,
              style: const TextStyle(color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Best for Weather...',
                prefixIcon: Icon(Icons.wb_sunny_outlined, color: AppColors.primary),
              ),
              dropdownColor: AppColors.surface,
              items: [
                DropdownMenuItem(
                  value: 'Summer',
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Summer / Hot",
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Winter',
                  child: Row(
                    children: [
                      Icon(Icons.ac_unit, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Winter / Cold",
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'All Year',
                  child: Row(
                    children: [
                      Icon(Icons.filter_hdr, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "All Year / Mild",
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => season = v.toString()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (image != null && name.text.isNotEmpty) {
                    await DatabaseService(user.uid).addItem(name.text, category, season, image!);
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Save to Closet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _changeProfilePic() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final user = FirebaseAuth.instance.currentUser!;
      await DatabaseService(user.uid).saveProfilePic(picked);
      setState(() {});
    }
  }

  void _showSettingsDialog(BuildContext context) {
    bool notificationsEnabled = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                "Settings",
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.notifications_active_rounded,
                          color: AppColors.primary),
                      title: Text("Push Notifications",
                          style: GoogleFonts.poppins(color: AppColors.textDark)),
                      trailing: Switch(
                        value: notificationsEnabled,
                        onChanged: (value) {
                          setState(() => notificationsEnabled = value);
                          final user = FirebaseAuth.instance.currentUser!;
                          Hive.box('closet_box').put('notifications_${user.uid}', value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? "Notifications enabled" : "Notifications disabled",
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: value ? AppColors.success : AppColors.warning,
                            ),
                          );
                        },
                        activeColor: AppColors.primary,
                        inactiveTrackColor: AppColors.textLight.withOpacity(0.3),
                      ),
                    ),

                    const Divider(color: AppColors.textLight, height: 1),

                    ListTile(
                      leading: Icon(Icons.storage_rounded,
                          color: AppColors.primary),
                      title: Text("Clear Cache",
                          style: GoogleFonts.poppins(color: AppColors.textDark)),
                      onTap: () {
                        Navigator.pop(context);
                        _showClearCacheDialog(context);
                      },
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: GoogleFonts.poppins(color: AppColors.textLight),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Clear Cache",
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "This will remove cached images and temporary data. Your clothing items and profile will remain intact.",
            style: GoogleFonts.poppins(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _performClearCache(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(
                "Clear",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performClearCache(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final box = Hive.box('closet_box');

      // Get all items in the box
      final allKeys = box.keys.toList();
      int clearedCount = 0;

      for (var key in allKeys) {
        final item = box.get(key);

        // Check if this is a cached/temp item (not user's clothing items)
        if (item is Map) {
          // Skip user's clothing items
          if (item.containsKey('uid') && item.containsKey('category')) {
            continue; // This is a clothing item, don't delete
          }
        }

        // Check for cache keys
        final keyStr = key.toString();
        if (keyStr.contains('cache_') ||
            keyStr.contains('temp_') ||
            keyStr.contains('image_cache_') ||
            keyStr.contains('weather_cache_') ||
            keyStr == 'app_cache' ||
            keyStr == 'image_cache') {
          await box.delete(key);
          clearedCount++;
        }
      }

      // Also clear any cached images from image picker
      if (!kIsWeb) {
        try {
          final appDir = await getTemporaryDirectory();
          if (appDir.existsSync()) {
            appDir.deleteSync(recursive: true);
          }
        } catch (e) {
          print('Error clearing temp directory: $e');
        }
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cache cleared successfully! Cleared $clearedCount items.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Force refresh the UI
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error clearing cache: ${e.toString()}",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Help & Support",
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need help? We're here for you!",
                  style: GoogleFonts.poppins(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "Frequently Asked Questions",
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                _buildFAQItem(
                    context,
                    "How do I add clothing items?",
                    "Go to 'My Closet' tab and tap the + button. Take or upload a photo, add details, and save!"
                ),

                _buildFAQItem(
                    context,
                    "How does weather filtering work?",
                    "The app uses your current weather to suggest suitable clothing. You can also manually set weather mode."
                ),

                _buildFAQItem(
                    context,
                    "Can I change my profile picture?",
                    "Yes! Tap on your profile picture in the top right or go to Profile tab and tap the camera icon."
                ),

                const SizedBox(height: 20),

                Text(
                  "Contact Support",
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                ListTile(
                  leading: Icon(Icons.email_rounded, color: AppColors.primary),
                  title: Text("Email", style: GoogleFonts.poppins(color: AppColors.textDark)),
                  subtitle: Text("support@fitcheck.com", style: GoogleFonts.poppins(color: AppColors.textLight)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Opening email client...",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.phone_rounded, color: AppColors.primary),
                  title: Text("Call", style: GoogleFonts.poppins(color: AppColors.textDark)),
                  subtitle: Text("03315477687", style: GoogleFonts.poppins(color: AppColors.textLight)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Opening phone dialer...",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: GoogleFonts.poppins(color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Privacy Policy",
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: GoogleFonts.poppins(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),

                _buildPolicySection(
                    "Data Collection",
                    "We collect only essential data to provide our services:\n• Clothing images you upload\n• Weather preferences\n• User account information\n• App usage statistics"
                ),

                const SizedBox(height: 15),

                _buildPolicySection(
                    "Data Usage",
                    "Your data is used to:\n• Personalize clothing recommendations\n• Filter items based on weather\n• Improve app features\n• Provide customer support"
                ),

                const SizedBox(height: 15),

                _buildPolicySection(
                    "Data Storage",
                    "All data is stored securely:\n• Images are stored locally on your device\n• User preferences in encrypted local storage\n• Authentication via secure Firebase services"
                ),

                const SizedBox(height: 15),

                _buildPolicySection(
                    "Your Rights",
                    "You have the right to:\n• Access your personal data\n• Delete your account and data\n• Opt-out of non-essential data collection\n• Export your clothing inventory"
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _exportData(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        "Export My Data",
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        _showDeleteAccountDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.danger),
                      ),
                      child: Text(
                        "Delete Account",
                        style: GoogleFonts.poppins(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: GoogleFonts.poppins(color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: GoogleFonts.poppins(
            color: AppColors.textLight,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _exportData(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final db = DatabaseService(user.uid);

    final userItems = db.getUserItems();
    final weatherMode = db.getWeatherMode();

    final exportData = {
      'user': {
        'name': user.displayName,
        'email': user.email,
        'uid': user.uid,
      },
      'clothing_items': userItems.length,
      'weather_mode': weatherMode,
      'export_date': DateTime.now().toIso8601String(),
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Data Export",
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "Your data has been prepared for export:\n\n"
                "• ${userItems.length} clothing items\n"
                "• Weather preference: $weatherMode\n"
                "• User profile information\n\n"
                "Data would be downloaded as JSON file.",
            style: GoogleFonts.poppins(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Data exported successfully! Check your downloads.",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                "Download",
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Delete Account",
            style: GoogleFonts.poppins(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            "This action is permanent and cannot be undone!\n\n"
                "All your data will be deleted:\n"
                "• All clothing items\n"
                "• Weather preferences\n"
                "• Profile information\n"
                "• App settings\n\n"
                "Are you absolutely sure?",
            style: GoogleFonts.poppins(color: AppColors.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final db = DatabaseService(user.uid);

                  final box = Hive.box('closet_box');
                  final userItems = db.getUserItems();

                  for (var item in userItems) {
                    if (item['key'] != null) {
                      box.delete(item['key']);
                    }
                  }

                  box.delete('weather_mode_${user.uid}');
                  box.delete('profile_pic_${user.uid}');
                  box.delete('preferred_city_${user.uid}');
                  box.delete('current_weather_${user.uid}');
                  box.delete('notifications_${user.uid}');

                  await user.delete();

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Account deleted successfully",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  await AuthService().logout();

                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error deleting account: ${e.toString()}",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(
                "Delete Account",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return ValueListenableBuilder(
        valueListenable: Hive.box('closet_box').listenable(),
        builder: (context, Box box, _) {
          final profilePath = DatabaseService(user.uid).getProfilePic();
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                "My Profile",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: AppColors.surface,
                            backgroundImage: (profilePath != null)
                                ? NetworkImage(profilePath) as ImageProvider
                                : null,
                            child: (profilePath == null)
                                ? Icon(
                              Icons.person_rounded,
                              size: 80,
                              color: AppColors.primary,
                            )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeProfilePic,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    user.displayName ?? "User",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? "",
                    style: GoogleFonts.poppins(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          icon: Icons.settings_rounded,
                          title: "Settings",
                          onTap: () => _showSettingsDialog(context),
                        ),
                        _buildProfileItem(
                          icon: Icons.help_rounded,
                          title: "Help & Support",
                          onTap: () => _showHelpSupportDialog(context),
                        ),
                        _buildProfileItem(
                          icon: Icons.privacy_tip_rounded,
                          title: "Privacy Policy",
                          onTap: () => _showPrivacyPolicyDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => AuthService().logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Logout",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textLight,
      ),
    );
  }
}