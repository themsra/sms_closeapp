import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/telegram_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController botTokenController = TextEditingController();
  final TextEditingController chatIdController = TextEditingController();

  bool obscureToken = true;
  bool testing = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    botTokenController.text = prefs.getString('bot_token') ?? '';
    chatIdController.text = prefs.getString('chat_id') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> saveValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bot_token', botTokenController.text.trim());
    await prefs.setString('chat_id', chatIdController.text.trim());
  }

  Future<void> saveSettings() async {
    await saveValues();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات با موفقیت ذخیره شد')),
    );
  }

  Future<void> testTelegram() async {
    if (botTokenController.text.trim().isEmpty ||
        chatIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bot Token و Chat ID را وارد کنید')),
      );
      return;
    }

    setState(() => testing = true);
    await saveValues();
    final ok = await TelegramService.sendMessage(
      '✅ تست اتصال موفق بود.\nاپلیکیشن پیام پشتیبان به تلگرام متصل است.',
    );
    if (!mounted) return;
    setState(() => testing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'ارسال موفق بود؛ ربات پیام را دریافت کرد.'
              : 'ارسال ناموفق بود؛ Token و Chat ID را بررسی کنید.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    botTokenController.dispose();
    chatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings),
          SizedBox(width: 10),
          Text('تنظیمات'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: botTokenController,
              obscureText: obscureToken,
              decoration: InputDecoration(
                labelText: 'Bot Token',
                hintText: 'توکن ربات تلگرام',
                prefixIcon: const Icon(Icons.smart_toy),
                suffixIcon: IconButton(
                  icon: Icon(obscureToken ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscureToken = !obscureToken),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: chatIdController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Chat ID',
                hintText: 'شناسه چت تلگرام',
                prefixIcon: Icon(Icons.chat),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: testing ? null : () => Navigator.of(context).pop(),
          child: const Text('لغو'),
        ),
        OutlinedButton.icon(
          onPressed: testing ? null : testTelegram,
          icon: testing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('تست'),
        ),
        FilledButton.icon(
          onPressed: testing ? null : saveSettings,
          icon: const Icon(Icons.save),
          label: const Text('ذخیره'),
        ),
      ],
    );
  }
}
