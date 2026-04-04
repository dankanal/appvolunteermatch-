import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.selectedCity,
    required this.onCityChanged,
  });

  static const List<String> cities = [
    'Шымкент',
    'Алматы',
    'Астана',
    'Караганда',
    'Тараз',
    'Туркестан',
    'Кызылорда',
    'Актобе',
    'Атырау',
    'Павлодар',
    'Семей',
    'Усть-Каменогорск',
    'Костанай',
    'Петропавловск',
    'Уральск',
    'Актау',
    'Талдыкорган',
    'Кокшетау',
  ];

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Ты действительно хочешь выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    html.window.localStorage.remove('vm_login_time');
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final card = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final text = isDarkMode ? Colors.white : const Color(0xFF111827);
    final sub = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDarkMode,
                  onChanged: onThemeChanged,
                  title: Text(
                    'Тёмная тема',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Переключение светлой и тёмной темы',
                    style: TextStyle(color: sub),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Город',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    selectedCity,
                    style: TextStyle(color: sub),
                  ),
                  trailing: DropdownButton<String>(
                    value: selectedCity,
                    underline: const SizedBox(),
                    items: cities
                        .map(
                          (city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onCityChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: Text(
                    'Уведомления',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Скоро добавим настройки уведомлений',
                    style: TextStyle(color: sub),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(
                    'О приложении',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Volunteer Match',
                    style: TextStyle(color: sub),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text(
                    'Выйти из аккаунта',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Завершить текущую сессию',
                    style: TextStyle(color: sub),
                  ),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}