import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'event_model.dart';
import 'user_role_service.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _imageService = CloudinaryImageService();

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
    final placeCtrl = TextEditingController();

    String imageUrl = '';
    bool imageUploading = false;

    DateTime startAt = DateTime.now().add(const Duration(days: 1));

    bool askFullName = true;
    bool askSchool = false;
    bool askUniversity = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          Future<void> pickEventImage() async {
            setLocal(() => imageUploading = true);
            try {
              final url = await _imageService.pickAndUploadImage(
                folder: 'volunteer_match/events',
                imageQuality: 85,
              );

              if (url != null) {
                setLocal(() => imageUrl = url);
              }
            } catch (e) {
              if (context.mounted) {
                AppNotice.show(
                  context,
                  message: 'Ошибка загрузки картинки: $e',
                  type: AppNoticeType.error,
                );
              }
            } finally {
              setLocal(() => imageUploading = false);
            }
          }

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
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Описание'),
                  ),
                  const SizedBox(height: 12),
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: imageUploading ? null : pickEventImage,
                      icon: imageUploading
                          ? const LeafSpinner(size: 18)
                          : const Icon(Icons.image_outlined),
                      label: Text(
                        imageUploading
                            ? 'Загрузка...'
                            : imageUrl.isEmpty
                                ? 'Загрузить картинку'
                                : 'Заменить картинку',
                      ),
                    ),
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
      'imageUrl': imageUrl,
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
        .snapshots();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadRole(),
      builder: (context, roleSnap) {
        final role = (roleSnap.data?['role'] ?? 'user').toString();
        final canCreate = role == 'admin' || role == 'moderator';
        final isAdmin = role == 'admin';

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
                    if (isAdmin)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminReportsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Жалобы'),
                      ),
                    if (canCreate) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openCreateEventDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Создать'),
                      ),
                    ],
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
                          child: Text('Пока что нет новых ивентов'),
                        );
                      }

                      final docs = snap.data!.docs.toList();

                      docs.sort((a, b) {
                        final aTs = a.data()['startAt'] as Timestamp?;
                        final bTs = b.data()['startAt'] as Timestamp?;
                        final aDate = aTs?.toDate() ?? DateTime(2100);
                        final bDate = bTs?.toDate() ?? DateTime(2100);
                        return aDate.compareTo(bDate);
                      });

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