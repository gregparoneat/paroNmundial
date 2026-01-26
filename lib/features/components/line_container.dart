import 'package:fantacy11/app_config/colors.dart';
import 'package:flutter/material.dart';

class LineContainer extends StatelessWidget {
  final double margin;
  final double? height;

  const LineContainer(this.margin, {super.key, this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: margin),
      height: height ?? 1,
      color: bgTextColor,
    );
  }
}
