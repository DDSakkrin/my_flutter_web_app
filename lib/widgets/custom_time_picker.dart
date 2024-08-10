import 'package:flutter/material.dart';

class CustomTimePicker extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final String label;

  const CustomTimePicker({
    required this.selectedTime,
    required this.onTimeChanged,
    required this.label,
    Key? key,
  }) : super(key: key);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      onTimeChanged(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;
        double fontSize = isLargeScreen ? 18 : 14;
        double padding = isLargeScreen ? 16.0 : 8.0;
        double buttonHeight = isLargeScreen ? 48.0 : 36.0;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "$label: ${selectedTime?.format(context) ?? 'Not set'}",
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              SizedBox(width: padding),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: TextStyle(fontSize: fontSize),
                  minimumSize: Size(buttonHeight, buttonHeight),
                ),
                child: Text('Select Time'),
              ),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Time Picker Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Responsive Custom Time Picker'),
        ),
        body: Center(
          child: CustomTimePicker(
            selectedTime: TimeOfDay.now(),
            onTimeChanged: (time) {
              // Handle time changed
              print('Selected time: $time');
            },
            label: 'Selected Time',
          ),
        ),
      ),
    );
  }
}
