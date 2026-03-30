import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/twilio_sms_service.dart';
import 'sms_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => ConversationListScreenState();
}

class ConversationListScreenState extends State<ConversationListScreen> {
  // Mutable list — add more contacts via + button
  final List<Contact> _contacts = [
    const Contact(name: '+12708170271', number: '+12708170271'),
  ];

  final Map<String, _ConvPreview> _previews = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadPreviews();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _loadPreviews());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreviews() async {
    for (final contact in List<Contact>.from(_contacts)) {
      try {
        final msgs = await TwilioSmsService.fetchMessages(contact.number);
        if (!mounted) return;
        if (msgs.isNotEmpty) {
          final last = msgs.last;
          setState(() {
            _previews[contact.number] = _ConvPreview(
              text: last.body,
              time: last.timestamp,
              isMe: last.isMe,
            );
          });
        }
      } catch (_) {}
    }
  }

  void openAddContact() {
    final nameCtrl   = TextEditingController();
    final numberCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (+1XXXXXXXXXX)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final number = numberCtrl.text.trim();
              final name   = nameCtrl.text.trim().isEmpty
                  ? number
                  : nameCtrl.text.trim();
              if (number.isNotEmpty) {
                setState(() {
                  _contacts.add(Contact(name: name, number: number));
                });
                Navigator.pop(ctx);
                _loadPreviews();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts yet.\nTap + to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _contacts.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final preview = _previews[contact.number];
        return _ConversationTile(
          contact: contact,
          preview: preview,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SmsScreen(contact: contact)),
          ),
        );
      },
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Contact contact;
  final _ConvPreview? preview;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.contact,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: scheme.primary,
        child: Text(
          contact.initials,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      title: Text(
        contact.name,
        style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: preview == null
          ? Text(contact.number,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13))
          : Row(
              children: [
                if (preview!.isMe)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.done_all,
                        size: 14, color: Colors.blue),
                  ),
                Expanded(
                  child: Text(
                    preview!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
      trailing: preview == null
          ? null
          : Text(
              _formatTime(preview!.time),
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final local   = dt.toLocal();
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final msgDay  = DateTime(local.year, local.month, local.day);

    if (msgDay == today) {
      final h    = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final m    = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May',
      'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[local.month - 1]} ${local.day}';
  }
}

class _ConvPreview {
  final String text;
  final DateTime time;
  final bool isMe;
  const _ConvPreview(
      {required this.text, required this.time, required this.isMe});
}
