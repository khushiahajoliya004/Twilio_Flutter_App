import 'package:twilio_voice/twilio_voice.dart';
import 'package:permission_handler/permission_handler.dart';

class TwilioVoiceService {
  static final TwilioVoiceService _instance = TwilioVoiceService._internal();
  factory TwilioVoiceService() => _instance;
  TwilioVoiceService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Request microphone permission then register the device with
  /// the Twilio access token obtained from your backend.
  Future<bool> init(String accessToken) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return false;

    await TwilioVoice.instance.setTokens(
      accessToken: accessToken,
      deviceToken: 'device-token', // replaced by FCM/APNs token in production
    );

    _isInitialized = true;
    return true;
  }

  /// Register call-event listeners
  void registerCallListeners({
    required void Function() onCallConnected,
    required void Function() onCallDisconnected,
    required void Function(String error) onCallFailed,
    required void Function(String from, String to) onIncomingCall,
  }) {
    TwilioVoice.instance.callEventsListener.listen((event) {
      switch (event) {
        case CallEvent.connected:
          onCallConnected();
          break;
        case CallEvent.callEnded:
        case CallEvent.declined:
        case CallEvent.missedCall:
          onCallDisconnected();
          break;
        default:
          break;
      }
    });

    // Register this client so incoming calls display a name
    TwilioVoice.instance.registerClient('flutter_user', 'Flutter User');
  }

  /// Place an outbound call
  Future<void> makeCall(String to, String from) async {
    if (!_isInitialized) {
      throw Exception('TwilioVoiceService not initialized. Set credentials first.');
    }
    await TwilioVoice.instance.call.place(to: to, from: from);
  }

  /// Hang up the active call
  Future<void> hangUp() async {
    await TwilioVoice.instance.call.hangUp();
  }

  /// Toggle mute on active call
  Future<void> toggleMute(bool muted) async {
    await TwilioVoice.instance.call.toggleMute(muted);
  }

  /// Toggle speaker on active call
  Future<void> toggleSpeaker(bool speaker) async {
    await TwilioVoice.instance.call.toggleSpeaker(speaker);
  }

  /// Answer incoming call
  Future<void> answer() async {
    await TwilioVoice.instance.call.answer();
  }

  /// Reject incoming call
  Future<void> reject() async {
    await TwilioVoice.instance.call.hangUp();
  }

  /// Send DTMF digits during call
  Future<void> sendDigits(String digit) async {
    await TwilioVoice.instance.call.sendDigits(digit);
  }
}
