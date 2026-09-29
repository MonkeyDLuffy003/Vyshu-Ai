import {
  ApiVaultKeys,
  ChatMessage,
  ContactItem,
  DeviceStatus,
  FitnessLog,
  TaskItem,
  ConnectedBot,
  VyshuCustomization,
  CustomEmoji,
  StickerPack,
} from '../types';

const KEYS = {
  CHAT_HISTORY: 'vyshu_chat_history',
  VAULT_KEYS: 'vyshu_vault_keys',
  TASKS: 'vyshu_tasks',
  FITNESS: 'vyshu_fitness_logs',
  CONTACTS: 'vyshu_contacts',
  DEVICE_STATUS: 'vyshu_device_status',
  ONBOARDING_DONE: 'vyshu_onboarding_complete',
  CHAT_MODE: 'vyshu_chat_mode', // 'HOME' | 'OFFICE'
  VOICE_OUTPUT: 'vyshu_voice_output',
  SELECTED_LANG: 'vyshu_selected_lang',
  CONNECTED_BOTS: 'vyshu_connected_bots',
  CUSTOMIZATION: 'vyshu_customization_settings',
  CUSTOM_EMOJIS: 'vyshu_custom_emojis',
  STICKER_PACKS: 'vyshu_sticker_packs',
};

export const DEFAULT_CUSTOMIZATION: VyshuCustomization = {
  avatarUrl: '/assets/images/vyshu_avatar.png',
  avatarPresetId: 'vyshu-authentic',
  wallpaperUrl: 'gradient:deep-cyber',
  wallpaperPresetId: 'deep-cyber',
  theme: 'cyber-cyan',
  fontStyle: 'sans',
  layout: 'bubble',
  lastSeenMode: 'online',
  customLastSeenText: 'Active now • Synchronized with Teja',
  bubbleOpacity: 92,
  fontSize: 'medium',
};

export const DEFAULT_STICKER_PACKS: StickerPack[] = [
  {
    id: 'pack-vyshu-core',
    title: 'Vyshu Reactions',
    author: 'Vyshu AI Studio',
    stickers: [
      { id: 'v1', name: 'happy', emoji: '😊', label: 'Happy Vyshu' },
      { id: 'v2', name: 'thumbsup', emoji: '👍', label: 'Thumbs Up' },
      { id: 'v3', name: 'hi', emoji: '👋', label: 'Hi Teja' },
      { id: 'v4', name: 'excited', emoji: '✨', label: 'Excited' },
      { id: 'v5', name: 'celebrate', emoji: '🎉', label: 'Celebrate' },
      { id: 'v6', name: 'calm', emoji: '😌', label: 'Calm' },
      { id: 'v7', name: 'slipper1', emoji: '🩴', label: 'Slipper Warning' },
      { id: 'v8', name: 'gun1', emoji: '🔫', label: 'Water Gun Alert' },
      { id: 'v9', name: 'wink', emoji: '😉', label: 'Wink' },
      { id: 'v10', name: 'salute', emoji: '🫡', label: 'At Your Command' },
      { id: 'v11', name: 'cool', emoji: '😎', label: 'Jarvis Cool' },
      { id: 'v12', name: 'fire', emoji: '🔥', label: 'Peak Performance' },
    ],
  },
  {
    id: 'pack-ironman-jarvis',
    title: 'Stark & J.A.R.V.I.S. Protocol',
    author: 'Avengers Tactical Hub',
    stickers: [
      { id: 'j1', name: 'arc_reactor', emoji: '💠', label: 'Arc Core 100%' },
      { id: 'j2', name: 'iron_mask', emoji: '🤖', label: 'Armor Calibrated' },
      { id: 'j3', name: 'shield', emoji: '🛡️', label: 'Defense Protocol' },
      { id: 'j4', name: 'bolt', emoji: '⚡', label: 'Full Power' },
      { id: 'j5', name: 'target', emoji: '🎯', label: 'Target Locked' },
      { id: 'j6', name: 'satellite', emoji: '🛰️', label: 'Orbital Uplink' },
    ],
  },
  {
    id: 'pack-vaani-beats',
    title: 'Vaani Sound Engine',
    author: 'Vaani Beats Team',
    stickers: [
      { id: 'm1', name: 'headphones', emoji: '🎧', label: 'Vibe Mode' },
      { id: 'm2', name: 'disc', emoji: '💿', label: 'Playing Local' },
      { id: 'm3', name: 'notes', emoji: '🎶', label: 'Melody Flow' },
      { id: 'm4', name: 'speaker', emoji: '🔊', label: 'Bass Boosted' },
    ],
  },
];

