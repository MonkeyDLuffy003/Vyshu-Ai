import React, { useState, useEffect, useRef } from 'react';
import {
  Mic,
  MicOff,
  Volume2,
  VolumeX,
  Sparkles,
  BookOpen,
  Home,
  Briefcase,
  PlaySquare,
  Music,
  MessageCircle,
  PhoneCall,
  Image as ImageIcon,
  Camera,
  Calendar,
  Compass,
  Globe,
  FolderArchive,
  Settings,
  Terminal,
  Zap,
  CheckCircle2,
  Search,
  ExternalLink,
  Plus,
  RefreshCw,
  Eye,
  Sliders,
  X,
  Smartphone,
  ChevronRight,
  Maximize2,
  Info,
} from 'lucide-react';
import { audioService } from '../services/audioService';
import { brainService } from '../services/brainService';
import { storageService } from '../services/storageService';
import { vyshuActivationService } from '../services/vyshuActivationService';
import {
  androidCapabilityService,
  AndroidLibraryBook,
  LibraryCategory,
} from '../services/androidCapabilityService';

interface VirtualRoomProps {
  onOpenFeatures?: (tab?: any) => void;
  onSwitchToChat?: () => void;
}

export type RoomViewMode = 'cozy-penthouse' | 'library-bookshelf' | 'workstation' | 'lounge';

