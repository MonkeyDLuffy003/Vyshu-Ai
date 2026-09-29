import React, { useState, useEffect, useRef } from 'react';
import {
  Mic,
  MicOff,
  Send,
  Plus,
  Volume2,
  VolumeX,
  Home,
  Briefcase,
  Copy,
  Share2,
  Edit2,
  Trash2,
  CheckCircle2,
  X,
  Image as ImageIcon,
  Smile,
  ExternalLink,
  Search,
  Sparkles,
  Phone,
  Flame,
  Check,
  MoreVertical,
  Activity,
  Music,
  Radio,
  Palette,
  Sticker,
} from 'lucide-react';
import { brainService } from '../services/brainService';
import { storageService } from '../services/storageService';
import { audioService } from '../services/audioService';
import { vaaniBotService } from '../services/vaaniBotService';
import { vyshuActivationService } from '../services/vyshuActivationService';
import { ChatMessage, VyshuCustomization, CustomEmoji, StickerPack } from '../types';

interface ChatScreenProps {
  onOpenFeatures: (tab?: any) => void;
  externalPrompt?: string;
  onClearExternalPrompt?: () => void;
}

const STICKERS: Record<string, { label: string; emoji: string }> = {
  happy: { label: 'Happy Vyshu', emoji: '😊' },
  thumbsup: { label: 'Thumbs Up', emoji: '👍' },
  hi: { label: 'Hi Teja', emoji: '👋' },
  excited: { label: 'Excited', emoji: '✨' },
  celebrate: { label: 'Celebrate', emoji: '🎉' },
  calm: { label: 'Calm', emoji: '😌' },
  coffee: { label: 'Coffee Break', emoji: '☕' },
  fullbody: { label: 'Vyshu Secretary', emoji: '👩‍💼' },
  slipper1: { label: 'Slipper Raise', emoji: '🩴' },
  slipper2: { label: 'Slipper Throw', emoji: '🩴💥' },
  gun1: { label: 'Gun Aim', emoji: '🔫' },
  gun2: { label: 'Double Guns', emoji: '🔫🔫' },
};

