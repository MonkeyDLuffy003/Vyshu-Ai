import tkinter as tk
from tkinter import messagebox
from google_fonts import GoogleFonts  # Placeholder for Google Fonts equivalent in Python
import json  # For simulating SharedPreferences

class SettingsScreen(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.mode = "HOME"
        self.adaptive_room = "park"
        self.voice_enabled = True
        self.save_status = {}
        self.controllers = {}
        
        # Synced with ALL keys in VyshuConfig
        self.key_fields = [
            KeyField("Gemini Key 1", VyshuConfig.kGeminiKey1),
            KeyField("Gemini Key 2", VyshuConfig.kGeminiKey2),
            KeyField("Gemini Key 3", VyshuConfig.kGeminiKey3),
            KeyField("Gemini Key 4", VyshuConfig.kGeminiKey4),
            KeyField("Gemini Key 5", VyshuConfig.kGeminiKey5),
            KeyField("Groq API Key", VyshuConfig.kGroqKey),
            KeyField("Together AI", VyshuConfig.kTogetherKey),
            KeyField("Tavily Search", VyshuConfig.kTavilyKey),
            KeyField("LinkedIn Token", VyshuConfig.kLinkedInToken),
            KeyField("Gmail Address", VyshuConfig.kGmailAddress, hint="yourname@gmail.com"),
            KeyField("App Password", VyshuConfig.kGmailAppPwd, hint="xxxx xxxx xxxx xxxx", obscure=True),
        ]

        self.init_ui()
        self.load_settings()

    def init_ui(self):
        self.pack()
        self.create_widgets()

    def create_widgets(self):
        # Create header
        header = tk.Label(self, text="SETTINGS", font=GoogleFonts.orbitron(size=16, weight='bold'))
        header.pack()

        # Create sections
        self.build_section("Virtual Room and Mode", self.mode_selector())
        self.build_section("Vyshu Wardrobe", self.wardrobe_grid())
        self.build_section("API Keys", self.build_key_fields())
        self.build_section("Gmail Archive", self.archive_button())
        self.build_section("Voice", self.toggle_row("Voice Output", self.voice_enabled))

    def build_section(self, title, content):
        section_frame = tk.Frame(self)
        section_frame.pack(pady=16)
        
        title_label = tk.Label(section_frame, text=title, font=GoogleFonts.inter(size=13, weight='medium'))
        title_label.pack()
        
        content.pack()

    def load_settings(self):
        # Simulating SharedPreferences
        try:
            with open('preferences.json', 'r') as f:
                prefs = json.load(f)
                self.mode = prefs.get(VyshuConfig.kCurrentMode, "HOME")
                self.adaptive_room = prefs.get(VyshuConfig.kAdaptiveRoom, "park")
                self.voice_enabled = prefs.get(VyshuConfig.kVoiceEnabled, True)
                for field in self.key_fields:
                    saved = prefs.get(field.pref_key, "")
                    self.controllers[field.pref_key].set(saved)
                    self.save_status[field.pref_key] = bool(saved)
        except FileNotFoundError:
            pass  # Handle the case where preferences file doesn't exist

    def save_key(self, pref_key, label):
        value = self.controllers[pref_key].get().strip()
        if not value:
            self.set_status(pref_key, False)
            self.show_snack(f"⚠️ {label} cannot be empty")
            return
        try:
            with open('preferences.json', 'r+') as f:
                prefs = json.load(f)
                prefs[pref_key] = value
                f.seek(0)
                json.dump(prefs, f)
                f.truncate()
                self.set_status(pref_key, True)
                self.show_snack(f"✅ {label} saved!")
        except Exception as e:
            self.set_status(pref_key, False)
            self.show_snack(f"❌ Error: {e}")

    def set_status(self, pref_key, status):
        self.save_status[pref_key] = status
        if status is not None:
            self.after(3000, lambda: self.save_status.update({pref_key: None}))

    def toggle_row(self, label, value):
        frame = tk.Frame(self)
        label_widget = tk.Label(frame, text=label)
        label_widget.pack(side=tk.LEFT)
        
        toggle = tk.Checkbutton(frame, variable=value, command=lambda: self.save_pref(VyshuConfig.kVoiceEnabled, value.get()))
        toggle.pack(side=tk.RIGHT)

        return frame

    def show_snack(self, msg):
        messagebox.showinfo("Notification", msg)

class KeyField:
    def __init__(self, label, pref_key, hint="Enter key...", obscure=False):
        self.label = label
        self.pref_key = pref_key
        self.hint = hint
        self.obscure = obscure

# Example usage
if __name__ == "__main__":
    root = tk.Tk()
    app = SettingsScreen(master=root)
    app.mainloop()