export const VirtualRoom: React.FC<VirtualRoomProps> = ({
  onOpenFeatures,
  onSwitchToChat,
}) => {
  const [viewMode, setViewMode] = useState<RoomViewMode>('cozy-penthouse');
  const [books, setBooks] = useState<AndroidLibraryBook[]>([]);
  const [selectedBook, setSelectedBook] = useState<AndroidLibraryBook | null>(null);
  const [activeCategory, setActiveCategory] = useState<LibraryCategory | 'all'>('all');
  const [speechText, setSpeechText] = useState<string>('');
  const [isListening, setIsListening] = useState(false);
  const [voiceOutput, setVoiceOutput] = useState(true);
  const [mode, setMode] = useState<'HOME' | 'OFFICE'>('HOME');
  const [liveTranscript, setLiveTranscript] = useState<string>('');
  const [customInput, setCustomInput] = useState('');
  const [isLauncherMode, setIsLauncherMode] = useState(false);
  const [showAddAppModal, setShowAddAppModal] = useState(false);
  const [newAppName, setNewAppName] = useState('');
  const [newPackageName, setNewPackageName] = useState('');
  const [newAppCategory, setNewAppCategory] = useState<LibraryCategory>('study_work');
  const [hologramInterference, setHologramInterference] = useState(false);
  const [activeInterferenceTag, setActiveInterferenceTag] = useState<string | null>(null);
  const [vyshuState, setVyshuState] = useState<'attentive' | 'reading' | 'speaking' | 'launching'>('attentive');

  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    setBooks(androidCapabilityService.getBooks());
    setIsLauncherMode(androidCapabilityService.isLauncherMode());
    const savedMode = storageService.getChatMode() || 'HOME';
    setMode(savedMode);
    const savedVoice = storageService.getVoiceOutput();
    setVoiceOutput(savedVoice);

    const getDynamicGreeting = () => {
      const hour = new Date().getHours();
      const greetings =
        savedMode === 'HOME'
          ? hour < 12
            ? [
                "Morning, Teja. All systems are smooth. What's on your mind today?",
                "Good morning, Teja. Everything is ready on your shelf whenever you need.",
                "Morning, Teja. Ready when you are.",
              ]
            : hour < 17
            ? [
                "Good afternoon, Teja. How's the day treating you?",
                "Afternoon, Teja. Running smoothly here. What are we diving into?",
                "Right here with you, Teja. Say the word.",
              ]
            : [
                "Hey Teja! How was your day?",
                "Evening, Teja! What are we up to tonight?",
                "Hey Teja, good to see you. How's everything going?",
              ]
          : [
              "Executive protocols active, Teja sir. Standing by.",
              "All operating layers synchronized, Teja sir. At your command.",
              "System ready, Teja sir.",
            ];
      return greetings[Math.floor(Math.random() * greetings.length)];
    };

    const greeting = getDynamicGreeting();
    setSpeechText(greeting);
    if (savedVoice) {
      audioService.speak(greeting, 'en-IN');
    }

    // 3-finger swipe gesture trigger
    const unsub = vyshuActivationService.onActivate(() => {
      triggerInterference('3-FINGER HUD INVOCATION');
      handleStartListening();
    });

    return () => unsub();
  }, []);

  // Canvas particle / room ambient lighting
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animId: number;
    let width = (canvas.width = canvas.parentElement?.clientWidth || window.innerWidth);
    let height = (canvas.height = canvas.parentElement?.clientHeight || window.innerHeight);

    const onResize = () => {
      if (!canvas.parentElement) return;
      width = canvas.width = canvas.parentElement.clientWidth;
      height = canvas.height = canvas.parentElement.clientHeight;
    };
    window.addEventListener('resize', onResize);

    const particles = Array.from({ length: 30 }, () => ({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.4,
      vy: (Math.random() - 0.5) * 0.4,
      radius: Math.random() * 2 + 1,
      alpha: Math.random() * 0.5 + 0.2,
    }));

    const render = () => {
      ctx.clearRect(0, 0, width, height);

      particles.forEach((p) => {
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0 || p.x > width) p.vx *= -1;
        if (p.y < 0 || p.y > height) p.vy *= -1;

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(0, 204, 255, ${p.alpha})`;
        ctx.fill();
      });

      animId = requestAnimationFrame(render);
    };
    render();

    return () => {
      cancelAnimationFrame(animId);
      window.removeEventListener('resize', onResize);
    };
  }, []);

  // Trigger Holographic AI Interference
  const triggerInterference = (tag: string) => {
    setHologramInterference(true);
    setActiveInterferenceTag(tag);
    audioService.playSound('toggle');
    setTimeout(() => {
      setHologramInterference(false);
      setActiveInterferenceTag(null);
    }, 2400);
  };

  // Launch Book / Android Capability
  const handleLaunchBook = (book: AndroidLibraryBook, params?: { query?: string }) => {
    setSelectedBook(book);
    setVyshuState('launching');
    triggerInterference(`LAUNCHING: ${book.appName.toUpperCase()}`);

    const launchPhrases =
      mode === 'HOME'
        ? [
            `Bringing up ${book.appName} now, Teja.`,
            `Launching ${book.appName}.`,
            `Opening ${book.appName} for you.`,
          ]
        : [
            `Executing Android intent for ${book.appName}, Teja sir.`,
            `Launching ${book.appName}, Teja sir.`,
          ];
    const announcement = launchPhrases[Math.floor(Math.random() * launchPhrases.length)];

    setSpeechText(announcement);
    if (voiceOutput) {
      audioService.speak(announcement, 'en-IN');
    }

    // Execute immediately without delay
    setTimeout(() => {
      const res = androidCapabilityService.launchBook(book, params);
      setBooks(androidCapabilityService.getBooks());
      setVyshuState('attentive');
    }, 250);
  };

  // Toggle Mode
  const handleToggleMode = () => {
    const next = mode === 'HOME' ? 'OFFICE' : 'HOME';
    setMode(next);
    storageService.setChatMode(next);
    audioService.playSound('toggle');

    const msg =
      next === 'HOME'
        ? 'Hi Teja! Home mode engaged in the virtual room.'
        : 'Hi, Teja sir. Office executive protocols online.';

    setSpeechText(msg);
    if (voiceOutput) audioService.speak(msg, 'en-IN');
  };

  // Voice Interaction
  const handleStartListening = () => {
    if (isListening) {
      audioService.stopListening();
      setIsListening(false);
      return;
    }

    setIsListening(true);
    setVyshuState('attentive');
    audioService.playSound('click');

    audioService.startListening(
      (recognized, isFinal) => {
        setLiveTranscript(recognized);
        if (isFinal && recognized.trim()) {
          setIsListening(false);
          handleProcessIntent(recognized);
        }
      },
      () => setIsListening(false),
      (status) => setIsListening(status)
    );
  };

  // Natural Language Intent Engine inside Virtual Room
  const handleProcessIntent = async (command: string) => {
    setVyshuState('reading');
    const lower = command.toLowerCase().trim();

    // 1. Direct match with Android Library Books
    const matchedBook = androidCapabilityService.matchIntentToBook(command);
    if (matchedBook) {
      handleLaunchBook(matchedBook, { query: command });
      return;
    }

    // 2. Room View Switcher
    if (lower.includes('bookshelf') || lower.includes('library') || lower.includes('all apps')) {
      setViewMode('library-bookshelf');
      const msg =
        mode === 'HOME'
          ? 'Here is your Android Library Shelf, Teja! Every book represents an app.'
          : 'Displaying Android Capability Bookshelf, Teja sir.';
      setSpeechText(msg);
      if (voiceOutput) audioService.speak(msg, 'en-IN');
      setVyshuState('attentive');
      return;
    }

    if (lower.includes('main view') || lower.includes('room') || lower.includes('cozy')) {
      setViewMode('cozy-penthouse');
      return;
    }

    // 3. Fallback to Brain Service
    try {
      const reply = await brainService.respond(command, mode);
      setSpeechText(reply.text);
      setVyshuState('speaking');

      if (voiceOutput) {
        audioService.speak(reply.text, 'en-IN');
      }

      // Check if brain service output an intent tool tag
      if (reply.text.includes('[TOOL: LAUNCH_BOOK:')) {
        const match = reply.text.match(/\[TOOL: LAUNCH_BOOK:(.+?)(?:\|(.*))?\]/);
        if (match) {
          const bookId = match[1].trim();
          const target = books.find((b) => b.id === bookId);
          if (target) {
            handleLaunchBook(target, { query: match[2] });
          }
        }
      }

      setTimeout(() => setVyshuState('attentive'), 4000);
    } catch {
      setVyshuState('attentive');
    }
  };

  const handleInputSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customInput.trim()) return;
    const txt = customInput;
    setCustomInput('');
    handleProcessIntent(txt);
  };

  // Add custom discovered Android app
  const handleAddCustomApp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAppName.trim() || !newPackageName.trim()) return;

    const book = androidCapabilityService.registerInstalledApp(
      newAppName.trim(),
      newPackageName.trim(),
      newAppCategory
    );

    setBooks(androidCapabilityService.getBooks());
    setShowAddAppModal(false);
    setNewAppName('');
    setNewPackageName('');

    audioService.playSound('send');
    const msg =
      mode === 'HOME'
        ? `Added ${book.appName} to your Android Library, Teja!`
        : `Package ${book.packageName} indexed in Library, Teja sir.`;
    setSpeechText(msg);
    if (voiceOutput) audioService.speak(msg, 'en-IN');
  };

  // Toggle Android Launcher Home mode
  const handleToggleLauncherMode = () => {
    const next = !isLauncherMode;
    setIsLauncherMode(next);
    androidCapabilityService.setLauncherMode(next);
    audioService.playSound('toggle');

    const msg = next
      ? 'Vyshu is now configured as your primary Android AI Interface & Home Screen!'
      : 'Vyshu launcher mode toggled off.';

    setSpeechText(msg);
    if (voiceOutput) audioService.speak(msg, 'en-IN');
  };

  const filteredBooks =
    activeCategory === 'all' ? books : books.filter((b) => b.category === activeCategory);

  // Helper to render book icon
  const renderBookIcon = (iconName: string) => {
    switch (iconName) {
      case 'PlaySquare':
        return <PlaySquare className="w-5 h-5 text-red-400" />;
      case 'Music':
        return <Music className="w-5 h-5 text-emerald-400" />;
      case 'MessageCircle':
        return <MessageCircle className="w-5 h-5 text-green-400" />;
      case 'PhoneCall':
        return <PhoneCall className="w-5 h-5 text-blue-400" />;
      case 'Image':
        return <ImageIcon className="w-5 h-5 text-amber-400" />;
      case 'Camera':
        return <Camera className="w-5 h-5 text-pink-400" />;
      case 'Calendar':
        return <Calendar className="w-5 h-5 text-indigo-400" />;
      case 'Compass':
        return <Compass className="w-5 h-5 text-cyan-400" />;
      case 'Globe':
        return <Globe className="w-5 h-5 text-purple-400" />;
      case 'FolderArchive':
        return <FolderArchive className="w-5 h-5 text-yellow-400" />;
      case 'Settings':
        return <Settings className="w-5 h-5 text-slate-400" />;
      default:
        return <BookOpen className="w-5 h-5 text-teal-400" />;
    }
  };

  return (
    <div className="relative w-full h-full overflow-hidden bg-[#070914] text-slate-100 select-none flex flex-col">
      {/* Background Room Canvas */}
      <canvas ref={canvasRef} className="absolute inset-0 pointer-events-none z-0" />

      {/* Futuristic Room Lighting Overlay (Night City Skyline + Ambient Glows) */}
      <div className="absolute inset-0 bg-gradient-to-t from-[#050713] via-transparent to-[#0b1026]/70 pointer-events-none z-0" />

      {/* Top Header Bar: Status, Mode, Launcher Switch */}
      <div className="relative z-20 p-3 px-4 flex items-center justify-between border-b border-slate-800/80 bg-[#060814]/90 backdrop-blur-md">
        <div className="flex items-center space-x-3">
          <div className="relative">
            <div className="w-10 h-10 rounded-2xl bg-cyan-500/10 border border-cyan-400/50 p-1 flex items-center justify-center glow-cyan shadow-lg">
              <img
                src="/assets/images/vyshu_logo.png"
                alt="Vyshu APK Logo"
                className="w-full h-full object-contain"
              />
            </div>
            <span className="absolute -bottom-1 -right-1 w-3 h-3 rounded-full bg-emerald-400 border-2 border-[#060814] animate-ping" />
            <span className="absolute -bottom-1 -right-1 w-3 h-3 rounded-full bg-emerald-400 border-2 border-[#060814]" />
          </div>

          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-sm tracking-wide text-white">VYSHU AI</span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-cyan-500/20 text-cyan-300 border border-cyan-500/40">
                AI-NATIVE ANDROID
              </span>
            </div>
            <div className="text-[11px] text-slate-400 flex items-center gap-1.5 font-mono">
              <span className="text-emerald-400">● LIVE ROOM</span>
              <span>•</span>
              <span className="text-cyan-300">APPS: {books.length} READY</span>
              <span>•</span>
              <span className="text-purple-300">{isLauncherMode ? 'HOME LAUNCHER' : 'ORCHESTRATOR'}</span>
            </div>
          </div>
        </div>

        {/* Controls: Mode, Launcher, Voice Output */}
        <div className="flex items-center space-x-2">
          {/* Mode Switch */}
          <button
            onClick={handleToggleMode}
            className={`px-2.5 py-1.5 rounded-xl text-xs font-bold border transition flex items-center gap-1.5 ${
              mode === 'HOME'
                ? 'bg-pink-500/20 text-pink-300 border-pink-500/40 glow-purple'
                : 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40 glow-cyan'
            }`}
          >
            {mode === 'HOME' ? <Home className="w-3.5 h-3.5" /> : <Briefcase className="w-3.5 h-3.5" />}
            <span className="hidden sm:inline">{mode === 'HOME' ? 'HOME: Hi Teja' : 'OFFICE: Teja sir'}</span>
          </button>

          {/* Launcher Mode Switch */}
          <button
            onClick={handleToggleLauncherMode}
            title={isLauncherMode ? 'Vyshu is Home Launcher' : 'Make Vyshu default Android Home Interface'}
            className={`px-2.5 py-1.5 rounded-xl text-xs font-bold border transition flex items-center gap-1.5 ${
              isLauncherMode
                ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40 glow-emerald'
                : 'bg-[#0d1326] text-slate-400 border-slate-800 hover:text-white'
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            <span className="hidden md:inline">Launcher</span>
          </button>

          {/* Voice Mute Toggle */}
          <button
            onClick={() => setVoiceOutput(!voiceOutput)}
            className={`p-2 rounded-xl border transition ${
              voiceOutput
                ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40'
                : 'bg-slate-800 text-slate-500 border-slate-700'
            }`}
          >
            {voiceOutput ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>

          {/* Switch to Chat */}
          {onSwitchToChat && (
            <button
              onClick={onSwitchToChat}
              className="p-2 rounded-xl bg-[#0d1326] text-slate-400 border border-slate-800 hover:text-cyan-300 transition"
              title="Return to Vyshu Chat"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Main Room View Area */}
      <div className="relative z-10 flex-1 flex flex-col justify-between overflow-hidden p-3 sm:p-5">
        {/* Top Floating Speech & Intent HUD */}
        <div className="max-w-xl w-full mx-auto z-20">
          <div className="p-3.5 px-4 rounded-2xl bg-[#080d22]/90 border border-cyan-500/35 backdrop-blur-md shadow-2xl glow-cyan animate-fade-in relative">
            <div className="flex items-center justify-between mb-1.5">
              <div className="flex items-center space-x-2">
                <span className="w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
                <span className="text-[11px] font-bold uppercase tracking-wider text-cyan-400 font-mono">
                  {mode === 'HOME' ? 'Vyshu (Your AI Companion)' : 'Vyshu (Executive Orchestrator)'}
                </span>
              </div>
              <span className="text-[10px] text-slate-400 font-mono">
                {vyshuState.toUpperCase()}
              </span>
            </div>

            <p className="text-sm font-medium text-slate-100 leading-relaxed drop-shadow">
              &ldquo;{speechText}&rdquo;
            </p>

            {isListening && liveTranscript && (
              <div className="mt-2 pt-2 border-t border-cyan-500/20 text-xs text-cyan-300 font-mono flex items-center gap-1.5">
                <Mic className="w-3.5 h-3.5 animate-pulse text-cyan-400" />
                <span>Hearing: &ldquo;{liveTranscript}&rdquo;</span>
              </div>
            )}
          </div>
        </div>

        {/* Center Environment Representation (Cozy Penthouse or Library Bookshelf) */}
        {viewMode === 'cozy-penthouse' ? (
          <div className="relative my-auto flex flex-col items-center justify-center">
            {/* Holographic Interference Screen Effect */}
            {hologramInterference && (
              <div className="absolute inset-0 z-30 pointer-events-none flex items-center justify-center">
                <div className="w-full h-full bg-cyan-400/10 mix-blend-screen animate-pulse filter blur-sm" />
                <div className="absolute top-2 px-3 py-1 rounded-full bg-cyan-500 text-slate-950 font-bold font-mono text-xs shadow-lg glow-cyan animate-bounce">
                  ⚡ {activeInterferenceTag || 'AI INTERFERENCE'}
                </div>
              </div>
            )}

            {/* 3D Holographic Launcher & Room Books Shelf Layout */}
            <div className="w-full max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-12 gap-4 items-center">
              {/* Left Column: Interactive 3D Android Apps Shelf Grid */}
              <div className="md:col-span-4 bg-[#070b18]/85 border border-cyan-500/30 rounded-2xl p-3.5 backdrop-blur-md glow-cyan shadow-xl order-2 md:order-1">
                <div className="flex items-center justify-between pb-2 mb-2 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <BookOpen className="w-4 h-4 text-cyan-400" />
                    <span className="text-xs font-extrabold text-white tracking-wider">APPS SHELF</span>
                  </div>
                  <button
                    onClick={() => setViewMode('library-bookshelf')}
                    className="text-[10px] text-cyan-400 font-bold hover:underline"
                  >
                    View All ({books.length})
                  </button>
                </div>
                <div className="text-[10px] text-slate-400 mb-2">
                  Organized applications ready on your shelf.
                </div>
                {/* 6 Core Quick Launch Books */}
                <div className="grid grid-cols-3 gap-2">
                  {books.slice(0, 6).map((b) => (
                    <button
                      key={b.id}
                      onClick={() => handleLaunchBook(b)}
                      className="flex flex-col items-center justify-center p-2 rounded-xl bg-slate-900/80 border border-slate-800 hover:border-cyan-400/60 hover:bg-cyan-950/30 transition group text-center"
                    >
                      <div
                        className="w-8 h-8 rounded-lg flex items-center justify-center mb-1 text-white shadow-md transition transform group-hover:scale-110"
                        style={{ backgroundColor: `${b.spineColor}33`, borderColor: b.spineColor, borderWidth: '1px' }}
                      >
                        {renderBookIcon(b.icon)}
                      </div>
                      <span className="text-[10px] font-semibold text-slate-200 truncate w-full">
                        {b.appName.split('/')[0].trim()}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Center Column: Central Vyshu Holographic Presence */}
              <div className="md:col-span-4 flex flex-col items-center justify-center order-1 md:order-2">
                <div
                  className="relative group cursor-pointer"
                  onClick={() => {
                    triggerInterference('RESONANCE SYNC');
                    const tapReplies =
                      mode === 'HOME'
                        ? [
                            "Right here, Teja. All systems are smooth.",
                            "Listening, Teja. What are we getting into?",
                            "Ready when you are, Teja.",
                          ]
                        : [
                            "Operating layers synchronized, Teja sir.",
                            "Standing by, Teja sir.",
                          ];
                    const reply = tapReplies[Math.floor(Math.random() * tapReplies.length)];
                    setSpeechText(reply);
                    if (voiceOutput) audioService.speak(reply, 'en-IN');
                  }}
                >
                  {/* Outer Gyroscope Rings */}
                  <div className="absolute -inset-6 rounded-full border border-cyan-400/20 border-dashed animate-spin-slow pointer-events-none" />
                  <div className="absolute -inset-12 rounded-full border border-purple-500/20 animate-reverse-spin pointer-events-none" />

                  {/* Character Visual: Vyshu's Authentic Portrait in Red Beret */}
                  <div className="relative w-44 h-60 sm:w-52 sm:h-68 rounded-3xl overflow-hidden border-2 border-cyan-400/80 shadow-[0_0_40px_rgba(0,204,255,0.4)] bg-[#070b18] p-1">
                    <img
                      src="/assets/images/vyshu_avatar.png"
                      alt="Vyshu AI in Virtual Room"
                      className="w-full h-full object-cover rounded-2xl"
                    />

                    {/* Scanline & ambient overlay */}
                    <div className="absolute inset-0 bg-gradient-to-b from-transparent via-cyan-400/5 to-cyan-500/20 pointer-events-none" />
                    <div className="absolute inset-0 bg-[linear-gradient(rgba(18,16,16,0)_50%,rgba(0,204,255,0.12)_50%)] bg-[length:100%_4px] pointer-events-none" />

                    {/* Room status badge */}
                    <div className="absolute bottom-2 left-2 right-2 bg-[#050814]/85 backdrop-blur-md py-1.5 px-3 rounded-xl border border-cyan-500/30 flex items-center justify-between">
                      <span className="text-[10px] font-bold text-white flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                        <span>Vyshu AI</span>
                      </span>
                      <span className="text-[9px] text-cyan-400 font-mono">
                        {mode === 'HOME' ? 'Cozy Companion' : 'Executive'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* 3D Holo-Plate Base */}
                <div className="w-36 h-4 mt-2 rounded-full bg-gradient-to-r from-transparent via-cyan-400/40 to-transparent blur-xs border-b border-cyan-400" />
              </div>

              {/* Right Column: Live Android Holographic Notification & OS State Panel */}
              <div className="md:col-span-4 bg-[#070b18]/85 border border-cyan-500/30 rounded-2xl p-3.5 backdrop-blur-md glow-cyan shadow-xl order-3">
                <div className="flex items-center justify-between pb-2 mb-2 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <Smartphone className="w-4 h-4 text-cyan-400" />
                    <span className="text-xs font-extrabold text-white tracking-wider">PHONE HUD & NOTIFICATIONS</span>
                  </div>
                  <span className="text-[9px] font-mono text-emerald-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                    ONLINE
                  </span>
                </div>

                <div className="space-y-2 max-h-[160px] overflow-y-auto pr-1">
                  <div className="p-2 rounded-xl bg-slate-900/70 border border-slate-800 flex items-start gap-2.5">
                    <div className="w-6 h-6 rounded-lg bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0 text-xs">
                      💬
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="text-[11px] font-semibold text-white">WhatsApp</span>
                        <span className="text-[9px] text-slate-500">Just now</span>
                      </div>
                      <p className="text-[10px] text-slate-400 truncate">Mom: Take care beta ❤️</p>
                    </div>
                  </div>

                  <div className="p-2 rounded-xl bg-slate-900/70 border border-slate-800 flex items-start gap-2.5">
                    <div className="w-6 h-6 rounded-lg bg-red-500/20 text-red-400 flex items-center justify-center shrink-0 text-xs">
                      ▶️
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="text-[11px] font-semibold text-white">YouTube</span>
                        <span className="text-[9px] text-slate-500">10m ago</span>
                      </div>
                      <p className="text-[10px] text-slate-400 truncate">New tech drops in AI robotics</p>
                    </div>
                  </div>

                  <div className="p-2 rounded-xl bg-slate-900/70 border border-slate-800 flex items-start gap-2.5">
                    <div className="w-6 h-6 rounded-lg bg-blue-500/20 text-blue-400 flex items-center justify-center shrink-0 text-xs">
                      🛡️
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="text-[11px] font-semibold text-cyan-300">Call Shield</span>
                        <span className="text-[9px] text-slate-500">Active</span>
                      </div>
                      <p className="text-[10px] text-slate-400 truncate">Spam blocker armed & identity masked</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* ========================================================================= */
          /* THE VYSHU LIBRARY: 3D Bookshelf of Android Applications & Capabilities   */
          /* ========================================================================= */
          <div className="flex-1 flex flex-col overflow-hidden max-w-4xl w-full mx-auto bg-[#080c20]/80 border border-cyan-500/30 rounded-3xl p-4 backdrop-blur-md glow-cyan my-auto max-h-[70vh]">
            {/* Shelf Header */}
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center space-x-2.5">
                <div className="p-2 rounded-xl bg-cyan-500/10 border border-cyan-500/30 text-cyan-400">
                  <BookOpen className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-sm font-extrabold text-white flex items-center gap-2">
                    <span>VYSHU LIBRARY — ANDROID CAPABILITY SHELF</span>
                    <span className="text-[10px] font-mono text-cyan-400 bg-cyan-500/10 px-2 py-0.5 rounded-full border border-cyan-500/20">
                      {books.length} Installed Capabilities
                    </span>
                  </div>
                  <div className="text-[11px] text-slate-400">
                    Each book connects directly to an Android application or system intent.
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setShowAddAppModal(true)}
                  className="px-2.5 py-1.5 rounded-xl bg-cyan-400 text-slate-950 text-xs font-bold hover:bg-cyan-300 transition flex items-center gap-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Add App</span>
                </button>

                <button
                  onClick={() => setViewMode('cozy-penthouse')}
                  className="p-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition"
                  title="Close Shelf"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Category Filter Tabs */}
            <div className="flex items-center gap-1.5 py-2.5 overflow-x-auto no-scrollbar border-b border-slate-800/60">
              {(
                [
                  'all',
                  'entertainment',
                  'music',
                  'communication',
                  'memories',
                  'knowledge',
                  'planning',
                  'camera',
                  'navigation',
                  'study_work',
                  'system',
                ] as const
              ).map((cat) => (
                <button
                  key={cat}
                  onClick={() => setActiveCategory(cat)}
                  className={`px-3 py-1 rounded-xl text-xs font-semibold whitespace-nowrap transition border ${
                    activeCategory === cat
                      ? 'bg-cyan-400 text-slate-950 font-bold border-cyan-400'
                      : 'bg-[#0d1326] text-slate-400 border-slate-800 hover:text-white'
                  }`}
                >
                  {cat.toUpperCase()}
                </button>
              ))}
            </div>

            {/* Bookshelf Grid of 3D Books */}
            <div className="flex-1 overflow-y-auto p-2 pt-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3.5">
              {filteredBooks.map((book) => {
                const isCurrent = selectedBook?.id === book.id;
                return (
                  <div
                    key={book.id}
                    onClick={() => handleLaunchBook(book)}
                    className={`relative group cursor-pointer p-3.5 rounded-2xl border transition-all duration-200 transform hover:-translate-y-1 hover:shadow-xl ${
                      isCurrent
                        ? 'bg-cyan-500/15 border-cyan-400 text-cyan-300 ring-2 ring-cyan-500/30'
                        : 'bg-[#0a0f24] border-slate-800 hover:border-slate-600'
                    }`}
                    style={{
                      borderLeftWidth: '5px',
                      borderLeftColor: book.spineColor,
                    }}
                  >
                    {/* Top Spine & Icon */}
                    <div className="flex items-center justify-between mb-2">
                      <div className="p-2 rounded-xl bg-slate-900/80 border border-slate-800">
                        {renderBookIcon(book.icon)}
                      </div>
                      <span className="text-[10px] font-mono text-slate-400 uppercase tracking-wider">
                        {book.category}
                      </span>
                    </div>

                    {/* Book & App Titles */}
                    <div className="text-xs font-bold text-white group-hover:text-cyan-300 transition line-clamp-1">
                      {book.bookTitle}
                    </div>
                    <div className="text-[11px] text-cyan-400 font-mono mt-0.5 truncate">
                      {book.appName}
                    </div>

                    <div className="text-[10px] text-slate-400 mt-1 line-clamp-2">
                      {book.description}
                    </div>

                    {/* Launch Indicator */}
                    <div className="mt-3 pt-2 border-t border-slate-800/80 flex items-center justify-between text-[10px] font-mono text-slate-500 group-hover:text-cyan-300">
                      <span>INTENT EXEC</span>
                      <ChevronRight className="w-3.5 h-3.5 transform group-hover:translate-x-1 transition" />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Bottom Voice Push-to-Talk & Natural Language Orchestrator Bar */}
        <div className="w-full max-w-xl mx-auto z-20 space-y-2">
          {/* Quick Voice Intent Suggestions */}
          <div className="flex items-center space-x-2 overflow-x-auto no-scrollbar py-1 text-[11px]">
            <span className="text-[10px] font-mono text-slate-400 uppercase shrink-0 flex items-center gap-1">
              <Zap className="w-3 h-3 text-cyan-400" /> Try:
            </span>
            {[
              'Vyshu, open YouTube',
              'Vyshu, play music',
              'Vyshu, open my photos',
              'Vyshu, open WhatsApp',
              'Vyshu, show my books',
            ].map((sug, i) => (
              <button
                key={i}
                onClick={() => handleProcessIntent(sug)}
                className="px-2.5 py-1 rounded-xl bg-[#0c1228] border border-cyan-500/20 text-cyan-300 whitespace-nowrap hover:bg-cyan-500/10 transition active:scale-95"
              >
                &ldquo;{sug}&rdquo;
              </button>
            ))}
          </div>

          {/* Voice Mic & Text Command Bar */}
          <form onSubmit={handleInputSubmit} className="flex items-center space-x-2">
            <button
              type="button"
              onClick={handleStartListening}
              className={`p-3.5 rounded-2xl flex items-center justify-center transition shadow-lg shrink-0 ${
                isListening
                  ? 'bg-red-500 text-white animate-pulse shadow-red-500/40 ring-4 ring-red-500/20'
                  : 'bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 shadow-cyan-500/30'
              }`}
              title="Speak to Vyshu (Primary Android Interface)"
            >
              {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
            </button>

            <input
              type="text"
              value={customInput}
              onChange={(e) => setCustomInput(e.target.value)}
              placeholder={
                mode === 'HOME'
                  ? 'Speak or type: "Vyshu, open YouTube", "Play music", "Call mom"...'
                  : 'Direct Vyshu to open an Android capability or execute action...'
              }
              className="flex-1 bg-[#090e24] border border-cyan-500/35 rounded-2xl px-4 py-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-cyan-400 glow-cyan"
            />

            <button
              type="submit"
              className="p-3 rounded-2xl bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 hover:bg-cyan-500/30 transition shrink-0"
              title="Execute Intent"
            >
              <Zap className="w-4 h-4" />
            </button>
          </form>
        </div>
      </div>

      {/* Add Custom Installed App Modal */}
      {showAddAppModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#080d22] border border-cyan-500/30 rounded-3xl max-w-md w-full p-5 shadow-2xl glow-cyan animate-fade-in space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div className="flex items-center space-x-2">
                <Smartphone className="w-5 h-5 text-cyan-400" />
                <span className="font-extrabold text-sm text-white">Index New Android App</span>
              </div>
              <button
                onClick={() => setShowAddAppModal(false)}
                className="text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleAddCustomApp} className="space-y-3">
              <div>
                <label className="text-[11px] font-semibold text-slate-400 uppercase">App Name</label>
                <input
                  type="text"
                  required
                  value={newAppName}
                  onChange={(e) => setNewAppName(e.target.value)}
                  placeholder="e.g. Netflix, Telegram, Discord"
                  className="w-full mt-1 bg-[#0e1633] border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div>
                <label className="text-[11px] font-semibold text-slate-400 uppercase">Android Package Name</label>
                <input
                  type="text"
                  required
                  value={newPackageName}
                  onChange={(e) => setNewPackageName(e.target.value)}
                  placeholder="e.g. com.netflix.mediaclient"
                  className="w-full mt-1 bg-[#0e1633] border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-400 font-mono"
                />
              </div>

              <div>
                <label className="text-[11px] font-semibold text-slate-400 uppercase">Library Category</label>
                <select
                  value={newAppCategory}
                  onChange={(e) => setNewAppCategory(e.target.value as LibraryCategory)}
                  className="w-full mt-1 bg-[#0e1633] border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-400"
                >
                  <option value="entertainment">Entertainment</option>
                  <option value="music">Music</option>
                  <option value="communication">Communication</option>
                  <option value="memories">Memories / Photos</option>
                  <option value="knowledge">Knowledge / Browser</option>
                  <option value="planning">Planning / Calendar</option>
                  <option value="camera">Camera</option>
                  <option value="navigation">Navigation</option>
                  <option value="study_work">Study &amp; Work</option>
                  <option value="system">System</option>
                </select>
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddAppModal(false)}
                  className="px-3 py-2 rounded-xl bg-slate-800 text-slate-300 text-xs font-semibold hover:bg-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-cyan-400 text-slate-950 text-xs font-bold hover:bg-cyan-300 glow-cyan"
                >
                  Save as Library Book
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
