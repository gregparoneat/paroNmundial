class PredictorScore {
  final int home;
  final int away;

  const PredictorScore({required this.home, required this.away});

  Map<String, dynamic> toJson() => {'home': home, 'away': away};

  factory PredictorScore.fromJson(Map<String, dynamic> json) => PredictorScore(
    home: json['home'] as int? ?? 0,
    away: json['away'] as int? ?? 0,
  );
}

class PredictorTeam {
  final int id;
  final String name;
  final String shortName;
  final String? logoUrl;
  final String group;

  const PredictorTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoUrl,
    required this.group,
  });
}

class GroupStageFixture {
  final int id;
  final String group;
  final DateTime? kickoff;
  final PredictorTeam homeTeam;
  final PredictorTeam awayTeam;

  const GroupStageFixture({
    required this.id,
    required this.group,
    required this.kickoff,
    required this.homeTeam,
    required this.awayTeam,
  });
}

class GroupStandingRow {
  final PredictorTeam team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const GroupStandingRow({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  GroupStandingRow copyWith({
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? points,
  }) {
    return GroupStandingRow(
      team: team,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      points: points ?? this.points,
    );
  }
}

class KnockoutTeamSlot {
  final int? teamId;
  final String label;
  final String? teamName;
  final String? logoUrl;
  final String? seed;

  const KnockoutTeamSlot({
    required this.teamId,
    required this.label,
    this.teamName,
    this.logoUrl,
    this.seed,
  });

  bool get isResolved => teamId != null;
}

class KnockoutMatchView {
  final int id;
  final String round;
  final KnockoutTeamSlot home;
  final KnockoutTeamSlot away;
  final int? winnerTeamId;

  const KnockoutMatchView({
    required this.id,
    required this.round,
    required this.home,
    required this.away,
    this.winnerTeamId,
  });
}

class WorldCupPredictionState {
  final Map<int, PredictorScore> groupScores;
  final Map<int, int> knockoutWinners;

  const WorldCupPredictionState({
    this.groupScores = const {},
    this.knockoutWinners = const {},
  });

  Map<String, dynamic> toJson() => {
    'groupScores': groupScores.map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    ),
    'knockoutWinners': knockoutWinners.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
  };

  factory WorldCupPredictionState.fromJson(Map<String, dynamic> json) {
    final rawScores = json['groupScores'] as Map<String, dynamic>? ?? {};
    final rawWinners = json['knockoutWinners'] as Map<String, dynamic>? ?? {};
    return WorldCupPredictionState(
      groupScores: rawScores.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          PredictorScore.fromJson(value as Map<String, dynamic>),
        ),
      ),
      knockoutWinners: rawWinners.map(
        (key, value) => MapEntry(int.tryParse(key) ?? 0, value as int),
      ),
    );
  }
}

class KnockoutBuildResult {
  final List<KnockoutMatchView> roundOf32;
  final List<KnockoutMatchView> roundOf16;
  final List<KnockoutMatchView> quarterFinals;
  final List<KnockoutMatchView> semiFinals;
  final KnockoutMatchView bronzeFinal;
  final KnockoutMatchView finalMatch;
  final KnockoutTeamSlot? champion;

  const KnockoutBuildResult({
    required this.roundOf32,
    required this.roundOf16,
    required this.quarterFinals,
    required this.semiFinals,
    required this.bronzeFinal,
    required this.finalMatch,
    required this.champion,
  });
}

