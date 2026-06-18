import flet as ft
import traceback
import sys

# Global variable to catch deep boot-level crashes
boot_crash_log = ""

try:
    import json
    import os
    import asyncio
    import brain  # ✅ FIX 3: Connected brain to main
except Exception as e:
    boot_crash_log = traceback.format_exc()

def main(page: ft.Page):
    page.title = "Vyshu AI V1.0"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0

    # 1. IF THE APP CRASHED ON BOOT, SHOW THE ERROR ON SCREEN
    if boot_crash_log:
        page.scroll = ft.ScrollMode.AUTO
        page.add(ft.Text("⚠️ CRITICAL BOOT ERROR ⚠️", color=ft.colors.RED_ACCENT, size=20, weight="bold"))
        page.add(ft.Text(boot_crash_log, color=ft.colors.RED_200, selectable=True))
        page.update()
        return

    # 2. NORMAL APP EXECUTION
    try:
        config_file = "vyshu_config.json"

        def load_config():
            if os.path.exists(config_file):
                try:
                    with open(config_file, "r") as f:
                        return json.load(f)
                except Exception:
                    return {}
            return {}

        def save_config(data):
            try:
                with open(config_file, "w") as f:
                    json.dump(data, f, indent=4)
                return True
            except Exception:
                return False

        config = load_config()

        # Chat Interface
        chat_log = ft.ListView(expand=True, spacing=10, auto_scroll=True, padding=20)
        chat_log.controls.append(ft.Text("Vyshu: Hello Teja, I am online. Ready when you are.", color=ft.colors.CYAN_ACCENT, weight="bold"))

        def send_message(e):
            if not user_input.value: return
            user_text = user_input.value
            chat_log.controls.append(ft.Text(f"You: {user_text}", color=ft.colors.WHITE))
            user_input.value = ""
            page.update()

            # ✅ FIX 3: Actually call brain.py now
            try:
                reply = asyncio.run(brain.generate_response(user_text, mode="HOME"))
            except Exception as ex:
                reply = f"⚠️ Brain error: {str(ex)}"

            chat_log.controls.append(ft.Text(f"Vyshu: {reply}", color=ft.colors.CYAN_200))
            page.update()

        user_input = ft.TextField(hint_text="Message Vyshu...", expand=True, border_radius=20, filled=True, bgcolor=ft.colors.with_opacity(0.5, ft.colors.BLACK), on_submit=send_message)
        
        chat_interface = ft.Stack(
            expand=True,
            controls=[
                ft.Container(expand=True, gradient=ft.LinearGradient(begin=ft.alignment.top_center, end=ft.alignment.bottom_center, colors=[ft.colors.BLUE_GREY_900, ft.colors.BLACK])),
                ft.Column(
                    expand=True,
                    controls=[
                        ft.Container(expand=True), 
                        ft.Container(content=chat_log, height=250, bgcolor=ft.colors.with_opacity(0.4, ft.colors.BLACK), border_radius=10, margin=10),
                        ft.Container(padding=10, content=ft.Row([user_input, ft.IconButton(icon=ft.icons.SEND, icon_color=ft.colors.CYAN_ACCENT, on_click=send_message)]))
                    ]
                )
            ]
        )

        # Settings Interface
        def save_keys(e):
            data = {"gemini_1": g1.value, "groq": grq.value, "discord_tok": dt.value}
            if save_config(data):
                page.overlay.append(ft.SnackBar(ft.Text("Vault Locked & Saved! ✅"), bgcolor=ft.colors.GREEN_800, open=True))
                page.update()

        g1 = ft.TextField(label="Gemini Key", value=config.get("gemini_1", ""), password=True, can_reveal_password=True)
        grq = ft.TextField(label="Groq Key", value=config.get("groq", ""), password=True, can_reveal_password=True)
        dt = ft.TextField(label="Discord Token", value=config.get("discord_tok", ""), password=True, can_reveal_password=True)

        settings_interface = ft.Container(
            padding=30,
            content=ft.Column(
                scroll=ft.ScrollMode.AUTO,
                controls=[
                    ft.Text("Vyshu Core Setup", size=30, weight="bold", color=ft.colors.CYAN_ACCENT),
                    g1, grq, dt,
                    ft.ElevatedButton("Save Credentials", icon=ft.icons.LOCK, bgcolor=ft.colors.CYAN_700, color=ft.colors.WHITE, on_click=save_keys)
                ]
            )
        )

        # Navigation
        def tab_changed(e):
            main_view.content = chat_interface if e.control.selected_index == 0 else settings_interface
            page.update()

        nav_bar = ft.NavigationBar(
            destinations=[
                ft.NavigationBarDestination(icon=ft.icons.CHAT, label="Vyshu"),
                ft.NavigationBarDestination(icon=ft.icons.SETTINGS, label="Vault"),
            ],
            on_change=tab_changed
        )

        main_view = ft.Container(expand=True, content=chat_interface)
        page.add(main_view)
        page.navigation_bar = nav_bar
        page.update()

    except Exception as e:
        # Catch any UI rendering errors
        page.scroll = ft.ScrollMode.AUTO
        page.add(ft.Text("⚠️ CRITICAL UI ERROR ⚠️", color=ft.colors.RED_ACCENT, size=20, weight="bold"))
        page.add(ft.Text(traceback.format_exc(), color=ft.colors.RED_200, selectable=True))
        page.update()

# Assets dir removed temporarily for safe booting
ft.app(target=main)
