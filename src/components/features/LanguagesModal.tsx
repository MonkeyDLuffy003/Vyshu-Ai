import React, { useState } from 'react';
import { Globe, Clock, Volume2, Search, Check, Sparkles } from 'lucide-react';
import { SUPPORTED_18_LANGUAGES } from '../../constants/languages';
import { audioService } from '../../services/audioService';
import { storageService } from '../../services/storageService';
import { LanguageInfo } from '../../types';

interface LanguagesModalProps {
  onSelectLanguage?: (lang: LanguageInfo) => void;
  onAskTime?: (cityName: string, timeStr: string) => void;
}

export const LanguagesModal: React.FC<LanguagesModalProps> = ({ onSelectLanguage, onAskTime }) => {
  const [search, setSearch] = useState('');
  const [selectedLang, setSelectedLang] = useState(storageService.getSelectedLanguage());

  const filtered = SUPPORTED_18_LANGUAGES.filter(
    (l) =>
      l.name.toLowerCase().includes(search.toLowerCase()) ||
      l.nativeName.toLowerCase().includes(search.toLowerCase()) ||
      l.timezoneCity.toLowerCase().includes(search.toLowerCase())
  );

  const getTimeInZone = (tz: string) => {
    try {
      return new Intl.DateTimeFormat('en-US', {
        timeZone: tz,
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: true,
      }).format(new Date());
    } catch {
      return '--:--';
    }
  };

  const handleSpeakGreeting = (lang: LanguageInfo) => {
    audioService.speak(lang.sampleGreeting, lang.voiceLangCode);
  };

  const handleSelect = (lang: LanguageInfo) => {
    setSelectedLang(lang.code);
    storageService.setSelectedLanguage(lang.code);
    if (onSelectLanguage) onSelectLanguage(lang);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Globe className="w-4 h-4" /> 18 Languages &amp; Time Zones
          </h2>
          <p className="text-xs text-slate-400">
            Fluent multilingual support with Romanization and international time awareness.
          </p>
        </div>
      </div>

      {/* Search Input */}
      <div className="relative">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search language or city..."
          className="w-full bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-400"
        />
        <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
      </div>

      {/* Languages Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-h-[60vh] overflow-y-auto pr-1">
        {filtered.map((lang) => {
          const isCurrent = selectedLang === lang.code;
          const time = getTimeInZone(lang.timezone);
          return (
            <div
              key={lang.code}
              className={`p-3.5 rounded-2xl border transition relative ${
                isCurrent
                  ? 'bg-cyan-500/10 border-cyan-400/80 shadow-md shadow-cyan-500/10'
                  : 'bg-[#0b0b16] border-slate-800/80 hover:border-slate-700'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center space-x-2.5">
                  <span className="text-2xl">{lang.flag}</span>
                  <div>
                    <div className="text-sm font-bold text-white flex items-center gap-1.5">
                      {lang.name}
                      <span className="text-xs font-normal text-slate-400">({lang.nativeName})</span>
                    </div>
                    <div className="text-[11px] text-cyan-400/90 flex items-center gap-1">
                      <Clock className="w-3 h-3" /> {lang.timezoneCity}: <span className="font-mono font-semibold">{time}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-1">
                  <button
                    onClick={() => handleSpeakGreeting(lang)}
                    title="Pronounce greeting"
                    className="p-1.5 rounded-lg bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-cyan-300 transition"
                  >
                    <Volume2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => handleSelect(lang)}
                    title="Select language"
                    className={`p-1.5 rounded-lg transition ${
                      isCurrent
                        ? 'bg-cyan-400 text-slate-950 font-bold'
                        : 'bg-slate-800/80 text-slate-400 hover:text-white'
                    }`}
                  >
                    <Check className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Romanization guide */}
              <div className="mt-2.5 pt-2 border-t border-slate-800/60 text-[11px]">
                <div className="text-slate-400 font-medium">Romanized Script Sample:</div>
                <div className="text-slate-200 italic mt-0.5 font-mono text-[10px] bg-[#05050f] p-1.5 rounded-lg border border-slate-900">
                  &ldquo;{lang.romanizationSample}&rdquo;
                </div>
              </div>

              {onAskTime && (
                <button
                  onClick={() => onAskTime(lang.timezoneCity, time)}
                  className="mt-2 w-full py-1 text-[10px] font-semibold text-cyan-400 hover:text-cyan-300 bg-cyan-500/10 hover:bg-cyan-500/20 rounded-lg transition text-center"
                >
                  Ask Vyshu time in {lang.timezoneCity.split('/')[0]}
                </button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
