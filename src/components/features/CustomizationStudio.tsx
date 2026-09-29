import React, { useState, useRef } from 'react';
import {
  Palette,
  Image as ImageIcon,
  User,
  Sliders,
  Type,
  Layout,
  Clock,
  Sparkles,
  Smile,
  Sticker,
  Plus,
  Trash2,
  Check,
  Eye,
  CheckCircle2,
  Upload,
  RefreshCw,
  Zap,
  Activity,
  Smartphone,
  Shield,
} from 'lucide-react';
import { storageService, DEFAULT_STICKER_PACKS, DEFAULT_CUSTOM_EMOJIS } from '../../services/storageService';
import {
  vyshuActivationService,
  GestureActivationSettings,
} from '../../services/vyshuActivationService';
import {
  VyshuCustomization,
  ChatTheme,
  FontStyle,
  ChatLayoutMode,
  LastSeenOption,
  CustomEmoji,
  StickerPack,
} from '../../types';
import { audioService } from '../../services/audioService';

const AVATAR_PRESETS = [
  { id: 'vyshu-authentic', name: 'Vyshu AI (Her Picture)', url: '/assets/images/vyshu_avatar.png', desc: 'Your custom designed signature red beret & off-shoulder knit' },
  { id: 'vyshu-logo', name: 'Official Vyshu App Logo', url: '/assets/images/vyshu_logo.png', desc: 'Official Android APK launcher icon' },
];

const WALLPAPER_PRESETS = [
  { id: 'deep-cyber', name: 'Deep Cyber Void', value: 'gradient:deep-cyber', css: 'bg-[#05050f]' },
  { id: 'matrix-grid', name: 'Matrix Cyber Grid', value: 'gradient:matrix-grid', css: 'bg-radial-gradient from-emerald-950/40 via-[#030806] to-[#010403]' },
  { id: 'stark-arc', name: 'Stark Arc Reactor Glow', value: 'gradient:stark-arc', css: 'bg-gradient-to-b from-[#09152b] via-[#050b16] to-[#02050b]' },
  { id: 'ironman-crimson', name: 'Crimson Gold Core', value: 'gradient:ironman', css: 'bg-gradient-to-b from-[#1f0b0e] via-[#0f0406] to-[#040102]' },
  { id: 'amethyst-night', name: 'Midnight Amethyst', value: 'gradient:amethyst', css: 'bg-gradient-to-b from-[#180928] via-[#0a0413] to-[#040107]' },
  { id: 'oled-pure', name: 'Pure Stealth Black (OLED)', value: 'gradient:pure-black', css: 'bg-black' },
];

const THEME_OPTIONS: { id: ChatTheme; name: string; primary: string; glow: string }[] = [
  { id: 'cyber-cyan', name: 'Cyber Cyan (Default)', primary: '#00ccff', glow: 'shadow-[0_0_15px_rgba(0,204,255,0.4)]' },
  { id: 'matrix-green', name: 'Matrix Emerald', primary: '#10b981', glow: 'shadow-[0_0_15px_rgba(16,185,129,0.4)]' },
  { id: 'ironman-red', name: 'Iron Man Crimson', primary: '#ef4444', glow: 'shadow-[0_0_15px_rgba(239,68,68,0.4)]' },
  { id: 'midnight-amethyst', name: 'Midnight Amethyst', primary: '#a855f7', glow: 'shadow-[0_0_15px_rgba(168,85,247,0.4)]' },
  { id: 'nebula-rose', name: 'Nebula Cyber Rose', primary: '#ec4899', glow: 'shadow-[0_0_15px_rgba(236,72,153,0.4)]' },
  { id: 'sunset-gold', name: 'Stark Gold', primary: '#f59e0b', glow: 'shadow-[0_0_15px_rgba(245,158,11,0.4)]' },
  { id: 'stealth-black', name: 'Titanium Stealth', primary: '#94a3b8', glow: 'shadow-[0_0_15px_rgba(148,163,184,0.4)]' },
];

