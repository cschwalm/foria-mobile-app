import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// Image links. //

const String calendarImage = 'assets/ui_elements/calendar-icon.png';

const String refreshIcon = 'assets/ui_elements/refresh-icon.png';

const String scanButton = 'assets/ui_elements/scan-button.png';

const String greyScannerSquare = 'assets/ui_elements/grey-scanner-square.png';

const String redScannerSquare = 'assets/ui_elements/red-scanner-square.png';

const String greenScannerSquare = 'assets/ui_elements/green-scanner-square.png';

const String transferPendingImage = 'assets/ui_elements/transfer-pending-image.png';

const String introQrGif = 'assets/ui_elements/intro_qr_gif.gif';

const String introTransferImage = 'assets/ui_elements/intro-transfer-image.jpg';

// Theme formatting. //

const Color constPrimaryLight = Color(0xFFFF69B4);

const Color constPrimaryColor = Color(0xFFFF0266);

const Color constPrimaryColorDark = Color(0xFFC5003C);

const Color settingsBackgroundColor = Color(0xffEEEEEE);

const Color textGreyColor = Color(0xFF7E7E7E);

const Color formInputColor = Color(0xFFF2F2F2);

const Color snackbarColor = Color(0xFF313131);

const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(8.0));

const SizedBox sizedBoxH3 = SizedBox(height: 3);

// Scanner constants. //

const Duration scannerShutdownDuration = Duration(seconds: 1);

// Date string formatting. //

final dateFormatDay = DateFormat('E, MMMM d');

final dateFormatShortDay = DateFormat('E');

final dateFormatLongMonth = DateFormat('MMMM');

final dateFormatShortMonth = DateFormat('MMM');

final dateFormatTime = DateFormat('jm');

// Sentry DSN //
const String sentryDsn = 'https://6c60214971cd4a2f914ebac3a233155d@sentry.io/1729721';

// TextStyle //

const TextStyle foriaBodyTwo = TextStyle(fontSize: 14.0, color: constPrimaryColor);

// Platform Channel //
const String screenshotAction = 'SCREENSHOT_TAKEN';