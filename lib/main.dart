import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final int points;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
  });
}

const achievementDefinitions = [
  AchievementDefinition(
    id: 'verified_email',
    title: 'Подтверждённый email',
    description: 'Подтвердите адрес электронной почты',
    points: 10,
  ),
  AchievementDefinition(
    id: 'first_request_created',
    title: 'Первая заявка',
    description: 'Создайте свою первую заявку',
    points: 10,
  ),
  AchievementDefinition(
    id: 'first_chat_message',
    title: 'Первый контакт',
    description: 'Отправьте первое сообщение в чате',
    points: 5,
  ),
  AchievementDefinition(
    id: 'first_rating_received',
    title: 'Первая оценка',
    description: 'Получите первую пользовательскую оценку',
    points: 10,
  ),
  AchievementDefinition(
    id: 'rating_4_5',
    title: 'Хорошая репутация',
    description: 'Достигните рейтинга 4.5 и выше',
    points: 20,
  ),
  AchievementDefinition(
    id: 'first_volunteer_help',
    title: 'Первый добрый поступок',
    description: 'Помогите кому-то впервые',
    points: 15,
  ),
  AchievementDefinition(
    id: 'five_volunteer_helps',
    title: 'Надёжный помощник',
    description: 'Помогите 5 раз',
    points: 35,
  ),
];

Map<String, dynamic> buildInitialAchievements() {
  return {
    'verified_email': {'unlocked': false},
    'first_request_created': {'unlocked': false},
    'first_chat_message': {'unlocked': false},
    'first_rating_received': {'unlocked': false},
    'rating_4_5': {'unlocked': false},
    'first_volunteer_help': {'unlocked': false},
    'five_volunteer_helps': {'unlocked': false},
  };
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// фон
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xffe8f5e9),
                  Color(0xffc8e6c9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// падающие листья
          ...List.generate(12, (i) {
            return Positioned(
              left: (i * 30) % MediaQuery.of(context).size.width,
              top: -20,
              child: const Icon(
                Icons.eco,
                color: Colors.green,
                size: 24,
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .moveY(
                    begin: -100,
                    end: MediaQuery.of(context).size.height + 100,
                    duration: Duration(seconds: 5 + i),
                  )
                  .rotate(duration: Duration(seconds: 3 + i)),
            );
          }),

          /// логотип
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.volunteer_activism,
                  size: 80,
                  color: Colors.green,
                ),
                SizedBox(height: 16),
                Text(
                  "Volunteer Match",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}


class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> unlockAchievementForUser({
    required String userId,
    required String achievementId,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    final snap = await userRef.get();
    final data = snap.data() ?? {};

    final achievements = Map<String, dynamic>.from(data['achievements'] ?? {});
    final current = Map<String, dynamic>.from(
      achievements[achievementId] ?? {'unlocked': false},
    );

    if (current['unlocked'] == true) return false;

    achievements[achievementId] = {
      'unlocked': true,
      'unlockedAt': FieldValue.serverTimestamp(),
    };

    await userRef.set({
      'achievements': achievements,
    }, SetOptions(merge: true));

    return true;
  }

  Future<bool> unlockAchievement(String achievementId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    return unlockAchievementForUser(
      userId: user.uid,
      achievementId: achievementId,
    );
  }

  Future<String?> checkVerifiedEmail() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed?.emailVerified == true) {
      final unlocked = await unlockAchievement('verified_email');
      if (unlocked) return 'Открыто достижение: Подтверждённый email';
    }
    return null;
  }

  Future<String?> checkAfterRequestCreated() async {
    final unlocked = await unlockAchievement('first_request_created');
    if (unlocked) return 'Открыто достижение: Первая заявка';
    return null;
  }

  Future<String?> checkAfterFirstChatMessage() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final count = (data['chatMessagesCount'] is num)
        ? (data['chatMessagesCount'] as num).toInt()
        : 0;

    if (count >= 1) {
      final unlocked = await unlockAchievement('first_chat_message');
      if (unlocked) return 'Открыто достижение: Первый контакт';
    }
    return null;
  }

  Future<List<String>> checkAfterReceivedRatingForUser({
    required String userId,
    required int ratingCount,
    required double rating,
  }) async {
    final result = <String>[];

    if (ratingCount >= 1) {
      final first = await unlockAchievementForUser(
        userId: userId,
        achievementId: 'first_rating_received',
      );
      if (first) result.add('Открыто достижение: Первая оценка');
    }

    if (ratingCount >= 1 && rating >= 4.5) {
      final rep = await unlockAchievementForUser(
        userId: userId,
        achievementId: 'rating_4_5',
      );
      if (rep) result.add('Открыто достижение: Хорошая репутация');
    }

    return result;
  }

  Future<List<String>> checkAfterVolunteerHelpCountForUser({
    required String userId,
    required int helpsCount,
  }) async {
    final result = <String>[];

    if (helpsCount >= 1) {
      final first = await unlockAchievementForUser(
        userId: userId,
        achievementId: 'first_volunteer_help',
      );
      if (first) result.add('Открыто достижение: Первый добрый поступок');
    }

    if (helpsCount >= 5) {
      final five = await unlockAchievementForUser(
        userId: userId,
        achievementId: 'five_volunteer_helps',
      );
      if (five) result.add('Открыто достижение: Надёжный помощник');
    }

    return result;
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // google_sign_in v7+: singleton + initialize

  runApp(const VolunteerMatchApp());
}

