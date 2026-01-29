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

  String get myLeagues {
    return Intl.message('My Leagues', name: 'myLeagues', desc: '', args: []);
  }

  String get fixtures {
    return Intl.message('Fixtures', name: 'fixtures', desc: '', args: []);
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

  // ==================== Player Profile Localizations ====================

  /// `Player Details`
  String get playerDetails {
    return Intl.message('Player Details', name: 'playerDetails', desc: '', args: []);
  }

  /// `Player not found`
  String get playerNotFound {
    return Intl.message('Player not found', name: 'playerNotFound', desc: '', args: []);
  }

  /// `Fantasy Points Prediction`
  String get fantasyPointsPrediction {
    return Intl.message('Fantasy Points Prediction', name: 'fantasyPointsPrediction', desc: '', args: []);
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
    return Intl.message('Loading next match...', name: 'loadingNextMatch', desc: '', args: []);
  }

  /// `Next Match`
  String get nextMatch {
    return Intl.message('Next Match', name: 'nextMatch', desc: '', args: []);
  }

  /// `Tournament Statistics`
  String get tournamentStatistics {
    return Intl.message('Tournament Statistics', name: 'tournamentStatistics', desc: '', args: []);
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
    return Intl.message('Loading tournament stats...', name: 'loadingTournamentStats', desc: '', args: []);
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
    return Intl.message('Clean Sheets', name: 'cleanSheets', desc: '', args: []);
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
    return Intl.message('Full Season Statistics', name: 'fullSeasonStatistics', desc: '', args: []);
  }

  /// `Includes Apertura + Clausura tournaments`
  String get includesAperturaClausura {
    return Intl.message('Includes Apertura + Clausura tournaments', name: 'includesAperturaClausura', desc: '', args: []);
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
    return Intl.message('Season averages', name: 'seasonAverages', desc: '', args: []);
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
    return Intl.message('Search Players', name: 'searchPlayers', desc: '', args: []);
  }

  /// `Search by name...`
  String get searchByName {
    return Intl.message('Search by name...', name: 'searchByName', desc: '', args: []);
  }

  /// `No players found`
  String get noPlayersFound {
    return Intl.message('No players found', name: 'noPlayersFound', desc: '', args: []);
  }

  /// `Recent Searches`
  String get recentSearches {
    return Intl.message('Recent Searches', name: 'recentSearches', desc: '', args: []);
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
    return Intl.message('Transfer History', name: 'transferHistory', desc: '', args: []);
  }

  /// `Current Team`
  String get currentTeam {
    return Intl.message('Current Team', name: 'currentTeam', desc: '', args: []);
  }

  /// `Previous Teams`
  String get previousTeams {
    return Intl.message('Previous Teams', name: 'previousTeams', desc: '', args: []);
  }

  /// `Jersey Number`
  String get jerseyNumber {
    return Intl.message('Jersey Number', name: 'jerseyNumber', desc: '', args: []);
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
    return Intl.message('Date of Birth', name: 'dateOfBirth', desc: '', args: []);
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
    return Intl.message('Average Rating', name: 'averageRating', desc: '', args: []);
  }

  /// `Career Totals`
  String get careerTotals {
    return Intl.message('Career Totals', name: 'careerTotals', desc: '', args: []);
  }

  /// `Clear History`
  String get clearHistoryTitle {
    return Intl.message('Clear History', name: 'clearHistoryTitle', desc: '', args: []);
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
    return Intl.message('Search history cleared', name: 'searchHistoryCleared', desc: '', args: []);
  }

  /// `Search players by name...`
  String get searchPlayersHint {
    return Intl.message('Search players by name...', name: 'searchPlayersHint', desc: '', args: []);
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
    return Intl.message('Try a different search term', name: 'tryDifferentSearch', desc: '', args: []);
  }

  /// `Search Results`
  String get searchResultsTitle {
    return Intl.message('Search Results', name: 'searchResultsTitle', desc: '', args: []);
  }

  /// `Recent Players`
  String get recentPlayersTitle {
    return Intl.message('Recent Players', name: 'recentPlayersTitle', desc: '', args: []);
  }

  /// `Search for Players`
  String get searchForPlayers {
    return Intl.message('Search for Players', name: 'searchForPlayers', desc: '', args: []);
  }

  /// `Enter at least 3 characters to search`
  String get enterAtLeast3Chars {
    return Intl.message('Enter at least 3 characters to search', name: 'enterAtLeast3Chars', desc: '', args: []);
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
    return Intl.message('Select Your Favorite Team', name: 'selectFavoriteTeam', desc: '', args: []);
  }

  /// `Choose your favorite Liga MX team. We'll personalize your experience and show players from your team first.`
  String get favoriteTeamDescription {
    return Intl.message('Choose your favorite Liga MX team. We\'ll personalize your experience and show players from your team first.', name: 'favoriteTeamDescription', desc: '', args: []);
  }

  /// `Error loading teams`
  String get errorLoadingTeams {
    return Intl.message('Error loading teams', name: 'errorLoadingTeams', desc: '', args: []);
  }

  /// `No teams found`
  String get noTeamsFound {
    return Intl.message('No teams found', name: 'noTeamsFound', desc: '', args: []);
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Saving...`
  String get saving {
    return Intl.message('Saving...', name: 'saving', desc: '', args: []);
  }

  /// `Favorite Team`
  String get favoriteTeam {
    return Intl.message('Favorite Team', name: 'favoriteTeam', desc: '', args: []);
  }

  /// `Change Favorite Team`
  String get changeFavoriteTeam {
    return Intl.message('Change Favorite Team', name: 'changeFavoriteTeam', desc: '', args: []);
  }

  /// `Your Favorite Team`
  String get yourFavoriteTeam {
    return Intl.message('Your Favorite Team', name: 'yourFavoriteTeam', desc: '', args: []);
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
