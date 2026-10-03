export type VyshuMode = 'PROFESSIONAL' | 'HOME' | 'NORMAL' | 'STANDBY';

export type TaskPriority = 'high' | 'medium' | 'low';

export type TaskStatus =
  | 'pending'
  | 'in_progress'
  | 'completed'
  | 'postponed'
  | 'cancelled'
  | 'overdue';

export interface ScheduledTask {
  id: string;
  title: string;
  description?: string;
  scheduledDate: string; // YYYY-MM-DD
  startTime?: string;    // HH:MM (24-hr)
  endTime?: string;      // HH:MM (24-hr)
  deadline?: string;     // ISO timestamp or HH:MM
  priority: TaskPriority;
  status: TaskStatus;
  category: 'work' | 'personal' | 'health' | 'content' | 'routine';
  recurrence?: 'none' | 'daily' | 'weekdays' | 'weekly' | 'custom';
  notes?: string;
  dependencies?: string[];
  postponedCount: number;
  originalTime?: string;
  completedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SecretaryAlarm {
  id: string;
  time: string; // HH:MM
  label: string;
  enabled: boolean;
  daysOfWeek: number[]; // 0=Sun, 1=Mon...
  createdAt: string;
}

export interface SecretaryReminder {
  id: string;
  message: string;
  triggerTime: string; // ISO date-time or condition string
  condition?: string; // e.g. "when home", "after lunch"
  recurrence?: 'none' | 'daily' | 'weekly' | 'monthly';
  status: 'active' | 'triggered' | 'dismissed';
  createdAt: string;
}

export interface AppointmentRecord {
  id: string;
  name: string;
  date: string; // YYYY-MM-DD
  time: string; // HH:MM
  location?: string;
  contactPerson?: string;
  notes?: string;
  confirmationCode?: string;
  reminderMinutesBefore: number;
  status: 'scheduled' | 'completed' | 'cancelled';
  createdAt: string;
}

export interface FollowUpItem {
  id: string;
  title: string;
  targetDate: string;
  contactPerson?: string;
  priority: TaskPriority;
  status: 'pending' | 'completed';
  notes?: string;
  createdAt: string;
}

export interface DailyActivityItem {
  timeSlot: string; // "09:00 - 13:00"
  activity: string;
  category: 'work' | 'personal' | 'meals' | 'fitness' | 'rest';
  isRecurringCandidate?: boolean;
}

export interface PersonalMemory {
  id: string;
  category: 'personal' | 'work' | 'projects' | 'routine';
  key: string;
  value: string;
  createdAt: string;
}

export interface ProjectContext {
  id: string;
  projectName: string;
  description: string;
  activeStatus: string;
  currentMilestone: string;
  notes: string[];
}
