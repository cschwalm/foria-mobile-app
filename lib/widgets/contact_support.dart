import 'package:flutter_email_sender/flutter_email_sender.dart';

import 'package:foria/utils/strings.dart';

Future<void> contactSupport() async {
  final Email email = Email(
    subject: supportEmailSubject,
    recipients: [supportEmailAddress],
  );

  await FlutterEmailSender.send(email);
}
