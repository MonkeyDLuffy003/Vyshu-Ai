import React, { useState, useRef, useEffect } from 'react';
import {
  Music,
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Volume2,
  FolderPlus,
  Radio,
  Disc,
  Sparkles,
  ExternalLink,
  Bot,
  Shuffle,
  Repeat,
  Sliders,
  CheckCircle2,
} from 'lucide-react';
import { SongTrack } from '../../types';
import { vaaniBotService, VaaniBotConfig } from '../../services/vaaniBotService';
import { audioService } from '../../services/audioService';

export const MusicPlayer: React.FC = () => {
  const [tracks, setTracks] = useState<SongTrack[]>(vaaniBotService.getPlaylist());
  const [currentTrackIndex, setCurrentTrackIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [config, setConfig] = useState<VaaniBotConfig>(vaaniBotService.getConfig());
  const [showConfigModal, setShowConfigModal] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(210);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // Subscribe to central Vaani bot service state
  useEffect(() => {
    const unsubscribe = vaaniBotService.subscribe((state) => {
      setIsPlaying(state.isPlaying);
      setCurrentTrackIndex(state.index);
    });
    return () => unsubscribe();
  }, []);

  const currentTrack = tracks[currentTrackIndex] || tracks[0];

  const handlePlayPause = () => {
    audioService.playSound('toggle');
    if (isPlaying) {
      vaaniBotService.pause();
    } else {
      vaaniBotService.playTrack(currentTrackIndex);
    }
  };

  const handleNext = () => {
    audioService.playSound('click');
    vaaniBotService.next();
  };

  const handlePrev = () => {
    audioService.playSound('click');
    vaaniBotService.previous();
  };

  const handleSelectTrack = (idx: number) => {
    audioService.playSound('click');
    vaaniBotService.playTrack(idx);
  };

  // Upload local offline music files into Vaani
  const handleLocalMusicUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    const newTracks: SongTrack[] = [];
    Array.from(files).forEach((file, idx) => {
      const url = URL.createObjectURL(file);
      newTracks.push({
        id: `local-vaani-${Date.now()}-${idx}`,
        title: file.name.replace(/\.[^/.]+$/, ''),
        artist: 'Offline Phone Storage',
        duration: '3:30',
        audioUrl: url,
        isCustom: true,
      });
    });

    const updated = [...newTracks, ...tracks];
    setTracks(updated);
    vaaniBotService.savePlaylist(updated);
    audioService.playSound('send');
    audioService.speak(`Vaani imported ${newTracks.length} offline tracks.`, 'en-IN');
  };

  // Launch Vaani APK on Android
  const handleLaunchVaaniApk = () => {
    audioService.playSound('click');
    audioService.speak('Launching Vaani Music Bot APK on your device.', 'en-IN');
    vaaniBotService.openVaaniApk();
  };

  const toggleShuffle = () => {
    const updated = { ...config, shuffle: !config.shuffle };
    setConfig(updated);
    vaaniBotService.saveConfig(updated);
    audioService.playSound('toggle');
  };

  const toggleRepeat = () => {
    const updated = { ...config, repeat: !config.repeat };
    setConfig(updated);
    vaaniBotService.saveConfig(updated);
    audioService.playSound('toggle');
  };

  return (
    <div className="space-y-4">
      {/* Hidden local music picker */}
      <input
        type="file"
        ref={fileInputRef}
        multiple
        accept="audio/*"
        onChange={handleLocalMusicUpload}
        className="hidden"
      />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2.5">
          <div className="w-9 h-9 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400 glow-cyan">
            <Radio className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-white tracking-wide uppercase flex items-center gap-1.5">
              <span>Vaani Music Bot</span>
              <span className="text-[10px] text-cyan-400 bg-cyan-500/10 px-2 py-0.5 rounded-full border border-cyan-500/20 font-mono">
                Offline Engine
              </span>
            </h2>
            <p className="text-xs text-slate-400">
              Operated by Vyshu AI via voice commands &bull; Native APK Bridge
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={() => setShowConfigModal(!showConfigModal)}
            title="Vaani Bot Settings"
            className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition"
          >
            <Sliders className="w-4 h-4" />
          </button>

          <button
            onClick={handleLaunchVaaniApk}
            className="text-xs px-3 py-1.5 rounded-xl bg-purple-500/20 border border-purple-500/40 text-purple-300 font-semibold hover:bg-purple-500/30 flex items-center gap-1.5 transition active:scale-95"
            title="Open Vaani Music Bot APK on device"
          >
            <Bot className="w-3.5 h-3.5" /> Launch APK <ExternalLink className="w-3 h-3" />
          </button>
        </div>
      </div>

      {/* Vaani APK Configuration Banner */}
      {showConfigModal && (
        <div className="p-4 bg-[#0e1422] border border-cyan-500/40 rounded-2xl space-y-3 animate-fade-in text-xs">
          <div className="font-bold text-cyan-400 flex items-center gap-1.5">
            <Bot className="w-4 h-4" /> Vaani APK Package Configuration
          </div>
          <p className="text-slate-300">
            Configure the Android package name of your standalone Vaani Music Bot APK so Vyshu can launch
            or control it directly via Android OS Intents.
          </p>
          <div>
            <label className="text-slate-400 block mb-1">Android Package Name</label>
            <input
              type="text"
              value={config.apkPackageName}
              onChange={(e) => {
                const updated = { ...config, apkPackageName: e.target.value };
                setConfig(updated);
                vaaniBotService.saveConfig(updated);
              }}
              placeholder="com.teja.vaani"
              className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono focus:outline-none focus:border-cyan-400"
            />
          </div>
          <div className="flex items-center justify-between text-[11px] text-emerald-400 font-mono pt-1">
            <span className="flex items-center gap-1">
              <CheckCircle2 className="w-3.5 h-3.5" /> Voice intent listening: &quot;Vaani, play...&quot;
            </span>
            <button
              onClick={() => setShowConfigModal(false)}
              className="text-slate-400 hover:text-white"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Now Playing Card */}
      <div className="p-5 bg-[#0b0b16] border border-cyan-500/30 rounded-3xl glow-cyan space-y-4">
        <div className="flex items-center space-x-4">
          <div className={`w-14 h-14 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400 shadow-md ${isPlaying ? 'animate-spin' : ''}`}>
            <Disc className="w-7 h-7" />
          </div>
          <div className="overflow-hidden flex-1">
            <div className="text-[10px] text-cyan-400 font-mono tracking-wider uppercase flex items-center gap-1">
              <span>VAANI BOT OPERATING</span>
              {isPlaying && <span className="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-ping"></span>}
            </div>
            <div className="text-base font-bold text-white truncate">{currentTrack.title}</div>
            <div className="text-xs text-slate-400 truncate">{currentTrack.artist}</div>
          </div>
        </div>

        {/* Progress bar */}
        <div className="space-y-1">
          <div className="w-full bg-slate-800 rounded-full h-1.5 overflow-hidden">
            <div
              className="bg-cyan-400 h-1.5 rounded-full transition-all duration-300"
              style={{ width: isPlaying ? '55%' : '15%' }}
            />
          </div>
          <div className="flex justify-between text-[10px] font-mono text-slate-500">
            <span>{isPlaying ? '01:42' : '00:00'}</span>
            <span>{currentTrack.duration}</span>
          </div>
        </div>

        {/* Playback Controls */}
        <div className="flex items-center justify-between pt-1">
          <button
            onClick={toggleShuffle}
            className={`p-2 rounded-xl transition ${config.shuffle ? 'text-cyan-400 bg-cyan-500/10' : 'text-slate-500 hover:text-slate-300'}`}
            title="Shuffle"
          >
            <Shuffle className="w-4 h-4" />
          </button>

          <div className="flex items-center space-x-5">
            <button
              onClick={handlePrev}
              className="p-2 text-slate-400 hover:text-white transition active:scale-95"
            >
              <SkipBack className="w-5 h-5" />
            </button>

            <button
              onClick={handlePlayPause}
              className="w-12 h-12 rounded-full bg-cyan-400 text-slate-950 font-bold flex items-center justify-center hover:bg-cyan-300 transition active:scale-95 shadow-lg shadow-cyan-500/30"
            >
              {isPlaying ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5 ml-0.5" />}
            </button>

            <button
              onClick={handleNext}
              className="p-2 text-slate-400 hover:text-white transition active:scale-95"
            >
              <SkipForward className="w-5 h-5" />
            </button>
          </div>

          <button
            onClick={toggleRepeat}
            className={`p-2 rounded-xl transition ${config.repeat ? 'text-cyan-400 bg-cyan-500/10' : 'text-slate-500 hover:text-slate-300'}`}
            title="Repeat"
          >
            <Repeat className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Voice delegation banner */}
      <div className="p-3 bg-[#080814] border border-slate-800 rounded-2xl flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-cyan-400 shrink-0" />
          <span className="text-slate-300">
            Voice command active: Say <strong className="text-white">&ldquo;Vaani, play my songs&rdquo;</strong> in chat
          </span>
        </div>
        <button
          onClick={() => fileInputRef.current?.click()}
          className="text-xs px-3 py-1.5 rounded-xl bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 flex items-center gap-1.5 transition active:scale-95 shrink-0"
        >
          <FolderPlus className="w-3.5 h-3.5" /> Add Songs
        </button>
      </div>

      {/* Playlist */}
      <div className="space-y-2">
        <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider px-1">
          Vaani Offline Playlist ({tracks.length} Tracks)
        </div>
        <div className="space-y-2 max-h-[30vh] overflow-y-auto pr-1">
          {tracks.map((track, idx) => {
            const isSelected = idx === currentTrackIndex;
            return (
              <div
                key={track.id}
                onClick={() => handleSelectTrack(idx)}
                className={`p-3 rounded-2xl border transition flex items-center justify-between cursor-pointer ${
                  isSelected
                    ? 'bg-cyan-500/10 border-cyan-400 text-cyan-300 shadow-sm'
                    : 'bg-[#0b0b16] border-slate-800/80 hover:border-slate-700'
                }`}
              >
                <div className="flex items-center space-x-3 overflow-hidden">
                  <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-xs font-bold shrink-0 ${isSelected ? 'bg-cyan-400 text-slate-950' : 'bg-slate-800 text-slate-400'}`}>
                    {idx + 1}
                  </div>
                  <div className="truncate">
                    <div className="text-xs font-bold text-white truncate">{track.title}</div>
                    <div className="text-[11px] text-slate-400 truncate">{track.artist}</div>
                  </div>
                </div>

                <div className="text-xs font-mono text-slate-400 shrink-0">{track.duration}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
