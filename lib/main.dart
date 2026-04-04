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
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:intl/intl.dart';




const List<String> kAvailableCities = [
  'Алматы',
  'Астана',
  'Шымкент',
  'Караганда',
  'Актобе',
  'Тараз',
  'Павлодар',
  'Семей',
  'Усть-Каменогорск',
  'Костанай',
  'Кызылорда',
  'Атырау',
  'Актау',
  'Петропавловск',
  'Туркестан',
];

String normalizeCity(String? city) {
  final value = (city ?? '').trim();
  if (value.isEmpty) return kAvailableCities.first;
  if (kAvailableCities.contains(value)) return value;
  return kAvailableCities.first;
}
class EventRegistrationDialog extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventRegistrationDialog({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventRegistrationDialog> createState() => _EventRegistrationDialogState();
}



class _EventRegistrationDialogState extends State<EventRegistrationDialog> {
  final _fullNameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _schoolCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final askFullName = widget.eventData['askFullName'] == true;
    final askSchool = widget.eventData['askSchool'] == true;
    final askUniversity = widget.eventData['askUniversity'] == true;

    if (askFullName && _fullNameCtrl.text.trim().isEmpty) {
      AppNotice.show(
        context,
        message: 'Заполни имя и фамилию',
        type: AppNoticeType.error,
      );
      return;
    }

    if (askSchool && _schoolCtrl.text.trim().isEmpty) {
      AppNotice.show(
        context,
        message: 'Заполни школу',
        type: AppNoticeType.error,
      );
      return;
    }

    if (askUniversity && _universityCtrl.text.trim().isEmpty) {
      AppNotice.show(
        context,
        message: 'Заполни университет',
        type: AppNoticeType.error,
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final regRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('registrations')
          .doc(user.uid);

      await regRef.set({
        'userId': user.uid,
        'email': user.email ?? '',
        'fullName': _fullNameCtrl.text.trim(),
        'school': _schoolCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      AppNotice.show(
        context,
        message: 'Ты зарегистрирован на ивент',
        type: AppNoticeType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка регистрации: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final askFullName = widget.eventData['askFullName'] == true;
    final askSchool = widget.eventData['askSchool'] == true;
    final askUniversity = widget.eventData['askUniversity'] == true;

    return AlertDialog(
      title: const Text('Регистрация на ивент'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (askFullName) ...[
              TextField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (askSchool) ...[
              TextField(
                controller: _schoolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Школа',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (askUniversity) ...[
              TextField(
                controller: _universityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Университет',
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Выйти'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const LeafSpinner(size: 18, color: Colors.white)
              : const Text('Отправить'),
        ),
      ],
    );
  }
}


class EventDetailsDialog extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;

  const EventDetailsDialog({
    super.key,
    required this.eventId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final place = (data['place'] ?? '').toString();
    final startAt = data['startAt'] as Timestamp?;
    final dateText = startAt == null
        ? 'Дата не указана'
        : DateFormat('dd.MM.yyyy • HH:mm').format(startAt.toDate());

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Image.network(
                  imageUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF466E2D),
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('📍 $place'),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => EventRegistrationDialog(
                                  eventId: eventId,
                                  eventData: data,
                                ),
                              );
                            },
                            child: const Text('Участвовать'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Закрыть'),
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
      ),
    );
  }
}

class EventBigCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;

  const EventBigCard({
    super.key,
    required this.eventId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final place = (data['place'] ?? '').toString();
    final startAt = data['startAt'] as Timestamp?;
    final dateText = startAt == null
        ? 'Дата не указана'
        : DateFormat('dd.MM.yyyy • HH:mm').format(startAt.toDate());

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => EventDetailsDialog(
            eventId: eventId,
            data: data,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: imageUrl.isEmpty
              ? const LinearGradient(
                  colors: [
                    Color(0xFFA8E932),
                    Color(0xFFEAF7C7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.08),
                  Colors.black.withOpacity(0.48),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dateText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF091633),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                if (place.isNotEmpty)
                  Text(
                    '📍 $place',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.45,
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


class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Future<Map<String, dynamic>?> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return snap.data();
  }

  Future<void> _openCreateEventDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final placeCtrl = TextEditingController();

    DateTime startAt = DateTime.now().add(const Duration(days: 1));

    bool askFullName = true;
    bool askSchool = false;
    bool askUniversity = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Создать ивент'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: placeCtrl,
                    decoration: const InputDecoration(labelText: 'Место'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(labelText: 'URL картинки'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Описание'),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: askFullName,
                    onChanged: (v) => setLocal(() => askFullName = v ?? false),
                    title: const Text('Спрашивать имя и фамилию'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: askSchool,
                    onChanged: (v) => setLocal(() => askSchool = v ?? false),
                    title: const Text('Спрашивать школу'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: askUniversity,
                    onChanged: (v) => setLocal(() => askUniversity = v ?? false),
                    title: const Text('Спрашивать университет'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(DateFormat('dd.MM.yyyy HH:mm').format(startAt)),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: startAt,
                        );
                        if (date == null) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(startAt),
                        );
                        if (time == null) return;

                        setLocal(() {
                          startAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: const Text('Выбрать'),
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
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
      AppNotice.show(
        context,
        message: 'Заполни название и описание ивента',
        type: AppNoticeType.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final roleSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = (roleSnap.data()?['role'] ?? 'user').toString();

    if (role != 'admin' && role != 'moderator') {
      AppNotice.show(
        context,
        message: 'Только модератор или админ может создавать ивенты',
        type: AppNoticeType.error,
      );
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'imageUrl': imageCtrl.text.trim(),
      'place': placeCtrl.text.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'isActive': true,
      'askFullName': askFullName,
      'askSchool': askSchool,
      'askUniversity': askUniversity,
      'createdBy': user.uid,
      'createdByRole': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    AppNotice.show(
      context,
      message: 'Ивент создан',
      type: AppNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('events')
        .where('isActive', isEqualTo: true)
        .orderBy('startAt', descending: false)
        .snapshots();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadRole(),
      builder: (context, roleSnap) {
        final role = (roleSnap.data?['role'] ?? 'user').toString();
        final canCreate = role == 'admin' || role == 'moderator';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ивенты',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (canCreate)
                      FilledButton.icon(
                        onPressed: () => _openCreateEventDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Создать'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: stream,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: LeafSpinner(size: 30));
                      }

                      if (snap.hasError) {
                        return Center(
                          child: Text('Ошибка загрузки ивентов: ${snap.error}'),
                        );
                      }

                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Пока ивентов нет'),
                        );
                      }

                      final docs = snap.data!.docs;

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data();
                          return EventBigCard(
                            eventId: doc.id,
                            data: data,
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
      },
    );
  }
}

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль пользователя'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: LeafSpinner(size: 34));
            }

            if (!snap.data!.exists) {
              return const Center(
                child: Text('Пользователь не найден'),
              );
            }

            final data = snap.data!.data() ?? {};

            final name = (data['name'] ?? 'Без имени').toString();
            final email = (data['email'] ?? '').toString();
            final avatarUrl = (data['avatarUrl'] ?? '').toString();
            final bio = (data['bio'] ?? '').toString();
            final backgroundUrl = (data['profileBackground'] ?? '').toString();

            final rating = (data['rating'] is num)
                ? (data['rating'] as num).toDouble()
                : 5.0;

            final ratingCount = (data['ratingCount'] is num)
                ? (data['ratingCount'] as num).toInt()
                : 0;

            final createdRequestsCount = (data['createdRequestsCount'] is num)
                ? (data['createdRequestsCount'] as num).toInt()
                : 0;

            final volunteerHelpsCount = (data['volunteerHelpsCount'] is num)
                ? (data['volunteerHelpsCount'] as num).toInt()
                : 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFF4F7EF),
                    image: backgroundUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(backgroundUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: backgroundUrl.isNotEmpty
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.28),
                                  Colors.black.withOpacity(0.10),
                                ],
                              )
                            : null,
                        color: backgroundUrl.isEmpty
                            ? Colors.white
                            : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(0xFFC8F0A4),
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 42)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundUrl.isNotEmpty
                                  ? Colors.white.withOpacity(0.78)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundUrl.isNotEmpty
                                    ? Colors.white.withOpacity(0.68)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                email,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _PublicProfileStatChip(
                                icon: Icons.star_outline,
                                text: '${rating.toStringAsFixed(1)} ⭐',
                              ),
                              _PublicProfileStatChip(
                                icon: Icons.reviews_outlined,
                                text: '$ratingCount оценок',
                              ),
                              _PublicProfileStatChip(
                                icon: Icons.edit_note,
                                text: '$createdRequestsCount заявок',
                              ),
                              _PublicProfileStatChip(
                                icon: Icons.volunteer_activism_outlined,
                                text: '$volunteerHelpsCount помощи',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        bio,
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}


class UserMiniProfileButton extends StatelessWidget {
  final String userId;
  final bool compact;

  const UserMiniProfileButton({
    super.key,
    required this.userId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('users').doc(userId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = (data['name'] ?? 'Без имени').toString();
        final avatarUrl = (data['avatarUrl'] ?? '').toString();

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(userId: userId),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: compact ? 13 : 16,
                  backgroundColor: const Color(0xFFC8F0A4),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: compact ? 14 : 16,
                          color: Colors.black87,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 110 : 170,
                  ),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _PublicProfileStatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PublicProfileStatChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
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


class CloudinaryImageService {
  final ImagePicker _picker = ImagePicker();

  static const String cloudName = 'dvdizve6c';
  static const String uploadPreset = 'volunteer_app';

  Future<String?> pickAndUploadImage({
    required String folder,
    int imageQuality = 85,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload error: ${response.statusCode} $body');
    }

    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = (jsonMap['secure_url'] ?? '').toString();

    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary не вернул secure_url');
    }

    return secureUrl;
  }
}


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
          builder: (_) => const IntroGate(),
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

class VolunteerMatchApp extends StatefulWidget {
  const VolunteerMatchApp({super.key});

  @override
  State<VolunteerMatchApp> createState() => _VolunteerMatchAppState();
}

class _VolunteerMatchAppState extends State<VolunteerMatchApp> {
  final AppSettingsController _settings = AppSettingsController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _settings.load();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  ThemeData _buildTheme(bool dark) {
    final seed = const Color(0xFF7FBF3F);

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0E1511) : const Color(0xFFF7FAF4),
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: dark ? Colors.white : const Color(0xFF091633),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF16201A) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF18231D) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF466E2D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF121A15) : Colors.white,
        indicatorColor: const Color(0xFFA8E932).withOpacity(0.20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Stack(
            children: [
              FallingLeavesBackground(),
              Center(child: LeafSpinner(size: 42)),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Volunteer Match',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(_settings.isDarkMode),
          home: AuthGateWithSettings(settings: _settings),
        );
      },
    );
  }
}


Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("onboarding_seen") ?? false;
}


class AuthGateWithSettings extends StatefulWidget {
  final AppSettingsController settings;

  const AuthGateWithSettings({
    super.key,
    required this.settings,
  });

  @override
  State<AuthGateWithSettings> createState() => _AuthGateWithSettingsState();
}

class _AuthGateWithSettingsState extends State<AuthGateWithSettings> {
  bool _checkedSession = false;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  Future<void> _prepareSession() async {
    final auth = FirebaseAuth.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final savedAt = html.window.localStorage['vm_login_time'];

    if (auth.currentUser == null) {
      html.window.localStorage.remove('vm_login_time');
    } else if (savedAt == null) {
      html.window.localStorage['vm_login_time'] = now.toString();
    } else {
      final loginTime = int.tryParse(savedAt) ?? now;
      final diffMs = now - loginTime;
      final hours48 = const Duration(hours: 48).inMilliseconds;

      if (diffMs > hours48) {
        await auth.signOut();
        html.window.localStorage.remove('vm_login_time');
      }
    }

    if (!mounted) return;
    setState(() => _checkedSession = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedSession) {
      return const Scaffold(
        body: Stack(
          children: [
            FallingLeavesBackground(),
            Center(child: LeafSpinner(size: 42)),
          ],
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Stack(
              children: [
                FallingLeavesBackground(),
                Center(child: LeafSpinner(size: 42)),
              ],
            ),
          );
        }

        final user = snap.data;

        if (user == null) {
          return const IntroGate();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        return MainShell(settings: widget.settings);
      },
    );
  }
}


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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// тема + город
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

                    items: cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),

                    onChanged: (v) {
                      if (v != null) {
                        onCityChanged(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// выход
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(

              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),

              title: const Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),

              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}





class FallingLeavesBackground extends StatefulWidget {
  final bool dense;

  const FallingLeavesBackground({
    super.key,
    this.dense = false,
  });

  @override
  State<FallingLeavesBackground> createState() => _FallingLeavesBackgroundState();
}

class _FallingLeavesBackgroundState extends State<FallingLeavesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = math.Random(7);

  late final List<_LeafSpec> _leaves;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final count = widget.dense ? 22 : 14;
    _leaves = List.generate(count, (_) {
      return _LeafSpec(
        startX: _random.nextDouble(),
        size: 16 + _random.nextDouble() * 28,
        durationFactor: 0.7 + _random.nextDouble() * 0.9,
        delay: _random.nextDouble(),
        drift: (_random.nextDouble() - 0.5) * 0.18,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2.2,
        opacity: 0.18 + _random.nextDouble() * 0.32,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progress(double t, double delay, double durationFactor) {
    final shifted = (t * durationFactor + delay) % 1.0;
    return shifted;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7FAEF),
                        Color(0xFFEDF6D9),
                        Color(0xFFF9FBF4),
                      ],
                    ),
                  ),
                ),
                for (final leaf in _leaves)
                  () {
                    final p = _progress(t, leaf.delay, leaf.durationFactor);
                    final x = (leaf.startX + math.sin(p * math.pi * 2) * leaf.drift) * w;
                    final y = (p * 1.25 - 0.15) * h;
                    final angle = p * math.pi * 2 * leaf.rotationSpeed;

                    return Positioned(
                      left: x.clamp(-40.0, w + 40.0),
                      top: y,
                      child: Opacity(
                        opacity: leaf.opacity,
                        child: Transform.rotate(
                          angle: angle,
                          child: Icon(
                            Icons.eco_outlined,
                            size: leaf.size,
                            color: const Color(0xFF7FAF44),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            );
          },
        );
      },
    );
  }
}

class _LeafSpec {
  final double startX;
  final double size;
  final double durationFactor;
  final double delay;
  final double drift;
  final double rotationSpeed;
  final double opacity;

  _LeafSpec({
    required this.startX,
    required this.size,
    required this.durationFactor,
    required this.delay,
    required this.drift,
    required this.rotationSpeed,
    required this.opacity,
  });
}

class LeafSpinner extends StatefulWidget {
  final double size;
  final Color color;

  const LeafSpinner({
    super.key,
    this.size = 26,
    this.color = const Color(0xFF4C7B2F),
  });

  @override
  State<LeafSpinner> createState() => _LeafSpinnerState();
}

class _LeafSpinnerState extends State<LeafSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _leaf(double angle, double scale, double opacity) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Icon(
            Icons.eco,
            size: widget.size * 0.42,
            color: widget.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;

          return Transform.rotate(
            angle: t * math.pi * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -widget.size * 0.34),
                  child: _leaf(0.1, 1.00, 1.00),
                ),
                Transform.translate(
                  offset: Offset(widget.size * 0.30, 0),
                  child: _leaf(1.7, 0.88, 0.82),
                ),
                Transform.translate(
                  offset: Offset(0, widget.size * 0.34),
                  child: _leaf(3.2, 0.76, 0.64),
                ),
                Transform.translate(
                  offset: Offset(-widget.size * 0.30, 0),
                  child: _leaf(4.8, 0.64, 0.46),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Используй AuthGateWithSettings вместо AuthGate'),
      ),
    );
  }
}

