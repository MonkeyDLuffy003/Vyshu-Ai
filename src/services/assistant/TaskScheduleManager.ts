import { ScheduledTask, TaskPriority, TaskStatus } from '../../types/assistant';

const STORAGE_KEY = 'vyshu_scheduled_tasks_v2';

const DEFAULT_SCHEDULED_TASKS: ScheduledTask[] = [
  {
    id: 'task-1',
    title: 'Professional Work & Standup',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '09:00',
    endTime: '11:00',
    priority: 'high',
    status: 'completed',
    category: 'work',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-2',
    title: 'V3 Testing & Architecture Review',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '16:00',
    endTime: '17:30',
    priority: 'high',
    status: 'pending',
    category: 'work',
    postponedCount: 1,
    originalTime: '11:00',
    notes: 'Postponed earlier from morning session.',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-3',
    title: 'Creator Task & Video Sync',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '20:30',
    endTime: '21:15',
    priority: 'medium',
    status: 'pending',
    category: 'content',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-4',
    title: 'Athlete Workout (Phase 1 Foundation)',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '18:00',
    endTime: '18:35',
    priority: 'high',
    status: 'pending',
    category: 'health',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

export class TaskScheduleManager {
  private static instance: TaskScheduleManager;

  private constructor() {
    this.initDefaults();
  }

  public static getInstance(): TaskScheduleManager {
    if (!TaskScheduleManager.instance) {
      TaskScheduleManager.instance = new TaskScheduleManager();
    }
    return TaskScheduleManager.instance;
  }

  private initDefaults(): void {
    if (!localStorage.getItem(STORAGE_KEY)) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(DEFAULT_SCHEDULED_TASKS));
    }
  }

  public getAllTasks(): ScheduledTask[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : DEFAULT_SCHEDULED_TASKS;
    } catch {
      return DEFAULT_SCHEDULED_TASKS;
    }
  }

  private save(tasks: ScheduledTask[]): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
  }

  public getTasksForDate(dateStr: string): ScheduledTask[] {
    return this.getAllTasks().filter((t) => t.scheduledDate === dateStr);
  }

  public getTodayTasks(): ScheduledTask[] {
    const today = new Date().toISOString().split('T')[0];
    return this.getTasksForDate(today).sort((a, b) => (a.startTime || '99:99').localeCompare(b.startTime || '99:99'));
  }

  public findTaskByQuery(query: string): ScheduledTask | undefined {
    const lower = query.toLowerCase().trim();
    const tasks = this.getTodayTasks();
    return (
      tasks.find((t) => t.title.toLowerCase().includes(lower)) ||
      tasks.find((t) => lower.includes(t.title.toLowerCase())) ||
      this.getAllTasks().find((t) => t.title.toLowerCase().includes(lower))
    );
  }

  public createTask(
    title: string,
    options?: {
      scheduledDate?: string;
      startTime?: string;
      endTime?: string;
      priority?: TaskPriority;
      notes?: string;
    }
  ): ScheduledTask {
    const today = new Date().toISOString().split('T')[0];
    const task: ScheduledTask = {
      id: `task-${Date.now()}`,
      title: title.trim(),
      scheduledDate: options?.scheduledDate || today,
      startTime: options?.startTime || '12:00',
      endTime: options?.endTime,
      priority: options?.priority || 'medium',
      status: 'pending',
      category: 'work',
      notes: options?.notes,
      postponedCount: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const all = this.getAllTasks();
    all.push(task);
    this.save(all);
    return task;
  }

  public rescheduleTask(
    queryOrId: string,
    newTime?: string,
    newDate?: string
  ): { success: boolean; task?: ScheduledTask; message: string } {
    const all = this.getAllTasks();
    const task =
      all.find((t) => t.id === queryOrId) ||
      all.find((t) => t.title.toLowerCase().includes(queryOrId.toLowerCase()));

    if (!task) {
      return { success: false, message: `Could not locate task matching "${queryOrId}".` };
    }

    if (newTime) {
      task.originalTime = task.startTime;
      task.startTime = newTime;
    }
    if (newDate) {
      task.scheduledDate = newDate;
    }
    task.postponedCount += 1;
    task.status = 'postponed';
    task.updatedAt = new Date().toISOString();

    this.save(all);
    return {
      success: true,
      task,
      message: `Updated "${task.title}" to ${newDate ? `date ${newDate}` : ''} ${newTime ? `at ${newTime}` : ''}.`,
    };
  }

  public completeTask(queryOrId: string): { success: boolean; task?: ScheduledTask; message: string } {
    const all = this.getAllTasks();
    const task =
      all.find((t) => t.id === queryOrId) ||
      all.find((t) => t.title.toLowerCase().includes(queryOrId.toLowerCase()));

    if (!task) {
      return { success: false, message: `Could not locate task matching "${queryOrId}".` };
    }

    task.status = 'completed';
    task.updatedAt = new Date().toISOString();
    this.save(all);
    return { success: true, task, message: `Completed task: "${task.title}".` };
  }

  // Intelligent schedule overview for AI prompt
  public getScheduleContext(): string {
    const today = new Date().toISOString().split('T')[0];
    const nowHour = new Date().getHours();
    const nowMin = new Date().getMinutes();
    const nowTimeStr = `${String(nowHour).padStart(2, '0')}:${String(nowMin).padStart(2, '0')}`;

    const tasks = this.getTodayTasks();
    const pending = tasks.filter((t) => t.status === 'pending' || t.status === 'postponed');
    const completed = tasks.filter((t) => t.status === 'completed');

    const nextTask = pending.find((t) => (t.startTime || '00:00') >= nowTimeStr) || pending[0];

    const lines: string[] = [
      `CURRENT DATE: ${today}`,
      `CURRENT LOCAL TIME: ${nowTimeStr}`,
      `TASKS REMAINING TODAY (${pending.length}):`,
    ];

    if (pending.length === 0) {
      lines.push("  - No remaining scheduled tasks for today. All caught up.");
    } else {
      pending.forEach((t) => {
        lines.push(
          `  - [${t.startTime || 'Anytime'}] ${t.title} (Priority: ${t.priority.toUpperCase()}${
            t.postponedCount > 0 ? `, Postponed ${t.postponedCount}x from ${t.originalTime || 'earlier'}` : ''
          })`
        );
      });
    }

    if (nextTask) {
      lines.push(`NEXT UP: "${nextTask.title}" at ${nextTask.startTime || 'TBD'}`);
    }

    if (completed.length > 0) {
      lines.push(`COMPLETED TODAY (${completed.length}): ${completed.map((c) => c.title).join(', ')}`);
    }

    return lines.join('\n');
  }
}

export const taskScheduleManager = TaskScheduleManager.getInstance();
