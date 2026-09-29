import React, { useState, useEffect } from 'react';
import {
  Wifi,
  Flashlight,
  WifiOff,
  Radio,
  Volume2,
  VolumeX,
  Sun,
  Moon,
  Music,
  Video,
  Globe,
  Camera,
  MessageCircle,
  Phone,
  Calculator,
  Compass,
  Sliders,
  CheckCircle2,
  AlertTriangle,
  Bot,
  RefreshCw,
  ExternalLink,
  Power,
} from 'lucide-react';
import { storageService } from '../services/storageService';
import { VyshuDiscordControl } from '../services/discordControl';
import { DeviceStatus } from '../types';
import { audioService } from '../services/audioService';

export const ControlScreen: React.FC = () => {
  const [device, setDevice] = useState<DeviceStatus>(storageService.getDeviceStatus());
  const [screenTorchActive, setScreenTorchActive] = useState(false);
  const [activeMediaStream, setActiveMediaStream] = useState<MediaStream | null>(null);

  // Discord Bot state
  const vault = storageService.getVaultKeys();
  const [discordHost, setDiscordHost] = useState(vault.discord_bot_url || 'http://localhost:8080');
  const [discordStatus, setDiscordStatus] = useState<{
    online: boolean;
    botTag?: string;
    servers: Array<{ id: string; name: string; mode: 'translate' | 'personal' | 'off'; members?: number }>;
  } | null>(null);
  const [isDiscordLoading, setIsDiscordLoading] = useState(false);
  const [discordMsg, setDiscordMsg] = useState('');

  useEffect(() => {
    storageService.saveDeviceStatus(device);
  }, [device]);

  // Torch control with MediaStream track or screen torch fallback
  const handleToggleTorch = async () => {
    audioService.playSound('toggle');
    const newState = !device.torch;

    if (newState) {
      try {
        // Try real camera torch if browser supports it
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
          const stream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: 'environment' },
          });
          const track = stream.getVideoTracks()[0];
          const capabilities = (track.getCapabilities && (track.getCapabilities() as any)) || {};
          if (capabilities.torch) {
            await (track as any).applyConstraints({ advanced: [{ torch: true }] });
            setActiveMediaStream(stream);
          } else {
            // Flash screen torch
            setScreenTorchActive(true);
          }
        } else {
          setScreenTorchActive(true);
        }
      } catch {
        // Fallback to screen torch
        setScreenTorchActive(true);
      }
    } else {
      if (activeMediaStream) {
        activeMediaStream.getTracks().forEach((t) => t.stop());
        setActiveMediaStream(null);
      }
      setScreenTorchActive(false);
    }

    setDevice((prev) => ({ ...prev, torch: newState }));
  };

  const toggleWifi = () => {
    audioService.playSound('toggle');
    setDevice((prev) => ({ ...prev, wifi: !prev.wifi }));
  };

  const toggleHotspot = () => {
    audioService.playSound('toggle');
    setDevice((prev) => ({ ...prev, hotspot: !prev.hotspot }));
  };

  const toggleBluetooth = () => {
    audioService.playSound('toggle');
    setDevice((prev) => ({ ...prev, bluetooth: !prev.bluetooth }));
  };

  const handleVolumeChange = (newVal: number) => {
    setDevice((prev) => ({ ...prev, volume: newVal }));
  };

  const handleBrightnessChange = (newVal: number) => {
    setDevice((prev) => ({ ...prev, brightness: newVal }));
  };

  // Launch external apps / web apps
  const handleOpenApp = (url: string, name: string) => {
    audioService.playSound('click');
    window.open(url, '_blank');
  };

  // Fetch Discord Bot Status
  const handleCheckDiscord = async () => {
    setIsDiscordLoading(true);
    setDiscordMsg('');
    const control = new VyshuDiscordControl(discordHost, vault.discord_token);
    const status = await control.getStatus();
    setDiscordStatus(status);
    setIsDiscordLoading(false);
  };

  const handleSetDiscordMode = async (guildId: string, mode: 'translate' | 'personal' | 'off') => {
    const control = new VyshuDiscordControl(discordHost, vault.discord_token);
    const res = await control.setMode(guildId, mode);
    setDiscordMsg(res.message);
    if (discordStatus) {
      setDiscordStatus({
        ...discordStatus,
        servers: discordStatus.servers.map((s) => (s.id === guildId ? { ...s, mode } : s)),
      });
    }
  };

  return (
    <div className="flex-1 bg-[#05050f] text-slate-100 overflow-y-auto pb-24 p-5 max-w-2xl mx-auto space-y-6">
      {/* Fullscreen Torch Light overlay if active */}
      {screenTorchActive && (
        <div
          onClick={handleToggleTorch}
          className="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center cursor-pointer select-none"
        >
          <div className="text-black text-center p-6 space-y-2">
            <Flashlight className="w-16 h-16 text-black mx-auto animate-pulse" />
            <h2 className="text-2xl font-black tracking-wide">TORCH ACTIVE</h2>
            <p className="text-sm font-medium text-slate-700">Screen maximum brightness torch. Tap anywhere to turn off.</p>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between pt-2">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center glow-cyan">
            <Sliders className="w-5 h-5 text-cyan-400" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white flex items-center gap-2">
              CONTROL PANEL
            </h1>
            <p className="text-xs text-slate-400">Mobile accessories &amp; automation bridge</p>
          </div>
        </div>

        <div className="flex items-center gap-1.5 text-xs font-mono text-cyan-400 bg-cyan-500/10 border border-cyan-500/20 px-3 py-1.5 rounded-full">
          <CheckCircle2 className="w-3.5 h-3.5" /> Bridge Active
        </div>
      </div>

      {/* Mobile Accessories Section */}
      <div className="space-y-3">
        <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
          Mobile Accessories
        </h2>

        <div className="grid grid-cols-3 gap-3">
          {/* WiFi */}
          <button
            onClick={toggleWifi}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.wifi
                ? 'bg-[#0e1422] border-cyan-400 text-cyan-400 shadow-md shadow-cyan-500/10'
                : 'bg-[#0b0b16] border-slate-800 text-slate-500'
            }`}
          >
            <Wifi className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Wi-Fi</span>
            <span className={`text-[10px] font-mono font-bold tracking-wider ${device.wifi ? 'text-cyan-400' : 'text-slate-500'}`}>
              {device.wifi ? 'ON' : 'OFF'}
            </span>
          </button>

          {/* Torch */}
          <button
            onClick={handleToggleTorch}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.torch
                ? 'bg-amber-500/10 border-amber-400 text-amber-300 shadow-md shadow-amber-500/20'
                : 'bg-[#0b0b16] border-slate-800 text-slate-500'
            }`}
          >
            <Flashlight className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Torch</span>
            <span className={`text-[10px] font-mono font-bold tracking-wider ${device.torch ? 'text-amber-400' : 'text-slate-500'}`}>
              {device.torch ? 'ON' : 'OFF'}
            </span>
          </button>

          {/* Hotspot */}
          <button
            onClick={toggleHotspot}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.hotspot
                ? 'bg-[#0e1422] border-cyan-400 text-cyan-400 shadow-md shadow-cyan-500/10'
                : 'bg-[#0b0b16] border-slate-800 text-slate-500'
            }`}
          >
            <Radio className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Hotspot</span>
            <span className={`text-[10px] font-mono font-bold tracking-wider ${device.hotspot ? 'text-cyan-400' : 'text-slate-500'}`}>
              {device.hotspot ? 'ON' : 'OFF'}
            </span>
          </button>

          {/* Bluetooth */}
          <button
            onClick={toggleBluetooth}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.bluetooth
                ? 'bg-[#0e1422] border-indigo-400 text-indigo-400 shadow-md shadow-indigo-500/10'
                : 'bg-[#0b0b16] border-slate-800 text-slate-500'
            }`}
          >
            <Radio className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Bluetooth</span>
            <span className={`text-[10px] font-mono font-bold tracking-wider ${device.bluetooth ? 'text-indigo-400' : 'text-slate-500'}`}>
              {device.bluetooth ? 'ON' : 'OFF'}
            </span>
          </button>

          {/* Vol Max Toggle */}
          <button
            onClick={() => handleVolumeChange(device.volume >= 14 ? 5 : 15)}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.volume >= 14
                ? 'bg-[#0e1422] border-cyan-400 text-cyan-400 shadow-md shadow-cyan-500/10'
                : 'bg-[#0b0b16] border-slate-800 text-slate-400'
            }`}
          >
            <Volume2 className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Volume</span>
            <span className="text-[10px] font-mono font-bold text-cyan-400">
              {device.volume}/15
            </span>
          </button>

          {/* Brightness Quick Toggle */}
          <button
            onClick={() => handleBrightnessChange(device.brightness >= 240 ? 60 : 255)}
            className={`p-4 rounded-2xl border transition flex flex-col items-center justify-center space-y-2 ${
              device.brightness >= 240
                ? 'bg-[#0e1422] border-amber-400 text-amber-300 shadow-md shadow-amber-500/10'
                : 'bg-[#0b0b16] border-slate-800 text-slate-400'
            }`}
          >
            <Sun className="w-6 h-6" />
            <span className="text-xs font-semibold text-slate-200">Brightness</span>
            <span className="text-[10px] font-mono font-bold text-amber-400">
              {Math.round((device.brightness / 255) * 100)}%
            </span>
          </button>
        </div>

        {/* Sliders for Volume and Brightness fine adjustment */}
        <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-4 space-y-4">
          <div>
            <div className="flex items-center justify-between text-xs mb-1.5">
              <span className="font-medium text-slate-300 flex items-center gap-1.5">
                <Volume2 className="w-3.5 h-3.5 text-cyan-400" /> Media Volume Level
              </span>
              <span className="font-mono text-cyan-400 font-bold">{device.volume} / 15</span>
            </div>
            <input
              type="range"
              min={0}
              max={15}
              value={device.volume}
              onChange={(e) => handleVolumeChange(Number(e.target.value))}
              className="w-full h-1.5 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-cyan-400"
            />
          </div>

          <div>
            <div className="flex items-center justify-between text-xs mb-1.5">
              <span className="font-medium text-slate-300 flex items-center gap-1.5">
                <Sun className="w-3.5 h-3.5 text-amber-400" /> Screen Brightness
              </span>
              <span className="font-mono text-amber-400 font-bold">{Math.round((device.brightness / 255) * 100)}%</span>
            </div>
            <input
              type="range"
              min={10}
              max={255}
              value={device.brightness}
              onChange={(e) => handleBrightnessChange(Number(e.target.value))}
              className="w-full h-1.5 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-amber-400"
            />
          </div>
        </div>
      </div>

      {/* Open Apps Section (YouTube, Spotify, WhatsApp, Discord, Camera, Maps, etc.) */}
      <div className="space-y-3 pt-2">
        <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
          Open Apps &amp; Automation
        </h2>

        <div className="grid grid-cols-4 gap-2.5">
          <button
            onClick={() => handleOpenApp('https://www.youtube.com', 'YouTube')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Video className="w-5 h-5 text-red-500" />
            <span className="text-[11px] font-medium text-slate-300">YouTube</span>
          </button>

          <button
            onClick={() => handleOpenApp('https://open.spotify.com', 'Spotify')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Music className="w-5 h-5 text-emerald-400" />
            <span className="text-[11px] font-medium text-slate-300">Spotify</span>
          </button>

          <button
            onClick={() => handleOpenApp('https://web.whatsapp.com', 'WhatsApp')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <MessageCircle className="w-5 h-5 text-emerald-500" />
            <span className="text-[11px] font-medium text-slate-300">WhatsApp</span>
          </button>

          <button
            onClick={() => handleOpenApp('https://discord.com/app', 'Discord')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Bot className="w-5 h-5 text-indigo-400" />
            <span className="text-[11px] font-medium text-slate-300">Discord</span>
          </button>

          <button
            onClick={() => handleOpenApp('https://www.google.com', 'Chrome')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Globe className="w-5 h-5 text-cyan-400" />
            <span className="text-[11px] font-medium text-slate-300">Browser</span>
          </button>

          <button
            onClick={() => handleOpenApp('https://maps.google.com', 'Maps')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Compass className="w-5 h-5 text-blue-400" />
            <span className="text-[11px] font-medium text-slate-300">Maps</span>
          </button>

          <button
            onClick={() => handleOpenApp('tel:', 'Phone')}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Phone className="w-5 h-5 text-emerald-400" />
            <span className="text-[11px] font-medium text-slate-300">Dialer</span>
          </button>

          <button
            onClick={() => handleToggleTorch()}
            className="p-3 bg-[#0e1422] hover:bg-slate-800/80 border border-slate-800 rounded-xl flex flex-col items-center justify-center space-y-1.5 transition active:scale-95"
          >
            <Camera className="w-5 h-5 text-amber-400" />
            <span className="text-[11px] font-medium text-slate-300">Camera</span>
          </button>
        </div>
      </div>

      {/* Discord Bot Master Control Section (Ported from vyshu_discord_control.dart) */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Bot className="w-4 h-4" />
            <span>Discord Bot Remote Control</span>
          </h2>
          <button
            onClick={handleCheckDiscord}
            disabled={isDiscordLoading}
            className="text-[11px] px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 flex items-center gap-1 transition"
          >
            <RefreshCw className={`w-3 h-3 ${isDiscordLoading ? 'animate-spin' : ''}`} />
            Check Bot
          </button>
        </div>

        <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-4 space-y-3">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={discordHost}
              onChange={(e) => setDiscordHost(e.target.value)}
              placeholder="Bot Base URL (e.g. http://123.45.67.89:8080)"
              className="flex-1 bg-[#0e1422] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 placeholder-slate-600 font-mono focus:outline-none focus:border-cyan-400"
            />
            <button
              onClick={handleCheckDiscord}
              className="px-3 py-2 rounded-xl bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 text-xs font-semibold hover:bg-cyan-500/30 transition shrink-0"
            >
              Ping Bot
            </button>
          </div>

          {discordMsg && (
            <div className="p-2.5 rounded-lg bg-cyan-500/10 border border-cyan-500/20 text-xs text-cyan-300">
              {discordMsg}
            </div>
          )}

          {discordStatus && (
            <div className="space-y-2 pt-2 border-t border-slate-800/80">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Bot Tag:</span>
                <span className="font-mono text-cyan-400 font-semibold">{discordStatus.botTag}</span>
              </div>
              <div className="text-xs font-semibold text-slate-300 pt-1">Managed Servers:</div>
              <div className="space-y-2">
                {discordStatus.servers.map((srv) => (
                  <div
                    key={srv.id}
                    className="p-3 bg-[#0e1422] rounded-xl border border-slate-800 flex items-center justify-between"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-100">{srv.name}</div>
                      <div className="text-[10px] text-slate-400">
                        ID: {srv.id} • Mode: <span className="text-cyan-400 font-mono">{srv.mode}</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-1.5">
                      {(['translate', 'personal', 'off'] as const).map((m) => (
                        <button
                          key={m}
                          onClick={() => handleSetDiscordMode(srv.id, m)}
                          className={`text-[10px] px-2 py-1 rounded font-mono capitalize transition ${
                            srv.mode === m
                              ? 'bg-cyan-500 text-slate-950 font-bold'
                              : 'bg-slate-800 text-slate-400 hover:text-white'
                          }`}
                        >
                          {m}
                        </button>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
