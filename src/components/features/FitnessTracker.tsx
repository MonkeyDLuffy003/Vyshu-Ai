import React, { useState, useEffect } from 'react';
import {
  Flame,
  Dumbbell,
  Trophy,
  Calendar,
  Plus,
  Play,
  Pause,
  RotateCcw,
  CheckCircle2,
  TrendingUp,
  Clock,
  Sparkles,
} from 'lucide-react';
import { storageService } from '../../services/storageService';
import { FitnessLog } from '../../types';
import { audioService } from '../../services/audioService';

export const FitnessTracker: React.FC = () => {
  const [logs, setLogs] = useState<FitnessLog[]>(storageService.getFitnessLogs());
  const [newType, setNewType] = useState('Full Body Workout');
  const [newDuration, setNewDuration] = useState(30);
  const [newCalories, setNewCalories] = useState(200);
  const [newNotes, setNewNotes] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);

  // Rest / Workout Stopwatch Timer
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);

  useEffect(() => {
    let interval: any = null;
    if (isTimerRunning) {
      interval = setInterval(() => {
        setTimerSeconds((prev) => prev + 1);
      }, 1000);
    } else {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning]);

  const streakDays = logs.filter((l) => l.completed).length;
  const totalCalories = logs.reduce((acc, l) => acc + (l.caloriesBurned || 0), 0);
  const totalMinutes = logs.reduce((acc, l) => acc + (l.durationMinutes || 0), 0);
  const consistencyRate = Math.min(100, Math.round((streakDays / Math.max(1, logs.length)) * 100));

  const handleAddWorkout = (e: React.FormEvent) => {
    e.preventDefault();
    const newLog: FitnessLog = {
      id: Date.now().toString(),
      date: new Date().toISOString().split('T')[0],
      dayNumber: logs.length + 1,
      workoutType: newType,
      durationMinutes: Number(newDuration),
      caloriesBurned: Number(newCalories),
      notes: newNotes || 'Workout logged with Vyshu AI',
      completed: true,
    };

    const updated = [newLog, ...logs];
    setLogs(updated);
    storageService.saveFitnessLogs(updated);
    setShowAddForm(false);
    setNewNotes('');
    audioService.playSound('send');
  };

  const formatTimer = (sec: number) => {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <div className="space-y-5">
      {/* Header Stats */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Dumbbell className="w-4 h-4" /> Teja&apos;s Workout Consistency Tracker
          </h2>
          <p className="text-xs text-slate-400">
            Started 4 days ago • Calculating daily adherence &amp; active calorie burn
          </p>
        </div>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="text-xs px-3 py-1.5 rounded-xl bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 flex items-center gap-1.5 transition active:scale-95"
        >
          <Plus className="w-3.5 h-3.5" /> Log Day {logs.length + 1}
        </button>
      </div>

      {/* Consistency Metrics Banner */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className="p-3.5 bg-[#0b0b16] border border-cyan-500/30 rounded-2xl glow-cyan">
          <div className="flex items-center justify-between text-cyan-400 mb-1">
            <span className="text-[11px] font-semibold uppercase">Active Streak</span>
            <Flame className="w-4 h-4 text-amber-400 animate-pulse" />
          </div>
          <div className="text-2xl font-black text-white">{streakDays} Days</div>
          <div className="text-[10px] text-emerald-400 font-medium">Unbroken streak!</div>
        </div>

        <div className="p-3.5 bg-[#0b0b16] border border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between text-slate-400 mb-1">
            <span className="text-[11px] font-semibold uppercase">Consistency</span>
            <TrendingUp className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-black text-emerald-400">{consistencyRate}%</div>
          <div className="text-[10px] text-slate-400">Target: &gt;90%</div>
        </div>

        <div className="p-3.5 bg-[#0b0b16] border border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between text-slate-400 mb-1">
            <span className="text-[11px] font-semibold uppercase">Total Burn</span>
            <Flame className="w-4 h-4 text-orange-400" />
          </div>
          <div className="text-2xl font-black text-white">{totalCalories}</div>
          <div className="text-[10px] text-slate-400">kCal recorded</div>
        </div>

        <div className="p-3.5 bg-[#0b0b16] border border-slate-800 rounded-2xl">
          <div className="flex items-center justify-between text-slate-400 mb-1">
            <span className="text-[11px] font-semibold uppercase">Total Time</span>
            <Clock className="w-4 h-4 text-cyan-400" />
          </div>
          <div className="text-2xl font-black text-white">{totalMinutes}</div>
          <div className="text-[10px] text-slate-400">active minutes</div>
        </div>
      </div>

      {/* Workout Stopwatch / Rest Timer */}
      <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-4 flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-cyan-500/10 flex items-center justify-center text-cyan-400">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs font-bold text-slate-200">Session / Rest Timer</div>
            <div className="text-xl font-mono font-bold text-cyan-400">{formatTimer(timerSeconds)}</div>
          </div>
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={() => {
              audioService.playSound('toggle');
              setIsTimerRunning(!isTimerRunning);
            }}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition ${
              isTimerRunning ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40' : 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40'
            }`}
          >
            {isTimerRunning ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
            {isTimerRunning ? 'Pause' : 'Start'}
          </button>
          <button
            onClick={() => {
              setIsTimerRunning(false);
              setTimerSeconds(0);
            }}
            className="p-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 transition"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Add Workout Form */}
      {showAddForm && (
        <form onSubmit={handleAddWorkout} className="bg-[#0e1422] border border-cyan-500/30 rounded-2xl p-4 space-y-3 animate-fade-in">
          <div className="text-xs font-bold text-cyan-400 uppercase tracking-wider">Log New Workout Entry</div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="text-[11px] text-slate-400 block mb-1">Workout Type</label>
              <select
                value={newType}
                onChange={(e) => setNewType(e.target.value)}
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400"
              >
                <option>Full Body Workout</option>
                <option>Pushups &amp; Core</option>
                <option>Dumbbells &amp; Arms</option>
                <option>Legs &amp; Squats</option>
                <option>Cardio &amp; Running</option>
                <option>Gym Strength Training</option>
              </select>
            </div>
            <div>
              <label className="text-[11px] text-slate-400 block mb-1">Duration (minutes)</label>
              <input
                type="number"
                min="5"
                max="240"
                value={newDuration}
                onChange={(e) => setNewDuration(Number(e.target.value))}
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400 font-mono"
              />
            </div>
            <div>
              <label className="text-[11px] text-slate-400 block mb-1">Calories Burned</label>
              <input
                type="number"
                min="10"
                max="2000"
                value={newCalories}
                onChange={(e) => setNewCalories(Number(e.target.value))}
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400 font-mono"
              />
            </div>
          </div>
          <div>
            <label className="text-[11px] text-slate-400 block mb-1">Session Notes</label>
            <input
              type="text"
              value={newNotes}
              onChange={(e) => setNewNotes(e.target.value)}
              placeholder="e.g. 50 pushups, 4 sets dumbbell curls..."
              className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400"
            />
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => setShowAddForm(false)}
              className="px-3 py-1.5 rounded-xl bg-slate-800 text-slate-400 text-xs font-semibold hover:bg-slate-700"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 rounded-xl bg-cyan-400 text-slate-950 text-xs font-bold hover:bg-cyan-300"
            >
              Save Workout
            </button>
          </div>
        </form>
      )}

      {/* Workout Logs List */}
      <div className="space-y-2">
        <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider px-1">
          Consistency Log (Days 1 to {logs.length})
        </div>
        <div className="space-y-2.5 max-h-[40vh] overflow-y-auto pr-1">
          {logs.map((log) => (
            <div
              key={log.id}
              className="p-3.5 bg-[#0b0b16] border border-slate-800/80 rounded-2xl flex items-center justify-between hover:border-slate-700 transition"
            >
              <div className="flex items-center space-x-3">
                <div className="w-9 h-9 rounded-xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center font-bold text-cyan-400 text-xs">
                  D{log.dayNumber}
                </div>
                <div>
                  <div className="text-xs font-bold text-slate-200 flex items-center gap-2">
                    {log.workoutType}
                    <span className="text-[10px] text-emerald-400 flex items-center gap-0.5">
                      <CheckCircle2 className="w-3 h-3" /> Completed
                    </span>
                  </div>
                  <div className="text-[11px] text-slate-400 mt-0.5">{log.notes}</div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-xs font-mono font-bold text-cyan-300">{log.durationMinutes} min</div>
                <div className="text-[10px] font-mono text-amber-400">{log.caloriesBurned} kcal</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
