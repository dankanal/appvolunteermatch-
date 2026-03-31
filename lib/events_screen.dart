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
  bool _canManageEvents = false;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final canManage = await UserRoleService.isAdminOrModerator();

    if (!mounted) return;

    setState(() {
      _canManageEvents = canManage;
      _loadingRole = false;
    });
  }

  Future<void> _joinEvent(EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (event.joinedUserIds.contains(user.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ты уже участвуешь')),
      );
      return;
    }

    if (event.maxVolunteers > 0 &&
        event.joinedUserIds.length >= event.maxVolunteers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Свободных мест больше нет')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('events').doc(event.id).update({
      'joinedUserIds': FieldValue.arrayUnion([user.uid]),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Участие подтверждено')),
    );
  }

  Future<void> _leaveEvent(EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('events').doc(event.id).update({
      'joinedUserIds': FieldValue.arrayRemove([user.uid]),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Участие отменено')),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _eventInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ивенты'),
      ),
      floatingActionButton: _loadingRole
          ? null
          : (_canManageEvents
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEventScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('status', isEqualTo: 'active')
            .orderBy('eventDate')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Ошибка загрузки ивентов'),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final now = DateTime.now();

          final events = (snap.data?.docs ?? [])
              .map((doc) => EventModel.fromDoc(doc))
              .where((e) => e.eventDate.isAfter(now))
              .toList();

          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        size: 42,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Пока что нет новых ивентов',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Когда администраторы добавят новые мероприятия,\nони появятся здесь.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final event = events[i];
              final isJoined =
                  currentUid != null && event.joinedUserIds.contains(currentUid);

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (event.isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'ВАЖНО',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _eventInfoRow(Icons.location_city, 'Город: ${event.city}'),
                      const SizedBox(height: 8),
                      _eventInfoRow(Icons.place, 'Место: ${event.locationName}'),
                      const SizedBox(height: 8),
                      _eventInfoRow(Icons.schedule, 'Дата: ${_formatDate(event.eventDate)}'),
                      const SizedBox(height: 8),
                      _eventInfoRow(
                        Icons.groups,
                        'Участники: ${event.joinedUserIds.length}/${event.maxVolunteers}',
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isJoined
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFF22C55E),
                            foregroundColor:
                                isJoined ? const Color(0xFF111827) : Colors.white,
                          ),
                          onPressed: isJoined
                              ? () => _leaveEvent(event)
                              : () => _joinEvent(event),
                          child: Text(
                            isJoined ? 'Отменить участие' : 'Участвовать',
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
      ),
    );
  }
}