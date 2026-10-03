import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Clock,
  CheckCircle2,
  Bell,
  AlarmClock,
  Briefcase,
  AlertCircle,
  Plus,
  ChevronRight,
  UserCheck,
  Shield,
  Layers,
  Sparkles,
  PhoneCall,
  CalendarCheck,
  BookmarkCheck,
} from 'lucide-react';
import { secretaryDataManager } from '../../services/assistant/SecretaryDataManager';
import { modeManager } from '../../services/assistant/ModeManager';
import { memoryManager } from '../../services/assistant/MemoryManager';
import {
  ScheduledTask,
  SecretaryAlarm,
  SecretaryReminder,
  AppointmentRecord,
  FollowUpItem,
  PersonalMemory,
  VyshuMode,
} from '../../types/assistant';

interface SecretaryDashboardProps {
  onAskVyshu?: (query: string) => void;
}

export const SecretaryDashboard: React.FC<SecretaryDashboardProps> = ({ onAskVyshu }) => {
  const [activeTab, setActiveTab] = useState<'today' | 'upcoming' | 'memory' | 'alarms'>('today');
  const [tasks, setTasks] = useState<ScheduledTask[]>([]);
  const [alarms, setAlarms] = useState<SecretaryAlarm[]>([]);
  const [reminders, setReminders] = useState<SecretaryReminder[]>([]);
  const [appointments, setAppointments] = useState<AppointmentRecord[]>([]);
  const [followUps, setFollowUps] = useState<FollowUpItem[]>([]);
  const [activeMode, setActiveMode] = useState<VyshuMode>('HOME');

  const reloadData = () => {
    setTasks(secretaryDataManager.getTodayTasks());
    setAlarms(secretaryDataManager.getAlarms());
    setReminders(secretaryDataManager.getReminders());
    setAppointments(secretaryDataManager.getAppointments());
    setFollowUps(secretaryDataManager.getFollowUps());
    setActiveMode(modeManager.getMode());
  };

  useEffect(() => {
    reloadData();
    const interval = setInterval(reloadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleToggleTask = (task: ScheduledTask) => {
    if (task.status === 'completed') {
      // Toggle back to pending
      const all = secretaryDataManager.getTasks();
      const target = all.find((t: ScheduledTask) => t.id === task.id);
      if (target) {
        target.status = 'pending';
        secretaryDataManager.saveTasks(all);
        reloadData();
      }
    } else {
      secretaryDataManager.completeTask(task.id);
      reloadData();
    }
  };

  const handleToggleAlarm = (id: string) => {
    secretaryDataManager.toggleAlarm(id);
    reloadData();
  };

  const pendingTasks = tasks.filter((t) => t.status !== 'completed');
  const completedTasks = tasks.filter((t) => t.status === 'completed');

  return (
    <div className="flex flex-col h-full bg-[#070b18] text-slate-100 overflow-y-auto p-4 sm:p-5">
      {/* Top Secretary Header */}
      <div className="rounded-2xl p-4 sm:p-5 bg-gradient-to-r from-[#0d1636] via-[#091129] to-[#060a1c] border border-cyan-500/30 mb-4 shadow-xl flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 font-mono">
              EXECUTIVE SECRETARY • MODE: {activeMode}
            </span>
            <span className="text-[10px] text-slate-400 font-mono">Teja Private System</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-white flex items-center gap-2">
            <span>DAILY SECRETARY COORDINATOR</span>
          </h2>
          <p className="text-xs text-slate-300 mt-0.5 max-w-lg leading-relaxed">
            Continuously managing your commitments, tasks, alarms, appointments, and follow-ups.
          </p>
        </div>

        {/* Quick Briefing Button */}
        {onAskVyshu && (
          <button
            onClick={() => onAskVyshu("Vyshu, what's my day? Give me my morning briefing.")}
            className="px-4 py-2.5 rounded-xl text-xs font-bold bg-cyan-500 text-slate-950 hover:bg-cyan-400 transition flex items-center justify-center gap-2 shadow-lg shadow-cyan-500/20"
          >
            <Sparkles className="w-4 h-4 text-slate-950" />
            <span>Morning Briefing Aloud</span>
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900/90 border border-slate-800 mb-4 overflow-x-auto">
        {[
          { id: 'today', label: `Today's Schedule (${pendingTasks.length})`, icon: Calendar },
          { id: 'upcoming', label: `Appointments & Follow-ups`, icon: CalendarCheck },
          { id: 'alarms', label: `Alarms & Reminders (${alarms.filter((a) => a.enabled).length})`, icon: AlarmClock },
          { id: 'memory', label: `Assistant Memory`, icon: BookmarkCheck },
        ].map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex-1 min-w-[120px] py-2 px-3 rounded-lg text-xs font-bold transition flex items-center justify-center gap-1.5 ${
                activeTab === tab.id
                  ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* TAB 1: TODAY'S SCHEDULE & COMMITMENTS */}
      {activeTab === 'today' && (
        <div className="space-y-4">
          {/* Active Schedule Flow */}
          <div className="bg-[#090e24] border border-cyan-500/20 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center justify-between pb-3 mb-3 border-b border-slate-800">
              <span className="text-xs font-black text-cyan-400 uppercase tracking-wider font-mono">
                Planned Schedule for Today
              </span>
              <span className="text-xs text-slate-400 font-mono">
                {pendingTasks.length} Pending • {completedTasks.length} Done
              </span>
            </div>

            <div className="space-y-2.5">
              {tasks.length === 0 ? (
                <div className="text-center py-6 text-slate-400 text-xs">
                  No scheduled activities for today yet.
                </div>
              ) : (
                tasks.map((task) => (
                  <div
                    key={task.id}
                    onClick={() => handleToggleTask(task)}
                    className={`p-3 rounded-xl border transition flex items-center justify-between gap-3 cursor-pointer ${
                      task.status === 'completed'
                        ? 'bg-emerald-950/20 border-emerald-500/30 opacity-70'
                        : 'bg-slate-900/80 border-slate-800/80 hover:border-cyan-500/40'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-5 h-5 rounded-full border flex items-center justify-center transition shrink-0 ${
                          task.status === 'completed'
                            ? 'bg-emerald-500 border-emerald-400 text-slate-950'
                            : 'border-slate-600 hover:border-cyan-400'
                        }`}
                      >
                        {task.status === 'completed' && <CheckCircle2 className="w-3.5 h-3.5" />}
                      </div>

                      <div>
                        <div className="flex items-center gap-2">
                          <span
                            className={`text-xs font-bold ${
                              task.status === 'completed' ? 'line-through text-slate-400' : 'text-white'
                            }`}
                          >
                            {task.title}
                          </span>
                          {task.postponedCount > 0 && (
                            <span className="px-1.5 py-0.5 rounded text-[9px] font-mono bg-amber-500/20 text-amber-300 border border-amber-500/30">
                              Postponed {task.postponedCount}x
                            </span>
                          )}
                        </div>
                        {task.description && (
                          <p className="text-[11px] text-slate-400 mt-0.5">{task.description}</p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <span className="text-xs font-mono font-bold text-cyan-300 bg-cyan-500/10 px-2 py-0.5 rounded border border-cyan-500/20">
                        {task.startTime || 'Anytime'}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: APPOINTMENTS & FOLLOW-UPS */}
      {activeTab === 'upcoming' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Appointments Block */}
          <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center gap-2 text-xs font-black text-cyan-400 uppercase tracking-wider mb-3 font-mono">
              <CalendarCheck className="w-4 h-4" />
              <span>Confirmed Appointments & Bookings</span>
            </div>

            <div className="space-y-2.5">
              {appointments.map((apt) => (
                <div key={apt.id} className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-white">{apt.name}</span>
                    <span className="text-[11px] font-mono text-cyan-300 bg-cyan-500/10 px-2 py-0.5 rounded border border-cyan-500/20">
                      {apt.date} • {apt.time}
                    </span>
                  </div>
                  {apt.location && <div className="text-[11px] text-slate-400 mt-1">📍 {apt.location}</div>}
                  {apt.contactPerson && <div className="text-[11px] text-slate-400">👤 {apt.contactPerson}</div>}
                </div>
              ))}
            </div>
          </div>

          {/* Follow-up Secretary Block */}
          <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center gap-2 text-xs font-black text-purple-400 uppercase tracking-wider mb-3 font-mono">
              <PhoneCall className="w-4 h-4" />
              <span>Follow-ups Required</span>
            </div>

            <div className="space-y-2.5">
              {followUps.map((fol) => (
                <div key={fol.id} className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-white">{fol.title}</span>
                    <span className="text-[10px] font-mono text-purple-300 bg-purple-500/10 px-1.5 py-0.5 rounded border border-purple-500/20">
                      Due: {fol.targetDate}
                    </span>
                  </div>
                  {fol.contactPerson && (
                    <div className="text-[11px] text-slate-400 mt-1">Contact: {fol.contactPerson}</div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: ALARMS & REMINDERS */}
      {activeTab === 'alarms' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Alarms Block */}
          <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2 text-xs font-black text-emerald-400 uppercase tracking-wider font-mono">
                <AlarmClock className="w-4 h-4" />
                <span>Executive Alarms</span>
              </div>
            </div>

            <div className="space-y-2.5">
              {alarms.map((alm) => (
                <div
                  key={alm.id}
                  className="p-3 rounded-xl bg-slate-900/80 border border-slate-800 flex items-center justify-between"
                >
                  <div>
                    <span className="text-base font-black text-white font-mono">{alm.time}</span>
                    <div className="text-[11px] text-slate-400">{alm.label}</div>
                  </div>
                  <button
                    onClick={() => handleToggleAlarm(alm.id)}
                    className={`px-3 py-1 rounded-xl text-xs font-bold border transition ${
                      alm.enabled
                        ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40'
                        : 'bg-slate-800 text-slate-500 border-slate-700'
                    }`}
                  >
                    {alm.enabled ? 'ON' : 'OFF'}
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Reminders Block */}
          <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center gap-2 text-xs font-black text-amber-400 uppercase tracking-wider mb-3 font-mono">
              <Bell className="w-4 h-4" />
              <span>Active Reminders</span>
            </div>

            <div className="space-y-2.5">
              {reminders.map((rem) => (
                <div key={rem.id} className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
                  <div className="text-xs font-bold text-white">{rem.message}</div>
                  <div className="text-[10px] text-slate-400 font-mono mt-1">
                    Trigger: {rem.triggerTime} {rem.condition ? `(${rem.condition})` : ''}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 4: ASSISTANT MEMORY */}
      {activeTab === 'memory' && (
        <div className="space-y-4">
          <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
            <div className="flex items-center gap-2 text-xs font-black text-cyan-400 uppercase tracking-wider mb-3 font-mono">
              <BookmarkCheck className="w-4 h-4" />
              <span>Long-Term Personal & Project Memories</span>
            </div>
            <p className="text-xs text-slate-300 mb-3 leading-relaxed">
              Vyshu only remembers what you explicitly ask her to remember ("Vyshu, remember this").
            </p>

            <div className="space-y-2 text-xs text-slate-300">
              {memoryManager.getPersonalMemories().map((mem: PersonalMemory) => (
                <div key={mem.id} className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
                  <strong className="text-white capitalize">{mem.key.replace(/_/g, ' ')}:</strong>
                  <span className="text-slate-300 ml-2">{mem.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
