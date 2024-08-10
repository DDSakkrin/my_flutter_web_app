import 'package:flutter/material.dart';

class ImagePickerButton extends StatelessWidget {
  final VoidCallback onPickImage;

  const ImagePickerButton({required this.onPickImage, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;
        double paddingHorizontal = isLargeScreen ? 24.0 : 12.0;
        double paddingVertical = isLargeScreen ? 16.0 : 8.0;
        double fontSize = isLargeScreen ? 18.0 : 14.0;
        double buttonHeight = isLargeScreen ? 60.0 : 48.0;

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              width: isLargeScreen ? 200.0 : 150.0,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: onPickImage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: TextStyle(fontSize: fontSize),
                ),
                child: Text('Pick Image'),
              ),
            ),
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
      title: 'Responsive Button Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Responsive Image Picker Button'),
        ),
        body: Center(
          child: ImagePickerButton(
            onPickImage: () {
              // Define the action to be performed on button press
              print('Image picker button pressed');
            },
          ),
        ),
      ),
    );
  }
}
