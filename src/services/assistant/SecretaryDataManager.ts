import {
  ScheduledTask,
  SecretaryAlarm,
  SecretaryReminder,
  AppointmentRecord,
  FollowUpItem,
  DailyActivityItem,
  TaskPriority,
  TaskStatus,
} from '../../types/assistant';

const STORAGE_KEYS = {
  TASKS: 'vyshu_secretary_tasks_v3',
  ALARMS: 'vyshu_secretary_alarms_v3',
  REMINDERS: 'vyshu_secretary_reminders_v3',
  APPOINTMENTS: 'vyshu_secretary_appointments_v3',
  FOLLOW_UPS: 'vyshu_secretary_followups_v3',
  MORNING_BRIEFING_ENABLED: 'vyshu_morning_briefing_enabled',
};

const DEFAULT_TASKS: ScheduledTask[] = [
  {
    id: 't-1',
    title: 'Professional Work & Standup',
    description: 'Engineering coordination and core team deliverables.',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '09:00',
    endTime: '13:00',
    priority: 'high',
    status: 'completed',
    category: 'work',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 't-2',
    title: 'V3 Testing & Architecture Review',
    description: 'Run through regression checklist and memory pipeline test.',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '20:00',
    endTime: '21:30',
    priority: 'high',
    status: 'pending',
    category: 'work',
    postponedCount: 1,
    originalTime: '16:00',
    notes: 'Postponed earlier from afternoon session.',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 't-3',
    title: 'Athlete Workout (Phase 1 Foundation)',
    description: 'Upper body and posture push-ups with core stability.',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '19:00',
    endTime: '19:40',
    priority: 'high',
    status: 'pending',
    category: 'health',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 't-4',
    title: 'Content Creation & Review',
    description: 'Review tech demo clips and schedule social drops.',
    scheduledDate: new Date().toISOString().split('T')[0],
    startTime: '21:30',
    endTime: '22:15',
    priority: 'medium',
    status: 'pending',
    category: 'content',
    postponedCount: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
];

const DEFAULT_ALARMS: SecretaryAlarm[] = [
  {
    id: 'alm-1',
    time: '08:00',
    label: 'Morning Wakeup Routine',
    enabled: true,
    daysOfWeek: [1, 2, 3, 4, 5],
    createdAt: new Date().toISOString(),
  },
  {
    id: 'alm-2',
    time: '22:30',
    label: 'Evening Wind-down',
    enabled: true,
    daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
    createdAt: new Date().toISOString(),
  },
];

const DEFAULT_REMINDERS: SecretaryReminder[] = [
  {
    id: 'rem-1',
    message: 'Drink 500ml water and stretch',
    triggerTime: '15:00',
    condition: 'Daily routine',
    status: 'active',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'rem-2',
    message: 'Check V3 build output on GitHub Actions',
    triggerTime: '20:00',
    status: 'active',
    createdAt: new Date().toISOString(),
  },
];

const DEFAULT_APPOINTMENTS: AppointmentRecord[] = [
  {
    id: 'apt-1',
    name: 'Dentist Checkup & Cleaning',
    date: new Date(Date.now() + 86400000 * 2).toISOString().split('T')[0],
    time: '17:00',
    location: 'City Dental Clinic',
    contactPerson: 'Dr. Rao',
    reminderMinutesBefore: 60,
    status: 'scheduled',
    createdAt: new Date().toISOString(),
  },
];

const DEFAULT_FOLLOWUPS: FollowUpItem[] = [
  {
    id: 'fol-1',
    title: 'Call Technical Recruiter regarding pipeline follow-up',
    targetDate: new Date(Date.now() + 86400000).toISOString().split('T')[0],
    contactPerson: 'Recruiter',
    priority: 'high',
    status: 'pending',
    createdAt: new Date().toISOString(),
  },
];

export class SecretaryDataManager {
  private static instance: SecretaryDataManager;

  private constructor() {
    this.initDefaults();
  }

  public static getInstance(): SecretaryDataManager {
    if (!SecretaryDataManager.instance) {
      SecretaryDataManager.instance = new SecretaryDataManager();
    }
    return SecretaryDataManager.instance;
  }

  private initDefaults(): void {
    if (!localStorage.getItem(STORAGE_KEYS.TASKS)) {
      localStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(DEFAULT_TASKS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.ALARMS)) {
      localStorage.setItem(STORAGE_KEYS.ALARMS, JSON.stringify(DEFAULT_ALARMS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.REMINDERS)) {
      localStorage.setItem(STORAGE_KEYS.REMINDERS, JSON.stringify(DEFAULT_REMINDERS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.APPOINTMENTS)) {
      localStorage.setItem(STORAGE_KEYS.APPOINTMENTS, JSON.stringify(DEFAULT_APPOINTMENTS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.FOLLOW_UPS)) {
      localStorage.setItem(STORAGE_KEYS.FOLLOW_UPS, JSON.stringify(DEFAULT_FOLLOWUPS));
    }
  }

  // --- TASKS ---
  public getTasks(): ScheduledTask[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.TASKS);
      return raw ? JSON.parse(raw) : DEFAULT_TASKS;
    } catch {
      return DEFAULT_TASKS;
    }
  }

  public saveTasks(tasks: ScheduledTask[]): void {
    localStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(tasks));
  }

  public getTodayTasks(): ScheduledTask[] {
    const today = new Date().toISOString().split('T')[0];
    return this.getTasks()
      .filter((t) => t.scheduledDate === today)
      .sort((a, b) => (a.startTime || '99:99').localeCompare(b.startTime || '99:99'));
  }

  public createTask(data: {
    title: string;
    description?: string;
    startTime?: string;
    endTime?: string;
    priority?: TaskPriority;
    category?: ScheduledTask['category'];
    date?: string;
  }): ScheduledTask {
    const today = new Date().toISOString().split('T')[0];
    const task: ScheduledTask = {
      id: `t-${Date.now()}`,
      title: data.title.trim(),
      description: data.description,
      scheduledDate: data.date || today,
      startTime: data.startTime || '12:00',
      endTime: data.endTime,
      priority: data.priority || 'medium',
      status: 'pending',
      category: data.category || 'work',
      postponedCount: 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const tasks = this.getTasks();
    tasks.push(task);
    this.saveTasks(tasks);
    return task;
  }

  public rescheduleTask(
    queryOrId: string,
    newTime?: string,
    newDate?: string
  ): { success: boolean; task?: ScheduledTask; message: string } {
    const tasks = this.getTasks();
    const task =
      tasks.find((t) => t.id === queryOrId) ||
      tasks.find((t) => t.title.toLowerCase().includes(queryOrId.toLowerCase()));

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

    this.saveTasks(tasks);
    return {
      success: true,
      task,
      message: `Rescheduled "${task.title}" to ${newDate ? `date ${newDate}` : ''} ${newTime ? `at ${newTime}` : ''}.`,
    };
  }

  public completeTask(queryOrId: string): { success: boolean; task?: ScheduledTask; message: string } {
    const tasks = this.getTasks();
    const task =
      tasks.find((t) => t.id === queryOrId) ||
      tasks.find((t) => t.title.toLowerCase().includes(queryOrId.toLowerCase()));

    if (!task) {
      return { success: false, message: `Could not locate task matching "${queryOrId}".` };
    }

    task.status = 'completed';
    task.completedAt = new Date().toISOString();
    task.updatedAt = new Date().toISOString();
    this.saveTasks(tasks);
    return { success: true, task, message: `Completed task: "${task.title}".` };
  }

  // --- ALARMS ---
  public getAlarms(): SecretaryAlarm[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.ALARMS);
      return raw ? JSON.parse(raw) : DEFAULT_ALARMS;
    } catch {
      return DEFAULT_ALARMS;
    }
  }

  public setAlarm(time: string, label: string = 'Alarm'): SecretaryAlarm {
    const alarms = this.getAlarms();
    const alarm: SecretaryAlarm = {
      id: `alm-${Date.now()}`,
      time,
      label,
      enabled: true,
      daysOfWeek: [0, 1, 2, 3, 4, 5, 6],
      createdAt: new Date().toISOString(),
    };
    alarms.push(alarm);
    localStorage.setItem(STORAGE_KEYS.ALARMS, JSON.stringify(alarms));
    return alarm;
  }

  public toggleAlarm(id: string): boolean {
    const alarms = this.getAlarms();
    const a = alarms.find((item) => item.id === id);
    if (a) {
      a.enabled = !a.enabled;
      localStorage.setItem(STORAGE_KEYS.ALARMS, JSON.stringify(alarms));
      return a.enabled;
    }
    return false;
  }

  // --- REMINDERS ---
  public getReminders(): SecretaryReminder[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.REMINDERS);
      return raw ? JSON.parse(raw) : DEFAULT_REMINDERS;
    } catch {
      return DEFAULT_REMINDERS;
    }
  }

  public createReminder(message: string, triggerTime: string, condition?: string): SecretaryReminder {
    const list = this.getReminders();
    const rem: SecretaryReminder = {
      id: `rem-${Date.now()}`,
      message,
      triggerTime,
      condition,
      status: 'active',
      createdAt: new Date().toISOString(),
    };
    list.push(rem);
    localStorage.setItem(STORAGE_KEYS.REMINDERS, JSON.stringify(list));
    return rem;
  }

  // --- APPOINTMENTS ---
  public getAppointments(): AppointmentRecord[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.APPOINTMENTS);
      return raw ? JSON.parse(raw) : DEFAULT_APPOINTMENTS;
    } catch {
      return DEFAULT_APPOINTMENTS;
    }
  }

  public recordAppointment(data: {
    name: string;
    date: string;
    time: string;
    location?: string;
    contactPerson?: string;
    notes?: string;
  }): AppointmentRecord {
    const list = this.getAppointments();
    const apt: AppointmentRecord = {
      id: `apt-${Date.now()}`,
      name: data.name,
      date: data.date,
      time: data.time,
      location: data.location,
      contactPerson: data.contactPerson,
      notes: data.notes,
      reminderMinutesBefore: 60,
      status: 'scheduled',
      createdAt: new Date().toISOString(),
    };
    list.push(apt);
    localStorage.setItem(STORAGE_KEYS.APPOINTMENTS, JSON.stringify(list));
    return apt;
  }

  // --- FOLLOW-UPS ---
  public getFollowUps(): FollowUpItem[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.FOLLOW_UPS);
      return raw ? JSON.parse(raw) : DEFAULT_FOLLOWUPS;
    } catch {
      return DEFAULT_FOLLOWUPS;
    }
  }

  public addFollowUp(title: string, targetDate: string, contactPerson?: string): FollowUpItem {
    const list = this.getFollowUps();
    const fol: FollowUpItem = {
      id: `fol-${Date.now()}`,
      title,
      targetDate,
      contactPerson,
      priority: 'high',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    list.push(fol);
    localStorage.setItem(STORAGE_KEYS.FOLLOW_UPS, JSON.stringify(list));
    return fol;
  }

  // --- MORNING BRIEFING SYNTHESIS ---
  public generateMorningBriefing(): string {
    const todayTasks = this.getTodayTasks();
    const pending = todayTasks.filter((t) => t.status !== 'completed');
    const appointments = this.getAppointments().filter(
      (a) => a.date === new Date().toISOString().split('T')[0] && a.status === 'scheduled'
    );
    const reminders = this.getReminders().filter((r) => r.status === 'active');

    const firstActivity = pending[0] ? `Your first activity starts at ${pending[0].startTime || 'morning'}.` : "No early morning blocks scheduled.";

    return `Good morning, Teja.\n\nToday's Briefing:\n• ${pending.length} scheduled tasks remaining\n• ${appointments.length} appointment today\n• ${reminders.length} active reminders\n\n${firstActivity}`;
  }

  // --- COMPREHENSIVE SECRETARY STATE FOR AI PROMPT ---
  public getFullSecretaryContext(): string {
    const today = new Date().toISOString().split('T')[0];
    const nowHour = new Date().getHours();
    const nowMin = new Date().getMinutes();
    const nowStr = `${String(nowHour).padStart(2, '0')}:${String(nowMin).padStart(2, '0')}`;

    const todayTasks = this.getTodayTasks();
    const pending = todayTasks.filter((t) => t.status !== 'completed');
    const completed = todayTasks.filter((t) => t.status === 'completed');
    const alarms = this.getAlarms().filter((a) => a.enabled);
    const appointments = this.getAppointments().filter((a) => a.status === 'scheduled');
    const followUps = this.getFollowUps().filter((f) => f.status === 'pending');

    const lines: string[] = [
      `DEVICE LOCAL TIME: ${nowStr} (${today})`,
      `TODAY'S TASKS PENDING (${pending.length}):`,
    ];

    if (pending.length === 0) {
      lines.push("  - All scheduled tasks for today are finished.");
    } else {
      pending.forEach((t) => {
        lines.push(`  - [${t.startTime || 'TBD'}] ${t.title} (Priority: ${t.priority.toUpperCase()}${t.postponedCount > 0 ? `, Postponed ${t.postponedCount}x from ${t.originalTime || 'earlier'}` : ''})`);
      });
    }

    if (completed.length > 0) {
      lines.push(`COMPLETED TODAY: ${completed.map((c) => c.title).join(', ')}`);
    }

    if (alarms.length > 0) {
      lines.push(`ACTIVE ALARMS: ${alarms.map((a) => `${a.time} (${a.label})`).join(', ')}`);
    }

    if (appointments.length > 0) {
      lines.push(`UPCOMING APPOINTMENTS: ${appointments.map((a) => `${a.date} at ${a.time} — ${a.name}`).join('; ')}`);
    }

    if (followUps.length > 0) {
      lines.push(`PENDING FOLLOW-UPS: ${followUps.map((f) => `${f.title} (Due: ${f.targetDate})`).join('; ')}`);
    }

    return lines.join('\n');
  }
}

export const secretaryDataManager = SecretaryDataManager.getInstance();