export const ChatScreen: React.FC<ChatScreenProps> = ({
  onOpenFeatures,
  externalPrompt,
  onClearExternalPrompt,
}) => {
  const [messages, setMessages] = useState<ChatMessage[]>(() => {
    const history = storageService.getChatHistory();
    if (history.length > 0) return history;

    // Default greeting matching J.A.R.V.I.S. style elegance
    const hour = new Date().getHours();
    const timeGreeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return [
      {
        id: 'initial',
        role: 'vyshu',
        text: `${timeGreeting}, Teja. All systems are operational, bot links calibrated, and I am standing by for your command.`,
        timestamp: new Date().toISOString(),
      },
    ];
  });

  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [mode, setMode] = useState<'HOME' | 'OFFICE'>(storageService.getChatMode());
  const [voiceOutput, setVoiceOutput] = useState(storageService.getVoiceOutput());
  const [isListening, setIsListening] = useState(false);
  const [isHandsFree247, setIsHandsFree247] = useState(false);

  // Selection mode
  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  // Attachments modal
  const [showAttachmentMenu, setShowAttachmentMenu] = useState(false);
  const [showStickerPicker, setShowStickerPicker] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [activeStickerTab, setActiveStickerTab] = useState<string>('all');

  // Customization Settings
  const [cust, setCust] = useState<VyshuCustomization>(storageService.getCustomization());
  const [customEmojis, setCustomEmojis] = useState<CustomEmoji[]>(storageService.getCustomEmojis());
  const [stickerPacks, setStickerPacks] = useState<StickerPack[]>(storageService.getStickerPacks());

  // Editing message modal
  const [editingMsg, setEditingMsg] = useState<{ id: string; text: string } | null>(null);

  // Active message action popup
  const [activeActionMenuId, setActiveActionMenuId] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Save history on changes
  useEffect(() => {
    const vault = storageService.getVaultKeys();
    storageService.saveChatHistory(messages, vault.useCloudRetention30Days);
    scrollToBottom();
  }, [messages]);

  // Handle external prompts
  useEffect(() => {
    if (externalPrompt) {
      handleSendMessage(externalPrompt);
      if (onClearExternalPrompt) onClearExternalPrompt();
    }
  }, [externalPrompt]);

  // Hook 3-Finger Swipe Down Gesture & Background Activations
  useEffect(() => {
    const unsub = vyshuActivationService.onActivate((trigger) => {
      audioService.playSound('click');
      audioService.speak('At your service, Teja. Listening.', 'en-IN');
      handleToggleMic();
    });
    return () => unsub();
  }, [isListening]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const toggleMode = () => {
    const newMode = mode === 'HOME' ? 'OFFICE' : 'HOME';
    setMode(newMode);
    storageService.setChatMode(newMode);
    audioService.playSound('toggle');

    if (voiceOutput) {
      if (newMode === 'HOME') {
        audioService.speak('Hi Teja! Home mode activated.', 'en-IN');
      } else {
        audioService.speak('Hi, Teja sir. Office mode engaged.', 'en-IN');
      }
    }
  };

  const toggleVoiceOutput = () => {
    const newVal = !voiceOutput;
    setVoiceOutput(newVal);
    storageService.setVoiceOutput(newVal);
    if (!newVal) audioService.stopSpeaking();
    audioService.playSound('toggle');
  };

  // Tool tags parser & action handler
  const handleToolTagAction = (toolText: string) => {
    if (toolText.includes('[TOOL: OPEN_YOUTUBE]')) {
      window.open('https://www.youtube.com', '_blank');
    } else if (toolText.includes('[TOOL: OPEN_SPOTIFY]')) {
      window.open('https://open.spotify.com', '_blank');
    } else if (toolText.includes('[TOOL: OPEN_WHATSAPP]')) {
      window.open('https://web.whatsapp.com', '_blank');
    } else if (toolText.includes('[TOOL: OPEN_DISCORD]')) {
      window.open('https://discord.com/app', '_blank');
    } else if (toolText.includes('[TOOL: TORCH_ON]')) {
      const dev = storageService.getDeviceStatus();
      storageService.saveDeviceStatus({ ...dev, torch: true });
    } else if (toolText.includes('[TOOL: TORCH_OFF]')) {
      const dev = storageService.getDeviceStatus();
      storageService.saveDeviceStatus({ ...dev, torch: false });
    } else if (toolText.includes('[TOOL: TOGGLE_WIFI]')) {
      const dev = storageService.getDeviceStatus();
      storageService.saveDeviceStatus({ ...dev, wifi: !dev.wifi });
    } else if (toolText.includes('[TOOL: SEARCH:')) {
      const match = toolText.match(/\[TOOL: SEARCH:(.+?)\]/);
      if (match && match[1]) {
        window.open(`https://www.google.com/search?q=${encodeURIComponent(match[1])}`, '_blank');
      }
    } else if (toolText.includes('[TOOL: SAVE_TASK:')) {
      const match = toolText.match(/\[TOOL: SAVE_TASK:(.+?)\]/);
      if (match && match[1]) {
        const tasks = storageService.getTasks();
        tasks.unshift({
          id: Date.now().toString(),
          title: match[1],
          completed: false,
          createdAt: new Date().toISOString(),
        });
        storageService.saveTasks(tasks);
      }
    } else if (toolText.includes('[TOOL: GET_TASKS]')) {
      onOpenFeatures('tasks');
    } else if (toolText.includes('[TOOL: CALL_CONTACT:')) {
      const match = toolText.match(/\[TOOL: CALL_CONTACT:(.+?)\]/);
      if (match && match[1]) {
        window.location.href = `tel:${encodeURIComponent(match[1])}`;
      }
    } else if (toolText.includes('[TOOL: VAANI_PLAY:')) {
      const match = toolText.match(/\[TOOL: VAANI_PLAY:(.+?)\]/);
      const query = match ? match[1] : '';
      vaaniBotService.searchAndPlay(query);
      onOpenFeatures('music');
    } else if (toolText.includes('[TOOL: VAANI_PAUSE]')) {
      vaaniBotService.pause();
    } else if (toolText.includes('[TOOL: VAANI_NEXT]')) {
      vaaniBotService.next();
      onOpenFeatures('music');
    } else if (toolText.includes('[TOOL: VAANI_PREV]')) {
      vaaniBotService.previous();
      onOpenFeatures('music');
    } else if (toolText.includes('[TOOL: VAANI_OPEN_APK]')) {
      vaaniBotService.openVaaniApk();
      onOpenFeatures('music');
    } else if (toolText.includes('[TOOL: SEARCH_YOUTUBE:')) {
      const match = toolText.match(/\[TOOL: SEARCH_YOUTUBE:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('youtube', match ? match[1] : undefined);
    } else if (toolText.includes('[TOOL: SEARCH_SPOTIFY:')) {
      const match = toolText.match(/\[TOOL: SEARCH_SPOTIFY:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('spotify', match ? match[1] : undefined);
    } else if (toolText.includes('[TOOL: OPEN_INSTAGRAM:')) {
      const match = toolText.match(/\[TOOL: OPEN_INSTAGRAM:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('instagram', match ? match[1] : undefined);
    } else if (toolText.includes('[TOOL: OPEN_TELEGRAM:')) {
      const match = toolText.match(/\[TOOL: OPEN_TELEGRAM:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('telegram', match ? match[1] : undefined);
    } else if (toolText.includes('[TOOL: OPEN_MESSENGER:')) {
      const match = toolText.match(/\[TOOL: OPEN_MESSENGER:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('messenger', undefined, match ? match[1] : undefined);
    } else if (toolText.includes('[TOOL: OPEN_FACEBOOK]')) {
      vyshuActivationService.launchAppWithIntent('facebook');
    } else if (toolText.includes('[TOOL: SEND_SMS:')) {
      const match = toolText.match(/\[TOOL: SEND_SMS:(.+?)\]/);
      vyshuActivationService.launchAppWithIntent('sms', undefined, match ? match[1] : undefined);
    }
  };

  const handleSendMessage = async (textToSend?: string) => {
    const text = (textToSend || input).trim();
    if (!text) return;

    if (!textToSend) setInput('');
    audioService.playSound('send');

    const turnId = Date.now().toString();
    const userMsg: ChatMessage = {
      id: `u-${turnId}`,
      turnId,
      role: 'user',
      text,
      timestamp: new Date().toISOString(),
      type: 'text',
    };

    setMessages((prev) => [...prev, userMsg]);
    setIsTyping(true);

    try {
      const res = await brainService.respond(text, mode);
      setIsTyping(false);

      const vyshuMsg: ChatMessage = {
        id: `v-${res.id || turnId}`,
        turnId: res.id || turnId,
        role: 'vyshu',
        text: res.text,
        timestamp: new Date().toISOString(),
        type: res.sticker ? 'sticker' : 'text',
        path: res.sticker,
        toolAction: res.text.includes('[TOOL:') ? res.text : undefined,
      };

      setMessages((prev) => [...prev, vyshuMsg]);

      // Speak reply if voice output is enabled
      if (voiceOutput) {
        audioService.speak(res.text, 'en-IN');
      }

      // Execute tool action
      handleToolTagAction(res.text);
    } catch {
      setIsTyping(false);
    }
  };

  // Push-to-talk voice recording
  const handleToggleMic = () => {
    if (isListening) {
      audioService.stopListening();
      setIsListening(false);
      return;
    }

    setIsListening(true);
    audioService.startListening(
      (recognized, isFinal) => {
        setInput(recognized);
        if (isFinal && recognized.trim()) {
          setIsListening(false);
          handleSendMessage(recognized);
        }
      },
      (err) => {
        setIsListening(false);
      },
      (listening) => {
        setIsListening(listening);
      }
    );
  };

  // 24/7 Hands-Free Continuous Voice Mode
  const toggleHandsFree = () => {
    const newState = !isHandsFree247;
    setIsHandsFree247(newState);
    if (newState) {
      audioService.speak("Hands-free voice mode active, Teja. I'm listening.", 'en-IN');
      setIsListening(true);
      audioService.startListening(
        (recognized, isFinal) => {
          if (isFinal && recognized.trim()) {
            handleSendMessage(recognized);
          }
        },
        () => {},
        (listening) => setIsListening(listening)
      );
    } else {
      audioService.stopListening();
      setIsListening(false);
      audioService.speak('Hands-free mode paused.', 'en-IN');
    }
  };

  // Send photo attachment
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string;
      const turnId = Date.now().toString();
      const mediaMsg: ChatMessage = {
        id: `u-${turnId}`,
        turnId,
        role: 'user',
        text: 'Photo Attachment',
        timestamp: new Date().toISOString(),
        type: 'image',
        path: dataUrl,
      };

      setMessages((prev) => [...prev, mediaMsg]);
      setShowAttachmentMenu(false);
      audioService.playSound('send');

      // AI acknowledges photo
      setTimeout(() => {
        const replyMsg: ChatMessage = {
          id: `v-${turnId}`,
          turnId,
          role: 'vyshu',
          text: `Got your photo, ${mode === 'HOME' ? 'Teja' : 'Teja sir'}! I have added it to your daily logs.`,
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, replyMsg]);
        if (voiceOutput) audioService.speak(replyMsg.text, 'en-IN');
      }, 700);
    };
    reader.readAsDataURL(file);
  };

  // Send sticker
  const handleSendSticker = (stickerKey: string) => {
    const turnId = Date.now().toString();
    const stickerMsg: ChatMessage = {
      id: `u-${turnId}`,
      turnId,
      role: 'user',
      text: STICKERS[stickerKey]?.label || stickerKey,
      timestamp: new Date().toISOString(),
      type: 'sticker',
      path: stickerKey,
    };

    setMessages((prev) => [...prev, stickerMsg]);
    setShowStickerPicker(false);
    setShowAttachmentMenu(false);
    audioService.playSound('send');
  };

  // Message Actions: Copy, Share, Edit, Delete
  const handleCopyMessage = (text: string) => {
    navigator.clipboard.writeText(text);
    setActiveActionMenuId(null);
  };

  const handleShareMessage = (text: string) => {
    if (navigator.share) {
      navigator.share({ title: 'Vyshu AI Message', text });
    } else {
      navigator.clipboard.writeText(text);
    }
    setActiveActionMenuId(null);
  };

  const handleDeleteMessage = (turnId?: string, id?: string) => {
    if (turnId) {
      setMessages((prev) => prev.filter((m) => m.turnId !== turnId));
      brainService.deleteTurn(turnId);
    } else if (id) {
      setMessages((prev) => prev.filter((m) => m.id !== id));
    }
    setActiveActionMenuId(null);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingMsg || !editingMsg.text.trim()) return;

    const originalMsg = messages.find((m) => m.id === editingMsg.id);
    const turnId = originalMsg?.turnId;

    // Remove old turn messages
    if (turnId) {
      setMessages((prev) => prev.filter((m) => m.turnId !== turnId));
      brainService.deleteTurn(turnId);
    }

    setEditingMsg(null);
    await handleSendMessage(editingMsg.text.trim());
  };

  const handleSelectMessage = (id: string) => {
    setSelectionMode(true);
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
    setActiveActionMenuId(null);
  };

  const handleDeleteSelected = () => {
    setMessages((prev) => prev.filter((m) => !selectedIds.has(m.id)));
    setSelectionMode(false);
    setSelectedIds(new Set());
  };

  // Strip tool tags before display
  const getCleanDisplayText = (text: string) => {
    return text.replace(/\[TOOL:[^\]]*\]/gi, '').trim();
  };

  // Compute theme background style
  const getWallpaperStyle = () => {
    if (cust.wallpaperUrl.startsWith('data:') || cust.wallpaperUrl.startsWith('http')) {
      return {
        backgroundImage: `linear-gradient(rgba(5, 5, 15, 0.85), rgba(5, 5, 15, 0.9)), url(${cust.wallpaperUrl})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      };
    }
    if (cust.wallpaperUrl === 'gradient:matrix-grid') {
      return { background: 'radial-gradient(ellipse at top, #062417 0%, #030e09 50%, #010503 100%)' };
    }
    if (cust.wallpaperUrl === 'gradient:stark-arc') {
      return { background: 'linear-gradient(180deg, #091a38 0%, #050e1f 50%, #02060e 100%)' };
    }
    if (cust.wallpaperUrl === 'gradient:ironman') {
      return { background: 'linear-gradient(180deg, #2a0b11 0%, #130407 50%, #060102 100%)' };
    }
    if (cust.wallpaperUrl === 'gradient:amethyst') {
      return { background: 'linear-gradient(180deg, #1b092c 0%, #0b0312 50%, #050109 100%)' };
    }
    if (cust.wallpaperUrl === 'gradient:pure-black') {
      return { background: '#000000' };
    }
    return { background: '#05050f' };
  };

  const fontClass =
    cust.fontStyle === 'mono'
      ? 'font-mono'
      : cust.fontStyle === 'serif'
      ? 'font-serif'
      : cust.fontStyle === 'display'
      ? 'font-sans tracking-wide'
      : 'font-sans';

  const userBubbleThemeBg =
    cust.theme === 'matrix-green'
      ? 'bg-[#059669]'
      : cust.theme === 'ironman-red'
      ? 'bg-[#dc2626]'
      : cust.theme === 'midnight-amethyst'
      ? 'bg-[#9333ea]'
      : cust.theme === 'nebula-rose'
      ? 'bg-[#db2777]'
      : cust.theme === 'sunset-gold'
      ? 'bg-[#d97706]'
      : cust.theme === 'stealth-black'
      ? 'bg-[#475569]'
      : 'bg-[#1e63e0]';

  return (
    <div
      style={getWallpaperStyle()}
      className={`flex-1 flex flex-col h-full text-slate-100 overflow-hidden relative ${fontClass}`}
    >
      {/* Hidden file input for photos */}
      <input
        type="file"
        ref={fileInputRef}
        accept="image/*"
        onChange={handleFileUpload}
        className="hidden"
      />

      {/* Header Bar */}
      {selectionMode ? (
        <div className="p-3 px-4 bg-[#0b0b16] border-b border-slate-800 flex items-center justify-between z-10">
          <div className="flex items-center space-x-3">
            <button
              onClick={() => {
                setSelectionMode(false);
                setSelectedIds(new Set());
              }}
              className="p-1 rounded-lg text-slate-400 hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>
            <span className="text-sm font-semibold text-white">{selectedIds.size} Selected</span>
          </div>

          <button
            onClick={handleDeleteSelected}
            disabled={selectedIds.size === 0}
            className="p-2 rounded-xl bg-rose-500/10 text-rose-400 hover:bg-rose-500/20 transition disabled:opacity-40"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ) : (
        <div className="p-3 px-5 bg-[#0b0b16] border-b border-slate-800/80 flex items-center justify-between z-10">
          {/* Avatar and status */}
          <div className="flex items-center space-x-3 cursor-pointer" onClick={() => onOpenFeatures('customization')}>
            <div className="relative">
              <div className="w-10 h-10 rounded-full overflow-hidden border-2 border-cyan-400/80 p-0.5 bg-gradient-to-tr from-cyan-500 to-purple-600 shadow-md glow-cyan">
                <img
                  src={cust.avatarUrl || "/assets/images/vyshu_avatar.png"}
                  alt="Vyshu AI"
                  className="w-full h-full object-cover rounded-full"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
                  }}
                />
              </div>
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-400 border-2 border-[#05050f] rounded-full animate-pulse"></span>
            </div>

            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-sm text-white tracking-wide">Vyshu AI</span>
                <span className="text-[10px] text-cyan-400 font-mono bg-cyan-500/10 px-1.5 py-0.5 rounded border border-cyan-500/20">
                  Secretary
                </span>
              </div>
              <div className="flex items-center gap-1 text-[11px] text-emerald-400">
                {cust.lastSeenMode !== 'stealth' && <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>}
                <span className="truncate max-w-[170px]">
                  {cust.lastSeenMode === 'custom'
                    ? cust.customLastSeenText
                    : cust.lastSeenMode === 'active_now'
                    ? 'Active Now • Systems 100%'
                    : cust.lastSeenMode === 'last_seen_just_now'
                    ? 'Last seen just now'
                    : cust.lastSeenMode === 'always_online'
                    ? '24/7 Guarded • Standing by for Teja'
                    : cust.lastSeenMode === 'stealth'
                    ? ''
                    : 'Online • 18 Languages'}
                </span>
              </div>
            </div>
          </div>

          {/* Quick controls: Studio Theme, Voice Reply, Hands-free, Mode */}
          <div className="flex items-center space-x-1.5">
            {/* Customization Studio Button */}
            <button
              onClick={() => onOpenFeatures('customization')}
              title="Vyshu Studio: Profile, Themes, Wallpaper & Emojis"
              className="p-2 rounded-xl bg-cyan-500/10 hover:bg-cyan-500/20 border border-cyan-500/30 text-cyan-300 transition"
            >
              <Palette className="w-4 h-4" />
            </button>

            {/* 24/7 Hands-Free Voice Listening Switch */}
            <button
              onClick={toggleHandsFree}
              title={isHandsFree247 ? 'Continuous voice listening active' : 'Turn on 24/7 hands-free voice mode'}
              className={`p-2 rounded-xl text-xs font-semibold flex items-center gap-1 transition ${
                isHandsFree247
                  ? 'bg-cyan-500 text-slate-950 font-bold shadow-md shadow-cyan-500/30 animate-pulse'
                  : 'bg-[#0e1422] text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              <Activity className="w-3.5 h-3.5" />
              <span className="hidden sm:inline text-[11px]">24/7 Voice</span>
            </button>

            {/* Voice Mute Toggle */}
            <button
              onClick={toggleVoiceOutput}
              title={voiceOutput ? 'Voice replies ON' : 'Voice replies OFF (Text Only)'}
              className={`p-2 rounded-xl transition ${
                voiceOutput
                  ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40'
                  : 'bg-[#0e1422] text-slate-500 border border-slate-800'
              }`}
            >
              {voiceOutput ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
            </button>

            {/* HOME / OFFICE Mode */}
            <button
              onClick={toggleMode}
              title={`Switch mode (Current: ${mode})`}
              className="px-3 py-1.5 rounded-xl bg-[#14142a] border border-[#2a2a4a] text-cyan-300 text-xs font-bold flex items-center gap-1.5 hover:border-cyan-400 transition"
            >
              {mode === 'HOME' ? <Home className="w-3.5 h-3.5 text-cyan-400" /> : <Briefcase className="w-3.5 h-3.5 text-purple-400" />}
              <span>{mode}</span>
            </button>
          </div>
        </div>
      )}

      {/* Suggested Quick Prompts */}
      <div className="p-2 px-4 bg-[#080814] border-b border-slate-800/40 flex items-center gap-2 overflow-x-auto no-scrollbar">
        {[
          { label: 'Vaani Play', query: 'Vaani, play my offline music' },
          { label: 'Next Song', query: 'Vaani, next song' },
          { label: 'Workout Streak', query: 'What is my workout consistency streak?' },
          { label: 'Time in Tokyo', query: 'What time is it in Tokyo right now?' },
          { label: 'Open YouTube', query: 'Open YouTube for me' },
          { label: 'Voice Calculation', query: 'Calculate 145 times 28 plus 500' },
          { label: 'Read News Briefing', query: 'Read today news briefing aloud' },
          { label: 'Toggle Torch', query: 'Turn on the torch' },
        ].map((item, idx) => (
          <button
            key={idx}
            onClick={() => handleSendMessage(item.query)}
            className="px-2.5 py-1 rounded-full bg-[#0e1422] hover:bg-slate-800 text-[11px] text-slate-300 border border-slate-800/80 whitespace-nowrap transition active:scale-95"
          >
            {item.label}
          </button>
        ))}
      </div>

      {/* Messages Scroll Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3.5">
        {messages.map((msg) => {
          const isUser = msg.role === 'user';
          const isSelected = selectedIds.has(msg.id);
          const cleanText = getCleanDisplayText(msg.text);

          return (
            <div
              key={msg.id}
              className={`flex flex-col ${isUser ? 'items-end' : 'items-start'} group relative`}
            >
              <div
                onClick={() => {
                  if (selectionMode) handleSelectMessage(msg.id);
                }}
                style={{ opacity: (cust.bubbleOpacity || 95) / 100 }}
                className={`max-w-[85%] sm:max-w-[75%] p-3.5 px-4.5 transition relative select-text ${
                  cust.layout === 'futuristic'
                    ? isUser
                      ? `${userBubbleThemeBg} text-white rounded-2xl rounded-tr-none border border-white/20 shadow-lg glow-cyan`
                      : 'bg-[#0e1422]/90 border border-cyan-500/40 text-slate-100 rounded-2xl rounded-tl-none shadow-md'
                    : cust.layout === 'compact'
                    ? isUser
                      ? `${userBubbleThemeBg} text-white rounded-lg p-2.5 px-3.5 text-xs shadow`
                      : 'bg-[#141426]/90 border border-slate-800 text-slate-100 rounded-lg p-2.5 px-3.5 text-xs'
                    : cust.layout === 'glass'
                    ? isUser
                      ? `${userBubbleThemeBg}/80 backdrop-blur-md text-white rounded-3xl rounded-br-sm border border-white/25 shadow-xl`
                      : 'bg-[#101026]/70 backdrop-blur-md border border-white/10 text-slate-100 rounded-3xl rounded-bl-sm shadow-xl'
                    : isUser
                    ? `${userBubbleThemeBg} text-white rounded-3xl rounded-br-sm shadow-md`
                    : 'bg-[#141426] border border-slate-800/80 text-slate-100 rounded-3xl rounded-bl-sm shadow-sm'
                } ${isSelected ? 'ring-2 ring-cyan-400 bg-cyan-950/40' : ''}`}
              >
                {/* Media rendering (Image / Sticker) */}
                {msg.type === 'image' && msg.path && (
                  <div className="mb-2 rounded-2xl overflow-hidden max-w-xs border border-white/20">
                    <img src={msg.path} alt="Uploaded media" className="w-full h-auto object-cover max-h-60" />
                  </div>
                )}

                {msg.type === 'sticker' && (() => {
                  // Check custom packs first, then fall back to STICKERS
                  let stickerEmoji = '✨';
                  let stickerLabel = msg.path || '';

                  for (const pack of stickerPacks) {
                    const match = pack.stickers.find((s) => s.name === msg.path || s.id === msg.path);
                    if (match) {
                      stickerEmoji = match.emoji;
                      stickerLabel = match.label;
                      break;
                    }
                  }

                  if (STICKERS[msg.path || '']) {
                    stickerEmoji = STICKERS[msg.path || ''].emoji;
                    stickerLabel = STICKERS[msg.path || ''].label;
                  }

                  return (
                    <div className="p-2 flex flex-col items-center">
                      <span className="text-4xl mb-1">{stickerEmoji}</span>
                      <span className="text-[11px] font-mono text-cyan-300">
                        {stickerLabel}
                      </span>
                    </div>
                  );
                })()}

                {/* Text body */}
                {cleanText && (
                  <div className="text-sm leading-relaxed whitespace-pre-wrap font-normal">
                    {cleanText}
                  </div>
                )}

                {/* Interactive Tool Actions */}
                {msg.toolAction && (
                  <div className="mt-2.5 pt-2 border-t border-white/10 flex flex-wrap gap-1.5">
                    {msg.toolAction.includes('OPEN_YOUTUBE') && (
                      <button
                        onClick={() => window.open('https://www.youtube.com', '_blank')}
                        className="px-2.5 py-1 rounded-lg bg-red-500/20 text-red-300 border border-red-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-red-500/30"
                      >
                        Launch YouTube <ExternalLink className="w-3 h-3" />
                      </button>
                    )}
                    {msg.toolAction.includes('OPEN_SPOTIFY') && (
                      <button
                        onClick={() => window.open('https://open.spotify.com', '_blank')}
                        className="px-2.5 py-1 rounded-lg bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-emerald-500/30"
                      >
                        Launch Spotify <ExternalLink className="w-3 h-3" />
                      </button>
                    )}
                    {msg.toolAction.includes('OPEN_WHATSAPP') && (
                      <button
                        onClick={() => window.open('https://web.whatsapp.com', '_blank')}
                        className="px-2.5 py-1 rounded-lg bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-emerald-500/30"
                      >
                        Open WhatsApp <ExternalLink className="w-3 h-3" />
                      </button>
                    )}
                    {msg.toolAction.includes('OPEN_DISCORD') && (
                      <button
                        onClick={() => window.open('https://discord.com/app', '_blank')}
                        className="px-2.5 py-1 rounded-lg bg-indigo-500/20 text-indigo-300 border border-indigo-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-indigo-500/30"
                      >
                        Open Discord <ExternalLink className="w-3 h-3" />
                      </button>
                    )}
                    {msg.toolAction.includes('TORCH_') && (
                      <button
                        onClick={() => {
                          const dev = storageService.getDeviceStatus();
                          storageService.saveDeviceStatus({ ...dev, torch: !dev.torch });
                        }}
                        className="px-2.5 py-1 rounded-lg bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-amber-500/30"
                      >
                        Torch Control
                      </button>
                    )}
                    {msg.toolAction.includes('VAANI_') && (
                      <button
                        onClick={() => onOpenFeatures('music')}
                        className="px-2.5 py-1 rounded-lg bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 text-[11px] font-semibold flex items-center gap-1 hover:bg-cyan-500/30"
                      >
                        <Music className="w-3 h-3 text-cyan-400" /> Vaani Player
                      </button>
                    )}
                  </div>
                )}

                {/* Timestamp and action menu trigger */}
                <div className="flex items-center justify-between text-[10px] text-white/50 mt-1.5 space-x-2">
                  <span>
                    {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setActiveActionMenuId(activeActionMenuId === msg.id ? null : msg.id);
                    }}
                    className="p-1 rounded hover:text-white transition"
                  >
                    <MoreVertical className="w-3 h-3" />
                  </button>
                </div>
              </div>

              {/* Message Context Actions Popup */}
              {activeActionMenuId === msg.id && (
                <div
                  className={`absolute z-30 ${isUser ? 'right-0' : 'left-0'} top-full mt-1 bg-[#181826] border border-slate-700/80 rounded-2xl p-1.5 shadow-2xl flex flex-col space-y-1 min-w-[140px] animate-fade-in`}
                >
                  <button
                    onClick={() => handleCopyMessage(cleanText)}
                    className="flex items-center gap-2 px-3 py-1.5 text-xs text-slate-300 hover:text-white hover:bg-slate-700/60 rounded-xl transition text-left"
                  >
                    <Copy className="w-3.5 h-3.5" /> Copy Text
                  </button>

                  <button
                    onClick={() => handleShareMessage(cleanText)}
                    className="flex items-center gap-2 px-3 py-1.5 text-xs text-slate-300 hover:text-white hover:bg-slate-700/60 rounded-xl transition text-left"
                  >
                    <Share2 className="w-3.5 h-3.5" /> Share
                  </button>

                  {isUser && (
                    <button
                      onClick={() => {
                        setEditingMsg({ id: msg.id, text: cleanText });
                        setActiveActionMenuId(null);
                      }}
                      className="flex items-center gap-2 px-3 py-1.5 text-xs text-slate-300 hover:text-white hover:bg-slate-700/60 rounded-xl transition text-left"
                    >
                      <Edit2 className="w-3.5 h-3.5" /> Edit Message
                    </button>
                  )}

                  <button
                    onClick={() => handleSelectMessage(msg.id)}
                    className="flex items-center gap-2 px-3 py-1.5 text-xs text-slate-300 hover:text-white hover:bg-slate-700/60 rounded-xl transition text-left"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" /> Select
                  </button>

                  <button
                    onClick={() => handleDeleteMessage(msg.turnId, msg.id)}
                    className="flex items-center gap-2 px-3 py-1.5 text-xs text-rose-400 hover:bg-rose-500/20 rounded-xl transition text-left"
                  >
                    <Trash2 className="w-3.5 h-3.5" /> Delete
                  </button>
                </div>
              )}
            </div>
          );
        })}

        {isTyping && (
          <div className="flex items-center space-x-2 text-xs text-cyan-400 font-mono p-2">
            <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping"></span>
            <span>Vyshu is preparing response...</span>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Editing Message Modal */}
      {editingMsg && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            onSubmit={handleEditSubmit}
            className="bg-[#0b0b16] border border-cyan-500/40 rounded-3xl p-5 max-w-md w-full space-y-4 glow-cyan"
          >
            <div className="text-sm font-bold text-white flex items-center gap-2">
              <Edit2 className="w-4 h-4 text-cyan-400" /> Edit &amp; Regenerate Vyshu&apos;s Reply
            </div>
            <textarea
              rows={3}
              value={editingMsg.text}
              onChange={(e) => setEditingMsg({ ...editingMsg, text: e.target.value })}
              className="w-full bg-[#0e1422] border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:outline-none focus:border-cyan-400"
            />
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setEditingMsg(null)}
                className="px-3.5 py-1.5 rounded-xl bg-slate-800 text-slate-400 text-xs font-semibold hover:bg-slate-700"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-1.5 rounded-xl bg-cyan-400 text-slate-950 text-xs font-bold hover:bg-cyan-300"
              >
                Save &amp; Resend
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Stickers & Emojis Sheet */}
      {showStickerPicker && (
        <div className="p-4 bg-[#0e1422] border-t border-slate-800 max-h-64 overflow-y-auto space-y-3">
          <div className="flex items-center justify-between text-xs font-semibold text-slate-300">
            <div className="flex items-center space-x-2">
              <span className="text-cyan-400 font-bold">Stickers &amp; Custom Emojis</span>
              <button
                onClick={() => {
                  setShowStickerPicker(false);
                  onOpenFeatures('customization');
                }}
                className="text-[10px] text-purple-400 hover:underline font-mono"
              >
                + Studio Creator
              </button>
            </div>
            <button onClick={() => setShowStickerPicker(false)}>
              <X className="w-4 h-4 text-slate-400 hover:text-white" />
            </button>
          </div>

          {/* Sticker Pack Tabs */}
          <div className="flex items-center space-x-1.5 overflow-x-auto no-scrollbar pb-1">
            <button
              onClick={() => setActiveStickerTab('all')}
              className={`px-2.5 py-1 rounded-lg text-[10px] font-semibold transition ${
                activeStickerTab === 'all'
                  ? 'bg-cyan-400 text-slate-950 font-bold'
                  : 'bg-[#080814] text-slate-400 hover:text-white'
              }`}
            >
              All Packs
            </button>
            <button
              onClick={() => setActiveStickerTab('emojis')}
              className={`px-2.5 py-1 rounded-lg text-[10px] font-semibold transition ${
                activeStickerTab === 'emojis'
                  ? 'bg-cyan-400 text-slate-950 font-bold'
                  : 'bg-[#080814] text-slate-400 hover:text-white'
              }`}
            >
              Custom Emojis ({customEmojis.length})
            </button>
            {stickerPacks.map((pack) => (
              <button
                key={pack.id}
                onClick={() => setActiveStickerTab(pack.id)}
                className={`px-2.5 py-1 rounded-lg text-[10px] font-semibold whitespace-nowrap transition ${
                  activeStickerTab === pack.id
                    ? 'bg-cyan-400 text-slate-950 font-bold'
                    : 'bg-[#080814] text-slate-400 hover:text-white'
                }`}
              >
                {pack.title}
              </button>
            ))}
          </div>

          {/* Custom Emojis Tab View */}
          {activeStickerTab === 'emojis' && (
            <div className="grid grid-cols-4 sm:grid-cols-6 gap-2">
              {customEmojis.map((e) => (
                <button
                  key={e.id}
                  onClick={() => {
                    setInput((prev) => prev + ' ' + e.iconData);
                    setShowStickerPicker(false);
                  }}
                  className="p-2 rounded-xl bg-[#080814] hover:bg-slate-800 border border-slate-800/80 flex flex-col items-center justify-center transition active:scale-95"
                >
                  <span className="text-2xl">{e.iconData}</span>
                  <span className="text-[9px] text-cyan-400 font-mono truncate w-full text-center">{e.code}</span>
                </button>
              ))}
            </div>
          )}

          {/* Sticker Packs View */}
          {activeStickerTab !== 'emojis' && (
            <div className="space-y-3">
              {stickerPacks
                .filter((p) => activeStickerTab === 'all' || p.id === activeStickerTab)
                .map((pack) => (
                  <div key={pack.id} className="space-y-1.5">
                    <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">
                      {pack.title}
                    </div>
                    <div className="grid grid-cols-4 sm:grid-cols-6 gap-2">
                      {pack.stickers.map((stk) => (
                        <button
                          key={stk.id}
                          onClick={() => {
                            // Inject custom sticker message
                            const newMsg: ChatMessage = {
                              id: Date.now().toString(),
                              role: 'user',
                              text: `[Sticker: ${stk.label}]`,
                              type: 'sticker',
                              path: stk.name,
                              timestamp: new Date().toISOString(),
                            };
                            setMessages((prev) => [...prev, newMsg]);
                            setShowStickerPicker(false);
                            audioService.playSound('send');

                            // Trigger prompt
                            setTimeout(async () => {
                              setIsTyping(true);
                              const res = await brainService.respond(`I sent you a ${stk.label} sticker!`, mode);
                              setIsTyping(false);
                              setMessages((prev) => [
                                ...prev,
                                {
                                  id: res.id,
                                  role: 'vyshu',
                                  text: res.text,
                                  type: res.sticker ? 'sticker' : 'text',
                                  path: res.sticker,
                                  timestamp: new Date().toISOString(),
                                },
                              ]);
                            }, 500);
                          }}
                          className="p-2.5 rounded-2xl bg-[#080814] hover:bg-slate-800 border border-slate-800/80 flex flex-col items-center justify-center space-y-1 transition active:scale-95"
                        >
                          <span className="text-2xl">{stk.emoji}</span>
                          <span className="text-[10px] text-slate-400 truncate max-w-full">{stk.label}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                ))}
            </div>
          )}
        </div>
      )}

      {/* Attachment Options Menu */}
      {showAttachmentMenu && (
        <div className="p-3 bg-[#0e1422] border-t border-slate-800 flex items-center justify-around">
          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex flex-col items-center space-y-1 text-slate-300 hover:text-cyan-400"
          >
            <div className="p-2.5 rounded-full bg-cyan-500/10 border border-cyan-500/20">
              <ImageIcon className="w-5 h-5 text-cyan-400" />
            </div>
            <span className="text-[11px]">Send Photo</span>
          </button>

          <button
            onClick={() => {
              setShowStickerPicker(true);
              setShowAttachmentMenu(false);
            }}
            className="flex flex-col items-center space-y-1 text-slate-300 hover:text-purple-400"
          >
            <div className="p-2.5 rounded-full bg-purple-500/10 border border-purple-500/20">
              <Smile className="w-5 h-5 text-purple-400" />
            </div>
            <span className="text-[11px]">Send Sticker</span>
          </button>
        </div>
      )}

      {/* Bottom Input Bar */}
      <div className="p-3 px-4 bg-[#0b0b16] border-t border-slate-800/80 flex items-center space-x-2 z-10">
        <button
          onClick={() => setShowAttachmentMenu(!showAttachmentMenu)}
          className="p-2 rounded-xl text-slate-400 hover:text-cyan-400 hover:bg-slate-800/60 transition"
        >
          <Plus className="w-5 h-5" />
        </button>

        {/* Mic / Push-to-talk button */}
        <button
          onClick={handleToggleMic}
          className={`p-2 rounded-xl transition ${
            isListening
              ? 'bg-rose-500 text-white animate-pulse shadow-md shadow-rose-500/40'
              : 'text-cyan-400 hover:bg-slate-800/60'
          }`}
          title={isListening ? 'Stop Listening' : 'Voice Input (Speech-to-text)'}
        >
          {isListening ? <Mic className="w-5 h-5" /> : <MicOff className="w-5 h-5 text-slate-400 hover:text-cyan-400" />}
        </button>

        {/* Text Input */}
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') handleSendMessage();
          }}
          placeholder="Message Vyshu AI..."
          className="flex-1 bg-[#14142a] border border-slate-800 rounded-2xl px-4 py-2.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-cyan-400 transition"
        />

        {/* Send Button */}
        <button
          onClick={() => handleSendMessage()}
          disabled={!input.trim()}
          className="p-2.5 rounded-2xl bg-[#1e63e0] text-white hover:bg-blue-600 disabled:opacity-40 transition active:scale-95 shadow-md shadow-blue-500/20"
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
