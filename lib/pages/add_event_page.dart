import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';
import '../widgets/custom_date_picker.dart';
import '../widgets/custom_time_picker.dart';
import '../widgets/image_picker_button.dart';
import 'dart:io';
import 'dart:typed_data';

class AddEventPage extends StatefulWidget {
  final User user;

  const AddEventPage({required this.user, Key? key}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _organizerController = TextEditingController();
  final TextEditingController _relatedLinkController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _availableSeatsController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _otherTagController = TextEditingController();
  File? _imageFile;
  Uint8List? _imageBytes;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  final List<String> _tagOptions = [
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
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _relatedLinkController.dispose();
    _termsController.dispose();
    _availableSeatsController.dispose();
    _contactInfoController.dispose();
    _tagsController.dispose();
    _otherTagController.dispose();
    super.dispose();
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
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        setState(() {
          _imageFile = pickedFile != null ? File(pickedFile.path) : null;
          _imageBytes = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_selectedStartTime == null || _selectedEndTime == null) {
        _showSnackBar('Please select both start and end times');
        return;
      }

      try {
        String? imageUrl;

        // Upload image
        if (kIsWeb && _imageBytes != null) {
          imageUrl = await ImageService.uploadImageFromBytes(_imageBytes!);
        } else if (_imageFile != null) {
          imageUrl = await ImageService.uploadImageFromFile(_imageFile!);
        }

        if (imageUrl == null) {
          _showSnackBar('Image upload failed');
          return;
        }

        // Create event
        final startTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedStartTime!.hour,
          _selectedStartTime!.minute,
        );
        final endTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );

        final newEvent = Event(
          id: FirebaseService.generateEventId(),
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          organizer: _organizerController.text,
          relatedLink: _relatedLinkController.text,
          terms: _termsController.text,
          availableSeats: int.tryParse(_availableSeatsController.text) ?? 0,
          contactInfo: _contactInfoController.text,
          tags: _tagsController.text == 'อื่นๆ (Others)' ? _otherTagController.text : _tagsController.text,
          imageUrl: imageUrl,
          date: _selectedDate,
          startTime: startTime,
          endTime: endTime,
          createdBy: widget.user.uid,
          participants: [],
        );

        // Add event to Firestore
        await FirebaseService.addEvent(newEvent);
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Error adding event: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: Text('Add Event')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard('Event Details', [
                _buildTextFormField('Title', _titleController, 'Please enter a title'),
                _buildTextFormField('Description', _descriptionController, 'Please enter a description'),
                _buildTextFormField('Location', _locationController, 'Please enter a location'),
                _buildTextFormField('Organizer', _organizerController, 'Please enter an organizer'),
                _buildNumericFormField('Available Seats', _availableSeatsController, 'Please enter the number of available seats'),
              ]),
              _buildCard('Details Others', [
                _buildTextFormField('Terms', _termsController, 'Please enter Terms'),
                _buildTextFormField('Contact Info', _contactInfoController, 'Please enter Contact Info'),
                _buildTextFormField('Related Link', _relatedLinkController, 'Please enter Related Link'),
              ]),
              _buildCard('Event Schedule', [
                CustomDatePicker(
                  selectedDate: _selectedDate,
                  onDateChanged: (pickedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomTimePicker(
                        selectedTime: _selectedStartTime,
                        onTimeChanged: (pickedTime) {
                          setState(() {
                            _selectedStartTime = pickedTime;
                          });
                        },
                        label: "Start Time",
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 20),
                    Expanded(
                      child: CustomTimePicker(
                        selectedTime: _selectedEndTime,
                        onTimeChanged: (pickedTime) {
                          setState(() {
                            _selectedEndTime = pickedTime;
                          });
                        },
                        label: "End Time",
                      ),
                    ),
                  ],
                ),
              ]),
              _buildCard('Tags', [
                _buildDropdownFormField('Tags', _tagsController),
                if (_tagsController.text == 'อื่นๆ (Others)')
                  _buildTextFormField('Other Tag', _otherTagController, 'Please enter the tag'),
              ]),
              _buildCard('Image', [
                Text(
                  'Event Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: isMobile ? 5 : 10),
                if (kIsWeb)
                  _imageBytes == null
                      ? Text('No image selected')
                      : Image.memory(_imageBytes!)
                else
                  _imageFile == null
                      ? Text('No image selected')
                      : Image.file(_imageFile!),
                SizedBox(height: isMobile ? 10 : 20),
                ImagePickerButton(onPickImage: _pickImage),
              ]),
              Center(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, String validatorText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value?.isEmpty ?? true ? validatorText : null,
      ),
    );
  }

  Widget _buildNumericFormField(String label, TextEditingController controller, String validatorText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value?.isEmpty ?? true ? validatorText : null,
      ),
    );
  }

  Widget _buildDropdownFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: _tagOptions.map((String tag) {
          return DropdownMenuItem<String>(
            value: tag,
            child: Text(tag),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            controller.text = newValue ?? '';
          });
        },
        validator: (value) => value == null || value.isEmpty ? 'Please select a tag' : null,
      ),
    );
  }
}
