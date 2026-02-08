import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/features/match/models/match_info_ui.dart';
import 'package:flutter/material.dart';

class SingleTeamContainer extends StatelessWidget {
  final String? text;
  final TextStyle? match;
  final bool showScore;
  final MatchInfo? matchInfo;

  const SingleTeamContainer({
    super.key,
    this.text,
    this.match,
    this.showScore = false,
    this.matchInfo,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    const double logoSize = 40.0;

    // Use matchInfo data or fallback to defaults
    final team1FullName = matchInfo?.team1 ?? 'WOLVES UNITED';
    final team2FullName = matchInfo?.team2 ?? 'COBRA GUARDIANS';
    final team1ShortName = matchInfo?.team1Name ?? 'WLS';
    final team2ShortName = matchInfo?.team2Name ?? 'CBR';
    final team1Logo = matchInfo?.team1Logo ?? '';
    final team2Logo = matchInfo?.team2Logo ?? '';
    final team1Color = matchInfo?.team1Color ?? Colors.blue;
    final team2Color = matchInfo?.team2Color ?? Colors.deepPurple;

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(18), topLeft: Radius.circular(18)),
        gradient: LinearGradient(
          colors: [
            team1Color,
            Colors.black,
            team2Color,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    team1FullName.toUpperCase(),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team2FullName.toUpperCase(),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 10),
              FadedScaleAnimation(
                child: _buildTeamLogo(team1Logo, logoSize, theme),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Text(
                    team1ShortName,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  if (showScore)
                    Text(
                      '0',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                text ?? 'VS',
                style: match ??
                    theme.textTheme.bodySmall!
                        .copyWith(color: bgTextColor, fontSize: 10),
              ),
              const Spacer(),
              Column(
                children: [
                  Text(
                    team2ShortName,
                    style:
                        theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
                  ),
                  if (showScore)
                    Text(
                      '2',
                      style:
                          theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              FadedScaleAnimation(
                child: _buildTeamLogo(team2Logo, logoSize, theme),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String logoUrl, double size, ThemeData theme) {
    if (logoUrl.isNotEmpty && logoUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        ),
        errorWidget: (context, url, error) => SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.sports_soccer, color: iconColor, size: size * 0.8),
        ),
      );
    } else if (logoUrl.isNotEmpty) {
      // Local asset
      return Image.asset(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.sports_soccer,
          color: iconColor,
          size: size * 0.8,
        ),
      );
    } else {
      return Icon(Icons.sports_soccer, color: iconColor, size: size * 0.8);
    }
  }
}
