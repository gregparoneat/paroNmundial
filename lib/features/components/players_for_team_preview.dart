import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class PlayerForTeamPreview extends StatelessWidget {
  final String image;
  final String name;
  final Color color;

  const PlayerForTeamPreview(this.image, this.name, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRoutes.chooseCaptain);
      },
      child: Column(
        children: [
          FadedScaleAnimation(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: Colors.black,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.asset(image, scale: 2.6),
                  ),
                ),
                PositionedDirectional(
                  bottom: -10,
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(8)),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Text(
                          name,
                          style: theme.textTheme.bodyMedium!
                              .copyWith(fontSize: 12),
                        ),
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            '9.0',
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
