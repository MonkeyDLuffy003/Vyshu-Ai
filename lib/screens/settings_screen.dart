import flet as ft
from flet import (
    Page, Column, Row, Container, Text, TextField, Icon, ElevatedButton,
    OutlinedButton, GestureDetector, GridView, Switch, SnackBar,
    CrossAxisAlignment, MainAxisAlignment, BorderRadius, EdgeInsets,
    LinearGradient, Alignment, Colors, Icons, IconButton
)
import asyncio

# Simulated MemoryService (replace with your actual logic)
class MemoryService:
    @staticmethod
    async def archive_to_gmail():
        await asyncio.sleep(1)  # Simulate network
        return "Archived 5 expired memories to Gmail"

# Config keys (same as VyshuConfig)
class VyshuConfig:
    kGeminiKey1 = "gemini_key_1"
    kGeminiKey2 = "gemini_key_2"
    kGeminiKey3 = "gemini_key_3"
    kGroqKey = "groq_key"
    kTogetherKey = "together_key"
    kTavilyKey = "tavily_key"
    kGmailAddress = "gmail_address"
    kGmailAppPwd = "gmail_app_password"
    kCurrentMode = "current_mode"
    kAdaptiveRoom = "adaptive_room"
    kVoiceEnabled = "voice_enabled"

    adaptive_rooms = ["park", "cafe", "library", "beach", "mountain"]
    room_emojis = {
        "park": "🌳", "cafe": "☕", "library": "📚",
        "beach": "🏖️", "mountain": "⛰️"
    }

class KeyField:
    def __init__(self, label, pref_key, hint="Enter key...", obscure=False):
        self.label = label
        self.pref_key = pref_key
        self.hint = hint
        self.obscure = obscure

