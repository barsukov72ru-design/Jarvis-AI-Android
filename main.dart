import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.cyan,
      ),
      home: const JarvisScreen(),
    );
  }
}

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _JarvisScreenContent();
  }
}

class _JarvisScreenContent extends StatefulWidget {
  const _JarvisScreenContent();

  @override
  State<_JarvisScreenContent> createState() => _JarvisScreenContentState();
}

class _JarvisScreenContentState extends State<_JarvisScreenContent> {
  // Список сообщений чата
  List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  late SharedPreferences _prefs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTtsAndMemory();
  }

  // Загружаем память телефона при старте приложения
  void _initTtsAndMemory() async {
    await _tts.setLanguage("ru-RU");
    await _tts.setSpeechRate(0.5);

    _prefs = await SharedPreferences.getInstance();
    final String? savedChat = _prefs.getString('jarvis_chat_history');

    setState(() {
      if (savedChat != null) {
        // Если история есть в телефоне — восстанавливаем её
        final List<dynamic> decoded = jsonDecode(savedChat);
        _messages = decoded.map((item) => Map<String, String>.from(item)).toList();
      } else {
        // Если это первый запуск — пишем приветствие
        _messages = [
          {"bot": "Джарвис на связи, сэр. Архив памяти успешно инициализирован. Система активна."}
        ];
        _saveHistoryToDevice();
      }
    });

    _speak("Система активна, сэр.");
  }

  // Функция сохранения истории в память смартфона (без интернета)
  void _saveHistoryToDevice() async {
    final String encoded = jsonEncode(_messages);
    await _prefs.setString('jarvis_chat_history', encoded);
  }

  void _speak(String text) async {
    await _tts.speak(text);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"user": text});
      _isLoading = true;
    });
    _controller.clear();
    _saveHistoryToDevice(); // Сразу пишем в память телефона

    String lowerText = text.toLowerCase();
    
    // ----------------------------------------------------
    // Локальные команды БЕЗ ИНТЕРНЕТА
    // ----------------------------------------------------
    if (lowerText.contains("время") || lowerText.contains("час")) {
      String time = DateFormat('HH:mm').format(DateTime.now());
      _addBotResponse("Сейчас $time, сэр.");
      return;
    }
    
    if (lowerText.contains("очисти память") || lowerText.contains("забудь всё")) {
      setState(() {
        _messages = [{"bot": "Память полностью очищена, сэр. Я всё забыл."}];
      });
      _saveHistoryToDevice();
      _speak("Память очищена.");
      return;
    }

    // ----------------------------------------------------
    // Запрос к ИИ (Контекстная память + Интернет)
    // ----------------------------------------------------
    const url = "https://huggingface.co";
    const token = "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";

    // Собираем контекст из последних 10 сообщений переписки
    String dialogContext = "";
    int startIdx = _messages.length > 10 ? _messages.length - 10 : 0;
    for (int i = startIdx; i < _messages.length - 1; i++) {
      if (_messages[i].containsKey("user")) {
        dialogContext += "User: ${_messages[i]["user"]}\n";
      } else if (_messages[i].containsKey("bot")) {
        dialogContext += "Assistant: ${_messages[i]["bot"]}\n";
      }
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "inputs": "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\nТы — Джарвис, продвинутый военный ИИ-ассистент Тони Старка. Отвечай всегда строго на русском языке, вежливо, коротко и емко. Обращайся к пользователю 'сэр'. Вот история нашего диалога, помни её:\n$dialogContext<|eot_id|><|start_header_id|>user<|end_header_id|>\n$text<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n",
          "parameters": {"max_new_tokens": 120, "temperature": 0.7}
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(utf8.decode(response.bodyBytes));
        String rawRes = result['generated_text'];
        String aiResponse = rawRes.split("<|start_header_id|>assistant<|end_header_id|>\n").last.replaceAll("<|eot_id|>", "").trim();
        _addBotResponse(aiResponse);
      } else {
        _addBotResponse("Сэр, возникли помехи на центральном сервере. Проверьте сеть.");
      }
    } catch (_) {
      _addBotResponse("Сэр, каналы связи недоступны. Информация сохранена в локальный архив до возобновления сети.");
    }
  }

  void _addBotResponse(String text) {
    setState(() {
      _messages.add({"bot": text});
      _isLoading = false;
    });
    _saveHistoryToDevice(); // Сохраняем ответ ИИ в память телефона
    _speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ JARVIS AI SYSTEM ⚡', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg.containsKey("user");
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueGrey[800] : Colors.grey[900],
                      border: Border.all(color: isUser ? Colors.transparent : Colors.cyan, width: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUser ? "${msg["user"]}" : "${msg["bot"]}",
                      style: TextStyle(color: isUser ? Colors.white : Colors.cyanAccent, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.cyan),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Введите команду для Джарвиса...',
                      hintStyle: TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan, size: 28),
                  onPressed: _sendMessage, // ТУТ ВСЁ ИСПРАВЛЕНО НА ONPRESSED!
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
