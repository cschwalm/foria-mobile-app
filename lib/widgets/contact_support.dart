import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:foria/utils/message_stream.dart';
import 'package:foria/utils/strings.dart';
import 'package:get_it/get_it.dart';

Future<void> contactSupport() async {
  final MessageStream messageStream = GetIt.instance<MessageStream>();

  final Email email = Email(
    subject: supportEmailSubject,
    recipients: [supportEmailAddress],
  );

  try {
    await FlutterEmailSender.send(email);
    messageStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, supportEmailSent, null));
  } catch (error) {
    messageStream.announceMessage(ForiaNotification.message(MessageType.MESSAGE, supportEmailFailed, null));
  }
}