class VolunteerMatchApp extends StatelessWidget {
  const VolunteerMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7ED957), // салатовый
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}


Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("onboarding_seen") ?? false;
}
/// =====================
/// AUTH GATE
/// =====================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        print('AUTH user=${user?.email}, verified=${user?.emailVerified}');

        if (user == null) {
          return const EmailAuthScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        return const MainShell();
      },
    );
  }
}


class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'name': (user.displayName ?? '').trim().isEmpty
            ? 'Без имени'
            : user.displayName,
        'avatarUrl': user.photoURL ?? '',
        'rating': 5.0,
        'ratingCount': 0,
        'chatMessagesCount': 0,
        'volunteerHelpsCount': 0,
        'createdRequestsCount': 0,
        'achievements': buildInitialAchievements(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snap.data() ?? {};
      final patch = <String, dynamic>{};

      if (!data.containsKey('chatMessagesCount')) {
        patch['chatMessagesCount'] = 0;
      }
      if (!data.containsKey('volunteerHelpsCount')) {
        patch['volunteerHelpsCount'] = 0;
      }
      if (!data.containsKey('createdRequestsCount')) {
        patch['createdRequestsCount'] = 0;
      }
      if (!data.containsKey('achievements')) {
        patch['achievements'] = buildInitialAchievements();
      }

      if (patch.isNotEmpty) {
        await ref.set(patch, SetOptions(merge: true));
      }
    }
  }

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (!email.contains('@') || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email нормальный, пароль минимум 6 символов'),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      if (_isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );

        await _ensureUserDoc(cred.user!);
        await FirebaseAuth.instance.currentUser?.reload();

        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Почта ещё не подтверждена. Проверь письмо.'),
            ),
          );
        }
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        await _ensureUserDoc(cred.user!);

        await cred.user?.sendEmailVerification();
        print('VERIFY EMAIL SENT TO: ${cred.user?.email}');

        await FirebaseAuth.instance.currentUser?.reload();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аккаунт создан. Письмо для подтверждения отправлено.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Вход' : 'Регистрация'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Пароль (мин. 6)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submitEmail,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? 'Войти' : 'Создать аккаунт'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() => _isLogin = !_isLogin);
                    },
              child: Text(
                _isLogin
                    ? 'Нет аккаунта? Регистрация'
                    : 'Уже есть аккаунт? Войти',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _checkVerified() async {
    setState(() => _busy = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      final achievementText = await AchievementService().checkVerifiedEmail();

      if (!mounted) return;

      if (achievementText != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(achievementText)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка проверки: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      print('RESEND VERIFY EMAIL TO: ${user?.email}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Письмо отправлено ещё раз')),
      );
    } catch (e) {
      print('RESEND VERIFY EMAIL ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение почты')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.mark_email_read_outlined, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Подтверди почту',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Мы отправили письмо на: ${user?.email ?? "-"}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Открой письмо, нажми ссылку подтверждения, потом вернись сюда и нажми "Я подтвердил".',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _checkVerified,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Я подтвердил'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resendEmail,
                child: const Text('Отправить письмо ещё раз'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _logout,
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// MAIN SHELL
/// =====================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    FeedScreen(),
    CreateRequestScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, chatSnap) {
        int totalUnread = 0;

        if (chatSnap.hasData) {
          totalUnread = getTotalUnreadFromChats(chatSnap.data!.docs, user.uid);
        }

        return Scaffold(
          body: _pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.view_agenda),
                label: 'Лента',
              ),
              const NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                label: 'Заявка',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.person_outline),
                    if (totalUnread > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: _UnreadBadge(count: totalUnread),
                      ),
                  ],
                ),
                label: 'Профиль',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// =====================
