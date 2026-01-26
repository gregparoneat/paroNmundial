import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.text,
    this.onTap,
    this.margin,
  });
  final String? text;
  final Function? onTap;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: TextButton(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.green,
          //onSurface: Colors.grey,
        ),
        onPressed: onTap as void Function()?,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text == null
                ? S.of(context).continueText.toUpperCase()
                : text!.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}
