import 'package:intl/intl.dart';

// Theme formatting. //

final int primaryColor = 0xFFFF0266;

final int primaryColorDark = 0xFFC5003C;

final int textGrey = 0xFF7E7E7E;

// Date string formatting. //

final dateFormatShortMonth = DateFormat('MMM');

final dateFormatTime = DateFormat('jm');

// General purpose strings. //

const String textTransfer = 'Transfer';

const String textLogout = 'Logout';

const String googleMapsSearchUrl = 'https://www.google.com/maps/search/?api=1&query=';

const String textCancel = 'Cancel';

// Venue related strings. //

const String venueAccount = 'Venue Account';

const String scanTickets = 'Scan Tickets';

const String scanToRedeemTitle = 'Ready To Scan';

// Auth0 strings. //

const String loginRegister = 'Sign Up / Sign In';

const String loginError = "There was an issue logging into your account. " +
    "Please check your internet connection and try again. " +
    "If the issue continues, contact support listed in the app store.";

const String emailConfirmationRequired = 'Email Confirmation Required';

const String pleaseConfirmEmail = 'Please check your email for an email confirmation request. Once completed you\'ll be able to log in.';

const String iveConfirmedEmail = 'I\'ve confirmed my email';

// Contact Us Strings. //

const String contactUs = 'Contact Us';

const String FAQ = 'FAQ';

const String FAQUrl = "https://foriatickets.com/contact-us.html";

const String supportEmailAddress = "support@foriatickets.com";

const String supportEmailSubject = "Foria Support";

// my_passes_tab Strings. //

const String noEvents = 'You don\'t have any \nupcoming events';

const String noTickets = 'If you can\'t find your tickets, \nplease first check '
    'your \nemail order confirmation \n pulldown to refresh your tickets.';

const String otherwiseContact = 'Otherwise, Contact Us';

const String activeOnAnotherDevice = 'Your tickets are active on \nanother device';

const String toAccessTickets = 'To access your tickets, you must deactivate them '
    'from the other device and relocate your tickets';

const String relocateTickets = 'Relocate Tickets';

const String refreshTickets = 'Refresh';

const String imageUnavailable = 'Image unavailable';

const String ticketLoadingFailure = 'It looks like you\'re currently offline.\n\n'
    'Don\'t worry, we\'re using an offline copy of your tickets. As long as you haven\'t transferred or sold your tickets, they will be valid.';

// selected_ticket_screen Strings. //

const String foriaPass ='Foria Pass';

const String passRefresh ='Your pass refreshes in  ';

const String passOptions = 'Pass Options';

const String directionsText = 'Directions';

const String barcodeLoading = 'Barcode Loading...';

const String transferConfirm = 'Confirm Transfer';

const String transferWarning = 'Transfers are non-reversible and processed immediately if the transferee has a Foria account. Otherwise, they are processed once the transferee creates an account.';

// ticket_scan_screen Strings. //

const String passValid = 'Valid Pass';

const String passInvalid = 'Invalid Pass';

const String passInvalidInfo = 'Pass already redeemed or transferred';

const String barcodeInvalid = 'Invalid Barcode';

const String barcodeInvalidInfo = 'Not a foria pass';