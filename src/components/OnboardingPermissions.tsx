import React, { useState } from 'react';
import {
  Mic,
  Users,
  Phone,
  Bell,
  Camera,
  FolderArchive,
  Bluetooth,
  Sliders,
  CheckCircle2,
  Circle,
  ExternalLink,
  ShieldCheck,
  Sparkles,
} from 'lucide-react';
import { storageService } from '../services/storageService';

interface OnboardingPermissionsProps {
  onComplete: () => void;
}

export const OnboardingPermissions: React.FC<OnboardingPermissionsProps> = ({ onComplete }) => {
  const [permissions, setPermissions] = useState<Record<string, boolean>>({
    'Microphone (voice chat)': true,
    'Contacts (calling)': true,
    'Phone calls': true,
    'Notifications': true,
    'Camera (torch/scan)': true,
    'Storage (offline music)': true,
    'Bluetooth': true,
  });

  const [specialPermissions, setSpecialPermissions] = useState<Record<string, boolean>>({
    accessibility: true,
    notificationListener: true,
    systemSettings: true,
  });

  const [requesting, setRequesting] = useState(false);

  const togglePermission = (name: string) => {
    setPermissions((prev) => ({ ...prev, [name]: !prev[name] }));
  };

  const handleGrantAll = () => {
    setRequesting(true);
    setTimeout(() => {
      setPermissions({
        'Microphone (voice chat)': true,
        'Contacts (calling)': true,
        'Phone calls': true,
        'Notifications': true,
        'Camera (torch/scan)': true,
        'Storage (offline music)': true,
        'Bluetooth': true,
      });
      setSpecialPermissions({
        accessibility: true,
        notificationListener: true,
        systemSettings: true,
      });
      setRequesting(false);
    }, 600);
  };

  const handleFinish = () => {
    storageService.setOnboardingComplete(true);
    onComplete();
  };

  return (
    <div className="min-h-screen bg-[#05050f] text-slate-100 flex flex-col justify-between p-6 max-w-lg mx-auto">
      <div className="space-y-6 pt-4">
        {/* Header */}
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center glow-cyan">
            <ShieldCheck className="w-6 h-6 text-cyan-400" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
              Before Vyshu Wakes Up <Sparkles className="w-4 h-4 text-cyan-400" />
            </h1>
            <p className="text-xs text-cyan-400/80 font-mono tracking-wider uppercase">Android 15 Permission Guard</p>
          </div>
        </div>

        <p className="text-sm text-slate-400 leading-relaxed bg-[#0b0b16] p-3.5 rounded-xl border border-slate-800">
          Vyshu needs permission access to talk, call, automate apps, and control hardware accessories.
          Android locks these down without explicit authorization.
        </p>

        {/* Runtime Permissions List */}
        <div className="space-y-2.5">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-400 px-1">
            Standard Runtime Permissions
          </h2>
          <div className="bg-[#0b0b16] border border-slate-800/80 rounded-2xl divide-y divide-slate-800/60 overflow-hidden">
            {[
              { label: 'Microphone (voice chat)', icon: Mic },
              { label: 'Contacts (calling)', icon: Users },
              { label: 'Phone calls', icon: Phone },
              { label: 'Notifications', icon: Bell },
              { label: 'Camera (torch/scan)', icon: Camera },
              { label: 'Storage (offline music)', icon: FolderArchive },
              { label: 'Bluetooth', icon: Bluetooth },
            ].map(({ label, icon: Icon }) => {
              const isGranted = permissions[label];
              return (
                <div
                  key={label}
                  onClick={() => togglePermission(label)}
                  className="flex items-center justify-between p-3 px-4 hover:bg-slate-800/30 cursor-pointer transition"
                >
                  <div className="flex items-center space-x-3">
                    <Icon className="w-4 h-4 text-slate-400" />
                    <span className="text-sm font-medium text-slate-200">{label}</span>
                  </div>
                  {isGranted ? (
                    <span className="flex items-center text-xs font-semibold text-emerald-400 gap-1.5 bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20">
                      <CheckCircle2 className="w-3.5 h-3.5" /> Granted
                    </span>
                  ) : (
                    <span className="flex items-center text-xs text-slate-400 gap-1.5 bg-slate-800/60 px-2.5 py-1 rounded-full">
                      <Circle className="w-3.5 h-3.5" /> Tap to grant
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Special Android System Permissions */}
        <div className="space-y-2.5">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-cyan-400 px-1 flex items-center justify-between">
            <span>Special System Services</span>
            <span className="text-[10px] text-slate-400 font-normal">Android settings toggle</span>
          </h2>
          <div className="bg-[#0b0b16] border border-slate-800/80 rounded-2xl divide-y divide-slate-800/60 overflow-hidden">
            <div className="p-3 px-4 flex items-center justify-between">
              <div>
                <div className="text-sm font-medium text-slate-200 flex items-center gap-1.5">
                  <Sliders className="w-4 h-4 text-cyan-400" /> Accessibility Service
                </div>
                <div className="text-xs text-slate-400 mt-0.5">Needed for app-opening &amp; screen automation</div>
              </div>
              <button
                onClick={() => setSpecialPermissions((p) => ({ ...p, accessibility: !p.accessibility }))}
                className={`text-xs px-3 py-1.5 rounded-lg border flex items-center gap-1 font-medium transition ${
                  specialPermissions.accessibility
                    ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40'
                    : 'bg-slate-800 text-slate-300 border-slate-700'
                }`}
              >
                {specialPermissions.accessibility ? 'Active' : 'Configure'} <ExternalLink className="w-3 h-3" />
              </button>
            </div>

            <div className="p-3 px-4 flex items-center justify-between">
              <div>
                <div className="text-sm font-medium text-slate-200 flex items-center gap-1.5">
                  <Bell className="w-4 h-4 text-cyan-400" /> Notification Listener
                </div>
                <div className="text-xs text-slate-400 mt-0.5">Allows Vyshu to read notifications aloud</div>
              </div>
              <button
                onClick={() =>
                  setSpecialPermissions((p) => ({ ...p, notificationListener: !p.notificationListener }))
                }
                className={`text-xs px-3 py-1.5 rounded-lg border flex items-center gap-1 font-medium transition ${
                  specialPermissions.notificationListener
                    ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40'
                    : 'bg-slate-800 text-slate-300 border-slate-700'
                }`}
              >
                {specialPermissions.notificationListener ? 'Active' : 'Configure'} <ExternalLink className="w-3 h-3" />
              </button>
            </div>

            <div className="p-3 px-4 flex items-center justify-between">
              <div>
                <div className="text-sm font-medium text-slate-200 flex items-center gap-1.5">
                  <Sliders className="w-4 h-4 text-cyan-400" /> Modify System Settings
                </div>
                <div className="text-xs text-slate-400 mt-0.5">For Wi-Fi, torch, volume &amp; brightness control</div>
              </div>
              <button
                onClick={() => setSpecialPermissions((p) => ({ ...p, systemSettings: !p.systemSettings }))}
                className={`text-xs px-3 py-1.5 rounded-lg border flex items-center gap-1 font-medium transition ${
                  specialPermissions.systemSettings
                    ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40'
                    : 'bg-slate-800 text-slate-300 border-slate-700'
                }`}
              >
                {specialPermissions.systemSettings ? 'Active' : 'Configure'} <ExternalLink className="w-3 h-3" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="space-y-3 pt-6 pb-2">
        <button
          onClick={handleGrantAll}
          disabled={requesting}
          className="w-full py-3.5 px-4 rounded-xl bg-[#12122a] border border-cyan-500/40 text-cyan-300 font-semibold text-sm hover:bg-cyan-500/10 active:scale-[0.99] transition flex items-center justify-center gap-2"
        >
          {requesting ? (
            <span className="inline-block w-4 h-4 border-2 border-cyan-400 border-t-transparent rounded-full animate-spin"></span>
          ) : (
            'Grant All App Permissions'
          )}
        </button>

        <button
          onClick={handleFinish}
          className="w-full py-3.5 px-4 rounded-xl bg-cyan-400 hover:bg-cyan-300 text-slate-950 font-bold text-sm shadow-lg shadow-cyan-500/20 active:scale-[0.99] transition flex items-center justify-center gap-2"
        >
          Continue to Vyshu AI
        </button>
      </div>
    </div>
  );
};
