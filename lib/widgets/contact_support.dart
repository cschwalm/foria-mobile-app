import 'package:flutter_email_sender/flutter_email_sender.dart';

Future<void> contactSupport() async {
  final Email email = Email(
    subject: 'Foria Support',
    recipients: ['info@foriatickets.com'],
  );

  await FlutterEmailSender.send(email);
}
