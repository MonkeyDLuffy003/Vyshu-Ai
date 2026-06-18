import struct
import os
import flet as ft

try:
    import pvporcupine
    import pyaudio
    import speech_recognition as sr
    from gtts import gTTS
    VOICE_AVAILABLE = True
except ImportError:
    VOICE_AVAILABLE = False
# ---------------------------------------------------------
# THE MOUTH: TEXT-TO-SPEECH
# ---------------------------------------------------------
def speak(page: ft.Page, text: str):
    """Generates a natural female voice and plays it through Flet's audio system."""
    try:
        # We use gTTS for a much more natural, human-sounding voice
        # 'en-in' gives a clear, highly professional English accent
        tts = gTTS(text=text, lang='en-in', slow=False)
        audio_file = "vyshu_response.mp3"
        tts.save(audio_file)
        
        # Load and play the audio via the Android UI
        audio = ft.Audio(src=audio_file, autoplay=True)
        page.overlay.append(audio)
        page.update()
        
    except Exception as e:
        print(f"⚠️ Voice Output Error: {str(e)}")

# ---------------------------------------------------------
# THE EARS: SPEECH-TO-TEXT (Active Listening)
# ---------------------------------------------------------
def listen_for_command():
    """Listens for the user's actual request after the wake word is detected."""
    recognizer = sr.Recognizer()
    
    with sr.Microphone() as source:
        print("🎙️ Vyshu is listening...")
        # Adjust for background noise quickly
        recognizer.adjust_for_ambient_noise(source, duration=0.5)
        try:
            audio = recognizer.listen(source, timeout=5, phrase_time_limit=15)
            command = recognizer.recognize_google(audio)
            print(f"Teja said: {command}")
            return command
        except sr.WaitTimeoutError:
            return None
        except sr.UnknownValueError:
            return "⚠️ I didn't quite catch that."
        except sr.RequestError:
            return "⚠️ My speech recognition servers are currently unreachable."

# ---------------------------------------------------------
# THE WAKE-WORD: 24/7 BACKGROUND LISTENER
# ---------------------------------------------------------
def start_wake_word_loop(picovoice_access_key, page, on_wake_callback):
    """
    Runs silently in the background. Draws almost zero battery.
    Wakes up ONLY when it hears "Computer" or a custom keyword.
    """
    try:
        # Initialize Porcupine with a built-in keyword (e.g., 'computer' or 'jarvis')
        # Note: To use the exact word "Vyshu", you would train a custom model on the Picovoice Console.
        porcupine = pvporcupine.create(
            access_key=picovoice_access_key,
            keywords=["computer"] 
        )
        
        pa = pyaudio.PyAudio()
        audio_stream = pa.open(
            rate=porcupine.sample_rate,
            channels=1,
            format=pyaudio.paInt16,
            input=True,
            frames_per_buffer=porcupine.frame_length
        )
        
        print("🛡️ Silent wake-word listener active. Say the wake word...")

        while True:
            # Read audio data from the microphone
            pcm = audio_stream.read(porcupine.frame_length, exception_on_overflow=False)
            pcm = struct.unpack_from("h" * porcupine.frame_length, pcm)
            
            # Check if the wake word was spoken
            keyword_index = porcupine.process(pcm)
            if keyword_index >= 0:
                print("✨ Wake word detected!")
                speak(page, "Yes, Teja?")
                
                # Hand over to the active listener
                command = listen_for_command()
                if command and not command.startswith("⚠️"):
                    # Pass the command back to main.py to be sent to brain.py
                    on_wake_callback(command)

    except Exception as e:
        print(f"⚠️ Wake Word Engine Error: {str(e)}")
    finally:
        if 'audio_stream' in locals():
            audio_stream.close()
        if 'pa' in locals():
            pa.terminate()
        if 'porcupine' in locals():
            porcupine.delete()
          
