import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditEventPage extends StatefulWidget {
  final User user;
  final Event event;

  const EditEventPage({required this.user, required this.event}); // Made const

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _location;
  late String _organizer;
  late String _relatedLink;
  late String _terms;
  late int _availableSeats;
  late String _contactInfo;
  late String _tags;
  File? _imageFile;
  Uint8List? _imageBytes;
  late DateTime _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  String? _imageUrl;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _isOtherSelected = false; // New state variable
  String? _otherTag; // New state variable

  final List<String> _tagOptions = [
    // Made final
    'การประชุม (Meetings)',
    'การสัมมนา/การฝึกอบรม (Seminars/Workshops)',
    'งานเลี้ยง/ปาร์ตี้ (Parties)',
    'กิจกรรมกีฬา (Sports)',
    'งานอาสาสมัคร (Volunteering)',
    'การพบปะทางสังคม (Social Gatherings)',
    'กิจกรรมครอบครัว (Family Activities)',
    'การแข่งขัน (Competitions)',
    'กิจกรรมทางวัฒนธรรม (Cultural Events)',
    'กิจกรรมการศึกษา (Educational Activities)',
    'กิจกรรมเพื่อสุขภาพ (Health & Wellness)',
    'การท่องเที่ยว (Travel/Tours)',
    'กิจกรรมทางศาสนา (Religious Events)',
    'การแสดง (Performances)',
    'อื่นๆ (Others)',
  ]; // ตัวอย่างแท็ก

  @override
  void initState() {
    super.initState();
    _title = widget.event.title;
    _description = widget.event.description;
    _location = widget.event.location;
    _selectedDate = widget.event.date;
    _imageUrl = widget.event.imageUrl;
    _selectedStartTime = TimeOfDay.fromDateTime(widget.event.startTime);
    _selectedEndTime = TimeOfDay.fromDateTime(widget.event.endTime);
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _organizer = widget.event.organizer;
    _relatedLink = widget.event.relatedLink;
    _terms = widget.event.terms;
    _availableSeats = widget.event.availableSeats;
    _contactInfo = widget.event.contactInfo;
    _tags = widget.event.tags;

    if (_tags == 'อื่นๆ (Others)') {
      _isOtherSelected = true;
      _otherTag = widget.event.tags;
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final pickedBytes = await ImagePickerWeb.getImageAsBytes();
        setState(() {
          _imageBytes = pickedBytes;
          _imageFile = null;
        });
      } else {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        setState(() {
          _imageFile = pickedFile != null ? File(pickedFile.path) : null;
          _imageBytes = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_selectedStartTime ?? TimeOfDay.now())
          : (_selectedEndTime ?? TimeOfDay.now()),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = pickedTime;
        } else {
          _selectedEndTime = pickedTime;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_imageFile != null || _imageBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images/${DateTime.now().toIso8601String()}.png');
        try {
          if (kIsWeb && _imageBytes != null) {
            await storageRef.putData(_imageBytes!);
          } else if (_imageFile != null) {
            await storageRef.putFile(_imageFile!);
          }
          _imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          _showSnackBar('Error uploading image: $e');
          return;
        }
      }

      final updatedEvent = Event(
        id: widget.event.id,
        title: _title,
        description: _description,
        location: _location,
        imageUrl: _imageUrl ?? '', // Handle null case here
        createdBy: widget.user.uid,
        date: _selectedDate,
        reminderTime: _selectedStartTime != null
            ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedStartTime!.hour,
                _selectedStartTime!.minute,
              )
            : null,
        startTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedStartTime?.hour ?? 0,
          _selectedStartTime?.minute ?? 0,
        ),
        endTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedEndTime?.hour ?? 0,
          _selectedEndTime?.minute ?? 0,
        ),
        participants:
            widget.event.participants, // Provide the existing participants
        organizer: _organizer,
        relatedLink: _relatedLink,
        terms: _terms,
        availableSeats: _availableSeats,
        contactInfo: _contactInfo,
        tags: _isOtherSelected ? _otherTag! : _tags,
      );

      try {
        await FirebaseService.updateEvent(updatedEvent);
        Navigator.pop(context, true); // Pass a true flag to indicate success
      } catch (e) {
        _showSnackBar('Error updating event: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')), // Made const
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard('Event Details', [
                _buildTextFormField('Title', _title,
                    (value) => _title = value ?? '', 'Please enter a title'),
                _buildTextFormField(
                    'Description',
                    _description,
                    (value) => _description = value ?? '',
                    'Please enter a description'),
                _buildTextFormField(
                    'Location',
                    _location,
                    (value) => _location = value ?? '',
                    'Please enter a location'),
                _buildTextFormField(
                    'Organizer',
                    _organizer,
                    (value) => _organizer = value ?? '',
                    'Please enter an organizer'),
                _buildNumericFormField(
                    'Available Seats',
                    _availableSeats.toString(),
                    (value) =>
                        _availableSeats = int.tryParse(value ?? '0') ?? 0,
                    'Please enter a valid number'),
              ]),
              _buildCard('Details Others', [
                _buildTextFormField('Terms', _terms,
                    (value) => _terms = value ?? '', 'Please enter terms'),
                _buildTextFormField(
                    'Contact Info',
                    _contactInfo,
                    (value) => _contactInfo = value ?? '',
                    'Please enter contact info'),
                _buildTextFormField(
                    'Related Link',
                    _relatedLink,
                    (value) => _relatedLink = value ?? '',
                    'Please enter related link'),
              ]),
              _buildCard('Event Schedule', [
                _buildDatePicker(context),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(context, 'Start Time', true),
                    ),
                    SizedBox(width: isMobile ? 10 : 20),
                    Expanded(
                      child: _buildTimePicker(context, 'End Time', false),
                    ),
                  ],
                ),
              ]),
              _buildCard('Tags', [
                _buildDropdownFormField(
                    'Tags', _tags, (value) => _tags = value ?? '', _tagOptions),
                if (_isOtherSelected)
                  _buildTextFormField(
                      'Other Tag',
                      _otherTag ?? '',
                      (value) => _otherTag = value,
                      'Please enter other tag'),
              ]),
              _buildCard('Image', [
                const Text(
                  // Made const
                  'Event Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10), // Made const
                _buildImagePreview(),
                TextButton.icon(
                  icon: const Icon(Icons.image), // Made const
                  label: const Text('Change Event Image'), // Made const
                  onPressed: _pickImage,
                ),
              ]),
              const SizedBox(height: 16), // Made const
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Changes'), // Made const
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0), // Made const
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Made const
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)), // Made const
            const SizedBox(height: 10), // Made const
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, String initialValue,
      FormFieldSetter<String> onSaved, String validatorText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Made const
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(), // Made const
        ),
        onSaved: onSaved,
        validator: (value) => value?.isEmpty ?? true ? validatorText : null,
      ),
    );
  }

  Widget _buildNumericFormField(String label, String initialValue,
      FormFieldSetter<String> onSaved, String validatorText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Made const
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(), // Made const
        ),
        onSaved: onSaved,
        validator: (value) =>
            value?.isEmpty ?? true || int.tryParse(value ?? '') == null
                ? validatorText
                : null,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
            style: const TextStyle(fontSize: 16), // Made const
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today), // Made const
          label: const Text('Select Date'), // Made const
          onPressed: () => _pickDate(context),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
      BuildContext context, String label, bool isStartTime) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label +
                ': ${isStartTime ? _selectedStartTime?.format(context) : _selectedEndTime?.format(context) ?? 'Not selected'}',
            style: const TextStyle(fontSize: 16), // Made const
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.access_time), // Made const
          label: const Text('Select'), // Made const
          onPressed: () => _pickTime(context, isStartTime),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return _imageBytes != null
        ? Image.memory(_imageBytes!)
        : _imageFile != null
            ? Image.file(_imageFile!)
            : _imageUrl != null
                ? Image.network(_imageUrl!)
                : Container();
  }

  Widget _buildDropdownFormField(String label, String initialValue,
      FormFieldSetter<String> onSaved, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Made const
      child: DropdownButtonFormField<String>(
        value: options.contains(initialValue) ? initialValue : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(), // Made const
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _tags = value ?? '';
            _isOtherSelected = value == 'อื่นๆ (Others)';
          });
        },
        onSaved: onSaved,
        validator: (value) => value == null ? 'Please select a tag' : null,
      ),
    );
  }
}
