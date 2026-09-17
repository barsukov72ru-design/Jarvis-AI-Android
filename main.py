import flet as ft
import requests
import json
from plyer import tts

def main(page: ft.Page):
    page.title = "Jarvis AI"
    page.theme_mode = ft.ThemeMode.DARK
    page.vertical_alignment = ft.MainAxisAlignment.CENTER
    page.horizontal_alignment = ft.CrossAxisAlignment.CENTER
    
    # Текст статуса голосового движка
    status_text = ft.Text("", color=ft.colors.GREEN_ACCENT)

    # Функция озвучки (Plyer TTS отлично работает на Android)
    def bot_speak(text_to_say):
        try:
            status_text.value = "🔊 Джарвис говорит..."
            page.update()
            tts.speak(text_to_say)
            status_text.value = ""
            page.update()
        except Exception as e:
            status_text.value = f"⚠️ Ошибка звука: {str(e)}"
            page.update()

    # Окно истории чата
    chat_history = ft.Column(
        scroll=ft.ScrollMode.AUTO,
        expand=True,
        spacing=10,
    )

    # Поле ввода текста
    user_input = ft.TextField(
        hint_text="Введите ваш запрос для Джарвиса...",
        expand=True,
        on_submit=lambda e: send_message(e)
    )

    # Функция обработки сообщений
    def send_message(e):
        if not user_input.value.strip():
            return
            
        user_text = user_input.value
        chat_history.controls.append(
            ft.Container(
                content=ft.Text(f"Вы: {user_text}", color=ft.colors.WHITE),
                padding=10,
                bgcolor=ft.colors.BLUE_GREY_800,
                border_radius=10,
            )
        )
        user_input.value = ""
        page.update()

        # Шаблон логики ответа 
        response_text = f"Слушаю вас. Ваш запрос '{user_text}' принят в обработку, сэр."
        
        chat_history.controls.append(
            ft.Container(
                content=ft.Text(f"Джарвис: {response_text}", color=ft.colors.CYAN_ACCENT),
                padding=10,
                bgcolor=ft.colors.BLUE_GREY_900,
                border_radius=10,
            )
        )
        page.update()
        
        # Запуск озвучки ответа
        bot_speak(response_text)

    # Главный контейнер интерфейса
    page.add(
        ft.Container(
            content=ft.Column([
                ft.Text("⚡ JARVIS AI SYSTEM ⚡", size=24, weight=ft.FontWeight.BOLD, color=ft.colors.CYAN),
                status_text,
                ft.Divider(color=ft.colors.CYAN_700),
                ft.Container(content=chat_history, expand=True, padding=10),
                ft.Row([
                    user_input,
                    ft.IconButton(
                        icon=ft.icons.SEND,
                        icon_color=ft.colors.CYAN,
                        on_click=send_message
                    )
                ], spacing=10)
            ]),
            expand=True,
            padding=20,
            bgcolor=ft.colors.BLACK,
            border_radius=15,
            border=ft.border.all(2, ft.colors.CYAN_700)
        )
    )

# Исправленный запуск для новых версий Flet в окружении Colab
if __name__ == "__main__":
    ft.main(target=main, view=ft.AppView.WEB_BROWSER, port=8550)