class WorldCupPredictorEngine {
  static const List<String> orderedGroups = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
  ];

  static Map<String, List<GroupStandingRow>> buildStandings({
    required Map<String, List<PredictorTeam>> groups,
    required List<GroupStageFixture> fixtures,
    required Map<int, PredictorScore> scores,
  }) {
    final standings = <String, List<GroupStandingRow>>{};

    for (final entry in groups.entries) {
      standings[entry.key] = entry.value
          .map(
            (team) => GroupStandingRow(
              team: team,
              played: 0,
              won: 0,
              drawn: 0,
              lost: 0,
              goalsFor: 0,
              goalsAgainst: 0,
              goalDifference: 0,
              points: 0,
            ),
          )
          .toList();
    }

    for (final fixture in fixtures) {
      final score = scores[fixture.id];
      if (score == null) continue;

      final rows = standings[fixture.group];
      if (rows == null) continue;

      final homeIndex = rows.indexWhere((row) => row.team.id == fixture.homeTeam.id);
      final awayIndex = rows.indexWhere((row) => row.team.id == fixture.awayTeam.id);
      if (homeIndex < 0 || awayIndex < 0) continue;

      final homeRow = rows[homeIndex];
      final awayRow = rows[awayIndex];

      final homeWon = score.home > score.away;
      final awayWon = score.away > score.home;
      final isDraw = score.home == score.away;

      rows[homeIndex] = homeRow.copyWith(
        played: homeRow.played + 1,
        won: homeRow.won + (homeWon ? 1 : 0),
        drawn: homeRow.drawn + (isDraw ? 1 : 0),
        lost: homeRow.lost + (awayWon ? 1 : 0),
        goalsFor: homeRow.goalsFor + score.home,
        goalsAgainst: homeRow.goalsAgainst + score.away,
        goalDifference: (homeRow.goalsFor + score.home) - (homeRow.goalsAgainst + score.away),
        points: homeRow.points + (homeWon ? 3 : (isDraw ? 1 : 0)),
      );

      rows[awayIndex] = awayRow.copyWith(
        played: awayRow.played + 1,
        won: awayRow.won + (awayWon ? 1 : 0),
        drawn: awayRow.drawn + (isDraw ? 1 : 0),
        lost: awayRow.lost + (homeWon ? 1 : 0),
        goalsFor: awayRow.goalsFor + score.away,
        goalsAgainst: awayRow.goalsAgainst + score.home,
        goalDifference: (awayRow.goalsFor + score.away) - (awayRow.goalsAgainst + score.home),
        points: awayRow.points + (awayWon ? 3 : (isDraw ? 1 : 0)),
      );
    }

    for (final rows in standings.values) {
      rows.sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;
        final goalDiffCompare = b.goalDifference.compareTo(a.goalDifference);
        if (goalDiffCompare != 0) return goalDiffCompare;
        final goalsForCompare = b.goalsFor.compareTo(a.goalsFor);
        if (goalsForCompare != 0) return goalsForCompare;
        return a.team.name.compareTo(b.team.name);
      });
    }

    return standings;
  }

  static KnockoutBuildResult buildKnockout({
    required Map<String, List<GroupStandingRow>> standings,
    required Map<int, int> winners,
    Map<String, Map<int, String>>? thirdPlaceMatrix,
  }) {
    final qualifiers = <String, GroupStandingRow>{};
    final thirdPlaceRows = <GroupStandingRow>[];

    for (final group in orderedGroups) {
      final rows = standings[group];
      if (rows == null || rows.length < 3) continue;
      qualifiers['${group}1'] = rows[0];
      qualifiers['${group}2'] = rows[1];
      thirdPlaceRows.add(rows[2]);
    }

    thirdPlaceRows.sort((a, b) {
      final pointsCompare = b.points.compareTo(a.points);
      if (pointsCompare != 0) return pointsCompare;
      final goalDiffCompare = b.goalDifference.compareTo(a.goalDifference);
      if (goalDiffCompare != 0) return goalDiffCompare;
      final goalsForCompare = b.goalsFor.compareTo(a.goalsFor);
      if (goalsForCompare != 0) return goalsForCompare;
      return a.team.group.compareTo(b.team.group);
    });

    final advancingThirds = thirdPlaceRows.take(8).toList();
    final thirdAssignments = _assignThirdPlaceTeams(
      advancingThirds,
      thirdPlaceMatrix: thirdPlaceMatrix,
    );

    final roundOf32 = _roundOf32Definitions.map((def) {
      final home = _resolveSeedSlot(
        def.id,
        def.homeSeed,
        qualifiers,
        thirdAssignments,
      );
      final away = _resolveSeedSlot(
        def.id,
        def.awaySeed,
        qualifiers,
        thirdAssignments,
      );
      final chosenWinner = winners[def.id];
      final winnerId =
          chosenWinner != null &&
              (chosenWinner == home.teamId || chosenWinner == away.teamId)
          ? chosenWinner
          : null;

      return KnockoutMatchView(
        id: def.id,
        round: 'Round of 32',
        home: home,
        away: away,
        winnerTeamId: winnerId,
      );
    }).toList();

    final roundOf32Map = {for (final match in roundOf32) match.id: match};
    final roundOf16 = _buildPlayoffRound(
      round: 'Round of 16',
      defs: _roundOf16Definitions,
      previousMatches: roundOf32Map,
      winners: winners,
    );
    final roundOf16Map = {for (final match in roundOf16) match.id: match};
    final quarterFinals = _buildPlayoffRound(
      round: 'Quarter-finals',
      defs: _quarterFinalDefinitions,
      previousMatches: roundOf16Map,
      winners: winners,
    );
    final quarterMap = {for (final match in quarterFinals) match.id: match};
    final semiFinals = _buildPlayoffRound(
      round: 'Semi-finals',
      defs: _semiFinalDefinitions,
      previousMatches: quarterMap,
      winners: winners,
    );
    final semiMap = {for (final match in semiFinals) match.id: match};
    final bronzeFinal = _buildPlayoffMatch(
      def: _bronzeDefinition,
      round: 'Bronze Final',
      previousMatches: semiMap,
      winners: winners,
      losers: true,
    );
    final finalMatch = _buildPlayoffMatch(
      def: _finalDefinition,
      round: 'Final',
      previousMatches: semiMap,
      winners: winners,
    );

    final champion = _resolveWinnerSlot(finalMatch);

    return KnockoutBuildResult(
      roundOf32: roundOf32,
      roundOf16: roundOf16,
      quarterFinals: quarterFinals,
      semiFinals: semiFinals,
      bronzeFinal: bronzeFinal,
      finalMatch: finalMatch,
      champion: champion,
    );
  }

  static KnockoutTeamSlot? _resolveWinnerSlot(KnockoutMatchView match) {
    if (match.winnerTeamId == null) return null;
    if (match.home.teamId == match.winnerTeamId) return match.home;
    if (match.away.teamId == match.winnerTeamId) return match.away;
    return null;
  }

  static List<KnockoutMatchView> _buildPlayoffRound({
    required String round,
    required List<_KnockoutDefinition> defs,
    required Map<int, KnockoutMatchView> previousMatches,
    required Map<int, int> winners,
  }) {
    return defs
        .map(
          (def) => _buildPlayoffMatch(
            def: def,
            round: round,
            previousMatches: previousMatches,
            winners: winners,
          ),
        )
        .toList();
  }

  static KnockoutMatchView _buildPlayoffMatch({
    required _KnockoutDefinition def,
    required String round,
    required Map<int, KnockoutMatchView> previousMatches,
    required Map<int, int> winners,
    bool losers = false,
  }) {
    final home = _resolvePreviousSlot(previousMatches[def.homeMatchId], losers: losers);
    final away = _resolvePreviousSlot(previousMatches[def.awayMatchId], losers: losers);
    final chosenWinner = winners[def.id];
    final winnerId =
        chosenWinner != null &&
            (chosenWinner == home.teamId || chosenWinner == away.teamId)
        ? chosenWinner
        : null;

    return KnockoutMatchView(
      id: def.id,
      round: round,
      home: home,
      away: away,
      winnerTeamId: winnerId,
    );
  }

  static KnockoutTeamSlot _resolvePreviousSlot(
    KnockoutMatchView? match, {
    bool losers = false,
  }) {
    if (match == null) {
      return KnockoutTeamSlot(teamId: null, label: losers ? 'Loser TBD' : 'Winner TBD');
    }

    if (!losers) {
      final winner = _resolveWinnerSlot(match);
      if (winner != null) {
        return winner;
      }
      return KnockoutTeamSlot(teamId: null, label: 'Winner M${match.id}');
    }

    if (match.winnerTeamId == null) {
      return KnockoutTeamSlot(teamId: null, label: 'Loser M${match.id}');
    }
    if (match.home.teamId != null && match.home.teamId != match.winnerTeamId) {
      return match.home;
    }
    if (match.away.teamId != null && match.away.teamId != match.winnerTeamId) {
      return match.away;
    }
    return KnockoutTeamSlot(teamId: null, label: 'Loser M${match.id}');
  }

  static KnockoutTeamSlot _resolveSeedSlot(
    int matchId,
    String? seed,
    Map<String, GroupStandingRow> qualifiers,
    Map<int, GroupStandingRow> thirdAssignments,
  ) {
    if (seed == null) {
      final assignment = thirdAssignments[matchId];
      if (assignment != null) {
        return KnockoutTeamSlot(
          teamId: assignment.team.id,
          label: '${assignment.team.group}3',
          teamName: assignment.team.name,
          logoUrl: assignment.team.logoUrl,
          seed: '${assignment.team.group}3',
        );
      }
      final eligible = _roundOf32Definitions
          .firstWhere((def) => def.id == matchId)
          .thirdEligibleGroups;
      final label = eligible == null || eligible.isEmpty
          ? 'Best 3rd'
          : 'Best 3rd (${eligible.join('/')})';
      return KnockoutTeamSlot(teamId: null, label: label);
    }

    final team = qualifiers[seed];
    if (team == null) {
      return KnockoutTeamSlot(teamId: null, label: seed);
    }
    return KnockoutTeamSlot(
      teamId: team.team.id,
      label: seed,
      teamName: team.team.name,
      logoUrl: team.team.logoUrl,
      seed: seed,
    );
  }

  static Map<int, GroupStandingRow> _assignThirdPlaceTeams(
    List<GroupStandingRow> thirdPlaceRows,
    {
    Map<String, Map<int, String>>? thirdPlaceMatrix,
    }
  ) {
    final matrixAssignments = _assignThirdPlaceTeamsFromMatrix(
      thirdPlaceRows,
      thirdPlaceMatrix,
    );
    if (matrixAssignments.isNotEmpty) {
      return matrixAssignments;
    }

    final matchesWithThird = _roundOf32Definitions
        .where((def) => def.thirdEligibleGroups != null)
        .toList();
    final result = <int, GroupStandingRow>{};

    bool assign(int index, List<GroupStandingRow> remaining) {
      if (index >= matchesWithThird.length) {
        return true;
      }

      final def = matchesWithThird[index];
      final eligible = def.thirdEligibleGroups!;
      for (final row in remaining) {
        if (!eligible.contains(row.team.group)) continue;
        result[def.id] = row;
        final nextRemaining = [...remaining]..remove(row);
        if (assign(index + 1, nextRemaining)) {
          return true;
        }
        result.remove(def.id);
      }
      return false;
    }

    assign(0, thirdPlaceRows);
    return result;
  }

  static Map<int, GroupStandingRow> _assignThirdPlaceTeamsFromMatrix(
    List<GroupStandingRow> thirdPlaceRows,
    Map<String, Map<int, String>>? thirdPlaceMatrix,
  ) {
    if (thirdPlaceMatrix == null || thirdPlaceMatrix.isEmpty) {
      return const {};
    }

    final combinationKey = (thirdPlaceRows.map((row) => row.team.group).toList()
          ..sort())
        .join();
    final slotMap = thirdPlaceMatrix[combinationKey];
    if (slotMap == null || slotMap.isEmpty) {
      return const {};
    }

    final rowsBySeed = {
      for (final row in thirdPlaceRows) '3${row.team.group}': row,
    };
    final assignments = <int, GroupStandingRow>{};
    for (final entry in slotMap.entries) {
      final row = rowsBySeed[entry.value];
      if (row != null) {
        assignments[entry.key] = row;
      }
    }
    return assignments;
  }

  static final List<_KnockoutDefinition> _roundOf32Definitions = [
    _KnockoutDefinition(id: 73, homeSeed: 'A2', awaySeed: 'B2'),
    _KnockoutDefinition(
      id: 74,
      homeSeed: 'E1',
      awaySeed: null,
      thirdEligibleGroups: ['A', 'B', 'C', 'D', 'F'],
    ),
    _KnockoutDefinition(id: 75, homeSeed: 'F1', awaySeed: 'C2'),
    _KnockoutDefinition(id: 76, homeSeed: 'C1', awaySeed: 'F2'),
    _KnockoutDefinition(
      id: 77,
      homeSeed: 'I1',
      awaySeed: null,
      thirdEligibleGroups: ['C', 'D', 'F', 'G', 'H'],
    ),
    _KnockoutDefinition(id: 78, homeSeed: 'E2', awaySeed: 'I2'),
    _KnockoutDefinition(
      id: 79,
      homeSeed: 'A1',
      awaySeed: null,
      thirdEligibleGroups: ['C', 'E', 'F', 'H', 'I'],
    ),
    _KnockoutDefinition(
      id: 80,
      homeSeed: 'L1',
      awaySeed: null,
      thirdEligibleGroups: ['E', 'H', 'I', 'J', 'K'],
    ),
    _KnockoutDefinition(
      id: 81,
      homeSeed: 'D1',
      awaySeed: null,
      thirdEligibleGroups: ['B', 'E', 'F', 'I', 'J'],
    ),
    _KnockoutDefinition(
      id: 82,
      homeSeed: 'G1',
      awaySeed: null,
      thirdEligibleGroups: ['A', 'E', 'H', 'I', 'J'],
    ),
    _KnockoutDefinition(id: 83, homeSeed: 'K2', awaySeed: 'L2'),
    _KnockoutDefinition(id: 84, homeSeed: 'H1', awaySeed: 'J2'),
    _KnockoutDefinition(
      id: 85,
      homeSeed: 'B1',
      awaySeed: null,
      thirdEligibleGroups: ['E', 'F', 'G', 'I', 'J'],
    ),
    _KnockoutDefinition(id: 86, homeSeed: 'J1', awaySeed: 'H2'),
    _KnockoutDefinition(
      id: 87,
      homeSeed: 'K1',
      awaySeed: null,
      thirdEligibleGroups: ['D', 'E', 'I', 'J', 'L'],
    ),
    _KnockoutDefinition(id: 88, homeSeed: 'D2', awaySeed: 'G2'),
  ];

  static final List<_KnockoutDefinition> _roundOf16Definitions = [
    _KnockoutDefinition(id: 89, homeMatchId: 73, awayMatchId: 74),
    _KnockoutDefinition(id: 90, homeMatchId: 75, awayMatchId: 76),
    _KnockoutDefinition(id: 91, homeMatchId: 77, awayMatchId: 78),
    _KnockoutDefinition(id: 92, homeMatchId: 79, awayMatchId: 80),
    _KnockoutDefinition(id: 93, homeMatchId: 81, awayMatchId: 82),
    _KnockoutDefinition(id: 94, homeMatchId: 83, awayMatchId: 84),
    _KnockoutDefinition(id: 95, homeMatchId: 85, awayMatchId: 86),
    _KnockoutDefinition(id: 96, homeMatchId: 87, awayMatchId: 88),
  ];

  static final List<_KnockoutDefinition> _quarterFinalDefinitions = [
    _KnockoutDefinition(id: 97, homeMatchId: 89, awayMatchId: 90),
    _KnockoutDefinition(id: 98, homeMatchId: 93, awayMatchId: 94),
    _KnockoutDefinition(id: 99, homeMatchId: 91, awayMatchId: 92),
    _KnockoutDefinition(id: 100, homeMatchId: 95, awayMatchId: 96),
  ];

  static final List<_KnockoutDefinition> _semiFinalDefinitions = [
    _KnockoutDefinition(id: 101, homeMatchId: 97, awayMatchId: 98),
    _KnockoutDefinition(id: 102, homeMatchId: 99, awayMatchId: 100),
  ];

  static final _KnockoutDefinition _bronzeDefinition = _KnockoutDefinition(
    id: 103,
    homeMatchId: 101,
    awayMatchId: 102,
  );

  static final _KnockoutDefinition _finalDefinition = _KnockoutDefinition(
    id: 104,
    homeMatchId: 101,
    awayMatchId: 102,
  );
}

class _KnockoutDefinition {
  final int id;
  final String? homeSeed;
  final String? awaySeed;
  final List<String>? thirdEligibleGroups;
  final int? homeMatchId;
  final int? awayMatchId;

  const _KnockoutDefinition({
    required this.id,
    this.homeSeed,
    this.awaySeed,
    this.thirdEligibleGroups,
    this.homeMatchId,
    this.awayMatchId,
  });
}