class _IntroTopBar extends StatelessWidget {
  final VoidCallback onOpenWebsite;
  final VoidCallback onDownloadApk;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _IntroTopBar({
    required this.onOpenWebsite,
    required this.onDownloadApk,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8E932),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.eco, color: Color(0xFF12203A)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volunteer Match',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101B36),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Помощь рядом, когда она нужна',
                            style: TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: onOpenWebsite,
                      child: const Text('Сайт'),
                    ),
                    OutlinedButton(
                      onPressed: onLogin,
                      child: const Text('Войти'),
                    ),
                    FilledButton(
                      onPressed: onRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F1933),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Регистрация'),
                    ),
                    FilledButton(
                      onPressed: onDownloadApk,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA8E932),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('APK'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E932),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco, color: Color(0xFF12203A)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteer Match',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101B36),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Помощь рядом, когда она нужна',
                        style: TextStyle(
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onOpenWebsite,
                  child: const Text('Сайт'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onLogin,
                  child: const Text('Войти'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onRegister,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1933),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Регистрация'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onDownloadApk,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA8E932),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('APK'),
                ),
              ],
            ),
    );
  }
}



class IntroScreen extends StatelessWidget {
  final VoidCallback onOpenApp;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const IntroScreen({
    super.key,
    required this.onOpenApp,
    required this.onLogin,
    required this.onRegister,
  });