const FONT_OPTIONS: { id: FontStyle; name: string; styleName: string; fontClass: string }[] = [
  { id: 'sans', name: 'Inter / Modern Sans', styleName: 'Clean & Futuristic', fontClass: 'font-sans' },
  { id: 'mono', name: 'Cyber Monospace', styleName: 'Tech Code Terminal', fontClass: 'font-mono' },
  { id: 'display', name: 'Iron Man Display', styleName: 'Bold Tactical Grotesk', fontClass: 'font-sans tracking-wide font-medium' },
  { id: 'serif', name: 'Executive Elegant Serif', styleName: 'Refined Royal Butler', fontClass: 'font-serif' },
];

const LAYOUT_OPTIONS: { id: ChatLayoutMode; name: string; desc: string }[] = [
  { id: 'bubble', name: 'Modern Rounded Bubbles', desc: 'Standard comfortable messenger bubbles' },
  { id: 'futuristic', name: 'J.A.R.V.I.S. Tactical HUD', desc: 'Sharp cyber corners with glowing accent borders' },
  { id: 'compact', name: 'Compact Operations View', desc: 'High-density stream, minimal padding for rapid reading' },
  { id: 'glass', name: 'Frosted Glassmorphism', desc: 'Deep blur with translucent liquid glass sheen' },
];

const LAST_SEEN_OPTIONS: { id: LastSeenOption; label: string; preview: string }[] = [
  { id: 'online', label: 'Online (Always Present)', preview: '• Online • 18 Languages' },
  { id: 'active_now', label: 'Active Now (J.A.R.V.I.S. Mode)', preview: '• Active Now • Systems 100%' },
  { id: 'last_seen_just_now', label: 'Last Seen Just Now', preview: 'Last seen just now' },
  { id: 'always_online', label: '24/7 Secretary Standby', preview: '• 24/7 Guarded • Standing by for Teja' },
  { id: 'stealth', label: 'Stealth Ghost (Hidden)', preview: '' },
  { id: 'custom', label: 'Custom Custom Status', preview: 'Custom user text' },
];

