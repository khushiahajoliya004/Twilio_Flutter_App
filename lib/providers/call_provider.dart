import 'package:flutter/material.dart';
import '../services/twilio_voice_service.dart';

enum CallState { idle, calling, connected, incoming }

class CallProvider extends ChangeNotifier {
  final TwilioVoiceService _voiceService = TwilioVoiceService();

  CallState _callState = CallState.idle;
  bool _isMuted = false;
  bool _isSpeaker = false;
  String _activeNumber = '';

  CallState get callState => _callState;
  bool get isMuted => _isMuted;
  bool get isSpeaker => _isSpeaker;
  String get activeNumber => _activeNumber;
  bool get isInCall => _callState == CallState.connected || _callState == CallState.calling;

  Future<bool> initVoice(String accessToken) async {
    final result = await _voiceService.init(accessToken);
    if (result) {
      _voiceService.registerCallListeners(
        onCallConnected: () {
          _callState = CallState.connected;
          notifyListeners();
        },
        onCallDisconnected: () {
          _callState = CallState.idle;
          _isMuted = false;
          _isSpeaker = false;
          _activeNumber = '';
          notifyListeners();
        },
        onCallFailed: (error) {
          _callState = CallState.idle;
          notifyListeners();
        },
        onIncomingCall: (from, to) {
          _callState = CallState.incoming;
          _activeNumber = from;
          notifyListeners();
        },
      );
    }
    return result;
  }

  Future<void> makeCall(String to, String from) async {
    _activeNumber = to;
    _callState = CallState.calling;
    notifyListeners();
    await _voiceService.makeCall(to, from);
  }

  Future<void> hangUp() async {
    await _voiceService.hangUp();
    _callState = CallState.idle;
    _isMuted = false;
    _isSpeaker = false;
    _activeNumber = '';
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _voiceService.toggleMute(_isMuted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    _isSpeaker = !_isSpeaker;
    await _voiceService.toggleSpeaker(_isSpeaker);
    notifyListeners();
  }

  Future<void> answer() async {
    await _voiceService.answer();
    _callState = CallState.connected;
    notifyListeners();
  }

  Future<void> reject() async {
    await _voiceService.reject();
    _callState = CallState.idle;
    notifyListeners();
  }

  Future<void> sendDigits(String digit) async {
    await _voiceService.sendDigits(digit);
  }
}
