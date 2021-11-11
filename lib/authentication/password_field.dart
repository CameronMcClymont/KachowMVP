import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    this.fieldKey,
    this.hintText,
    this.labelText = 'Password',
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
    this.controller,
    Key? key
  }) : super(key: key);

  final Key? fieldKey;
  final String? hintText;
  final String labelText;
  final String? helperText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextEditingController? controller;

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: _obscureText,
      cursorColor: Theme.of(context).textSelectionTheme.cursorColor,
      onSaved: widget.onSaved,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: TextInputAction.go,
      decoration: InputDecoration(
        filled: true,
        hintText: widget.hintText,
        labelText: widget.labelText,
        helperText: widget.helperText,
        icon: const Icon(Icons.lock),
        suffixIcon: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            semanticLabel: _obscureText ? 'Show password' : 'Hide password',
          ),
        ),
      ),
    );
  }
}