/// FEED SCREEN (REAL REQUESTS, EXCLUDE OWN)
/// =====================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Position? _myPosition;
  String? _myCity;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndCity();
  }

  Future<void> _initLocationAndCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String city = 'Неизвестно';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = (p.locality?.trim().isNotEmpty == true)
            ? p.locality!.trim()
            : (p.administrativeArea?.trim().isNotEmpty == true)
                ? p.administrativeArea!.trim()
                : 'Неизвестно';
      }

      if (mounted) {
        setState(() {
          _myPosition = pos;
          _myCity = city;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  double? _distanceKm(Map<String, dynamic> data) {
    if (_myPosition == null) return null;

    final lat = data['lat'];
    final lng = data['lng'];

    if (lat is! num || lng is! num) return null;

    final meters = Geolocator.distanceBetween(
      _myPosition!.latitude,
      _myPosition!.longitude,
      lat.toDouble(),
      lng.toDouble(),
    );

    return meters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;

    if (_loadingLocation) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myCity == null || _myCity == 'Неизвестно') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Лента заявок',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Не удалось определить ваш город.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _initLocationAndCity,
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'open')
        .where('city', isEqualTo: _myCity)
        .orderBy('createdAt', descending: true);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Лента заявок',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Ваш город: $_myCity'),
            const SizedBox(height: 8),
            const Text('Свои заявки в ленте не показываются.'),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Ошибка загрузки: ${snap.error}'),
                    );
                  }

                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snap.hasData) {
                    return const Center(child: Text('Нет данных'));
                  }

                  final now = DateTime.now();

                  for (final d in snap.data!.docs) {
                    final data = d.data();
                    final expires = data['expiresAt'] as Timestamp?;
                    final status = (data['status'] ?? '').toString();

                    if (expires != null &&
                        expires.toDate().isBefore(now) &&
                        status == 'open') {
                      FirebaseFirestore.instance
                          .collection('requests')
                          .doc(d.id)
                          .delete();
                    }
                  }

                  final docs = snap.data!.docs.where((d) {
                    final data = d.data();

                    final authorId = (data['authorId'] ?? '').toString();
                    final expiresTs = data['expiresAt'] as Timestamp?;
                    final expiresAt = expiresTs?.toDate();

                    final isNotMine = authorId != me.uid;
                    final isNotExpired =
                        expiresAt == null ? true : expiresAt.isAfter(now);

                    return isNotMine && isNotExpired;
                  }).toList();

                  if (_myPosition != null) {
                    docs.sort((a, b) {
                      final da = _distanceKm(a.data()) ?? 999999;
                      final db = _distanceKm(b.data()) ?? 999999;
                      return da.compareTo(db);
                    });
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Пока нет чужих открытых заявок в городе $_myCity.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final distanceKm = _distanceKm(data);

                      return RequestDocCard(
                        requestId: doc.id,
                        title: (data['title'] ?? '').toString(),
                        category: (data['category'] ?? '').toString(),
                        description: (data['description'] ?? '').toString(),
                        urgent: (data['urgent'] ?? false) == true,
                        authorId: (data['authorId'] ?? '').toString(),
                        expiresAt: data['expiresAt'] as Timestamp?,
                        city: (data['city'] ?? '').toString(),
                        distanceKm: distanceKm,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class RequestDocCard extends StatefulWidget {
  final String requestId;
  final String title;
  final String category;
  final String description;
  final bool urgent;
  final String authorId;
  final Timestamp? expiresAt;
  final String city;
  final double? distanceKm;

  const RequestDocCard({
    super.key,
    required this.requestId,
    required this.title,
    required this.category,
    required this.description,
    required this.urgent,
    required this.authorId,
    required this.expiresAt,
    required this.city,
    required this.distanceKm,
  });

  @override
  State<RequestDocCard> createState() => _RequestDocCardState();
}

class _RequestDocCardState extends State<RequestDocCard> {
  bool _opening = false;

  String _formatRemaining(Timestamp? ts) {
    if (ts == null) return 'Без срока';

    final diff = ts.toDate().difference(DateTime.now());

    if (diff.isNegative) return 'Истекла';

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours ч $minutes мин';
  }

  String _formatDistance(double? km) {
    if (km == null) return 'Неизвестно';
    if (km < 1) return '${(km * 1000).round()} м';
    return '${km.toStringAsFixed(1)} км';
  }

  Future<void> _help() async {
    final me = FirebaseAuth.instance.currentUser!;
    setState(() => _opening = true);

    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();

      await chatRef.set({
        'chatId': chatRef.id,
        'requestId': widget.requestId,
        'requestTitle': widget.title,
        'requestCategory': widget.category,
        'members': [me.uid, widget.authorId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCountMap': {
          me.uid: 0,
          widget.authorId: 0,
        },
      });

      await chatRef.collection('messages').add({
        'text': 'Чат создан. Опиши детали помощи здесь.',
        'senderId': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'status': 'in_chat',
        'acceptedBy': me.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'chatId': chatRef.id,
      });

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatRef.id,
            title: widget.title,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNearby = widget.distanceKm != null && widget.distanceKm! <= 5;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  text: widget.category,
                ),
                if (isNearby)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'РЯДОМ',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (widget.urgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'СРОЧНО',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📍 ${_formatDistance(widget.distanceKm)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Text(
                    '⏳ ${_formatRemaining(widget.expiresAt)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: widget.urgent ? Colors.red : Colors.black54,
                      fontWeight:
                          widget.urgent ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _opening ? null : _help,
                icon: _opening
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_border),
                label: Text(_opening ? 'Открываю...' : 'Помочь'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() ?? {};
          final achievements = Map<String, dynamic>.from(data['achievements'] ?? {});

          int unlockedCount = 0;
          int totalPoints = 0;

          for (final def in achievementDefinitions) {
            final item = Map<String, dynamic>.from(
              achievements[def.id] ?? {'unlocked': false},
            );
            final unlocked = item['unlocked'] == true;
            if (unlocked) {
              unlockedCount++;
              totalPoints += def.points;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Открыто: $unlockedCount из ${achievementDefinitions.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Очки достижений: $totalPoints',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...achievementDefinitions.map((def) {
                final item = Map<String, dynamic>.from(
                  achievements[def.id] ?? {'unlocked': false},
                );
                final unlocked = item['unlocked'] == true;

                return Card(
                  child: ListTile(
                    leading: Icon(
                      unlocked ? Icons.emoji_events : Icons.lock,
                    ),
                    title: Text(def.title),
                    subtitle: Text(def.description),
                    trailing: Text('${def.points}'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}


/// =====================
/// CREATE REQUEST SCREEN
/// =====================
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();

  String _category = 'Еда';
  bool _busy = false;
  int _hoursToLive = 24;

  String? _detectedCity;
  Position? _currentPosition;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndCity();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _loadingLocation = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _loadingLocation = false);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String city = 'Неизвестно';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = (p.locality?.trim().isNotEmpty == true)
            ? p.locality!.trim()
            : (p.administrativeArea?.trim().isNotEmpty == true)
                ? p.administrativeArea!.trim()
                : 'Неизвестно';
      }

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _detectedCity = city;
          _loadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final t = _title.text.trim();
    final d = _desc.text.trim();

    if (t.isEmpty || d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполни название и описание')),
      );
      return;
    }

    if (_currentPosition == null || _detectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нужна геолокация, чтобы создать заявку'),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final hours = _hoursToLive <= 0 ? 24 : _hoursToLive;
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: hours));
      final autoUrgent = hours <= 3;

      await FirebaseFirestore.instance.collection('requests').add({
        'title': t,
        'description': d,
        'category': _category,
        'city': _detectedCity,
        'lat': _currentPosition!.latitude,
        'lng': _currentPosition!.longitude,
        'urgent': autoUrgent,
        'durationHours': hours,
        'authorId': user.uid,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      }).timeout(const Duration(seconds: 10));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'createdRequestsCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      final achievementText = await AchievementService().checkAfterRequestCreated();

      _title.clear();
      _desc.clear();

      setState(() {
        _category = 'Еда';
        _hoursToLive = 24;
      });

      if (!mounted) return;

      final snackText = achievementText == null
          ? 'Заявка опубликована ✅ Город: $_detectedCity'
          : 'Заявка опубликована ✅ Город: $_detectedCity\n$achievementText';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackText)),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore: ${e.code} ${e.message ?? ""}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Создать заявку',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_loadingLocation)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Определяю ваш город...'),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _detectedCity == null
                    ? 'Город не определён. Включи геолокацию.'
                    : 'Ваш город: $_detectedCity',
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            items: const [
              DropdownMenuItem(value: 'Еда', child: Text('Еда')),
              DropdownMenuItem(value: 'Медицина', child: Text('Медицина')),
              DropdownMenuItem(value: 'Учёба', child: Text('Учёба')),
              DropdownMenuItem(value: 'Техника', child: Text('Техника')),
              DropdownMenuItem(value: 'Разговор', child: Text('Разговор')),
              DropdownMenuItem(value: 'Животные', child: Text('Животные')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'Еда'),
            decoration: const InputDecoration(
              labelText: 'Категория',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Описание',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _hoursToLive,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 час')),
              DropdownMenuItem(value: 2, child: Text('2 часа')),
              DropdownMenuItem(value: 3, child: Text('3 часа')),
              DropdownMenuItem(value: 6, child: Text('6 часов')),
              DropdownMenuItem(value: 12, child: Text('12 часов')),
              DropdownMenuItem(value: 24, child: Text('1 день')),
            ],
            onChanged: (v) => setState(() => _hoursToLive = v ?? 24),
            decoration: const InputDecoration(
              labelText: 'Сколько держать заявку',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_hoursToLive <= 3)
                  ? Colors.red.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _hoursToLive <= 3
                  ? 'Эта заявка будет автоматически помечена как СРОЧНО.'
                  : 'Обычная заявка.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Опубликовать'),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// PROFILE SCREEN (EDIT + MY ACTIVE REQUESTS + CLOSE + RATE)
/// =====================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(
    BuildContext context,
    Map<String, dynamic> current,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final nameCtrl = TextEditingController(
      text: (current['name'] ?? '').toString(),
    );
    final avatarCtrl = TextEditingController(
      text: (current['avatarUrl'] ?? '').toString(),
    );
    final bgCtrl = TextEditingController(
      text: (current['profileBackground'] ?? '').toString(),
    );
    final bioCtrl = TextEditingController(
      text: (current['bio'] ?? '').toString(),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: avatarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Аватар URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Фон профиля URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  hintText: 'Расскажи кратко о себе и чем можешь помочь',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': nameCtrl.text.trim().isEmpty ? 'Без имени' : nameCtrl.text.trim(),
      'avatarUrl': avatarCtrl.text.trim(),
      'profileBackground': bgCtrl.text.trim(),
      'bio': bioCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Color> _getAdaptiveBioColor(String imageUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(300, 300),
        maximumColorCount: 16,
      );

      final color =
          palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          const Color(0xFFE8F5E9);

      return Color.lerp(Colors.white, color, 0.35) ?? const Color(0xFFF3F7EF);
    } catch (_) {
      return const Color(0xFFF3F7EF);
    }
  }

  Color _getReadableTextColor(Color bg) {
    final brightness = ThemeData.estimateBrightnessForColor(bg);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() ?? {};
          final name = (data['name'] ?? 'Без имени').toString();
          final avatarUrl = (data['avatarUrl'] ?? '').toString();
          final bio = (data['bio'] ?? '').toString();
          final profileBackground =
              (data['profileBackground'] ?? '').toString();

          final rating = (data['rating'] is num)
              ? (data['rating'] as num).toDouble()
              : 5.0;
          final ratingCount = (data['ratingCount'] ?? 0).toString();
          final createdRequestsCount =
              (data['createdRequestsCount'] ?? 0).toString();
          final volunteerHelpsCount =
              (data['volunteerHelpsCount'] ?? 0).toString();

          final hasBackground = profileBackground.isNotEmpty;

          return FutureBuilder<Color>(
            future: hasBackground
                ? _getAdaptiveBioColor(profileBackground)
                : Future.value(const Color(0xFFF5F7F2)),
            builder: (context, colorSnap) {
              final adaptiveBioColor =
                  colorSnap.data ?? const Color(0xFFF5F7F2);
              final bioTextColor = _getReadableTextColor(adaptiveBioColor);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF1B5E20),
                        width: 1.5,
                      ),
                      color: hasBackground ? null : const Color(0xFFF4F7EF),
                      image: hasBackground
                          ? DecorationImage(
                              image: NetworkImage(profileBackground),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          if (hasBackground)
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 3.5,
                                  sigmaY: 3.5,
                                ),
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: hasBackground
                                    ? LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.28),
                                          Colors.black.withOpacity(0.14),
                                          Colors.black.withOpacity(0.08),
                                        ],
                                      )
                                    : null,
                                color: hasBackground ? null : Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: const Color(0xFFC8F0A4),
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 38)
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasBackground
                                        ? Colors.white.withOpacity(0.74)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasBackground
                                        ? Colors.white.withOpacity(0.64)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    user.email ?? '-',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _GlassInfoChip(
                                      icon: Icons.star_outline,
                                      text: '${rating.toStringAsFixed(1)} ⭐',
                                    ),
                                    _GlassInfoChip(
                                      icon: Icons.reviews_outlined,
                                      text: '$ratingCount оценок',
                                    ),
                                    _GlassInfoChip(
                                      icon: Icons.edit_note,
                                      text: '$createdRequestsCount заявок',
                                    ),
                                    _GlassInfoChip(
                                      icon: Icons.volunteer_activism_outlined,
                                      text: '$volunteerHelpsCount помощи',
                                    ),
                                  ],
                                ),
                                if (bio.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: adaptiveBioColor.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.08),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      bio,
                                      style: TextStyle(
                                        height: 1.35,
                                        color: bioTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editProfile(context, data),
                          icon: const Icon(Icons.edit),
                          label: const Text('Изменить'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AchievementsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('Достижения'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('members', arrayContains: user.uid)
                        .snapshots(),
                    builder: (context, chatSnap) {
                      int totalUnread = 0;

                      if (chatSnap.hasData) {
                        totalUnread = getTotalUnreadFromChats(
                          chatSnap.data!.docs,
                          user.uid,
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RequestsHubPage(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.list_alt),
                              const SizedBox(width: 8),
                              const Text('Заявки'),
                              if (totalUnread > 0) ...[
                                const SizedBox(width: 8),
                                _UnreadBadge(count: totalUnread),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Выйти'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}


class _GlassInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}


class _HelpingNowTab extends StatelessWidget {
  final String myId;
  const _HelpingNowTab({required this.myId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Активные заявки, где ты сейчас помогаешь',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _RequestsListSimple(
          query: FirebaseFirestore.instance
              .collection('requests')
              .where('acceptedBy', isEqualTo: myId),
          emptyText: 'Ты пока никому активно не помогаешь.',
          onlyInChat: true,
        ),
      ],
    );
  }
}


int getTotalUnreadFromChats(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs,
  String myId,
) {
  int total = 0;

  for (final doc in chatDocs) {
    final data = doc.data();
    final unreadMap = Map<String, dynamic>.from(data['unreadCountMap'] ?? {});
    final count = unreadMap[myId];

    if (count is num) {
      total += count.toInt();
    }
  }

  return total;
}


class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 9 ? '9+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      constraints: const BoxConstraints(minWidth: 22),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RequestsHubPage extends StatelessWidget {
  const RequestsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Заявки'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Активно помогаю'),
              Tab(text: 'Мои заявки'),
              Tab(text: 'История'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HelpingNowTab(myId: user.uid),
            _MyCreatedRequestsTab(myId: user.uid),
            _RequestsHistoryTab(myId: user.uid),
          ],
        ),
      ),
    );
  }
}


