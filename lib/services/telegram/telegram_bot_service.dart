import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import 'telegram_file_service.dart';

/// Handles Telegram commands for the authorized chat only.
///
/// The app must be running for polling to work. Android background execution
/// can be added later with an explicit foreground/background service.
class TelegramBotService {
  Timer? _timer;
  int _offset = 0;

  final TelegramFileService _fileService = TelegramFileService();

  // Short-lived maps keep Telegram callback_data below its size limit.
  final Map<String, AssetPathEntity> _folders = {};
  final Map<String, AssetEntity> _assets = {};

  Future<void> start({
    Duration interval = const Duration(seconds: 3),
  }) async {
    await stop();
    _timer = Timer.periodic(interval, (_) => pollOnce());
    await pollOnce();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('bot_token') ?? Config.botToken).trim();
  }

  Future<String> _chatId() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('chat_id') ?? Config.chatId).trim();
  }

  Future<void> pollOnce() async {
    final token = await _token();
    if (token.isEmpty) return;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$token/getUpdates'
      '?timeout=0&offset=$_offset&allowed_updates=${Uri.encodeComponent(jsonEncode(['message', 'callback_query']))}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data is! Map || data['ok'] != true) return;

      final updates = data['result'];
      if (updates is! List) return;

      for (final raw in updates) {
        if (raw is! Map) continue;

        final updateId = raw['update_id'];
        if (updateId is int) {
          _offset = updateId + 1;
        }

        final callback = raw['callback_query'];
        if (callback is Map) {
          await _handleCallback(callback);
          continue;
        }

        final message = raw['message'];
        if (message is Map) {
          await _handleMessage(message);
        }
      }
    } catch (_) {
      // Keep polling. A temporary network failure must not stop the service.
    }
  }

  Future<bool> _isAuthorized(String incomingChatId) async {
    final configured = await _chatId();
    return configured.isNotEmpty && incomingChatId == configured;
  }

  String _chatIdFromMessage(Map message) {
    final chat = message['chat'];
    if (chat is Map) {
      return '${chat['id'] ?? ''}';
    }
    return '';
  }

  Future<void> _handleMessage(Map message) async {
    final chatId = _chatIdFromMessage(message);
    if (!await _isAuthorized(chatId)) return;

    final text = '${message['text'] ?? ''}'.trim();
    if (text == '/start' || text == '/menu') {
      await _sendMenu(chatId);
    } else if (text == '/gallery' || text == '🖼 گالری') {
      await _sendGalleryFolders(chatId);
    } else if (text == '/files' || text == '📂 فایل‌ها') {
      await _sendFilesInfo(chatId);
    }
  }

  Future<void> _handleCallback(Map callback) async {
    final callbackId = '${callback['id'] ?? ''}';
    final message = callback['message'];
    if (message is! Map) {
      await _answerCallback(callbackId);
      return;
    }

    final chatId = _chatIdFromMessage(message);
    if (!await _isAuthorized(chatId)) {
      await _answerCallback(callbackId, text: 'دسترسی مجاز نیست.');
      return;
    }

    final data = '${callback['data'] ?? ''}';
    if (data == 'menu') {
      await _answerCallback(callbackId);
      await _editMessage(chatId, '${message['message_id']}', _menuText(), _menuKeyboard());
      return;
    }

    if (data == 'gallery') {
      await _answerCallback(callbackId);
      await _editGallery(chatId, '${message['message_id']}');
      return;
    }

    if (data == 'files') {
      await _answerCallback(callbackId);
      await _editMessage(
        chatId,
        '${message['message_id']}',
        '📂 فایل‌ها\n\nبرای دسترسی به فایل‌های معمولی گوشی، باید یک پوشه ریشه را یک‌بار از داخل خود برنامه انتخاب کنیم. این مرحله را در نسخه بعد اضافه می‌کنیم.',
        _backKeyboard(),
      );
      return;
    }

    if (data.startsWith('gf:')) {
      await _answerCallback(callbackId);
      final folder = _folders[data.substring(3)];
      if (folder == null) {
        await _sendText(chatId, 'این دکمه منقضی شده است. دوباره /gallery را بزن.');
        return;
      }
      await _editFolder(chatId, '${message['message_id']}', folder);
      return;
    }

    if (data.startsWith('ga:')) {
      await _answerCallback(callbackId, text: 'در حال ارسال فایل...');
      final asset = _assets[data.substring(3)];
      if (asset == null) {
        await _sendText(chatId, 'این فایل منقضی شده است. دوباره پوشه را باز کن.');
        return;
      }

      final file = await asset.file;
      if (file == null || !await file.exists()) {
        await _sendText(chatId, 'فایل دیگر در گوشی موجود نیست یا قابل دسترسی نیست.');
        return;
      }

      final ok = await _fileService.sendFile(
        file,
        caption: '📎 ${asset.title ?? 'فایل'}',
      );

      if (!ok) {
        await _sendText(chatId, '❌ ارسال فایل ناموفق بود.');
      }
      return;
    }
  }

  String _menuText() {
    return '📱 کنترل گوشی\n\nیک گزینه را انتخاب کن:';
  }

  Map<String, dynamic> _menuKeyboard() {
    return {
      'inline_keyboard': [
        [
          {'text': '🖼 گالری', 'callback_data': 'gallery'},
          {'text': '📂 فایل‌ها', 'callback_data': 'files'},
        ],
      ],
    };
  }

  Map<String, dynamic> _backKeyboard() {
    return {
      'inline_keyboard': [
        [
          {'text': '⬅️ منوی اصلی', 'callback_data': 'menu'},
        ],
      ],
    };
  }

  Future<void> _sendMenu(String chatId) async {
    await _sendText(
      chatId,
      _menuText(),
      replyMarkup: _menuKeyboard(),
    );
  }

  Future<void> _sendGalleryFolders(String chatId) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      await _sendText(
        chatId,
        '⚠️ دسترسی گالری فعال نیست.\nابتدا دسترسی عکس‌ها و ویدیوها را به برنامه بده.',
      );
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      hasAll: false,
      onlyAll: false,
      type: RequestType.common,
    );

    _folders.clear();

    final rows = <List<Map<String, String>>>[];
    var index = 0;

    for (final path in paths) {
      final key = '$index';
      _folders[key] = path;

      rows.add([
        {
          'text': '📁 ${path.name}',
          'callback_data': 'gf:$key',
        }
      ]);
      index++;

      // Telegram inline keyboard callback data is limited; also keep the
      // list practical on small screens.
      if (index >= 80) break;
    }

    if (rows.isEmpty) {
      await _sendText(chatId, '🖼 هیچ پوشه گالری قابل دسترسی پیدا نشد.');
      return;
    }

    rows.add([
      {'text': '⬅️ منوی اصلی', 'callback_data': 'menu'}
    ]);

    await _sendText(
      chatId,
      '🖼 پوشه‌های گالری:\n\nروی یک پوشه بزن:',
      replyMarkup: {'inline_keyboard': rows},
    );
  }

  Future<void> _editGallery(String chatId, String messageId) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      await _editMessage(
        chatId,
        messageId,
        '⚠️ دسترسی گالری فعال نیست.',
        _backKeyboard(),
      );
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      hasAll: false,
      onlyAll: false,
      type: RequestType.common,
    );

    _folders.clear();

    final rows = <List<Map<String, String>>>[];
    for (var i = 0; i < paths.length && i < 80; i++) {
      final path = paths[i];
      final key = '$i';
      _folders[key] = path;
      rows.add([
        {
          'text': '📁 ${path.name}',
          'callback_data': 'gf:$key',
        }
      ]);
    }

    rows.add([
      {'text': '⬅️ منوی اصلی', 'callback_data': 'menu'}
    ]);

    await _editMessage(
      chatId,
      messageId,
      '🖼 پوشه‌های گالری:\n\nروی یک پوشه بزن:',
      {'inline_keyboard': rows},
    );
  }

  Future<void> _editFolder(
    String chatId,
    String messageId,
    AssetPathEntity folder,
  ) async {
    final assets = await folder.getAssetListPaged(page: 0, size: 50);
    _assets.clear();

    final rows = <List<Map<String, String>>>[];

    for (var i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final key = '$i';
      _assets[key] = asset;

      final icon = asset.type == AssetType.video ? '🎬' : '🖼';
      rows.add([
        {
          'text': '$icon ${_shortName(asset.title ?? 'فایل ${i + 1}') }',
          'callback_data': 'ga:$key',
        }
      ]);
    }

    rows.add([
      {'text': '⬅️ پوشه‌ها', 'callback_data': 'gallery'}
    ]);

    final name = folder.name.isEmpty ? 'پوشه' : folder.name;
    final text = assets.isEmpty
        ? '📁 $name\n\nفایلی در این پوشه پیدا نشد.'
        : '📁 $name\n\n${assets.length} فایل اول:\nروی فایل بزن تا برایت ارسال شود.';

    await _editMessage(
      chatId,
      messageId,
      text,
      {'inline_keyboard': rows},
    );
  }

  String _shortName(String value) {
    if (value.length <= 38) return value;
    return '${value.substring(0, 35)}...';
  }

  Future<void> _sendFilesInfo(String chatId) async {
    await _sendText(
      chatId,
      '📂 برای فایل‌های عمومی گوشی، Android دسترسی کامل به کل حافظه را به‌صورت خودکار نمی‌دهد.\n\nدر مرحله بعد یک انتخاب «پوشه ریشه» اضافه می‌کنیم؛ بعد از انتخاب یک‌باره، ربات می‌تواند همان پوشه و زیرپوشه‌های مجازش را مرور کند.',
      replyMarkup: _backKeyboard(),
    );
  }

  Future<void> _sendText(
    String chatId,
    String text, {
    Map<String, dynamic>? replyMarkup,
  }) async {
    final token = await _token();
    if (token.isEmpty) return;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$token/sendMessage',
    );

    final body = <String, String>{
      'chat_id': chatId,
      'text': text,
    };

    if (replyMarkup != null) {
      body['reply_markup'] = jsonEncode(replyMarkup);
    }

    try {
      await http.post(uri, body: body);
    } catch (_) {}
  }

  Future<void> _editMessage(
    String chatId,
    String messageId,
    String text,
    Map<String, dynamic> replyMarkup,
  ) async {
    final token = await _token();
    if (token.isEmpty) return;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$token/editMessageText',
    );

    try {
      await http.post(
        uri,
        body: <String, String>{
          'chat_id': chatId,
          'message_id': messageId,
          'text': text,
          'reply_markup': jsonEncode(replyMarkup),
        },
      );
    } catch (_) {}
  }

  Future<void> _answerCallback(
    String callbackId, {
    String? text,
  }) async {
    final token = await _token();
    if (token.isEmpty || callbackId.isEmpty) return;

    final uri = Uri.parse(
      'https://api.telegram.org/bot$token/answerCallbackQuery',
    );

    try {
      await http.post(
        uri,
        body: <String, String>{
          'callback_query_id': callbackId,
          if (text != null) 'text': text,
        },
      );
    } catch (_) {}
  }
}
