import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditEventPage extends StatefulWidget {
  final User user;
  final Event event;

  EditEventPage({required this.user, required this.event});

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _location;
  File? _imageFile;
  Uint8List? _imageBytes;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
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
    _selectedTime = widget.event.reminderTime != null
        ? TimeOfDay.fromDateTime(widget.event.reminderTime!)
        : null;
    _joinedUsers = List<Map<String, String>>.from(widget.event.joinedUsers); // Initialize joinedUsers with the correct type
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final pickedBytes = await ImagePickerWeb.getImageAsBytes();
      setState(() {
        _imageBytes = pickedBytes;
        _imageFile = null;
      });
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      setState(() {
        _imageFile = pickedFile != null ? File(pickedFile.path) : null;
        _imageBytes = null;
      });
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

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
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
          print('Error uploading image: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image')));
          return;
        }
      }

      final updatedEvent = Event(
        id: widget.event.id,
        title: _title,
        description: _description,
        location: _location,
        imageUrl: _imageUrl,
        createdBy: widget.user.uid,
        date: _selectedDate,
        reminderTime: _selectedTime != null
            ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              )
            : null,
        joinedUsers: _joinedUsers,
      );

      try {
        await FirebaseService.updateEvent(updatedEvent);
        Navigator.pop(context, true);
      } catch (e) {
        print('Error updating event: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating event')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
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
