// Audio service handling Web Speech API (TTS & STT) and cybernetic sound cues

class AudioService {
  private synth: SpeechSynthesis | null = null;
  private recognition: any = null;
  private isListeningContinuous: boolean = false;
  private audioCtx: AudioContext | null = null;

  constructor() {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      this.synth = window.speechSynthesis;
    }
  }

  private getAudioContext(): AudioContext {
    if (!this.audioCtx) {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      this.audioCtx = new AudioCtx();
    }
    if (this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  // Play crisp cybernetic feedback sounds
  public playSound(type: 'wake' | 'send' | 'alert' | 'click' | 'toggle'): void {
    try {
      const ctx = this.getAudioContext();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);

      const now = ctx.currentTime;
      if (type === 'wake') {
        // Futuristic double chime
        osc.frequency.setValueAtTime(587.33, now); // D5
        osc.frequency.exponentialRampToValueAtTime(880, now + 0.12); // A5
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
        osc.start(now);
        osc.stop(now + 0.25);
      } else if (type === 'send') {
        osc.frequency.setValueAtTime(440, now);
        osc.frequency.exponentialRampToValueAtTime(659.25, now + 0.08);
        gain.gain.setValueAtTime(0.08, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
        osc.start(now);
        osc.stop(now + 0.15);
      } else if (type === 'alert') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(320, now);
        osc.frequency.setValueAtTime(440, now + 0.1);
        gain.gain.setValueAtTime(0.15, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
        osc.start(now);
        osc.stop(now + 0.35);
      } else if (type === 'toggle') {
        osc.frequency.setValueAtTime(520, now);
        gain.gain.setValueAtTime(0.06, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
        osc.start(now);
        osc.stop(now + 0.08);
      } else {
        osc.frequency.setValueAtTime(800, now);
        gain.gain.setValueAtTime(0.04, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
        osc.start(now);
        osc.stop(now + 0.04);
      }
    } catch {
      // AudioContext unavailable or not interacted yet
    }
  }

  // Clean text from emojis, markdown, and [TOOL: ...] tags before speaking
  public cleanTextForSpeech(text: string): string {
    const noEmoji = text.replace(
      /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}\u{2B00}-\u{2BFF}]/gu,
      ''
    );
    const noTools = noEmoji.replace(/\[TOOL:[^\]]*\]/gi, '');
    const clean = noTools.replace(/[*_~`#>-]/g, '').trim();
    return clean;
  }

  public speak(text: string, langCode: string = 'en-US', onEnd?: () => void): void {
    if (!this.synth) return;

    this.stopSpeaking();
    const clean = this.cleanTextForSpeech(text);
    if (!clean) {
      if (onEnd) onEnd();
      return;
    }

    const utterance = new SpeechSynthesisUtterance(clean);
    utterance.rate = 1.0;
    utterance.pitch = 1.05; // Slightly youthful tone for Vyshu
    utterance.lang = langCode;

    // Pick best available voice matching language if available
    const voices = this.synth.getVoices();
    const matchingVoice = voices.find((v) =>
      v.lang.toLowerCase().startsWith(langCode.slice(0, 2).toLowerCase()) &&
      (v.name.toLowerCase().includes('female') || v.name.toLowerCase().includes('google') || v.name.toLowerCase().includes('natural'))
    ) || voices.find((v) => v.lang.toLowerCase().startsWith(langCode.slice(0, 2).toLowerCase()));

    if (matchingVoice) {
      utterance.voice = matchingVoice;
    }

    if (onEnd) {
      utterance.onend = onEnd;
      utterance.onerror = onEnd;
    }

    this.synth.speak(utterance);
  }

  public stopSpeaking(): void {
    if (this.synth) {
      this.synth.cancel();
    }
  }

  // Speech Recognition (STT)
  public isSpeechRecognitionSupported(): boolean {
    return typeof window !== 'undefined' && ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window);
  }

  public startListening(
    onResult: (text: string, isFinal: boolean) => void,
    onError: (err: any) => void,
    onStatusChange?: (listening: boolean) => void,
    lang: string = 'en-IN'
  ): () => void {
    if (!this.isSpeechRecognitionSupported()) {
      onError('Speech recognition not supported in this browser.');
      return () => {};
    }

    const SpeechRec = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    this.recognition = new SpeechRec();
    this.recognition.continuous = true;
    this.recognition.interimResults = true;
    this.recognition.lang = lang;

    this.recognition.onstart = () => {
      this.playSound('wake');
      if (onStatusChange) onStatusChange(true);
    };

    this.recognition.onresult = (event: any) => {
      let interim = '';
      let final = '';

      for (let i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          final += event.results[i][0].transcript;
        } else {
          interim += event.results[i][0].transcript;
        }
      }

      if (final.trim()) {
        onResult(final.trim(), true);
      } else if (interim.trim()) {
        onResult(interim.trim(), false);
      }
    };

    this.recognition.onerror = (event: any) => {
      if (event.error !== 'no-speech') {
        onError(event.error);
      }
    };

    this.recognition.onend = () => {
      if (onStatusChange) onStatusChange(false);
    };

    try {
      this.recognition.start();
    } catch (e) {
      onError(e);
    }

    return () => {
      this.stopListening();
    };
  }

  public stopListening(): void {
    if (this.recognition) {
      try {
        this.recognition.stop();
      } catch {}
      this.recognition = null;
    }
  }
}

export const audioService = new AudioService();
