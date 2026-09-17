import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    // Текст нашей футуристичной веб-страницы чата Джарвиса
    final String htmlContent = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body { background: #000; color: #00ffff; font-family: 'Courier New', monospace; padding: 10px; margin:0; overflow: hidden; }
            .header { text-align: center; font-weight: bold; font-size: 18px; text-shadow: 0 0 8px #00ffff; margin: 10px 0; }
            .chat { height: 75vh; overflow-y: auto; border: 1px solid #005555; padding: 10px; border-radius: 8px; background: #030303; box-shadow: inset 0 0 10px #003333; }
            .msg { margin-bottom: 10px; padding: 8px; border-radius: 6px; font-size: 14px; line-height: 1.4; }
            .user { background: #002233; color: #fff; text-align: right; border-left: 3px solid #0088cc; }
            .bot { background: #001111; color: #00ffcc; border-left: 3px solid #00ffff; }
            .input-area { display: flex; gap: 8px; padding-top: 10px; }
            input { flex: 1; padding: 12px; border: 1px solid #00aaaa; background: #111; color: #fff; border-radius: 6px; outline: none; font-size: 14px; }
            button { padding: 12px 18px; background: #00aaaa; color: #000; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; }
        </style>
    </head>
    <body>
        <div class="header">⚡ JARVIS AI SYSTEM ⚡</div>
        <div class="chat" id="chat"></div>
        <div class="input-area">
            <input type="text" id="userInput" placeholder="Введите команду, сэр..." onkeydown="if(event.key==='Enter') sendMessage()">
            <button onclick="sendMessage()">></button>
        </div>

        <script>
            var chat = document.getElementById('chat');
            var input = document.getElementById('userInput');
            
            // Восстанавливаем бесконечную историю переписки из локальной памяти телефона (localStorage)
            var savedHistory = localStorage.getItem('jarvis_history');
            if (savedHistory) {
                chat.innerHTML = savedHistory;
                chat.scrollTop = chat.scrollHeight;
            } else {
                addMessage('bot', 'Джарвис на связи, сэр. Все системы памяти активны.');
                speak('Джарвис на связи, сэр. Все системы памяти активны.');
            }

            function addMessage(type, text) {
                chat.innerHTML += '<div class="msg ' + type + '">' + (type === 'user' ? 'Вы: ' : 'Джарвис: ') + text + '</div>';
                chat.scrollTop = chat.scrollHeight;
                localStorage.setItem('jarvis_history', chat.innerHTML); // Запись в память телефона
            }

            // Нативная и стабильная озвучка на русском языке
            function speak(text) {
                if ('speechSynthesis' in window) {
                    window.speechSynthesis.cancel();
                    var utterance = new SpeechSynthesisUtterance(text);
                    utterance.lang = 'ru-RU';
                    utterance.rate = 1.0;
                    window.speechSynthesis.speak(utterance);
                }
            }

            async function sendMessage() {
                var text = input.value.trim();
                if (!text) return;

                addMessage('user', text);
                input.value = '';

                // Локальная команда времени без интернета
                if (text.toLowerCase().includes('время') || text.toLowerCase().includes('час')) {
                    var now = new Date().toLocaleTimeString('ru-RU', {hour: '2-digit', minute:'2-digit'});
                    addMessage('bot', 'Сейчас ' + now + ', сэр.');
                    speak('Сейчас ' + now + ', сэр.');
                    return;
                }

                if (text.toLowerCase().includes('очисти память') || text.toLowerCase().includes('забудь')) {
                    localStorage.removeItem('jarvis_history');
                    chat.innerHTML = '';
                    addMessage('bot', 'Память очищена, сэр.');
                    speak('Память очищена.');
                    return;
                }

                // Запрос к ИИ (Контекст + Интернет)
                addMessage('bot', 'Секунду, сэр...');
                
                // Собираем последние сообщения со страницы для контекста ИИ
                var messagesDivs = chat.getElementsByClassName('msg');
                var contextText = "";
                var start = Math.max(0, messagesDivs.length - 8);
                for(var i=start; i<messagesDivs.length-1; i++) {
                    contextText += messagesDivs[i].innerText + "\\n";
                }

                try {
                    var response = await fetch("https://huggingface.co", {
                        method: "POST",
                        headers: {
                            "Authorization": "Bearer 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",
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({
                            "inputs": "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\\nТы — Джарвис, ИИ Тони Старка. Отвечай коротко, емко, на русском языке. Обращайся 'сэр'. Помни историю диалога:\\n" + contextText + "<|eot_id|><|start_header_id|>user<|end_header_id|>\\n" + text + "<|eot_id|><|start_header_id|>assistant<|end_header_id|>\\n",
                            "parameters": {"max_new_tokens": 100, "temperature": 0.7}
                        })
                    });

                    if (response.status === 200) {
                        var result = await response.json();
                        var rawRes = result[0].generated_text;
                        var aiResponse = rawRes.split("<|start_header_id|>assistant<|end_header_id|>\\n").pop().replace("<|eot_id|>", "").trim();
                        
                        // Удаляем сообщение "Секунду, сэр..." и пишем реальный ответ ИИ
                        chat.removeChild(chat.lastChild);
                        addMessage('bot', aiResponse);
                        speak(aiResponse);
                    } else {
                        throw new Error();
                    }
                } catch(e) {
                    chat.removeChild(chat.lastChild);
                    addMessage('bot', 'Сэр, каналы связи недоступны. Информация сохранена локально.');
                    speak('Каналы связи недоступны, сэр.');
                }
            }
        </script>
    </body>
    </html>
    """;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