class SettingsScreen:
    def __init__(self, page: Page):
        self.page = page
        self.page.title = "Settings"
        self.page.theme_mode = ft.ThemeMode.DARK
        self.page.bgcolor = None  # use gradient on container

        self.mode = "HOME"
        self.adaptive_room = "park"
        self.voice_enabled = True

        # Controllers and status for API keys
        self.controllers = {}
        self.save_status = {}  # True = saved, False = error, None = idle

        self.key_fields = [
            KeyField("Gemini Key 1", VyshuConfig.kGeminiKey1),
            KeyField("Gemini Key 2", VyshuConfig.kGeminiKey2),
            KeyField("Gemini Key 3", VyshuConfig.kGeminiKey3),
            KeyField("Groq API Key", VyshuConfig.kGroqKey),
            KeyField("Together AI", VyshuConfig.kTogetherKey),
            KeyField("Tavily Search", VyshuConfig.kTavilyKey),
            KeyField("Gmail Address", VyshuConfig.kGmailAddress,
                     hint="yourname@gmail.com"),
            KeyField("App Password", VyshuConfig.kGmailAppPwd,
                     hint="xxxx xxxx xxxx xxxx", obscure=True),
        ]

        self.page.on_route_change = self.load_settings
        self.page.add(self.build())

    async def load_settings(self, e=None):
        # Load from client storage
        self.mode = await self.page.client_storage.get_async(
            VyshuConfig.kCurrentMode) or "HOME"
        self.adaptive_room = await self.page.client_storage.get_async(
            VyshuConfig.kAdaptiveRoom) or "park"
        self.voice_enabled = await self.page.client_storage.get_async(
            VyshuConfig.kVoiceEnabled) or True
        # Load API keys into controllers
        for f in self.key_fields:
            saved = await self.page.client_storage.get_async(f.pref_key) or ""
            self.controllers[f.pref_key] = ft.TextField(
                value=saved,
                hint_text=f.hint,
                password=f.obscure,
                can_reveal_password=f.obscure,
                text_size=13,
                border=ft.InputBorder.OUTLINE,
                filled=True,
                fill_color=ft.Colors.with_opacity(0.1, ft.Colors.WHITE),
                border_radius=10,
                content_padding=EdgeInsets.symmetric(horizontal=12, vertical=8),
            )
            self.save_status[f.pref_key] = True if saved else None
        self.page.update()

    async def save_key(self, pref_key, label):
        value = self.controllers[pref_key].value.strip()
        if not value:
            self.save_status[pref_key] = False
            self.show_snack(f"⚠️ {label} cannot be empty")
            self.page.update()
            return
        try:
            await self.page.client_storage.set_async(pref_key, value)
            # Verify
            read_back = await self.page.client_storage.get_async(pref_key) or ""
            if read_back == value:
                self.save_status[pref_key] = True
                self.show_snack(f"✅ {label} saved!")
            else:
                self.save_status[pref_key] = False
                self.show_snack(f"❌ {label} write failed")
        except Exception as e:
            self.save_status[pref_key] = False
            self.show_snack(f"❌ Error: {e}")
        self.page.update()
        # Reset status after 3 seconds
        await asyncio.sleep(3)
        if self.save_status.get(pref_key) is not None:
            self.save_status[pref_key] = None
            self.page.update()

    async def save_pref(self, key, value):
        await self.page.client_storage.set_async(key, value)

    def build(self):
        main_container = Container(
            expand=True,
            gradient=LinearGradient(
                begin=Alignment.top_center,
                end=Alignment.bottom_center,
                colors=["#000C1A", "#000000"],
            ),
            content=ft.SafeArea(
                Column(
                    scroll=ft.ScrollMode.AUTO,
                    controls=[
                        self._build_header(),
                        ft.Divider(height=20, color=ft.Colors.TRANSPARENT),
                        self._build_section(
                            "Virtual Room and Mode", Icons.MEETING_ROOM,
                            [
                                self._build_mode_selector(),
                                ft.Container(
                                    visible=self.mode == "ADAPTIVE",
                                    content=self._build_room_selector(),
                                )
                            ]
                        ),
                        ft.Divider(height=16, color=ft.Colors.TRANSPARENT),
                        self._build_section(
                            "Vyshu Wardrobe", Icons.CHECKROOM,
                            [self._build_wardrobe_grid()]
                        ),
                        ft.Divider(height=16, color=ft.Colors.TRANSPARENT),
                        self._build_section(
                            "API Keys", Icons.KEY,
                            [
                                self._build_key_field(f)
                                for f in self.key_fields
                                if f.pref_key not in [VyshuConfig.kGmailAddress, VyshuConfig.kGmailAppPwd]
                            ]
                        ),
                        ft.Divider(height=16, color=ft.Colors.TRANSPARENT),
                        self._build_section(
                            "Gmail Archive", Icons.EMAIL,
                            [
                                self._build_key_field(f)
                                for f in self.key_fields
                                if f.pref_key in [VyshuConfig.kGmailAddress, VyshuConfig.kGmailAppPwd]
                            ] + [
                                ft.Divider(height=8, color=ft.Colors.TRANSPARENT),
                                self._build_archive_button(),
                            ]
                        ),
                        ft.Divider(height=16, color=ft.Colors.TRANSPARENT),
                        self._build_section(
                            "Voice", Icons.VOLUME_UP,
                            [self._build_toggle_row("Voice Output", self.voice_enabled)]
                        ),
                        ft.Divider(height=32, color=ft.Colors.TRANSPARENT),
                    ],
                )
            ),
        )
        return main_container

    def _build_header(self):
        return Row(
            controls=[
                Icon(Icons.SETTINGS, color="#00B4FF", size=22),
                ft.Divider(width=10, color=ft.Colors.TRANSPARENT),
                Text("SETTINGS", font_family="Orbitron",
                     size=16, weight=ft.FontWeight.BOLD, color="#00B4FF",
                     letter_spacing=2),
            ]
        )

    def _build_section(self, title, icon, children):
        return Container(
            padding=EdgeInsets.all(16),
            border_radius=16,
            bgcolor="#0F1F38",
            border=ft.border.all(color="#3300B4FF", width=1),
            content=Column(
                cross_axis=CrossAxisAlignment.START,
                controls=[
                    Row(controls=[
                        Icon(icon, color="#00FFFF", size=16),
                        ft.Divider(width=8, color=ft.Colors.TRANSPARENT),
                        Text(title, size=13, weight=ft.FontWeight.W600, color="#00FFFF"),
                    ]),
                    ft.Divider(height=14, color=ft.Colors.TRANSPARENT),
                    *children,
                ]
            )
        )

    def _build_mode_selector(self):
        modes = ["HOME", "OFFICE", "ADAPTIVE"]
        icons = [Icons.HOME, Icons.WORK, Icons.EXPLORE]
        return Row(
            controls=[
                Container(
                    expand=True,
                    margin=EdgeInsets.symmetric(horizontal=4),
                    content=GestureDetector(
                        on_tap=lambda m=modes[i]: self._set_mode(m),
                        content=Container(
                            padding=EdgeInsets.symmetric(vertical=10),
                            border_radius=10,
                            bgcolor="#00B4FF" if self.mode == modes[i] else "#0A1628",
                            alignment=ft.alignment.center,
                            content=Column(
                                spacing=4,
                                controls=[
                                    Icon(icons[i], color=ft.Colors.WHITE, size=20),
                                    Text(modes[i], size=9, weight=ft.FontWeight.W600,
                                         color=ft.Colors.WHITE, font_family="Orbitron"),
                                ]
                            )
                        )
                    ),
                ) for i in range(3)
            ]
        )

    async def _set_mode(self, mode):
        self.mode = mode
        await self.save_pref(VyshuConfig.kCurrentMode, mode)
        self.page.update()

    def _build_room_selector(self):
        return Column(
            cross_axis=CrossAxisAlignment.START,
            controls=[
                Text("Choose Adaptive Room:", size=12, color="#7EC8E3"),
                ft.Divider(height=8, color=ft.Colors.TRANSPARENT),
                Wrap(
                    spacing=8, run_spacing=8,
                    controls=[
                        GestureDetector(
                            on_tap=lambda r=room: self._set_room(r),
                            content=Container(
                                padding=EdgeInsets.symmetric(horizontal=12, vertical=6),
                                border_radius=20,
                                bgcolor="#00B4FF" if self.adaptive_room == room else "#0A1628",
                                border=ft.border.all(
                                    color="#00B4FF" if self.adaptive_room == room else "#5500B4FF"
                                ),
                                content=Text(
                                    f"{VyshuConfig.room_emojis.get(room, '🌍')} {room.capitalize()}",
                                    size=12, color=ft.Colors.WHITE
                                ),
                            )
                        ) for room in VyshuConfig.adaptive_rooms
                    ]
                )
            ]
        )

    async def _set_room(self, room):
        self.adaptive_room = room
        await self.save_pref(VyshuConfig.kAdaptiveRoom, room)
        self.page.update()

    def _build_wardrobe_grid(self):
        outfits = [
            ("Office 1", Icons.WORK),
            ("Office 2", Icons.WORK_OUTLINE),
            ("Office 3", Icons.BUSINESS_CENTER),
            ("Home 1", Icons.HOME),
            ("Home 2", Icons.FAVORITE),
            ("Night", Icons.NIGHTS_STAY),
        ]
        return GridView(
            expand=False,
            runs_count=3,
            max_extent=100,
            child_aspect_ratio=0.85,
            spacing=8,
            run_spacing=8,
            controls=[
                Container(
                    border_radius=12,
                    bgcolor="#0A1628",
                    border=ft.border.all(color="#3300B4FF"),
                    alignment=ft.alignment.center,
                    content=Column(
                        main_axis=MainAxisAlignment.CENTER,
                        spacing=6,
                        controls=[
                            Icon(icon, color="#00B4FF", size=28),
                            Text(label, size=10, color="#7EC8E3"),
                        ]
                    )
                ) for label, icon in outfits
            ]
        )

    def _build_key_field(self, field: KeyField):
        controller = self.controllers[field.pref_key]
        status = self.save_status.get(field.pref_key)
        btn_color = "#00B4FF"
        btn_icon = Icons.CHECK
        if status is True:
            btn_color = "#00C853"
            btn_icon = Icons.CHECK_CIRCLE
        elif status is False:
            btn_color = "#FF3B3B"
            btn_icon = Icons.ERROR

        return Column(
            cross_axis=CrossAxisAlignment.START,
            controls=[
                Text(field.label, size=11, color="#7EC8E3"),
                ft.Divider(height=4, color=ft.Colors.TRANSPARENT),
                Row(
                    controls=[
                        Container(expand=True, content=controller),
                        ft.Divider(width=8, color=ft.Colors.TRANSPARENT),
                        Container(
                            border_radius=10,
                            bgcolor=btn_color,
                            content=IconButton(
                                icon=Icon(btn_icon, color=ft.Colors.WHITE, size=18),
                                on_click=lambda e, pk=field.pref_key, lbl=field.label: asyncio.create_task(self.save_key(pk, lbl)),
                                padding=EdgeInsets.symmetric(horizontal=12, vertical=10),
                            )
                        )
                    ]
                )
            ]
        )

    def _build_archive_button(self):
        return GestureDetector(
            on_tap=lambda _: asyncio.create_task(self._archive_to_gmail()),
            content=Container(
                width=float('inf'),
                padding=EdgeInsets.symmetric(vertical=12),
                border_radius=10,
                bgcolor="#002A4A",
                border=ft.border.all(color="#00B4FF"),
                content=Row(
                    main_axis=MainAxisAlignment.CENTER,
                    controls=[
                        Icon(Icons.ARCHIVE, color="#00B4FF", size=18),
                        ft.Divider(width=8, color=ft.Colors.TRANSPARENT),
                        Text("Archive Expired Memory to Gmail", size=13,
                             weight=ft.FontWeight.W600, color="#00B4FF"),
                    ]
                )
            )
        )

    async def _archive_to_gmail(self):
        self.show_snack("Archiving to Gmail...")
        result = await MemoryService.archive_to_gmail()
        self.show_snack(result)

    def _build_toggle_row(self, label, value):
        return Row(
            main_axis=MainAxisAlignment.SPACE_BETWEEN,
            controls=[
                Text(label, size=13, color=ft.Colors.WHITE),
                Switch(
                    value=value,
                    on_change=lambda e: asyncio.create_task(self._toggle_voice(e.control.value)),
                    active_color="#00B4FF",
                    inactive_track_color="#1A2A3A",
                )
            ]
        )

    async def _toggle_voice(self, val):
        self.voice_enabled = val
        await self.save_pref(VyshuConfig.kVoiceEnabled, val)
        self.page.update()

    def show_snack(self, message):
        self.page.show_snack_bar(
            SnackBar(content=Text(message, size=13), bgcolor="#0A1628", duration=2000)
        )


async def main(page: Page):
    page.window_width = 450
    page.window_height = 800
    settings = SettingsScreen(page)

if __name__ == "__main__":
    ft.app(target=main)
