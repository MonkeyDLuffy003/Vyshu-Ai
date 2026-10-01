import React from 'react';
import { MessageSquare, Sliders, KeyRound, Sparkles, LayoutGrid, Eye } from 'lucide-react';

interface BottomNavProps {
  currentTab: 'vyshu' | 'room' | 'control' | 'vault';
  onSelectTab: (tab: 'vyshu' | 'room' | 'control' | 'vault') => void;
  onOpenHub: () => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentTab, onSelectTab, onOpenHub }) => {
  return (
    <div className="fixed bottom-0 left-0 right-0 z-30 bg-[#0a0a0a]/95 backdrop-blur-md border-t border-slate-800/80">
      <div className="max-w-md mx-auto flex items-center justify-around py-2 px-2">
        {/* Vyshu Chat */}
        <button
          onClick={() => onSelectTab('vyshu')}
          className={`flex flex-col items-center py-1.5 px-3 rounded-2xl transition ${
            currentTab === 'vyshu'
              ? 'text-cyan-400 bg-cyan-500/10 font-bold'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <MessageSquare className="w-5 h-5 mb-1" />
          <span className="text-[10px] tracking-wide">Vyshu</span>
        </button>

        {/* Virtual Room with AI Interference */}
        <button
          onClick={() => onSelectTab('room')}
          className={`flex flex-col items-center py-1.5 px-3 rounded-2xl transition relative ${
            currentTab === 'room'
              ? 'text-purple-400 bg-purple-500/15 font-bold shadow-md shadow-purple-500/20 glow-purple'
              : 'text-slate-400 hover:text-purple-300'
          }`}
        >
          <div className="relative">
            <Eye className="w-5 h-5 mb-1 text-purple-400" />
            <span className="absolute -top-0.5 -right-1 w-2 h-2 rounded-full bg-cyan-400 animate-ping" />
          </div>
          <span className="text-[10px] tracking-wide">3D Room</span>
        </button>

        {/* Control Panel */}
        <button
          onClick={() => onSelectTab('control')}
          className={`flex flex-col items-center py-1.5 px-3 rounded-2xl transition ${
            currentTab === 'control'
              ? 'text-cyan-400 bg-cyan-500/10 font-bold'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Sliders className="w-5 h-5 mb-1" />
          <span className="text-[10px] tracking-wide">Control</span>
        </button>

        {/* Feature Hub Trigger */}
        <button
          onClick={onOpenHub}
          className="flex flex-col items-center py-1.5 px-3 rounded-2xl text-slate-400 hover:text-cyan-300 transition"
        >
          <LayoutGrid className="w-5 h-5 mb-1 text-cyan-400" />
          <span className="text-[10px] tracking-wide">Tools</span>
        </button>

        {/* Vault Keys */}
        <button
          onClick={() => onSelectTab('vault')}
          className={`flex flex-col items-center py-1.5 px-3 rounded-2xl transition ${
            currentTab === 'vault'
              ? 'text-cyan-400 bg-cyan-500/10 font-bold'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <KeyRound className="w-5 h-5 mb-1" />
          <span className="text-[10px] tracking-wide">Vault</span>
        </button>
      </div>
    </div>
  );
};
