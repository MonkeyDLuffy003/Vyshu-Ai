export type MessageRole = 'user' | 'vyshu';
export type MessageType = 'text' | 'image' | 'video' | 'sticker' | 'action';

export interface ChatMessage {
  id: string;
  turnId?: string;
  role: MessageRole;
  text: string;
  timestamp: string;
  type?: MessageType;
  path?: string; // image/video URL or sticker name
  toolAction?: string;
}

export interface ApiVaultKeys {
  gemini_1: string;
  gemini_2: string;
  gemini_3: string;
  gemini_4: string;
  gemini_5: string;
  groq: string;
  discord_token: string;
  discord_id: string;
  discord_bot_url: string;
  gcs_json: string;
  useCloudRetention30Days: boolean;
}

export interface TaskItem {
  id: string;
  title: string;
  completed: boolean;
  dueDate?: string;
  createdAt: string;
}

export interface ContactItem {
  id: string;
  name: string;
  phone: string;
  email?: string;
  avatarColor?: string;
}

export interface FitnessLog {
  id: string;
  date: string; // YYYY-MM-DD
  dayNumber: number;
  workoutType: string;
  durationMinutes: number;
  caloriesBurned: number;
  notes: string;
  completed: boolean;
}

export interface LanguageInfo {
  code: string;
  name: string;
  nativeName: string;
  flag: string;
  timezone: string;
  timezoneCity: string;
  romanizationSample: string;
  sampleGreeting: string;
  voiceLangCode: string;
}

export interface DeviceStatus {
  wifi: boolean;
  torch: boolean;
  hotspot: boolean;
  bluetooth: boolean;
  volume: number; // 0 - 15
  brightness: number; // 0 - 255
}

export interface NewsArticle {
  id: string;
  category: 'Crime' | 'Business' | 'Sports' | 'Entertainment' | 'Tech' | 'World';
  title: string;
  summary: string;
  source: string;
  timeAgo: string;
  url?: string;
}

export interface SongTrack {
  id: string;
  title: string;
  artist: string;
  duration: string;
  audioUrl: string;
  coverArt?: string;
  isCustom?: boolean;
}

export type BotType = 'music_bot' | 'discord_bot' | 'telegram_bot' | 'assistant_bot' | 'custom_apk';

export interface ConnectedBot {
  id: string;
  name: string;
  type: BotType;
  botId: string; // Bot ID or client ID
  secretToken: string; // Token, Auth Key, or Security Key
  endpointUrl?: string; // Webhook / Server URL
  packageName?: string; // Android APK package name (e.g. com.teja.vaani)
  isLocked: boolean; // Security lock: requires PIN or toggle to edit/view credentials
  lockPin?: string;
  isActive: boolean; // Enabled / Disabled state
  voiceTriggerWords: string[]; // e.g. ["vaani", "play music"]
  createdAt: string;
}

export type ChatTheme = 'cyber-cyan' | 'matrix-green' | 'ironman-red' | 'midnight-amethyst' | 'nebula-rose' | 'stealth-black' | 'sunset-gold';

export type FontStyle = 'sans' | 'mono' | 'display' | 'serif' | 'comic';

export type ChatLayoutMode = 'bubble' | 'compact' | 'futuristic' | 'glass';

export type LastSeenOption = 'online' | 'active_now' | 'last_seen_just_now' | 'always_online' | 'stealth' | 'custom';

export type OutfitId =
  | 'signature-red-beret'
  | 'stark-executive'
  | 'holographic-tactical'
  | 'casual-hoodie'
  | 'traditional-festive'
  | 'cyber-operations'
  | 'custom_uploaded';

export interface VyshuOutfit {
  id: OutfitId;
  name: string;
  tagline: string;
  category: 'Signature' | 'Executive' | 'Tactical' | 'Casual' | 'Festive';
  avatarUrl: string;
  badge: string;
  description: string;
  accentColor: string;
}

export interface VyshuCustomization {
  avatarUrl: string; // Custom profile image or preset
  avatarPresetId: string;
  outfitId?: OutfitId; // Active wardrobe outfit
  wallpaperUrl: string; // Custom wallpaper image url / gradient
  wallpaperPresetId: string;
  theme: ChatTheme;
  fontStyle: FontStyle;
  layout: ChatLayoutMode;
  lastSeenMode: LastSeenOption;
  customLastSeenText: string;
  bubbleOpacity: number; // 50 - 100
  fontSize: 'small' | 'medium' | 'large';
  userProfiles?: { id: string; name: string; avatarUrl: string; outfitName: string; createdAt: string }[];
}

export interface CustomEmoji {
  id: string;
  code: string; // e.g. :teja_sparkle: or :vyshu_wink:
  name: string;
  iconData: string; // emoji character or base64 / svg image data
  category: string;
  createdAt: string;
}

export interface StickerPack {
  id: string;
  title: string;
  author: string;
  stickers: { id: string; name: string; emoji: string; label: string; url?: string }[];
  isCustom?: boolean;
}

