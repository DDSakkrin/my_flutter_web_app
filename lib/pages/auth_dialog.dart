import 'package:flutter/material.dart';

class AuthDialog extends StatefulWidget {
  final String title;
  final String action;

  AuthDialog({required this.title, required this.action});

  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isValid = true;

  void _validateAndSubmit() {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username == 'admin' && password == '1234') {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: !_isValid ? 'Invalid credentials' : null,
            ),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: !_isValid ? 'Invalid credentials' : null,
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: Text(widget.action),
          onPressed: _validateAndSubmit,
        ),
      ],
    );
  }
}
