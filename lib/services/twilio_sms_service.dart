import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  final String sid;
  final String body;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.sid,
    required this.body,
    required this.isMe,
    required this.timestamp,
  });
}

class TwilioSmsService {
  static const String accountSid = 'AC6ed268c11382fe7b7af829468d3f106e';
  static const String authToken  = '3c6c2b8c03f47df5fb8d8db0d306fbd5';
  static const String twilioNumber = '+18559054543';

  static String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}';

  static Map<String, String> get _headers => {'Authorization': _authHeader};

  /// Send SMS from Twilio number to [toNumber]
  static Future<http.Response> sendSms({
    required String toNumber,
    required String message,
  }) {
    return http.post(
      Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
      headers: {
        'Authorization': _authHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': twilioNumber,
        'To': toNumber,
        'Body': message,
      },
    );
  }

  /// Fetch sent + received messages with [contactNumber], sorted oldest→newest
  static Future<List<ChatMessage>> fetchMessages(String contactNumber) async {
    final sentUrl = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'
      '?From=$twilioNumber&To=$contactNumber&PageSize=50',
    );
    final receivedUrl = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'
      '?From=$contactNumber&To=$twilioNumber&PageSize=50',
    );

    final results = await Future.wait([
      http.get(sentUrl, headers: _headers),
      http.get(receivedUrl, headers: _headers),
    ]);

    final List<ChatMessage> messages = [];
    for (int i = 0; i < results.length; i++) {
      if (results[i].statusCode == 200) {
        final data = jsonDecode(results[i].body);
        for (final msg in data['messages'] as List) {
          final dateStr = (msg['date_sent'] ?? msg['date_created']) as String;
          messages.add(ChatMessage(
            sid: msg['sid'],
            body: msg['body'],
            isMe: i == 0, // 0 = sent by us, 1 = received
            timestamp: DateTime.parse(dateStr),
          ));
        }
      }
    }

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
}
