import 'package:flutter/material.dart';

import 'models/log_entry.dart';
import 'services/log_service.dart';
import 'services/sms_service.dart';
import 'services/telegram/telegram_bot_service.dart';
import 'widgets/settings_dialog.dart';
import 'screens/storage_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmsBackupApp());
}

class SmsBackupApp extends StatelessWidget {
  const SmsBackupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MSRA',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsService smsService = SmsService();
  final LogService logService = LogService();
  final TelegramBotService telegramBotService = TelegramBotService();

  bool serviceEnabled = false;
  bool requestingPermission = false;

  List<LogEntry> logs = [];

  @override
  void initState() {
    super.initState();
    loadLogs();
    telegramBotService.start();
  }

  Future<void> loadLogs() async {
    final savedLogs = await logService.getLogs();

    if (!mounted) return;

    setState(() {
      logs = savedLogs;
    });
  }

  Future<void> enableSmsService() async {
    if (requestingPermission) return;

    setState(() {
      requestingPermission = true;
    });

    try {
      final granted = await smsService.requestPermissions();

      if (!granted) {
        if (!mounted) return;

        setState(() {
          serviceEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مجوز SMS داده نشد'),
          ),
        );

        return;
      }

      smsService.startListening(
        onMessage: handleIncomingSms,
      );

      if (!mounted) return;

      setState(() {
        serviceEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دریافت پیامک فعال شد'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          requestingPermission = false;
        });
      }
    }
  }

  Future<void> handleIncomingSms(
      String sender,
      String message,
      ) async {
    await logService.addLog(
      sender: sender,
      message: message,
    );

    await loadLogs();
  }

  Future<void> toggleService(bool value) async {
    if (value) {
      await enableSmsService();
    } else {
      setState(() {
        serviceEnabled = false;
      });
    }
  }

  void openSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return const SettingsDialog();
      },
    );
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  void dispose() {
    telegramBotService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'پیام پشتیبان',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StorageScreen()),
                );
              },
              icon: const Icon(Icons.folder_copy_outlined),
              tooltip: 'گالری و فایل‌ها',
            ),
            IconButton(
              onPressed: openSettings,
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sms_outlined,
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'وضعیت سرویس',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: serviceEnabled,
                          onChanged: requestingPermission
                              ? null
                              : toggleService,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (requestingPermission)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'پیام‌های اخیر',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: logs.isEmpty
                      ? Card(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 50,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'هنوز پیامی دریافت نشده',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.sms),
                          ),
                          title: Text(
                            log.sender,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            log.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            formatTime(log.time),
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}