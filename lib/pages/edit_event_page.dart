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
  late List<Map<String, String>> _joinedUsers; // Correct type for joinedUsers

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
      appBar: AppBar(
        title: Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (value) {
                  _title = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) {
                  _description = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _location,
                decoration: InputDecoration(labelText: 'Location'),
                onSaved: (value) {
                  _location = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
                  SizedBox(width: 20.0),
                  ElevatedButton(
                    onPressed: () => _pickDate(context),
                    child: Text('Select Date'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text("Time: ${_selectedTime?.format(context) ?? 'Not set'}"),
                  SizedBox(width: 20.0),
                  ElevatedButton(
                    onPressed: () => _pickTime(context),
                    child: Text('Select Time'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (kIsWeb)
                _imageBytes == null
                    ? (_imageUrl != null
                        ? Image.network(_imageUrl!)
                        : Text('No image selected'))
                    : Image.memory(_imageBytes!)
              else
                _imageFile == null
                    ? (_imageUrl != null
                        ? Image.network(_imageUrl!)
                        : Text('No image selected'))
                    : Image.file(_imageFile!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
