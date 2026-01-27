import 'package:animation_wrappers/animations/faded_scale_animation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:flutter/material.dart';

class MatchCard extends StatelessWidget {
  final MatchInfo matchInfo;
  final String matchTime;
  final String rightText;
  final VoidCallback? onTap;

  const MatchCard(this.matchInfo, this.matchTime, this.rightText, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    const double logoSize = 30.0; // Adjust this value as needed
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              matchInfo.team1Color,
              Colors.black,
              matchInfo.team2Color,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Text(
                    matchInfo.team1,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    matchInfo.leagueName,
                    style: theme.textTheme.bodyMedium!.copyWith(fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    matchInfo.team2,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                FadedScaleAnimation(
                  child: (matchInfo.team1Logo.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: matchInfo.team1Logo,
                    width: logoSize,  // Directly set the logical width
                    height: logoSize, // Directly set the logical height
                    fit: BoxFit.contain, // Keep aspect ratio, fit inside box
                    placeholder: (context, url) => SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor), // Loading indicator
                    ),
                    errorWidget: (context, url, error) => SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Icon(Icons.error_outline, color: theme.colorScheme.error), // Error icon
                    ),
                  )
                      : SizedBox(width: logoSize, height: logoSize), // Placeholder if no logo URL
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  matchInfo.team1Name,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  matchInfo.getTimeRemaining(),
                  style: theme.textTheme.bodySmall!
                      .copyWith(color: theme.primaryColor, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  matchInfo.team2Name,
                  style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
                ),
                const SizedBox(
                  width: 10,
                ),
                FadedScaleAnimation(
                  child: (matchInfo.team2Logo.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: matchInfo.team2Logo,
                    width: logoSize,  // Directly set the logical width
                    height: logoSize, // Directly set the logical height
                    fit: BoxFit.contain, // Keep aspect ratio, fit inside box
                    placeholder: (context, url) => SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor), // Loading indicator
                    ),
                    errorWidget: (context, url, error) => SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Icon(Icons.error_outline, color: theme.colorScheme.error), // Error icon
                    ),
                  )
                      : SizedBox(width: logoSize, height: logoSize), // Placeholder if no logo URL
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.92,
              padding:
                  const EdgeInsets.only(left: 10, top: 4, bottom: 4, right: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18)),
              ),
              height: 24,
              margin: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    matchInfo.leftText,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: iconColor,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    rightText,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.primaryColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.notifications,
                    size: 12,
                    color: iconColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
