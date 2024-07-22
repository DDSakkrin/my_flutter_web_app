import 'package:flutter/material.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const CustomDatePicker({
    required this.selectedDate,
    required this.onDateChanged,
    Key? key,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      onDateChanged(pickedDate);
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
                  "Date: ${selectedDate.toLocal().toIso8601String().split('T').first}",
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              SizedBox(width: padding),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: TextStyle(fontSize: fontSize),
                  minimumSize: Size(buttonHeight, buttonHeight),
                ),
                child: Text('Select Date'),
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
      title: 'Responsive Date Picker Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Responsive Custom Date Picker'),
        ),
        body: Center(
          child: CustomDatePicker(
            selectedDate: DateTime.now(),
            onDateChanged: (date) {
              // Handle date changed
              print('Selected date: $date');
            },
          ),
        ),
      ),
    );
  }
}
