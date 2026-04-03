import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EntryField extends StatelessWidget {
  const EntryField({
    super.key,
    this.label,
    this.hint,
    this.maxLines,
    this.minLines,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.maxLength,
  });

  final String? label;
  final String? hint;
  final int? maxLines;
  final int? minLines;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.left,
            ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLines: maxLines,
            minLines: minLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).hintColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
