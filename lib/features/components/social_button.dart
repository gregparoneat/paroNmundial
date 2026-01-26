import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String icon;
  final String text;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const SocialButton(
      {super.key,
      required this.icon,
      required this.text,
      this.iconColor,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: ImageIcon(AssetImage(icon), color: iconColor, size: 20),
      onPressed: onPressed ?? () {},
      style: ButtonStyle(
        overlayColor:
            WidgetStateColor.resolveWith((states) => Colors.transparent),
      ),
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
