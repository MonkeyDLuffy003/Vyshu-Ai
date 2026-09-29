// Vaani Music Bot Integration Service
// Handles offline song scanning, voice playback delegation from Vyshu,
// and Android Deep Linking / Intent bridge to the Vaani Music Bot APK.

import { SongTrack } from '../types';
import { audioService } from './audioService';

const VAANI_STORAGE_KEY = 'vaani_offline_playlist';
const VAANI_CONFIG_KEY = 'vaani_bot_config';

export interface VaaniBotConfig {
  apkPackageName: string; // e.g. "com.teja.vaani" or "com.vaani.music"
  enableApkDeepLink: boolean;
  shuffle: boolean;
  repeat: boolean;
  bassBoost: boolean;
  volume: number; // 0 - 100
}

const DEFAULT_VAANI_CONFIG: VaaniBotConfig = {
  apkPackageName: 'com.teja.vaani',
  enableApkDeepLink: true,
  shuffle: false,
  repeat: false,
  bassBoost: true,
  volume: 85,
};

export const DEFAULT_VAANI_TRACKS: SongTrack[] = [
  {
    id: 'vaani-1',
    title: 'Vaani Offline Pulse (Lofi Beats)',
    artist: 'Vaani Music Bot',
    duration: '3:45',
    audioUrl: 'synth:lofi',
  },
  {
    id: 'vaani-2',
    title: 'Midnight Hyderabad Synth',
    artist: 'Vaani Audio Engine',
    duration: '2:50',
    audioUrl: 'synth:ambient',
  },
  {
    id: 'vaani-3',
    title: 'Teja Gym Motivation Drift',
    artist: 'Vaani Bass Boost',
    duration: '4:10',
    audioUrl: 'synth:focus',
  },
];

class VaaniBotService {
  private currentTrackIndex = 0;
  private isPlaying = false;
  private audio: HTMLAudioElement | null = null;
  private synthOsc: OscillatorNode | null = null;
  private synthGain: GainNode | null = null;
  private listeners: Set<(state: { isPlaying: boolean; track: SongTrack; index: number }) => void> = new Set();

  constructor() {
    if (typeof window !== 'undefined') {
      this.audio = new Audio();
      this.audio.onended = () => {
        this.next();
      };
    }
  }

  // Get Saved Playlist
  public getPlaylist(): SongTrack[] {
    try {
      const raw = localStorage.getItem(VAANI_STORAGE_KEY);
      if (!raw) return DEFAULT_VAANI_TRACKS;
      const parsed = JSON.parse(raw);
      return parsed.length > 0 ? parsed : DEFAULT_VAANI_TRACKS;
    } catch {
      return DEFAULT_VAANI_TRACKS;
    }
  }

  public savePlaylist(tracks: SongTrack[]): void {
    localStorage.setItem(VAANI_STORAGE_KEY, JSON.stringify(tracks));
  }

  // Get/Save Config
  public getConfig(): VaaniBotConfig {
    try {
      const raw = localStorage.getItem(VAANI_CONFIG_KEY);
      if (!raw) return DEFAULT_VAANI_CONFIG;
      return { ...DEFAULT_VAANI_CONFIG, ...JSON.parse(raw) };
    } catch {
      return DEFAULT_VAANI_CONFIG;
    }
  }

  public saveConfig(cfg: VaaniBotConfig): void {
    localStorage.setItem(VAANI_CONFIG_KEY, JSON.stringify(cfg));
  }

  public subscribe(cb: (state: { isPlaying: boolean; track: SongTrack; index: number }) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  private notify() {
    const list = this.getPlaylist();
    const track = list[this.currentTrackIndex] || list[0];
    this.listeners.forEach((cb) => cb({ isPlaying: this.isPlaying, track, index: this.currentTrackIndex }));
  }

  // Built-in synthesized audio generator
  private startSynth(type: string) {
    this.stopSynth();
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = type === 'synth:lofi' ? 'sine' : type === 'synth:ambient' ? 'triangle' : 'sawtooth';
      osc.frequency.setValueAtTime(220, ctx.currentTime); // A3

      gain.gain.setValueAtTime(0.08, ctx.currentTime);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();

      this.synthOsc = osc;
      this.synthGain = gain;
    } catch {}
  }

