import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController(text: 'Шымкент');
  final _locationController = TextEditingController();
  final _maxVolunteersController = TextEditingController(text: '20');

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isImportant = false;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выбери дату и время')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не найден');

      final eventDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'city': _cityController.text.trim(),
        'locationName': _locationController.text.trim(),
        'lat': null,
        'lng': null,
        'eventDate': Timestamp.fromDate(eventDate),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'maxVolunteers': int.tryParse(_maxVolunteersController.text.trim()) ?? 20,
        'joinedUserIds': [],
        'status': 'active',
        'imageUrl': '',
        'isImportant': _isImportant,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ивент создан')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _maxVolunteersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedText =
        (_selectedDate != null && _selectedTime != null)
            ? '${_selectedDate!.day.toString().padLeft(2, '0')}.'
              '${_selectedDate!.month.toString().padLeft(2, '0')}.'
              '${_selectedDate!.year} '
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
              '${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : 'Дата не выбрана';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Создать ивент'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Место',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите место';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxVolunteersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Максимум волонтёров',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isImportant,
                onChanged: (v) => setState(() => _isImportant = v),
                title: const Text('Важный ивент'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selectedText),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createEvent,
                  child: Text(_isLoading ? 'Создание...' : 'Создать ивент'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}