export const DEFAULT_CUSTOM_EMOJIS: CustomEmoji[] = [
  { id: 'e1', code: ':vyshu_heart:', name: 'Vyshu Cyber Heart', iconData: '💙', category: 'Vyshu AI', createdAt: new Date().toISOString() },
  { id: 'e2', code: ':teja_crown:', name: 'Teja King Crown', iconData: '👑', category: 'Owner', createdAt: new Date().toISOString() },
  { id: 'e3', code: ':jarvis_core:', name: 'Jarvis Core', iconData: '🌐', category: 'Jarvis', createdAt: new Date().toISOString() },
  { id: 'e4', code: ':vaani_music:', name: 'Vaani Engine', iconData: '🎵', category: 'Music', createdAt: new Date().toISOString() },
  { id: 'e5', code: ':gym_streak:', name: 'Gym 4 Days', iconData: '💪', category: 'Fitness', createdAt: new Date().toISOString() },
  { id: 'e6', code: ':rocket_boost:', name: 'Max Overdrive', iconData: '🚀', category: 'Action', createdAt: new Date().toISOString() },
];

// Initial default connected bots including Vaani Music Bot and Discord Master Bot
const DEFAULT_CONNECTED_BOTS: ConnectedBot[] = [
  {
    id: 'bot-vaani',
    name: 'Vaani Music Bot',
    type: 'music_bot',
    botId: 'vaani_music_engine_01',
    secretToken: 'vaani_offline_secure_key_teja',
    packageName: 'com.teja.vaani',
    endpointUrl: 'intent://vaani?action=play#Intent;scheme=vaani;package=com.teja.vaani;end',
    isLocked: true,
    lockPin: '1234',
    isActive: true,
    voiceTriggerWords: ['vaani', 'play songs', 'music', 'offline songs'],
    createdAt: new Date().toISOString(),
  },
  {
    id: 'bot-discord',
    name: 'Discord Vyshu Master',
    type: 'discord_bot',
    botId: '119283746592817263',
    secretToken: 'MTE5Mjg3NzYxNjkxMDk5NTQ1Ng.G_secure_bot_token_sample',
    endpointUrl: 'https://discord.com/api/v10',
    isLocked: true,
    lockPin: '1234',
    isActive: true,
    voiceTriggerWords: ['discord', 'server', 'translate channel'],
    createdAt: new Date().toISOString(),
  },
];

// Initial default contacts
const DEFAULT_CONTACTS: ContactItem[] = [
  { id: '1', name: 'Arni Manikanta Teja Swaroop', phone: '+91 98765 43210', email: 'manikantatejaswarooparni@gmail.com', avatarColor: '#00ccff' },
  { id: '2', name: 'Mom', phone: '+91 94401 23456', avatarColor: '#ec4899' },
  { id: '3', name: 'Dad', phone: '+91 98480 65432', avatarColor: '#3b82f6' },
  { id: '4', name: 'Gym Trainer', phone: '+91 99887 76655', avatarColor: '#10b981' },
  { id: '5', name: 'Discord Team Lead', phone: '+1 555 019 2834', avatarColor: '#8b5cf6' },
];

// Initial fitness logs: user mentioned "im started workouts since 4 days"
const DEFAULT_FITNESS_LOGS: FitnessLog[] = [
  {
    id: 'f1',
    date: new Date(Date.now() - 3 * 86400000).toISOString().split('T')[0],
    dayNumber: 1,
    workoutType: 'Full Body Primer & Pushups',
    durationMinutes: 30,
    caloriesBurned: 180,
    notes: 'First day kickstart! Pushups + stretching.',
    completed: true,
  },
  {
    id: 'f2',
    date: new Date(Date.now() - 2 * 86400000).toISOString().split('T')[0],
    dayNumber: 2,
    workoutType: 'Dumbbell Upper Body & Core',
    durationMinutes: 40,
    caloriesBurned: 240,
    notes: 'Chest press and core crunches.',
    completed: true,
  },
  {
    id: 'f3',
    date: new Date(Date.now() - 1 * 86400000).toISOString().split('T')[0],
    dayNumber: 3,
    workoutType: 'Legs & Cardio Intervals',
    durationMinutes: 35,
    caloriesBurned: 260,
    notes: 'Squats, lunges, and jumping jacks.',
    completed: true,
  },
  {
    id: 'f4',
    date: new Date().toISOString().split('T')[0],
    dayNumber: 4,
    workoutType: 'Arms & High Intensity Cardio',
    durationMinutes: 45,
    caloriesBurned: 310,
    notes: 'Day 4 completed strong! Vyshu tracking active.',
    completed: true,
  },
];

