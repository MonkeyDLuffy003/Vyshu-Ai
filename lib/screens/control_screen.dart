import json
import os
from tkinter import *
from tkinter import ttk, messagebox

# ----------------------------------------------------------------------
# Configuration file handling (replaces SharedPreferences)
# ----------------------------------------------------------------------
CONFIG_FILE = "vyshu_config.json"

DEFAULT_CONFIG = {
    "current_mode": "HOME",
    "adaptive_room": "park",
    "voice_enabled": True,
    "gemini_key_1": "",
    "gemini_key_2": "",
    "gemini_key_3": "",
    "groq_key": "",
    "together_key": "",
    "tavily_key": "",
    "elevenlabs_key": "",
    "discord_token": "",
    "discord_owner_id": "",
    "gmail_address": "",
    "gmail_app_password": ""
}

ADAPTIVE_ROOMS = ["park", "cafe", "library", "ocean"]
ROOM_EMOJIS = {
    "park": "🌳", "cafe": "☕", "library": "📚", "ocean": "🌊"
}


def load_config():
    if not os.path.exists(CONFIG_FILE):
        save_config(DEFAULT_CONFIG)
        return DEFAULT_CONFIG.copy()
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)


def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


# ----------------------------------------------------------------------
# Stub for Gmail archive (replace with actual implementation)
# ----------------------------------------------------------------------
def archive_to_gmail():
    # In your actual application, implement email sending logic here
    messagebox.showinfo("Archive", "Memory archived to Gmail (stub).")
    return "Archive completed (stub)"


