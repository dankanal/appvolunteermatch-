import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  final controller = PageController();
  int page = 0;

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("onboarding_seen", true);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, "/auth");
  }

  @override
  Widget build(BuildContext context) {

    final pages = [

      _Page(
        icon: Icons.volunteer_activism,
        title: "Помогай людям рядом",
        text: "Находи заявки поблизости и помогай тем, кому нужна помощь",
      ),

      _Page(
        icon: Icons.add_circle_outline,
        title: "Создавай заявки",
        text: "Нужна помощь? Создай заявку и волонтёры откликнутся",
      ),

      _Page(
        icon: Icons.chat_bubble_outline,
        title: "Общайся в чате",
        text: "После отклика вы сможете общаться прямо в приложении",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5E1),

      body: Column(
        children: [

          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,

              onPageChanged: (i) {
                setState(() {
                  page = i;
                });
              },

              itemBuilder: (_, i) => pages[i],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),

            child: page == pages.length - 1
                ? SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: finish,
                      child: const Text("Начать"),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      TextButton(
                        onPressed: finish,
                        child: const Text("Пропустить"),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        },

                        child: const Text("Далее"),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {

  final IconData icon;
  final String title;
  final String text;

  const _Page({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(40),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 120,
            color: const Color(0xFF4C7A38),
          ),

          const SizedBox(height: 40),

          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}