  Future<void> _openLanding() async {
    final uri = Uri.parse('https://volunteermatch1.netlify.app/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadApk() async {
    final uri = Uri.parse('https://volunteermatch1.netlify.app/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8EA),
      body: Stack(
        children: [
          const Positioned.fill(
            child: FallingLeavesBackground(dense: true),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IntroTopBar(
                        onOpenWebsite: _openLanding,
                        onDownloadApk: _downloadApk,
                        onLogin: onLogin,
                        onRegister: onRegister,
                      ),
                      const SizedBox(height: 28),
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _IntroHero(
                                    onOpenApp: onOpenApp,
                                    onDownloadApk: _downloadApk,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                const Expanded(
                                  child: _PhonePreviewCard(),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _IntroHero(
                                  onOpenApp: onOpenApp,
                                  onDownloadApk: _downloadApk,
                                ),
                                const SizedBox(height: 24),
                                const _PhonePreviewCard(),
                              ],
                            ),
                      const SizedBox(height: 28),
                      const _SectionTitle('Почему это удобно'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: const [
                          _FeatureCard(
                            icon: Icons.place_outlined,
                            title: 'Рядом',
                            text: 'Помощь и волонтёры поблизости.',
                          ),
                          _FeatureCard(
                            icon: Icons.shield_outlined,
                            title: 'Безопасно',
                            text: 'Профиль, рейтинг и прозрачная активность.',
                          ),
                          _FeatureCard(
                            icon: Icons.flash_on_outlined,
                            title: 'Быстро',
                            text: 'Быстрые отклики и удобный чат.',
                          ),
                          _FeatureCard(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Полезно',
                            text: 'Достижения, активность и история помощи.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle('Как это работает'),
                      const SizedBox(height: 16),
                      const _StepTile(
                        index: '1',
                        title: 'Создай заявку',
                        text: 'Опиши, какая помощь нужна и где ты находишься.',
                      ),
                      const _StepTile(
                        index: '2',
                        title: 'Получи отклик',
                        text: 'Волонтёр рядом увидит заявку и откликнется.',
                      ),
                      const _StepTile(
                        index: '3',
                        title: 'Общайся в чате',
                        text: 'Договоритесь о деталях прямо внутри приложения.',
                      ),
                      const _StepTile(
                        index: '4',
                        title: 'Заверши и оцени',
                        text: 'После помощи можно поставить оценку и получить достижения.',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AppLocationResult {
  final double? lat;
  final double? lng;
  final String? city;
  final String? error;

  const AppLocationResult({
    this.lat,
    this.lng,
    this.city,
    this.error,
  });

  bool get ok => lat != null && lng != null && error == null;
}

class AppLocationService {
  Future<AppLocationResult> getCurrentLocationWithCity() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const AppLocationResult(
          error: 'Геолокация на устройстве выключена',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const AppLocationResult(
          error: 'Доступ к геолокации запрещён',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const AppLocationResult(
          error: 'Доступ к геолокации навсегда запрещён в настройках браузера/телефона',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String city = 'Неизвестно';

      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = [
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
          ].firstWhere(
            (e) => e != null && e.trim().isNotEmpty,
            orElse: () => 'Неизвестно',
          )!;
        }
      } catch (_) {
        city = 'Неизвестно';
      }

      return AppLocationResult(
        lat: pos.latitude,
        lng: pos.longitude,
        city: city,
      );
    } catch (e) {
      return AppLocationResult(
        error: 'Ошибка геолокации: $e',
      );
    }
  }
}

enum AppNoticeType {
  success,
  error,
  info,
}

class AppNotice {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    AppNoticeType type = AppNoticeType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final color = switch (type) {
      AppNoticeType.success => const Color(0xFF1E8E3E),
      AppNoticeType.error => const Color(0xFFD93025),
      AppNoticeType.info => const Color(0xFF0F1933),
    };

    final icon = switch (type) {
      AppNoticeType.success => Icons.check_circle_rounded,
      AppNoticeType.error => Icons.error_rounded,
      AppNoticeType.info => Icons.info_rounded,
    };

    final entry = OverlayEntry(
      builder: (context) => _AppNoticeOverlay(
        message: message,
        color: color,
        icon: icon,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}


class _AppNoticeOverlay extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _AppNoticeOverlay({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  State<_AppNoticeOverlay> createState() => _AppNoticeOverlayState();
}

class _AppNoticeOverlayState extends State<_AppNoticeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.black.withOpacity(0.18),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _IntroHero extends StatelessWidget {
  final VoidCallback onOpenApp;
  final VoidCallback onDownloadApk;

  const _IntroHero({
    required this.onOpenApp,
    required this.onDownloadApk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD6E7A8)),
          ),
          child: const Text(
            '✨ Мобильное приложение для волонтёрской помощи',
            style: TextStyle(
              color: Color(0xFF4C5565),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Volunteer Match —\nпомощь людям\nрядом с вами',
          style: TextStyle(
            fontSize: 54,
            height: 0.96,
            fontWeight: FontWeight.w900,
            color: Color(0xFF091633),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Создавайте заявки, находите волонтёров поблизости, общайтесь в чате и делайте добрые дела быстрее и удобнее.',
          style: TextStyle(
            fontSize: 20,
            height: 1.5,
            color: Color(0xFF5F6B7A),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            FilledButton(
              onPressed: onDownloadApk,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA8E932),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Скачать Android APK',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton(
              onPressed: onOpenApp,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Открыть приложение',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhonePreviewCard extends StatelessWidget {
  const _PhonePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6DA),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE3EFBE), width: 10),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ближайшая заявка',
                    style: TextStyle(color: Color(0xFF7C8798)),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Нужны продукты',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF091633),
                          ),
                        ),
                      ),
                      _UrgentBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _MiniInfo(text: '📍 1.2 км'),
                      _MiniInfo(text: '⏳ 2 часа'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08132D),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Чат',
                    style: TextStyle(
                      color: Color(0xFFB7C4DD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ChatBubble(
                      text: 'Здравствуйте, я рядом и могу помочь через 20 минут.',
                      dark: true,
                    ),
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ChatBubble(
                      text: 'Спасибо! Напишу адрес в личные сообщения.',
                      dark: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _BottomMiniCard(
                    icon: Icons.star_border,
                    title: 'Рейтинг и отзывы',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _BottomMiniCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Достижения и активность',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBackground extends StatefulWidget {
  const _IntroBackground();

  @override
  State<_IntroBackground> createState() => _IntroBackgroundState();
}

class _IntroBackgroundState extends State<_IntroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _leaf(double size, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Icon(
        Icons.eco_outlined,
        size: size,
        color: const Color(0xFF86B84C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6F9EB),
                    Color(0xFFF0F5DE),
                    Color(0xFFF8FBF1),
                  ],
                ),
              ),
            ),
            Positioned(left: 40 + 20 * t, top: 140, child: _leaf(42, 0.55)),
            Positioned(right: 90, top: 90 + 24 * t, child: _leaf(36, 0.35)),
            Positioned(left: 130, bottom: 140 + 16 * t, child: _leaf(34, 0.4)),
            Positioned(right: 140 + 18 * t, bottom: 80, child: _leaf(48, 0.5)),
            Positioned(left: 260, top: 300 + 14 * t, child: _leaf(28, 0.32)),
            Positioned(right: 320, top: 220, child: _leaf(30, 0.28)),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF79B100), size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF091633),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF687486),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String index;
  final String title;
  final String text;

  const _StepTile({
    required this.index,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFA8E932),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              index,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF091633),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF687486),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Color(0xFF091633),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String text;
  const _MiniInfo({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF5F6B7A)),
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'СРОЧНО',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool dark;

  const _ChatBubble({
    required this.text,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E2A4A) : const Color(0xFFA8E932),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          height: 1.45,
        ),
      ),
    );
  }
}

class _BottomMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _BottomMiniCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: const Color(0xFF091633)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5F6B7A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class IntroGate extends StatefulWidget {
  const IntroGate({super.key});

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  bool _loading = true;
  bool _showAuth = false;
  bool _startInLoginMode = true;

  @override
  void initState() {
    super.initState();
    _loadIntroState();
  }

  Future<void> _loadIntroState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('intro_seen') ?? false;

    if (!mounted) return;
    setState(() {
      _showAuth = seen;
      _loading = false;
    });
  }

  Future<void> _openAuth({required bool loginMode}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);

    if (!mounted) return;
    setState(() {
      _startInLoginMode = loginMode;
      _showAuth = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Stack(
          children: [
            FallingLeavesBackground(),
            Center(child: LeafSpinner(size: 34)),
          ],
        ),
      );
    }

    if (_showAuth) {
      return EmailAuthScreen(initialIsLogin: _startInLoginMode);
    }

    return IntroScreen(
      onOpenApp: () => _openAuth(loginMode: true),
      onLogin: () => _openAuth(loginMode: true),
      onRegister: () => _openAuth(loginMode: false),
    );
  }
}


class EmailAuthScreen extends StatefulWidget {
  final bool initialIsLogin;

  const EmailAuthScreen({
    super.key,
    this.initialIsLogin = true,
  });

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  late bool _isLogin;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

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
        'role': 'user',
        'city': kAvailableCities.first,
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
      if (!data.containsKey('role')) {
        patch['role'] = 'user';
      }
      if (!data.containsKey('city')) {
        patch['city'] = kAvailableCities.first;
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
      AppNotice.show(
        context,
        message: 'Email нормальный, пароль минимум 6 символов',
        type: AppNoticeType.error,
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

        html.window.localStorage['vm_login_time'] =
            DateTime.now().millisecondsSinceEpoch.toString();

        await FirebaseAuth.instance.currentUser?.reload();

        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          if (!mounted) return;
          AppNotice.show(
            context,
            message: 'Почта ещё не подтверждена. Проверь письмо.',
            type: AppNoticeType.info,
          );
        }
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        await _ensureUserDoc(cred.user!);

        html.window.localStorage['vm_login_time'] =
            DateTime.now().millisecondsSinceEpoch.toString();

        await cred.user?.sendEmailVerification();
        await FirebaseAuth.instance.currentUser?.reload();

        if (!mounted) return;
        AppNotice.show(
          context,
          message: 'Аккаунт создан. Письмо для подтверждения отправлено.',
          type: AppNoticeType.success,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: e.message ?? e.code,
        type: AppNoticeType.error,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _backToIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const IntroGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      body: Stack(
        children: [
          const FallingLeavesBackground(dense: true),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: isWide
                      ? Row(
                          children: [
                            const Expanded(child: _AuthSideInfo()),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _AuthCard(
                                isLogin: _isLogin,
                                busy: _busy,
                                emailController: _email,
                                passController: _pass,
                                onSubmit: _submitEmail,
                                onToggle: () {
                                  setState(() => _isLogin = !_isLogin);
                                },
                                onBack: _backToIntro,
                              ),
                            ),
                          ],
                        )
                      : _AuthCard(
                          isLogin: _isLogin,
                          busy: _busy,
                          emailController: _email,
                          passController: _pass,
                          onSubmit: _submitEmail,
                          onToggle: () {
                            setState(() => _isLogin = !_isLogin);
                          },
                          onBack: _backToIntro,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AppSettingsController extends ChangeNotifier {
  static const _darkModeKey = 'app_dark_mode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}


class _AuthSideInfo extends StatelessWidget {
  const _AuthSideInfo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Добро пожаловать\nв Volunteer Match',
            style: TextStyle(
              fontSize: 48,
              height: 0.98,
              fontWeight: FontWeight.w900,
              color: Color(0xFF091633),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Находи помощь рядом, общайся в чате, закрывай заявки и копи достижения за добрые дела.',
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Color(0xFF5F6B7A),
            ),
          ),
          SizedBox(height: 24),
          _AuthInfoBullet(text: 'Заявки рядом по городу и расстоянию'),
          SizedBox(height: 10),
          _AuthInfoBullet(text: 'Чат между пользователями внутри заявки'),
          SizedBox(height: 10),
          _AuthInfoBullet(text: 'Рейтинг, история помощи и достижения'),
        ],
      ),
    );
  }
}

class _AuthInfoBullet extends StatelessWidget {
  final String text;
  const _AuthInfoBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFA8E932),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, size: 18, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF465266),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isLogin;
  final bool busy;
  final TextEditingController emailController;
  final TextEditingController passController;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;
  final VoidCallback onBack;

  const _AuthCard({
    required this.isLogin,
    required this.busy,
    required this.emailController,
    required this.passController,
    required this.onSubmit,
    required this.onToggle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              label: const Text('Назад'),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFA8E932),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.eco, size: 36, color: Color(0xFF12203A)),
          ),
          const SizedBox(height: 16),
          Text(
            isLogin ? 'С возвращением' : 'Создайте аккаунт',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF091633),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Войдите, чтобы продолжить пользоваться Volunteer Match'
                : 'Зарегистрируйтесь и начните помогать людям рядом',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email',
              prefixIcon: const Icon(Icons.mail_outline),
              filled: true,
              fillColor: const Color(0xFFF6F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Пароль (мин. 6)',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: const Color(0xFFF6F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF466E2D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: busy
                  ? const LeafSpinner(
                      size: 24,
                      color: Colors.white,
                    )
                  : Text(
                      isLogin ? 'Войти' : 'Создать аккаунт',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: busy ? null : onToggle,
            child: Text(
              isLogin
                  ? 'Нет аккаунта? Регистрация'
                  : 'Уже есть аккаунт? Войти',
            ),
          ),
        ],
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
  bool _resending = false;