# ----------------------------------------------------------------------
# Main Settings Window (Tkinter)
# ----------------------------------------------------------------------
class SettingsApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Vyshu AI – Settings")
        self.root.geometry("550x750")
        self.root.configure(bg="#000000")
        self.root.resizable(True, True)

        # Load existing config
        self.config = load_config()

        # StringVars for all settings
        self.mode_var = StringVar(value=self.config["current_mode"])
        self.room_var = StringVar(value=self.config["adaptive_room"])
        self.voice_var = BooleanVar(value=self.config["voice_enabled"])

        self.gemini1_var = StringVar(value=self.config["gemini_key_1"])
        self.gemini2_var = StringVar(value=self.config["gemini_key_2"])
        self.gemini3_var = StringVar(value=self.config["gemini_key_3"])
        self.groq_var = StringVar(value=self.config["groq_key"])
        self.together_var = StringVar(value=self.config["together_key"])
        self.tavily_var = StringVar(value=self.config["tavily_key"])
        self.elevenlabs_var = StringVar(value=self.config["elevenlabs_key"])
        self.discord_token_var = StringVar(value=self.config["discord_token"])
        self.discord_id_var = StringVar(value=self.config["discord_owner_id"])
        self.gmail_addr_var = StringVar(value=self.config["gmail_address"])
        self.gmail_pwd_var = StringVar(value=self.config["gmail_app_password"])

        # Apply dark style to ttk widgets
        self.style = ttk.Style()
        self.style.theme_use("clam")
        self.style.configure("TLabel", background="#000000", foreground="#FFFFFF",
                             font=("Inter", 10))
        self.style.configure("TFrame", background="#000000")
        self.style.configure("TLabelframe", background="#0F1F38", foreground="#00FFFF",
                             font=("Inter", 10, "bold"))
        self.style.configure("TLabelframe.Label", background="#0F1F38", foreground="#00FFFF")
        self.style.configure("TButton", background="#00B4FF", foreground="#000000",
                             font=("Inter", 10, "bold"), borderwidth=0)
        self.style.map("TButton", background=[("active", "#0099DD")])

        # Create scrollable canvas
        self.canvas = Canvas(root, bg="#000000", highlightthickness=0)
        self.scrollbar = Scrollbar(root, orient="vertical", command=self.canvas.yview)
        self.scrollable_frame = Frame(self.canvas, bg="#000000")
        self.scrollable_frame.bind("<Configure>", lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))
        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=self.scrollbar.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        self.scrollbar.pack(side="right", fill="y")

        # Build UI inside scrollable_frame
        self.build_ui()

        # Bind mouse wheel scrolling
        self.root.bind("<MouseWheel>", self._on_mousewheel)

    def _on_mousewheel(self, event):
        self.canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

    # ------------------------------------------------------------------
    # UI Construction
    # ------------------------------------------------------------------
    def build_ui(self):
        pad = 10
        # Header
        header = Frame(self.scrollable_frame, bg="#000000")
        header.pack(fill="x", pady=(10, 5), padx=pad)
        Label(header, text="⚙️ SETTINGS", font=("Orbitron", 16, "bold"),
              fg="#00B4FF", bg="#000000").pack(side="left")

        # ------------------- Virtual Room Section -------------------
        self.make_section("Virtual Room", "🏠", [
            self.mode_selector(),
            ("adaptive_room", self.adaptive_room_selector) if self.mode_var.get() == "ADAPTIVE" else None
        ])

        # ------------------- Gemini Keys Section -------------------
        self.make_section("Gemini Keys", "🧠", [
            self.key_row("Gemini Key 1", self.gemini1_var, "gemini_key_1"),
            self.key_row("Gemini Key 2", self.gemini2_var, "gemini_key_2"),
            self.key_row("Gemini Key 3", self.gemini3_var, "gemini_key_3"),
        ])

        # ------------------- Other Keys Section -------------------
        self.make_section("Other Keys", "🔑", [
            self.key_row("Groq Key", self.groq_var, "groq_key"),
            self.key_row("Together AI", self.together_var, "together_key"),
            self.key_row("Tavily Search", self.tavily_var, "tavily_key"),
            self.key_row("ElevenLabs", self.elevenlabs_var, "elevenlabs_key"),
        ])

        # ------------------- Discord Section -------------------
        self.make_section("Discord", "🎮", [
            self.key_row("Discord Token", self.discord_token_var, "discord_token", obscured=True),
            self.key_row("Discord Owner ID", self.discord_id_var, "discord_owner_id"),
        ])

        # ------------------- Gmail Archive Section -------------------
        self.make_section("Gmail Archive", "📧", [
            self.key_row("Gmail Address", self.gmail_addr_var, "gmail_address"),
            self.key_row("App Password", self.gmail_pwd_var, "gmail_app_password", obscured=True),
            self.archive_button(),
        ])

        # ------------------- Voice Section -------------------
        self.make_section("Voice", "🔊", [
            self.voice_toggle()
        ])

        # ------------------- Save All Button -------------------
        btn_save_all = Button(self.scrollable_frame, text="SAVE ALL KEYS",
                              bg="#00B4FF", fg="white", font=("Orbitron", 12, "bold"),
                              relief="flat", activebackground="#0099DD",
                              command=self.save_all)
        btn_save_all.pack(pady=(20, 30), padx=pad, fill="x")

    def make_section(self, title, emoji, widgets):
        """Create a titled container frame and pack given widgets inside."""
        section = LabelFrame(self.scrollable_frame, text=f" {emoji} {title} ", style="TLabelframe")
        section.pack(fill="x", padx=10, pady=8)
        for w in widgets:
            if w is None:
                continue
            if callable(w):
                w()      # function that adds its own widgets inside section
            else:
                w.pack(fill="x", padx=8, pady=4)

    # --------------------------------------------------------------
    # Mode selector (HOME / OFFICE / ADAPTIVE)
    # --------------------------------------------------------------
    def mode_selector(self):
        frame = Frame(self.scrollable_frame, bg="#0F1F38")
        frame.pack(fill="x", pady=5)
        modes = [("HOME", "🏠"), ("OFFICE", "💼"), ("ADAPTIVE", "🌍")]
        for i, (mode, icon) in enumerate(modes):
            btn = Button(frame, text=f"{icon} {mode}", font=("Orbitron", 9),
                         bg="#00B4FF" if self.mode_var.get() == mode else "#0A1628",
                         fg="white", relief="flat", padx=10, pady=5,
                         command=lambda m=mode: self.change_mode(m))
            btn.pack(side="left", expand=True, fill="x", padx=2)
        return frame

    def change_mode(self, mode):
        self.mode_var.set(mode)
        self.config["current_mode"] = mode
        save_config(self.config)
        # Refresh UI to show/hide adaptive room selector
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()
        self.build_ui()

    # --------------------------------------------------------------
    # Adaptive room selector (pill buttons)
    # --------------------------------------------------------------
    def adaptive_room_selector(self):
        frame = Frame(self.scrollable_frame, bg="#0F1F38")
        frame.pack(fill="x", pady=5)
        for room in ADAPTIVE_ROOMS:
            emoji = ROOM_EMOJIS.get(room, "🌍")
            bg = "#00B4FF" if self.room_var.get() == room else "#0A1628"
            btn = Button(frame, text=f"{emoji} {room.capitalize()}", font=("Inter", 10),
                         bg=bg, fg="white", relief="flat", padx=12, pady=4,
                         command=lambda r=room: self.change_room(r))
            btn.pack(side="left", padx=4, pady=2)
        return frame

    def change_room(self, room):
        self.room_var.set(room)
        self.config["adaptive_room"] = room
        save_config(self.config)

    # --------------------------------------------------------------
    # Single key row with save button
    # --------------------------------------------------------------
    def key_row(self, label, var, config_key, obscured=False):
        frame = Frame(self.scrollable_frame, bg="#0F1F38")
        frame.pack(fill="x", pady=4)

        Label(frame, text=label, font=("Inter", 9), fg="#7EC8E3", bg="#0F1F38").pack(anchor="w")

        row = Frame(frame, bg="#0F1F38")
        row.pack(fill="x")
        entry = Entry(row, textvariable=var, bg="#0A1628", fg="white",
                      font=("Inter", 11), insertbackground="white",
                      relief="flat", show="*" if obscured else "")
        entry.pack(side="left", fill="x", expand=True, padx=(0, 8), ipady=5)

        btn_save = Button(row, text="✓", width=3, bg="#00B4FF", fg="white",
                          relief="flat", command=lambda: self.save_single(config_key, var))
        btn_save.pack(side="right")
        return frame

    def save_single(self, config_key, var):
        self.config[config_key] = var.get().strip()
        save_config(self.config)
        messagebox.showinfo("Saved", f"{config_key} saved successfully.")

    # --------------------------------------------------------------
    # Voice toggle
    # --------------------------------------------------------------
    def voice_toggle(self):
        frame = Frame(self.scrollable_frame, bg="#0F1F38")
        frame.pack(fill="x", pady=4)
        Checkbutton(frame, text="Voice Output", variable=self.voice_var,
                    onvalue=True, offvalue=False,
                    bg="#0F1F38", fg="white", selectcolor="#0F1F38",
                    command=self.save_voice_setting).pack(anchor="w")
        return frame

    def save_voice_setting(self):
        self.config["voice_enabled"] = self.voice_var.get()
        save_config(self.config)

    # --------------------------------------------------------------
    # Archive button
    # --------------------------------------------------------------
    def archive_button(self):
        btn = Button(self.scrollable_frame, text="📁 Archive Memory to Gmail",
                     bg="#002A4A", fg="#00B4FF", font=("Inter", 11, "bold"),
                     relief="solid", bd=1, command=archive_to_gmail)
        btn.pack(fill="x", pady=(8, 0))
        return btn

    # --------------------------------------------------------------
    # Save all keys at once
    # --------------------------------------------------------------
    def save_all(self):
        self.config.update({
            "gemini_key_1": self.gemini1_var.get().strip(),
            "gemini_key_2": self.gemini2_var.get().strip(),
            "gemini_key_3": self.gemini3_var.get().strip(),
            "groq_key": self.groq_var.get().strip(),
            "together_key": self.together_var.get().strip(),
            "tavily_key": self.tavily_var.get().strip(),
            "elevenlabs_key": self.elevenlabs_var.get().strip(),
            "discord_token": self.discord_token_var.get().strip(),
            "discord_owner_id": self.discord_id_var.get().strip(),
            "gmail_address": self.gmail_addr_var.get().strip(),
            "gmail_app_password": self.gmail_pwd_var.get().strip(),
            "voice_enabled": self.voice_var.get(),
            "current_mode": self.mode_var.get(),
            "adaptive_room": self.room_var.get()
        })
        save_config(self.config)
        messagebox.showinfo("Saved", "All settings saved successfully!")


# ----------------------------------------------------------------------
if __name__ == "__main__":
    root = Tk()
    app = SettingsApp(root)
    root.mainloop()
