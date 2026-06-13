"""
VYSHU AI V4 — SETTINGS SCREEN (PYTHON / Tkinter)
Replicates the Flutter settings screen functionality.

- Persists settings in settings.json (JSON file)
- Supports Gemini keys (5), Groq, Together, Tavily, ElevenLabs, Discord, Gmail
- Mode selection (HOME/OFFICE/ADAPTIVE) + adaptive room picker
- Voice toggle, manual save per field, "Save All Keys" button
- Archive to Gmail stub (can be implemented via MemoryService later)
"""

import json
import os
from tkinter import Tk, Frame, Label, Entry, Button, Checkbutton, BooleanVar, StringVar, Scrollbar, Canvas
from tkinter import ttk, messagebox, HORIZONTAL, VERTICAL, BOTH, RIGHT, Y, LEFT, X, TOP, BOTTOM, END
from tkinter.font import Font

# ================================
# CONFIGURATION (mimics VyshuConfig)
# ================================
class VyshuConfig:
    # Preference keys
    kCurrentMode = "current_mode"
    kAdaptiveRoom = "adaptive_room"
    kVoiceEnabled = "voice_enabled"

    kGeminiKey1 = "gemini_key_1"
    kGeminiKey2 = "gemini_key_2"
    kGeminiKey3 = "gemini_key_3"
    kGeminiKey4 = "gemini_key_4"
    kGeminiKey5 = "gemini_key_5"
    kGroqKey = "groq_key"
    kTogetherKey = "together_key"
    kTavilyKey = "tavily_key"
    kGmailAddress = "gmail_address"
    kGmailAppPwd = "gmail_app_password"

    # Static rooms for adaptive mode
    adaptiveRooms = ["park", "library", "coffee", "space"]
    roomEmojis = {
        "park": "🌳",
        "library": "📚",
        "coffee": "☕",
        "space": "🚀"
    }

    @staticmethod
    def default_settings():
        return {
            VyshuConfig.kCurrentMode: "HOME",
            VyshuConfig.kAdaptiveRoom: "park",
            VyshuConfig.kVoiceEnabled: True,
            VyshuConfig.kGeminiKey1: "",
            VyshuConfig.kGeminiKey2: "",
            VyshuConfig.kGeminiKey3: "",
            VyshuConfig.kGeminiKey4: "",
            VyshuConfig.kGeminiKey5: "",
            VyshuConfig.kGroqKey: "",
            VyshuConfig.kTogetherKey: "",
            VyshuConfig.kTavilyKey: "",
            "elevenlabs_key": "",
            "discord_token": "",
            "discord_owner_id": "",
            VyshuConfig.kGmailAddress: "",
            VyshuConfig.kGmailAppPwd: "",
        }


# ================================
# MEMORY SERVICE STUB (archiveToGmail)
# ================================
class MemoryService:
    @staticmethod
    def archiveToGmail():
        # Placeholder for actual Gmail archiving logic.
        # In a real implementation you would use the stored Gmail credentials.
        return "Archiving simulation: memory archived (no actual email sent)."


