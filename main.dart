import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> {
  List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late SharedPreferences _prefs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initMemory();
  }

  void _initMemory() async {
    _prefs = await SharedPreferences.getInstance();
    final String? savedChat = _prefs.getString('jarvis_chat_history');
    setState(() {
      if (savedChat != null) {
        final List<dynamic> decoded = jsonDecode(savedChat);
        _messages = decoded.map((item) => Map<String, String>.from(item)).toList();
      } else {
        _messages = [
          {"bot": "Джарвис на связи, сэр. Архив памяти успешно инициализирован. Система активна."}
        ];
        _saveHistoryToDevice();
      }
    });
  }

  void _saveHistoryToDevice() async {
    final String encoded = jsonEncode(_messages);
    await _prefs.setString('jarvis_chat_history', encoded);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"user": text});
      _isLoading = true;
    });
    _controller.clear();
    _saveHistoryToDevice();

    String lowerText = text.toLowerCase();
    
    if (lowerText.contains("время") || lowerText.contains("час")) {
      final now = DateTime.now();
      _addBotResponse("Сейчас ${now.hour}:${now.minute.toString().padLeft(2, '0')}, сэр.");
      return;
    }
    
    if (lowerText.contains("очисти память") || lowerText.contains("забудь")) {
      setState(() {
        _messages = [{"bot": "Память полностью очищена, сэр. Я всё забыл."}];
      });
      _saveHistoryToDevice();
      return;
    }

    // Запрос к ИИ
    const url = "https://huggingface.co";
    const token = "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";

    String dialogContext = "";
    int startIdx = _messages.length > 8 ? _messages.length - 8 : 0;
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
          "inputs": "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\nТы — Джарвис, ИИ Тони Старка. Отвечай коротко, емко, на русском языке. Обращайся 'сэр'. Помни историю диалога:\n$dialogContext<|eot_id|><|start_header_id|>user<|end_header_id|>\n$text<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n",
          "parameters": {"max_new_tokens": 100, "temperature": 0.7}
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(utf8.decode(response.bodyBytes));
        String rawRes = result[0]['generated_text'];
        String aiResponse = rawRes.split("<|start_header_id|>assistant<|end_header_id|>\n").last.replaceAll("<|eot_id|>", "").trim();
        _addBotResponse(aiResponse);
      } else {
        _addBotResponse("Сэр, возникли помехи на центральном сервере. Проверьте сеть.");
      }
    } catch (_) {
      _addBotResponse("Сэр, каналы связи недоступны. Информация сохранена локально.");
    }
  }

  void _addBotResponse(String text) {
    setState(() {
      _messages.add({"bot": text});
      _isLoading = false;
    });
    _saveHistoryToDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ JARVIS AI SYSTEM ⚡', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
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
                      hintText: 'Введите команду...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan, size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
