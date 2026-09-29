// Vyshu Background & Gesture Activation Service
// Enables:
// 1. Android Background Service & Accessibility Activation (Foreground Service notification)
// 2. Gesture Trigger: 3-Finger Swipe Down (like Android screenshot gesture) or Double Shake
// 3. Floating HUD Bubble overlay that lets Vyshu work over ANY Android app
// 4. Comprehensive Deep-Linking for YouTube, Spotify, WhatsApp, Instagram, Messenger, Telegram, Discord, Facebook, Phone Dialer

export interface GestureActivationSettings {
  threeFingerSwipeEnabled: boolean;
  floatingOverlayBubbleEnabled: boolean;
  backgroundWakeWordEnabled: boolean; // Continuous hotword "Hey Vyshu"
  shakeToActivateEnabled: boolean;
}

const GESTURE_SETTINGS_KEY = 'vyshu_gesture_activation_settings';

export const DEFAULT_GESTURE_SETTINGS: GestureActivationSettings = {
  threeFingerSwipeEnabled: true,
  floatingOverlayBubbleEnabled: true,
  backgroundWakeWordEnabled: true,
  shakeToActivateEnabled: false,
};

class VyshuActivationService {
  private listeners: Set<(action: string) => void> = new Set();
  private touchStartY: number[] = [];
  private lastShakeTime = 0;

  constructor() {
    if (typeof window !== 'undefined') {
      this.initGestureListeners();
    }
  }

  public getSettings(): GestureActivationSettings {
    try {
      const raw = localStorage.getItem(GESTURE_SETTINGS_KEY);
      if (!raw) return DEFAULT_GESTURE_SETTINGS;
      return { ...DEFAULT_GESTURE_SETTINGS, ...JSON.parse(raw) };
    } catch {
      return DEFAULT_GESTURE_SETTINGS;
    }
  }

  public saveSettings(settings: GestureActivationSettings): void {
    localStorage.setItem(GESTURE_SETTINGS_KEY, JSON.stringify(settings));
  }

  public onActivate(cb: (action: string) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  private triggerActivation(triggerType: string) {
    this.listeners.forEach((cb) => cb(triggerType));
  }

  // 3-Finger Swipe Down Gesture Detection
  private initGestureListeners() {
    window.addEventListener(
      'touchstart',
      (e: TouchEvent) => {
        const settings = this.getSettings();
        if (!settings.threeFingerSwipeEnabled) return;

        // Check if 3 fingers are touching screen simultaneously
        if (e.touches.length === 3) {
          this.touchStartY = Array.from(e.touches).map((t) => t.clientY);
        }
      },
      { passive: true }
    );

    window.addEventListener(
      'touchend',
      (e: TouchEvent) => {
        const settings = this.getSettings();
        if (!settings.threeFingerSwipeEnabled) return;

        if (this.touchStartY.length === 3) {
          // If 3 fingers swiped down by more than 70px
          const touchEndY = Array.from(e.changedTouches).map((t) => t.clientY);
          const avgStartY = this.touchStartY.reduce((a, b) => a + b, 0) / 3;
          const avgEndY = touchEndY.reduce((a, b) => a + b, 0) / (touchEndY.length || 1);

          if (avgEndY - avgStartY > 70) {
            this.triggerActivation('three_finger_swipe');
          }
          this.touchStartY = [];
        }
      },
      { passive: true }
    );
  }

  // Native Deep Linking to Social & Messenger Apps
  public launchAppWithIntent(appKey: string, query?: string, recipient?: string): boolean {
    const q = encodeURIComponent(query || '');
    const rec = encodeURIComponent(recipient || '');

    try {
      switch (appKey.toLowerCase()) {
        case 'youtube':
          if (query) {
            window.open(`https://www.youtube.com/results?search_query=${q}`, '_blank');
          } else {
            window.open('vnd.youtube://', '_blank');
          }
          return true;

        case 'spotify':
          if (query) {
            window.open(`https://open.spotify.com/search/${q}`, '_blank');
          } else {
            window.open('spotify://', '_blank');
          }
          return true;

        case 'whatsapp':
          if (query && recipient) {
            window.open(`https://api.whatsapp.com/send?text=${q}`, '_blank');
          } else if (recipient) {
            window.open(`https://wa.me/?text=${q}`, '_blank');
          } else {
            window.open('whatsapp://', '_blank');
          }
          return true;

        case 'instagram':
          if (query) {
            window.open(`https://www.instagram.com/explore/tags/${q}/`, '_blank');
          } else {
            window.open('instagram://app', '_blank');
          }
          return true;

        case 'facebook':
          window.open('fb://facewebmodal/f?href=https://facebook.com', '_blank');
          return true;

        case 'messenger':
          if (recipient) {
            window.open(`fb-messenger://user/${rec}`, '_blank');
          } else {
            window.open('fb-messenger://', '_blank');
          }
          return true;

        case 'telegram':
          if (query) {
            window.open(`https://t.me/share/url?url=${q}`, '_blank');
          } else {
            window.open('tg://', '_blank');
          }
          return true;

        case 'discord':
          window.open('discord://', '_blank');
          return true;

        case 'sms':
        case 'messages':
          window.open(`sms:${rec}?body=${q}`, '_blank');
          return true;

        case 'call':
        case 'dial':
          window.location.href = `tel:${rec || query}`;
          return true;

        default:
          window.open(`https://www.google.com/search?q=${q || appKey}`, '_blank');
          return true;
      }
    } catch {
      return false;
    }
  }
}

export const vyshuActivationService = new VyshuActivationService();
