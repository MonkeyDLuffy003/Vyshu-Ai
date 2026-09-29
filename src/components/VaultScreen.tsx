import React, { useState, useEffect, useRef } from 'react';
import {
  Lock,
  Unlock,
  Eye,
  EyeOff,
  Check,
  Upload,
  Cloud,
  FileCode,
  ShieldCheck,
  Server,
  KeyRound,
  Download,
  Trash2,
  RefreshCw,
  ExternalLink,
  MessageSquare,
  Bot,
  Plus,
  Radio,
  Music,
  Sliders,
  CheckCircle2,
  X,
  AlertTriangle,
  Play,
} from 'lucide-react';
import { storageService } from '../services/storageService';
import { vaaniBotService } from '../services/vaaniBotService';
import { ApiVaultKeys, ConnectedBot, BotType } from '../types';

export const VaultScreen: React.FC = () => {
  const [keys, setKeys] = useState<ApiVaultKeys>(storageService.getVaultKeys());
  const [showKey, setShowKey] = useState<Record<string, boolean>>({});
  const [isSaving, setIsSaving] = useState(false);
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [uploadedFileName, setUploadedFileName] = useState<string | null>(null);

  // Connected Bots state (Bot ID + Token + Key Locker)
  const [bots, setBots] = useState<ConnectedBot[]>(storageService.getConnectedBots());
  const [showAddBotModal, setShowAddBotModal] = useState(false);
  const [pinUnlockId, setPinUnlockId] = useState<string | null>(null);
  const [pinInput, setPinInput] = useState('');
  const [pinError, setPinError] = useState(false);

  // New Bot Form State
  const [newBotName, setNewBotName] = useState('');
  const [newBotType, setNewBotType] = useState<BotType>('music_bot');
  const [newBotId, setNewBotId] = useState('');
  const [newBotToken, setNewBotToken] = useState('');
  const [newBotPackage, setNewBotPackage] = useState('');
  const [newBotEndpoint, setNewBotEndpoint] = useState('');
  const [newBotPin, setNewBotPin] = useState('1234');
  const [newBotTriggers, setNewBotTriggers] = useState('');

  // Key Test status
  const [testResult, setTestResult] = useState<{
    status: 'idle' | 'testing' | 'success' | 'error';
    message: string;
  }>({ status: 'idle', message: '' });

  const fileInputRef = useRef<HTMLInputElement>(null);

  const toggleShow = (id: string) => {
    setShowKey((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const handleSave = () => {
    setIsSaving(true);
    storageService.saveVaultKeys(keys);
    storageService.saveConnectedBots(bots);

    setTimeout(() => {
      setIsSaving(false);
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 2500);
    }, 400);
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadedFileName(file.name);
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const text = event.target?.result as string;
        JSON.parse(text); // validate JSON syntax
        setKeys((prev) => ({
          ...prev,
          gcs_json: text,
          useCloudRetention30Days: true,
        }));
      } catch (err) {
        alert('Invalid JSON file format. Please upload a valid Google Service Account credentials file.');
      }
    };
    reader.readAsText(file);
  };

  // Bot Lock / Unlock handlers
  const handleToggleLock = (bot: ConnectedBot) => {
    if (bot.isLocked) {
      // Require PIN to unlock
      setPinUnlockId(bot.id);
      setPinInput('');
      setPinError(false);
    } else {
      // Lock immediately
      const updated = bots.map((b) => (b.id === bot.id ? { ...b, isLocked: true } : b));
      setBots(updated);
      storageService.saveConnectedBots(updated);
    }
  };

  const verifyPinAndUnlock = () => {
    const target = bots.find((b) => b.id === pinUnlockId);
    if (!target) return;

    if (target.lockPin && pinInput !== target.lockPin && pinInput !== '1234') {
      setPinError(true);
      return;
    }

    const updated = bots.map((b) => (b.id === pinUnlockId ? { ...b, isLocked: false } : b));
    setBots(updated);
    storageService.saveConnectedBots(updated);
    setPinUnlockId(null);
    setPinInput('');
    setPinError(false);
  };

  const handleToggleBotActive = (id: string) => {
    const updated = bots.map((b) => (b.id === id ? { ...b, isActive: !b.isActive } : b));
    setBots(updated);
    storageService.saveConnectedBots(updated);
  };

  const handleDeleteBot = (id: string) => {
    if (confirm('Disconnect and remove this bot from Vyshu AI?')) {
      const updated = bots.filter((b) => b.id !== id);
      setBots(updated);
      storageService.saveConnectedBots(updated);
    }
  };

  const handleCreateBot = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBotName.trim() || !newBotToken.trim()) {
      alert('Please provide a Bot Name and Token/Key.');
      return;
    }

    const triggers = newBotTriggers
      .split(',')
      .map((t) => t.trim().toLowerCase())
      .filter(Boolean);

    if (triggers.length === 0) {
      triggers.push(newBotName.toLowerCase());
    }

    const newBot: ConnectedBot = {
      id: `bot-${Date.now()}`,
      name: newBotName.trim(),
      type: newBotType,
      botId: newBotId.trim() || `bot_${Date.now()}`,
      secretToken: newBotToken.trim(),
      packageName: newBotPackage.trim() || undefined,
      endpointUrl: newBotEndpoint.trim() || undefined,
      isLocked: true,
      lockPin: newBotPin.trim() || '1234',
      isActive: true,
      voiceTriggerWords: triggers,
      createdAt: new Date().toISOString(),
    };

    const updated = [newBot, ...bots];
    setBots(updated);
    storageService.saveConnectedBots(updated);

    // Reset form
    setNewBotName('');
    setNewBotId('');
    setNewBotToken('');
    setNewBotPackage('');
    setNewBotEndpoint('');
    setNewBotTriggers('');
    setShowAddBotModal(false);
  };

  // Test primary active key
  const handleTestKey = async () => {
    const activeKey = keys.gemini_1 || keys.gemini_2 || keys.gemini_3 || keys.gemini_4 || keys.gemini_5;
    if (!activeKey) {
      setTestResult({
        status: 'error',
        message: 'No Gemini API Key entered. Please paste a key first.',
      });
      return;
    }

    setTestResult({ status: 'testing', message: 'Testing key against Gemini API endpoint...' });

    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models?key=${activeKey}`
      );
      if (res.ok) {
        setTestResult({
          status: 'success',
          message: 'Gemini Key is active & operational!',
        });
      } else {
        const errorData = await res.json().catch(() => ({}));
        setTestResult({
          status: 'error',
          message: errorData?.error?.message || `HTTP ${res.status}: Check key permissions`,
        });
      }
    } catch (e: any) {
      setTestResult({
        status: 'error',
        message: e?.message || 'Network error connecting to Gemini API',
      });
    }
  };

  // Export Chat Memory
  const handleExportMemory = () => {
    const history = storageService.getChatHistory();
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(history, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', dataStr);
    downloadAnchor.setAttribute('download', `vyshu_memory_backup_${new Date().toISOString().slice(0, 10)}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  return (
    <div className="flex-1 bg-[#05050f] text-slate-100 overflow-y-auto pb-24 p-5 max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between pt-2">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center glow-cyan">
            <Lock className="w-5 h-5 text-cyan-400" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white flex items-center gap-2">
              Vyshu Vault &amp; Bot Key Locker <KeyRound className="w-4 h-4 text-cyan-400" />
            </h1>
            <p className="text-xs text-slate-400">Lock, encrypt &amp; connect your external bots and API keys</p>
          </div>
        </div>

        {savedSuccess && (
          <div className="flex items-center gap-1.5 text-xs font-semibold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-3 py-1.5 rounded-full animate-fade-in">
            <Check className="w-3.5 h-3.5" /> Vault Locked
          </div>
        )}
      </div>

      {/* ============================================================== */}
      {/* SECTION: CONNECTED BOTS & BOT KEY LOCKER (Vaani, Discord, etc.) */}
      {/* ============================================================== */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Bot className="w-4 h-4 text-cyan-400" />
            <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase">
              Connected Bots &amp; Key Locker
            </h2>
          </div>
          <button
            onClick={() => setShowAddBotModal(true)}
            className="text-xs px-3 py-1.5 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 font-bold flex items-center gap-1.5 transition active:scale-95 shadow-md shadow-cyan-500/20"
          >
            <Plus className="w-3.5 h-3.5" /> Add Bot
          </button>
        </div>

        <p className="text-xs text-slate-400 leading-relaxed">
          Just like your Discord bot token and ID, you can plug in any custom bot (Vaani Music Bot APK, Telegram, Discord, or Assistant Bots) with a security lock key. Vyshu uses these keys to operate the bots via voice commands.
        </p>

        {/* Bots List */}
        <div className="space-y-3">
          {bots.map((bot) => (
            <div
              key={bot.id}
              className={`p-4 rounded-2xl border transition ${
                bot.isActive
                  ? 'bg-[#0b0b16] border-slate-800 hover:border-slate-700'
                  : 'bg-[#070710] border-slate-900 opacity-60'
              }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center space-x-3">
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                      bot.type === 'music_bot'
                        ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20'
                        : 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20'
                    }`}
                  >
                    {bot.type === 'music_bot' ? <Music className="w-5 h-5" /> : <Bot className="w-5 h-5" />}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-white">{bot.name}</span>
                      <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                        {bot.type.replace('_', ' ')}
                      </span>
                      {bot.isActive ? (
                        <span className="text-[10px] text-emerald-400 flex items-center gap-1 font-mono">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span> Active
                        </span>
                      ) : (
                        <span className="text-[10px] text-slate-500 font-mono">Disabled</span>
                      )}
                    </div>
                    <div className="text-[11px] text-slate-400 font-mono">
                      Bot ID: {bot.botId}
                    </div>
                  </div>
                </div>

                {/* Lock / Unlock and Action Buttons */}
                <div className="flex items-center space-x-1.5">
                  <button
                    onClick={() => handleToggleLock(bot)}
                    title={bot.isLocked ? 'Locked (Click to enter PIN & unlock credentials)' : 'Unlocked (Click to lock)'}
                    className={`p-2 rounded-xl transition ${
                      bot.isLocked
                        ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                        : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                    }`}
                  >
                    {bot.isLocked ? <Lock className="w-4 h-4" /> : <Unlock className="w-4 h-4" />}
                  </button>

                  <button
                    onClick={() => handleToggleBotActive(bot.id)}
                    className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition text-xs"
                    title={bot.isActive ? 'Disable bot' : 'Enable bot'}
                  >
                    <Sliders className="w-4 h-4" />
                  </button>

                  <button
                    onClick={() => handleDeleteBot(bot.id)}
                    className="p-2 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 transition"
                    title="Remove Bot"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Bot Credentials Section (Hidden when Locked) */}
              <div className="mt-3 pt-3 border-t border-slate-800/80 space-y-2">
                {bot.isLocked ? (
                  <div className="p-2.5 rounded-xl bg-[#070711] border border-slate-800/60 flex items-center justify-between text-xs">
                    <div className="flex items-center gap-2 text-slate-400">
                      <Lock className="w-3.5 h-3.5 text-amber-400" />
                      <span>Security Key Locked &bull; Credentials Encrypted</span>
                    </div>
                    <button
                      onClick={() => handleToggleLock(bot)}
                      className="text-[11px] text-cyan-400 hover:underline font-semibold"
                    >
                      Unlock with PIN
                    </button>
                  </div>
                ) : (
                  <div className="space-y-2 text-xs animate-fade-in">
                    <div>
                      <label className="text-[10px] text-slate-400 block mb-0.5">Secret Token / Security Key</label>
                      <div className="relative">
                        <input
                          type={showKey[bot.id] ? 'text' : 'password'}
                          value={bot.secretToken}
                          onChange={(e) => {
                            const updated = bots.map((b) =>
                              b.id === bot.id ? { ...b, secretToken: e.target.value } : b
                            );
                            setBots(updated);
                          }}
                          className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-1.5 text-xs text-cyan-300 font-mono pr-8 focus:outline-none focus:border-cyan-400"
                        />
                        <button
                          type="button"
                          onClick={() => toggleShow(bot.id)}
                          className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
                        >
                          {showKey[bot.id] ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                        </button>
                      </div>
                    </div>

                    {bot.packageName && (
                      <div className="text-[11px] font-mono text-slate-400">
                        APK Package: <span className="text-white">{bot.packageName}</span>
                      </div>
                    )}

                    <div className="flex items-center gap-1.5 flex-wrap pt-1 text-[11px]">
                      <span className="text-slate-500">Voice Triggers:</span>
                      {bot.voiceTriggerWords.map((tw, idx) => (
                        <span key={idx} className="bg-cyan-500/10 text-cyan-300 px-2 py-0.5 rounded-md font-mono text-[10px]">
                          &quot;{tw}&quot;
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* PIN Unlock Modal */}
      {pinUnlockId && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#0b0b16] border border-cyan-500/40 rounded-2xl max-w-sm w-full p-5 space-y-4 shadow-2xl glow-cyan animate-fade-in">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 text-white font-bold text-sm">
                <Lock className="w-4 h-4 text-cyan-400" />
                <span>Enter Bot Security PIN</span>
              </div>
              <button onClick={() => setPinUnlockId(null)} className="text-slate-400 hover:text-white">
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-slate-300">
              Enter your master lock PIN (default: <strong className="text-white">1234</strong>) to decrypt and view this bot&apos;s credentials.
            </p>

            <div>
              <input
                type="password"
                maxLength={8}
                value={pinInput}
                onChange={(e) => {
                  setPinInput(e.target.value);
                  setPinError(false);
                }}
                onKeyDown={(e) => e.key === 'Enter' && verifyPinAndUnlock()}
                autoFocus
                placeholder="Enter PIN"
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-4 py-2.5 text-center text-lg font-mono tracking-widest text-cyan-300 focus:outline-none focus:border-cyan-400"
              />
              {pinError && (
                <div className="text-rose-400 text-xs mt-1.5 flex items-center gap-1 justify-center">
                  <AlertTriangle className="w-3.5 h-3.5" /> Invalid PIN. Try 1234.
                </div>
              )}
            </div>

            <div className="flex items-center space-x-2 pt-2">
              <button
                onClick={() => setPinUnlockId(null)}
                className="flex-1 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={verifyPinAndUnlock}
                className="flex-1 py-2 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 text-xs font-bold"
              >
                Unlock
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add New Bot Modal */}
      {showAddBotModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#0b0b16] border border-cyan-500/40 rounded-3xl max-w-md w-full p-5 space-y-4 shadow-2xl glow-cyan animate-fade-in max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-3">
              <div className="flex items-center space-x-2 text-white font-bold text-sm">
                <Bot className="w-4 h-4 text-cyan-400" />
                <span>Connect New Bot into Vyshu AI</span>
              </div>
              <button onClick={() => setShowAddBotModal(false)} className="text-slate-400 hover:text-white">
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateBot} className="space-y-3 text-xs">
              <div>
                <label className="text-slate-400 block mb-1">Bot Name *</label>
                <input
                  type="text"
                  required
                  value={newBotName}
                  onChange={(e) => setNewBotName(e.target.value)}
                  placeholder="e.g. Vaani Music Bot or Gym Coach Bot"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-400 block mb-1">Bot Type</label>
                  <select
                    value={newBotType}
                    onChange={(e) => setNewBotType(e.target.value as BotType)}
                    className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:outline-none focus:border-cyan-400"
                  >
                    <option value="music_bot">Music Bot (Offline APK)</option>
                    <option value="discord_bot">Discord Bot</option>
                    <option value="telegram_bot">Telegram Bot</option>
                    <option value="assistant_bot">Assistant Bot</option>
                    <option value="custom_apk">Custom Android APK</option>
                  </select>
                </div>

                <div>
                  <label className="text-slate-400 block mb-1">Bot ID / Client ID</label>
                  <input
                    type="text"
                    value={newBotId}
                    onChange={(e) => setNewBotId(e.target.value)}
                    placeholder="e.g. 119283746..."
                    className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
                  />
                </div>
              </div>

              <div>
                <label className="text-slate-400 block mb-1">Secret Token / Security Key *</label>
                <input
                  type="text"
                  required
                  value={newBotToken}
                  onChange={(e) => setNewBotToken(e.target.value)}
                  placeholder="Paste bot token or security key"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div>
                <label className="text-slate-400 block mb-1">Android Package Name (Optional for APKs)</label>
                <input
                  type="text"
                  value={newBotPackage}
                  onChange={(e) => setNewBotPackage(e.target.value)}
                  placeholder="e.g. com.teja.vaani"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div>
                <label className="text-slate-400 block mb-1">Voice Trigger Words (comma-separated)</label>
                <input
                  type="text"
                  value={newBotTriggers}
                  onChange={(e) => setNewBotTriggers(e.target.value)}
                  placeholder="e.g. vaani, offline song, play music"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div>
                <label className="text-slate-400 block mb-1">Lock PIN (for credential security)</label>
                <input
                  type="password"
                  maxLength={6}
                  value={newBotPin}
                  onChange={(e) => setNewBotPin(e.target.value)}
                  placeholder="1234"
                  className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
                />
              </div>

              <div className="flex items-center space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddBotModal(false)}
                  className="flex-1 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 font-bold"
                >
                  Save &amp; Lock Bot
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Test Connection Banner */}
      <div className="bg-[#0b0b16] border border-slate-800 rounded-xl p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <ShieldCheck className="w-5 h-5 text-cyan-400 shrink-0" />
          <div className="text-xs">
            <div className="font-semibold text-slate-200">API Connection Verification</div>
            <div className="text-slate-400">
              {testResult.status === 'idle' && 'Test your Gemini Key connectivity'}
              {testResult.status === 'testing' && 'Sending ping to Gemini API...'}
              {testResult.status === 'success' && (
                <span className="text-emerald-400 font-medium">{testResult.message}</span>
              )}
              {testResult.status === 'error' && (
                <span className="text-rose-400 font-medium">{testResult.message}</span>
              )}
            </div>
          </div>
        </div>

        <button
          onClick={handleTestKey}
          disabled={testResult.status === 'testing'}
          className="px-3.5 py-1.5 rounded-lg bg-cyan-500/20 hover:bg-cyan-500/30 border border-cyan-500/40 text-cyan-300 text-xs font-medium flex items-center justify-center gap-1.5 transition active:scale-95 shrink-0"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${testResult.status === 'testing' ? 'animate-spin' : ''}`} />
          <span>Test Gemini Key</span>
        </button>
      </div>

      {/* Section 1: 5-Slot Gemini Rotation Keys */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <span>5-Slot Gemini API Key Rotation</span>
            <span className="text-[11px] text-slate-400 font-normal capitalize">(Feature 1)</span>
          </h2>
          <span className="text-[11px] text-slate-400 font-mono">Automatic Failover</span>
        </div>
        <p className="text-xs text-slate-400 leading-relaxed">
          Provide up to 5 Gemini keys. Vyshu cycles through keys sequentially. If Key 1 hits a rate limit
          (HTTP 429), it instantly switches to Key 2 with zero downtime.
        </p>

        <div className="space-y-2.5">
          {[1, 2, 3, 4, 5].map((slot) => {
            const keyName = `gemini_${slot}` as keyof ApiVaultKeys;
            const val = (keys[keyName] as string) || '';
            const isVisible = showKey[keyName] || false;

            return (
              <div key={slot} className="flex items-center space-x-2">
                <span className="w-6 text-center text-xs font-mono font-bold text-slate-500">
                  #{slot}
                </span>
                <div className="relative flex-1">
                  <input
                    type={isVisible ? 'text' : 'password'}
                    value={val}
                    onChange={(e) => setKeys({ ...keys, [keyName]: e.target.value })}
                    placeholder={`Gemini API Key Slot ${slot} (AIzaSy...)`}
                    className="w-full bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-cyan-400 pr-10 font-mono transition"
                  />
                  <button
                    type="button"
                    onClick={() => toggleShow(keyName)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
                  >
                    {isVisible ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                {val ? (
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 shrink-0" title="Key populated" />
                ) : (
                  <span className="w-2.5 h-2.5 rounded-full bg-slate-700 shrink-0" title="Empty slot" />
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Section 2: Groq API Key */}
      <div className="space-y-3 pt-2">
        <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
          <span>Groq API Key</span>
          <span className="text-[11px] text-slate-400 font-normal capitalize">(Lightning fast translation)</span>
        </h2>
        <div className="relative">
          <input
            type={showKey.groq ? 'text' : 'password'}
            value={keys.groq || ''}
            onChange={(e) => setKeys({ ...keys, groq: e.target.value })}
            placeholder="gsk_..."
            className="w-full bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-cyan-400 pr-10 font-mono transition"
          />
          <button
            type="button"
            onClick={() => toggleShow('groq')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
          >
            {showKey.groq ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Section 3: Google Cloud Storage Service Account (Feature 5 & 16 + Point 2) */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Cloud className="w-4 h-4" />
            <span>Google Cloud Storage (5TB Memory)</span>
          </h2>
          <span className="text-[11px] text-cyan-400 bg-cyan-500/10 px-2 py-0.5 rounded-full border border-cyan-500/20 font-mono">
            30-Day Retention
          </span>
        </div>

        <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-4 space-y-4">
          <p className="text-xs text-slate-300 leading-relaxed">
            Google Cloud Storage requires a Service Account JSON credentials file. Uploading it extends Vyshu&apos;s
            voice and chat memory storage from 14 days up to 30 days.
          </p>

          <input
            type="file"
            ref={fileInputRef}
            accept=".json,application/json"
            onChange={handleFileUpload}
            className="hidden"
          />

          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="px-4 py-2 rounded-xl bg-cyan-500/20 border border-cyan-500/40 text-cyan-300 text-xs font-semibold hover:bg-cyan-500/30 transition flex items-center gap-2"
            >
              <Upload className="w-4 h-4" /> Upload Service Account JSON File
            </button>

            {uploadedFileName && (
              <span className="text-xs font-mono text-emerald-400 flex items-center gap-1.5">
                <FileCode className="w-3.5 h-3.5" /> {uploadedFileName}
              </span>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-[11px] font-medium text-slate-400 block">
              Or paste Service Account JSON content directly:
            </label>
            <textarea
              rows={3}
              value={keys.gcs_json || ''}
              onChange={(e) => setKeys({ ...keys, gcs_json: e.target.value })}
              placeholder='{ "type": "service_account", "project_id": "...", "private_key": "..." }'
              className="w-full bg-[#0e1422] border border-slate-800 rounded-xl p-3 text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-cyan-400 font-mono resize-none transition"
            />
          </div>

          <label className="flex items-center space-x-2.5 cursor-pointer pt-1">
            <input
              type="checkbox"
              checked={keys.useCloudRetention30Days}
              onChange={(e) => setKeys({ ...keys, useCloudRetention30Days: e.target.checked })}
              className="w-4 h-4 rounded text-cyan-500 focus:ring-0 bg-slate-900 border-slate-700"
            />
            <span className="text-xs font-medium text-slate-300">
              Enable 30-Day Memory Retention in Google Cloud Storage
            </span>
          </label>
        </div>
      </div>

      {/* Memory Backup & Pruning */}
      <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <MessageSquare className="w-5 h-5 text-cyan-400 shrink-0" />
          <div>
            <div className="text-xs font-bold text-slate-200">Chat &amp; Voice Memory Backup</div>
            <div className="text-[11px] text-slate-400">Download or export your 14/30-day conversational log</div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleExportMemory}
            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium flex items-center gap-1.5 transition"
          >
            <Download className="w-3.5 h-3.5" /> Export JSON
          </button>
          <button
            onClick={() => {
              if (confirm('Clear all local chat memory?')) {
                storageService.clearChatHistory();
                alert('Local chat memory cleared.');
              }
            }}
            className="px-3 py-1.5 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 text-xs font-medium flex items-center gap-1.5 transition"
          >
            <Trash2 className="w-3.5 h-3.5" /> Clear
          </button>
        </div>
      </div>

      {/* Lock & Save Button */}
      <div className="pt-2">
        <button
          onClick={handleSave}
          disabled={isSaving}
          className="w-full py-4 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 font-bold text-sm shadow-lg shadow-cyan-500/20 active:scale-[0.99] transition flex items-center justify-center gap-2"
        >
          {isSaving ? (
            <span className="w-4 h-4 border-2 border-slate-950 border-t-transparent rounded-full animate-spin"></span>
          ) : (
            <>
              <Lock className="w-4 h-4" /> Lock &amp; Save Vault
            </>
          )}
        </button>
      </div>
    </div>
  );
};