  private stopSynth() {
    if (this.synthOsc) {
      try {
        this.synthOsc.stop();
        this.synthOsc.disconnect();
      } catch {}
      this.synthOsc = null;
    }
  }

  // Play Specific Index
  public playTrack(index: number): SongTrack {
    const list = this.getPlaylist();
    if (list.length === 0) return DEFAULT_VAANI_TRACKS[0];

    this.currentTrackIndex = Math.max(0, Math.min(index, list.length - 1));
    const track = list[this.currentTrackIndex];

    this.stopSynth();
    if (this.audio) {
      this.audio.pause();
    }

    if (track.isCustom && this.audio) {
      this.audio.src = track.audioUrl;
      this.audio.play().catch(() => {});
    } else {
      this.startSynth(track.audioUrl);
    }

    this.isPlaying = true;
    this.notify();
    return track;
  }

  // Voice Command: Search & Play track by name
  public searchAndPlay(query: string): { success: boolean; trackName: string } {
    const list = this.getPlaylist();
    const q = query.toLowerCase().trim();

    if (!q || q === 'music' || q === 'song' || q === 'songs') {
      const track = this.playTrack(this.currentTrackIndex);
      return { success: true, trackName: track.title };
    }

    const matchedIdx = list.findIndex(
      (t) => t.title.toLowerCase().includes(q) || t.artist.toLowerCase().includes(q)
    );

    if (matchedIdx !== -1) {
      const track = this.playTrack(matchedIdx);
      return { success: true, trackName: track.title };
    }

    // Default to current track if no exact match
    const track = this.playTrack(0);
    return { success: true, trackName: track.title };
  }

  // Voice Command: Play / Resume
  public play(): SongTrack {
    return this.playTrack(this.currentTrackIndex);
  }

  // Voice Command: Pause
  public pause(): void {
    if (this.audio) this.audio.pause();
    this.stopSynth();
    this.isPlaying = false;
    this.notify();
  }

  // Voice Command: Next Track
  public next(): SongTrack {
    const list = this.getPlaylist();
    const cfg = this.getConfig();
    let nextIdx = (this.currentTrackIndex + 1) % list.length;
    if (cfg.shuffle) {
      nextIdx = Math.floor(Math.random() * list.length);
    }
    return this.playTrack(nextIdx);
  }

  // Voice Command: Previous Track
  public previous(): SongTrack {
    const list = this.getPlaylist();
    const prevIdx = (this.currentTrackIndex - 1 + list.length) % list.length;
    return this.playTrack(prevIdx);
  }

  // Launch external Vaani Music Bot APK on Android device via Intent / URL Scheme
  public openVaaniApk(command?: string): boolean {
    const cfg = this.getConfig();
    const pkg = cfg.apkPackageName || 'com.teja.vaani';

    try {
      if (typeof window !== 'undefined') {
        // 1. Android Intent URL for direct app launch
        const intentUrl = command
          ? `intent://vaani?action=${encodeURIComponent(command)}#Intent;scheme=vaani;package=${pkg};end`
          : `intent://open#Intent;scheme=vaani;package=${pkg};end`;

        const link = document.createElement('a');
        link.href = intentUrl;
        document.body.appendChild(link);
        link.click();
        link.remove();
        return true;
      }
    } catch (e) {
      console.warn('Could not launch Vaani APK intent:', e);
    }
    return false;
  }

  public getCurrentState() {
    const list = this.getPlaylist();
    return {
      isPlaying: this.isPlaying,
      track: list[this.currentTrackIndex] || list[0],
      index: this.currentTrackIndex,
      total: list.length,
    };
  }
}

export const vaaniBotService = new VaaniBotService();
