import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// Image links. //

const String calendarImage = 'assets/ui_elements/calendar-icon.png';

const String refreshIcon = 'assets/ui_elements/refresh-icon.png';

const String greyScannerSquare = 'assets/ui_elements/grey-scanner-square.png';

const String redScannerSquare = 'assets/ui_elements/red-scanner-square.png';

const String greenScannerSquare = 'assets/ui_elements/green-scanner-square.png';

const String transferPendingImage = 'assets/ui_elements/transfer-pending-image.png';


// Theme formatting. //

final int primaryColor = 0xFFFF0266;

final int primaryColorDark = 0xFFC5003C;

final int textGrey = 0xFF7E7E7E;

final int formInputColor = 0xFFF2F2F2;

const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(8.0));

// Scanner constants. //

const Duration scannerShutdownDuration = Duration(seconds: 1);

// Date string formatting. //

final dateFormatShortMonth = DateFormat('MMM');

final dateFormatTime = DateFormat('jm');