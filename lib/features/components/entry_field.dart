import 'package:flutter/material.dart';

class EntryField extends StatelessWidget {
  const EntryField({
    super.key,
    this.label,
    this.hint,
    this.maxLines,
    this.minLines,
  });

  final String? label;
  final String? hint;
  final int? maxLines;
  final int? minLines;

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
