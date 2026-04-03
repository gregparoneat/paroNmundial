// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `My Matches`
  String get myMatches {
    return Intl.message('My Matches', name: 'myMatches', desc: '', args: []);
  }

  /// `Fixtures`
  String get fixtures {
    return Intl.message('Fixtures', name: 'fixtures', desc: '', args: []);
  }

  /// `My Leagues`
  String get myLeagues {
    return Intl.message('My Leagues', name: 'myLeagues', desc: '', args: []);
  }

  /// `Wallet`
  String get wallet {
    return Intl.message('Wallet', name: 'wallet', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Let's Play`
  String get letsPlay {
    return Intl.message('Let\'s Play', name: 'letsPlay', desc: '', args: []);
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter Phone Number`
  String get enterPhoneNumber {
    return Intl.message(
      'Enter Phone Number',
      name: 'enterPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Or Continue with`
  String get orContinueWith {
    return Intl.message(
      'Or Continue with',
      name: 'orContinueWith',
      desc: '',
      args: [],
    );
  }

  /// `Facebook`
  String get facebook {
    return Intl.message('Facebook', name: 'facebook', desc: '', args: []);
  }

  /// `Google`
  String get google {
    return Intl.message('Google', name: 'google', desc: '', args: []);
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
  }

  /// `in less than a minute`
  String get inLessThanAMinute {
    return Intl.message(
      'in less than a minute',
      name: 'inLessThanAMinute',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message('Full Name', name: 'fullName', desc: '', args: []);
  }

  /// `Enter Full Name`
  String get enterFullName {
    return Intl.message(
      'Enter Full Name',
      name: 'enterFullName',
      desc: '',
      args: [],
    );
  }

  /// `Email Address`
  String get emailAddress {
    return Intl.message(
      'Email Address',
      name: 'emailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter Email Address`
  String get enterEmailAddress {
    return Intl.message(
      'Enter Email Address',
      name: 'enterEmailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Birthdate`
  String get birthdate {
    return Intl.message('Birthdate', name: 'birthdate', desc: '', args: []);
  }

  /// `Select BirthDate`
  String get selectBirthdate {
    return Intl.message(
      'Select BirthDate',
      name: 'selectBirthdate',
      desc: '',
      args: [],
    );
  }

  /// `We'll send verification code.`
  String get weWillSendVerificationCode {
    return Intl.message(
      'We\'ll send verification code.',
      name: 'weWillSendVerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `Verification`
  String get verification {
    return Intl.message(
      'Verification',
      name: 'verification',
      desc: '',
      args: [],
    );
  }

  /// `We've sent 6 digit verification code.`
  String get weHaveSent {
    return Intl.message(
      'We\'ve sent 6 digit verification code.',
      name: 'weHaveSent',
      desc: '',
      args: [],
    );
  }

  /// `Enter Code`
  String get enterCode {
    return Intl.message('Enter Code', name: 'enterCode', desc: '', args: []);
  }

  /// `Enter 6 digit code`
  String get enterSixDigit {
    return Intl.message(
      'Enter 6 digit code',
      name: 'enterSixDigit',
      desc: '',
      args: [],
    );
  }

  /// `Get Started`
  String get getStarted {
    return Intl.message('Get Started', name: 'getStarted', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Preferred Language`
  String get preferredLanguage {
    return Intl.message(
      'Preferred Language',
      name: 'preferredLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Select Preferred Language`
  String get selectPreferredLanguage {
    return Intl.message(
      'Select Preferred Language',
      name: 'selectPreferredLanguage',
      desc: '',
      args: [],
    );
  }

  /// `PRIZE POOL`
  String get prizePool {
    return Intl.message('PRIZE POOL', name: 'prizePool', desc: '', args: []);
  }

  /// `spots`
  String get spots {
    return Intl.message('spots', name: 'spots', desc: '', args: []);
  }

  /// `spots left`
  String get spotsLeft {
    return Intl.message('spots left', name: 'spotsLeft', desc: '', args: []);
  }

  /// `JOINED WITH 2 TEAMS`
  String get joinedWithTwoTeams {
    return Intl.message(
      'JOINED WITH 2 TEAMS',
      name: 'joinedWithTwoTeams',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continueText {
    return Intl.message('Continue', name: 'continueText', desc: '', args: []);
  }

  /// `Level`
  String get level {
    return Intl.message('Level', name: 'level', desc: '', args: []);
  }

  /// `All Teams`
  String get allTeams {
    return Intl.message('All Teams', name: 'allTeams', desc: '', args: []);
  }

  /// `Points`
  String get points {
    return Intl.message('Points', name: 'points', desc: '', args: []);
  }

  /// `Rank`
  String get rank {
    return Intl.message('Rank', name: 'rank', desc: '', args: []);
  }

  /// `Max 7 player from a team`
  String get maxSevenPlayers {
    return Intl.message(
      'Max 7 player from a team',
      name: 'maxSevenPlayers',
      desc: '',
      args: [],
    );
  }

  /// `Winnings`
  String get winnings {
    return Intl.message('Winnings', name: 'winnings', desc: '', args: []);
  }

  /// `Who we are?`
  String get whoWeAre {
    return Intl.message('Who we are?', name: 'whoWeAre', desc: '', args: []);
  }

  /// `How we started?`
  String get howWeStarted {
    return Intl.message(
      'How we started?',
      name: 'howWeStarted',
      desc: '',
      args: [],
    );
  }

  /// `Leaderboard`
  String get leaderboard {
    return Intl.message('Leaderboard', name: 'leaderboard', desc: '', args: []);
  }

  /// `Know where you stands in competition`
  String get knowWhereYouStand {
    return Intl.message(
      'Know where you stands in competition',
      name: 'knowWhereYouStand',
      desc: '',
      args: [],
    );
  }

  /// `About us`
  String get aboutUs {
    return Intl.message('About us', name: 'aboutUs', desc: '', args: []);
  }

  /// `Where we are & How we started`
  String get whereWeAreAnd {
    return Intl.message(
      'Where we are & How we started',
      name: 'whereWeAreAnd',
      desc: '',
      args: [],
    );
  }

  /// `Support`
  String get support {
    return Intl.message('Support', name: 'support', desc: '', args: []);
  }

  /// `Connect us for Issues`
  String get connectUsForIssues {
    return Intl.message(
      'Connect us for Issues',
      name: 'connectUsForIssues',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Know our Privacy Policies`
  String get knowOurPrivacyPolicies {
    return Intl.message(
      'Know our Privacy Policies',
      name: 'knowOurPrivacyPolicies',
      desc: '',
      args: [],
    );
  }

  /// `Change Language`
  String get changeLanguage {
    return Intl.message(
      'Change Language',
      name: 'changeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Set your Preferred Language`
  String get setYourPreferredLanguage {
    return Intl.message(
      'Set your Preferred Language',
      name: 'setYourPreferredLanguage',
      desc: '',
      args: [],
    );
  }

  /// `FAQs`
  String get faqs {
    return Intl.message('FAQs', name: 'faqs', desc: '', args: []);
  }

  /// `Get your questions answered`
  String get getYourQuestionsAnswered {
    return Intl.message(
      'Get your questions answered',
      name: 'getYourQuestionsAnswered',
      desc: '',
      args: [],
    );
  }

  /// `View Profile`
  String get viewProfile {
    return Intl.message(
      'View Profile',
      name: 'viewProfile',
      desc: '',
      args: [],
    );
  }

  /// `Earn 129 more points to reach level 90`
  String get earnOneHundred {
    return Intl.message(
      'Earn 129 more points to reach level 90',
      name: 'earnOneHundred',
      desc: '',
      args: [],
    );
  }

  /// `How to Play?`
  String get howToPlay {
    return Intl.message('How to Play?', name: 'howToPlay', desc: '', args: []);
  }

  /// `How to add money?`
  String get howToAddMoney {
    return Intl.message(
      'How to add money?',
      name: 'howToAddMoney',
      desc: '',
      args: [],
    );
  }

  /// `How to select player?`
  String get howToSelectMoney {
    return Intl.message(
      'How to select player?',
      name: 'howToSelectMoney',
      desc: '',
      args: [],
    );
  }

  /// `How to change profile picture?`
  String get howToChangeProfile {
    return Intl.message(
      'How to change profile picture?',
      name: 'howToChangeProfile',
      desc: '',
      args: [],
    );
  }

  /// `How to send money to bank?`
  String get howToSend {
    return Intl.message(
      'How to send money to bank?',
      name: 'howToSend',
      desc: '',
      args: [],
    );
  }

  /// `How to Shop?`
  String get howToShop {
    return Intl.message('How to Shop?', name: 'howToShop', desc: '', args: []);
  }

  /// `How to change language?`
  String get howToChangeLanguage {
    return Intl.message(
      'How to change language?',
      name: 'howToChangeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Can I login through Social account?`
  String get canILogin {
    return Intl.message(
      'Can I login through Social account?',
      name: 'canILogin',
      desc: '',
      args: [],
    );
  }

  /// `How to Logout my account?`
  String get howToLogoutMyAccount {
    return Intl.message(
      'How to Logout my account?',
      name: 'howToLogoutMyAccount',
      desc: '',
      args: [],
    );
  }

  /// `Get your answers`
  String get getYourAnswers {
    return Intl.message(
      'Get your answers',
      name: 'getYourAnswers',
      desc: '',
      args: [],
    );
  }

  /// `All Series`
  String get allSeries {
    return Intl.message('All Series', name: 'allSeries', desc: '', args: []);
  }

  /// `You'll get 10 more points on every paid match you joined`
  String get youWillGet {
    return Intl.message(
      'You\'ll get 10 more points on every paid match you joined',
      name: 'youWillGet',
      desc: '',
      args: [],
    );
  }

  /// `Le joined 2 match = 20 points`
  String get LeJoined {
    return Intl.message(
      'Le joined 2 match = 20 points',
      name: 'LeJoined',
      desc: '',
      args: [],
    );
  }

  /// `If you joined and won the contest you'll get 1.5x of points.`
  String get ifYou {
    return Intl.message(
      'If you joined and won the contest you\'ll get 1.5x of points.',
      name: 'ifYou',
      desc: '',
      args: [],
    );
  }

  /// `i.e. Earned 300 points x1.5 =450 points`
  String get thatIs {
    return Intl.message(
      'i.e. Earned 300 points x1.5 =450 points',
      name: 'thatIs',
      desc: '',
      args: [],
    );
  }

  /// `If you joined and won the contest you'll get 1.0x of points.`
  String get iff {
    return Intl.message(
      'If you joined and won the contest you\'ll get 1.0x of points.',
      name: 'iff',
      desc: '',
      args: [],
    );
  }

  /// `i.e. Earned 300 points x1.0 =300 points`
  String get that {
    return Intl.message(
      'i.e. Earned 300 points x1.0 =300 points',
      name: 'that',
      desc: '',
      args: [],
    );
  }

  /// `You're on Level 89`
  String get youAre {
    return Intl.message(
      'You\'re on Level 89',
      name: 'youAre',
      desc: '',
      args: [],
    );
  }

  /// `How it works?`
  String get howItWorks {
    return Intl.message(
      'How it works?',
      name: 'howItWorks',
      desc: '',
      args: [],
    );
  }

  /// `How we work`
  String get howWeWork {
    return Intl.message('How we work', name: 'howWeWork', desc: '', args: []);
  }

  /// `Terms of use`
  String get termsOfUse {
    return Intl.message('Terms of use', name: 'termsOfUse', desc: '', args: []);
  }

  /// `My Profile`
  String get myProfile {
    return Intl.message('My Profile', name: 'myProfile', desc: '', args: []);
  }

  /// `Everything about you`
  String get everythingAboutYou {
    return Intl.message(
      'Everything about you',
      name: 'everythingAboutYou',
      desc: '',
      args: [],
    );
  }

  /// `Team Name`
  String get teamName {
    return Intl.message('Team Name', name: 'teamName', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Joined a Contest`
  String get joinedAContest {
    return Intl.message(
      'Joined a Contest',
      name: 'joinedAContest',
      desc: '',
      args: [],
    );
  }

  /// `Added to Wallet`
  String get addedToWallet {
    return Intl.message(
      'Added to Wallet',
      name: 'addedToWallet',
      desc: '',
      args: [],
    );
  }

  /// `Won a Contest`
  String get wonAContest {
    return Intl.message(
      'Won a Contest',
      name: 'wonAContest',
      desc: '',
      args: [],
    );
  }

  /// `Available Balance`
  String get availableBalance {
    return Intl.message(
      'Available Balance',
      name: 'availableBalance',
      desc: '',
      args: [],
    );
  }

  /// `Choose Captain & Vice Captain`
  String get chooseCaptain {
    return Intl.message(
      'Choose Captain & Vice Captain',
      name: 'chooseCaptain',
      desc: '',
      args: [],
    );
  }

  /// `C will get 2x points & VC will get 1.5x points`
  String get cWillGet {
    return Intl.message(
      'C will get 2x points & VC will get 1.5x points',
      name: 'cWillGet',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get type {
    return Intl.message('Type', name: 'type', desc: '', args: []);
  }

  /// `Point`
  String get point {
    return Intl.message('Point', name: 'point', desc: '', args: []);
  }

  /// `Cap`
  String get cap {
    return Intl.message('Cap', name: 'cap', desc: '', args: []);
  }

  /// `v.cap`
  String get vcap {
    return Intl.message('v.cap', name: 'vcap', desc: '', args: []);
  }

  /// `Save Team`
  String get saveTeam {
    return Intl.message('Save Team', name: 'saveTeam', desc: '', args: []);
  }

  /// `CONTESTS`
  String get contests {
    return Intl.message('CONTESTS', name: 'contests', desc: '', args: []);
  }

  /// `MY CONTESTS (2)`
  String get myContestsTwo {
    return Intl.message(
      'MY CONTESTS (2)',
      name: 'myContestsTwo',
      desc: '',
      args: [],
    );
  }

  /// `MY TEAM (3)`
  String get myTeamThree {
    return Intl.message('MY TEAM (3)', name: 'myTeamThree', desc: '', args: []);
  }

  /// `Max Contest`
  String get maxContest {
    return Intl.message('Max Contest', name: 'maxContest', desc: '', args: []);
  }

  /// `Multiple Entries`
  String get multipleEntries {
    return Intl.message(
      'Multiple Entries',
      name: 'multipleEntries',
      desc: '',
      args: [],
    );
  }

  /// `Head to Head`
  String get headToHead {
    return Intl.message('Head to Head', name: 'headToHead', desc: '', args: []);
  }

  /// `Single Entry`
  String get singleEntry {
    return Intl.message(
      'Single Entry',
      name: 'singleEntry',
      desc: '',
      args: [],
    );
  }

  /// `Create Team`
  String get createTeam {
    return Intl.message('Create Team', name: 'createTeam', desc: '', args: []);
  }

  /// `Set Match Reminder`
  String get setMatchReminder {
    return Intl.message(
      'Set Match Reminder',
      name: 'setMatchReminder',
      desc: '',
      args: [],
    );
  }

  /// `Match - ALS vs CBR`
  String get matchvs {
    return Intl.message(
      'Match - ALS vs CBR',
      name: 'matchvs',
      desc: '',
      args: [],
    );
  }

  /// `Will send reminder when lineup announced`
  String get willSend {
    return Intl.message(
      'Will send reminder when lineup announced',
      name: 'willSend',
      desc: '',
      args: [],
    );
  }

  /// `Tour - Football Premier League`
  String get tour {
    return Intl.message(
      'Tour - Football Premier League',
      name: 'tour',
      desc: '',
      args: [],
    );
  }

  /// `Select 3-5 defender`
  String get select {
    return Intl.message(
      'Select 3-5 defender',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Sell By`
  String get selBy {
    return Intl.message('Sell By', name: 'selBy', desc: '', args: []);
  }

  /// `Credit`
  String get credit {
    return Intl.message('Credit', name: 'credit', desc: '', args: []);
  }

  /// `In playing 11`
  String get inPlayingEleven {
    return Intl.message(
      'In playing 11',
      name: 'inPlayingEleven',
      desc: '',
      args: [],
    );
  }

  /// `Substitute`
  String get substitute {
    return Intl.message('Substitute', name: 'substitute', desc: '', args: []);
  }

  /// `Goals`
  String get goals {
    return Intl.message('Goals', name: 'goals', desc: '', args: []);
  }

  /// `Assists`
  String get assists {
    return Intl.message('Assists', name: 'assists', desc: '', args: []);
  }

  /// `Shots on Target`
  String get shotsOnTarget {
    return Intl.message(
      'Shots on Target',
      name: 'shotsOnTarget',
      desc: '',
      args: [],
    );
  }

  /// `Passes Completed`
  String get passesCompleted {
    return Intl.message(
      'Passes Completed',
      name: 'passesCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Tackle Won`
  String get tackleWon {
    return Intl.message('Tackle Won', name: 'tackleWon', desc: '', args: []);
  }

  /// `Interceptions Won`
  String get interceptionsWon {
    return Intl.message(
      'Interceptions Won',
      name: 'interceptionsWon',
      desc: '',
      args: [],
    );
  }

  /// `Blocked Shots`
  String get blockedShots {
    return Intl.message(
      'Blocked Shots',
      name: 'blockedShots',
      desc: '',
      args: [],
    );
  }

  /// `Clearance`
  String get clearance {
    return Intl.message('Clearance', name: 'clearance', desc: '', args: []);
  }

  /// `DEFENDERS`
  String get defenders {
    return Intl.message('DEFENDERS', name: 'defenders', desc: '', args: []);
  }

  /// `ADD`
  String get add {
    return Intl.message('ADD', name: 'add', desc: '', args: []);
  }

  /// `Recent match status`
  String get recentMatchStatus {
    return Intl.message(
      'Recent match status',
      name: 'recentMatchStatus',
      desc: '',
      args: [],
    );
  }

  /// `Events`
  String get events {
    return Intl.message('Events', name: 'events', desc: '', args: []);
  }

  /// `Actual`
  String get actual {
    return Intl.message('Actual', name: 'actual', desc: '', args: []);
  }

  /// `Football`
  String get football {
    return Intl.message('Football', name: 'football', desc: '', args: []);
  }

  /// `View all`
  String get viewAll {
    return Intl.message('View all', name: 'viewAll', desc: '', args: []);
  }

  /// `Upcoming Matches`
  String get upcomingMatches {
    return Intl.message(
      'Upcoming Matches',
      name: 'upcomingMatches',
      desc: '',
      args: [],
    );
  }

  /// `Match Completed`
  String get matchCompleted {
    return Intl.message(
      'Match Completed',
      name: 'matchCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Stats`
  String get stats {
    return Intl.message('Stats', name: 'stats', desc: '', args: []);
  }

  /// `Players`
  String get players {
    return Intl.message('Players', name: 'players', desc: '', args: []);
  }

  /// `Match Live`
  String get matchLive {
    return Intl.message('Match Live', name: 'matchLive', desc: '', args: []);
  }

  /// `UPCOMING`
  String get upcoming {
    return Intl.message('UPCOMING', name: 'upcoming', desc: '', args: []);
  }

  /// `LIVE`
  String get live {
    return Intl.message('LIVE', name: 'live', desc: '', args: []);
  }

  /// `COMPLETED`
  String get completed {
    return Intl.message('COMPLETED', name: 'completed', desc: '', args: []);
  }

  /// `Call us`
  String get callUs {
    return Intl.message('Call us', name: 'callUs', desc: '', args: []);
  }

  /// `Mail us`
  String get mailUs {
    return Intl.message('Mail us', name: 'mailUs', desc: '', args: []);
  }

  /// `Add Money`
  String get addMoney {
    return Intl.message('Add Money', name: 'addMoney', desc: '', args: []);
  }

  /// `Send to Bank`
  String get sendToBank {
    return Intl.message('Send to Bank', name: 'sendToBank', desc: '', args: []);
  }

  /// `Amount`
  String get amount {
    return Intl.message('Amount', name: 'amount', desc: '', args: []);
  }

  /// `Payment Method`
  String get paymentMethod {
    return Intl.message(
      'Payment Method',
      name: 'paymentMethod',
      desc: '',
      args: [],
    );
  }

  /// `Enter amount`
  String get enterAmount {
    return Intl.message(
      'Enter amount',
      name: 'enterAmount',
      desc: '',
      args: [],
    );
  }

  /// `Bank Details`
  String get bankDetails {
    return Intl.message(
      'Bank Details',
      name: 'bankDetails',
      desc: '',
      args: [],
    );
  }

  /// `Account Name`
  String get accountName {
    return Intl.message(
      'Account Name',
      name: 'accountName',
      desc: '',
      args: [],
    );
  }

  /// `Account holder name`
  String get accountHolderName {
    return Intl.message(
      'Account holder name',
      name: 'accountHolderName',
      desc: '',
      args: [],
    );
  }

  /// `Account Number`
  String get accountNumber {
    return Intl.message(
      'Account Number',
      name: 'accountNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter account number`
  String get enterAccountNumber {
    return Intl.message(
      'Enter account number',
      name: 'enterAccountNumber',
      desc: '',
      args: [],
    );
  }

  /// `IFSC Code`
  String get ifscCode {
    return Intl.message('IFSC Code', name: 'ifscCode', desc: '', args: []);
  }

  /// `Bank IFSC code`
  String get bankIfscCode {
    return Intl.message(
      'Bank IFSC code',
      name: 'bankIfscCode',
      desc: '',
      args: [],
    );
  }

  /// `No other sports available, contact admin`
  String get noOtherSportsAvailableContactAdmin {
    return Intl.message(
      'No other sports available, contact admin',
      name: 'noOtherSportsAvailableContactAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Write us`
  String get writeUs {
    return Intl.message('Write us', name: 'writeUs', desc: '', args: []);
  }

  /// `Add your issue/feedback`
  String get addYourIssuefeedback {
    return Intl.message(
      'Add your issue/feedback',
      name: 'addYourIssuefeedback',
      desc: '',
      args: [],
    );
  }

  /// `Write your message`
  String get writeYourMessage {
    return Intl.message(
      'Write your message',
      name: 'writeYourMessage',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Player Details`
  String get playerDetails {
    return Intl.message(
      'Player Details',
      name: 'playerDetails',
      desc: '',
      args: [],
    );
  }

  /// `Player not found`
  String get playerNotFound {
    return Intl.message(
      'Player not found',
      name: 'playerNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Fantasy Points Prediction`
  String get fantasyPointsPrediction {
    return Intl.message(
      'Fantasy Points Prediction',
      name: 'fantasyPointsPrediction',
      desc: '',
      args: [],
    );
  }

  /// `Last 5 Form`
  String get last5Form {
    return Intl.message('Last 5 Form', name: 'last5Form', desc: '', args: []);
  }

  /// `Confidence`
  String get confidence {
    return Intl.message('Confidence', name: 'confidence', desc: '', args: []);
  }

  /// `Key Factors`
  String get keyFactors {
    return Intl.message('Key Factors', name: 'keyFactors', desc: '', args: []);
  }

  /// `Loading next match...`
  String get loadingNextMatch {
    return Intl.message(
      'Loading next match...',
      name: 'loadingNextMatch',
      desc: '',
      args: [],
    );
  }

  /// `Next Match`
  String get nextMatch {
    return Intl.message('Next Match', name: 'nextMatch', desc: '', args: []);
  }

  /// `Tournament Statistics`
  String get tournamentStatistics {
    return Intl.message(
      'Tournament Statistics',
      name: 'tournamentStatistics',
      desc: '',
      args: [],
    );
  }

  /// `Recent Form`
  String get recentForm {
    return Intl.message('Recent Form', name: 'recentForm', desc: '', args: []);
  }

  /// `matches`
  String get matches {
    return Intl.message('matches', name: 'matches', desc: '', args: []);
  }

  /// `Last {count} matches`
  String lastNMatches(int count) {
    return Intl.message(
      'Last $count matches',
      name: 'lastNMatches',
      desc: '',
      args: [count],
    );
  }

  /// `{count} matches`
  String nMatches(int count) {
    return Intl.message(
      '$count matches',
      name: 'nMatches',
      desc: '',
      args: [count],
    );
  }

  /// `Loading tournament stats...`
  String get loadingTournamentStats {
    return Intl.message(
      'Loading tournament stats...',
      name: 'loadingTournamentStats',
      desc: '',
      args: [],
    );
  }

  /// `Games`
  String get games {
    return Intl.message('Games', name: 'games', desc: '', args: []);
  }

  /// `Minutes`
  String get minutes {
    return Intl.message('Minutes', name: 'minutes', desc: '', args: []);
  }

  /// `Yellow`
  String get yellow {
    return Intl.message('Yellow', name: 'yellow', desc: '', args: []);
  }

  /// `Red`
  String get red {
    return Intl.message('Red', name: 'red', desc: '', args: []);
  }

  /// `Clean Sheets`
  String get cleanSheets {
    return Intl.message(
      'Clean Sheets',
      name: 'cleanSheets',
      desc: '',
      args: [],
    );
  }

  /// `Saves`
  String get saves {
    return Intl.message('Saves', name: 'saves', desc: '', args: []);
  }

  /// `Avg Rating`
  String get avgRating {
    return Intl.message('Avg Rating', name: 'avgRating', desc: '', args: []);
  }

  /// `Full Season Statistics`
  String get fullSeasonStatistics {
    return Intl.message(
      'Full Season Statistics',
      name: 'fullSeasonStatistics',
      desc: '',
      args: [],
    );
  }

  /// `Includes Apertura + Clausura tournaments`
  String get includesAperturaClausura {
    return Intl.message(
      'Includes Apertura + Clausura tournaments',
      name: 'includesAperturaClausura',
      desc: '',
      args: [],
    );
  }

  /// `Appearances`
  String get appearances {
    return Intl.message('Appearances', name: 'appearances', desc: '', args: []);
  }

  /// `Age`
  String get age {
    return Intl.message('Age', name: 'age', desc: '', args: []);
  }

  /// `Height`
  String get height {
    return Intl.message('Height', name: 'height', desc: '', args: []);
  }

  /// `Weight`
  String get weight {
    return Intl.message('Weight', name: 'weight', desc: '', args: []);
  }

  /// `Nationality`
  String get nationality {
    return Intl.message('Nationality', name: 'nationality', desc: '', args: []);
  }

  /// `Position`
  String get position {
    return Intl.message('Position', name: 'position', desc: '', args: []);
  }

  /// `Team`
  String get team {
    return Intl.message('Team', name: 'team', desc: '', args: []);
  }

  /// `years old`
  String get yearsOld {
    return Intl.message('years old', name: 'yearsOld', desc: '', args: []);
  }

  /// `cm`
  String get cm {
    return Intl.message('cm', name: 'cm', desc: '', args: []);
  }

  /// `kg`
  String get kg {
    return Intl.message('kg', name: 'kg', desc: '', args: []);
  }

  /// `Based on {position} metrics`
  String basedOnMetrics(String position) {
    return Intl.message(
      'Based on $position metrics',
      name: 'basedOnMetrics',
      desc: '',
      args: [position],
    );
  }

  /// `Season averages`
  String get seasonAverages {
    return Intl.message(
      'Season averages',
      name: 'seasonAverages',
      desc: '',
      args: [],
    );
  }

  /// `matchup`
  String get matchup {
    return Intl.message('matchup', name: 'matchup', desc: '', args: []);
  }

  /// `Elite Pick`
  String get elitePick {
    return Intl.message('Elite Pick', name: 'elitePick', desc: '', args: []);
  }

  /// `Strong Pick`
  String get strongPick {
    return Intl.message('Strong Pick', name: 'strongPick', desc: '', args: []);
  }

  /// `Good Pick`
  String get goodPick {
    return Intl.message('Good Pick', name: 'goodPick', desc: '', args: []);
  }

  /// `Risky Pick`
  String get riskyPick {
    return Intl.message('Risky Pick', name: 'riskyPick', desc: '', args: []);
  }

  /// `Avoid`
  String get avoid {
    return Intl.message('Avoid', name: 'avoid', desc: '', args: []);
  }

  /// `Excellent`
  String get excellent {
    return Intl.message('Excellent', name: 'excellent', desc: '', args: []);
  }

  /// `Good`
  String get good {
    return Intl.message('Good', name: 'good', desc: '', args: []);
  }

  /// `Average`
  String get average {
    return Intl.message('Average', name: 'average', desc: '', args: []);
  }

  /// `Poor`
  String get poor {
    return Intl.message('Poor', name: 'poor', desc: '', args: []);
  }

  /// `Very High`
  String get veryHigh {
    return Intl.message('Very High', name: 'veryHigh', desc: '', args: []);
  }

  /// `High`
  String get high {
    return Intl.message('High', name: 'high', desc: '', args: []);
  }

  /// `Medium`
  String get medium {
    return Intl.message('Medium', name: 'medium', desc: '', args: []);
  }

  /// `Low`
  String get low {
    return Intl.message('Low', name: 'low', desc: '', args: []);
  }

  /// `Goalkeeper`
  String get goalkeeper {
    return Intl.message('Goalkeeper', name: 'goalkeeper', desc: '', args: []);
  }

  /// `Defender`
  String get defender {
    return Intl.message('Defender', name: 'defender', desc: '', args: []);
  }

  /// `Midfielder`
  String get midfielder {
    return Intl.message('Midfielder', name: 'midfielder', desc: '', args: []);
  }

  /// `Attacker`
  String get attacker {
    return Intl.message('Attacker', name: 'attacker', desc: '', args: []);
  }

  /// `Forward`
  String get forward {
    return Intl.message('Forward', name: 'forward', desc: '', args: []);
  }

  /// `Search Players`
  String get searchPlayers {
    return Intl.message(
      'Search Players',
      name: 'searchPlayers',
      desc: '',
      args: [],
    );
  }

  /// `Search by name...`
  String get searchByName {
    return Intl.message(
      'Search by name...',
      name: 'searchByName',
      desc: '',
      args: [],
    );
  }

  /// `No players found`
  String get noPlayersFound {
    return Intl.message(
      'No players found',
      name: 'noPlayersFound',
      desc: '',
      args: [],
    );
  }

  /// `Recent Searches`
  String get recentSearches {
    return Intl.message(
      'Recent Searches',
      name: 'recentSearches',
      desc: '',
      args: [],
    );
  }

  /// `Clear All`
  String get clearAll {
    return Intl.message('Clear All', name: 'clearAll', desc: '', args: []);
  }

  /// `Statistics`
  String get statistics {
    return Intl.message('Statistics', name: 'statistics', desc: '', args: []);
  }

  /// `{stageName} Statistics`
  String stageStatistics(String stageName) {
    return Intl.message(
      '$stageName Statistics',
      name: 'stageStatistics',
      desc: '',
      args: [stageName],
    );
  }

  /// `Transfer History`
  String get transferHistory {
    return Intl.message(
      'Transfer History',
      name: 'transferHistory',
      desc: '',
      args: [],
    );
  }

  /// `Current Team`
  String get currentTeam {
    return Intl.message(
      'Current Team',
      name: 'currentTeam',
      desc: '',
      args: [],
    );
  }

  /// `Previous Teams`
  String get previousTeams {
    return Intl.message(
      'Previous Teams',
      name: 'previousTeams',
      desc: '',
      args: [],
    );
  }

  /// `Jersey Number`
  String get jerseyNumber {
    return Intl.message(
      'Jersey Number',
      name: 'jerseyNumber',
      desc: '',
      args: [],
    );
  }

  /// `Rating`
  String get rating {
    return Intl.message('Rating', name: 'rating', desc: '', args: []);
  }

  /// `vs`
  String get vs {
    return Intl.message('vs', name: 'vs', desc: '', args: []);
  }

  /// `Player Info`
  String get playerInfo {
    return Intl.message('Player Info', name: 'playerInfo', desc: '', args: []);
  }

  /// `Date of Birth`
  String get dateOfBirth {
    return Intl.message(
      'Date of Birth',
      name: 'dateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Role`
  String get role {
    return Intl.message('Role', name: 'role', desc: '', args: []);
  }

  /// `Captain`
  String get captain {
    return Intl.message('Captain', name: 'captain', desc: '', args: []);
  }

  /// `Transfers`
  String get transfers {
    return Intl.message('Transfers', name: 'transfers', desc: '', args: []);
  }

  /// `Apps`
  String get apps {
    return Intl.message('Apps', name: 'apps', desc: '', args: []);
  }

  /// `Average Rating`
  String get averageRating {
    return Intl.message(
      'Average Rating',
      name: 'averageRating',
      desc: '',
      args: [],
    );
  }

  /// `Career Totals`
  String get careerTotals {
    return Intl.message(
      'Career Totals',
      name: 'careerTotals',
      desc: '',
      args: [],
    );
  }

  /// `Clear History`
  String get clearHistoryTitle {
    return Intl.message(
      'Clear History',
      name: 'clearHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear your recent players history?`
  String get clearHistoryMessage {
    return Intl.message(
      'Are you sure you want to clear your recent players history?',
      name: 'clearHistoryMessage',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `Search history cleared`
  String get searchHistoryCleared {
    return Intl.message(
      'Search history cleared',
      name: 'searchHistoryCleared',
      desc: '',
      args: [],
    );
  }

  /// `Search players by name...`
  String get searchPlayersHint {
    return Intl.message(
      'Search players by name...',
      name: 'searchPlayersHint',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `No players found for "{query}"`
  String noPlayersFoundFor(String query) {
    return Intl.message(
      'No players found for "$query"',
      name: 'noPlayersFoundFor',
      desc: '',
      args: [query],
    );
  }

  /// `Try a different search term`
  String get tryDifferentSearch {
    return Intl.message(
      'Try a different search term',
      name: 'tryDifferentSearch',
      desc: '',
      args: [],
    );
  }

  /// `Search Results`
  String get searchResultsTitle {
    return Intl.message(
      'Search Results',
      name: 'searchResultsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Recent Players`
  String get recentPlayersTitle {
    return Intl.message(
      'Recent Players',
      name: 'recentPlayersTitle',
      desc: '',
      args: [],
    );
  }

  /// `Search for Players`
  String get searchForPlayers {
    return Intl.message(
      'Search for Players',
      name: 'searchForPlayers',
      desc: '',
      args: [],
    );
  }

  /// `Enter at least 3 characters to search`
  String get enterAtLeast3Chars {
    return Intl.message(
      'Enter at least 3 characters to search',
      name: 'enterAtLeast3Chars',
      desc: '',
      args: [],
    );
  }

  /// `Last {count} matches`
  String lastMatchesPlus(int count) {
    return Intl.message(
      'Last $count matches',
      name: 'lastMatchesPlus',
      desc: '',
      args: [count],
    );
  }

  /// `+ matchup`
  String get plusMatchup {
    return Intl.message('+ matchup', name: 'plusMatchup', desc: '', args: []);
  }

  /// `Select Your Favorite Team`
  String get selectFavoriteTeam {
    return Intl.message(
      'Select Your Favorite Team',
      name: 'selectFavoriteTeam',
      desc: '',
      args: [],
    );
  }

  /// `Choose your favorite national team. We'll personalize your experience and show players from your team first.`
  String get favoriteTeamDescription {
    return Intl.message(
      'Choose your favorite national team. We\'ll personalize your experience and show players from your team first.',
      name: 'favoriteTeamDescription',
      desc: '',
      args: [],
    );
  }

  /// `Error loading teams`
  String get errorLoadingTeams {
    return Intl.message(
      'Error loading teams',
      name: 'errorLoadingTeams',
      desc: '',
      args: [],
    );
  }

  /// `No teams found`
  String get noTeamsFound {
    return Intl.message(
      'No teams found',
      name: 'noTeamsFound',
      desc: '',
      args: [],
    );
  }

  /// `Saving...`
  String get saving {
    return Intl.message('Saving...', name: 'saving', desc: '', args: []);
  }

  /// `Favorite Team`
  String get favoriteTeam {
    return Intl.message(
      'Favorite Team',
      name: 'favoriteTeam',
      desc: '',
      args: [],
    );
  }

  /// `Change Favorite Team`
  String get changeFavoriteTeam {
    return Intl.message(
      'Change Favorite Team',
      name: 'changeFavoriteTeam',
      desc: '',
      args: [],
    );
  }

  /// `Your Favorite Team`
  String get yourFavoriteTeam {
    return Intl.message(
      'Your Favorite Team',
      name: 'yourFavoriteTeam',
      desc: '',
      args: [],
    );
  }

  /// `Loading recent form...`
  String get loadingRecentStats {
    return Intl.message(
      'Loading recent form...',
      name: 'loadingRecentStats',
      desc: '',
      args: [],
    );
  }

  /// `No Recent Stats`
  String get noRecentStatsTitle {
    return Intl.message(
      'No Recent Stats',
      name: 'noRecentStatsTitle',
      desc: '',
      args: [],
    );
  }

  /// `This player doesn't have recent stats in the Mexican league within the last 6 weeks.`
  String get noRecentStatsMessage {
    return Intl.message(
      'This player doesn\'t have recent stats in the Mexican league within the last 6 weeks.',
      name: 'noRecentStatsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Based on {count} fixtures analyzed (some may have been skipped)`
  String fixturesAnalyzedNote(int count) {
    return Intl.message(
      'Based on $count fixtures analyzed (some may have been skipped)',
      name: 'fixturesAnalyzedNote',
      desc: '',
      args: [count],
    );
  }

  /// `Limited playtime recently - may be injured or benched`
  String get playerLimitedPlaytime {
    return Intl.message(
      'Limited playtime recently - may be injured or benched',
      name: 'playerLimitedPlaytime',
      desc: '',
      args: [],
    );
  }

  /// `View Advanced Statistics`
  String get viewAdvancedStats {
    return Intl.message(
      'View Advanced Statistics',
      name: 'viewAdvancedStats',
      desc: '',
      args: [],
    );
  }

  /// `View Stats Details`
  String get viewStatsDetails {
    return Intl.message(
      'View Stats Details',
      name: 'viewStatsDetails',
      desc: '',
      args: [],
    );
  }

  /// `Country Code`
  String get countryCode {
    return Intl.message(
      'Country Code',
      name: 'countryCode',
      desc: '',
      args: [],
    );
  }

  /// `Search country or code`
  String get searchCountryOrCode {
    return Intl.message(
      'Search country or code',
      name: 'searchCountryOrCode',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your phone number`
  String get pleaseEnterPhoneNumber {
    return Intl.message(
      'Please enter your phone number',
      name: 'pleaseEnterPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please complete at least name and phone number`
  String get pleaseCompleteNameAndPhone {
    return Intl.message(
      'Please complete at least name and phone number',
      name: 'pleaseCompleteNameAndPhone',
      desc: '',
      args: [],
    );
  }

  /// `Enter the 6-digit verification code`
  String get enterSixDigitVerificationCode {
    return Intl.message(
      'Enter the 6-digit verification code',
      name: 'enterSixDigitVerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `Please wait {seconds} seconds before resending`
  String pleaseWaitBeforeResending(int seconds) {
    return Intl.message(
      'Please wait $seconds seconds before resending',
      name: 'pleaseWaitBeforeResending',
      desc: '',
      args: [seconds],
    );
  }

  /// `Verification code resent`
  String get verificationCodeResent {
    return Intl.message(
      'Verification code resent',
      name: 'verificationCodeResent',
      desc: '',
      args: [],
    );
  }

  /// `Clearing cache...`
  String get clearingCache {
    return Intl.message(
      'Clearing cache...',
      name: 'clearingCache',
      desc: '',
      args: [],
    );
  }

  /// `Cache cleared! Restart app for fresh data.`
  String get cacheClearedRestart {
    return Intl.message(
      'Cache cleared! Restart app for fresh data.',
      name: 'cacheClearedRestart',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get errorLabel {
    return Intl.message('Error', name: 'errorLabel', desc: '', args: []);
  }

  /// `Clear Cache`
  String get clearCacheTitle {
    return Intl.message(
      'Clear Cache',
      name: 'clearCacheTitle',
      desc: '',
      args: [],
    );
  }

  /// `Clear all cached data (for testing)`
  String get clearCacheSubtitle {
    return Intl.message(
      'Clear all cached data (for testing)',
      name: 'clearCacheSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get overview {
    return Intl.message('Overview', name: 'overview', desc: '', args: []);
  }

  /// `Members`
  String get members {
    return Intl.message('Members', name: 'members', desc: '', args: []);
  }

  /// `Standings`
  String get standings {
    return Intl.message('Standings', name: 'standings', desc: '', args: []);
  }

  /// `Rules`
  String get rules {
    return Intl.message('Rules', name: 'rules', desc: '', args: []);
  }

  /// `Draft completed`
  String get draftCompleted {
    return Intl.message(
      'Draft completed',
      name: 'draftCompleted',
      desc: '',
      args: [],
    );
  }

  /// `How Draft Leagues Work`
  String get howDraftLeaguesWork {
    return Intl.message(
      'How Draft Leagues Work',
      name: 'howDraftLeaguesWork',
      desc: '',
      args: [],
    );
  }

  /// `Quick guide for users coming from classic budget fantasy.`
  String get quickDraftGuideSubtitle {
    return Intl.message(
      'Quick guide for users coming from classic budget fantasy.',
      name: 'quickDraftGuideSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Full Draft Guide`
  String get fullDraftGuide {
    return Intl.message(
      'Full Draft Guide',
      name: 'fullDraftGuide',
      desc: '',
      args: [],
    );
  }

  /// `Draft vs Classic`
  String get draftVsClassic {
    return Intl.message(
      'Draft vs Classic',
      name: 'draftVsClassic',
      desc: '',
      args: [],
    );
  }

  /// `Join Draft Now`
  String get joinDraftNow {
    return Intl.message(
      'Join Draft Now',
      name: 'joinDraftNow',
      desc: '',
      args: [],
    );
  }

  /// `Draft Room Opens 15 Min Before Start`
  String get draftRoomOpens15MinBeforeStart {
    return Intl.message(
      'Draft Room Opens 15 Min Before Start',
      name: 'draftRoomOpens15MinBeforeStart',
      desc: '',
      args: [],
    );
  }

  /// `No members yet`
  String get noMembersYet {
    return Intl.message(
      'No members yet',
      name: 'noMembersYet',
      desc: '',
      args: [],
    );
  }

  /// `League Full`
  String get leagueFull {
    return Intl.message('League Full', name: 'leagueFull', desc: '', args: []);
  }

  /// `Join League`
  String get joinLeague {
    return Intl.message('Join League', name: 'joinLeague', desc: '', args: []);
  }

  /// `Trades`
  String get trades {
    return Intl.message('Trades', name: 'trades', desc: '', args: []);
  }

  /// `Free Agency`
  String get freeAgency {
    return Intl.message('Free Agency', name: 'freeAgency', desc: '', args: []);
  }

  /// `Enter Draft Room`
  String get enterDraftRoom {
    return Intl.message(
      'Enter Draft Room',
      name: 'enterDraftRoom',
      desc: '',
      args: [],
    );
  }

  /// `Edit Team`
  String get editTeam {
    return Intl.message('Edit Team', name: 'editTeam', desc: '', args: []);
  }

  /// `Build Team`
  String get buildTeam {
    return Intl.message('Build Team', name: 'buildTeam', desc: '', args: []);
  }

  /// `Name Your Team`
  String get nameYourTeam {
    return Intl.message(
      'Name Your Team',
      name: 'nameYourTeam',
      desc: '',
      args: [],
    );
  }

  /// `Choose a name for your fantasy team:`
  String get chooseTeamNamePrompt {
    return Intl.message(
      'Choose a name for your fantasy team:',
      name: 'chooseTeamNamePrompt',
      desc: '',
      args: [],
    );
  }

  /// `Leave League?`
  String get leaveLeagueQuestion {
    return Intl.message(
      'Leave League?',
      name: 'leaveLeagueQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Leave`
  String get leaveLabel {
    return Intl.message('Leave', name: 'leaveLabel', desc: '', args: []);
  }

  /// `You have left the league`
  String get leftLeagueMessage {
    return Intl.message(
      'You have left the league',
      name: 'leftLeagueMessage',
      desc: '',
      args: [],
    );
  }

  /// `Invite code copied!`
  String get inviteCodeCopied {
    return Intl.message(
      'Invite code copied!',
      name: 'inviteCodeCopied',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message('Share', name: 'share', desc: '', args: []);
  }

  /// `Copy Code`
  String get copyCode {
    return Intl.message('Copy Code', name: 'copyCode', desc: '', args: []);
  }

  /// `Draft Schedule`
  String get draftSchedule {
    return Intl.message(
      'Draft Schedule',
      name: 'draftSchedule',
      desc: '',
      args: [],
    );
  }

  /// `Time pending`
  String get timePending {
    return Intl.message(
      'Time pending',
      name: 'timePending',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load leagues: {error}`
  String failedToLoadLeagues(String error) {
    return Intl.message(
      'Failed to load leagues: $error',
      name: 'failedToLoadLeagues',
      desc: '',
      args: [error],
    );
  }

  /// `paroNfantasyMx Leagues`
  String get leaguesTitle {
    return Intl.message(
      'paroNfantasyMx Leagues',
      name: 'leaguesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Join with code`
  String get joinWithCode {
    return Intl.message(
      'Join with code',
      name: 'joinWithCode',
      desc: '',
      args: [],
    );
  }

  /// `Public Leagues`
  String get publicLeagues {
    return Intl.message(
      'Public Leagues',
      name: 'publicLeagues',
      desc: '',
      args: [],
    );
  }

  /// `Create League`
  String get createLeagueLabel {
    return Intl.message(
      'Create League',
      name: 'createLeagueLabel',
      desc: '',
      args: [],
    );
  }

  /// `No Public Leagues Available`
  String get noPublicLeaguesAvailable {
    return Intl.message(
      'No Public Leagues Available',
      name: 'noPublicLeaguesAvailable',
      desc: '',
      args: [],
    );
  }

  /// `No Leagues Yet`
  String get noLeaguesYet {
    return Intl.message(
      'No Leagues Yet',
      name: 'noLeaguesYet',
      desc: '',
      args: [],
    );
  }

  /// `Create a public league or wait for others to create one`
  String get createPublicLeagueOrWait {
    return Intl.message(
      'Create a public league or wait for others to create one',
      name: 'createPublicLeagueOrWait',
      desc: '',
      args: [],
    );
  }

  /// `Create your first league or join an existing one`
  String get createOrJoinFirstLeague {
    return Intl.message(
      'Create your first league or join an existing one',
      name: 'createOrJoinFirstLeague',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message('Create', name: 'create', desc: '', args: []);
  }

  /// `Join`
  String get join {
    return Intl.message('Join', name: 'join', desc: '', args: []);
  }

  /// `{current}/{max} members`
  String membersCount(int current, int max) {
    return Intl.message(
      '$current/$max members',
      name: 'membersCount',
      desc: '',
      args: [current, max],
    );
  }

  /// `Match TBD`
  String get matchTbd {
    return Intl.message('Match TBD', name: 'matchTbd', desc: '', args: []);
  }

  /// `View →`
  String get viewArrow {
    return Intl.message('View →', name: 'viewArrow', desc: '', args: []);
  }

  /// `Join →`
  String get joinArrow {
    return Intl.message('Join →', name: 'joinArrow', desc: '', args: []);
  }

  /// `Full`
  String get full {
    return Intl.message('Full', name: 'full', desc: '', args: []);
  }

  /// `Started`
  String get started {
    return Intl.message('Started', name: 'started', desc: '', args: []);
  }

  /// `{minutes}m`
  String minutesShort(int minutes) {
    return Intl.message(
      '${minutes}m',
      name: 'minutesShort',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours}h {minutes}m`
  String hoursMinutesShort(int hours, int minutes) {
    return Intl.message(
      '${hours}h ${minutes}m',
      name: 'hoursMinutesShort',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `Tomorrow`
  String get tomorrow {
    return Intl.message('Tomorrow', name: 'tomorrow', desc: '', args: []);
  }

  /// `{days}d`
  String daysShort(int days) {
    return Intl.message('${days}d', name: 'daysShort', desc: '', args: [days]);
  }

  /// `Cancelled`
  String get cancelled {
    return Intl.message('Cancelled', name: 'cancelled', desc: '', args: []);
  }

  /// `Please set a draft date and time`
  String get pleaseSetDraftDateAndTime {
    return Intl.message(
      'Please set a draft date and time',
      name: 'pleaseSetDraftDateAndTime',
      desc: '',
      args: [],
    );
  }

  /// `League "{name}" created!`
  String leagueCreated(String name) {
    return Intl.message(
      'League "$name" created!',
      name: 'leagueCreated',
      desc: '',
      args: [name],
    );
  }

  /// `Failed to create league: {error}`
  String failedToCreateLeague(String error) {
    return Intl.message(
      'Failed to create league: $error',
      name: 'failedToCreateLeague',
      desc: '',
      args: [error],
    );
  }

  /// `League Mode`
  String get leagueMode {
    return Intl.message('League Mode', name: 'leagueMode', desc: '', args: []);
  }

  /// `Classic`
  String get classic {
    return Intl.message('Classic', name: 'classic', desc: '', args: []);
  }

  /// `Budget-based`
  String get budgetBased {
    return Intl.message(
      'Budget-based',
      name: 'budgetBased',
      desc: '',
      args: [],
    );
  }

  /// `Draft`
  String get draft {
    return Intl.message('Draft', name: 'draft', desc: '', args: []);
  }

  /// `Unique ownership`
  String get uniqueOwnership {
    return Intl.message(
      'Unique ownership',
      name: 'uniqueOwnership',
      desc: '',
      args: [],
    );
  }

  /// `League Visibility`
  String get leagueVisibility {
    return Intl.message(
      'League Visibility',
      name: 'leagueVisibility',
      desc: '',
      args: [],
    );
  }

  /// `Public`
  String get publicLeague {
    return Intl.message('Public', name: 'publicLeague', desc: '', args: []);
  }

  /// `Anyone can join`
  String get anyoneCanJoin {
    return Intl.message(
      'Anyone can join',
      name: 'anyoneCanJoin',
      desc: '',
      args: [],
    );
  }

  /// `Private`
  String get privateLeague {
    return Intl.message('Private', name: 'privateLeague', desc: '', args: []);
  }

  /// `Invite only`
  String get inviteOnly {
    return Intl.message('Invite only', name: 'inviteOnly', desc: '', args: []);
  }

  /// `League Details`
  String get leagueDetails {
    return Intl.message(
      'League Details',
      name: 'leagueDetails',
      desc: '',
      args: [],
    );
  }

  /// `League Name`
  String get leagueName {
    return Intl.message('League Name', name: 'leagueName', desc: '', args: []);
  }

  /// `Enter a name for your league`
  String get enterLeagueName {
    return Intl.message(
      'Enter a name for your league',
      name: 'enterLeagueName',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a league name`
  String get pleaseEnterLeagueName {
    return Intl.message(
      'Please enter a league name',
      name: 'pleaseEnterLeagueName',
      desc: '',
      args: [],
    );
  }

  /// `Name must be at least 3 characters`
  String get nameMustBeAtLeast3Characters {
    return Intl.message(
      'Name must be at least 3 characters',
      name: 'nameMustBeAtLeast3Characters',
      desc: '',
      args: [],
    );
  }

  /// `Description (Optional)`
  String get descriptionOptional {
    return Intl.message(
      'Description (Optional)',
      name: 'descriptionOptional',
      desc: '',
      args: [],
    );
  }

  /// `Describe your league`
  String get describeYourLeague {
    return Intl.message(
      'Describe your league',
      name: 'describeYourLeague',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Max Members`
  String get maxMembers {
    return Intl.message('Max Members', name: 'maxMembers', desc: '', args: []);
  }

  /// `2-20`
  String get range2to20 {
    return Intl.message('2-20', name: 'range2to20', desc: '', args: []);
  }

  /// `Roster Size`
  String get rosterSize {
    return Intl.message('Roster Size', name: 'rosterSize', desc: '', args: []);
  }

  /// `11-25`
  String get range11to25 {
    return Intl.message('11-25', name: 'range11to25', desc: '', args: []);
  }

  /// `Team Budget`
  String get teamBudget {
    return Intl.message('Team Budget', name: 'teamBudget', desc: '', args: []);
  }

  /// `Million USD`
  String get millionUsd {
    return Intl.message('Million USD', name: 'millionUsd', desc: '', args: []);
  }

  /// `50-1000`
  String get range50to1000 {
    return Intl.message('50-1000', name: 'range50to1000', desc: '', args: []);
  }

  /// `Draft Settings`
  String get draftSettings {
    return Intl.message(
      'Draft Settings',
      name: 'draftSettings',
      desc: '',
      args: [],
    );
  }

  /// `Draft Date & Time`
  String get draftDateTime {
    return Intl.message(
      'Draft Date & Time',
      name: 'draftDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Tap to select`
  String get tapToSelect {
    return Intl.message(
      'Tap to select',
      name: 'tapToSelect',
      desc: '',
      args: [],
    );
  }

  /// `Snake`
  String get snake {
    return Intl.message('Snake', name: 'snake', desc: '', args: []);
  }

  /// `1→10, 10→1...`
  String get snakeOrderExample {
    return Intl.message(
      '1→10, 10→1...',
      name: 'snakeOrderExample',
      desc: '',
      args: [],
    );
  }

  /// `Linear`
  String get linear {
    return Intl.message('Linear', name: 'linear', desc: '', args: []);
  }

  /// `Same order`
  String get sameOrder {
    return Intl.message('Same order', name: 'sameOrder', desc: '', args: []);
  }

  /// `Pick Timer`
  String get pickTimer {
    return Intl.message('Pick Timer', name: 'pickTimer', desc: '', args: []);
  }

  /// `Trade Settings`
  String get tradeSettings {
    return Intl.message(
      'Trade Settings',
      name: 'tradeSettings',
      desc: '',
      args: [],
    );
  }

  /// `Trade Approval`
  String get tradeApprovalTitle {
    return Intl.message(
      'Trade Approval',
      name: 'tradeApprovalTitle',
      desc: '',
      args: [],
    );
  }

  /// `Trade Deadline (Optional)`
  String get tradeDeadlineOptional {
    return Intl.message(
      'Trade Deadline (Optional)',
      name: 'tradeDeadlineOptional',
      desc: '',
      args: [],
    );
  }

  /// `No deadline`
  String get noDeadline {
    return Intl.message('No deadline', name: 'noDeadline', desc: '', args: []);
  }

  /// `How Classic Mode Works`
  String get howClassicModeWorks {
    return Intl.message(
      'How Classic Mode Works',
      name: 'howClassicModeWorks',
      desc: '',
      args: [],
    );
  }

  /// `How Draft Mode Works`
  String get howDraftModeWorks {
    return Intl.message(
      'How Draft Mode Works',
      name: 'howDraftModeWorks',
      desc: '',
      args: [],
    );
  }

  /// `Create your league and invite friends`
  String get classicInfoCreateInvite {
    return Intl.message(
      'Create your league and invite friends',
      name: 'classicInfoCreateInvite',
      desc: '',
      args: [],
    );
  }

  /// `Each member builds a team within the budget`
  String get classicInfoBudgetTeam {
    return Intl.message(
      'Each member builds a team within the budget',
      name: 'classicInfoBudgetTeam',
      desc: '',
      args: [],
    );
  }

  /// `Multiple managers can have the same players`
  String get classicInfoSamePlayersAllowed {
    return Intl.message(
      'Multiple managers can have the same players',
      name: 'classicInfoSamePlayersAllowed',
      desc: '',
      args: [],
    );
  }

  /// `Earn points based on real player performance`
  String get classicInfoEarnPoints {
    return Intl.message(
      'Earn points based on real player performance',
      name: 'classicInfoEarnPoints',
      desc: '',
      args: [],
    );
  }

  /// `Set up your league and schedule the draft`
  String get draftInfoScheduleDraft {
    return Intl.message(
      'Set up your league and schedule the draft',
      name: 'draftInfoScheduleDraft',
      desc: '',
      args: [],
    );
  }

  /// `On draft day, take turns picking players`
  String get draftInfoTakeTurns {
    return Intl.message(
      'On draft day, take turns picking players',
      name: 'draftInfoTakeTurns',
      desc: '',
      args: [],
    );
  }

  /// `Each player can only be owned by one team`
  String get draftInfoUniquePlayers {
    return Intl.message(
      'Each player can only be owned by one team',
      name: 'draftInfoUniquePlayers',
      desc: '',
      args: [],
    );
  }

  /// `Trade players and pick up free agents during the season`
  String get draftInfoTradesAndFreeAgency {
    return Intl.message(
      'Trade players and pick up free agents during the season',
      name: 'draftInfoTradesAndFreeAgency',
      desc: '',
      args: [],
    );
  }

  /// `Compete for the championship!`
  String get draftInfoCompeteChampionship {
    return Intl.message(
      'Compete for the championship!',
      name: 'draftInfoCompeteChampionship',
      desc: '',
      args: [],
    );
  }

  /// `Share the invite code with friends to join`
  String get shareInviteCodeWithFriends {
    return Intl.message(
      'Share the invite code with friends to join',
      name: 'shareInviteCodeWithFriends',
      desc: '',
      args: [],
    );
  }

  /// `No Approval`
  String get tradeApprovalNone {
    return Intl.message(
      'No Approval',
      name: 'tradeApprovalNone',
      desc: '',
      args: [],
    );
  }

  /// `Commissioner Approval`
  String get tradeApprovalCommissioner {
    return Intl.message(
      'Commissioner Approval',
      name: 'tradeApprovalCommissioner',
      desc: '',
      args: [],
    );
  }

  /// `League Vote`
  String get tradeApprovalLeagueVote {
    return Intl.message(
      'League Vote',
      name: 'tradeApprovalLeagueVote',
      desc: '',
      args: [],
    );
  }

  /// `Trades are processed immediately`
  String get tradeApprovalNoneDescription {
    return Intl.message(
      'Trades are processed immediately',
      name: 'tradeApprovalNoneDescription',
      desc: '',
      args: [],
    );
  }

  /// `Commissioner must approve all trades`
  String get tradeApprovalCommissionerDescription {
    return Intl.message(
      'Commissioner must approve all trades',
      name: 'tradeApprovalCommissionerDescription',
      desc: '',
      args: [],
    );
  }

  /// `League members vote on trades (majority wins)`
  String get tradeApprovalLeagueVoteDescription {
    return Intl.message(
      'League members vote on trades (majority wins)',
      name: 'tradeApprovalLeagueVoteDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid invite code`
  String get enterValidInviteCode {
    return Intl.message(
      'Enter a valid invite code',
      name: 'enterValidInviteCode',
      desc: '',
      args: [],
    );
  }

  /// `League not found. Check the invite code.`
  String get leagueNotFoundCheckInviteCode {
    return Intl.message(
      'League not found. Check the invite code.',
      name: 'leagueNotFoundCheckInviteCode',
      desc: '',
      args: [],
    );
  }

  /// `This league is full`
  String get thisLeagueIsFull {
    return Intl.message(
      'This league is full',
      name: 'thisLeagueIsFull',
      desc: '',
      args: [],
    );
  }

  /// `This league is no longer accepting members`
  String get leagueNoLongerAcceptingMembers {
    return Intl.message(
      'This league is no longer accepting members',
      name: 'leagueNoLongerAcceptingMembers',
      desc: '',
      args: [],
    );
  }

  /// `Error searching for league`
  String get errorSearchingForLeague {
    return Intl.message(
      'Error searching for league',
      name: 'errorSearchingForLeague',
      desc: '',
      args: [],
    );
  }

  /// `Failed to join league`
  String get failedToJoinLeague {
    return Intl.message(
      'Failed to join league',
      name: 'failedToJoinLeague',
      desc: '',
      args: [],
    );
  }

  /// `Error joining league: {error}`
  String errorJoiningLeague(String error) {
    return Intl.message(
      'Error joining league: $error',
      name: 'errorJoiningLeague',
      desc: '',
      args: [error],
    );
  }

  /// `Join Private League`
  String get joinPrivateLeague {
    return Intl.message(
      'Join Private League',
      name: 'joinPrivateLeague',
      desc: '',
      args: [],
    );
  }

  /// `Enter the invite code shared by your friend to join their private league.`
  String get joinPrivateLeagueDescription {
    return Intl.message(
      'Enter the invite code shared by your friend to join their private league.',
      name: 'joinPrivateLeagueDescription',
      desc: '',
      args: [],
    );
  }

  /// `Invite Code`
  String get inviteCode {
    return Intl.message('Invite Code', name: 'inviteCode', desc: '', args: []);
  }

  /// `Searching...`
  String get searching {
    return Intl.message('Searching...', name: 'searching', desc: '', args: []);
  }

  /// `Find League`
  String get findLeague {
    return Intl.message('Find League', name: 'findLeague', desc: '', args: []);
  }

  /// `League Found!`
  String get leagueFound {
    return Intl.message(
      'League Found!',
      name: 'leagueFound',
      desc: '',
      args: [],
    );
  }

  /// `Available`
  String get availableTab {
    return Intl.message('Available', name: 'availableTab', desc: '', args: []);
  }

  /// `My Roster`
  String get myRosterTab {
    return Intl.message('My Roster', name: 'myRosterTab', desc: '', args: []);
  }

  /// `Transactions`
  String get transactionsTab {
    return Intl.message(
      'Transactions',
      name: 'transactionsTab',
      desc: '',
      args: [],
    );
  }

  /// `Roster: {current} / {max}`
  String rosterCount(int current, int max) {
    return Intl.message(
      'Roster: $current / $max',
      name: 'rosterCount',
      desc: '',
      args: [current, max],
    );
  }

  /// `Roster Full - Drop a player to add`
  String get rosterFullDropPlayerToAdd {
    return Intl.message(
      'Roster Full - Drop a player to add',
      name: 'rosterFullDropPlayerToAdd',
      desc: '',
      args: [],
    );
  }

  /// `{count} spots available`
  String spotsAvailable(int count) {
    return Intl.message(
      '$count spots available',
      name: 'spotsAvailable',
      desc: '',
      args: [count],
    );
  }

  /// `Search players...`
  String get searchPlayersHintShort {
    return Intl.message(
      'Search players...',
      name: 'searchPlayersHintShort',
      desc: '',
      args: [],
    );
  }

  /// `{value} next`
  String pointsNext(String value) {
    return Intl.message(
      '$value next',
      name: 'pointsNext',
      desc: '',
      args: [value],
    );
  }

  /// `{value} season`
  String pointsSeason(String value) {
    return Intl.message(
      '$value season',
      name: 'pointsSeason',
      desc: '',
      args: [value],
    );
  }

  /// `projection`
  String get projectionLabel {
    return Intl.message(
      'projection',
      name: 'projectionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get addPlayerAction {
    return Intl.message('Add', name: 'addPlayerAction', desc: '', args: []);
  }

  /// `Swap`
  String get swapAction {
    return Intl.message('Swap', name: 'swapAction', desc: '', args: []);
  }

  /// `No players on roster`
  String get noPlayersOnRoster {
    return Intl.message(
      'No players on roster',
      name: 'noPlayersOnRoster',
      desc: '',
      args: [],
    );
  }

  /// `Add players from the Available tab`
  String get addPlayersFromAvailableTab {
    return Intl.message(
      'Add players from the Available tab',
      name: 'addPlayersFromAvailableTab',
      desc: '',
      args: [],
    );
  }

  /// `Drop player`
  String get dropPlayerTooltip {
    return Intl.message(
      'Drop player',
      name: 'dropPlayerTooltip',
      desc: '',
      args: [],
    );
  }

  /// `No transactions yet`
  String get noTransactionsYet {
    return Intl.message(
      'No transactions yet',
      name: 'noTransactionsYet',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get youLabel {
    return Intl.message('You', name: 'youLabel', desc: '', args: []);
  }

  /// `Roster is full. Swap or drop a player first.`
  String get rosterIsFullSwapOrDropFirst {
    return Intl.message(
      'Roster is full. Swap or drop a player first.',
      name: 'rosterIsFullSwapOrDropFirst',
      desc: '',
      args: [],
    );
  }

  /// `Player is already on your roster`
  String get playerAlreadyOnRoster {
    return Intl.message(
      'Player is already on your roster',
      name: 'playerAlreadyOnRoster',
      desc: '',
      args: [],
    );
  }

  /// `Cannot add player - fixture has already started`
  String get cannotAddPlayerFixtureStarted {
    return Intl.message(
      'Cannot add player - fixture has already started',
      name: 'cannotAddPlayerFixtureStarted',
      desc: '',
      args: [],
    );
  }

  /// `Added {name}`
  String addedPlayer(String name) {
    return Intl.message(
      'Added $name',
      name: 'addedPlayer',
      desc: '',
      args: [name],
    );
  }

  /// `Added locally, but failed to persist roster update`
  String get addedLocallyPersistFailed {
    return Intl.message(
      'Added locally, but failed to persist roster update',
      name: 'addedLocallyPersistFailed',
      desc: '',
      args: [],
    );
  }

  /// `Select player to drop`
  String get selectPlayerToDrop {
    return Intl.message(
      'Select player to drop',
      name: 'selectPlayerToDrop',
      desc: '',
      args: [],
    );
  }

  /// `Cannot swap: drop player is not on your roster`
  String get cannotSwapDropPlayerNotOnRoster {
    return Intl.message(
      'Cannot swap: drop player is not on your roster',
      name: 'cannotSwapDropPlayerNotOnRoster',
      desc: '',
      args: [],
    );
  }

  /// `Swapped {dropPlayer} for {addPlayer}`
  String swappedPlayers(String dropPlayer, String addPlayer) {
    return Intl.message(
      'Swapped $dropPlayer for $addPlayer',
      name: 'swappedPlayers',
      desc: '',
      args: [dropPlayer, addPlayer],
    );
  }

  /// `Swap completed locally, but failed to persist roster update`
  String get swapCompletedLocallyPersistFailed {
    return Intl.message(
      'Swap completed locally, but failed to persist roster update',
      name: 'swapCompletedLocallyPersistFailed',
      desc: '',
      args: [],
    );
  }

  /// `Failed to complete swap`
  String get failedToCompleteSwap {
    return Intl.message(
      'Failed to complete swap',
      name: 'failedToCompleteSwap',
      desc: '',
      args: [],
    );
  }

  /// `Drop Player?`
  String get dropPlayerQuestion {
    return Intl.message(
      'Drop Player?',
      name: 'dropPlayerQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to drop {name}? They will become available to other teams.`
  String dropPlayerConfirmation(String name) {
    return Intl.message(
      'Are you sure you want to drop $name? They will become available to other teams.',
      name: 'dropPlayerConfirmation',
      desc: '',
      args: [name],
    );
  }

  /// `Drop`
  String get dropAction {
    return Intl.message('Drop', name: 'dropAction', desc: '', args: []);
  }

  /// `Player is not on your saved roster`
  String get playerNotOnSavedRoster {
    return Intl.message(
      'Player is not on your saved roster',
      name: 'playerNotOnSavedRoster',
      desc: '',
      args: [],
    );
  }

  /// `Dropped {name}`
  String droppedPlayer(String name) {
    return Intl.message(
      'Dropped $name',
      name: 'droppedPlayer',
      desc: '',
      args: [name],
    );
  }

  /// `Dropped locally, but failed to persist roster update`
  String get droppedLocallyPersistFailed {
    return Intl.message(
      'Dropped locally, but failed to persist roster update',
      name: 'droppedLocallyPersistFailed',
      desc: '',
      args: [],
    );
  }

  /// `Season`
  String get seasonLabel {
    return Intl.message('Season', name: 'seasonLabel', desc: '', args: []);
  }

  /// `Price`
  String get priceLabel {
    return Intl.message('Price', name: 'priceLabel', desc: '', args: []);
  }

  /// `Add to Roster`
  String get addToRoster {
    return Intl.message(
      'Add to Roster',
      name: 'addToRoster',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get allLabel {
    return Intl.message('All', name: 'allLabel', desc: '', args: []);
  }

  /// `Inbox`
  String get inboxTab {
    return Intl.message('Inbox', name: 'inboxTab', desc: '', args: []);
  }

  /// `Propose`
  String get proposeTab {
    return Intl.message('Propose', name: 'proposeTab', desc: '', args: []);
  }

  /// `History`
  String get historyTab {
    return Intl.message('History', name: 'historyTab', desc: '', args: []);
  }

  /// `Trade deadline has passed`
  String get tradeDeadlineHasPassed {
    return Intl.message(
      'Trade deadline has passed',
      name: 'tradeDeadlineHasPassed',
      desc: '',
      args: [],
    );
  }

  /// `Trade deadline: {date}`
  String tradeDeadline(String date) {
    return Intl.message(
      'Trade deadline: $date',
      name: 'tradeDeadline',
      desc: '',
      args: [date],
    );
  }

  /// `No pending trades`
  String get noPendingTrades {
    return Intl.message(
      'No pending trades',
      name: 'noPendingTrades',
      desc: '',
      args: [],
    );
  }

  /// `Propose a trade to get started`
  String get proposeTradeToGetStarted {
    return Intl.message(
      'Propose a trade to get started',
      name: 'proposeTradeToGetStarted',
      desc: '',
      args: [],
    );
  }

  /// `Incoming Trades`
  String get incomingTrades {
    return Intl.message(
      'Incoming Trades',
      name: 'incomingTrades',
      desc: '',
      args: [],
    );
  }

  /// `Outgoing Trades`
  String get outgoingTrades {
    return Intl.message(
      'Outgoing Trades',
      name: 'outgoingTrades',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting League Vote`
  String get awaitingLeagueVote {
    return Intl.message(
      'Awaiting League Vote',
      name: 'awaitingLeagueVote',
      desc: '',
      args: [],
    );
  }

  /// `From: {name}`
  String fromUser(String name) {
    return Intl.message(
      'From: $name',
      name: 'fromUser',
      desc: '',
      args: [name],
    );
  }

  /// `To: {name}`
  String toUser(String name) {
    return Intl.message('To: $name', name: 'toUser', desc: '', args: [name]);
  }

  /// `You receive:`
  String get youReceive {
    return Intl.message('You receive:', name: 'youReceive', desc: '', args: []);
  }

  /// `You give:`
  String get youGive {
    return Intl.message('You give:', name: 'youGive', desc: '', args: []);
  }

  /// `Reject`
  String get rejectAction {
    return Intl.message('Reject', name: 'rejectAction', desc: '', args: []);
  }

  /// `Accept`
  String get acceptAction {
    return Intl.message('Accept', name: 'acceptAction', desc: '', args: []);
  }

  /// `Cancel Trade`
  String get cancelTradeAction {
    return Intl.message(
      'Cancel Trade',
      name: 'cancelTradeAction',
      desc: '',
      args: [],
    );
  }

  /// `League Vote`
  String get leagueVoteTitle {
    return Intl.message(
      'League Vote',
      name: 'leagueVoteTitle',
      desc: '',
      args: [],
    );
  }

  /// `For`
  String get voteFor {
    return Intl.message('For', name: 'voteFor', desc: '', args: []);
  }

  /// `Against`
  String get voteAgainst {
    return Intl.message('Against', name: 'voteAgainst', desc: '', args: []);
  }

  /// `Vote Against`
  String get voteAgainstAction {
    return Intl.message(
      'Vote Against',
      name: 'voteAgainstAction',
      desc: '',
      args: [],
    );
  }

  /// `Vote For`
  String get voteForAction {
    return Intl.message('Vote For', name: 'voteForAction', desc: '', args: []);
  }

  /// `You cannot vote on your own trade`
  String get youCannotVoteOwnTrade {
    return Intl.message(
      'You cannot vote on your own trade',
      name: 'youCannotVoteOwnTrade',
      desc: '',
      args: [],
    );
  }

  /// `You have already voted`
  String get youAlreadyVoted {
    return Intl.message(
      'You have already voted',
      name: 'youAlreadyVoted',
      desc: '',
      args: [],
    );
  }

  /// `Trading is closed`
  String get tradingClosed {
    return Intl.message(
      'Trading is closed',
      name: 'tradingClosed',
      desc: '',
      args: [],
    );
  }

  /// `Find a player to target`
  String get findPlayerToTarget {
    return Intl.message(
      'Find a player to target',
      name: 'findPlayerToTarget',
      desc: '',
      args: [],
    );
  }

  /// `Search players in other squads...`
  String get searchPlayersInOtherSquads {
    return Intl.message(
      'Search players in other squads...',
      name: 'searchPlayersInOtherSquads',
      desc: '',
      args: [],
    );
  }

  /// `Choose one of your players to offer:`
  String get chooseOnePlayerToOffer {
    return Intl.message(
      'Choose one of your players to offer:',
      name: 'chooseOnePlayerToOffer',
      desc: '',
      args: [],
    );
  }

  /// `Message (optional)`
  String get messageOptional {
    return Intl.message(
      'Message (optional)',
      name: 'messageOptional',
      desc: '',
      args: [],
    );
  }

  /// `Propose Trade`
  String get proposeTradeAction {
    return Intl.message(
      'Propose Trade',
      name: 'proposeTradeAction',
      desc: '',
      args: [],
    );
  }

  /// `No trade targets found`
  String get noTradeTargetsFound {
    return Intl.message(
      'No trade targets found',
      name: 'noTradeTargetsFound',
      desc: '',
      args: [],
    );
  }

  /// `{team} • Owned by {owner} • {points} next`
  String tradeTargetSubtitle(String team, String owner, String points) {
    return Intl.message(
      '$team • Owned by $owner • $points next',
      name: 'tradeTargetSubtitle',
      desc: '',
      args: [team, owner, points],
    );
  }

  /// `Owned by {owner}`
  String ownedBy(String owner) {
    return Intl.message(
      'Owned by $owner',
      name: 'ownedBy',
      desc: '',
      args: [owner],
    );
  }

  /// `{points} next • {team}`
  String requestedPlayerSummary(String points, String team) {
    return Intl.message(
      '$points next • $team',
      name: 'requestedPlayerSummary',
      desc: '',
      args: [points, team],
    );
  }

  /// `No trade history`
  String get noTradeHistory {
    return Intl.message(
      'No trade history',
      name: 'noTradeHistory',
      desc: '',
      args: [],
    );
  }

  /// `Trade proposed successfully`
  String get tradeProposedSuccessfully {
    return Intl.message(
      'Trade proposed successfully',
      name: 'tradeProposedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Trade accepted`
  String get tradeAccepted {
    return Intl.message(
      'Trade accepted',
      name: 'tradeAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Trade rejected`
  String get tradeRejected {
    return Intl.message(
      'Trade rejected',
      name: 'tradeRejected',
      desc: '',
      args: [],
    );
  }

  /// `Trade cancelled`
  String get tradeCancelled {
    return Intl.message(
      'Trade cancelled',
      name: 'tradeCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Vote recorded: {side}`
  String voteRecorded(String side) {
    return Intl.message(
      'Vote recorded: $side',
      name: 'voteRecorded',
      desc: '',
      args: [side],
    );
  }

  /// `Pending`
  String get tradeStatusPending {
    return Intl.message(
      'Pending',
      name: 'tradeStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get tradeStatusAccepted {
    return Intl.message(
      'Accepted',
      name: 'tradeStatusAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get tradeStatusCompleted {
    return Intl.message(
      'Completed',
      name: 'tradeStatusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Rejected`
  String get tradeStatusRejected {
    return Intl.message(
      'Rejected',
      name: 'tradeStatusRejected',
      desc: '',
      args: [],
    );
  }

  /// `Vetoed`
  String get tradeStatusVetoed {
    return Intl.message(
      'Vetoed',
      name: 'tradeStatusVetoed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get tradeStatusCancelled {
    return Intl.message(
      'Cancelled',
      name: 'tradeStatusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get tradeStatusExpired {
    return Intl.message(
      'Expired',
      name: 'tradeStatusExpired',
      desc: '',
      args: [],
    );
  }

  /// `Need midfield creativity. Interested in a direct swap?`
  String get seedTradeMessage1 {
    return Intl.message(
      'Need midfield creativity. Interested in a direct swap?',
      name: 'seedTradeMessage1',
      desc: '',
      args: [],
    );
  }

  /// `I can overpay at MID if you can spare defensive depth.`
  String get seedTradeMessage2 {
    return Intl.message(
      'I can overpay at MID if you can spare defensive depth.',
      name: 'seedTradeMessage2',
      desc: '',
      args: [],
    );
  }

  /// `Recommended budget: 130-150M for a balanced 18-player squad.`
  String get classicBudgetRecommendation {
    return Intl.message(
      'Recommended budget: 130-150M for a balanced 18-player squad.',
      name: 'classicBudgetRecommendation',
      desc: '',
      args: [],
    );
  }

  /// `Joined successfully. Team creation opens on {time}.`
  String joinedSuccessfullyTeamCreationOpensOn(String time) {
    return Intl.message(
      'Joined successfully. Team creation opens on $time.',
      name: 'joinedSuccessfullyTeamCreationOpensOn',
      desc: '',
      args: [time],
    );
  }

  /// `Joined successfully. Team creation opens on draft day.`
  String get joinedSuccessfullyTeamCreationOnDraftDay {
    return Intl.message(
      'Joined successfully. Team creation opens on draft day.',
      name: 'joinedSuccessfullyTeamCreationOnDraftDay',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to the league! Your team "{teamName}" is ready.`
  String welcomeToLeagueTeamReady(String teamName) {
    return Intl.message(
      'Welcome to the league! Your team "$teamName" is ready.',
      name: 'welcomeToLeagueTeamReady',
      desc: '',
      args: [teamName],
    );
  }

  /// `e.g., Los Galacticos FC`
  String get teamNameExampleHint {
    return Intl.message(
      'e.g., Los Galacticos FC',
      name: 'teamNameExampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to leave this league? Your team will be deleted.`
  String get leaveLeagueConfirmation {
    return Intl.message(
      'Are you sure you want to leave this league? Your team will be deleted.',
      name: 'leaveLeagueConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Join {leagueName} on Fantasy 11!`
  String joinLeagueOnFantasy11(String leagueName) {
    return Intl.message(
      'Join $leagueName on Fantasy 11!',
      name: 'joinLeagueOnFantasy11',
      desc: '',
      args: [leagueName],
    );
  }

  /// `Share invite`
  String get shareInvite {
    return Intl.message(
      'Share invite',
      name: 'shareInvite',
      desc: '',
      args: [],
    );
  }

  /// `Budget`
  String get budgetLabel {
    return Intl.message('Budget', name: 'budgetLabel', desc: '', args: []);
  }

  /// `Select 18 players (11 starters + 7 subs) through the live draft`
  String get ruleSelect18PlayersDraft {
    return Intl.message(
      'Select 18 players (11 starters + 7 subs) through the live draft',
      name: 'ruleSelect18PlayersDraft',
      desc: '',
      args: [],
    );
  }

  /// `Select 18 players (11 starters + 7 subs) within \${budget}M`
  String ruleSelect18PlayersBudget(int budget) {
    return Intl.message(
      'Select 18 players (11 starters + 7 subs) within \\\$${budget}M',
      name: 'ruleSelect18PlayersBudget',
      desc: '',
      args: [budget],
    );
  }

  /// `Squad: 18 total players`
  String get ruleSquad18Players {
    return Intl.message(
      'Squad: 18 total players',
      name: 'ruleSquad18Players',
      desc: '',
      args: [],
    );
  }

  /// `Captain gets 2x points, Vice-captain gets 1.5x`
  String get ruleCaptainViceCaptainPoints {
    return Intl.message(
      'Captain gets 2x points, Vice-captain gets 1.5x',
      name: 'ruleCaptainViceCaptainPoints',
      desc: '',
      args: [],
    );
  }

  /// `Max 4 players from one team`
  String get ruleMax4PlayersOneTeam {
    return Intl.message(
      'Max 4 players from one team',
      name: 'ruleMax4PlayersOneTeam',
      desc: '',
      args: [],
    );
  }

  /// `Team locks when match starts`
  String get ruleTeamLocksWhenMatchStarts {
    return Intl.message(
      'Team locks when match starts',
      name: 'ruleTeamLocksWhenMatchStarts',
      desc: '',
      args: [],
    );
  }

  /// `Each manager takes turns selecting one player at a time. Once a player is drafted, nobody else can roster him.`
  String get draftGuideBullet1 {
    return Intl.message(
      'Each manager takes turns selecting one player at a time. Once a player is drafted, nobody else can roster him.',
      name: 'draftGuideBullet1',
      desc: '',
      args: [],
    );
  }

  /// `There is no transfer budget during the draft. Your advantage comes from pick timing, queue priority, and roster balance.`
  String get draftGuideBullet2 {
    return Intl.message(
      'There is no transfer budget during the draft. Your advantage comes from pick timing, queue priority, and roster balance.',
      name: 'draftGuideBullet2',
      desc: '',
      args: [],
    );
  }

  /// `Auto-pick can step in if your clock expires, so your queue matters even when you are not actively selecting.`
  String get draftGuideBullet3 {
    return Intl.message(
      'Auto-pick can step in if your clock expires, so your queue matters even when you are not actively selecting.',
      name: 'draftGuideBullet3',
      desc: '',
      args: [],
    );
  }

  /// `Draft League Guide`
  String get draftLeagueGuideTitle {
    return Intl.message(
      'Draft League Guide',
      name: 'draftLeagueGuideTitle',
      desc: '',
      args: [],
    );
  }

  /// `How The Draft Works`
  String get guideHowDraftWorksTitle {
    return Intl.message(
      'How The Draft Works',
      name: 'guideHowDraftWorksTitle',
      desc: '',
      args: [],
    );
  }

  /// `When the draft starts, managers pick one player at a time in the draft order shown by the room.`
  String get guideHowDraftWorksItem1 {
    return Intl.message(
      'When the draft starts, managers pick one player at a time in the draft order shown by the room.',
      name: 'guideHowDraftWorksItem1',
      desc: '',
      args: [],
    );
  }

  /// `If the league uses snake order, the order reverses every round so the manager picking last in one round picks first in the next.`
  String get guideHowDraftWorksItem2 {
    return Intl.message(
      'If the league uses snake order, the order reverses every round so the manager picking last in one round picks first in the next.',
      name: 'guideHowDraftWorksItem2',
      desc: '',
      args: [],
    );
  }

  /// `Every player can belong to only one manager. If someone drafts a player before you, that player is gone from the pool.`
  String get guideHowDraftWorksItem3 {
    return Intl.message(
      'Every player can belong to only one manager. If someone drafts a player before you, that player is gone from the pool.',
      name: 'guideHowDraftWorksItem3',
      desc: '',
      args: [],
    );
  }

  /// `You can queue players before your turn so the app can auto-pick from your priority list if your clock expires.`
  String get guideHowDraftWorksItem4 {
    return Intl.message(
      'You can queue players before your turn so the app can auto-pick from your priority list if your clock expires.',
      name: 'guideHowDraftWorksItem4',
      desc: '',
      args: [],
    );
  }

  /// `What You Are Building`
  String get guideWhatYouAreBuildingTitle {
    return Intl.message(
      'What You Are Building',
      name: 'guideWhatYouAreBuildingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your draft roster has 18 players total.`
  String get guideWhatYouAreBuildingItem1 {
    return Intl.message(
      'Your draft roster has 18 players total.',
      name: 'guideWhatYouAreBuildingItem1',
      desc: '',
      args: [],
    );
  }

  /// `You must still be able to finish with at least 1 goalkeeper, 3 defenders, 3 midfielders, and 1 forward.`
  String get guideWhatYouAreBuildingItem2 {
    return Intl.message(
      'You must still be able to finish with at least 1 goalkeeper, 3 defenders, 3 midfielders, and 1 forward.',
      name: 'guideWhatYouAreBuildingItem2',
      desc: '',
      args: [],
    );
  }

  /// `Beyond those minimums, the remaining spots are flexible, so strategy matters.`
  String get guideWhatYouAreBuildingItem3 {
    return Intl.message(
      'Beyond those minimums, the remaining spots are flexible, so strategy matters.',
      name: 'guideWhatYouAreBuildingItem3',
      desc: '',
      args: [],
    );
  }

  /// `Draft Vs Classic`
  String get guideDraftVsClassicTitle {
    return Intl.message(
      'Draft Vs Classic',
      name: 'guideDraftVsClassicTitle',
      desc: '',
      args: [],
    );
  }

  /// `Draft mode is exclusive: once you draft a player, nobody else in the league can own him.`
  String get guideDraftVsClassicItem1 {
    return Intl.message(
      'Draft mode is exclusive: once you draft a player, nobody else in the league can own him.',
      name: 'guideDraftVsClassicItem1',
      desc: '',
      args: [],
    );
  }

  /// `Classic mode is budget-based: multiple users can buy the same player as long as they can afford him.`
  String get guideDraftVsClassicItem2 {
    return Intl.message(
      'Classic mode is budget-based: multiple users can buy the same player as long as they can afford him.',
      name: 'guideDraftVsClassicItem2',
      desc: '',
      args: [],
    );
  }

  /// `In draft mode, your decisions are about scarcity, timing, and roster construction. In classic mode, they are about value under budget.`
  String get guideDraftVsClassicItem3 {
    return Intl.message(
      'In draft mode, your decisions are about scarcity, timing, and roster construction. In classic mode, they are about value under budget.',
      name: 'guideDraftVsClassicItem3',
      desc: '',
      args: [],
    );
  }

  /// `Season projection is most useful during drafting and buying, while next-match projection is more useful later when deciding starters and substitutions.`
  String get guideDraftVsClassicItem4 {
    return Intl.message(
      'Season projection is most useful during drafting and buying, while next-match projection is more useful later when deciding starters and substitutions.',
      name: 'guideDraftVsClassicItem4',
      desc: '',
      args: [],
    );
  }

  /// `Practical Tips`
  String get guidePracticalTipsTitle {
    return Intl.message(
      'Practical Tips',
      name: 'guidePracticalTipsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Use the queue to rank fallback picks before your turn arrives.`
  String get guidePracticalTipsItem1 {
    return Intl.message(
      'Use the queue to rank fallback picks before your turn arrives.',
      name: 'guidePracticalTipsItem1',
      desc: '',
      args: [],
    );
  }

  /// `Watch the turns-left indicator so you know when to stop browsing and start narrowing your shortlist.`
  String get guidePracticalTipsItem2 {
    return Intl.message(
      'Watch the turns-left indicator so you know when to stop browsing and start narrowing your shortlist.',
      name: 'guidePracticalTipsItem2',
      desc: '',
      args: [],
    );
  }

  /// `Do not ignore position balance early enough that you become forced into weak picks late in the draft.`
  String get guidePracticalTipsItem3 {
    return Intl.message(
      'Do not ignore position balance early enough that you become forced into weak picks late in the draft.',
      name: 'guidePracticalTipsItem3',
      desc: '',
      args: [],
    );
  }

  /// `My Team`
  String get myTeamLabel {
    return Intl.message('My Team', name: 'myTeamLabel', desc: '', args: []);
  }

  /// `Waiting for opponent...`
  String get waitingForOpponentEllipsis {
    return Intl.message(
      'Waiting for opponent...',
      name: 'waitingForOpponentEllipsis',
      desc: '',
      args: [],
    );
  }

  /// `Next Matchup`
  String get nextMatchupTitle {
    return Intl.message(
      'Next Matchup',
      name: 'nextMatchupTitle',
      desc: '',
      args: [],
    );
  }

  /// `{points} pts`
  String pointsAbbrev(String points) {
    return Intl.message(
      '$points pts',
      name: 'pointsAbbrev',
      desc: '',
      args: [points],
    );
  }

  /// `VS`
  String get vsUpper {
    return Intl.message('VS', name: 'vsUpper', desc: '', args: []);
  }

  /// `You are projected to win by {points} pts!`
  String projectedWinBy(String points) {
    return Intl.message(
      'You are projected to win by $points pts!',
      name: 'projectedWinBy',
      desc: '',
      args: [points],
    );
  }

  /// `Behind by {points} pts - Edit your team!`
  String behindByEditTeam(String points) {
    return Intl.message(
      'Behind by $points pts - Edit your team!',
      name: 'behindByEditTeam',
      desc: '',
      args: [points],
    );
  }

  /// `It is a close matchup!`
  String get closeMatchup {
    return Intl.message(
      'It is a close matchup!',
      name: 'closeMatchup',
      desc: '',
      args: [],
    );
  }

  /// `Draft Room Ready`
  String get draftRoomReady {
    return Intl.message(
      'Draft Room Ready',
      name: 'draftRoomReady',
      desc: '',
      args: [],
    );
  }

  /// `Team Will Be Drafted Live`
  String get teamWillBeDraftedLive {
    return Intl.message(
      'Team Will Be Drafted Live',
      name: 'teamWillBeDraftedLive',
      desc: '',
      args: [],
    );
  }

  /// `The draft is live. Enter the room to make your picks while other managers auto-pick when their timers expire.`
  String get draftLiveEnterRoomDescription {
    return Intl.message(
      'The draft is live. Enter the room to make your picks while other managers auto-pick when their timers expire.',
      name: 'draftLiveEnterRoomDescription',
      desc: '',
      args: [],
    );
  }

  /// `Your team is created through the live draft, not with the classic team builder.`
  String get teamCreatedThroughLiveDraftDescription {
    return Intl.message(
      'Your team is created through the live draft, not with the classic team builder.',
      name: 'teamCreatedThroughLiveDraftDescription',
      desc: '',
      args: [],
    );
  }

  /// `Waiting For Draft Start`
  String get waitingForDraftStart {
    return Intl.message(
      'Waiting For Draft Start',
      name: 'waitingForDraftStart',
      desc: '',
      args: [],
    );
  }

  /// `No Team Yet`
  String get noTeamYet {
    return Intl.message('No Team Yet', name: 'noTeamYet', desc: '', args: []);
  }

  /// `Build your fantasy team to compete in this league!`
  String get buildFantasyTeamCompete {
    return Intl.message(
      'Build your fantasy team to compete in this league!',
      name: 'buildFantasyTeamCompete',
      desc: '',
      args: [],
    );
  }

  /// `{count}/{total} players`
  String playersCountOfTotal(int count, int total) {
    return Intl.message(
      '$count/$total players',
      name: 'playersCountOfTotal',
      desc: '',
      args: [count, total],
    );
  }

  /// `{count}/{total} players • \${budget}M left`
  String playersAndBudgetLeft(int count, int total, String budget) {
    return Intl.message(
      '$count/$total players • \\\$${budget}M left',
      name: 'playersAndBudgetLeft',
      desc: '',
      args: [count, total, budget],
    );
  }

  /// `Pick Your Starters And Formation`
  String get pickStartersAndFormation {
    return Intl.message(
      'Pick Your Starters And Formation',
      name: 'pickStartersAndFormation',
      desc: '',
      args: [],
    );
  }

  /// `Your draft squad is ready. Set your starting XI, choose a formation, and assign captain roles before the matchup locks.`
  String get draftSquadReadySetStarters {
    return Intl.message(
      'Your draft squad is ready. Set your starting XI, choose a formation, and assign captain roles before the matchup locks.',
      name: 'draftSquadReadySetStarters',
      desc: '',
      args: [],
    );
  }

  /// `Set Starters`
  String get setStarters {
    return Intl.message(
      'Set Starters',
      name: 'setStarters',
      desc: '',
      args: [],
    );
  }

  /// `Current Formation`
  String get currentFormation {
    return Intl.message(
      'Current Formation',
      name: 'currentFormation',
      desc: '',
      args: [],
    );
  }

  /// `Projected Points`
  String get projectedPoints {
    return Intl.message(
      'Projected Points',
      name: 'projectedPoints',
      desc: '',
      args: [],
    );
  }

  /// `pts`
  String get ptsShort {
    return Intl.message('pts', name: 'ptsShort', desc: '', args: []);
  }

  /// `Team created`
  String get teamCreated {
    return Intl.message(
      'Team created',
      name: 'teamCreated',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for opponent`
  String get waitingForOpponent {
    return Intl.message(
      'Waiting for opponent',
      name: 'waitingForOpponent',
      desc: '',
      args: [],
    );
  }

  /// `Your Predicted Points`
  String get yourPredictedPoints {
    return Intl.message(
      'Your Predicted Points',
      name: 'yourPredictedPoints',
      desc: '',
      args: [],
    );
  }

  /// `Next Opponent`
  String get nextOpponent {
    return Intl.message(
      'Next Opponent',
      name: 'nextOpponent',
      desc: '',
      args: [],
    );
  }

  /// `No standings yet`
  String get noStandingsYet {
    return Intl.message(
      'No standings yet',
      name: 'noStandingsYet',
      desc: '',
      args: [],
    );
  }

  /// `Standings will appear after match starts`
  String get standingsAppearAfterMatchStarts {
    return Intl.message(
      'Standings will appear after match starts',
      name: 'standingsAppearAfterMatchStarts',
      desc: '',
      args: [],
    );
  }

  /// `{count} players • \${budget}M left`
  String playersAndMoneyLeft(int count, String budget) {
    return Intl.message(
      '$count players • \\\$${budget}M left',
      name: 'playersAndMoneyLeft',
      desc: '',
      args: [count, budget],
    );
  }

  /// `Draft: {time}`
  String draftAt(String time) {
    return Intl.message(
      'Draft: $time',
      name: 'draftAt',
      desc: '',
      args: [time],
    );
  }

  /// `Failed to load players: {error}`
  String failedToLoadPlayers(String error) {
    return Intl.message(
      'Failed to load players: $error',
      name: 'failedToLoadPlayers',
      desc: '',
      args: [error],
    );
  }

  /// `TBD`
  String get tbd {
    return Intl.message('TBD', name: 'tbd', desc: '', args: []);
  }

  /// `Now`
  String get now {
    return Intl.message('Now', name: 'now', desc: '', args: []);
  }

  /// `Draft time has not been scheduled yet`
  String get draftTimeNotScheduledYet {
    return Intl.message(
      'Draft time has not been scheduled yet',
      name: 'draftTimeNotScheduledYet',
      desc: '',
      args: [],
    );
  }

  /// `Draft is live now`
  String get draftIsLiveNow {
    return Intl.message(
      'Draft is live now',
      name: 'draftIsLiveNow',
      desc: '',
      args: [],
    );
  }

  /// `Starts in {days}d {hours}h {minutes}m`
  String startsInDaysHoursMinutes(int days, int hours, int minutes) {
    return Intl.message(
      'Starts in ${days}d ${hours}h ${minutes}m',
      name: 'startsInDaysHoursMinutes',
      desc: '',
      args: [days, hours, minutes],
    );
  }

  /// `Starts in {hh}:{mm}:{ss}`
  String startsInCountdown(String hh, String mm, String ss) {
    return Intl.message(
      'Starts in $hh:$mm:$ss',
      name: 'startsInCountdown',
      desc: '',
      args: [hh, mm, ss],
    );
  }

  /// `FREE`
  String get freeLabel {
    return Intl.message('FREE', name: 'freeLabel', desc: '', args: []);
  }

  /// `YOU`
  String get youUpper {
    return Intl.message('YOU', name: 'youUpper', desc: '', args: []);
  }

  /// `CREATOR`
  String get creatorUpper {
    return Intl.message('CREATOR', name: 'creatorUpper', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'id'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'sw'),
      Locale.fromSubtags(languageCode: 'tr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
