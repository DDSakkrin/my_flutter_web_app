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

class AddEventPage extends StatefulWidget {
  final User user;

  AddEventPage({required this.user});

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _location = '';
  File? _imageFile;
  Uint8List? _imageBytes;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

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
        _imageFile = File(pickedFile?.path ?? '');
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
      initialTime: TimeOfDay.now(),
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
      String? imageUrl;

      if (_imageFile != null || _imageBytes != null) {
        final storageRef = FirebaseStorage.instance.ref().child('event_images/${DateTime.now().toIso8601String()}.png');
        try {
          if (kIsWeb && _imageBytes != null) {
            await storageRef.putData(_imageBytes!);
          } else if (_imageFile != null) {
            await storageRef.putFile(_imageFile!);
          }
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('Error uploading image: $e');
        }
      }

      final newEvent = Event(
        id: FirebaseService.generateEventId(),
        title: _title,
        description: _description,
        location: _location,
        imageUrl: imageUrl,
        createdBy: widget.user.uid,
        date: _selectedDate,
        reminderTime: _selectedTime != null
            ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime!.hour, _selectedTime!.minute)
            : null,
        joinedUsers: [],
      );

      await FirebaseService.addEvent(newEvent);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Event')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (value) => _title = value ?? '',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value ?? '',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Location'),
                onSaved: (value) => _location = value ?? '',
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a location' : null,
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
                    ? Text('No image selected')
                    : Image.memory(_imageBytes!)
              else
                _imageFile == null
                    ? Text('No image selected')
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
