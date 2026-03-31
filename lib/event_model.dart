import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String city;
  final String locationName;
  final double? lat;
  final double? lng;
  final DateTime eventDate;
  final DateTime? createdAt;
  final String createdBy;
  final int maxVolunteers;
  final List<String> joinedUserIds;
  final String status;
  final String imageUrl;
  final bool isImportant;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.eventDate,
    required this.createdAt,
    required this.createdBy,
    required this.maxVolunteers,
    required this.joinedUserIds,
    required this.status,
    required this.imageUrl,
    required this.isImportant,
  });

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return EventModel(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      locationName: (data['locationName'] ?? '').toString(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: (data['createdBy'] ?? '').toString(),
      maxVolunteers: (data['maxVolunteers'] as num?)?.toInt() ?? 0,
      joinedUserIds: List<String>.from(data['joinedUserIds'] ?? const []),
      status: (data['status'] ?? 'active').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      isImportant: data['isImportant'] == true,
    );
  }
}