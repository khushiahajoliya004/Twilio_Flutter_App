import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/twilio_sms_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sidController = TextEditingController();
  final _tokenController = TextEditingController();
  final _numberController = TextEditingController();
  final _accessTokenController = TextEditingController();

  bool _obscureToken = true;
  bool _obscureAccessToken = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _sidController.text    = TwilioSmsService.accountSid;
    _tokenController.text  = TwilioSmsService.authToken;
    _numberController.text = TwilioSmsService.twilioNumber;
    _accessTokenController.text = prefs.getString('access_token') ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_sid', _sidController.text.trim());
    await prefs.setString('auth_token', _tokenController.text.trim());
    await prefs.setString('twilio_number', _numberController.text.trim());
    await prefs.setString('access_token', _accessTokenController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sidController.dispose();
    _tokenController.dispose();
    _numberController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Twilio Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: 'SMS Credentials', icon: Icons.sms),
            const SizedBox(height: 12),
            _buildField(
              controller: _sidController,
              label: 'Account SID',
              hint: 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              icon: Icons.account_circle_outlined,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _tokenController,
              label: 'Auth Token',
              hint: 'Your Twilio Auth Token',
              icon: Icons.lock_outline,
              obscure: _obscureToken,
              onToggleObscure: () => setState(() => _obscureToken = !_obscureToken),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _numberController,
              label: 'Twilio Phone Number',
              hint: '+1234567890',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Voice Credentials', icon: Icons.call),
            const SizedBox(height: 4),
            const Text(
              'Generate an Access Token from your backend server using the Twilio Voice SDK.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _accessTokenController,
              label: 'Voice Access Token',
              hint: 'JWT token from your backend',
              icon: Icons.vpn_key_outlined,
              obscure: _obscureAccessToken,
              onToggleObscure: () => setState(() => _obscureAccessToken = !_obscureAccessToken),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const _HelpCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF22F46)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 6),
              Text('How to get credentials', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ]),
            SizedBox(height: 8),
            Text('1. Sign up at twilio.com', style: TextStyle(fontSize: 12)),
            Text('2. Copy Account SID & Auth Token from the Console', style: TextStyle(fontSize: 12)),
            Text('3. Get a Twilio phone number', style: TextStyle(fontSize: 12)),
            Text('4. Generate a Voice Access Token from your backend', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