class _MyCreatedRequestsTab extends StatelessWidget {
  final String myId;
  const _MyCreatedRequestsTab({required this.myId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Все заявки, которые ты создавал',
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _RequestsListSimple(
          query: FirebaseFirestore.instance
              .collection('requests')
              .where('authorId', isEqualTo: myId),
          emptyText: 'Ты ещё не создавал заявки.',
        ),
      ],
    );
  }
}


class MyCreatedHistoryList extends StatelessWidget {
  final String myId;
  const MyCreatedHistoryList({super.key, required this.myId});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Дата неизвестна';
    final d = ts.toDate();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'done':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      case 'expired':
        return 'Истекла';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('authorId', isEqualTo: myId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ошибка: ${snap.error}'),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('История твоих заявок пока пуста.'),
          );
        }

        final docs = snap.data!.docs.where((d) {
          final status = (d.data()['status'] ?? '').toString();
          return status == 'done' || status == 'cancelled' || status == 'expired';
        }).toList();

        docs.sort((a, b) {
          final ta = (a.data()['closedAt'] as Timestamp?)?.toDate() ??
              (a.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          final tb = (b.data()['closedAt'] as Timestamp?)?.toDate() ??
              (b.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime(1970);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Пока нет завершённых или отменённых заявок.'),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final category = (data['category'] ?? '').toString();
            final city = (data['city'] ?? '').toString();
            final status = (data['status'] ?? '').toString();
            final closedAt = data['closedAt'] as Timestamp?;
            final helperRating = data['helperRating'];

            final color = _statusColor(status);

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(status),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.category_outlined, text: category),
                        _InfoChip(icon: Icons.location_on_outlined, text: city),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Дата: ${_formatDate(closedAt)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (helperRating != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Оценка помощнику: $helperRating ⭐',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestsHistoryTab extends StatelessWidget {
  final String myId;
  const _RequestsHistoryTab({required this.myId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'История твоей помощи',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        HelpHistoryList(myId: myId),
        const SizedBox(height: 24),
        const Text(
          'История моих заявок',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        MyCreatedHistoryList(myId: myId),
      ],
    );
  }
}

class MyRequestsUnified extends StatelessWidget {
  final String myId;
  const MyRequestsUnified({super.key, required this.myId});

  @override
  Widget build(BuildContext context) {
    final mineQ = FirebaseFirestore.instance
        .collection('requests')
        .where('authorId', isEqualTo: myId);

    final acceptedQ = FirebaseFirestore.instance
        .collection('requests')
        .where('acceptedBy', isEqualTo: myId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Мои заявки',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _RequestsListSimple(
          query: mineQ,
          emptyText: 'Ты ещё не создавал заявки.',
        ),

        const SizedBox(height: 20),
        const Text(
          'Активно помогаю',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _RequestsListSimple(
          query: acceptedQ,
          emptyText: 'Ты пока не принял ни одной заявки.',
          onlyInChat: true,
        ),

        const SizedBox(height: 20),
        const Text(
          'История помощи',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        HelpHistoryList(myId: myId),
      ],
    );
  }
}

class _RequestsListSimple extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  final String emptyText;
  final bool onlyInChat;

  const _RequestsListSimple({
    super.key,
    required this.query,
    required this.emptyText,
    this.onlyInChat = false,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_chat':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'open':
        return 'Открыта';
      case 'in_chat':
        return 'В процессе';
      case 'done':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ошибка: ${snap.error}'),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(emptyText),
          );
        }

        var docs = snap.data!.docs.toList();

        if (onlyInChat) {
          docs = docs.where((d) {
            final status = (d.data()['status'] ?? '').toString();
            return status == 'in_chat';
          }).toList();
        }

        docs.sort((a, b) {
          final ta =
              (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final tb =
              (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(emptyText),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final category = (data['category'] ?? '').toString();
            final city = (data['city'] ?? '').toString();
            final status = (data['status'] ?? '').toString();
            final chatId = (data['chatId'] ?? '').toString();
            final authorId = (data['authorId'] ?? '').toString();
            final acceptedBy = (data['acceptedBy'] ?? '').toString();
            final helperRated = (data['helperRated'] ?? false) == true;

            final isMyRequest = authorId == myId;

            final canCloseAndRate =
                isMyRequest &&
                status == 'in_chat' &&
                acceptedBy.isNotEmpty &&
                !helperRated;

            final badgeColor = _statusColor(status);

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (chatId.isNotEmpty)
                                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chatId)
                                          .snapshots(),
                                      builder: (context, chatSnap) {
                                        if (!chatSnap.hasData || !chatSnap.data!.exists) {
                                          return const SizedBox.shrink();
                                        }

                                        final chatData = chatSnap.data!.data() ?? {};
                                        final unreadMap = Map<String, dynamic>.from(
                                          chatData['unreadCountMap'] ?? {},
                                        );
                                        final countRaw = unreadMap[myId];
                                        final unreadCount =
                                            countRaw is num ? countRaw.toInt() : 0;

                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: _UnreadBadge(count: unreadCount),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(
                                    icon: Icons.category_outlined,
                                    text: category,
                                  ),
                                  _InfoChip(
                                    icon: Icons.location_on_outlined,
                                    text: city,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(status),
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (chatId.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    title: title,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (isMyRequest)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Удалить заявку?'),
                                  content: const Text(
                                    'Это действие нельзя отменить. Удалить заявку?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Отмена'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );

                              if (ok == true) {
                                await FirebaseFirestore.instance
                                    .collection('requests')
                                    .doc(d.id)
                                    .delete();
                              }
                            },
                          ),
                      ],
                    ),
                    if (canCloseAndRate)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await closeRequestAndRateHelper(
                                context: context,
                                requestId: d.id,
                                helperId: acceptedBy,
                              );
                            },
                            icon: const Icon(Icons.star),
                            label: const Text('Завершить и оценить'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HelpHistoryList extends StatelessWidget {
  final String myId;
  const HelpHistoryList({super.key, required this.myId});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Дата неизвестна';
    final d = ts.toDate();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('acceptedBy', isEqualTo: myId)
        .where('status', isEqualTo: 'done');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ошибка: ${snap.error}'),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('История помощи пока пуста.'),
          );
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final ta = (a.data()['closedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final tb = (b.data()['closedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return tb.compareTo(ta);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final category = (data['category'] ?? '').toString();
            final city = (data['city'] ?? '').toString();
            final helperRating = data['helperRating'];
            final closedAt = data['closedAt'] as Timestamp?;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.category_outlined, text: category),
                        _InfoChip(icon: Icons.location_on_outlined, text: city),
                        _InfoChip(
                          icon: Icons.check_circle_outline,
                          text: 'Завершено',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Дата завершения: ${_formatDate(closedAt)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (helperRating != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Оценка: $helperRating ⭐',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}


class RatingDialog extends StatefulWidget {
  final String helperId;
  const RatingDialog({super.key, required this.helperId});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оценка помощи'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Поставь оценку помощнику (1–5 ⭐)'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _rating,
            items: List.generate(
              5,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} ⭐')),
            ),
            onChanged: (v) => setState(() => _rating = v ?? 5),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(context, _rating), child: const Text('Оценить')),
      ],
    );
  }
}

/// =====================
/// CHAT SCREEN (FIRESTORE REALTIME)
/// =====================
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msg = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _markChatAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({
        'unreadCountMap.${user.uid}': 0,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _msg.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _msg.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    try {
      final chatSnap = await chatRef.get();
      final chatData = chatSnap.data() ?? {};
      final members = List<String>.from(chatData['members'] ?? []);

      String? otherUserId;
      for (final id in members) {
        if (id != user.uid) {
          otherUserId = id;
          break;
        }
      }

      await chatRef.collection('messages').add({
        'text': text,
        'senderId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      final updateData = <String, dynamic>{
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCountMap.${user.uid}': 0,
      };

      if (otherUserId != null && otherUserId.isNotEmpty) {
        updateData['unreadCountMap.$otherUserId'] = FieldValue.increment(1);
      }

      await chatRef.update(updateData).timeout(const Duration(seconds: 10));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'chatMessagesCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      final achievementText = await AchievementService().checkAfterFirstChatMessage();

      if (achievementText != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(achievementText)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не отправилось: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final myId = user?.uid;

    final messagesQuery = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesQuery.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Пока нет сообщений'));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markChatAsRead();
                });

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final text = (data['text'] ?? '').toString();
                    final senderId = (data['senderId'] ?? '').toString();
                    final isMe = senderId == myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF7ED957).withOpacity(0.18)
                              : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msg,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: const Icon(Icons.send),
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

Future<void> closeRequestAndRateHelper({
  required BuildContext context,
  required String requestId,
  required String helperId,
}) async {
  final rating = await showDialog<int>(
    context: context,
    builder: (_) => RatingDialog(helperId: helperId),
  );

  if (rating == null) return;

  final db = FirebaseFirestore.instance;
  final requestRef = db.collection('requests').doc(requestId);
  final helperRef = db.collection('users').doc(helperId);

  int newCount = 0;
  double newRating = 5.0;
  int newHelpsCount = 0;

  try {
    await db.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      final helperSnap = await tx.get(helperRef);

      if (!requestSnap.exists) {
        throw Exception('Заявка не найдена');
      }

      final requestData = requestSnap.data() as Map<String, dynamic>;

      if ((requestData['status'] ?? '') == 'done') {
        throw Exception('Заявка уже завершена');
      }

      if ((requestData['helperRated'] ?? false) == true) {
        throw Exception('Оценка уже была поставлена');
      }

      final helperData = helperSnap.data() ?? <String, dynamic>{};

      final oldRating =
          (helperData['rating'] is num) ? (helperData['rating'] as num).toDouble() : 5.0;
      final oldCount =
          (helperData['ratingCount'] is num) ? (helperData['ratingCount'] as num).toInt() : 0;
      final oldHelpsCount =
          (helperData['volunteerHelpsCount'] is num) ? (helperData['volunteerHelpsCount'] as num).toInt() : 0;

      newCount = oldCount + 1;
      newRating = ((oldRating * oldCount) + rating) / newCount;
      newHelpsCount = oldHelpsCount + 1;

      tx.update(helperRef, {
        'rating': newRating,
        'ratingCount': newCount,
        'volunteerHelpsCount': newHelpsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(requestRef, {
        'status': 'done',
        'helperRated': true,
        'helperRating': rating,
        'closedAt': FieldValue.serverTimestamp(),
      });
    });

    final achievementMessages = <String>[];
    achievementMessages.addAll(
      await AchievementService().checkAfterReceivedRatingForUser(
        userId: helperId,
        ratingCount: newCount,
        rating: newRating,
      ),
    );
    achievementMessages.addAll(
      await AchievementService().checkAfterVolunteerHelpCountForUser(
        userId: helperId,
        helpsCount: newHelpsCount,
      ),
    );

    if (!context.mounted) return;

    final text = achievementMessages.isEmpty
        ? 'Заявка завершена, оценка сохранена ✅'
        : 'Заявка завершена, оценка сохранена ✅\n${achievementMessages.join('\n')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка завершения: $e')),
    );
  }
}


class AcceptedByMeList extends StatelessWidget {
  final String myId;
  const AcceptedByMeList({super.key, required this.myId});

  @override
  Widget build(BuildContext context) {
    // ✅ Без orderBy/whereIn — чтобы не требовать индекс
    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('acceptedBy', isEqualTo: myId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ошибка: ${snap.error}'),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Ты пока не принял ни одной заявки.'),
          );
        }

        // ✅ Фильтр по статусу на клиенте
        final docs = snap.data!.docs.where((d) {
          final data = d.data();
          final s = (data['status'] ?? '').toString();
          return s == 'in_chat';
        }).toList();

        // ✅ Сортировка по createdAt на клиенте
        docs.sort((a, b) {
          final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Сейчас нет активных принятых заявок.'),
          );
        }

        // ✅ Не Column, чтобы не было overflow
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final status = (data['status'] ?? '').toString();
            final chatId = (data['chatId'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text('Статус: $status'),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: chatId.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chatId, title: title),
                          ),
                        );
                      },
              ),
            );
          },
        );
      },
    );
  }
}
