import React, { useState } from 'react';
import {
  CheckSquare,
  Square,
  Plus,
  Trash2,
  Calendar,
  Volume2,
  Clock,
  Sparkles,
  CheckCircle2,
} from 'lucide-react';
import { storageService } from '../../services/storageService';
import { TaskItem } from '../../types';
import { audioService } from '../../services/audioService';

export const TaskManager: React.FC = () => {
  const [tasks, setTasks] = useState<TaskItem[]>(storageService.getTasks());
  const [newTitle, setNewTitle] = useState('');
  const [dueDate, setDueDate] = useState('');

  const handleAddTask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    const newTask: TaskItem = {
      id: Date.now().toString(),
      title: newTitle.trim(),
      completed: false,
      dueDate: dueDate || undefined,
      createdAt: new Date().toISOString(),
    };

    const updated = [newTask, ...tasks];
    setTasks(updated);
    storageService.saveTasks(updated);
    setNewTitle('');
    setDueDate('');
    audioService.playSound('send');
  };

  const handleToggle = (id: string) => {
    audioService.playSound('toggle');
    const updated = tasks.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t));
    setTasks(updated);
    storageService.saveTasks(updated);
  };

  const handleDelete = (id: string) => {
    audioService.playSound('click');
    const updated = tasks.filter((t) => t.id !== id);
    setTasks(updated);
    storageService.saveTasks(updated);
  };

  const handleClearCompleted = () => {
    const updated = tasks.filter((t) => !t.completed);
    setTasks(updated);
    storageService.saveTasks(updated);
  };

  const handleReadTasks = () => {
    const pending = tasks.filter((t) => !t.completed);
    if (pending.length === 0) {
      audioService.speak('Teja, you have no pending tasks right now. Great job!', 'en-IN');
      return;
    }
    const taskNames = pending.map((t, idx) => `Task ${idx + 1}: ${t.title}`).join('. ');
    audioService.speak(`Teja, you have ${pending.length} pending tasks. ${taskNames}`, 'en-IN');
  };

  const completedCount = tasks.filter((t) => t.completed).length;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Calendar className="w-4 h-4" /> Task Reminders &amp; Calendar
          </h2>
          <p className="text-xs text-slate-400">
            {completedCount} of {tasks.length} tasks completed
          </p>
        </div>

        <button
          onClick={handleReadTasks}
          className="text-xs px-3 py-1.5 rounded-xl bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 font-semibold hover:bg-cyan-500/30 flex items-center gap-1.5 transition active:scale-95"
        >
          <Volume2 className="w-3.5 h-3.5" /> Read Pending
        </button>
      </div>

      {/* Add Task Input Form */}
      <form onSubmit={handleAddTask} className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-3 flex flex-col sm:flex-row gap-2">
        <input
          type="text"
          value={newTitle}
          onChange={(e) => setNewTitle(e.target.value)}
          placeholder="Add a new task or reminder..."
          className="flex-1 bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-cyan-400"
        />
        <input
          type="date"
          value={dueDate}
          onChange={(e) => setDueDate(e.target.value)}
          className="bg-[#0e1422] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-400 focus:outline-none focus:border-cyan-400"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-cyan-400 text-slate-950 font-bold text-xs rounded-xl hover:bg-cyan-300 transition active:scale-95 shrink-0 flex items-center justify-center gap-1.5"
        >
          <Plus className="w-3.5 h-3.5" /> Add Task
        </button>
      </form>

      {/* Tasks List */}
      <div className="space-y-2 max-h-[50vh] overflow-y-auto pr-1">
        {tasks.map((task) => (
          <div
            key={task.id}
            className={`p-3.5 rounded-2xl border transition flex items-center justify-between ${
              task.completed
                ? 'bg-[#0b0b16]/60 border-slate-800/50 text-slate-500'
                : 'bg-[#0b0b16] border-slate-800 hover:border-slate-700 text-slate-200'
            }`}
          >
            <div className="flex items-center space-x-3 overflow-hidden">
              <button
                onClick={() => handleToggle(task.id)}
                className={`p-1 rounded-lg transition ${task.completed ? 'text-emerald-400' : 'text-slate-400 hover:text-cyan-400'}`}
              >
                {task.completed ? <CheckSquare className="w-4 h-4" /> : <Square className="w-4 h-4" />}
              </button>

              <div className="truncate">
                <span className={`text-xs font-medium block truncate ${task.completed ? 'line-through text-slate-500' : 'text-white'}`}>
                  {task.title}
                </span>
                {task.dueDate && (
                  <span className="text-[10px] text-cyan-400 flex items-center gap-1 font-mono">
                    <Clock className="w-2.5 h-2.5" /> Due: {task.dueDate}
                  </span>
                )}
              </div>
            </div>

            <button
              onClick={() => handleDelete(task.id)}
              className="p-1.5 text-slate-500 hover:text-rose-400 transition"
              title="Delete Task"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        ))}
      </div>

      {completedCount > 0 && (
        <div className="flex justify-end pt-1">
          <button
            onClick={handleClearCompleted}
            className="text-xs text-slate-400 hover:text-rose-400 transition"
          >
            Clear {completedCount} Completed Tasks
          </button>
        </div>
      )}
    </div>
  );
};
