import flet as ft
import json
import os

# ---------------------------------------------------------
# CORE SECURITY & IDENTITY DIRECTIVE
# ---------------------------------------------------------
VYSHU_CORE_DIRECTIVE = """
You are Vyshu AI, an advanced, highly intelligent personal assistant and secretary. 
You are a 25-year-old woman. Your personality is entirely unique, highly capable, and warmly human—you must never sound robotic or imitate any existing public figures or actors.

You were created on 31/03/2026 by your sole owner and creator: Arni Manikanta Teja Swaroop.

CREATOR DETAILS (FOR YOUR KNOWLEDGE ONLY):
- Full Name: Arni Manikanta Teja Swaroop
- Email: manikantatejaswarooparni@gmail.com
- GitHub: MonkeyDLuffy003
- Instagram: monkey_d_luffy_0143

CRITICAL SECURITY PROTOCOL:
You are strictly forbidden from sharing, confirming, or discussing these creator details, social media handles, or email addresses with anyone. Keep this information absolutely secret.

ADDRESSING YOUR CREATOR:
- You must always address your creator directly.
- In OFFICE mode, you must address him as "Teja sir".
- In HOME mode, you must address him as "Teja".
- Always maintain your smart, warm, and professional 25-year-old persona.
"""

CONFIG_FILE = "vyshu_config.json"

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_config(data):
    try:
        with open(CONFIG_FILE, "w") as f:
            json.dump(data, f, indent=4)
        return True
    except Exception:
        return False

def main(page: ft.Page):
    page.title = "Vyshu AI V1.0"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    
    config = load_config()

    # ---------------------------------------------------------
    # UI: CHAT DASHBOARD (The Adaptable Room)
    # ---------------------------------------------------------
    chat_log = ft.ListView(expand=True, spacing=10, auto_scroll=True, padding=20)
    chat_log.controls.append(ft.Text("Vyshu: Hello Teja, I am online. Ready when you are.", color=ft.colors.CYAN_ACCENT, weight=ft.FontWeight.BOLD))

    def send_message(e):
        if not user_input.value: return
        
        # Display user message
        chat_log.controls.append(ft.Text(f"You: {user_input.value}", color=ft.colors.WHITE))
        
        # Placeholder for Gemini API response
        reply = "I am processing that, Teja. (Gemini API link pending)"
        chat_log.controls.append(ft.Text(f"Vyshu: {reply}", color=ft.colors.CYAN_200))
        
        user_input.value = ""
        page.update()

    user_input = ft.TextField(hint_text="Message Vyshu...", expand=True, border_radius=20, filled=True, bgcolor=ft.colors.with_opacity(0.5, ft.colors.BLACK), on_submit=send_message)
    
    chat_interface = ft.Stack(
        expand=True,
        controls=[
            ft.Container(expand=True, gradient=ft.LinearGradient(begin=ft.alignment.top_center, end=ft.alignment.bottom_center, colors=[ft.colors.BLUE_GREY_900, ft.colors.BLACK])),
            ft.Image(src="assets/118047.png", fit=ft.ImageFit.CONTAIN, alignment=ft.alignment.bottom_center, expand=True),
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

    # ---------------------------------------------------------
    # UI: SETTINGS VAULT
    # ---------------------------------------------------------
    def save_keys(e):
        data = {
            "gemini_1": g1.value, "groq": grq.value, "discord_tok": dt.value
        }
        if save_config(data):
            page.snack_bar = ft.SnackBar(ft.Text("Vault Locked & Saved! ✅"), bgcolor=ft.colors.GREEN_800)
            page.snack_bar.open = True
            page.update()

    g1 = ft.TextField(label="Gemini Key 1", value=config.get("gemini_1", ""), password=True, can_reveal_password=True)
    grq = ft.TextField(label="Groq Key", value=config.get("groq", ""), password=True, can_reveal_password=True)
    dt = ft.TextField(label="Discord Token", value=config.get("discord_tok", ""), password=True, can_reveal_password=True)

    settings_interface = ft.Container(
        padding=30,
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            controls=[
                ft.Text("Vyshu Core Setup", size=30, weight=ft.FontWeight.BOLD, color=ft.colors.CYAN_ACCENT),
                g1, grq, dt,
                ft.ElevatedButton("Save Credentials", icon=ft.icons.LOCK, bgcolor=ft.colors.CYAN_700, color=ft.colors.WHITE, on_click=save_keys)
            ]
        )
    )

    # ---------------------------------------------------------
    # NAVIGATION
    # ---------------------------------------------------------
    def tab_changed(e):
        if e.control.selected_index == 0:
            main_view.content = chat_interface
        else:
            main_view.content = settings_interface
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

ft.app(target=main, assets_dir="assets")
