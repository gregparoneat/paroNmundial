// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(name) => "Added ${name}";

  static String m1(position) => "Based on ${position} metrics";

  static String m2(points) => "Behind by ${points} pts - Edit your team!";

  static String m3(days) => "${days}d";

  static String m4(time) => "Draft: ${time}";

  static String m5(name) =>
      "Are you sure you want to drop ${name}? They will become available to other teams.";

  static String m6(name) => "Dropped ${name}";

  static String m7(error) => "Error joining league: ${error}";

  static String m8(error) => "Failed to create league: ${error}";

  static String m9(error) => "Failed to load leagues: ${error}";

  static String m10(error) => "Failed to load players: ${error}";

  static String m11(count) =>
      "Based on ${count} fixtures analyzed (some may have been skipped)";

  static String m12(name) => "From: ${name}";

  static String m13(hours, minutes) => "${hours}h ${minutes}m";

  static String m14(leagueName) => "Join ${leagueName} on Fantasy 11!";

  static String m15(time) =>
      "Joined successfully. Team creation opens on ${time}.";

  static String m16(count) => "Last ${count} matches";

  static String m17(count) => "Last ${count} matches";

  static String m18(name) => "League \"${name}\" created!";

  static String m19(current, max) => "${current}/${max} members";

  static String m20(minutes) => "${minutes}m";

  static String m21(count) => "${count} matches";

  static String m22(query) => "No players found for \"${query}\"";

  static String m23(owner) => "Owned by ${owner}";

  static String m24(count, total, budget) =>
      "${count}/${total} players • \\\$${budget}M left";

  static String m25(count, budget) => "${count} players • \\\$${budget}M left";

  static String m26(count, total) => "${count}/${total} players";

  static String m27(seconds) =>
      "Please wait ${seconds} seconds before resending";

  static String m28(points) => "${points} pts";

  static String m29(value) => "${value} next";

  static String m30(value) => "${value} season";

  static String m31(points) => "You are projected to win by ${points} pts!";

  static String m32(points, team) => "${points} next • ${team}";

  static String m33(current, max) => "Roster: ${current} / ${max}";

  static String m34(budget) =>
      "Select 18 players (11 starters + 7 subs) within \\\$${budget}M";

  static String m35(count) => "${count} spots available";

  static String m36(stageName) => "${stageName} Statistics";

  static String m37(hh, mm, ss) => "Starts in ${hh}:${mm}:${ss}";

  static String m38(days, hours, minutes) =>
      "Starts in ${days}d ${hours}h ${minutes}m";

  static String m39(dropPlayer, addPlayer) =>
      "Swapped ${dropPlayer} for ${addPlayer}";

  static String m40(name) => "To: ${name}";

  static String m41(date) => "Trade deadline: ${date}";

  static String m42(team, owner, points) =>
      "${team} • Owned by ${owner} • ${points} next";

  static String m43(side) => "Vote recorded: ${side}";

  static String m44(teamName) =>
      "Welcome to the league! Your team \"${teamName}\" is ready.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "LeJoined": MessageLookupByLibrary.simpleMessage(
      "Le joined 2 match = 20 points",
    ),
    "aboutUs": MessageLookupByLibrary.simpleMessage("About us"),
    "acceptAction": MessageLookupByLibrary.simpleMessage("Accept"),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "accountHolderName": MessageLookupByLibrary.simpleMessage(
      "Account holder name",
    ),
    "accountName": MessageLookupByLibrary.simpleMessage("Account Name"),
    "accountNumber": MessageLookupByLibrary.simpleMessage("Account Number"),
    "actual": MessageLookupByLibrary.simpleMessage("Actual"),
    "add": MessageLookupByLibrary.simpleMessage("ADD"),
    "addMoney": MessageLookupByLibrary.simpleMessage("Add Money"),
    "addPlayerAction": MessageLookupByLibrary.simpleMessage("Add"),
    "addPlayersFromAvailableTab": MessageLookupByLibrary.simpleMessage(
      "Add players from the Available tab",
    ),
    "addToRoster": MessageLookupByLibrary.simpleMessage("Add to Roster"),
    "addYourIssuefeedback": MessageLookupByLibrary.simpleMessage(
      "Add your issue/feedback",
    ),
    "addedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Added locally, but failed to persist roster update",
    ),
    "addedPlayer": m0,
    "addedToWallet": MessageLookupByLibrary.simpleMessage("Added to Wallet"),
    "age": MessageLookupByLibrary.simpleMessage("Age"),
    "allLabel": MessageLookupByLibrary.simpleMessage("All"),
    "allSeries": MessageLookupByLibrary.simpleMessage("All Series"),
    "allTeams": MessageLookupByLibrary.simpleMessage("All Teams"),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "anyoneCanJoin": MessageLookupByLibrary.simpleMessage("Anyone can join"),
    "appearances": MessageLookupByLibrary.simpleMessage("Appearances"),
    "apps": MessageLookupByLibrary.simpleMessage("Apps"),
    "assists": MessageLookupByLibrary.simpleMessage("Assists"),
    "attacker": MessageLookupByLibrary.simpleMessage("Attacker"),
    "availableBalance": MessageLookupByLibrary.simpleMessage(
      "Available Balance",
    ),
    "availableTab": MessageLookupByLibrary.simpleMessage("Available"),
    "average": MessageLookupByLibrary.simpleMessage("Average"),
    "averageRating": MessageLookupByLibrary.simpleMessage("Average Rating"),
    "avgRating": MessageLookupByLibrary.simpleMessage("Avg Rating"),
    "avoid": MessageLookupByLibrary.simpleMessage("Avoid"),
    "awaitingLeagueVote": MessageLookupByLibrary.simpleMessage(
      "Awaiting League Vote",
    ),
    "bankDetails": MessageLookupByLibrary.simpleMessage("Bank Details"),
    "bankIfscCode": MessageLookupByLibrary.simpleMessage("Bank IFSC code"),
    "basedOnMetrics": m1,
    "behindByEditTeam": m2,
    "birthdate": MessageLookupByLibrary.simpleMessage("Birthdate"),
    "blockedShots": MessageLookupByLibrary.simpleMessage("Blocked Shots"),
    "budgetBased": MessageLookupByLibrary.simpleMessage("Budget-based"),
    "budgetLabel": MessageLookupByLibrary.simpleMessage("Budget"),
    "buildFantasyTeamCompete": MessageLookupByLibrary.simpleMessage(
      "Build your fantasy team to compete in this league!",
    ),
    "buildTeam": MessageLookupByLibrary.simpleMessage("Build Team"),
    "cWillGet": MessageLookupByLibrary.simpleMessage(
      "C will get 2x points & VC will get 1.5x points",
    ),
    "cacheClearedRestart": MessageLookupByLibrary.simpleMessage(
      "Cache cleared! Restart app for fresh data.",
    ),
    "callUs": MessageLookupByLibrary.simpleMessage("Call us"),
    "canILogin": MessageLookupByLibrary.simpleMessage(
      "Can I login through Social account?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelTradeAction": MessageLookupByLibrary.simpleMessage("Cancel Trade"),
    "cancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "cannotAddPlayerFixtureStarted": MessageLookupByLibrary.simpleMessage(
      "Cannot add player - fixture has already started",
    ),
    "cannotSwapDropPlayerNotOnRoster": MessageLookupByLibrary.simpleMessage(
      "Cannot swap: drop player is not on your roster",
    ),
    "cap": MessageLookupByLibrary.simpleMessage("Cap"),
    "captain": MessageLookupByLibrary.simpleMessage("Captain"),
    "careerTotals": MessageLookupByLibrary.simpleMessage("Career Totals"),
    "changeFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Change Favorite Team",
    ),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Change Language"),
    "chooseCaptain": MessageLookupByLibrary.simpleMessage(
      "Choose Captain & Vice Captain",
    ),
    "chooseOnePlayerToOffer": MessageLookupByLibrary.simpleMessage(
      "Choose one of your players to offer:",
    ),
    "chooseTeamNamePrompt": MessageLookupByLibrary.simpleMessage(
      "Choose a name for your fantasy team:",
    ),
    "classic": MessageLookupByLibrary.simpleMessage("Classic"),
    "classicBudgetRecommendation": MessageLookupByLibrary.simpleMessage(
      "Recommended budget: 130-150M for a balanced 18-player squad.",
    ),
    "classicInfoBudgetTeam": MessageLookupByLibrary.simpleMessage(
      "Each member builds a team within the budget",
    ),
    "classicInfoCreateInvite": MessageLookupByLibrary.simpleMessage(
      "Create your league and invite friends",
    ),
    "classicInfoEarnPoints": MessageLookupByLibrary.simpleMessage(
      "Earn points based on real player performance",
    ),
    "classicInfoSamePlayersAllowed": MessageLookupByLibrary.simpleMessage(
      "Multiple managers can have the same players",
    ),
    "cleanSheets": MessageLookupByLibrary.simpleMessage("Clean Sheets"),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Clear All"),
    "clearCacheSubtitle": MessageLookupByLibrary.simpleMessage(
      "Clear all cached data (for testing)",
    ),
    "clearCacheTitle": MessageLookupByLibrary.simpleMessage("Clear Cache"),
    "clearHistoryMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear your recent players history?",
    ),
    "clearHistoryTitle": MessageLookupByLibrary.simpleMessage("Clear History"),
    "clearance": MessageLookupByLibrary.simpleMessage("Clearance"),
    "clearingCache": MessageLookupByLibrary.simpleMessage("Clearing cache..."),
    "closeMatchup": MessageLookupByLibrary.simpleMessage(
      "It is a close matchup!",
    ),
    "cm": MessageLookupByLibrary.simpleMessage("cm"),
    "completed": MessageLookupByLibrary.simpleMessage("COMPLETED"),
    "confidence": MessageLookupByLibrary.simpleMessage("Confidence"),
    "connectUsForIssues": MessageLookupByLibrary.simpleMessage(
      "Connect us for Issues",
    ),
    "contests": MessageLookupByLibrary.simpleMessage("CONTESTS"),
    "continueText": MessageLookupByLibrary.simpleMessage("Continue"),
    "copyCode": MessageLookupByLibrary.simpleMessage("Copy Code"),
    "countryCode": MessageLookupByLibrary.simpleMessage("Country Code"),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "createLeagueLabel": MessageLookupByLibrary.simpleMessage("Create League"),
    "createOrJoinFirstLeague": MessageLookupByLibrary.simpleMessage(
      "Create your first league or join an existing one",
    ),
    "createPublicLeagueOrWait": MessageLookupByLibrary.simpleMessage(
      "Create a public league or wait for others to create one",
    ),
    "createTeam": MessageLookupByLibrary.simpleMessage("Create Team"),
    "creatorUpper": MessageLookupByLibrary.simpleMessage("CREATOR"),
    "credit": MessageLookupByLibrary.simpleMessage("Credit"),
    "currentFormation": MessageLookupByLibrary.simpleMessage(
      "Current Formation",
    ),
    "currentTeam": MessageLookupByLibrary.simpleMessage("Current Team"),
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Date of Birth"),
    "daysShort": m3,
    "defender": MessageLookupByLibrary.simpleMessage("Defender"),
    "defenders": MessageLookupByLibrary.simpleMessage("DEFENDERS"),
    "describeYourLeague": MessageLookupByLibrary.simpleMessage(
      "Describe your league",
    ),
    "descriptionOptional": MessageLookupByLibrary.simpleMessage(
      "Description (Optional)",
    ),
    "draft": MessageLookupByLibrary.simpleMessage("Draft"),
    "draftAt": m4,
    "draftCompleted": MessageLookupByLibrary.simpleMessage("Draft completed"),
    "draftDateTime": MessageLookupByLibrary.simpleMessage("Draft Date & Time"),
    "draftGuideBullet1": MessageLookupByLibrary.simpleMessage(
      "Each manager takes turns selecting one player at a time. Once a player is drafted, nobody else can roster him.",
    ),
    "draftGuideBullet2": MessageLookupByLibrary.simpleMessage(
      "There is no transfer budget during the draft. Your advantage comes from pick timing, queue priority, and roster balance.",
    ),
    "draftGuideBullet3": MessageLookupByLibrary.simpleMessage(
      "Auto-pick can step in if your clock expires, so your queue matters even when you are not actively selecting.",
    ),
    "draftInfoCompeteChampionship": MessageLookupByLibrary.simpleMessage(
      "Compete for the championship!",
    ),
    "draftInfoScheduleDraft": MessageLookupByLibrary.simpleMessage(
      "Set up your league and schedule the draft",
    ),
    "draftInfoTakeTurns": MessageLookupByLibrary.simpleMessage(
      "On draft day, take turns picking players",
    ),
    "draftInfoTradesAndFreeAgency": MessageLookupByLibrary.simpleMessage(
      "Trade players and pick up free agents during the season",
    ),
    "draftInfoUniquePlayers": MessageLookupByLibrary.simpleMessage(
      "Each player can only be owned by one team",
    ),
    "draftIsLiveNow": MessageLookupByLibrary.simpleMessage("Draft is live now"),
    "draftLeagueGuideTitle": MessageLookupByLibrary.simpleMessage(
      "Draft League Guide",
    ),
    "draftLiveEnterRoomDescription": MessageLookupByLibrary.simpleMessage(
      "The draft is live. Enter the room to make your picks while other managers auto-pick when their timers expire.",
    ),
    "draftRoomOpens15MinBeforeStart": MessageLookupByLibrary.simpleMessage(
      "Draft Room Opens 15 Min Before Start",
    ),
    "draftRoomReady": MessageLookupByLibrary.simpleMessage("Draft Room Ready"),
    "draftSchedule": MessageLookupByLibrary.simpleMessage("Draft Schedule"),
    "draftSettings": MessageLookupByLibrary.simpleMessage("Draft Settings"),
    "draftSquadReadySetStarters": MessageLookupByLibrary.simpleMessage(
      "Your draft squad is ready. Set your starting XI, choose a formation, and assign captain roles before the matchup locks.",
    ),
    "draftTimeNotScheduledYet": MessageLookupByLibrary.simpleMessage(
      "Draft time has not been scheduled yet",
    ),
    "draftVsClassic": MessageLookupByLibrary.simpleMessage("Draft vs Classic"),
    "dropAction": MessageLookupByLibrary.simpleMessage("Drop"),
    "dropPlayerConfirmation": m5,
    "dropPlayerQuestion": MessageLookupByLibrary.simpleMessage("Drop Player?"),
    "dropPlayerTooltip": MessageLookupByLibrary.simpleMessage("Drop player"),
    "droppedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Dropped locally, but failed to persist roster update",
    ),
    "droppedPlayer": m6,
    "earnOneHundred": MessageLookupByLibrary.simpleMessage(
      "Earn 129 more points to reach level 90",
    ),
    "editTeam": MessageLookupByLibrary.simpleMessage("Edit Team"),
    "elitePick": MessageLookupByLibrary.simpleMessage("Elite Pick"),
    "emailAddress": MessageLookupByLibrary.simpleMessage("Email Address"),
    "enterAccountNumber": MessageLookupByLibrary.simpleMessage(
      "Enter account number",
    ),
    "enterAmount": MessageLookupByLibrary.simpleMessage("Enter amount"),
    "enterAtLeast3Chars": MessageLookupByLibrary.simpleMessage(
      "Enter at least 3 characters to search",
    ),
    "enterCode": MessageLookupByLibrary.simpleMessage("Enter Code"),
    "enterDraftRoom": MessageLookupByLibrary.simpleMessage("Enter Draft Room"),
    "enterEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Enter Email Address",
    ),
    "enterFullName": MessageLookupByLibrary.simpleMessage("Enter Full Name"),
    "enterLeagueName": MessageLookupByLibrary.simpleMessage(
      "Enter a name for your league",
    ),
    "enterPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Enter Phone Number",
    ),
    "enterSixDigit": MessageLookupByLibrary.simpleMessage("Enter 6 digit code"),
    "enterSixDigitVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Enter the 6-digit verification code",
    ),
    "enterValidInviteCode": MessageLookupByLibrary.simpleMessage(
      "Enter a valid invite code",
    ),
    "errorJoiningLeague": m7,
    "errorLabel": MessageLookupByLibrary.simpleMessage("Error"),
    "errorLoadingTeams": MessageLookupByLibrary.simpleMessage(
      "Error loading teams",
    ),
    "errorSearchingForLeague": MessageLookupByLibrary.simpleMessage(
      "Error searching for league",
    ),
    "events": MessageLookupByLibrary.simpleMessage("Events"),
    "everythingAboutYou": MessageLookupByLibrary.simpleMessage(
      "Everything about you",
    ),
    "excellent": MessageLookupByLibrary.simpleMessage("Excellent"),
    "facebook": MessageLookupByLibrary.simpleMessage("Facebook"),
    "failedToCompleteSwap": MessageLookupByLibrary.simpleMessage(
      "Failed to complete swap",
    ),
    "failedToCreateLeague": m8,
    "failedToJoinLeague": MessageLookupByLibrary.simpleMessage(
      "Failed to join league",
    ),
    "failedToLoadLeagues": m9,
    "failedToLoadPlayers": m10,
    "fantasyPointsPrediction": MessageLookupByLibrary.simpleMessage(
      "Fantasy Points Prediction",
    ),
    "faqs": MessageLookupByLibrary.simpleMessage("FAQs"),
    "favoriteTeam": MessageLookupByLibrary.simpleMessage("Favorite Team"),
    "favoriteTeamDescription": MessageLookupByLibrary.simpleMessage(
      "Choose your favorite national team. We\'ll personalize your experience and show players from your team first.",
    ),
    "findLeague": MessageLookupByLibrary.simpleMessage("Find League"),
    "findPlayerToTarget": MessageLookupByLibrary.simpleMessage(
      "Find a player to target",
    ),
    "fixtures": MessageLookupByLibrary.simpleMessage("Fixtures"),
    "fixturesAnalyzedNote": m11,
    "football": MessageLookupByLibrary.simpleMessage("Football"),
    "forward": MessageLookupByLibrary.simpleMessage("Forward"),
    "freeAgency": MessageLookupByLibrary.simpleMessage("Free Agency"),
    "freeLabel": MessageLookupByLibrary.simpleMessage("FREE"),
    "fromUser": m12,
    "full": MessageLookupByLibrary.simpleMessage("Full"),
    "fullDraftGuide": MessageLookupByLibrary.simpleMessage("Full Draft Guide"),
    "fullName": MessageLookupByLibrary.simpleMessage("Full Name"),
    "fullSeasonStatistics": MessageLookupByLibrary.simpleMessage(
      "Full Season Statistics",
    ),
    "games": MessageLookupByLibrary.simpleMessage("Games"),
    "getStarted": MessageLookupByLibrary.simpleMessage("Get Started"),
    "getYourAnswers": MessageLookupByLibrary.simpleMessage("Get your answers"),
    "getYourQuestionsAnswered": MessageLookupByLibrary.simpleMessage(
      "Get your questions answered",
    ),
    "goalkeeper": MessageLookupByLibrary.simpleMessage("Goalkeeper"),
    "goals": MessageLookupByLibrary.simpleMessage("Goals"),
    "good": MessageLookupByLibrary.simpleMessage("Good"),
    "goodPick": MessageLookupByLibrary.simpleMessage("Good Pick"),
    "google": MessageLookupByLibrary.simpleMessage("Google"),
    "guideDraftVsClassicItem1": MessageLookupByLibrary.simpleMessage(
      "Draft mode is exclusive: once you draft a player, nobody else in the league can own him.",
    ),
    "guideDraftVsClassicItem2": MessageLookupByLibrary.simpleMessage(
      "Classic mode is budget-based: multiple users can buy the same player as long as they can afford him.",
    ),
    "guideDraftVsClassicItem3": MessageLookupByLibrary.simpleMessage(
      "In draft mode, your decisions are about scarcity, timing, and roster construction. In classic mode, they are about value under budget.",
    ),
    "guideDraftVsClassicItem4": MessageLookupByLibrary.simpleMessage(
      "Season projection is most useful during drafting and buying, while next-match projection is more useful later when deciding starters and substitutions.",
    ),
    "guideDraftVsClassicTitle": MessageLookupByLibrary.simpleMessage(
      "Draft Vs Classic",
    ),
    "guideHowDraftWorksItem1": MessageLookupByLibrary.simpleMessage(
      "When the draft starts, managers pick one player at a time in the draft order shown by the room.",
    ),
    "guideHowDraftWorksItem2": MessageLookupByLibrary.simpleMessage(
      "If the league uses snake order, the order reverses every round so the manager picking last in one round picks first in the next.",
    ),
    "guideHowDraftWorksItem3": MessageLookupByLibrary.simpleMessage(
      "Every player can belong to only one manager. If someone drafts a player before you, that player is gone from the pool.",
    ),
    "guideHowDraftWorksItem4": MessageLookupByLibrary.simpleMessage(
      "You can queue players before your turn so the app can auto-pick from your priority list if your clock expires.",
    ),
    "guideHowDraftWorksTitle": MessageLookupByLibrary.simpleMessage(
      "How The Draft Works",
    ),
    "guidePracticalTipsItem1": MessageLookupByLibrary.simpleMessage(
      "Use the queue to rank fallback picks before your turn arrives.",
    ),
    "guidePracticalTipsItem2": MessageLookupByLibrary.simpleMessage(
      "Watch the turns-left indicator so you know when to stop browsing and start narrowing your shortlist.",
    ),
    "guidePracticalTipsItem3": MessageLookupByLibrary.simpleMessage(
      "Do not ignore position balance early enough that you become forced into weak picks late in the draft.",
    ),
    "guidePracticalTipsTitle": MessageLookupByLibrary.simpleMessage(
      "Practical Tips",
    ),
    "guideWhatYouAreBuildingItem1": MessageLookupByLibrary.simpleMessage(
      "Your draft roster has 18 players total.",
    ),
    "guideWhatYouAreBuildingItem2": MessageLookupByLibrary.simpleMessage(
      "You must still be able to finish with at least 1 goalkeeper, 3 defenders, 3 midfielders, and 1 forward.",
    ),
    "guideWhatYouAreBuildingItem3": MessageLookupByLibrary.simpleMessage(
      "Beyond those minimums, the remaining spots are flexible, so strategy matters.",
    ),
    "guideWhatYouAreBuildingTitle": MessageLookupByLibrary.simpleMessage(
      "What You Are Building",
    ),
    "headToHead": MessageLookupByLibrary.simpleMessage("Head to Head"),
    "height": MessageLookupByLibrary.simpleMessage("Height"),
    "high": MessageLookupByLibrary.simpleMessage("High"),
    "historyTab": MessageLookupByLibrary.simpleMessage("History"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "hoursMinutesShort": m13,
    "howClassicModeWorks": MessageLookupByLibrary.simpleMessage(
      "How Classic Mode Works",
    ),
    "howDraftLeaguesWork": MessageLookupByLibrary.simpleMessage(
      "How Draft Leagues Work",
    ),
    "howDraftModeWorks": MessageLookupByLibrary.simpleMessage(
      "How Draft Mode Works",
    ),
    "howItWorks": MessageLookupByLibrary.simpleMessage("How it works?"),
    "howToAddMoney": MessageLookupByLibrary.simpleMessage("How to add money?"),
    "howToChangeLanguage": MessageLookupByLibrary.simpleMessage(
      "How to change language?",
    ),
    "howToChangeProfile": MessageLookupByLibrary.simpleMessage(
      "How to change profile picture?",
    ),
    "howToLogoutMyAccount": MessageLookupByLibrary.simpleMessage(
      "How to Logout my account?",
    ),
    "howToPlay": MessageLookupByLibrary.simpleMessage("How to Play?"),
    "howToSelectMoney": MessageLookupByLibrary.simpleMessage(
      "How to select player?",
    ),
    "howToSend": MessageLookupByLibrary.simpleMessage(
      "How to send money to bank?",
    ),
    "howToShop": MessageLookupByLibrary.simpleMessage("How to Shop?"),
    "howWeStarted": MessageLookupByLibrary.simpleMessage("How we started?"),
    "howWeWork": MessageLookupByLibrary.simpleMessage("How we work"),
    "ifYou": MessageLookupByLibrary.simpleMessage(
      "If you joined and won the contest you\'ll get 1.5x of points.",
    ),
    "iff": MessageLookupByLibrary.simpleMessage(
      "If you joined and won the contest you\'ll get 1.0x of points.",
    ),
    "ifscCode": MessageLookupByLibrary.simpleMessage("IFSC Code"),
    "inLessThanAMinute": MessageLookupByLibrary.simpleMessage(
      "in less than a minute",
    ),
    "inPlayingEleven": MessageLookupByLibrary.simpleMessage("In playing 11"),
    "inboxTab": MessageLookupByLibrary.simpleMessage("Inbox"),
    "includesAperturaClausura": MessageLookupByLibrary.simpleMessage(
      "Includes Apertura + Clausura tournaments",
    ),
    "incomingTrades": MessageLookupByLibrary.simpleMessage("Incoming Trades"),
    "interceptionsWon": MessageLookupByLibrary.simpleMessage(
      "Interceptions Won",
    ),
    "inviteCode": MessageLookupByLibrary.simpleMessage("Invite Code"),
    "inviteCodeCopied": MessageLookupByLibrary.simpleMessage(
      "Invite code copied!",
    ),
    "inviteOnly": MessageLookupByLibrary.simpleMessage("Invite only"),
    "jerseyNumber": MessageLookupByLibrary.simpleMessage("Jersey Number"),
    "join": MessageLookupByLibrary.simpleMessage("Join"),
    "joinArrow": MessageLookupByLibrary.simpleMessage("Join →"),
    "joinDraftNow": MessageLookupByLibrary.simpleMessage("Join Draft Now"),
    "joinLeague": MessageLookupByLibrary.simpleMessage("Join League"),
    "joinLeagueOnFantasy11": m14,
    "joinPrivateLeague": MessageLookupByLibrary.simpleMessage(
      "Join Private League",
    ),
    "joinPrivateLeagueDescription": MessageLookupByLibrary.simpleMessage(
      "Enter the invite code shared by your friend to join their private league.",
    ),
    "joinWithCode": MessageLookupByLibrary.simpleMessage("Join with code"),
    "joinedAContest": MessageLookupByLibrary.simpleMessage("Joined a Contest"),
    "joinedSuccessfullyTeamCreationOnDraftDay":
        MessageLookupByLibrary.simpleMessage(
          "Joined successfully. Team creation opens on draft day.",
        ),
    "joinedSuccessfullyTeamCreationOpensOn": m15,
    "joinedWithTwoTeams": MessageLookupByLibrary.simpleMessage(
      "JOINED WITH 2 TEAMS",
    ),
    "keyFactors": MessageLookupByLibrary.simpleMessage("Key Factors"),
    "kg": MessageLookupByLibrary.simpleMessage("kg"),
    "knowOurPrivacyPolicies": MessageLookupByLibrary.simpleMessage(
      "Know our Privacy Policies",
    ),
    "knowWhereYouStand": MessageLookupByLibrary.simpleMessage(
      "Know where you stands in competition",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "last5Form": MessageLookupByLibrary.simpleMessage("Last 5 Form"),
    "lastMatchesPlus": m16,
    "lastNMatches": m17,
    "leaderboard": MessageLookupByLibrary.simpleMessage("Leaderboard"),
    "leagueCreated": m18,
    "leagueDetails": MessageLookupByLibrary.simpleMessage("League Details"),
    "leagueFound": MessageLookupByLibrary.simpleMessage("League Found!"),
    "leagueFull": MessageLookupByLibrary.simpleMessage("League Full"),
    "leagueMode": MessageLookupByLibrary.simpleMessage("League Mode"),
    "leagueName": MessageLookupByLibrary.simpleMessage("League Name"),
    "leagueNoLongerAcceptingMembers": MessageLookupByLibrary.simpleMessage(
      "This league is no longer accepting members",
    ),
    "leagueNotFoundCheckInviteCode": MessageLookupByLibrary.simpleMessage(
      "League not found. Check the invite code.",
    ),
    "leagueVisibility": MessageLookupByLibrary.simpleMessage(
      "League Visibility",
    ),
    "leagueVoteTitle": MessageLookupByLibrary.simpleMessage("League Vote"),
    "leaguesTitle": MessageLookupByLibrary.simpleMessage(
      "paroNfantasyMx Leagues",
    ),
    "leaveLabel": MessageLookupByLibrary.simpleMessage("Leave"),
    "leaveLeagueConfirmation": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to leave this league? Your team will be deleted.",
    ),
    "leaveLeagueQuestion": MessageLookupByLibrary.simpleMessage(
      "Leave League?",
    ),
    "leftLeagueMessage": MessageLookupByLibrary.simpleMessage(
      "You have left the league",
    ),
    "letsPlay": MessageLookupByLibrary.simpleMessage("Let\'s Play"),
    "level": MessageLookupByLibrary.simpleMessage("Level"),
    "linear": MessageLookupByLibrary.simpleMessage("Linear"),
    "live": MessageLookupByLibrary.simpleMessage("LIVE"),
    "loadingNextMatch": MessageLookupByLibrary.simpleMessage(
      "Loading next match...",
    ),
    "loadingRecentStats": MessageLookupByLibrary.simpleMessage(
      "Loading recent form...",
    ),
    "loadingTournamentStats": MessageLookupByLibrary.simpleMessage(
      "Loading tournament stats...",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "low": MessageLookupByLibrary.simpleMessage("Low"),
    "mailUs": MessageLookupByLibrary.simpleMessage("Mail us"),
    "matchCompleted": MessageLookupByLibrary.simpleMessage("Match Completed"),
    "matchLive": MessageLookupByLibrary.simpleMessage("Match Live"),
    "matchTbd": MessageLookupByLibrary.simpleMessage("Match TBD"),
    "matches": MessageLookupByLibrary.simpleMessage("matches"),
    "matchup": MessageLookupByLibrary.simpleMessage("matchup"),
    "matchvs": MessageLookupByLibrary.simpleMessage("Match - ALS vs CBR"),
    "maxContest": MessageLookupByLibrary.simpleMessage("Max Contest"),
    "maxMembers": MessageLookupByLibrary.simpleMessage("Max Members"),
    "maxSevenPlayers": MessageLookupByLibrary.simpleMessage(
      "Max 7 player from a team",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "members": MessageLookupByLibrary.simpleMessage("Members"),
    "membersCount": m19,
    "messageOptional": MessageLookupByLibrary.simpleMessage(
      "Message (optional)",
    ),
    "midfielder": MessageLookupByLibrary.simpleMessage("Midfielder"),
    "millionUsd": MessageLookupByLibrary.simpleMessage("Million USD"),
    "minutes": MessageLookupByLibrary.simpleMessage("Minutes"),
    "minutesShort": m20,
    "multipleEntries": MessageLookupByLibrary.simpleMessage("Multiple Entries"),
    "myContestsTwo": MessageLookupByLibrary.simpleMessage("MY CONTESTS (2)"),
    "myLeagues": MessageLookupByLibrary.simpleMessage("My Leagues"),
    "myMatches": MessageLookupByLibrary.simpleMessage("My Matches"),
    "myProfile": MessageLookupByLibrary.simpleMessage("My Profile"),
    "myRosterTab": MessageLookupByLibrary.simpleMessage("My Roster"),
    "myTeamLabel": MessageLookupByLibrary.simpleMessage("My Team"),
    "myTeamThree": MessageLookupByLibrary.simpleMessage("MY TEAM (3)"),
    "nMatches": m21,
    "nameMustBeAtLeast3Characters": MessageLookupByLibrary.simpleMessage(
      "Name must be at least 3 characters",
    ),
    "nameYourTeam": MessageLookupByLibrary.simpleMessage("Name Your Team"),
    "nationality": MessageLookupByLibrary.simpleMessage("Nationality"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Next Match"),
    "nextMatchupTitle": MessageLookupByLibrary.simpleMessage("Next Matchup"),
    "nextOpponent": MessageLookupByLibrary.simpleMessage("Next Opponent"),
    "noDeadline": MessageLookupByLibrary.simpleMessage("No deadline"),
    "noLeaguesYet": MessageLookupByLibrary.simpleMessage("No Leagues Yet"),
    "noMembersYet": MessageLookupByLibrary.simpleMessage("No members yet"),
    "noOtherSportsAvailableContactAdmin": MessageLookupByLibrary.simpleMessage(
      "No other sports available, contact admin",
    ),
    "noPendingTrades": MessageLookupByLibrary.simpleMessage(
      "No pending trades",
    ),
    "noPlayersFound": MessageLookupByLibrary.simpleMessage("No players found"),
    "noPlayersFoundFor": m22,
    "noPlayersOnRoster": MessageLookupByLibrary.simpleMessage(
      "No players on roster",
    ),
    "noPublicLeaguesAvailable": MessageLookupByLibrary.simpleMessage(
      "No Public Leagues Available",
    ),
    "noRecentStatsMessage": MessageLookupByLibrary.simpleMessage(
      "This player doesn\'t have recent stats in the Mexican league within the last 6 weeks.",
    ),
    "noRecentStatsTitle": MessageLookupByLibrary.simpleMessage(
      "No Recent Stats",
    ),
    "noStandingsYet": MessageLookupByLibrary.simpleMessage("No standings yet"),
    "noTeamYet": MessageLookupByLibrary.simpleMessage("No Team Yet"),
    "noTeamsFound": MessageLookupByLibrary.simpleMessage("No teams found"),
    "noTradeHistory": MessageLookupByLibrary.simpleMessage("No trade history"),
    "noTradeTargetsFound": MessageLookupByLibrary.simpleMessage(
      "No trade targets found",
    ),
    "noTransactionsYet": MessageLookupByLibrary.simpleMessage(
      "No transactions yet",
    ),
    "now": MessageLookupByLibrary.simpleMessage("Now"),
    "orContinueWith": MessageLookupByLibrary.simpleMessage("Or Continue with"),
    "outgoingTrades": MessageLookupByLibrary.simpleMessage("Outgoing Trades"),
    "overview": MessageLookupByLibrary.simpleMessage("Overview"),
    "ownedBy": m23,
    "passesCompleted": MessageLookupByLibrary.simpleMessage("Passes Completed"),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("Payment Method"),
    "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone Number"),
    "pickStartersAndFormation": MessageLookupByLibrary.simpleMessage(
      "Pick Your Starters And Formation",
    ),
    "pickTimer": MessageLookupByLibrary.simpleMessage("Pick Timer"),
    "playerAlreadyOnRoster": MessageLookupByLibrary.simpleMessage(
      "Player is already on your roster",
    ),
    "playerDetails": MessageLookupByLibrary.simpleMessage("Player Details"),
    "playerInfo": MessageLookupByLibrary.simpleMessage("Player Info"),
    "playerLimitedPlaytime": MessageLookupByLibrary.simpleMessage(
      "Limited playtime recently - may be injured or benched",
    ),
    "playerNotFound": MessageLookupByLibrary.simpleMessage("Player not found"),
    "playerNotOnSavedRoster": MessageLookupByLibrary.simpleMessage(
      "Player is not on your saved roster",
    ),
    "players": MessageLookupByLibrary.simpleMessage("Players"),
    "playersAndBudgetLeft": m24,
    "playersAndMoneyLeft": m25,
    "playersCountOfTotal": m26,
    "pleaseCompleteNameAndPhone": MessageLookupByLibrary.simpleMessage(
      "Please complete at least name and phone number",
    ),
    "pleaseEnterLeagueName": MessageLookupByLibrary.simpleMessage(
      "Please enter a league name",
    ),
    "pleaseEnterPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Please enter your phone number",
    ),
    "pleaseSetDraftDateAndTime": MessageLookupByLibrary.simpleMessage(
      "Please set a draft date and time",
    ),
    "pleaseWaitBeforeResending": m27,
    "plusMatchup": MessageLookupByLibrary.simpleMessage("+ matchup"),
    "point": MessageLookupByLibrary.simpleMessage("Point"),
    "points": MessageLookupByLibrary.simpleMessage("Points"),
    "pointsAbbrev": m28,
    "pointsNext": m29,
    "pointsSeason": m30,
    "poor": MessageLookupByLibrary.simpleMessage("Poor"),
    "position": MessageLookupByLibrary.simpleMessage("Position"),
    "preferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Preferred Language",
    ),
    "previousTeams": MessageLookupByLibrary.simpleMessage("Previous Teams"),
    "priceLabel": MessageLookupByLibrary.simpleMessage("Price"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privateLeague": MessageLookupByLibrary.simpleMessage("Private"),
    "prizePool": MessageLookupByLibrary.simpleMessage("PRIZE POOL"),
    "projectedPoints": MessageLookupByLibrary.simpleMessage("Projected Points"),
    "projectedWinBy": m31,
    "projectionLabel": MessageLookupByLibrary.simpleMessage("projection"),
    "proposeTab": MessageLookupByLibrary.simpleMessage("Propose"),
    "proposeTradeAction": MessageLookupByLibrary.simpleMessage("Propose Trade"),
    "proposeTradeToGetStarted": MessageLookupByLibrary.simpleMessage(
      "Propose a trade to get started",
    ),
    "ptsShort": MessageLookupByLibrary.simpleMessage("pts"),
    "publicLeague": MessageLookupByLibrary.simpleMessage("Public"),
    "publicLeagues": MessageLookupByLibrary.simpleMessage("Public Leagues"),
    "quickDraftGuideSubtitle": MessageLookupByLibrary.simpleMessage(
      "Quick guide for users coming from classic budget fantasy.",
    ),
    "range11to25": MessageLookupByLibrary.simpleMessage("11-25"),
    "range2to20": MessageLookupByLibrary.simpleMessage("2-20"),
    "range50to1000": MessageLookupByLibrary.simpleMessage("50-1000"),
    "rank": MessageLookupByLibrary.simpleMessage("Rank"),
    "rating": MessageLookupByLibrary.simpleMessage("Rating"),
    "recentForm": MessageLookupByLibrary.simpleMessage("Recent Form"),
    "recentMatchStatus": MessageLookupByLibrary.simpleMessage(
      "Recent match status",
    ),
    "recentPlayersTitle": MessageLookupByLibrary.simpleMessage(
      "Recent Players",
    ),
    "recentSearches": MessageLookupByLibrary.simpleMessage("Recent Searches"),
    "red": MessageLookupByLibrary.simpleMessage("Red"),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "rejectAction": MessageLookupByLibrary.simpleMessage("Reject"),
    "requestedPlayerSummary": m32,
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "riskyPick": MessageLookupByLibrary.simpleMessage("Risky Pick"),
    "role": MessageLookupByLibrary.simpleMessage("Role"),
    "rosterCount": m33,
    "rosterFullDropPlayerToAdd": MessageLookupByLibrary.simpleMessage(
      "Roster Full - Drop a player to add",
    ),
    "rosterIsFullSwapOrDropFirst": MessageLookupByLibrary.simpleMessage(
      "Roster is full. Swap or drop a player first.",
    ),
    "rosterSize": MessageLookupByLibrary.simpleMessage("Roster Size"),
    "ruleCaptainViceCaptainPoints": MessageLookupByLibrary.simpleMessage(
      "Captain gets 2x points, Vice-captain gets 1.5x",
    ),
    "ruleMax4PlayersOneTeam": MessageLookupByLibrary.simpleMessage(
      "Max 4 players from one team",
    ),
    "ruleSelect18PlayersBudget": m34,
    "ruleSelect18PlayersDraft": MessageLookupByLibrary.simpleMessage(
      "Select 18 players (11 starters + 7 subs) through the live draft",
    ),
    "ruleSquad18Players": MessageLookupByLibrary.simpleMessage(
      "Squad: 18 total players",
    ),
    "ruleTeamLocksWhenMatchStarts": MessageLookupByLibrary.simpleMessage(
      "Team locks when match starts",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Rules"),
    "sameOrder": MessageLookupByLibrary.simpleMessage("Same order"),
    "saveTeam": MessageLookupByLibrary.simpleMessage("Save Team"),
    "saves": MessageLookupByLibrary.simpleMessage("Saves"),
    "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
    "searchByName": MessageLookupByLibrary.simpleMessage("Search by name..."),
    "searchCountryOrCode": MessageLookupByLibrary.simpleMessage(
      "Search country or code",
    ),
    "searchForPlayers": MessageLookupByLibrary.simpleMessage(
      "Search for Players",
    ),
    "searchHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Search history cleared",
    ),
    "searchPlayers": MessageLookupByLibrary.simpleMessage("Search Players"),
    "searchPlayersHint": MessageLookupByLibrary.simpleMessage(
      "Search players by name...",
    ),
    "searchPlayersHintShort": MessageLookupByLibrary.simpleMessage(
      "Search players...",
    ),
    "searchPlayersInOtherSquads": MessageLookupByLibrary.simpleMessage(
      "Search players in other squads...",
    ),
    "searchResultsTitle": MessageLookupByLibrary.simpleMessage(
      "Search Results",
    ),
    "searching": MessageLookupByLibrary.simpleMessage("Searching..."),
    "seasonAverages": MessageLookupByLibrary.simpleMessage("Season averages"),
    "seasonLabel": MessageLookupByLibrary.simpleMessage("Season"),
    "seedTradeMessage1": MessageLookupByLibrary.simpleMessage(
      "Need midfield creativity. Interested in a direct swap?",
    ),
    "seedTradeMessage2": MessageLookupByLibrary.simpleMessage(
      "I can overpay at MID if you can spare defensive depth.",
    ),
    "selBy": MessageLookupByLibrary.simpleMessage("Sell By"),
    "select": MessageLookupByLibrary.simpleMessage("Select 3-5 defender"),
    "selectBirthdate": MessageLookupByLibrary.simpleMessage("Select BirthDate"),
    "selectFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Select Your Favorite Team",
    ),
    "selectPlayerToDrop": MessageLookupByLibrary.simpleMessage(
      "Select player to drop",
    ),
    "selectPreferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Select Preferred Language",
    ),
    "sendToBank": MessageLookupByLibrary.simpleMessage("Send to Bank"),
    "setMatchReminder": MessageLookupByLibrary.simpleMessage(
      "Set Match Reminder",
    ),
    "setStarters": MessageLookupByLibrary.simpleMessage("Set Starters"),
    "setYourPreferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Set your Preferred Language",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "shareInvite": MessageLookupByLibrary.simpleMessage("Share invite"),
    "shareInviteCodeWithFriends": MessageLookupByLibrary.simpleMessage(
      "Share the invite code with friends to join",
    ),
    "shotsOnTarget": MessageLookupByLibrary.simpleMessage("Shots on Target"),
    "singleEntry": MessageLookupByLibrary.simpleMessage("Single Entry"),
    "snake": MessageLookupByLibrary.simpleMessage("Snake"),
    "snakeOrderExample": MessageLookupByLibrary.simpleMessage("1→10, 10→1..."),
    "spots": MessageLookupByLibrary.simpleMessage("spots"),
    "spotsAvailable": m35,
    "spotsLeft": MessageLookupByLibrary.simpleMessage("spots left"),
    "stageStatistics": m36,
    "standings": MessageLookupByLibrary.simpleMessage("Standings"),
    "standingsAppearAfterMatchStarts": MessageLookupByLibrary.simpleMessage(
      "Standings will appear after match starts",
    ),
    "started": MessageLookupByLibrary.simpleMessage("Started"),
    "startsInCountdown": m37,
    "startsInDaysHoursMinutes": m38,
    "statistics": MessageLookupByLibrary.simpleMessage("Statistics"),
    "stats": MessageLookupByLibrary.simpleMessage("Stats"),
    "strongPick": MessageLookupByLibrary.simpleMessage("Strong Pick"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "substitute": MessageLookupByLibrary.simpleMessage("Substitute"),
    "support": MessageLookupByLibrary.simpleMessage("Support"),
    "swapAction": MessageLookupByLibrary.simpleMessage("Swap"),
    "swapCompletedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Swap completed locally, but failed to persist roster update",
    ),
    "swappedPlayers": m39,
    "tackleWon": MessageLookupByLibrary.simpleMessage("Tackle Won"),
    "tapToSelect": MessageLookupByLibrary.simpleMessage("Tap to select"),
    "tbd": MessageLookupByLibrary.simpleMessage("TBD"),
    "team": MessageLookupByLibrary.simpleMessage("Team"),
    "teamBudget": MessageLookupByLibrary.simpleMessage("Team Budget"),
    "teamCreated": MessageLookupByLibrary.simpleMessage("Team created"),
    "teamCreatedThroughLiveDraftDescription": MessageLookupByLibrary.simpleMessage(
      "Your team is created through the live draft, not with the classic team builder.",
    ),
    "teamName": MessageLookupByLibrary.simpleMessage("Team Name"),
    "teamNameExampleHint": MessageLookupByLibrary.simpleMessage(
      "e.g., Los Galacticos FC",
    ),
    "teamWillBeDraftedLive": MessageLookupByLibrary.simpleMessage(
      "Team Will Be Drafted Live",
    ),
    "termsOfUse": MessageLookupByLibrary.simpleMessage("Terms of use"),
    "that": MessageLookupByLibrary.simpleMessage(
      "i.e. Earned 300 points x1.0 =300 points",
    ),
    "thatIs": MessageLookupByLibrary.simpleMessage(
      "i.e. Earned 300 points x1.5 =450 points",
    ),
    "thisLeagueIsFull": MessageLookupByLibrary.simpleMessage(
      "This league is full",
    ),
    "timePending": MessageLookupByLibrary.simpleMessage("Time pending"),
    "toUser": m40,
    "tomorrow": MessageLookupByLibrary.simpleMessage("Tomorrow"),
    "tour": MessageLookupByLibrary.simpleMessage(
      "Tour - Football Premier League",
    ),
    "tournamentStatistics": MessageLookupByLibrary.simpleMessage(
      "Tournament Statistics",
    ),
    "tradeAccepted": MessageLookupByLibrary.simpleMessage("Trade accepted"),
    "tradeApprovalCommissioner": MessageLookupByLibrary.simpleMessage(
      "Commissioner Approval",
    ),
    "tradeApprovalCommissionerDescription":
        MessageLookupByLibrary.simpleMessage(
          "Commissioner must approve all trades",
        ),
    "tradeApprovalLeagueVote": MessageLookupByLibrary.simpleMessage(
      "League Vote",
    ),
    "tradeApprovalLeagueVoteDescription": MessageLookupByLibrary.simpleMessage(
      "League members vote on trades (majority wins)",
    ),
    "tradeApprovalNone": MessageLookupByLibrary.simpleMessage("No Approval"),
    "tradeApprovalNoneDescription": MessageLookupByLibrary.simpleMessage(
      "Trades are processed immediately",
    ),
    "tradeApprovalTitle": MessageLookupByLibrary.simpleMessage(
      "Trade Approval",
    ),
    "tradeCancelled": MessageLookupByLibrary.simpleMessage("Trade cancelled"),
    "tradeDeadline": m41,
    "tradeDeadlineHasPassed": MessageLookupByLibrary.simpleMessage(
      "Trade deadline has passed",
    ),
    "tradeDeadlineOptional": MessageLookupByLibrary.simpleMessage(
      "Trade Deadline (Optional)",
    ),
    "tradeProposedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Trade proposed successfully",
    ),
    "tradeRejected": MessageLookupByLibrary.simpleMessage("Trade rejected"),
    "tradeSettings": MessageLookupByLibrary.simpleMessage("Trade Settings"),
    "tradeStatusAccepted": MessageLookupByLibrary.simpleMessage("Accepted"),
    "tradeStatusCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "tradeStatusCompleted": MessageLookupByLibrary.simpleMessage("Completed"),
    "tradeStatusExpired": MessageLookupByLibrary.simpleMessage("Expired"),
    "tradeStatusPending": MessageLookupByLibrary.simpleMessage("Pending"),
    "tradeStatusRejected": MessageLookupByLibrary.simpleMessage("Rejected"),
    "tradeStatusVetoed": MessageLookupByLibrary.simpleMessage("Vetoed"),
    "tradeTargetSubtitle": m42,
    "trades": MessageLookupByLibrary.simpleMessage("Trades"),
    "tradingClosed": MessageLookupByLibrary.simpleMessage("Trading is closed"),
    "transactionsTab": MessageLookupByLibrary.simpleMessage("Transactions"),
    "transferHistory": MessageLookupByLibrary.simpleMessage("Transfer History"),
    "transfers": MessageLookupByLibrary.simpleMessage("Transfers"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Try a different search term",
    ),
    "type": MessageLookupByLibrary.simpleMessage("Type"),
    "uniqueOwnership": MessageLookupByLibrary.simpleMessage("Unique ownership"),
    "upcoming": MessageLookupByLibrary.simpleMessage("UPCOMING"),
    "upcomingMatches": MessageLookupByLibrary.simpleMessage("Upcoming Matches"),
    "vcap": MessageLookupByLibrary.simpleMessage("v.cap"),
    "verification": MessageLookupByLibrary.simpleMessage("Verification"),
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Verification code resent",
    ),
    "veryHigh": MessageLookupByLibrary.simpleMessage("Very High"),
    "viewAdvancedStats": MessageLookupByLibrary.simpleMessage(
      "View Advanced Statistics",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("View all"),
    "viewArrow": MessageLookupByLibrary.simpleMessage("View →"),
    "viewProfile": MessageLookupByLibrary.simpleMessage("View Profile"),
    "viewStatsDetails": MessageLookupByLibrary.simpleMessage(
      "View Stats Details",
    ),
    "voteAgainst": MessageLookupByLibrary.simpleMessage("Against"),
    "voteAgainstAction": MessageLookupByLibrary.simpleMessage("Vote Against"),
    "voteFor": MessageLookupByLibrary.simpleMessage("For"),
    "voteForAction": MessageLookupByLibrary.simpleMessage("Vote For"),
    "voteRecorded": m43,
    "vs": MessageLookupByLibrary.simpleMessage("vs"),
    "vsUpper": MessageLookupByLibrary.simpleMessage("VS"),
    "waitingForDraftStart": MessageLookupByLibrary.simpleMessage(
      "Waiting For Draft Start",
    ),
    "waitingForOpponent": MessageLookupByLibrary.simpleMessage(
      "Waiting for opponent",
    ),
    "waitingForOpponentEllipsis": MessageLookupByLibrary.simpleMessage(
      "Waiting for opponent...",
    ),
    "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
    "weHaveSent": MessageLookupByLibrary.simpleMessage(
      "We\'ve sent 6 digit verification code.",
    ),
    "weWillSendVerificationCode": MessageLookupByLibrary.simpleMessage(
      "We\'ll send verification code.",
    ),
    "weight": MessageLookupByLibrary.simpleMessage("Weight"),
    "welcomeToLeagueTeamReady": m44,
    "whereWeAreAnd": MessageLookupByLibrary.simpleMessage(
      "Where we are & How we started",
    ),
    "whoWeAre": MessageLookupByLibrary.simpleMessage("Who we are?"),
    "willSend": MessageLookupByLibrary.simpleMessage(
      "Will send reminder when lineup announced",
    ),
    "winnings": MessageLookupByLibrary.simpleMessage("Winnings"),
    "wonAContest": MessageLookupByLibrary.simpleMessage("Won a Contest"),
    "writeUs": MessageLookupByLibrary.simpleMessage("Write us"),
    "writeYourMessage": MessageLookupByLibrary.simpleMessage(
      "Write your message",
    ),
    "yearsOld": MessageLookupByLibrary.simpleMessage("years old"),
    "yellow": MessageLookupByLibrary.simpleMessage("Yellow"),
    "youAlreadyVoted": MessageLookupByLibrary.simpleMessage(
      "You have already voted",
    ),
    "youAre": MessageLookupByLibrary.simpleMessage("You\'re on Level 89"),
    "youCannotVoteOwnTrade": MessageLookupByLibrary.simpleMessage(
      "You cannot vote on your own trade",
    ),
    "youGive": MessageLookupByLibrary.simpleMessage("You give:"),
    "youLabel": MessageLookupByLibrary.simpleMessage("You"),
    "youReceive": MessageLookupByLibrary.simpleMessage("You receive:"),
    "youUpper": MessageLookupByLibrary.simpleMessage("YOU"),
    "youWillGet": MessageLookupByLibrary.simpleMessage(
      "You\'ll get 10 more points on every paid match you joined",
    ),
    "yourFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Your Favorite Team",
    ),
    "yourPredictedPoints": MessageLookupByLibrary.simpleMessage(
      "Your Predicted Points",
    ),
  };
}
