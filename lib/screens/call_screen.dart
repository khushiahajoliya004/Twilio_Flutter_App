import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/call_provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _toController = TextEditingController();
  bool _voiceReady = false;
  String _fromNumber = '';

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final from = prefs.getString('twilio_number') ?? '';
    setState(() => _fromNumber = from);

    if (token.isNotEmpty) {
      if (!mounted) return;
      final provider = context.read<CallProvider>();
      final result = await provider.initVoice(token);
      if (!mounted) return;
      setState(() => _voiceReady = result);
    }
  }

  Future<void> _makeCall() async {
    if (!_voiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice not ready. Check access token in Settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_toController.text.isEmpty) return;
    await context.read<CallProvider>().makeCall(
          _toController.text.trim(),
          _fromNumber,
        );
  }

  @override
  void dispose() {
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        if (call.callState == CallState.incoming) {
          return _IncomingCallWidget(
            from: call.activeNumber,
            onAnswer: () => call.answer(),
            onReject: () => call.reject(),
          );
        }

        if (call.isInCall) {
          return _ActiveCallWidget(
            number: call.activeNumber,
            callState: call.callState,
            isMuted: call.isMuted,
            isSpeaker: call.isSpeaker,
            onHangUp: () => call.hangUp(),
            onToggleMute: () => call.toggleMute(),
            onToggleSpeaker: () => call.toggleSpeaker(),
            onDigit: (d) => call.sendDigits(d),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_voiceReady)
                MaterialBanner(
                  content: const Text('Voice access token not set. Go to Settings.'),
                  backgroundColor: Colors.orange.shade100,
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings').then((_) => _initVoice()),
                      child: const Text('SETTINGS'),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _toController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'To (e.g. +1234567890 or client:name)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _makeCall,
                icon: const Icon(Icons.call),
                label: const Text('Make Call'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.call_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Ready to make calls', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text(
                      'Enter a phone number or client name above',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Active Call UI ──────────────────────────────────────────────────────────

class _ActiveCallWidget extends StatefulWidget {
  const _ActiveCallWidget({
    required this.number,
    required this.callState,
    required this.isMuted,
    required this.isSpeaker,
    required this.onHangUp,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onDigit,
  });

  final String number;
  final CallState callState;
  final bool isMuted;
  final bool isSpeaker;
  final VoidCallback onHangUp;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final void Function(String) onDigit;

  @override
  State<_ActiveCallWidget> createState() => _ActiveCallWidgetState();
}

class _ActiveCallWidgetState extends State<_ActiveCallWidget> {
  bool _showDialpad = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFF22F46),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.callState == CallState.calling ? 'Calling...' : 'Connected',
              style: TextStyle(
                color: widget.callState == CallState.connected ? Colors.greenAccent : Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (_showDialpad) ...[
              _Dialpad(onDigit: widget.onDigit),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: widget.isMuted ? Icons.mic_off : Icons.mic,
                  label: widget.isMuted ? 'Unmute' : 'Mute',
                  color: widget.isMuted ? Colors.red : Colors.white24,
                  onTap: widget.onToggleMute,
                ),
                _CallButton(
                  icon: Icons.dialpad,
                  label: 'Keypad',
                  color: _showDialpad ? Colors.blue : Colors.white24,
                  onTap: () => setState(() => _showDialpad = !_showDialpad),
                ),
                _CallButton(
                  icon: widget.isSpeaker ? Icons.volume_up : Icons.volume_down,
                  label: 'Speaker',
                  color: widget.isSpeaker ? Colors.blue : Colors.white24,
                  onTap: widget.onToggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: widget.onHangUp,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Dialpad ─────────────────────────────────────────────────────────────────

class _Dialpad extends StatelessWidget {
  const _Dialpad({required this.onDigit});

  final void Function(String) onDigit;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '#'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((digit) {
            return TextButton(
              onPressed: () => onDigit(digit),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white12,
                minimumSize: const Size(72, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(digit, style: const TextStyle(fontSize: 20)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ── Incoming Call UI ─────────────────────────────────────────────────────────

class _IncomingCallWidget extends StatelessWidget {
  const _IncomingCallWidget({
    required this.from,
    required this.onAnswer,
    required this.onReject,
  });

  final String from;
  final VoidCallback onAnswer;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text('Incoming Call', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFF22F46),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(from, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onReject,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Decline', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onAnswer,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.call, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Answer', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