const DEFAULT_VAULT_KEYS: ApiVaultKeys = {
  gemini_1: '',
  gemini_2: '',
  gemini_3: '',
  gemini_4: '',
  gemini_5: '',
  groq: '',
  discord_token: '',
  discord_id: '',
  discord_bot_url: 'http://localhost:8080',
  gcs_json: '',
  useCloudRetention30Days: false,
};

export const storageService = {
  // Chat History with 14-day or 30-day retention
  getChatHistory(): ChatMessage[] {
    try {
      const raw = localStorage.getItem(KEYS.CHAT_HISTORY);
      if (!raw) return [];
      const parsed: ChatMessage[] = JSON.parse(raw);
      return parsed;
    } catch {
      return [];
    }
  },

  saveChatHistory(history: ChatMessage[], allow30Days: boolean = false): void {
    const days = allow30Days ? 30 : 14;
    const cutoffTime = Date.now() - days * 24 * 60 * 60 * 1000;

    const scrubbed = history.filter((msg) => {
      if (!msg.timestamp) return true;
      const ts = new Date(msg.timestamp).getTime();
      return isNaN(ts) || ts >= cutoffTime;
    });

    try {
      localStorage.setItem(KEYS.CHAT_HISTORY, JSON.stringify(scrubbed));
    } catch (e) {
      console.warn('LocalStorage quota limit reached, pruning older messages', e);
      if (scrubbed.length > 30) {
        localStorage.setItem(KEYS.CHAT_HISTORY, JSON.stringify(scrubbed.slice(-30)));
      }
    }
  },

  clearChatHistory(): void {
    localStorage.removeItem(KEYS.CHAT_HISTORY);
  },

  // Vault Keys
  getVaultKeys(): ApiVaultKeys {
    try {
      const raw = localStorage.getItem(KEYS.VAULT_KEYS);
      if (!raw) return DEFAULT_VAULT_KEYS;
      return { ...DEFAULT_VAULT_KEYS, ...JSON.parse(raw) };
    } catch {
      return DEFAULT_VAULT_KEYS;
    }
  },

  saveVaultKeys(keys: ApiVaultKeys): void {
    localStorage.setItem(KEYS.VAULT_KEYS, JSON.stringify(keys));
  },

  // Tasks
  getTasks(): TaskItem[] {
    try {
      const raw = localStorage.getItem(KEYS.TASKS);
      if (!raw) {
        return [
          { id: '1', title: 'Complete 45 min workout session', completed: true, createdAt: new Date().toISOString() },
          { id: '2', title: 'Drink 3 liters of water today', completed: false, createdAt: new Date().toISOString() },
          { id: '3', title: 'Check Discord server activity with Vyshu bot', completed: false, createdAt: new Date().toISOString() },
        ];
      }
      return JSON.parse(raw);
    } catch {
      return [];
    }
  },

  saveTasks(tasks: TaskItem[]): void {
    localStorage.setItem(KEYS.TASKS, JSON.stringify(tasks));
  },

  // Fitness
  getFitnessLogs(): FitnessLog[] {
    try {
      const raw = localStorage.getItem(KEYS.FITNESS);
      if (!raw) {
        localStorage.setItem(KEYS.FITNESS, JSON.stringify(DEFAULT_FITNESS_LOGS));
        return DEFAULT_FITNESS_LOGS;
      }
      return JSON.parse(raw);
    } catch {
      return DEFAULT_FITNESS_LOGS;
    }
  },

  saveFitnessLogs(logs: FitnessLog[]): void {
    localStorage.setItem(KEYS.FITNESS, JSON.stringify(logs));
  },

  // Contacts
  getContacts(): ContactItem[] {
    try {
      const raw = localStorage.getItem(KEYS.CONTACTS);
      if (!raw) {
        localStorage.setItem(KEYS.CONTACTS, JSON.stringify(DEFAULT_CONTACTS));
        return DEFAULT_CONTACTS;
      }
      return JSON.parse(raw);
    } catch {
      return DEFAULT_CONTACTS;
    }
  },

  saveContacts(contacts: ContactItem[]): void {
    localStorage.setItem(KEYS.CONTACTS, JSON.stringify(contacts));
  },

  // Device Status
  getDeviceStatus(): DeviceStatus {
    try {
      const raw = localStorage.getItem(KEYS.DEVICE_STATUS);
      if (!raw) {
        return {
          wifi: true,
          torch: false,
          hotspot: false,
          bluetooth: true,
          volume: 10,
          brightness: 200,
        };
      }
      return JSON.parse(raw);
    } catch {
      return { wifi: true, torch: false, hotspot: false, bluetooth: true, volume: 10, brightness: 200 };
    }
  },

  saveDeviceStatus(status: DeviceStatus): void {
    localStorage.setItem(KEYS.DEVICE_STATUS, JSON.stringify(status));
  },

  // Onboarding
  isOnboardingComplete(): boolean {
    return localStorage.getItem(KEYS.ONBOARDING_DONE) === 'true';
  },

  setOnboardingComplete(complete: boolean): void {
    localStorage.setItem(KEYS.ONBOARDING_DONE, complete ? 'true' : 'false');
  },

  // Preferences
  getChatMode(): 'HOME' | 'OFFICE' {
    return (localStorage.getItem(KEYS.CHAT_MODE) as 'HOME' | 'OFFICE') || 'HOME';
  },

  setChatMode(mode: 'HOME' | 'OFFICE'): void {
    localStorage.setItem(KEYS.CHAT_MODE, mode);
  },

  getVoiceOutput(): boolean {
    const val = localStorage.getItem(KEYS.VOICE_OUTPUT);
    return val === null ? true : val === 'true';
  },

  setVoiceOutput(enabled: boolean): void {
    localStorage.setItem(KEYS.VOICE_OUTPUT, enabled ? 'true' : 'false');
  },

  getSelectedLanguage(): string {
    return localStorage.getItem(KEYS.SELECTED_LANG) || 'en';
  },

  setSelectedLanguage(code: string): void {
    localStorage.setItem(KEYS.SELECTED_LANG, code);
  },

  // Connected Bots Manager (Vaani, Discord, Custom Bots)
  getConnectedBots(): ConnectedBot[] {
    try {
      const raw = localStorage.getItem(KEYS.CONNECTED_BOTS);
      if (!raw) {
        this.saveConnectedBots(DEFAULT_CONNECTED_BOTS);
        return DEFAULT_CONNECTED_BOTS;
      }
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : DEFAULT_CONNECTED_BOTS;
    } catch {
      return DEFAULT_CONNECTED_BOTS;
    }
  },

  saveConnectedBots(bots: ConnectedBot[]): void {
    localStorage.setItem(KEYS.CONNECTED_BOTS, JSON.stringify(bots));
  },

  // Customization Settings (Profile Avatar, Wallpapers, Layout, Fonts, Last Seen, Themes)
  getCustomization(): VyshuCustomization {
    try {
      const raw = localStorage.getItem(KEYS.CUSTOMIZATION);
      if (!raw) return DEFAULT_CUSTOMIZATION;
      return { ...DEFAULT_CUSTOMIZATION, ...JSON.parse(raw) };
    } catch {
      return DEFAULT_CUSTOMIZATION;
    }
  },

  saveCustomization(cust: VyshuCustomization): void {
    localStorage.setItem(KEYS.CUSTOMIZATION, JSON.stringify(cust));
  },

  // Custom Emojis
  getCustomEmojis(): CustomEmoji[] {
    try {
      const raw = localStorage.getItem(KEYS.CUSTOM_EMOJIS);
      if (!raw) {
        this.saveCustomEmojis(DEFAULT_CUSTOM_EMOJIS);
        return DEFAULT_CUSTOM_EMOJIS;
      }
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : DEFAULT_CUSTOM_EMOJIS;
    } catch {
      return DEFAULT_CUSTOM_EMOJIS;
    }
  },

  saveCustomEmojis(emojis: CustomEmoji[]): void {
    localStorage.setItem(KEYS.CUSTOM_EMOJIS, JSON.stringify(emojis));
  },

  // Sticker Packs
  getStickerPacks(): StickerPack[] {
    try {
      const raw = localStorage.getItem(KEYS.STICKER_PACKS);
      if (!raw) {
        this.saveStickerPacks(DEFAULT_STICKER_PACKS);
        return DEFAULT_STICKER_PACKS;
      }
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : DEFAULT_STICKER_PACKS;
    } catch {
      return DEFAULT_STICKER_PACKS;
    }
  },

  saveStickerPacks(packs: StickerPack[]): void {
    localStorage.setItem(KEYS.STICKER_PACKS, JSON.stringify(packs));
  },
};

