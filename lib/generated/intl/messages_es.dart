// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(name) => "Se agregó ${name}";

  static String m1(position) => "Basado en métricas de ${position}";

  static String m2(points) => "Vas abajo por ${points} pts - Edita tu equipo";

  static String m3(days) => "${days}d";

  static String m4(time) => "Draft: ${time}";

  static String m5(name) =>
      "¿Seguro que quieres soltar a ${name}? Quedará disponible para otros equipos.";

  static String m6(name) => "Se soltó a ${name}";

  static String m7(error) => "Error al unirse a la liga: ${error}";

  static String m8(error) => "Error al crear liga: ${error}";

  static String m9(error) => "Error al cargar ligas: ${error}";

  static String m10(error) => "Error al cargar jugadores: ${error}";

  static String m11(count) =>
      "Basado en ${count} partidos analizados (algunos pueden haber sido omitidos)";

  static String m12(name) => "De: ${name}";

  static String m13(hours, minutes) => "${hours}h ${minutes}m";

  static String m14(leagueName) => "¡Únete a ${leagueName} en Fantasy 11!";

  static String m15(time) =>
      "Unido correctamente. La creación del equipo abre el ${time}.";

  static String m16(count) => "Últimos ${count} partidos";

  static String m17(count) => "Últimos ${count} partidos";

  static String m18(name) => "¡Liga \"${name}\" creada!";

  static String m19(current, max) => "${current}/${max} miembros";

  static String m20(minutes) => "${minutes}m";

  static String m21(count) => "${count} partidos";

  static String m22(query) => "No se encontraron jugadores para \"${query}\"";

  static String m23(owner) => "Propiedad de ${owner}";

  static String m24(count, total, budget) =>
      "${count}/${total} jugadores • \\\$${budget}M restantes";

  static String m25(count, budget) =>
      "${count} jugadores • \\\$${budget}M restantes";

  static String m26(count, total) => "${count}/${total} jugadores";

  static String m27(seconds) =>
      "Por favor espera ${seconds} segundos antes de reenviar";

  static String m28(points) => "${points} pts";

  static String m29(value) => "${value} próximo";

  static String m30(value) => "${value} temporada";

  static String m31(points) => "Proyectas ganar por ${points} pts";

  static String m32(points, team) => "${points} próximo • ${team}";

  static String m33(current, max) => "Plantel: ${current} / ${max}";

  static String m34(budget) =>
      "Selecciona 18 jugadores (11 titulares + 7 suplentes) dentro de \\\$${budget}M";

  static String m35(count) => "${count} lugares disponibles";

  static String m36(stageName) => "Estadísticas ${stageName}";

  static String m37(hh, mm, ss) => "Empieza en ${hh}:${mm}:${ss}";

  static String m38(days, hours, minutes) =>
      "Empieza en ${days}d ${hours}h ${minutes}m";

  static String m39(dropPlayer, addPlayer) =>
      "Se intercambió ${dropPlayer} por ${addPlayer}";

  static String m40(name) => "Para: ${name}";

  static String m41(date) => "Fecha límite de intercambios: ${date}";

  static String m42(team, owner, points) =>
      "${team} • Propiedad de ${owner} • ${points} próximo";

  static String m43(side) => "Voto registrado: ${side}";

  static String m44(teamName) =>
      "¡Bienvenido a la liga! Tu equipo \"${teamName}\" está listo.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "LeJoined": MessageLookupByLibrary.simpleMessage(
      "Le unimos 2 partidos = 20 puntos",
    ),
    "aboutUs": MessageLookupByLibrary.simpleMessage("Sobre nosotros"),
    "acceptAction": MessageLookupByLibrary.simpleMessage("Aceptar"),
    "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
    "accountHolderName": MessageLookupByLibrary.simpleMessage(
      "Nombre del titular de la cuenta",
    ),
    "accountName": MessageLookupByLibrary.simpleMessage("Nombre de la cuenta"),
    "accountNumber": MessageLookupByLibrary.simpleMessage("Número de cuenta"),
    "actual": MessageLookupByLibrary.simpleMessage("Real"),
    "add": MessageLookupByLibrary.simpleMessage("AGREGAR"),
    "addMoney": MessageLookupByLibrary.simpleMessage("Agregar dinero"),
    "addPlayerAction": MessageLookupByLibrary.simpleMessage("Agregar"),
    "addPlayersFromAvailableTab": MessageLookupByLibrary.simpleMessage(
      "Agrega jugadores desde la pestaña Disponibles",
    ),
    "addToRoster": MessageLookupByLibrary.simpleMessage("Agregar al plantel"),
    "addYourIssuefeedback": MessageLookupByLibrary.simpleMessage(
      "Agregue su problema / comentarios",
    ),
    "addedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Se agregó localmente, pero no se pudo persistir la actualización del plantel",
    ),
    "addedPlayer": m0,
    "addedToWallet": MessageLookupByLibrary.simpleMessage("Agregado a Wallet"),
    "age": MessageLookupByLibrary.simpleMessage("Edad"),
    "allLabel": MessageLookupByLibrary.simpleMessage("Todos"),
    "allSeries": MessageLookupByLibrary.simpleMessage("Todas las series"),
    "allTeams": MessageLookupByLibrary.simpleMessage("Todos los equipos"),
    "amount": MessageLookupByLibrary.simpleMessage("Monto"),
    "anyoneCanJoin": MessageLookupByLibrary.simpleMessage(
      "Cualquiera puede unirse",
    ),
    "appearances": MessageLookupByLibrary.simpleMessage("Apariciones"),
    "apps": MessageLookupByLibrary.simpleMessage("Partidos"),
    "assists": MessageLookupByLibrary.simpleMessage("Asistencias"),
    "attacker": MessageLookupByLibrary.simpleMessage("Atacante"),
    "availableBalance": MessageLookupByLibrary.simpleMessage(
      "Saldo disponible",
    ),
    "availableTab": MessageLookupByLibrary.simpleMessage("Disponibles"),
    "average": MessageLookupByLibrary.simpleMessage("Promedio"),
    "averageRating": MessageLookupByLibrary.simpleMessage(
      "Calificación Promedio",
    ),
    "avgRating": MessageLookupByLibrary.simpleMessage("Calif. Prom"),
    "avoid": MessageLookupByLibrary.simpleMessage("Evitar"),
    "awaitingLeagueVote": MessageLookupByLibrary.simpleMessage(
      "Esperando voto de la liga",
    ),
    "bankDetails": MessageLookupByLibrary.simpleMessage("Detalles del banco"),
    "bankIfscCode": MessageLookupByLibrary.simpleMessage(
      "Código IFSC del banco",
    ),
    "basedOnMetrics": m1,
    "behindByEditTeam": m2,
    "birthdate": MessageLookupByLibrary.simpleMessage("Fecha de nacimiento"),
    "blockedShots": MessageLookupByLibrary.simpleMessage("Disparos bloqueados"),
    "budgetBased": MessageLookupByLibrary.simpleMessage(
      "Basado en presupuesto",
    ),
    "budgetLabel": MessageLookupByLibrary.simpleMessage("Presupuesto"),
    "buildFantasyTeamCompete": MessageLookupByLibrary.simpleMessage(
      "¡Arma tu equipo fantasy para competir en esta liga!",
    ),
    "buildTeam": MessageLookupByLibrary.simpleMessage("Armar equipo"),
    "cWillGet": MessageLookupByLibrary.simpleMessage(
      "C obtendrá 2x puntos y VC obtendrá 1.5x puntos",
    ),
    "cacheClearedRestart": MessageLookupByLibrary.simpleMessage(
      "¡Caché limpiada! Reinicia la app para datos frescos.",
    ),
    "callUs": MessageLookupByLibrary.simpleMessage("Llámanos"),
    "canILogin": MessageLookupByLibrary.simpleMessage(
      "¿Puedo iniciar sesión a través de una cuenta social?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "cancelTradeAction": MessageLookupByLibrary.simpleMessage(
      "Cancelar intercambio",
    ),
    "cancelled": MessageLookupByLibrary.simpleMessage("Cancelada"),
    "cannotAddPlayerFixtureStarted": MessageLookupByLibrary.simpleMessage(
      "No se puede agregar al jugador: el partido ya empezó",
    ),
    "cannotSwapDropPlayerNotOnRoster": MessageLookupByLibrary.simpleMessage(
      "No se puede intercambiar: el jugador a soltar no está en tu plantel",
    ),
    "cap": MessageLookupByLibrary.simpleMessage("Ninguna"),
    "captain": MessageLookupByLibrary.simpleMessage("Capitán"),
    "careerTotals": MessageLookupByLibrary.simpleMessage("Totales de Carrera"),
    "changeFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Cambiar Equipo Favorito",
    ),
    "changeLanguage": MessageLookupByLibrary.simpleMessage("Cambiar idioma"),
    "chooseCaptain": MessageLookupByLibrary.simpleMessage(
      "Elija Capitán y Vice Capitán",
    ),
    "chooseOnePlayerToOffer": MessageLookupByLibrary.simpleMessage(
      "Elige uno de tus jugadores para ofrecer:",
    ),
    "chooseTeamNamePrompt": MessageLookupByLibrary.simpleMessage(
      "Elige un nombre para tu equipo fantasy:",
    ),
    "classic": MessageLookupByLibrary.simpleMessage("Clásico"),
    "classicBudgetRecommendation": MessageLookupByLibrary.simpleMessage(
      "Presupuesto recomendado: 130-150M para un plantel equilibrado de 18 jugadores.",
    ),
    "classicInfoBudgetTeam": MessageLookupByLibrary.simpleMessage(
      "Cada miembro arma un equipo dentro del presupuesto",
    ),
    "classicInfoCreateInvite": MessageLookupByLibrary.simpleMessage(
      "Crea tu liga e invita amigos",
    ),
    "classicInfoEarnPoints": MessageLookupByLibrary.simpleMessage(
      "Gana puntos según el rendimiento real de los jugadores",
    ),
    "classicInfoSamePlayersAllowed": MessageLookupByLibrary.simpleMessage(
      "Varios managers pueden tener los mismos jugadores",
    ),
    "cleanSheets": MessageLookupByLibrary.simpleMessage("Porterías Invictas"),
    "clear": MessageLookupByLibrary.simpleMessage("Limpiar"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Limpiar Todo"),
    "clearCacheSubtitle": MessageLookupByLibrary.simpleMessage(
      "Borra todos los datos en caché (para pruebas)",
    ),
    "clearCacheTitle": MessageLookupByLibrary.simpleMessage("Limpiar caché"),
    "clearHistoryMessage": MessageLookupByLibrary.simpleMessage(
      "¿Estás seguro de que quieres limpiar tu historial de jugadores recientes?",
    ),
    "clearHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Limpiar Historial",
    ),
    "clearance": MessageLookupByLibrary.simpleMessage("Autorización"),
    "clearingCache": MessageLookupByLibrary.simpleMessage("Limpiando caché..."),
    "closeMatchup": MessageLookupByLibrary.simpleMessage(
      "¡Es un duelo muy parejo!",
    ),
    "cm": MessageLookupByLibrary.simpleMessage("cm"),
    "completed": MessageLookupByLibrary.simpleMessage("TERMINADO"),
    "confidence": MessageLookupByLibrary.simpleMessage("Confianza"),
    "connectUsForIssues": MessageLookupByLibrary.simpleMessage(
      "Comuníquese con nosotros para resolver problemas",
    ),
    "contests": MessageLookupByLibrary.simpleMessage("Concursos"),
    "continueText": MessageLookupByLibrary.simpleMessage("Continuar"),
    "copyCode": MessageLookupByLibrary.simpleMessage("Copiar código"),
    "countryCode": MessageLookupByLibrary.simpleMessage("Código de país"),
    "create": MessageLookupByLibrary.simpleMessage("Crear"),
    "createLeagueLabel": MessageLookupByLibrary.simpleMessage("Crear liga"),
    "createOrJoinFirstLeague": MessageLookupByLibrary.simpleMessage(
      "Crea tu primera liga o únete a una existente",
    ),
    "createPublicLeagueOrWait": MessageLookupByLibrary.simpleMessage(
      "Crea una liga pública o espera a que otros creen una",
    ),
    "createTeam": MessageLookupByLibrary.simpleMessage("Crear equipo"),
    "creatorUpper": MessageLookupByLibrary.simpleMessage("CREADOR"),
    "credit": MessageLookupByLibrary.simpleMessage("Crédito"),
    "currentFormation": MessageLookupByLibrary.simpleMessage(
      "Formación actual",
    ),
    "currentTeam": MessageLookupByLibrary.simpleMessage("Equipo Actual"),
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Fecha de Nacimiento"),
    "daysShort": m3,
    "defender": MessageLookupByLibrary.simpleMessage("Defensor"),
    "defenders": MessageLookupByLibrary.simpleMessage("DEFENSORES"),
    "describeYourLeague": MessageLookupByLibrary.simpleMessage(
      "Describe tu liga",
    ),
    "descriptionOptional": MessageLookupByLibrary.simpleMessage(
      "Descripción (Opcional)",
    ),
    "draft": MessageLookupByLibrary.simpleMessage("Draft"),
    "draftAt": m4,
    "draftCompleted": MessageLookupByLibrary.simpleMessage("Draft completado"),
    "draftDateTime": MessageLookupByLibrary.simpleMessage(
      "Fecha y hora del draft",
    ),
    "draftGuideBullet1": MessageLookupByLibrary.simpleMessage(
      "Cada manager elige por turnos un jugador a la vez. Cuando un jugador es drafteado, nadie más puede tenerlo.",
    ),
    "draftGuideBullet2": MessageLookupByLibrary.simpleMessage(
      "No hay presupuesto de transferencias durante el draft. Tu ventaja está en el timing de picks, prioridad de cola y balance del plantel.",
    ),
    "draftGuideBullet3": MessageLookupByLibrary.simpleMessage(
      "El auto-pick puede entrar si se acaba tu tiempo, así que tu cola importa incluso cuando no estás seleccionando activamente.",
    ),
    "draftInfoCompeteChampionship": MessageLookupByLibrary.simpleMessage(
      "¡Compite por el campeonato!",
    ),
    "draftInfoScheduleDraft": MessageLookupByLibrary.simpleMessage(
      "Configura tu liga y agenda el draft",
    ),
    "draftInfoTakeTurns": MessageLookupByLibrary.simpleMessage(
      "El día del draft, elijan jugadores por turnos",
    ),
    "draftInfoTradesAndFreeAgency": MessageLookupByLibrary.simpleMessage(
      "Intercambia jugadores y toma agentes libres durante la temporada",
    ),
    "draftInfoUniquePlayers": MessageLookupByLibrary.simpleMessage(
      "Cada jugador solo puede pertenecer a un equipo",
    ),
    "draftIsLiveNow": MessageLookupByLibrary.simpleMessage(
      "El draft está en vivo ahora",
    ),
    "draftLeagueGuideTitle": MessageLookupByLibrary.simpleMessage(
      "Guía de liga draft",
    ),
    "draftLiveEnterRoomDescription": MessageLookupByLibrary.simpleMessage(
      "El draft está en vivo. Entra a la sala para hacer tus picks mientras otros managers usan auto-pick al acabarse su tiempo.",
    ),
    "draftRoomOpens15MinBeforeStart": MessageLookupByLibrary.simpleMessage(
      "La sala de draft abre 15 min antes del inicio",
    ),
    "draftRoomReady": MessageLookupByLibrary.simpleMessage(
      "Sala de draft lista",
    ),
    "draftSchedule": MessageLookupByLibrary.simpleMessage("Horario del draft"),
    "draftSettings": MessageLookupByLibrary.simpleMessage(
      "Configuración del draft",
    ),
    "draftSquadReadySetStarters": MessageLookupByLibrary.simpleMessage(
      "Tu plantel draft está listo. Define tu XI inicial, elige formación y asigna capitán/vicecapitán antes del cierre del partido.",
    ),
    "draftTimeNotScheduledYet": MessageLookupByLibrary.simpleMessage(
      "La hora del draft aún no está programada",
    ),
    "draftVsClassic": MessageLookupByLibrary.simpleMessage("Draft vs clásico"),
    "dropAction": MessageLookupByLibrary.simpleMessage("Soltar"),
    "dropPlayerConfirmation": m5,
    "dropPlayerQuestion": MessageLookupByLibrary.simpleMessage(
      "¿Soltar jugador?",
    ),
    "dropPlayerTooltip": MessageLookupByLibrary.simpleMessage("Soltar jugador"),
    "droppedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Se soltó localmente, pero no se pudo persistir la actualización del plantel",
    ),
    "droppedPlayer": m6,
    "earnOneHundred": MessageLookupByLibrary.simpleMessage(
      "Gana 129 puntos más para alcanzar el nivel 90",
    ),
    "editTeam": MessageLookupByLibrary.simpleMessage("Editar equipo"),
    "elitePick": MessageLookupByLibrary.simpleMessage("Élite"),
    "emailAddress": MessageLookupByLibrary.simpleMessage(
      "Dirección de correo electrónico",
    ),
    "enterAccountNumber": MessageLookupByLibrary.simpleMessage(
      "Ingrese el número de cuenta",
    ),
    "enterAmount": MessageLookupByLibrary.simpleMessage("Ingrese la cantidad"),
    "enterAtLeast3Chars": MessageLookupByLibrary.simpleMessage(
      "Ingresa al menos 3 caracteres para buscar",
    ),
    "enterCode": MessageLookupByLibrary.simpleMessage("Introduzca el código"),
    "enterDraftRoom": MessageLookupByLibrary.simpleMessage(
      "Entrar a la sala de draft",
    ),
    "enterEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Introducir la dirección de correo electrónico",
    ),
    "enterFullName": MessageLookupByLibrary.simpleMessage(
      "Ingrese su nombre completo",
    ),
    "enterLeagueName": MessageLookupByLibrary.simpleMessage(
      "Ingresa un nombre para tu liga",
    ),
    "enterPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Introduzca el número de teléfono",
    ),
    "enterSixDigit": MessageLookupByLibrary.simpleMessage(
      "Ingrese el código de 6 dígitos",
    ),
    "enterSixDigitVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Ingresa el código de verificación de 6 dígitos",
    ),
    "enterValidInviteCode": MessageLookupByLibrary.simpleMessage(
      "Ingresa un código de invitación válido",
    ),
    "errorJoiningLeague": m7,
    "errorLabel": MessageLookupByLibrary.simpleMessage("Error"),
    "errorLoadingTeams": MessageLookupByLibrary.simpleMessage(
      "Error al cargar equipos",
    ),
    "errorSearchingForLeague": MessageLookupByLibrary.simpleMessage(
      "Error al buscar liga",
    ),
    "events": MessageLookupByLibrary.simpleMessage("Eventos"),
    "everythingAboutYou": MessageLookupByLibrary.simpleMessage("Todo sobre ti"),
    "excellent": MessageLookupByLibrary.simpleMessage("Excelente"),
    "facebook": MessageLookupByLibrary.simpleMessage("Facebook"),
    "failedToCompleteSwap": MessageLookupByLibrary.simpleMessage(
      "No se pudo completar el intercambio",
    ),
    "failedToCreateLeague": m8,
    "failedToJoinLeague": MessageLookupByLibrary.simpleMessage(
      "No se pudo unir a la liga",
    ),
    "failedToLoadLeagues": m9,
    "failedToLoadPlayers": m10,
    "fantasyPointsPrediction": MessageLookupByLibrary.simpleMessage(
      "Predicción de Puntos Fantasy",
    ),
    "faqs": MessageLookupByLibrary.simpleMessage("Preguntas frecuentes"),
    "favoriteTeam": MessageLookupByLibrary.simpleMessage("Equipo Favorito"),
    "favoriteTeamDescription": MessageLookupByLibrary.simpleMessage(
      "Elige tu selección favorita. Personalizaremos tu experiencia y mostraremos primero a los jugadores de tu equipo.",
    ),
    "findLeague": MessageLookupByLibrary.simpleMessage("Buscar liga"),
    "findPlayerToTarget": MessageLookupByLibrary.simpleMessage(
      "Encuentra un jugador objetivo",
    ),
    "fixtures": MessageLookupByLibrary.simpleMessage("Partidos"),
    "fixturesAnalyzedNote": m11,
    "football": MessageLookupByLibrary.simpleMessage("Fútbol americano"),
    "forward": MessageLookupByLibrary.simpleMessage("Delantero"),
    "freeAgency": MessageLookupByLibrary.simpleMessage("Agencia libre"),
    "freeLabel": MessageLookupByLibrary.simpleMessage("GRATIS"),
    "fromUser": m12,
    "full": MessageLookupByLibrary.simpleMessage("Llena"),
    "fullDraftGuide": MessageLookupByLibrary.simpleMessage(
      "Guía completa de draft",
    ),
    "fullName": MessageLookupByLibrary.simpleMessage("Nombre completo"),
    "fullSeasonStatistics": MessageLookupByLibrary.simpleMessage(
      "Estadísticas de Temporada Completa",
    ),
    "games": MessageLookupByLibrary.simpleMessage("Partidos"),
    "getStarted": MessageLookupByLibrary.simpleMessage("Empezar"),
    "getYourAnswers": MessageLookupByLibrary.simpleMessage(
      "Obtenga sus respuestas",
    ),
    "getYourQuestionsAnswered": MessageLookupByLibrary.simpleMessage(
      "Obtenga respuestas a sus preguntas",
    ),
    "goalkeeper": MessageLookupByLibrary.simpleMessage("Portero"),
    "goals": MessageLookupByLibrary.simpleMessage("Goles"),
    "good": MessageLookupByLibrary.simpleMessage("Bueno"),
    "goodPick": MessageLookupByLibrary.simpleMessage("Bueno"),
    "google": MessageLookupByLibrary.simpleMessage("Google"),
    "guideDraftVsClassicItem1": MessageLookupByLibrary.simpleMessage(
      "El modo draft es exclusivo: cuando drafteas un jugador, nadie más en la liga puede tenerlo.",
    ),
    "guideDraftVsClassicItem2": MessageLookupByLibrary.simpleMessage(
      "El modo clásico es por presupuesto: varios usuarios pueden comprar al mismo jugador si les alcanza.",
    ),
    "guideDraftVsClassicItem3": MessageLookupByLibrary.simpleMessage(
      "En draft, tus decisiones son sobre escasez, timing y construcción del plantel. En clásico, son sobre valor bajo presupuesto.",
    ),
    "guideDraftVsClassicItem4": MessageLookupByLibrary.simpleMessage(
      "La proyección de temporada es más útil durante draft y compras; la proyección del próximo partido es más útil después para decidir titulares y cambios.",
    ),
    "guideDraftVsClassicTitle": MessageLookupByLibrary.simpleMessage(
      "Draft vs clásico",
    ),
    "guideHowDraftWorksItem1": MessageLookupByLibrary.simpleMessage(
      "Cuando inicia el draft, los managers eligen un jugador a la vez según el orden mostrado en la sala.",
    ),
    "guideHowDraftWorksItem2": MessageLookupByLibrary.simpleMessage(
      "Si la liga usa orden serpiente, el orden se invierte cada ronda, así que quien elige al final en una ronda elige primero en la siguiente.",
    ),
    "guideHowDraftWorksItem3": MessageLookupByLibrary.simpleMessage(
      "Cada jugador solo puede pertenecer a un manager. Si alguien lo draftea antes, sale del pool.",
    ),
    "guideHowDraftWorksItem4": MessageLookupByLibrary.simpleMessage(
      "Puedes poner jugadores en cola antes de tu turno para que la app haga auto-pick según tu prioridad si se agota tu reloj.",
    ),
    "guideHowDraftWorksTitle": MessageLookupByLibrary.simpleMessage(
      "Cómo funciona el draft",
    ),
    "guidePracticalTipsItem1": MessageLookupByLibrary.simpleMessage(
      "Usa la cola para rankear picks alternativos antes de que llegue tu turno.",
    ),
    "guidePracticalTipsItem2": MessageLookupByLibrary.simpleMessage(
      "Mira el indicador de turnos restantes para saber cuándo dejar de explorar y cerrar tu shortlist.",
    ),
    "guidePracticalTipsItem3": MessageLookupByLibrary.simpleMessage(
      "No ignores el balance de posiciones demasiado tiempo o te forzará a picks débiles al final del draft.",
    ),
    "guidePracticalTipsTitle": MessageLookupByLibrary.simpleMessage(
      "Consejos prácticos",
    ),
    "guideWhatYouAreBuildingItem1": MessageLookupByLibrary.simpleMessage(
      "Tu plantel draft tiene 18 jugadores en total.",
    ),
    "guideWhatYouAreBuildingItem2": MessageLookupByLibrary.simpleMessage(
      "Debes poder terminar con al menos 1 portero, 3 defensas, 3 mediocampistas y 1 delantero.",
    ),
    "guideWhatYouAreBuildingItem3": MessageLookupByLibrary.simpleMessage(
      "Más allá de esos mínimos, los lugares restantes son flexibles, así que la estrategia importa.",
    ),
    "guideWhatYouAreBuildingTitle": MessageLookupByLibrary.simpleMessage(
      "Qué estás construyendo",
    ),
    "headToHead": MessageLookupByLibrary.simpleMessage("Cabeza a cabeza"),
    "height": MessageLookupByLibrary.simpleMessage("Altura"),
    "high": MessageLookupByLibrary.simpleMessage("Alta"),
    "historyTab": MessageLookupByLibrary.simpleMessage("Historial"),
    "home": MessageLookupByLibrary.simpleMessage("Inicio"),
    "hoursMinutesShort": m13,
    "howClassicModeWorks": MessageLookupByLibrary.simpleMessage(
      "Cómo funciona el modo clásico",
    ),
    "howDraftLeaguesWork": MessageLookupByLibrary.simpleMessage(
      "Cómo funcionan las ligas draft",
    ),
    "howDraftModeWorks": MessageLookupByLibrary.simpleMessage(
      "Cómo funciona el modo draft",
    ),
    "howItWorks": MessageLookupByLibrary.simpleMessage("¿Cómo funciona?"),
    "howToAddMoney": MessageLookupByLibrary.simpleMessage(
      "¿Cómo agregar dinero?",
    ),
    "howToChangeLanguage": MessageLookupByLibrary.simpleMessage(
      "¿Cómo cambiar de idioma?",
    ),
    "howToChangeProfile": MessageLookupByLibrary.simpleMessage(
      "¿Cómo cambiar la foto de perfil?",
    ),
    "howToLogoutMyAccount": MessageLookupByLibrary.simpleMessage(
      "¿Cómo cerrar sesión en mi cuenta?",
    ),
    "howToPlay": MessageLookupByLibrary.simpleMessage("¿Cómo jugar?"),
    "howToSelectMoney": MessageLookupByLibrary.simpleMessage(
      "¿Cómo seleccionar jugador?",
    ),
    "howToSend": MessageLookupByLibrary.simpleMessage(
      "¿Cómo enviar dinero al banco?",
    ),
    "howToShop": MessageLookupByLibrary.simpleMessage("¿Cómo comprar?"),
    "howWeStarted": MessageLookupByLibrary.simpleMessage("Como empezamos"),
    "howWeWork": MessageLookupByLibrary.simpleMessage("Cómo trabajamos"),
    "ifYou": MessageLookupByLibrary.simpleMessage(
      "Si te uniste y ganaste el concurso, obtendrás 1.5x de puntos.",
    ),
    "iff": MessageLookupByLibrary.simpleMessage(
      "Si te uniste y ganaste el concurso, obtendrás 1.0x de puntos.",
    ),
    "ifscCode": MessageLookupByLibrary.simpleMessage("Código IFSC"),
    "inLessThanAMinute": MessageLookupByLibrary.simpleMessage(
      "en menos de un minuto",
    ),
    "inPlayingEleven": MessageLookupByLibrary.simpleMessage("Al jugar 11"),
    "inboxTab": MessageLookupByLibrary.simpleMessage("Bandeja"),
    "includesAperturaClausura": MessageLookupByLibrary.simpleMessage(
      "Incluye torneos Apertura + Clausura",
    ),
    "incomingTrades": MessageLookupByLibrary.simpleMessage(
      "Intercambios entrantes",
    ),
    "interceptionsWon": MessageLookupByLibrary.simpleMessage(
      "Intercepciones ganadas",
    ),
    "inviteCode": MessageLookupByLibrary.simpleMessage("Código de invitación"),
    "inviteCodeCopied": MessageLookupByLibrary.simpleMessage(
      "¡Código de invitación copiado!",
    ),
    "inviteOnly": MessageLookupByLibrary.simpleMessage("Solo por invitación"),
    "jerseyNumber": MessageLookupByLibrary.simpleMessage("Número de Camiseta"),
    "join": MessageLookupByLibrary.simpleMessage("Unirse"),
    "joinArrow": MessageLookupByLibrary.simpleMessage("Unirse →"),
    "joinDraftNow": MessageLookupByLibrary.simpleMessage(
      "Entrar al draft ahora",
    ),
    "joinLeague": MessageLookupByLibrary.simpleMessage("Unirse a la liga"),
    "joinLeagueOnFantasy11": m14,
    "joinPrivateLeague": MessageLookupByLibrary.simpleMessage(
      "Unirse a liga privada",
    ),
    "joinPrivateLeagueDescription": MessageLookupByLibrary.simpleMessage(
      "Ingresa el código de invitación que te compartieron para unirte a la liga privada.",
    ),
    "joinWithCode": MessageLookupByLibrary.simpleMessage("Unirse con código"),
    "joinedAContest": MessageLookupByLibrary.simpleMessage(
      "Se unió a un concurso",
    ),
    "joinedSuccessfullyTeamCreationOnDraftDay":
        MessageLookupByLibrary.simpleMessage(
          "Unido correctamente. La creación del equipo abre el día del draft.",
        ),
    "joinedSuccessfullyTeamCreationOpensOn": m15,
    "joinedWithTwoTeams": MessageLookupByLibrary.simpleMessage(
      "UNIDO A 2 EQUIPOS",
    ),
    "keyFactors": MessageLookupByLibrary.simpleMessage("Factores Clave"),
    "kg": MessageLookupByLibrary.simpleMessage("kg"),
    "knowOurPrivacyPolicies": MessageLookupByLibrary.simpleMessage(
      "Conozca nuestras Políticas de privacidad",
    ),
    "knowWhereYouStand": MessageLookupByLibrary.simpleMessage(
      "Sepa cuál es su posición en la competencia",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Idioma"),
    "last5Form": MessageLookupByLibrary.simpleMessage("Forma Últ. 5"),
    "lastMatchesPlus": m16,
    "lastNMatches": m17,
    "leaderboard": MessageLookupByLibrary.simpleMessage(
      "Tabla de clasificación",
    ),
    "leagueCreated": m18,
    "leagueDetails": MessageLookupByLibrary.simpleMessage(
      "Detalles de la liga",
    ),
    "leagueFound": MessageLookupByLibrary.simpleMessage("¡Liga encontrada!"),
    "leagueFull": MessageLookupByLibrary.simpleMessage("Liga llena"),
    "leagueMode": MessageLookupByLibrary.simpleMessage("Modo de liga"),
    "leagueName": MessageLookupByLibrary.simpleMessage("Nombre de la liga"),
    "leagueNoLongerAcceptingMembers": MessageLookupByLibrary.simpleMessage(
      "Esta liga ya no acepta miembros",
    ),
    "leagueNotFoundCheckInviteCode": MessageLookupByLibrary.simpleMessage(
      "Liga no encontrada. Revisa el código de invitación.",
    ),
    "leagueVisibility": MessageLookupByLibrary.simpleMessage(
      "Visibilidad de liga",
    ),
    "leagueVoteTitle": MessageLookupByLibrary.simpleMessage("Voto de la liga"),
    "leaguesTitle": MessageLookupByLibrary.simpleMessage(
      "Ligas paroNfantasyMx",
    ),
    "leaveLabel": MessageLookupByLibrary.simpleMessage("Salir"),
    "leaveLeagueConfirmation": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres salir de esta liga? Tu equipo será eliminado.",
    ),
    "leaveLeagueQuestion": MessageLookupByLibrary.simpleMessage(
      "¿Salir de la liga?",
    ),
    "leftLeagueMessage": MessageLookupByLibrary.simpleMessage(
      "Has salido de la liga",
    ),
    "letsPlay": MessageLookupByLibrary.simpleMessage("Vamos a jugar"),
    "level": MessageLookupByLibrary.simpleMessage("Nivel"),
    "linear": MessageLookupByLibrary.simpleMessage("Lineal"),
    "live": MessageLookupByLibrary.simpleMessage("EN VIVO"),
    "loadingNextMatch": MessageLookupByLibrary.simpleMessage(
      "Cargando próximo partido...",
    ),
    "loadingRecentStats": MessageLookupByLibrary.simpleMessage(
      "Cargando forma reciente...",
    ),
    "loadingTournamentStats": MessageLookupByLibrary.simpleMessage(
      "Cargando estadísticas del torneo...",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Cerrar sesión"),
    "low": MessageLookupByLibrary.simpleMessage("Baja"),
    "mailUs": MessageLookupByLibrary.simpleMessage("Envíenos un correo"),
    "matchCompleted": MessageLookupByLibrary.simpleMessage(
      "Partido completado",
    ),
    "matchLive": MessageLookupByLibrary.simpleMessage("Partido en vivo"),
    "matchTbd": MessageLookupByLibrary.simpleMessage("Partido por definir"),
    "matches": MessageLookupByLibrary.simpleMessage("partidos"),
    "matchup": MessageLookupByLibrary.simpleMessage("enfrentamiento"),
    "matchvs": MessageLookupByLibrary.simpleMessage("Partido - ALS vs CBR"),
    "maxContest": MessageLookupByLibrary.simpleMessage("Concurso máximo"),
    "maxMembers": MessageLookupByLibrary.simpleMessage("Máx. miembros"),
    "maxSevenPlayers": MessageLookupByLibrary.simpleMessage(
      "Max 7 jugadores de un equipo",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("Media"),
    "members": MessageLookupByLibrary.simpleMessage("Miembros"),
    "membersCount": m19,
    "messageOptional": MessageLookupByLibrary.simpleMessage(
      "Mensaje (opcional)",
    ),
    "midfielder": MessageLookupByLibrary.simpleMessage("Mediocampista"),
    "millionUsd": MessageLookupByLibrary.simpleMessage("Millones USD"),
    "minutes": MessageLookupByLibrary.simpleMessage("Minutos"),
    "minutesShort": m20,
    "multipleEntries": MessageLookupByLibrary.simpleMessage(
      "Múltiples entradas",
    ),
    "myContestsTwo": MessageLookupByLibrary.simpleMessage("MIS CONCURSOS (2)"),
    "myLeagues": MessageLookupByLibrary.simpleMessage("Mis Ligas"),
    "myMatches": MessageLookupByLibrary.simpleMessage("Mis Partidos"),
    "myProfile": MessageLookupByLibrary.simpleMessage("Mi perfil"),
    "myRosterTab": MessageLookupByLibrary.simpleMessage("Mi plantel"),
    "myTeamLabel": MessageLookupByLibrary.simpleMessage("Mi equipo"),
    "myTeamThree": MessageLookupByLibrary.simpleMessage("MI EQUIPO (3)"),
    "nMatches": m21,
    "nameMustBeAtLeast3Characters": MessageLookupByLibrary.simpleMessage(
      "El nombre debe tener al menos 3 caracteres",
    ),
    "nameYourTeam": MessageLookupByLibrary.simpleMessage("Nombra tu equipo"),
    "nationality": MessageLookupByLibrary.simpleMessage("Nacionalidad"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Próximo Partido"),
    "nextMatchupTitle": MessageLookupByLibrary.simpleMessage(
      "Próximo enfrentamiento",
    ),
    "nextOpponent": MessageLookupByLibrary.simpleMessage("Próximo rival"),
    "noDeadline": MessageLookupByLibrary.simpleMessage("Sin fecha límite"),
    "noLeaguesYet": MessageLookupByLibrary.simpleMessage("Aún no hay ligas"),
    "noMembersYet": MessageLookupByLibrary.simpleMessage("Aún no hay miembros"),
    "noOtherSportsAvailableContactAdmin": MessageLookupByLibrary.simpleMessage(
      "No hay otros deportes disponibles, comuníquese con el administrador",
    ),
    "noPendingTrades": MessageLookupByLibrary.simpleMessage(
      "No hay intercambios pendientes",
    ),
    "noPlayersFound": MessageLookupByLibrary.simpleMessage(
      "No se encontraron jugadores",
    ),
    "noPlayersFoundFor": m22,
    "noPlayersOnRoster": MessageLookupByLibrary.simpleMessage(
      "No hay jugadores en el plantel",
    ),
    "noPublicLeaguesAvailable": MessageLookupByLibrary.simpleMessage(
      "No hay ligas públicas disponibles",
    ),
    "noRecentStatsMessage": MessageLookupByLibrary.simpleMessage(
      "Este jugador no tiene estadísticas recientes en la liga mexicana en las últimas 6 semanas.",
    ),
    "noRecentStatsTitle": MessageLookupByLibrary.simpleMessage(
      "Sin Estadísticas Recientes",
    ),
    "noStandingsYet": MessageLookupByLibrary.simpleMessage(
      "Aún no hay posiciones",
    ),
    "noTeamYet": MessageLookupByLibrary.simpleMessage("Aún no hay equipo"),
    "noTeamsFound": MessageLookupByLibrary.simpleMessage(
      "No se encontraron equipos",
    ),
    "noTradeHistory": MessageLookupByLibrary.simpleMessage(
      "Sin historial de intercambios",
    ),
    "noTradeTargetsFound": MessageLookupByLibrary.simpleMessage(
      "No se encontraron objetivos de intercambio",
    ),
    "noTransactionsYet": MessageLookupByLibrary.simpleMessage(
      "Aún no hay movimientos",
    ),
    "now": MessageLookupByLibrary.simpleMessage("Ahora"),
    "orContinueWith": MessageLookupByLibrary.simpleMessage("O continuar con"),
    "outgoingTrades": MessageLookupByLibrary.simpleMessage(
      "Intercambios salientes",
    ),
    "overview": MessageLookupByLibrary.simpleMessage("Resumen"),
    "ownedBy": m23,
    "passesCompleted": MessageLookupByLibrary.simpleMessage(
      "Pases completados",
    ),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("Método de pago"),
    "phoneNumber": MessageLookupByLibrary.simpleMessage("Número de teléfono"),
    "pickStartersAndFormation": MessageLookupByLibrary.simpleMessage(
      "Elige titulares y formación",
    ),
    "pickTimer": MessageLookupByLibrary.simpleMessage("Temporizador de pick"),
    "playerAlreadyOnRoster": MessageLookupByLibrary.simpleMessage(
      "El jugador ya está en tu plantel",
    ),
    "playerDetails": MessageLookupByLibrary.simpleMessage(
      "Detalles del Jugador",
    ),
    "playerInfo": MessageLookupByLibrary.simpleMessage("Info del Jugador"),
    "playerLimitedPlaytime": MessageLookupByLibrary.simpleMessage(
      "Tiempo de juego limitado recientemente - puede estar lesionado o en banca",
    ),
    "playerNotFound": MessageLookupByLibrary.simpleMessage(
      "Jugador no encontrado",
    ),
    "playerNotOnSavedRoster": MessageLookupByLibrary.simpleMessage(
      "El jugador no está en tu plantel guardado",
    ),
    "players": MessageLookupByLibrary.simpleMessage("Jugadores"),
    "playersAndBudgetLeft": m24,
    "playersAndMoneyLeft": m25,
    "playersCountOfTotal": m26,
    "pleaseCompleteNameAndPhone": MessageLookupByLibrary.simpleMessage(
      "Por favor completa al menos nombre y teléfono",
    ),
    "pleaseEnterLeagueName": MessageLookupByLibrary.simpleMessage(
      "Por favor ingresa un nombre de liga",
    ),
    "pleaseEnterPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Por favor ingresa tu número de teléfono",
    ),
    "pleaseSetDraftDateAndTime": MessageLookupByLibrary.simpleMessage(
      "Por favor establece fecha y hora del draft",
    ),
    "pleaseWaitBeforeResending": m27,
    "plusMatchup": MessageLookupByLibrary.simpleMessage("+ enfrentamiento"),
    "point": MessageLookupByLibrary.simpleMessage("Punto"),
    "points": MessageLookupByLibrary.simpleMessage("Puntos"),
    "pointsAbbrev": m28,
    "pointsNext": m29,
    "pointsSeason": m30,
    "poor": MessageLookupByLibrary.simpleMessage("Pobre"),
    "position": MessageLookupByLibrary.simpleMessage("Posición"),
    "preferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Idioma preferido",
    ),
    "previousTeams": MessageLookupByLibrary.simpleMessage("Equipos Anteriores"),
    "priceLabel": MessageLookupByLibrary.simpleMessage("Precio"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidad",
    ),
    "privateLeague": MessageLookupByLibrary.simpleMessage("Privada"),
    "prizePool": MessageLookupByLibrary.simpleMessage("BOLSA DE PREMIOS"),
    "projectedPoints": MessageLookupByLibrary.simpleMessage(
      "Puntos proyectados",
    ),
    "projectedWinBy": m31,
    "projectionLabel": MessageLookupByLibrary.simpleMessage("proyección"),
    "proposeTab": MessageLookupByLibrary.simpleMessage("Proponer"),
    "proposeTradeAction": MessageLookupByLibrary.simpleMessage(
      "Proponer intercambio",
    ),
    "proposeTradeToGetStarted": MessageLookupByLibrary.simpleMessage(
      "Propón un intercambio para comenzar",
    ),
    "ptsShort": MessageLookupByLibrary.simpleMessage("pts"),
    "publicLeague": MessageLookupByLibrary.simpleMessage("Pública"),
    "publicLeagues": MessageLookupByLibrary.simpleMessage("Ligas públicas"),
    "quickDraftGuideSubtitle": MessageLookupByLibrary.simpleMessage(
      "Guía rápida para usuarios que vienen del modo clásico con presupuesto.",
    ),
    "range11to25": MessageLookupByLibrary.simpleMessage("11-25"),
    "range2to20": MessageLookupByLibrary.simpleMessage("2-20"),
    "range50to1000": MessageLookupByLibrary.simpleMessage("50-1000"),
    "rank": MessageLookupByLibrary.simpleMessage("Rango"),
    "rating": MessageLookupByLibrary.simpleMessage("Calificación"),
    "recentForm": MessageLookupByLibrary.simpleMessage("Forma Reciente"),
    "recentMatchStatus": MessageLookupByLibrary.simpleMessage(
      "Estado de coincidencia reciente",
    ),
    "recentPlayersTitle": MessageLookupByLibrary.simpleMessage(
      "Jugadores Recientes",
    ),
    "recentSearches": MessageLookupByLibrary.simpleMessage(
      "Búsquedas Recientes",
    ),
    "red": MessageLookupByLibrary.simpleMessage("Rojas"),
    "register": MessageLookupByLibrary.simpleMessage("Registrarse"),
    "rejectAction": MessageLookupByLibrary.simpleMessage("Rechazar"),
    "requestedPlayerSummary": m32,
    "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
    "riskyPick": MessageLookupByLibrary.simpleMessage("Riesgoso"),
    "role": MessageLookupByLibrary.simpleMessage("Rol"),
    "rosterCount": m33,
    "rosterFullDropPlayerToAdd": MessageLookupByLibrary.simpleMessage(
      "Plantel lleno - Suelta un jugador para agregar",
    ),
    "rosterIsFullSwapOrDropFirst": MessageLookupByLibrary.simpleMessage(
      "El plantel está lleno. Intercambia o suelta un jugador primero.",
    ),
    "rosterSize": MessageLookupByLibrary.simpleMessage("Tamaño de plantilla"),
    "ruleCaptainViceCaptainPoints": MessageLookupByLibrary.simpleMessage(
      "Capitán obtiene 2x puntos, vicecapitán 1.5x",
    ),
    "ruleMax4PlayersOneTeam": MessageLookupByLibrary.simpleMessage(
      "Máximo 4 jugadores de un mismo equipo",
    ),
    "ruleSelect18PlayersBudget": m34,
    "ruleSelect18PlayersDraft": MessageLookupByLibrary.simpleMessage(
      "Selecciona 18 jugadores (11 titulares + 7 suplentes) mediante el draft en vivo",
    ),
    "ruleSquad18Players": MessageLookupByLibrary.simpleMessage(
      "Plantel: 18 jugadores en total",
    ),
    "ruleTeamLocksWhenMatchStarts": MessageLookupByLibrary.simpleMessage(
      "El equipo se bloquea cuando inicia el partido",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Reglas"),
    "sameOrder": MessageLookupByLibrary.simpleMessage("Mismo orden"),
    "saveTeam": MessageLookupByLibrary.simpleMessage("Guardar equipo"),
    "saves": MessageLookupByLibrary.simpleMessage("Atajadas"),
    "saving": MessageLookupByLibrary.simpleMessage("Guardando..."),
    "searchByName": MessageLookupByLibrary.simpleMessage(
      "Buscar por nombre...",
    ),
    "searchCountryOrCode": MessageLookupByLibrary.simpleMessage(
      "Buscar país o código",
    ),
    "searchForPlayers": MessageLookupByLibrary.simpleMessage(
      "Buscar Jugadores",
    ),
    "searchHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Historial de búsqueda limpiado",
    ),
    "searchPlayers": MessageLookupByLibrary.simpleMessage("Buscar Jugadores"),
    "searchPlayersHint": MessageLookupByLibrary.simpleMessage(
      "Buscar jugadores por nombre...",
    ),
    "searchPlayersHintShort": MessageLookupByLibrary.simpleMessage(
      "Buscar jugadores...",
    ),
    "searchPlayersInOtherSquads": MessageLookupByLibrary.simpleMessage(
      "Busca jugadores en otros planteles...",
    ),
    "searchResultsTitle": MessageLookupByLibrary.simpleMessage(
      "Resultados de Búsqueda",
    ),
    "searching": MessageLookupByLibrary.simpleMessage("Buscando..."),
    "seasonAverages": MessageLookupByLibrary.simpleMessage(
      "Promedios de temporada",
    ),
    "seasonLabel": MessageLookupByLibrary.simpleMessage("Temporada"),
    "seedTradeMessage1": MessageLookupByLibrary.simpleMessage(
      "Necesito creatividad en mediocampo. ¿Te interesa un intercambio directo?",
    ),
    "seedTradeMessage2": MessageLookupByLibrary.simpleMessage(
      "Puedo sobrepagar en MED si puedes ceder profundidad defensiva.",
    ),
    "selBy": MessageLookupByLibrary.simpleMessage("Vender por"),
    "select": MessageLookupByLibrary.simpleMessage("Seleccione 3-5 defensor"),
    "selectBirthdate": MessageLookupByLibrary.simpleMessage(
      "Seleccionar fecha de nacimiento",
    ),
    "selectFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Selecciona Tu Equipo Favorito",
    ),
    "selectPlayerToDrop": MessageLookupByLibrary.simpleMessage(
      "Selecciona el jugador a soltar",
    ),
    "selectPreferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Seleccione el idioma preferido",
    ),
    "sendToBank": MessageLookupByLibrary.simpleMessage("Enviar al banco"),
    "setMatchReminder": MessageLookupByLibrary.simpleMessage(
      "Establecer recordatorio de partido",
    ),
    "setStarters": MessageLookupByLibrary.simpleMessage("Definir titulares"),
    "setYourPreferredLanguage": MessageLookupByLibrary.simpleMessage(
      "Establezca su idioma preferido",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Configuración"),
    "share": MessageLookupByLibrary.simpleMessage("Compartir"),
    "shareInvite": MessageLookupByLibrary.simpleMessage("Compartir invitación"),
    "shareInviteCodeWithFriends": MessageLookupByLibrary.simpleMessage(
      "Comparte el código de invitación con amigos para unirse",
    ),
    "shotsOnTarget": MessageLookupByLibrary.simpleMessage(
      "Disparos en el blanco",
    ),
    "singleEntry": MessageLookupByLibrary.simpleMessage("Sola entrada"),
    "snake": MessageLookupByLibrary.simpleMessage("Serpiente"),
    "snakeOrderExample": MessageLookupByLibrary.simpleMessage("1→10, 10→1..."),
    "spots": MessageLookupByLibrary.simpleMessage("lugares"),
    "spotsAvailable": m35,
    "spotsLeft": MessageLookupByLibrary.simpleMessage("lugares a la izquierda"),
    "stageStatistics": m36,
    "standings": MessageLookupByLibrary.simpleMessage("Clasificación"),
    "standingsAppearAfterMatchStarts": MessageLookupByLibrary.simpleMessage(
      "La tabla aparecerá cuando inicie el partido",
    ),
    "started": MessageLookupByLibrary.simpleMessage("Iniciado"),
    "startsInCountdown": m37,
    "startsInDaysHoursMinutes": m38,
    "statistics": MessageLookupByLibrary.simpleMessage("Estadísticas"),
    "stats": MessageLookupByLibrary.simpleMessage("Estadisticas"),
    "strongPick": MessageLookupByLibrary.simpleMessage("Fuerte"),
    "submit": MessageLookupByLibrary.simpleMessage("Entregar"),
    "substitute": MessageLookupByLibrary.simpleMessage("Sustituir"),
    "support": MessageLookupByLibrary.simpleMessage("Apoyo"),
    "swapAction": MessageLookupByLibrary.simpleMessage("Intercambiar"),
    "swapCompletedLocallyPersistFailed": MessageLookupByLibrary.simpleMessage(
      "Intercambio completado localmente, pero no se pudo persistir la actualización del plantel",
    ),
    "swappedPlayers": m39,
    "tackleWon": MessageLookupByLibrary.simpleMessage("Tackle ganado"),
    "tapToSelect": MessageLookupByLibrary.simpleMessage(
      "Toca para seleccionar",
    ),
    "tbd": MessageLookupByLibrary.simpleMessage("Por definir"),
    "team": MessageLookupByLibrary.simpleMessage("Equipo"),
    "teamBudget": MessageLookupByLibrary.simpleMessage(
      "Presupuesto del equipo",
    ),
    "teamCreated": MessageLookupByLibrary.simpleMessage("Equipo creado"),
    "teamCreatedThroughLiveDraftDescription":
        MessageLookupByLibrary.simpleMessage(
          "Tu equipo se crea mediante draft en vivo, no con el armador clásico.",
        ),
    "teamName": MessageLookupByLibrary.simpleMessage("Nombre del equipo"),
    "teamNameExampleHint": MessageLookupByLibrary.simpleMessage(
      "ej., Los Galácticos FC",
    ),
    "teamWillBeDraftedLive": MessageLookupByLibrary.simpleMessage(
      "Tu equipo se drafteará en vivo",
    ),
    "termsOfUse": MessageLookupByLibrary.simpleMessage("Términos de Uso"),
    "that": MessageLookupByLibrary.simpleMessage(
      "es decir, ganó 300 puntos x1.0 = 300 puntos",
    ),
    "thatIs": MessageLookupByLibrary.simpleMessage(
      "es decir, ganó 300 puntos x1,5 = 450 puntos",
    ),
    "thisLeagueIsFull": MessageLookupByLibrary.simpleMessage(
      "Esta liga está llena",
    ),
    "timePending": MessageLookupByLibrary.simpleMessage("Hora pendiente"),
    "toUser": m40,
    "tomorrow": MessageLookupByLibrary.simpleMessage("Mañana"),
    "tour": MessageLookupByLibrary.simpleMessage(
      "Tour - Fútbol Premier League",
    ),
    "tournamentStatistics": MessageLookupByLibrary.simpleMessage(
      "Estadísticas del Torneo",
    ),
    "tradeAccepted": MessageLookupByLibrary.simpleMessage(
      "Intercambio aceptado",
    ),
    "tradeApprovalCommissioner": MessageLookupByLibrary.simpleMessage(
      "Aprobación del comisionado",
    ),
    "tradeApprovalCommissionerDescription":
        MessageLookupByLibrary.simpleMessage(
          "El comisionado debe aprobar todos los intercambios",
        ),
    "tradeApprovalLeagueVote": MessageLookupByLibrary.simpleMessage(
      "Voto de la liga",
    ),
    "tradeApprovalLeagueVoteDescription": MessageLookupByLibrary.simpleMessage(
      "Los miembros de la liga votan los intercambios (gana mayoría)",
    ),
    "tradeApprovalNone": MessageLookupByLibrary.simpleMessage("Sin aprobación"),
    "tradeApprovalNoneDescription": MessageLookupByLibrary.simpleMessage(
      "Los intercambios se procesan inmediatamente",
    ),
    "tradeApprovalTitle": MessageLookupByLibrary.simpleMessage(
      "Aprobación de intercambio",
    ),
    "tradeCancelled": MessageLookupByLibrary.simpleMessage(
      "Intercambio cancelado",
    ),
    "tradeDeadline": m41,
    "tradeDeadlineHasPassed": MessageLookupByLibrary.simpleMessage(
      "La fecha límite de intercambios ya pasó",
    ),
    "tradeDeadlineOptional": MessageLookupByLibrary.simpleMessage(
      "Fecha límite de intercambios (Opcional)",
    ),
    "tradeProposedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Intercambio propuesto correctamente",
    ),
    "tradeRejected": MessageLookupByLibrary.simpleMessage(
      "Intercambio rechazado",
    ),
    "tradeSettings": MessageLookupByLibrary.simpleMessage(
      "Configuración de intercambios",
    ),
    "tradeStatusAccepted": MessageLookupByLibrary.simpleMessage("Aceptado"),
    "tradeStatusCancelled": MessageLookupByLibrary.simpleMessage("Cancelado"),
    "tradeStatusCompleted": MessageLookupByLibrary.simpleMessage("Completado"),
    "tradeStatusExpired": MessageLookupByLibrary.simpleMessage("Expirado"),
    "tradeStatusPending": MessageLookupByLibrary.simpleMessage("Pendiente"),
    "tradeStatusRejected": MessageLookupByLibrary.simpleMessage("Rechazado"),
    "tradeStatusVetoed": MessageLookupByLibrary.simpleMessage("Vetado"),
    "tradeTargetSubtitle": m42,
    "trades": MessageLookupByLibrary.simpleMessage("Intercambios"),
    "tradingClosed": MessageLookupByLibrary.simpleMessage(
      "Intercambios cerrados",
    ),
    "transactionsTab": MessageLookupByLibrary.simpleMessage("Movimientos"),
    "transferHistory": MessageLookupByLibrary.simpleMessage(
      "Historial de Transferencias",
    ),
    "transfers": MessageLookupByLibrary.simpleMessage("Transferencias"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Prueba con un término de búsqueda diferente",
    ),
    "type": MessageLookupByLibrary.simpleMessage("Escribe"),
    "uniqueOwnership": MessageLookupByLibrary.simpleMessage("Propiedad única"),
    "upcoming": MessageLookupByLibrary.simpleMessage("PRÓXIMAMENTE"),
    "upcomingMatches": MessageLookupByLibrary.simpleMessage(
      "Próximos partidos",
    ),
    "vcap": MessageLookupByLibrary.simpleMessage("v.cab"),
    "verification": MessageLookupByLibrary.simpleMessage("Verificación"),
    "verificationCodeResent": MessageLookupByLibrary.simpleMessage(
      "Código de verificación reenviado",
    ),
    "veryHigh": MessageLookupByLibrary.simpleMessage("Muy Alta"),
    "viewAdvancedStats": MessageLookupByLibrary.simpleMessage(
      "Ver Estadísticas Avanzadas",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("Ver todo"),
    "viewArrow": MessageLookupByLibrary.simpleMessage("Ver →"),
    "viewProfile": MessageLookupByLibrary.simpleMessage("Ver perfil"),
    "viewStatsDetails": MessageLookupByLibrary.simpleMessage(
      "Ver Detalles de Estadísticas",
    ),
    "voteAgainst": MessageLookupByLibrary.simpleMessage("En contra"),
    "voteAgainstAction": MessageLookupByLibrary.simpleMessage(
      "Votar en contra",
    ),
    "voteFor": MessageLookupByLibrary.simpleMessage("A favor"),
    "voteForAction": MessageLookupByLibrary.simpleMessage("Votar a favor"),
    "voteRecorded": m43,
    "vs": MessageLookupByLibrary.simpleMessage("vs"),
    "vsUpper": MessageLookupByLibrary.simpleMessage("VS"),
    "waitingForDraftStart": MessageLookupByLibrary.simpleMessage(
      "Esperando inicio del draft",
    ),
    "waitingForOpponent": MessageLookupByLibrary.simpleMessage(
      "Esperando rival",
    ),
    "waitingForOpponentEllipsis": MessageLookupByLibrary.simpleMessage(
      "Esperando rival...",
    ),
    "wallet": MessageLookupByLibrary.simpleMessage("Cartera"),
    "weHaveSent": MessageLookupByLibrary.simpleMessage(
      "Hemos enviado un código de verificación de 6 dígitos.",
    ),
    "weWillSendVerificationCode": MessageLookupByLibrary.simpleMessage(
      "Enviaremos el código de verificación.",
    ),
    "weight": MessageLookupByLibrary.simpleMessage("Peso"),
    "welcomeToLeagueTeamReady": m44,
    "whereWeAreAnd": MessageLookupByLibrary.simpleMessage(
      "Dónde estamos y cómo empezamos",
    ),
    "whoWeAre": MessageLookupByLibrary.simpleMessage("¿Quienes somos?"),
    "willSend": MessageLookupByLibrary.simpleMessage(
      "Enviará un recordatorio cuando se anuncie la alineación",
    ),
    "winnings": MessageLookupByLibrary.simpleMessage("Ganancias"),
    "wonAContest": MessageLookupByLibrary.simpleMessage("Ganó un concurso"),
    "writeUs": MessageLookupByLibrary.simpleMessage("Escribenos"),
    "writeYourMessage": MessageLookupByLibrary.simpleMessage(
      "escribe tu mensaje",
    ),
    "yearsOld": MessageLookupByLibrary.simpleMessage("años"),
    "yellow": MessageLookupByLibrary.simpleMessage("Amarillas"),
    "youAlreadyVoted": MessageLookupByLibrary.simpleMessage("Ya votaste"),
    "youAre": MessageLookupByLibrary.simpleMessage("Estás en el nivel 89"),
    "youCannotVoteOwnTrade": MessageLookupByLibrary.simpleMessage(
      "No puedes votar tu propio intercambio",
    ),
    "youGive": MessageLookupByLibrary.simpleMessage("Entregas:"),
    "youLabel": MessageLookupByLibrary.simpleMessage("Tú"),
    "youReceive": MessageLookupByLibrary.simpleMessage("Recibes:"),
    "youUpper": MessageLookupByLibrary.simpleMessage("TÚ"),
    "youWillGet": MessageLookupByLibrary.simpleMessage(
      "Obtendrás 10 puntos más en cada partida paga a la que te unas",
    ),
    "yourFavoriteTeam": MessageLookupByLibrary.simpleMessage(
      "Tu Equipo Favorito",
    ),
    "yourPredictedPoints": MessageLookupByLibrary.simpleMessage(
      "Tus puntos proyectados",
    ),
  };
}
