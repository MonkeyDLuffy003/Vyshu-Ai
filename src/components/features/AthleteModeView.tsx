import React, { useState, useEffect } from 'react';
import {
  Activity,
  Flame,
  Droplets,
  Utensils,
  Trophy,
  CheckCircle2,
  Calendar,
  Clock,
  Sparkles,
  ArrowRight,
  ChevronRight,
  TrendingDown,
  ShieldAlert,
  Play,
  Pause,
  RotateCcw,
  Info,
  Layers,
  Heart,
  UserCheck,
} from 'lucide-react';
import { storageService } from '../../services/storageService';
import { audioService } from '../../services/audioService';
import { AthleteProfile, DEFAULT_ATHLETE_PROFILE } from '../../types/athlete';

interface AthleteModeViewProps {
  onAskVyshu?: (query: string) => void;
}

export const AthleteModeView: React.FC<AthleteModeViewProps> = ({ onAskVyshu }) => {
  const [profile, setProfile] = useState<AthleteProfile>(() => {
    const saved = storageService.getAthleteProfile();
    return saved || DEFAULT_ATHLETE_PROFILE;
  });

  const [activeTab, setActiveTab] = useState<'plan' | 'nutrition' | 'phases' | 'inspiration'>('plan');
  const [selectedDayIndex, setSelectedDayIndex] = useState(0);

  // Rest / Workout Stopwatch
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);

  useEffect(() => {
    storageService.saveAthleteProfile(profile);
  }, [profile]);

  useEffect(() => {
    let interval: any = null;
    if (isTimerRunning) {
      interval = setInterval(() => setTimerSeconds((s) => s + 1), 1000);
    } else {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning]);

  const formatTimer = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const handleToggleExerciseComplete = (dayIdx: number) => {
    setProfile((prev) => {
      const schedule = [...prev.weeklySchedule];
      const isDone = !schedule[dayIdx].completed;
      schedule[dayIdx] = { ...schedule[dayIdx], completed: isDone };
      const newCompleted = isDone ? prev.completedWorkouts + 1 : Math.max(0, prev.completedWorkouts - 1);
      const newStreak = isDone ? prev.streakDays + 1 : Math.max(0, prev.streakDays - 1);

      if (isDone) {
        audioService.speak(
          `Outstanding work today, Teja! Day ${schedule[dayIdx].day} session logged. Keep hydration high and muscles recovering.`,
          'en-IN'
        );
      }

      return {
        ...prev,
        weeklySchedule: schedule,
        completedWorkouts: newCompleted,
        streakDays: newStreak,
        lastWorkoutDate: new Date().toISOString(),
      };
    });
  };

  const handleAddWater = (amount: number) => {
    setProfile((prev) => {
      const updated = Math.min(prev.waterGoalLiters, +(prev.waterCurrentLiters + amount).toFixed(1));
      if (updated >= prev.waterGoalLiters) {
        audioService.speak("Goal crushed, Teja! Optimal hydration reached for fat metabolism and recovery.", "en-IN");
      }
      return { ...prev, waterCurrentLiters: updated };
    });
  };

  const currentDay = profile.weeklySchedule[selectedDayIndex];

  return (
    <div className="flex flex-col h-full bg-[#070b18] text-slate-100 overflow-y-auto p-4 sm:p-5">
      {/* Top Banner: Vyshu Athlete Coach */}
      <div className="relative rounded-2xl p-4 sm:p-5 bg-gradient-to-r from-emerald-950/60 via-cyan-950/50 to-slate-900 border border-emerald-500/30 mb-4 shadow-xl overflow-hidden">
        <div className="absolute top-0 right-0 p-4 opacity-10 pointer-events-none">
          <Activity className="w-32 h-32 text-emerald-400" />
        </div>
        <div className="relative z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                Phase {profile.currentPhase} • Foundation Week {profile.currentWeek}
              </span>
              <span className="text-[10px] text-slate-400 font-mono">
                Streak: {profile.streakDays} Days 🔥
              </span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black tracking-tight text-white flex items-center gap-2">
              <span>VYSHU ATHLETE COACH</span>
            </h2>
            <p className="text-xs text-slate-300 max-w-lg mt-0.5 leading-relaxed">
              Target: <span className="text-emerald-300 font-medium">{profile.targetLook}</span>. Built on the core philosophy: <span className="italic text-cyan-300">"Build muscle that you can use."</span>
            </p>
          </div>

          {/* Quick Metrics Bar */}
          <div className="flex items-center gap-2 sm:gap-3 bg-black/40 backdrop-blur-md p-2.5 px-3 rounded-xl border border-slate-800">
            <div className="text-center">
              <div className="text-[10px] text-slate-400 uppercase font-mono">Weight</div>
              <div className="text-sm font-extrabold text-white">{profile.weightKg} kg</div>
            </div>
            <div className="w-[1px] h-6 bg-slate-800" />
            <div className="text-center">
              <div className="text-[10px] text-slate-400 uppercase font-mono">Height</div>
              <div className="text-sm font-extrabold text-white">{profile.heightCm} cm</div>
            </div>
            <div className="w-[1px] h-6 bg-slate-800" />
            <div className="text-center">
              <div className="text-[10px] text-slate-400 uppercase font-mono">Sessions</div>
              <div className="text-sm font-extrabold text-emerald-400">{profile.completedWorkouts}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Sub-Tabs */}
      <div className="flex items-center gap-1.5 p-1 rounded-xl bg-slate-900/90 border border-slate-800 mb-4 overflow-x-auto">
        <button
          onClick={() => setActiveTab('plan')}
          className={`flex-1 min-w-[90px] py-2 px-3 rounded-lg text-xs font-bold transition flex items-center justify-center gap-1.5 ${
            activeTab === 'plan'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>Weekly Routine</span>
        </button>

        <button
          onClick={() => setActiveTab('nutrition')}
          className={`flex-1 min-w-[90px] py-2 px-3 rounded-lg text-xs font-bold transition flex items-center justify-center gap-1.5 ${
            activeTab === 'nutrition'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Utensils className="w-3.5 h-3.5" />
          <span>Indian Home Diet</span>
        </button>

        <button
          onClick={() => setActiveTab('phases')}
          className={`flex-1 min-w-[90px] py-2 px-3 rounded-lg text-xs font-bold transition flex items-center justify-center gap-1.5 ${
            activeTab === 'phases'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Layers className="w-3.5 h-3.5" />
          <span>3-Phase Roadmap</span>
        </button>

        <button
          onClick={() => setActiveTab('inspiration')}
          className={`flex-1 min-w-[90px] py-2 px-3 rounded-lg text-xs font-bold transition flex items-center justify-center gap-1.5 ${
            activeTab === 'inspiration'
              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Trophy className="w-3.5 h-3.5" />
          <span>Target Physique</span>
        </button>
      </div>

      {/* TAB 1: WEEKLY ROUTINE & WORKOUT TRACKER */}
      {activeTab === 'plan' && (
        <div className="space-y-4">
          {/* Day Selector Strip */}
          <div className="grid grid-cols-7 gap-1.5">
            {profile.weeklySchedule.map((item, idx) => (
              <button
                key={item.day}
                onClick={() => setSelectedDayIndex(idx)}
                className={`py-2 px-1 rounded-xl text-center border transition flex flex-col items-center ${
                  selectedDayIndex === idx
                    ? 'bg-emerald-500/25 border-emerald-400 text-white shadow-md'
                    : item.completed
                    ? 'bg-emerald-950/30 border-emerald-500/40 text-emerald-300'
                    : 'bg-slate-900/60 border-slate-800 text-slate-400 hover:border-slate-700'
                }`}
              >
                <span className="text-[10px] font-mono uppercase">{item.day.slice(0, 3)}</span>
                <span className="text-xs font-black mt-0.5">
                  {item.completed ? '✓' : idx + 1}
                </span>
              </button>
            ))}
          </div>

          {/* Selected Workout Card */}
          <div className="bg-[#090e24] border border-cyan-500/30 rounded-2xl p-4 sm:p-5 relative shadow-lg">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 mb-3 border-b border-slate-800 gap-2">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-extrabold text-cyan-400 uppercase tracking-wider font-mono">
                    {currentDay.day} Session
                  </span>
                  {currentDay.isRest && (
                    <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">
                      Active Recovery
                    </span>
                  )}
                </div>
                <h3 className="text-lg font-black text-white mt-0.5">{currentDay.focus}</h3>
                <span className="text-xs text-slate-400 flex items-center gap-1 mt-0.5">
                  <Clock className="w-3.5 h-3.5 text-cyan-400" />
                  Estimated Time: {currentDay.duration} • Zero equipment needed
                </span>
              </div>

              {/* Complete Toggle Button */}
              <button
                onClick={() => handleToggleExerciseComplete(selectedDayIndex)}
                className={`px-4 py-2.5 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 shadow-md ${
                  currentDay.completed
                    ? 'bg-emerald-500 text-slate-950 font-black'
                    : 'bg-slate-800 hover:bg-emerald-500/20 text-slate-200 hover:text-emerald-300 border border-slate-700'
                }`}
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>{currentDay.completed ? 'Completed Today!' : 'Mark Completed'}</span>
              </button>
            </div>

            {/* Exercises List */}
            <div className="space-y-2.5">
              <span className="text-[11px] font-mono text-slate-400 uppercase tracking-wider">Prescribed Movements</span>
              {currentDay.exercises.map((ex, i) => (
                <div
                  key={i}
                  className="flex items-start gap-3 p-3 rounded-xl bg-slate-900/80 border border-slate-800/80 hover:border-cyan-500/40 transition"
                >
                  <div className="w-5 h-5 rounded-full bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-[10px] font-bold text-cyan-300 shrink-0 mt-0.5">
                    {i + 1}
                  </div>
                  <div className="flex-1 text-xs text-slate-200 font-medium leading-relaxed">
                    {ex}
                  </div>
                </div>
              ))}
            </div>

            {/* Rest & Set Stopwatch */}
            <div className="mt-4 pt-4 border-t border-slate-800/80 flex flex-wrap items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-emerald-400" />
                <span className="text-xs font-bold text-slate-300">Rest Timer:</span>
                <span className="font-mono text-sm font-black text-emerald-400 bg-black/50 px-2.5 py-1 rounded-lg border border-emerald-500/30">
                  {formatTimer(timerSeconds)}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsTimerRunning(!isTimerRunning)}
                  className="px-3 py-1.5 rounded-lg text-xs font-bold bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-300 border border-emerald-500/40 flex items-center gap-1 transition"
                >
                  {isTimerRunning ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
                  <span>{isTimerRunning ? 'Pause' : 'Start (60s Rest)'}</span>
                </button>
                <button
                  onClick={() => {
                    setIsTimerRunning(false);
                    setTimerSeconds(0);
                  }}
                  className="p-1.5 rounded-lg text-slate-400 hover:text-white bg-slate-800 transition"
                  title="Reset"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>

          {/* Daily Hydration Progress */}
          <div className="bg-[#090e24] border border-cyan-500/20 rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-cyan-500/15 text-cyan-400 border border-cyan-500/30">
                <Droplets className="w-6 h-6" />
              </div>
              <div>
                <div className="text-xs font-bold text-white flex items-center gap-2">
                  <span>Hydration Target: {profile.waterGoalLiters} Liters</span>
                  <span className="text-[10px] text-cyan-300 font-mono">({profile.waterCurrentLiters}L so far)</span>
                </div>
                <div className="w-48 sm:w-60 bg-slate-800 h-2 rounded-full mt-1.5 overflow-hidden">
                  <div
                    className="bg-cyan-400 h-full rounded-full transition-all duration-300"
                    style={{ width: `${Math.min(100, (profile.waterCurrentLiters / profile.waterGoalLiters) * 100)}%` }}
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => handleAddWater(0.25)}
                className="px-3 py-1.5 rounded-xl text-xs font-bold bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 hover:bg-cyan-500/30 transition"
              >
                +250ml Glass
              </button>
              <button
                onClick={() => handleAddWater(0.5)}
                className="px-3 py-1.5 rounded-xl text-xs font-bold bg-cyan-500 text-slate-950 hover:bg-cyan-400 transition"
              >
                +500ml Bottle
              </button>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: NUTRITION STRATEGY (HOME-COOKED INDIAN MEALS) */}
      {activeTab === 'nutrition' && (
        <div className="space-y-4">
          <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-start gap-3">
            <Utensils className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
            <div className="text-xs text-slate-200 leading-relaxed">
              <strong className="text-amber-300">Core Nutrition Principle:</strong> No fancy diets or expensive supplements. Keep eating mom's home-cooked food, but apply the <span className="text-white font-bold">Rice Plate Rule</span> to trim abdominal fat while building lean shoulder/chest muscle.
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {/* The Rice Adjustment Strategy */}
            <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
              <div className="flex items-center gap-2 text-xs font-black text-emerald-400 uppercase tracking-wider mb-2 font-mono">
                <TrendingDown className="w-4 h-4" />
                <span>The Rice Plate Shift</span>
              </div>
              <p className="text-xs text-slate-300 leading-relaxed mb-3">
                Since rice is currently consumed in large portions, do not cut it cold turkey. Use the 25% swap method:
              </p>
              <div className="space-y-2 text-xs text-slate-300">
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <strong className="text-white">1. Cut 1/4th of the rice pile:</strong> Replace that space on your plate with thick Dal, Sambar, or Chana/Rajma.
                </div>
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <strong className="text-white">2. Eat Cucumbers & Tomatoes First:</strong> 5 minutes before lunch/dinner, eat 1 raw cucumber or tomato slice. It blunts insulin spikes and prevents overeating rice.
                </div>
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <strong className="text-white">3. Add 2 Boiled Eggs or 50g Paneer:</strong> Inexpensive protein to preserve muscle while shedding hip/abdominal fat.
                </div>
              </div>
            </div>

            {/* Beginner Indian Meal Blueprint */}
            <div className="bg-[#090e24] border border-slate-800 rounded-2xl p-4 shadow-lg">
              <div className="flex items-center gap-2 text-xs font-black text-cyan-400 uppercase tracking-wider mb-2 font-mono">
                <Utensils className="w-4 h-4" />
                <span>Everyday Meal Blueprint</span>
              </div>
              <div className="space-y-2 text-xs text-slate-300">
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <span className="text-cyan-300 font-bold">Morning / Breakfast:</span> 2-3 Idlis with peanut chutney + 2 boiled eggs (or sprouted moong dal).
                </div>
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <span className="text-cyan-300 font-bold">Afternoon Lunch:</span> Moderate rice portion + thick Dal / Chicken curry + curd (dahi) + vegetable curry.
                </div>
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <span className="text-cyan-300 font-bold">Evening Snack:</span> Roasted chana, buttermilk (chaas), or black coffee/tea with less sugar.
                </div>
                <div className="p-2.5 rounded-xl bg-slate-900/80 border border-slate-800">
                  <span className="text-cyan-300 font-bold">Dinner (Early):</span> 2 Rotis with sabzi & dal, or lighter rice bowl with paneer/eggs. Stop eating 2.5 hrs before bed.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB 3: 3-PHASE PROGRESSION ROADMAP */}
      {activeTab === 'phases' && (
        <div className="space-y-3">
          {/* Phase 1 */}
          <div className={`p-4 rounded-2xl border transition ${profile.currentPhase === 1 ? 'bg-emerald-950/30 border-emerald-500/50 glow-emerald' : 'bg-slate-900/60 border-slate-800'}`}>
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded text-[10px] font-black uppercase bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                  Phase 1 • Weeks 1 to 4
                </span>
                <span className="text-xs font-bold text-white">Foundation & Core Stability</span>
              </div>
              <span className="text-xs font-bold text-emerald-400">ACTIVE NOW</span>
            </div>
            <p className="text-xs text-slate-300 mt-2 leading-relaxed">
              Goal: Build the base without injury or joint burnout. Daily brisk walking (15-20 mins), basic push-ups against sofa/wall, chair squats, core bracing (knee planks), and fixing hydration habits.
            </p>
          </div>

          {/* Phase 2 */}
          <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded text-[10px] font-black uppercase bg-cyan-500/20 text-cyan-300 border border-cyan-500/40">
                  Phase 2 • Weeks 5 to 8
                </span>
                <span className="text-xs font-bold text-white">Athletic Development & Fat Shred</span>
              </div>
              <span className="text-xs text-slate-400 font-mono">Upcoming</span>
            </div>
            <p className="text-xs text-slate-300 mt-2 leading-relaxed">
              Goal: Progressive strength and stamina. Floor push-ups, explosive bodyweight squats, cardio intervals (HIIT brisk walk-run intervals), core anti-rotation, and low-level plyometrics.
            </p>
          </div>

          {/* Phase 3 */}
          <div className="p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded text-[10px] font-black uppercase bg-purple-500/20 text-purple-300 border border-purple-500/40">
                  Phase 3 • Weeks 9 to 12
                </span>
                <span className="text-xs font-bold text-white">Hero Conditioning & Speed</span>
              </div>
              <span className="text-xs text-slate-400 font-mono">Upcoming</span>
            </div>
            <p className="text-xs text-slate-300 mt-2 leading-relaxed">
              Goal: Sharp athletic definition and functional power. Boxing-style shadow conditioning, explosive movement, agility drills, and strength endurance circuits.
            </p>
          </div>
        </div>
      )}

      {/* TAB 4: PHYSIQUE INSPIRATION & GUIDANCE */}
      {activeTab === 'inspiration' && (
        <div className="space-y-4">
          <div className="bg-[#090e24] border border-cyan-500/30 rounded-2xl p-4 sm:p-5 shadow-lg">
            <div className="flex items-center gap-2 text-xs font-black text-cyan-400 uppercase tracking-wider mb-2 font-mono">
              <Trophy className="w-4 h-4" />
              <span>Target Aesthetic: Athletic Indian Hero</span>
            </div>
            <p className="text-xs text-slate-300 leading-relaxed mb-3">
              Inspired by the defined, functional, and lean muscular look of <strong className="text-white">Ram Charan in Dhruva</strong> combined with the grounded shoulder and back presence of <strong className="text-white">Prabhas</strong>.
            </p>

            <div className="p-3 rounded-xl bg-black/40 border border-slate-800 text-xs text-slate-300 space-y-1.5 leading-relaxed">
              <div className="text-emerald-300 font-bold">Important Guidance from Vyshu:</div>
              <div>• Celebrity physiques are visual inspirations, not clone blueprints. Your journey is calibrated for your genetics (170 cm, 82 kg).</div>
              <div>• We are prioritizing <strong className="text-white">waist fat loss + wide shoulders & back</strong> to create a natural, powerful V-taper.</div>
              <div>• You will look clean, athletic, approachable, and functional—not excessively bulky or stiff.</div>
            </div>

            {onAskVyshu && (
              <button
                onClick={() => onAskVyshu("Vyshu, review my athlete progression today and give me feedback on my routine.")}
                className="mt-4 w-full py-2.5 px-4 rounded-xl text-xs font-bold bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-300 border border-cyan-500/40 flex items-center justify-center gap-2 transition"
              >
                <Sparkles className="w-4 h-4 text-cyan-400" />
                <span>Ask Vyshu to Review My Physique Progress</span>
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
