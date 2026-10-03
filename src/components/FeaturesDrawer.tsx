import React, { useState } from 'react';
import {
  Globe,
  Dumbbell,
  Newspaper,
  Music,
  Phone,
  Calculator,
  Calendar,
  X,
  Sparkles,
} from 'lucide-react';
import { LanguagesModal } from './features/LanguagesModal';
import { SecretaryDashboard } from './features/SecretaryDashboard';
import { AthleteModeView } from './features/AthleteModeView';
import { FitnessTracker } from './features/FitnessTracker';
import { NewsReader } from './features/NewsReader';
import { MusicPlayer } from './features/MusicPlayer';
import { ContactsDialer } from './features/ContactsDialer';
import { VoiceCalculator } from './features/VoiceCalculator';
import { TaskManager } from './features/TaskManager';
import { CustomizationStudio } from './features/CustomizationStudio';
import { CallShield } from './features/CallShield';
import { LanguageInfo } from '../types';

interface FeaturesDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  initialTab?: 'secretary' | 'athlete' | 'languages' | 'fitness' | 'news' | 'music' | 'contacts' | 'calculator' | 'tasks' | 'customization' | 'callshield';
  onAskVyshu?: (query: string) => void;
}

export const FeaturesDrawer: React.FC<FeaturesDrawerProps> = ({
  isOpen,
  onClose,
  initialTab = 'secretary',
  onAskVyshu,
}) => {
  const [activeTab, setActiveTab] = useState<
    'secretary' | 'athlete' | 'languages' | 'fitness' | 'news' | 'music' | 'contacts' | 'calculator' | 'tasks' | 'customization' | 'callshield'
  >(initialTab);

  if (!isOpen) return null;

  const tabs = [
    { id: 'secretary', label: 'Executive Secretary', icon: Calendar },
    { id: 'athlete', label: 'Athlete Coach', icon: Dumbbell },
    { id: 'callshield', label: 'AI Call Shield', icon: Sparkles },
    { id: 'customization', label: 'Studio & Themes', icon: Sparkles },
    { id: 'languages', label: '18 Languages', icon: Globe },
    { id: 'fitness', label: 'Quick Workout Log', icon: Dumbbell },
    { id: 'news', label: 'News & Audio', icon: Newspaper },
    { id: 'music', label: 'Vaani Music Bot', icon: Music },
    { id: 'contacts', label: 'Contacts & Calls', icon: Phone },
    { id: 'calculator', label: 'Voice Calculator', icon: Calculator },
    { id: 'tasks', label: 'Tasks & Calendar', icon: Calendar },
  ] as const;

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex flex-col justify-end sm:justify-center p-0 sm:p-4 animate-fade-in">
      <div className="bg-[#05050f] border border-cyan-500/30 rounded-t-3xl sm:rounded-3xl max-w-2xl w-full mx-auto max-h-[90vh] flex flex-col shadow-2xl overflow-hidden glow-cyan">
        {/* Header */}
        <div className="p-4 px-5 border-b border-slate-800/80 flex items-center justify-between bg-[#0b0b16]">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-lg bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400">
              <Sparkles className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-white uppercase tracking-wider">Vyshu AI Secretary Hub</h2>
              <p className="text-[11px] text-cyan-400 font-mono">Tools, Automation &amp; Multi-Features</p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-400 hover:text-white transition"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Tab Selector pills */}
        <div className="flex overflow-x-auto gap-1.5 p-3 px-4 bg-[#080814] border-b border-slate-800/60 no-scrollbar">
          {tabs.map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap flex items-center gap-1.5 transition ${
                activeTab === id
                  ? 'bg-cyan-400 text-slate-950 font-bold shadow-sm shadow-cyan-500/20'
                  : 'bg-[#0e1422] text-slate-400 hover:text-slate-200 border border-slate-800/60'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              {label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        <div className="p-5 overflow-y-auto flex-1">
          {activeTab === 'secretary' && <SecretaryDashboard onAskVyshu={onAskVyshu} />}

          {activeTab === 'athlete' && <AthleteModeView onAskVyshu={onAskVyshu} />}

          {activeTab === 'callshield' && <CallShield onAskVyshu={onAskVyshu} />}

          {activeTab === 'customization' && <CustomizationStudio />}

          {activeTab === 'languages' && (
            <LanguagesModal
              onAskTime={(city, time) => {
                onClose();
                if (onAskVyshu) onAskVyshu(`What time is it in ${city}?`);
              }}
            />
          )}

          {activeTab === 'fitness' && <FitnessTracker />}

          {activeTab === 'news' && <NewsReader />}

          {activeTab === 'music' && <MusicPlayer />}

          {activeTab === 'contacts' && <ContactsDialer />}

          {activeTab === 'calculator' && <VoiceCalculator />}

          {activeTab === 'tasks' && <TaskManager />}
        </div>
      </div>
    </div>
  );
};