# ================================
# SETTINGS SCREEN (Tkinter)
# ================================
class SettingsScreen:
    def __init__(self, root):
        self.root = root
        self.root.title("VYSHU AI V4 — Settings")
        self.root.geometry("600x700")
        self.root.configure(bg="#000000")

        # Load settings file
        self.settings_file = "settings.json"
        self.settings = self._load_settings()

        # StringVars for all fields
        self.mode_var = StringVar(value=self.settings.get(VyshuConfig.kCurrentMode, "HOME"))
        self.adaptive_room_var = StringVar(value=self.settings.get(VyshuConfig.kAdaptiveRoom, "park"))
        self.voice_enabled_var = BooleanVar(value=self.settings.get(VyshuConfig.kVoiceEnabled, True))

        # API key variables
        self.gemini1_var = StringVar(value=self.settings.get(VyshuConfig.kGeminiKey1, ""))
        self.gemini2_var = StringVar(value=self.settings.get(VyshuConfig.kGeminiKey2, ""))
        self.gemini3_var = StringVar(value=self.settings.get(VyshuConfig.kGeminiKey3, ""))
        self.gemini4_var = StringVar(value=self.settings.get(VyshuConfig.kGeminiKey4, ""))
        self.gemini5_var = StringVar(value=self.settings.get(VyshuConfig.kGeminiKey5, ""))
        self.groq_var = StringVar(value=self.settings.get(VyshuConfig.kGroqKey, ""))
        self.together_var = StringVar(value=self.settings.get(VyshuConfig.kTogetherKey, ""))
        self.tavily_var = StringVar(value=self.settings.get(VyshuConfig.kTavilyKey, ""))
        self.elevenlabs_var = StringVar(value=self.settings.get("elevenlabs_key", ""))
        self.discord_token_var = StringVar(value=self.settings.get("discord_token", ""))
        self.discord_id_var = StringVar(value=self.settings.get("discord_owner_id", ""))
        self.gmail_var = StringVar(value=self.settings.get(VyshuConfig.kGmailAddress, ""))
        self.gmail_pwd_var = StringVar(value=self.settings.get(VyshuConfig.kGmailAppPwd, ""))

        self._build_ui()

    # ------------------------------------------------------------
    # Persistence helpers
    # ------------------------------------------------------------
    def _load_settings(self):
        if os.path.exists(self.settings_file):
            with open(self.settings_file, "r") as f:
                return json.load(f)
        else:
            return VyshuConfig.default_settings()

    def _save_settings(self):
        with open(self.settings_file, "w") as f:
            json.dump(self.settings, f, indent=2)

    def _save_pref(self, key, value):
        self.settings[key] = value
        self._save_settings()

    def _save_key(self, key, value):
        self._save_pref(key, value.strip())
        self._show_snackbar(f"✅ Saved {key}!")

    def _save_all_keys(self):
        # Gather all current values from StringVars
        self.settings[VyshuConfig.kGeminiKey1] = self.gemini1_var.get().strip()
        self.settings[VyshuConfig.kGeminiKey2] = self.gemini2_var.get().strip()
        self.settings[VyshuConfig.kGeminiKey3] = self.gemini3_var.get().strip()
        self.settings[VyshuConfig.kGeminiKey4] = self.gemini4_var.get().strip()
        self.settings[VyshuConfig.kGeminiKey5] = self.gemini5_var.get().strip()
        self.settings[VyshuConfig.kGroqKey] = self.groq_var.get().strip()
        self.settings[VyshuConfig.kTogetherKey] = self.together_var.get().strip()
        self.settings[VyshuConfig.kTavilyKey] = self.tavily_var.get().strip()
        self.settings["elevenlabs_key"] = self.elevenlabs_var.get().strip()
        self.settings["discord_token"] = self.discord_token_var.get().strip()
        self.settings["discord_owner_id"] = self.discord_id_var.get().strip()
        self.settings[VyshuConfig.kGmailAddress] = self.gmail_var.get().strip()
        self.settings[VyshuConfig.kGmailAppPwd] = self.gmail_pwd_var.get().strip()
        # Mode and room are saved on change already, but ensure they are up to date
        self.settings[VyshuConfig.kCurrentMode] = self.mode_var.get()
        self.settings[VyshuConfig.kAdaptiveRoom] = self.adaptive_room_var.get()
        self.settings[VyshuConfig.kVoiceEnabled] = self.voice_enabled_var.get()
        self._save_settings()
        self._show_snackbar("✅ All keys saved successfully!")

    def _archive_to_gmail(self):
        self._show_snackbar("Archiving to Gmail...")
        result = MemoryService.archiveToGmail()
        self._show_snackbar(result)

    def _show_snackbar(self, message):
        # Using messagebox as snackbar replacement (non-modal alternative)
        # For a real 'snackbar' you'd need a popup label, but messagebox works.
        # We use a simple label that disappears - just for demo.
        snack = Label(self.root, text=message, bg="#0A1628", fg="#00B4FF", font=("Inter", 10))
        snack.pack(side=BOTTOM, pady=5)
        self.root.after(2000, snack.destroy)

    # ------------------------------------------------------------
    # UI Construction
    # ------------------------------------------------------------
    def _build_ui(self):
        # Main canvas + scrollbar for scrolling
        main_canvas = Canvas(self.root, bg="#000000", highlightthickness=0)
        v_scrollbar = Scrollbar(self.root, orient=VERTICAL, command=main_canvas.yview)
        main_canvas.configure(yscrollcommand=v_scrollbar.set)
        v_scrollbar.pack(side=RIGHT, fill=Y)
        main_canvas.pack(side=LEFT, fill=BOTH, expand=True)

        # Frame inside canvas
        scrollable_frame = Frame(main_canvas, bg="#000000")
        scrollable_frame.bind("<Configure>", lambda e: main_canvas.configure(scrollregion=main_canvas.bbox("all")))
        main_canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")

        # ----- Header -----
        header_frame = Frame(scrollable_frame, bg="#000000")
        header_frame.pack(fill=X, padx=16, pady=(16, 8))
        Label(header_frame, text="⚙️", fg="#00B4FF", bg="#000000", font=("Segoe UI", 16)).pack(side=LEFT)
        Label(header_frame, text="SETTINGS", fg="#00B4FF", bg="#000000",
              font=("Orbitron", 14, "bold")).pack(side=LEFT, padx=5)

        # ----- Section: Virtual Room & Mode -----
        self._section(scrollable_frame, "Virtual Room & Mode", "🏠",
                      self._mode_selector_widget)

        # ----- Section: Gemini Keys -----
        self._section(scrollable_frame, "Gemini Keys (Brain)", "🧠",
                      self._gemini_keys_widget)

        # ----- Section: Other API Keys -----
        self._section(scrollable_frame, "Other API Keys", "🔑",
                      self._other_keys_widget)

        # ----- Section: Discord Bot -----
        self._section(scrollable_frame, "Discord Bot", "💬",
                      self._discord_widget)

        # ----- Section: Gmail Archive -----
        self._section(scrollable_frame, "Gmail Archive (14-day Memory)", "📧",
                      self._gmail_widget)

        # ----- Section: Voice Settings -----
        self._section(scrollable_frame, "Voice Settings", "🔊",
                      self._voice_widget)

        # ----- Save All Button -----
        save_btn = Button(scrollable_frame, text="SAVE ALL KEYS", command=self._save_all_keys,
                          bg="#00B4FF", fg="white", font=("Orbitron", 10, "bold"),
                          relief="flat", cursor="hand2")
        save_btn.pack(fill=X, padx=16, pady=(10, 30), ipady=8)

    # Helper: create a collapsible-like section (always expanded)
    def _section(self, parent, title, icon, content_builder):
        frame = Frame(parent, bg="#0F1F38", bd=1, relief="solid")
        frame.pack(fill=X, padx=16, pady=8)
        # header row
        header = Frame(frame, bg="#0F1F38")
        header.pack(fill=X, padx=12, pady=(12, 4))
        Label(header, text=icon, fg="#00FFFF", bg="#0F1F38", font=("Segoe UI", 12)).pack(side=LEFT)
        Label(header, text=title, fg="#00FFFF", bg="#0F1F38",
              font=("Inter", 11, "bold")).pack(side=LEFT, padx=6)
        # content
        content_frame = Frame(frame, bg="#0F1F38")
        content_frame.pack(fill=X, padx=12, pady=(0, 12))
        content_builder(content_frame)

    # --------------------------------------
    # Mode + Adaptive Room selector
    # --------------------------------------
    def _mode_selector_widget(self, parent):
        # Mode row: HOME / OFFICE / ADAPTIVE
        mode_frame = Frame(parent, bg="#0F1F38")
        mode_frame.pack(fill=X, pady=5)

        modes = ["HOME", "OFFICE", "ADAPTIVE"]
        icons = ["🏠", "💼", "🧭"]
        for i, mode in enumerate(modes):
            btn_frame = Frame(mode_frame, bg="#0F1F38")
            btn_frame.pack(side=LEFT, expand=True, fill=X, padx=4)
            selected = (self.mode_var.get() == mode)
            color = "#00B4FF" if selected else "#0A1628"
            btn = Button(btn_frame, text=f"{icons[i]}\n{mode}", bg=color, fg="white",
                         font=("Orbitron", 8, "bold"), relief="flat",
                         command=lambda m=mode: self._set_mode(m))
            btn.pack(fill=X, ipady=6)

        # Adaptive room row (only visible when ADAPTIVE mode)
        self.adaptive_room_frame = Frame(parent, bg="#0F1F38")
        self.adaptive_room_frame.pack(fill=X, pady=8)
        self._update_adaptive_room_visibility()
        # bind trace to show/hide
        self.mode_var.trace('w', lambda *a: self._update_adaptive_room_visibility())

    def _set_mode(self, mode):
        self.mode_var.set(mode)
        self._save_pref(VyshuConfig.kCurrentMode, mode)

    def _update_adaptive_room_visibility(self):
        if self.mode_var.get() == "ADAPTIVE":
            # rebuild room selector inside self.adaptive_room_frame
            for widget in self.adaptive_room_frame.winfo_children():
                widget.destroy()
            rooms = VyshuConfig.adaptiveRooms
            row_frame = Frame(self.adaptive_room_frame, bg="#0F1F38")
            row_frame.pack()
            for room in rooms:
                sel = (self.adaptive_room_var.get() == room)
                emoji = VyshuConfig.roomEmojis.get(room, "🌍")
                color = "#00B4FF" if sel else "#0A1628"
                btn = Button(row_frame, text=f"{emoji} {room.capitalize()}", bg=color, fg="white",
                             font=("Inter", 9), relief="flat", padx=8, pady=4,
                             command=lambda r=room: self._set_adaptive_room(r))
                btn.pack(side=LEFT, padx=4)
        else:
            for widget in self.adaptive_room_frame.winfo_children():
                widget.destroy()

    def _set_adaptive_room(self, room):
        self.adaptive_room_var.set(room)
        self._save_pref(VyshuConfig.kAdaptiveRoom, room)
        self._update_adaptive_room_visibility()  # refresh highlighting

    # --------------------------------------
    # Gemini Keys (5 fields)
    # --------------------------------------
    def _gemini_keys_widget(self, parent):
        fields = [
            ("Gemini Key 1 (Primary)", self.gemini1_var, VyshuConfig.kGeminiKey1),
            ("Gemini Key 2", self.gemini2_var, VyshuConfig.kGeminiKey2),
            ("Gemini Key 3", self.gemini3_var, VyshuConfig.kGeminiKey3),
            ("Gemini Key 4", self.gemini4_var, VyshuConfig.kGeminiKey4),
            ("Gemini Key 5", self.gemini5_var, VyshuConfig.kGeminiKey5),
        ]
        for label, var, key in fields:
            self._key_row(parent, label, var, key)

    # --------------------------------------
    # Other API keys (Groq, Together, Tavily, ElevenLabs)
    # --------------------------------------
    def _other_keys_widget(self, parent):
        others = [
            ("Groq Key (Translation)", self.groq_var, VyshuConfig.kGroqKey),
            ("Together AI (Image Gen)", self.together_var, VyshuConfig.kTogetherKey),
            ("Tavily (Web Research)", self.tavily_var, VyshuConfig.kTavilyKey),
            ("ElevenLabs (Voice)", self.elevenlabs_var, "elevenlabs_key"),
        ]
        for label, var, key in others:
            self._key_row(parent, label, var, key)

    # --------------------------------------
    # Discord section
    # --------------------------------------
    def _discord_widget(self, parent):
        self._key_row(parent, "Discord Bot Token", self.discord_token_var, "discord_token")
        self._key_row(parent, "Discord Owner ID", self.discord_id_var, "discord_owner_id", hint="Your Discord user ID")

    # --------------------------------------
    # Gmail archive section
    # --------------------------------------
    def _gmail_widget(self, parent):
        self._key_row(parent, "Gmail Address", self.gmail_var, VyshuConfig.kGmailAddress, hint="yourname@gmail.com")
        self._key_row(parent, "Gmail App Password", self.gmail_pwd_var, VyshuConfig.kGmailAppPwd,
                      hint="xxxx xxxx xxxx xxxx", obscure=True)
        archive_btn = Button(parent, text="📦 Archive Expired Memory to Gmail", command=self._archive_to_gmail,
                             bg="#002A4A", fg="#00B4FF", font=("Inter", 10, "bold"),
                             relief="flat", cursor="hand2")
        archive_btn.pack(fill=X, pady=(8, 0), ipady=6)

    # --------------------------------------
    # Voice toggle
    # --------------------------------------
    def _voice_widget(self, parent):
        toggle_frame = Frame(parent, bg="#0F1F38")
        toggle_frame.pack(fill=X)
        Label(toggle_frame, text="Voice Output (TTS)", fg="white", bg="#0F1F38",
              font=("Inter", 11)).pack(side=LEFT)
        cb = Checkbutton(toggle_frame, variable=self.voice_enabled_var, onvalue=True, offvalue=False,
                         command=self._save_voice_setting,
                         bg="#0F1F38", activebackground="#0F1F38", selectcolor="#0F1F38")
        cb.pack(side=RIGHT)

    def _save_voice_setting(self):
        self._save_pref(VyshuConfig.kVoiceEnabled, self.voice_enabled_var.get())

    # --------------------------------------
    # Generic key row with save button
    # --------------------------------------
    def _key_row(self, parent, label_text, variable, pref_key, hint="Enter key...", obscure=False):
        row = Frame(parent, bg="#0F1F38")
        row.pack(fill=X, pady=6)

        Label(row, text=label_text, fg="#7EC8E3", bg="#0F1F38", font=("Inter", 9)).pack(anchor="w")
        entry_frame = Frame(row, bg="#0F1F38")
        entry_frame.pack(fill=X, pady=2)

        show_char = "*" if obscure else None
        entry = Entry(entry_frame, textvariable=variable, bg="#0A1628", fg="white",
                      font=("Inter", 10), insertbackground="white",
                      relief="flat", highlightthickness=1, highlightcolor="#00B4FF")
        if show_char:
            entry.configure(show=show_char)
        entry.pack(side=LEFT, fill=X, expand=True, ipady=4)

        save_btn = Button(entry_frame, text="✓", command=lambda: self._save_key(pref_key, variable.get()),
                          bg="#00B4FF", fg="white", relief="flat", width=3, cursor="hand2")
        save_btn.pack(side=RIGHT, padx=(6, 0))

        # hint as tooltip (simple: placeholder)
        if hint:
            entry.configure(highlightbackground="#1F2F4F")
            # add placeholder via bind focus?
            # simpler: use default text variable but no placeholder logic
            pass


# ================================
# RUN APPLICATION
# ================================
if __name__ == "__main__":
    root = Tk()
    app = SettingsScreen(root)
    root.mainloop()
