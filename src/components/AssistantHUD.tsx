import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Clock,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  MoveRight,
  Shield,
  Layers,
  Sparkles,
} from 'lucide-react';
import { taskScheduleManager } from '../services/assistant/TaskScheduleManager';
import { modeManager } from '../services/assistant/ModeManager';
import { ScheduledTask, VyshuMode } from '../types/assistant';

interface AssistantHUDProps {
  onOpenSchedule?: () => void;
  onSelectPrompt?: (text: string) => void;
}

export const AssistantHUD: React.FC<AssistantHUDProps> = ({ onSelectPrompt }) => {
  const [tasks, setTasks] = useState<ScheduledTask[]>([]);
  const [activeMode, setActiveMode] = useState<VyshuMode>('HOME');

  useEffect(() => {
    setTasks(taskScheduleManager.getTodayTasks());
    setActiveMode(modeManager.getMode());

    const interval = setInterval(() => {
      setTasks(taskScheduleManager.getTodayTasks());
      setActiveMode(modeManager.getMode());
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  const pending = tasks.filter((t) => t.status === 'pending' || t.status === 'postponed');
  const nextTask = pending[0];

  const getModeBadge = (m: VyshuMode) => {
    switch (m) {
      case 'PROFESSIONAL':
        return { label: 'OFFICE / SIR', color: 'bg-purple-500/20 text-purple-300 border-purple-500/40' };
      case 'HOME':
        return { label: 'HOME / BUDDY', color: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40' };
      case 'NORMAL':
        return { label: 'NORMAL / TEJA', color: 'bg-cyan-500/20 text-cyan-300 border-cyan-500/40' };
      case 'STANDBY':
        return { label: 'STANDBY', color: 'bg-slate-700/30 text-slate-400 border-slate-700' };
    }
  };

  const badge = getModeBadge(activeMode);

  return (
    <div className="bg-[#090d22]/95 border-b border-cyan-500/20 p-2.5 px-4 backdrop-blur-md flex flex-wrap items-center justify-between gap-2 text-xs">
      <div className="flex items-center gap-2">
        <span className={`px-2 py-0.5 rounded-full font-mono text-[10px] font-black border uppercase tracking-wider ${badge.color}`}>
          {badge.label}
        </span>

        {nextTask ? (
          <div className="flex items-center gap-1.5 text-slate-300">
            <Clock className="w-3.5 h-3.5 text-cyan-400" />
            <span className="font-semibold text-white">{nextTask.startTime || 'Next'}:</span>
            <span className="truncate max-w-[150px] sm:max-w-[220px] text-slate-200">{nextTask.title}</span>
            {nextTask.postponedCount > 0 && (
              <span className="text-[10px] text-amber-400 font-mono bg-amber-400/10 px-1 rounded">
                Postponed
              </span>
            )}
          </div>
        ) : (
          <span className="text-slate-400 flex items-center gap-1">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
            <span>All tasks completed today</span>
          </span>
        )}
      </div>

      <div className="flex items-center gap-1.5 overflow-x-auto">
        <button
          onClick={() => onSelectPrompt?.("What am I supposed to be doing now?")}
          className="px-2 py-1 rounded-lg bg-slate-800/80 hover:bg-cyan-500/20 text-slate-300 hover:text-cyan-300 border border-slate-700/60 text-[10px] transition whitespace-nowrap"
        >
          What's next?
        </button>
        <button
          onClick={() => onSelectPrompt?.("Move V3 testing to 9 PM.")}
          className="px-2 py-1 rounded-lg bg-slate-800/80 hover:bg-cyan-500/20 text-slate-300 hover:text-cyan-300 border border-slate-700/60 text-[10px] transition whitespace-nowrap"
        >
          Reschedule V3
        </button>
        <button
          onClick={() => onSelectPrompt?.("Switch to office mode.")}
          className="px-2 py-1 rounded-lg bg-slate-800/80 hover:bg-cyan-500/20 text-slate-300 hover:text-cyan-300 border border-slate-700/60 text-[10px] transition whitespace-nowrap"
        >
          Office Mode
        </button>
      </div>
    </div>
  );
};
