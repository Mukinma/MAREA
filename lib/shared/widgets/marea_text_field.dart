import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MareaTextField extends StatelessWidget {
  const MareaTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.prefixText,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onFieldSubmitted,
    this.onChanged,
    this.helperText,
    this.inputFormatters,
    this.outlined = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final String? prefixText;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final useOutline = outlined || MareaFlatSurfaces.of(context);
    final field = TextFormField(
      enabled: enabled,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: useOutline,
        labelText: label,
        hintText: hint,
        helperText: helperText,
        floatingLabelBehavior: useOutline ? FloatingLabelBehavior.always : null,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
      ),
    );
    return useOutline
        ? field
        : MareaSurface(inset: true, radius: 16, child: field);
  }
}
