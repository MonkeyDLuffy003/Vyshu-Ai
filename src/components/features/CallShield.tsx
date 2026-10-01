import React, { useState } from 'react';
import {
  ShieldCheck,
  ShieldAlert,
  PhoneOff,
  PhoneCall,
  UserCheck,
  Lock,
  Volume2,
  Trash2,
  CheckCircle2,
  Sparkles,
  RefreshCw,
  PlusCircle,
  EyeOff,
  Radio,
} from 'lucide-react';
import {
  vyshuCallShieldService,
  ScreenedCallRecord,
  CallShieldSettings,
} from '../../services/vyshuCallShieldService';

interface CallShieldProps {
  onAskVyshu?: (query: string) => void;
}

export const CallShield: React.FC<CallShieldProps> = () => {
  const [settings, setSettings] = useState<CallShieldSettings>(() =>
    vyshuCallShieldService.getSettings()
  );
  const [callLogs, setCallLogs] = useState<ScreenedCallRecord[]>(() =>
    vyshuCallShieldService.getCallLogs()
  );
  const [activeSimulationModal, setActiveSimulationModal] = useState<boolean>(false);
  const [simPhoneNumber, setSimPhoneNumber] = useState<string>('+91 99120 44821');
  const [simCallerType, setSimCallerType] = useState<'spam' | 'safe'>('spam');
  const [selectedCallDetails, setSelectedCallDetails] = useState<ScreenedCallRecord | null>(null);

  const handleToggle = (key: keyof CallShieldSettings) => {
    const updated = { ...settings, [key]: !settings[key] };
    setSettings(updated);
    vyshuCallShieldService.updateSettings({ [key]: updated[key] });
  };

  const handleSimulateCall = () => {
    const record = vyshuCallShieldService.simulateIncomingCall(
      simPhoneNumber,
      simCallerType === 'spam' ? 'Unverified Telemarketing AI' : 'Courier / Delivery Agent',
      simCallerType === 'spam'
    );
    setCallLogs(vyshuCallShieldService.getCallLogs());
    setSelectedCallDetails(record);
    setActiveSimulationModal(false);
  };

  const handleDeleteLog = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    vyshuCallShieldService.deleteLog(id);
    setCallLogs(vyshuCallShieldService.getCallLogs());
    if (selectedCallDetails?.id === id) {
      setSelectedCallDetails(null);
    }
  };

  return (
    <div className="space-y-5 p-1 animate-fade-in text-slate-100">
      {/* Hero Banner: Identity Shield & Voice Screener */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-cyan-950/60 via-slate-900/90 to-blue-950/70 border border-cyan-500/30 p-5 shadow-lg">
        <div className="absolute -top-12 -right-12 w-40 h-40 bg-cyan-500/10 rounded-full blur-3xl pointer-events-none" />
        
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-start space-x-3.5">
            <div className="p-3 rounded-xl bg-cyan-500/20 border border-cyan-400/40 text-cyan-300 shadow-inner">
              <ShieldCheck className="w-7 h-7 text-cyan-400 animate-pulse" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h3 className="text-lg font-bold text-white tracking-wide">
                  Vyshu AI Call Screening & Identity Shield
                </h3>
                <span className="px-2 py-0.5 text-[10px] uppercase font-bold rounded-full bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 flex items-center gap-1">
                  <Radio className="w-2.5 h-2.5 animate-ping" /> OS Layer Active
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1 max-w-md leading-relaxed">
                Vyshu intercepts incoming calls on your phone, answers in her own voice, conceals your real name and identity from scammers, interrogates the caller, and only rings you when verified safe.
              </p>
            </div>
          </div>

          <button
            onClick={() => setActiveSimulationModal(true)}
            className="flex items-center justify-center space-x-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-black font-semibold text-xs tracking-wide transition shadow-lg shadow-cyan-500/20"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Simulate Incoming Call</span>
          </button>
        </div>

        {/* Protection Metrics */}
        <div className="grid grid-cols-3 gap-2.5 mt-4 pt-4 border-t border-slate-800/80">
          <div className="bg-slate-950/60 rounded-xl p-2.5 border border-slate-800 text-center">
            <div className="text-base font-extrabold text-cyan-400">100%</div>
            <div className="text-[10px] text-slate-400 uppercase tracking-wider mt-0.5">Identity Concealed</div>
          </div>
          <div className="bg-slate-950/60 rounded-xl p-2.5 border border-slate-800 text-center">
            <div className="text-base font-extrabold text-emerald-400">
              {callLogs.filter((c) => c.status === 'BLOCKED' || c.status === 'DEFLECTED').length}
            </div>
            <div className="text-[10px] text-slate-400 uppercase tracking-wider mt-0.5">Spam Calls Silenced</div>
          </div>
          <div className="bg-slate-950/60 rounded-xl p-2.5 border border-slate-800 text-center">
            <div className="text-base font-extrabold text-blue-400">
              {callLogs.filter((c) => c.status === 'TRANSFERRED_TO_TEJA').length}
            </div>
            <div className="text-[10px] text-slate-400 uppercase tracking-wider mt-0.5">VIPs Patched To Teja</div>
          </div>
        </div>
      </div>

      {/* Core Security Toggles */}
      <div className="bg-[#0b0b18] rounded-2xl border border-slate-800/80 p-4 space-y-3">
        <h4 className="text-xs uppercase tracking-wider font-semibold text-slate-400 flex items-center gap-1.5">
          <Lock className="w-3.5 h-3.5 text-cyan-400" /> Autonomous Shield Policies
        </h4>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
          <div
            onClick={() => handleToggle('concealTejaIdentity')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
              settings.concealTejaIdentity
                ? 'bg-cyan-950/30 border-cyan-500/40 text-cyan-200'
                : 'bg-slate-900/50 border-slate-800 text-slate-400'
            }`}
          >
            <div className="flex items-center space-x-2.5">
              <EyeOff className="w-4 h-4 text-cyan-400" />
              <div>
                <div className="text-xs font-semibold">Conceal Teja's Identity</div>
                <div className="text-[10px] text-slate-400">Never reveals your name or location to callers</div>
              </div>
            </div>
            <div className={`w-8 h-4 rounded-full relative transition-colors ${settings.concealTejaIdentity ? 'bg-cyan-500' : 'bg-slate-700'}`}>
              <div className={`w-3.5 h-3.5 bg-white rounded-full absolute top-[1px] transition-transform ${settings.concealTejaIdentity ? 'translate-x-4' : 'translate-x-0.5'}`} />
            </div>
          </div>

          <div
            onClick={() => handleToggle('autoScreenUnknownNumbers')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
              settings.autoScreenUnknownNumbers
                ? 'bg-cyan-950/30 border-cyan-500/40 text-cyan-200'
                : 'bg-slate-900/50 border-slate-800 text-slate-400'
            }`}
          >
            <div className="flex items-center space-x-2.5">
              <Sparkles className="w-4 h-4 text-cyan-400" />
              <div>
                <div className="text-xs font-semibold">Auto-Screen Unknown Numbers</div>
                <div className="text-[10px] text-slate-400">Vyshu answers first with voice screening</div>
              </div>
            </div>
            <div className={`w-8 h-4 rounded-full relative transition-colors ${settings.autoScreenUnknownNumbers ? 'bg-cyan-500' : 'bg-slate-700'}`}>
              <div className={`w-3.5 h-3.5 bg-white rounded-full absolute top-[1px] transition-transform ${settings.autoScreenUnknownNumbers ? 'translate-x-4' : 'translate-x-0.5'}`} />
            </div>
          </div>

          <div
            onClick={() => handleToggle('autoBlockKnownSpam')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
              settings.autoBlockKnownSpam
                ? 'bg-cyan-950/30 border-cyan-500/40 text-cyan-200'
                : 'bg-slate-900/50 border-slate-800 text-slate-400'
            }`}
          >
            <div className="flex items-center space-x-2.5">
              <PhoneOff className="w-4 h-4 text-red-400" />
              <div>
                <div className="text-xs font-semibold">Auto-Block Known Telemarketers</div>
                <div className="text-[10px] text-slate-400">Instantly terminates telemarketing bots</div>
              </div>
            </div>
            <div className={`w-8 h-4 rounded-full relative transition-colors ${settings.autoBlockKnownSpam ? 'bg-cyan-500' : 'bg-slate-700'}`}>
              <div className={`w-3.5 h-3.5 bg-white rounded-full absolute top-[1px] transition-transform ${settings.autoBlockKnownSpam ? 'translate-x-4' : 'translate-x-0.5'}`} />
            </div>
          </div>

          <div
            onClick={() => handleToggle('recordingEnabled')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
              settings.recordingEnabled
                ? 'bg-cyan-950/30 border-cyan-500/40 text-cyan-200'
                : 'bg-slate-900/50 border-slate-800 text-slate-400'
            }`}
          >
            <div className="flex items-center space-x-2.5">
              <Volume2 className="w-4 h-4 text-blue-400" />
              <div>
                <div className="text-xs font-semibold">Full Speech Transcriptions</div>
                <div className="text-[10px] text-slate-400">Live AI audio transcripts generated on device</div>
              </div>
            </div>
            <div className={`w-8 h-4 rounded-full relative transition-colors ${settings.recordingEnabled ? 'bg-cyan-500' : 'bg-slate-700'}`}>
              <div className={`w-3.5 h-3.5 bg-white rounded-full absolute top-[1px] transition-transform ${settings.recordingEnabled ? 'translate-x-4' : 'translate-x-0.5'}`} />
            </div>
          </div>
        </div>
      </div>

      {/* Screened Call Activity History */}
      <div className="bg-[#0b0b18] rounded-2xl border border-slate-800/80 p-4 space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="text-xs uppercase tracking-wider font-semibold text-slate-400 flex items-center gap-1.5">
            <UserCheck className="w-3.5 h-3.5 text-emerald-400" /> Screened Calls Log ({callLogs.length})
          </h4>
          <span className="text-[11px] text-slate-500">Tap any call to read Vyshu's full transcript</span>
        </div>

        <div className="space-y-2.5 max-h-[300px] overflow-y-auto pr-1">
          {callLogs.map((log) => {
            const isSpam = log.threatLevel === 'SPAM_BLOCKED' || log.threatLevel === 'SCAMMER_DEFLECTED';
            return (
              <div
                key={log.id}
                onClick={() => setSelectedCallDetails(log)}
                className={`p-3 rounded-xl border transition cursor-pointer flex flex-col gap-2 ${
                  selectedCallDetails?.id === log.id
                    ? 'border-cyan-500 bg-cyan-950/20'
                    : isSpam
                    ? 'border-red-900/40 bg-red-950/10 hover:border-red-500/50'
                    : 'border-slate-800 bg-slate-900/40 hover:border-slate-700'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2.5">
                    <div
                      className={`w-7 h-7 rounded-lg flex items-center justify-center ${
                        isSpam ? 'bg-red-500/20 text-red-400' : 'bg-emerald-500/20 text-emerald-400'
                      }`}
                    >
                      {isSpam ? <ShieldAlert className="w-4 h-4" /> : <PhoneCall className="w-4 h-4" />}
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-white flex items-center gap-2">
                        <span>{log.callerNumber}</span>
                        {log.callerName && (
                          <span className="text-[11px] text-slate-400 font-normal">({log.callerName})</span>
                        )}
                      </div>
                      <div className="text-[10px] text-slate-400">{log.timestamp} • {log.durationSeconds}s call</div>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <span
                      className={`px-2 py-0.5 text-[9px] font-bold uppercase rounded-md border ${
                        isSpam
                          ? 'bg-red-500/10 text-red-300 border-red-500/30'
                          : 'bg-emerald-500/10 text-emerald-300 border-emerald-500/30'
                      }`}
                    >
                      {log.threatLevel.replace('_', ' ')}
                    </span>
                    <button
                      onClick={(e) => handleDeleteLog(log.id, e)}
                      className="p-1 text-slate-500 hover:text-red-400 transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                <div className="text-[11px] text-slate-300 bg-slate-950/60 p-2 rounded-lg border border-slate-800/80 leading-relaxed">
                  <span className="text-cyan-400 font-medium">Vyshu Summary:</span> {log.vyshuAiSummary}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Selected Call Detail & Live Transcript View */}
      {selectedCallDetails && (
        <div className="bg-[#050510] border border-cyan-500/40 rounded-2xl p-4 space-y-3 shadow-2xl animate-fade-in">
          <div className="flex items-center justify-between border-b border-slate-800 pb-2.5">
            <div className="flex items-center space-x-2">
              <Sparkles className="w-4 h-4 text-cyan-400" />
              <h4 className="text-xs font-bold text-white uppercase tracking-wider">
                Call Interception Transcript — {selectedCallDetails.callerNumber}
              </h4>
            </div>
            <span className="text-[10px] text-emerald-400 flex items-center gap-1 font-semibold">
              <CheckCircle2 className="w-3 h-3" /> Identity Masking Maintained
            </span>
          </div>

          <div className="space-y-2 text-xs">
            <div className="bg-cyan-950/20 border border-cyan-500/20 p-2.5 rounded-xl">
              <span className="text-[10px] text-cyan-400 uppercase font-bold tracking-wider block mb-1">
                Vyshu's Autonomous Opening Statement:
              </span>
              <p className="text-slate-200 italic">"{selectedCallDetails.vyshuSpokenIntro}"</p>
            </div>

            <div className="space-y-1.5 pt-1">
              <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider block">
                Dialog Exchange:
              </span>
              {selectedCallDetails.callerTranscript.map((t, idx) => (
                <div
                  key={idx}
                  className={`p-2 rounded-lg text-xs leading-relaxed ${
                    t.startsWith('Caller')
                      ? 'bg-slate-900/80 border border-slate-800 text-slate-200'
                      : 'bg-cyan-900/20 border border-cyan-500/30 text-cyan-200 font-medium'
                  }`}
                >
                  {t}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Simulation Modal */}
      {activeSimulationModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#0b0b18] border border-cyan-500/40 rounded-2xl max-w-sm w-full p-5 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-bold text-white flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-cyan-400" /> Simulate Call Interception
              </h4>
              <button
                onClick={() => setActiveSimulationModal(false)}
                className="text-xs text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2.5">
              <div>
                <label className="text-[10px] text-slate-400 uppercase tracking-wider font-semibold block mb-1">
                  Caller Phone Number
                </label>
                <input
                  type="text"
                  value={simPhoneNumber}
                  onChange={(e) => setSimPhoneNumber(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-cyan-500"
                />
              </div>

              <div>
                <label className="text-[10px] text-slate-400 uppercase tracking-wider font-semibold block mb-1">
                  Caller Profile
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setSimCallerType('spam')}
                    className={`py-2 px-3 rounded-xl border text-xs font-semibold transition ${
                      simCallerType === 'spam'
                        ? 'bg-red-500/20 border-red-500/40 text-red-300'
                        : 'bg-slate-900 border-slate-800 text-slate-400'
                    }`}
                  >
                    Spam / Telemarketer
                  </button>
                  <button
                    type="button"
                    onClick={() => setSimCallerType('safe')}
                    className={`py-2 px-3 rounded-xl border text-xs font-semibold transition ${
                      simCallerType === 'safe'
                        ? 'bg-emerald-500/20 border-emerald-500/40 text-emerald-300'
                        : 'bg-slate-900 border-slate-800 text-slate-400'
                    }`}
                  >
                    Safe Courier / VIP
                  </button>
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setActiveSimulationModal(false)}
                className="px-3 py-1.5 text-xs text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={handleSimulateCall}
                className="px-4 py-2 bg-gradient-to-r from-cyan-500 to-blue-600 font-bold text-xs text-black rounded-xl hover:opacity-90 transition"
              >
                Run Screening
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