  Future<void> _checkVerified() async {
    setState(() => _busy = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      final achievementText = await AchievementService().checkVerifiedEmail();

      if (!mounted) return;

      if (achievementText != null) {
        AppNotice.show(
          context,
          message: achievementText,
          type: AppNoticeType.success,
        );
      } else {
        AppNotice.show(
          context,
          message: 'Почта ещё не подтверждена',
          type: AppNoticeType.info,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка проверки: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Письмо отправлено ещё раз',
        type: AppNoticeType.info,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка отправки: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  Future<void> _logout() async {
    html.window.localStorage.remove('vm_login_time');
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      body: Stack(
        children: [
          const FallingLeavesBackground(dense: true),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: isWide
                      ? Row(
                          children: [
                            const Expanded(child: _VerifyInfoSide()),
                            const SizedBox(width: 28),
                            Expanded(
                              child: _VerifyCard(
                                email: user?.email ?? '-',
                                busy: _busy,
                                resending: _resending,
                                onCheck: _checkVerified,
                                onResend: _resendEmail,
                                onLogout: _logout,
                              ),
                            ),
                          ],
                        )
                      : _VerifyCard(
                          email: user?.email ?? '-',
                          busy: _busy,
                          resending: _resending,
                          onCheck: _checkVerified,
                          onResend: _resendEmail,
                          onLogout: _logout,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyInfoSide extends StatelessWidget {
  const _VerifyInfoSide();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Остался\nпоследний шаг',
            style: TextStyle(
              fontSize: 46,
              height: 0.98,
              fontWeight: FontWeight.w900,
              color: Color(0xFF091633),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Подтверди email, чтобы открыть доступ ко всем функциям Volunteer Match.',
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Color(0xFF5F6B7A),
            ),
          ),
          SizedBox(height: 24),
          _AuthInfoBullet(text: 'Безопасный вход и подтверждённый профиль'),
          SizedBox(height: 10),
          _AuthInfoBullet(text: 'Доступ к заявкам, чату и рейтингу'),
          SizedBox(height: 10),
          _AuthInfoBullet(text: 'Первое достижение за подтверждение почты'),
        ],
      ),
    );
  }
}

class _VerifyCard extends StatelessWidget {
  final String email;
  final bool busy;
  final bool resending;
  final VoidCallback onCheck;
  final VoidCallback onResend;
  final VoidCallback onLogout;

  const _VerifyCard({
    required this.email,
    required this.busy,
    required this.resending,
    required this.onCheck,
    required this.onResend,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFA8E932),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: Color(0xFF12203A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Подтверди почту',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF091633),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Мы отправили письмо на:\n$email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Открой письмо, нажми ссылку подтверждения, потом вернись сюда и нажми кнопку ниже.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF667085),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onCheck,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF466E2D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: busy
                  ? const LeafSpinner(
                      size: 24,
                      color: Colors.white,
                    )
                  : const Text(
                      'Я подтвердил',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: resending ? null : onResend,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: resending
                  ? const LeafSpinner(size: 24)
                  : const Text('Отправить письмо ещё раз'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onLogout,
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// MAIN SHELL
/// =====================


class MainShell extends StatefulWidget {
  final AppSettingsController settings;

  const MainShell({
    super.key,
    required this.settings,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  String _selectedCity = kAvailableCities.first;
  bool _cityLoaded = false;

  late final List<Widget> _pages = [
    const FeedScreen(),
    const EventsScreen(),
    const CreateRequestScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Лента',
    'Ивенты',
    'Заявка',
    'Профиль',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserCity();
  }

  Future<void> _loadUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final city = normalizeCity((snap.data()?['city'] ?? '').toString());

      if (!mounted) return;
      setState(() {
        _selectedCity = city;
        _cityLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedCity = kAvailableCities.first;
        _cityLoaded = true;
      });
    }
  }

  Future<void> _changeCity(String city) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'city': city,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _selectedCity = city;
    });

    AppNotice.show(
      context,
      message: 'Город обновлён: $city',
      type: AppNoticeType.success,
    );
  }

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
          appBar: AppBar(
            title: Text(_titles[_index]),
            actions: [
              IconButton(
                tooltip: 'Настройки',
                onPressed: !_cityLoaded
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              isDarkMode: widget.settings.isDarkMode,
                              onThemeChanged: (value) {
                                widget.settings.setDarkMode(value);
                              },
                              selectedCity: _selectedCity,
                              onCityChanged: (city) async {
                                await _changeCity(city);
                              },
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.view_agenda_outlined),
                selectedIcon: Icon(Icons.view_agenda),
                label: 'Лента',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Ивенты',
              ),
              const NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
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
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.person),
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
  bool _loadingCity = true;
  String _selectedCity = kAvailableCities.first;

  @override
  void initState() {
    super.initState();
    _loadUserCity();
  }

  Future<void> _loadUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final city = normalizeCity((snap.data()?['city'] ?? '').toString());

    if (!mounted) return;
    setState(() {
      _selectedCity = city;
      _loadingCity = false;
    });
  }

  Future<void> _saveCity(String city) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'city': city,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _selectedCity = city;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;

    if (_loadingCity) {
      return const SafeArea(
        child: Center(child: LeafSpinner(size: 30)),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'open')
        .where('city', isEqualTo: _selectedCity)
        .orderBy('createdAt', descending: true);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Лента заявок',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              items: kAvailableCities
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ))
                  .toList(),
              onChanged: (v) async {
                final city = v ?? kAvailableCities.first;
                await _saveCity(city);
              },
              decoration: const InputDecoration(
                labelText: 'Выбранный город',
              ),
            ),
            const SizedBox(height: 8),
            Text('Показываются заявки по городу: $_selectedCity'),
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
                    return const Center(child: LeafSpinner(size: 28));
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

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Пока нет чужих открытых заявок в городе $_selectedCity.',
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

                      return RequestDocCard(
                        requestId: doc.id,
                        title: (data['title'] ?? '').toString(),
                        category: (data['category'] ?? '').toString(),
                        description: (data['description'] ?? '').toString(),
                        urgent: (data['urgent'] ?? false) == true,
                        authorId: (data['authorId'] ?? '').toString(),
                        expiresAt: data['expiresAt'] as Timestamp?,
                        city: (data['city'] ?? '').toString(),
                        distanceKm: null,
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
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours ч $minutes мин';
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
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Expanded(
                  child: UserMiniProfileButton(
                    userId: widget.authorId,
                  ),
                ),
                const SizedBox(width: 8),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  text: widget.category,
                ),
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  text: widget.city,
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
            Text(
              '⏳ ${_formatRemaining(widget.expiresAt)}',
              style: TextStyle(
                color: widget.urgent ? Colors.red : Colors.black54,
                fontWeight: widget.urgent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _opening ? null : _help,
                icon: _opening
                    ? const LeafSpinner(size: 18, color: Colors.white)
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
  String _selectedCity = kAvailableCities.first;

  @override
  void initState() {
    super.initState();
    _loadUserCity();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _loadUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final city = normalizeCity((snap.data()?['city'] ?? '').toString());

    if (!mounted) return;
    setState(() {
      _selectedCity = city;
    });
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final t = _title.text.trim();
    final d = _desc.text.trim();

    if (t.isEmpty || d.isEmpty) {
      AppNotice.show(
        context,
        message: 'Заполни название и описание',
        type: AppNoticeType.error,
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
        'city': _selectedCity,
        'urgent': autoUrgent,
        'durationHours': hours,
        'authorId': user.uid,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      }).timeout(const Duration(seconds: 10));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'createdRequestsCount': FieldValue.increment(1),
        'city': _selectedCity,
      }, SetOptions(merge: true));

      final achievementText =
          await AchievementService().checkAfterRequestCreated();

      _title.clear();
      _desc.clear();

      setState(() {
        _category = 'Еда';
        _hoursToLive = 24;
      });

      if (!mounted) return;

      final text = achievementText == null
          ? 'Заявка опубликована. Город: $_selectedCity'
          : 'Заявка опубликована. Город: $_selectedCity\n$achievementText';

      AppNotice.show(
        context,
        message: text,
        type: AppNoticeType.success,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Firestore: ${e.code} ${e.message ?? ""}',
        type: AppNoticeType.error,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка: $e',
        type: AppNoticeType.error,
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            items: kAvailableCities
                .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedCity = v ?? kAvailableCities.first);
            },
            decoration: const InputDecoration(
              labelText: 'Город',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Название',
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
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Описание',
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
                ? const LeafSpinner(size: 18, color: Colors.white)
                : const Text('Опубликовать'),
          ),
        ],
      ),
    );
  }
}


class ProfileImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadImage({
    required String uid,
    required String folder,
    int imageQuality = 85,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );

    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final ext = _fileExtension(file.name);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child(folder)
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: _contentTypeForExt(ext),
    );

    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  String _fileExtension(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last.toLowerCase();
  }

  String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}

/// =====================
/// PROFILE SCREEN (EDIT + MY ACTIVE REQUESTS + CLOSE + RATE)
/// =====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imageService = CloudinaryImageService();

  bool _avatarUploading = false;
  bool _bgUploading = false;

  Future<void> _editProfile(
    BuildContext context,
    Map<String, dynamic> current,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final nameCtrl = TextEditingController(
      text: (current['name'] ?? '').toString(),
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
      'bio': bioCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _pickAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _avatarUploading = true);

    try {
      final url = await _imageService.pickAndUploadImage(
        folder: 'volunteer_match/avatars',
        imageQuality: 80,
      );

      if (url == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Аватар обновлён',
        type: AppNoticeType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка загрузки аватара: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  Future<void> _pickProfileBackground() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _bgUploading = true);

    try {
      final url = await _imageService.pickAndUploadImage(
        folder: 'volunteer_match/backgrounds',
        imageQuality: 85,
      );

      if (url == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profileBackground': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Фон профиля обновлён',
        type: AppNoticeType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Ошибка загрузки фона: $e',
        type: AppNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _bgUploading = false);
      }
    }
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
            return const Center(child: LeafSpinner(size: 34));
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
                          Positioned(
                            top: 12,
                            right: 12,
                            child: FilledButton.icon(
                              onPressed:
                                  _bgUploading ? null : _pickProfileBackground,
                              icon: _bgUploading
                                  ? const LeafSpinner(
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : const Icon(Icons.image, size: 18),
                              label: Text(
                                _bgUploading ? 'Загрузка...' : 'Фон',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.58),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Stack(
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
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: _avatarUploading
                                            ? null
                                            : _pickAvatar,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF466E2D),
                                            shape: BoxShape.circle,
                                          ),
                                          child: _avatarUploading
                                              ? const Center(
                                                  child: LeafSpinner(
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.camera_alt,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                      onPressed: () async {
                        html.window.localStorage.remove('vm_login_time');
                        await FirebaseAuth.instance.signOut();
                      },
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

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

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

      final achievementText =
          await AchievementService().checkAfterFirstChatMessage();

      if (achievementText != null && mounted) {
        AppNotice.show(
          context,
          message: achievementText,
          type: AppNoticeType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppNotice.show(
        context,
        message: 'Не отправилось: $e',
        type: AppNoticeType.error,
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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, chatSnap) {
        final chatData = chatSnap.data?.data() ?? {};
        final members = List<String>.from(chatData['members'] ?? []);

        String? otherUserId;
        for (final id in members) {
          if (id != myId) {
            otherUserId = id;
            break;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: otherUserId == null
                ? Text(widget.title)
                : UserMiniProfileButton(
                    userId: otherUserId,
                    compact: true,
                  ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messagesQuery.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: LeafSpinner(size: 28));
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
                        final isSystem = senderId == 'system';

                        return Align(
                          alignment: isSystem
                              ? Alignment.center
                              : isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: isSystem
                                  ? Colors.black.withOpacity(0.06)
                                  : isMe
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
                        child: _sending
                            ? const LeafSpinner(size: 18, color: Colors.white)
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        ? 'Заявка завершена, оценка сохранена'
        : 'Заявка завершена, оценка сохранена\n${achievementMessages.join('\n')}';

    AppNotice.show(
      context,
      message: text,
      type: AppNoticeType.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppNotice.show(
      context,
      message: 'Ошибка завершения: $e',
      type: AppNoticeType.error,
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