export const CustomizationStudio: React.FC = () => {
  const [cust, setCust] = useState<VyshuCustomization>(storageService.getCustomization());
  const [activeTab, setActiveTab] = useState<'profile' | 'theme' | 'layout' | 'emojis' | 'stickers' | 'gestures'>('profile');
  const [gestureSettings, setGestureSettings] = useState<GestureActivationSettings>(vyshuActivationService.getSettings());
  const [emojis, setEmojis] = useState<CustomEmoji[]>(storageService.getCustomEmojis());
  const [stickerPacks, setStickerPacks] = useState<StickerPack[]>(storageService.getStickerPacks());

  // New emoji form
  const [newEmojiChar, setNewEmojiChar] = useState('');
  const [newEmojiCode, setNewEmojiCode] = useState('');
  const [newEmojiName, setNewEmojiName] = useState('');

  // New sticker form
  const [selectedPackId, setSelectedPackId] = useState(stickerPacks[0]?.id || 'pack-vyshu-core');
  const [newStickerEmoji, setNewStickerEmoji] = useState('');
  const [newStickerLabel, setNewStickerLabel] = useState('');

  // Custom photo upload ref
  const avatarFileRef = useRef<HTMLInputElement>(null);
  const wallpaperFileRef = useRef<HTMLInputElement>(null);

  const saveCust = (newCust: VyshuCustomization) => {
    setCust(newCust);
    storageService.saveCustomization(newCust);
    audioService.playSound('toggle');
  };

  const handleAvatarUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const url = event.target?.result as string;
      saveCust({
        ...cust,
        avatarUrl: url,
        avatarPresetId: 'custom_uploaded',
      });
      audioService.playSound('send');
    };
    reader.readAsDataURL(file);
  };

  const handleWallpaperUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const url = event.target?.result as string;
      saveCust({
        ...cust,
        wallpaperUrl: url,
        wallpaperPresetId: 'custom_uploaded_wallpaper',
      });
      audioService.playSound('send');
    };
    reader.readAsDataURL(file);
  };

  const handleAddCustomEmoji = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEmojiChar.trim() || !newEmojiCode.trim()) return;

    const code = newEmojiCode.startsWith(':') && newEmojiCode.endsWith(':')
      ? newEmojiCode
      : `:${newEmojiCode.replace(/:/g, '').trim()}:`;

    const newEmoji: CustomEmoji = {
      id: `emoji-${Date.now()}`,
      code,
      name: newEmojiName.trim() || code,
      iconData: newEmojiChar.trim(),
      category: 'Custom Emojis',
      createdAt: new Date().toISOString(),
    };

    const updated = [newEmoji, ...emojis];
    setEmojis(updated);
    storageService.saveCustomEmojis(updated);

    setNewEmojiChar('');
    setNewEmojiCode('');
    setNewEmojiName('');
    audioService.playSound('send');
  };

  const handleDeleteEmoji = (id: string) => {
    const updated = emojis.filter((e) => e.id !== id);
    setEmojis(updated);
    storageService.saveCustomEmojis(updated);
  };

  const handleAddStickerToPack = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStickerEmoji.trim() || !newStickerLabel.trim()) return;

    const updatedPacks = stickerPacks.map((pack) => {
      if (pack.id === selectedPackId) {
        return {
          ...pack,
          stickers: [
            ...pack.stickers,
            {
              id: `stk-${Date.now()}`,
              name: newStickerLabel.toLowerCase().replace(/\s+/g, '_'),
              emoji: newStickerEmoji.trim(),
              label: newStickerLabel.trim(),
            },
          ],
        };
      }
      return pack;
    });

    setStickerPacks(updatedPacks);
    storageService.saveStickerPacks(updatedPacks);
    setNewStickerEmoji('');
    setNewStickerLabel('');
    audioService.playSound('send');
  };

  const handleCreateNewPack = () => {
    const title = prompt('Enter New Sticker Pack Name:');
    if (!title) return;

    const newPack: StickerPack = {
      id: `pack-${Date.now()}`,
      title,
      author: 'Teja Swaroop',
      isCustom: true,
      stickers: [
        { id: `stk-${Date.now()}-1`, name: 'spark', emoji: '✨', label: 'Sparkle' },
      ],
    };

    const updated = [...stickerPacks, newPack];
    setStickerPacks(updated);
    setSelectedPackId(newPack.id);
    storageService.saveStickerPacks(updated);
  };

  return (
    <div className="space-y-4 text-xs">
      {/* Hidden file pickers */}
      <input type="file" ref={avatarFileRef} accept="image/*" onChange={handleAvatarUpload} className="hidden" />
      <input type="file" ref={wallpaperFileRef} accept="image/*" onChange={handleWallpaperUpload} className="hidden" />

      {/* Header */}
      <div className="flex items-center justify-between pb-1 border-b border-slate-800/80">
        <div className="flex items-center space-x-2.5">
          <div className="w-8 h-8 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400 glow-cyan">
            <Palette className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-white tracking-wide uppercase">
              Vyshu Studio &amp; Customization
            </h2>
            <p className="text-[11px] text-slate-400">
              Profiles, Wallpapers, Chat Themes, Fonts, Last Seen, Custom Emojis &amp; Sticker Packs
            </p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center space-x-1.5 overflow-x-auto no-scrollbar bg-[#0b0b16] p-1.5 rounded-2xl border border-slate-800">
        {[
          { id: 'profile', label: 'Profile & Avatar', icon: User },
          { id: 'theme', label: 'Themes & Wallpaper', icon: Palette },
          { id: 'layout', label: 'Layout & Fonts', icon: Layout },
          { id: 'gestures', label: '24/7 & Gestures', icon: Zap },
          { id: 'emojis', label: 'Emoji Creator', icon: Smile },
          { id: 'stickers', label: 'Sticker Packs', icon: Sticker },
        ].map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => {
                setActiveTab(tab.id as any);
                audioService.playSound('click');
              }}
              className={`px-3 py-1.5 rounded-xl font-semibold flex items-center gap-1.5 whitespace-nowrap transition ${
                isActive
                  ? 'bg-cyan-400 text-slate-950 font-bold shadow-md shadow-cyan-500/20'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* ============================================================== */}
      {/* TAB 1: PROFILE, AVATAR & LAST SEEN */}
      {/* ============================================================== */}
      {activeTab === 'profile' && (
        <div className="space-y-4 animate-fade-in">
          {/* Avatar Preview & Upload */}
          <div className="p-4 bg-[#0b0b16] border border-cyan-500/20 rounded-2xl flex items-center justify-between gap-4">
            <div className="flex items-center space-x-3.5">
              <div className="relative">
                <img
                  src={cust.avatarUrl}
                  alt="Vyshu Avatar"
                  className="w-16 h-16 rounded-2xl object-cover border-2 border-cyan-400 shadow-lg glow-cyan"
                />
                <span className="absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full bg-emerald-400 border-2 border-[#05050f]" />
              </div>
              <div>
                <div className="text-sm font-bold text-white flex items-center gap-2">
                  <span>Vyshu AI</span>
                  <span className="text-[10px] bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 px-2 py-0.5 rounded-full font-mono">
                    Active Profile
                  </span>
                </div>
                <div className="text-[11px] text-slate-400 mt-0.5">
                  {cust.lastSeenMode === 'custom'
                    ? cust.customLastSeenText
                    : LAST_SEEN_OPTIONS.find((o) => o.id === cust.lastSeenMode)?.preview || 'Online'}
                </div>
              </div>
            </div>

            <button
              onClick={() => avatarFileRef.current?.click()}
              className="px-3 py-2 rounded-xl bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 transition flex items-center gap-1.5 active:scale-95 shrink-0"
            >
              <Upload className="w-3.5 h-3.5" /> Upload Photo
            </button>
          </div>

          {/* Preset Profile Avatars */}
          <div className="space-y-2">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center justify-between">
              <span>Authentic Vyshu AI Identity (Designed by Teja)</span>
              <span className="text-[10px] text-cyan-400 font-mono">100% Unique Design</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {AVATAR_PRESETS.map((preset) => {
                const isSelected = cust.avatarUrl === preset.url;
                return (
                  <div
                    key={preset.id}
                    onClick={() => saveCust({ ...cust, avatarUrl: preset.url, avatarPresetId: preset.id })}
                    className={`p-3 rounded-2xl border flex items-center space-x-3 cursor-pointer transition ${
                      isSelected
                        ? 'bg-cyan-500/10 border-cyan-400 text-cyan-300 ring-2 ring-cyan-500/30'
                        : 'bg-[#0b0b16] border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    <img
                      src={preset.url}
                      alt={preset.name}
                      className="w-14 h-14 rounded-2xl object-cover shrink-0 border border-slate-700 shadow-md"
                    />
                    <div className="overflow-hidden">
                      <div className="text-xs font-bold text-white flex items-center gap-1.5">
                        <span className="truncate">{preset.name}</span>
                        {isSelected && <Check className="w-3.5 h-3.5 text-cyan-400 shrink-0" />}
                      </div>
                      <div className="text-[10px] text-slate-400 mt-0.5 line-clamp-2">
                        {preset.desc}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Last Seen / Status Changing */}
          <div className="space-y-2 pt-2 border-t border-slate-800">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5 text-cyan-400" /> Last Seen &amp; Presence Status
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {LAST_SEEN_OPTIONS.map((opt) => {
                const isSelected = cust.lastSeenMode === opt.id;
                return (
                  <div
                    key={opt.id}
                    onClick={() => saveCust({ ...cust, lastSeenMode: opt.id })}
                    className={`p-2.5 rounded-xl border flex items-center justify-between cursor-pointer transition ${
                      isSelected
                        ? 'bg-cyan-500/10 border-cyan-400 text-cyan-300'
                        : 'bg-[#0b0b16] border-slate-800 hover:border-slate-700 text-slate-300'
                    }`}
                  >
                    <div>
                      <div className="font-semibold text-white">{opt.label}</div>
                      <div className="text-[10px] text-slate-400 font-mono">{opt.preview || '(Hidden status)'}</div>
                    </div>
                    {isSelected && <CheckCircle2 className="w-4 h-4 text-cyan-400 shrink-0" />}
                  </div>
                );
              })}
            </div>

            {/* Custom status input */}
            {cust.lastSeenMode === 'custom' && (
              <div className="pt-2 animate-fade-in">
                <label className="text-slate-400 block mb-1">Custom Status Text</label>
                <input
                  type="text"
                  value={cust.customLastSeenText}
                  onChange={(e) => saveCust({ ...cust, customLastSeenText: e.target.value })}
                  placeholder="e.g. In lab with Tony • Standing by"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-medium focus:outline-none focus:border-cyan-400"
                />
              </div>
            )}
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 2: CHAT THEMES & WALLPAPERS */}
      {/* ============================================================== */}
      {activeTab === 'theme' && (
        <div className="space-y-4 animate-fade-in">
          {/* Theme Palette */}
          <div className="space-y-2">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Palette className="w-3.5 h-3.5 text-cyan-400" /> Chat Accent Theme
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
              {THEME_OPTIONS.map((theme) => {
                const isSelected = cust.theme === theme.id;
                return (
                  <div
                    key={theme.id}
                    onClick={() => saveCust({ ...cust, theme: theme.id })}
                    className={`p-3 rounded-xl border flex items-center space-x-2.5 cursor-pointer transition ${
                      isSelected
                        ? 'border-white bg-[#0e1422] shadow-sm'
                        : 'border-slate-800 bg-[#0b0b16] hover:border-slate-700'
                    }`}
                  >
                    <span
                      className="w-4 h-4 rounded-full shrink-0 shadow-md"
                      style={{ backgroundColor: theme.primary }}
                    />
                    <span className="text-[11px] font-semibold text-white truncate">{theme.name}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Wallpapers */}
          <div className="space-y-2 pt-2 border-t border-slate-800">
            <div className="flex items-center justify-between">
              <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
                <ImageIcon className="w-3.5 h-3.5 text-cyan-400" /> Chat Background Wallpaper
              </div>
              <button
                onClick={() => wallpaperFileRef.current?.click()}
                className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-[11px] font-semibold flex items-center gap-1"
              >
                <Upload className="w-3 h-3" /> Custom Image
              </button>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
              {WALLPAPER_PRESETS.map((wp) => {
                const isSelected = cust.wallpaperUrl === wp.value;
                return (
                  <div
                    key={wp.id}
                    onClick={() => saveCust({ ...cust, wallpaperUrl: wp.value, wallpaperPresetId: wp.id })}
                    className={`p-3 h-20 rounded-xl border cursor-pointer relative overflow-hidden flex flex-col justify-end transition ${
                      isSelected ? 'border-cyan-400 ring-2 ring-cyan-400/40' : 'border-slate-800 hover:border-slate-700'
                    } ${wp.css}`}
                  >
                    <span className="text-[10px] font-bold text-white z-10 drop-shadow-md">{wp.name}</span>
                    {isSelected && (
                      <span className="absolute top-2 right-2 w-4 h-4 rounded-full bg-cyan-400 text-slate-950 flex items-center justify-center font-bold text-[10px]">
                        ✓
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Bubble Opacity Slider */}
          <div className="p-4 bg-[#0b0b16] border border-slate-800 rounded-2xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-slate-300 font-semibold">Message Bubble Opacity</span>
              <span className="font-mono text-cyan-400">{cust.bubbleOpacity}%</span>
            </div>
            <input
              type="range"
              min={40}
              max={100}
              value={cust.bubbleOpacity}
              onChange={(e) => saveCust({ ...cust, bubbleOpacity: Number(e.target.value) })}
              className="w-full accent-cyan-400"
            />
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 3: LAYOUT & FONT STYLES */}
      {/* ============================================================== */}
      {activeTab === 'layout' && (
        <div className="space-y-4 animate-fade-in">
          {/* Chat Layout Style */}
          <div className="space-y-2">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Layout className="w-3.5 h-3.5 text-cyan-400" /> Chat Bubble Layout Mode
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {LAYOUT_OPTIONS.map((layout) => {
                const isSelected = cust.layout === layout.id;
                return (
                  <div
                    key={layout.id}
                    onClick={() => saveCust({ ...cust, layout: layout.id })}
                    className={`p-3 rounded-xl border cursor-pointer transition ${
                      isSelected
                        ? 'bg-cyan-500/10 border-cyan-400 text-cyan-300'
                        : 'bg-[#0b0b16] border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    <div className="font-bold text-white">{layout.name}</div>
                    <div className="text-[11px] text-slate-400 mt-0.5">{layout.desc}</div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Typography Font Styles */}
          <div className="space-y-2 pt-2 border-t border-slate-800">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Type className="w-3.5 h-3.5 text-cyan-400" /> Typography &amp; Font Family
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {FONT_OPTIONS.map((font) => {
                const isSelected = cust.fontStyle === font.id;
                return (
                  <div
                    key={font.id}
                    onClick={() => saveCust({ ...cust, fontStyle: font.id })}
                    className={`p-3 rounded-xl border cursor-pointer transition ${
                      isSelected
                        ? 'bg-cyan-500/10 border-cyan-400 text-cyan-300'
                        : 'bg-[#0b0b16] border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    <div className={`text-sm font-bold text-white ${font.fontClass}`}>
                      {font.name}
                    </div>
                    <div className="text-[11px] text-slate-400">{font.styleName}</div>
                    <div className={`mt-1.5 text-slate-300 text-xs ${font.fontClass}`}>
                      &ldquo;At your service, Teja. All systems calibrated.&rdquo;
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Font Size */}
          <div className="space-y-2 pt-2 border-t border-slate-800">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              Chat Font Size
            </div>
            <div className="grid grid-cols-3 gap-2">
              {(['small', 'medium', 'large'] as const).map((sz) => (
                <button
                  key={sz}
                  onClick={() => saveCust({ ...cust, fontSize: sz })}
                  className={`py-2 rounded-xl border capitalize font-semibold transition ${
                    cust.fontSize === sz
                      ? 'bg-cyan-400 text-slate-950 font-bold border-cyan-400'
                      : 'bg-[#0b0b16] border-slate-800 text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  {sz}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB: 24/7 BACKGROUND & GESTURE ACTIVATION (Android HUD & 3-Finger) */}
      {/* ============================================================== */}
      {activeTab === 'gestures' && (
        <div className="space-y-4 animate-fade-in">
          <div className="p-4 bg-[#0b0b16] border border-cyan-500/30 rounded-2xl space-y-3 glow-cyan">
            <div className="flex items-center space-x-2 text-white font-bold text-sm">
              <Smartphone className="w-5 h-5 text-cyan-400" />
              <span>3-Finger Swipe Down Activation</span>
            </div>
            <p className="text-slate-300 text-xs leading-relaxed">
              Just like Android screenshot gestures (dragging 3 fingers downwards), dragging 3 fingers down anywhere on the screen immediately wakes up Vyshu and begins continuous voice recognition with zero clicks.
            </p>

            <div className="flex items-center justify-between p-3 bg-[#05050f] rounded-xl border border-slate-800">
              <span className="text-white font-semibold">Enable 3-Finger Swipe Gesture</span>
              <input
                type="checkbox"
                checked={gestureSettings.threeFingerSwipeEnabled}
                onChange={(e) => {
                  const updated = { ...gestureSettings, threeFingerSwipeEnabled: e.target.checked };
                  setGestureSettings(updated);
                  vyshuActivationService.saveSettings(updated);
                  audioService.playSound('toggle');
                }}
                className="w-5 h-5 accent-cyan-400 cursor-pointer"
              />
            </div>
          </div>

          {/* 24/7 Android Background Service Architecture */}
          <div className="p-4 bg-[#0b0b16] border border-slate-800 rounded-2xl space-y-3">
            <div className="flex items-center space-x-2 text-white font-bold text-sm">
              <Activity className="w-5 h-5 text-emerald-400" />
              <span>24/7 Background Service (Run Without Opening App)</span>
            </div>
            <p className="text-slate-300 text-xs leading-relaxed">
              For Vyshu to wake up and execute your commands even when the app is completely closed:
            </p>

            <div className="space-y-2 text-xs text-slate-300 font-mono bg-[#05050f] p-3 rounded-xl border border-slate-800">
              <div className="flex items-start gap-2">
                <span className="text-cyan-400 font-bold">1.</span>
                <span><strong>Android Foreground Service:</strong> Keeps a persistent silent status bar notification so Android OS never kills Vyshu in the background.</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-cyan-400 font-bold">2.</span>
                <span><strong>Accessibility Service (Gesture Trigger):</strong> Intercepts 3-finger swipe down or double tap from ANY screen (Home screen, WhatsApp, YouTube) to pop open Vyshu&apos;s Voice HUD.</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="text-cyan-400 font-bold">3.</span>
                <span><strong>Floating HUD Overlay:</strong> Shows a compact floating circular bubble over other apps so you can speak to Vyshu without leaving what you are doing.</span>
              </div>
            </div>

            <div className="flex items-center justify-between p-3 bg-[#05050f] rounded-xl border border-slate-800">
              <span className="text-white font-semibold">Floating HUD Bubble Overlay</span>
              <input
                type="checkbox"
                checked={gestureSettings.floatingOverlayBubbleEnabled}
                onChange={(e) => {
                  const updated = { ...gestureSettings, floatingOverlayBubbleEnabled: e.target.checked };
                  setGestureSettings(updated);
                  vyshuActivationService.saveSettings(updated);
                  audioService.playSound('toggle');
                }}
                className="w-5 h-5 accent-cyan-400 cursor-pointer"
              />
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 4: EMOJI CREATOR STUDIO */}
      {/* ============================================================== */}
      {activeTab === 'emojis' && (
        <div className="space-y-4 animate-fade-in">
          {/* Creator Form */}
          <form onSubmit={handleAddCustomEmoji} className="p-4 bg-[#0b0b16] border border-cyan-500/30 rounded-2xl space-y-3 glow-cyan">
            <div className="font-bold text-white flex items-center gap-1.5">
              <Smile className="w-4 h-4 text-cyan-400" /> Create Custom Emoji for Vyshu
            </div>
            <p className="text-slate-300 text-[11px]">
              Design and register custom emoji symbols that can be inserted into chat with shorthand codes (e.g. <code>:teja_crown:</code>).
            </p>

            <div className="grid grid-cols-3 gap-2">
              <div>
                <label className="text-slate-400 block mb-1">Emoji / Symbol *</label>
                <input
                  type="text"
                  required
                  maxLength={4}
                  value={newEmojiChar}
                  onChange={(e) => setNewEmojiChar(e.target.value)}
                  placeholder="⚡"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-center text-lg text-white focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div className="col-span-2">
                <label className="text-slate-400 block mb-1">Emoji Code (Shortcode) *</label>
                <input
                  type="text"
                  required
                  value={newEmojiCode}
                  onChange={(e) => setNewEmojiCode(e.target.value)}
                  placeholder=":teja_bolt:"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
                />
              </div>
            </div>

            <div>
              <label className="text-slate-400 block mb-1">Emoji Name (Optional)</label>
              <input
                type="text"
                value={newEmojiName}
                onChange={(e) => setNewEmojiName(e.target.value)}
                placeholder="Lightning Arc Reactor"
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:outline-none focus:border-cyan-400"
              />
            </div>

            <button
              type="submit"
              className="w-full py-2.5 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 font-bold transition flex items-center justify-center gap-1.5 active:scale-95"
            >
              <Plus className="w-4 h-4" /> Save Custom Emoji
            </button>
          </form>

          {/* Emojis Grid */}
          <div className="space-y-2">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center justify-between">
              <span>Saved Custom Emojis ({emojis.length})</span>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {emojis.map((emoji) => (
                <div
                  key={emoji.id}
                  className="p-2.5 bg-[#0b0b16] border border-slate-800 rounded-xl flex items-center justify-between gap-2"
                >
                  <div className="flex items-center space-x-2">
                    <span className="text-xl">{emoji.iconData}</span>
                    <div className="overflow-hidden">
                      <div className="font-bold text-white truncate text-[11px]">{emoji.name}</div>
                      <div className="font-mono text-[10px] text-cyan-400 truncate">{emoji.code}</div>
                    </div>
                  </div>
                  <button
                    onClick={() => handleDeleteEmoji(emoji.id)}
                    className="p-1 text-slate-500 hover:text-rose-400 transition"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* TAB 5: STICKER PACKS */}
      {/* ============================================================== */}
      {activeTab === 'stickers' && (
        <div className="space-y-4 animate-fade-in">
          {/* Pack Selector Header */}
          <div className="flex items-center justify-between">
            <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <Sticker className="w-3.5 h-3.5 text-cyan-400" /> Sticker Packs Library
            </div>
            <button
              onClick={handleCreateNewPack}
              className="px-2.5 py-1 rounded-lg bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 text-[11px] flex items-center gap-1"
            >
              <Plus className="w-3 h-3" /> New Pack
            </button>
          </div>

          {/* Pack Tabs */}
          <div className="flex items-center space-x-2 overflow-x-auto no-scrollbar">
            {stickerPacks.map((pack) => (
              <button
                key={pack.id}
                onClick={() => setSelectedPackId(pack.id)}
                className={`px-3 py-1.5 rounded-xl border text-[11px] font-semibold transition shrink-0 ${
                  selectedPackId === pack.id
                    ? 'bg-cyan-500/20 border-cyan-400 text-cyan-300 font-bold'
                    : 'bg-[#0b0b16] border-slate-800 text-slate-400 hover:text-white'
                }`}
              >
                {pack.title} ({pack.stickers.length})
              </button>
            ))}
          </div>

          {/* Active Pack Stickers Display */}
          {(() => {
            const activePack = stickerPacks.find((p) => p.id === selectedPackId) || stickerPacks[0];
            if (!activePack) return null;

            return (
              <div className="space-y-3">
                <div className="p-3 bg-[#0b0b16] border border-slate-800 rounded-2xl">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-bold text-white text-xs">{activePack.title}</span>
                    <span className="text-[10px] text-slate-400 font-mono">By {activePack.author}</span>
                  </div>

                  <div className="grid grid-cols-4 sm:grid-cols-6 gap-2">
                    {activePack.stickers.map((stk) => (
                      <div
                        key={stk.id}
                        className="p-2.5 bg-[#05050f] border border-slate-800/80 rounded-xl flex flex-col items-center justify-center gap-1 hover:border-cyan-400 transition cursor-pointer"
                        title={stk.label}
                      >
                        <span className="text-2xl">{stk.emoji}</span>
                        <span className="text-[9px] text-slate-400 truncate w-full text-center">{stk.label}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Add Sticker to this pack */}
                <form onSubmit={handleAddStickerToPack} className="p-3 bg-[#080814] border border-slate-800 rounded-2xl flex items-center gap-2">
                  <input
                    type="text"
                    required
                    maxLength={4}
                    value={newStickerEmoji}
                    onChange={(e) => setNewStickerEmoji(e.target.value)}
                    placeholder="🚀"
                    className="w-12 bg-[#05050f] border border-slate-800 rounded-xl p-2 text-center text-lg focus:outline-none focus:border-cyan-400"
                  />
                  <input
                    type="text"
                    required
                    value={newStickerLabel}
                    onChange={(e) => setNewStickerLabel(e.target.value)}
                    placeholder="Sticker label (e.g. Overdrive)"
                    className="flex-1 bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 text-xs focus:outline-none focus:border-cyan-400"
                  />
                  <button
                    type="submit"
                    className="px-3 py-2 rounded-xl bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 transition text-xs shrink-0 flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" /> Add
                  </button>
                </form>
              </div>
            );
          })()}
        </div>
      )}
    </div>
  );
};
