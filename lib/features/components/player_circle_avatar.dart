import 'package:flutter/material.dart';

class PlayerCircleAvatar extends StatelessWidget {
  final String name;
  final String nickname;
  final Color color;
  final String image;
  const PlayerCircleAvatar(this.name, this.nickname, this.color, this.image,
      {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Image.asset(
              image,
              scale: 2,
            )),
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.black,
          child: Text(
            nickname,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 10,
            ),
          ),
        ),
        PositionedDirectional(
          top: 66,
          start: 0,
          end: 0,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  name,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.bodyMedium!.copyWith(fontSize: 12),
                ),
              )),
        ),
      ],
    );
  }
}
