import { secretaryDataManager } from './SecretaryDataManager';
import { modeManager } from './ModeManager';
import { memoryManager } from './MemoryManager';
import { VyshuMode, TaskPriority } from '../../types/assistant';

export interface ToolExecutionResult {
  tool: string;
  success: boolean;
  message: string;
  data?: any;
}

export class ToolExecutor {
  private static instance: ToolExecutor;

  public static getInstance(): ToolExecutor {
    if (!ToolExecutor.instance) {
      ToolExecutor.instance = new ToolExecutor();
    }
    return ToolExecutor.instance;
  }

  // Parse structured secretary instructions returned by AI reasoning layer
  public executeTool(toolCommand: string): ToolExecutionResult {
    const match = toolCommand.match(/\[ACTION:\s*([A-Z_]+)(?::(.*))?\]/);
    if (!match) {
      return { tool: 'unknown', success: false, message: 'Invalid tool command format' };
    }

    const action = match[1];
    const args = match[2] ? match[2].split('|').map((s) => s.trim()) : [];

    switch (action) {
      case 'RESCHEDULE_TASK': {
        const [taskQuery, newTime, newDate] = args;
        const res = secretaryDataManager.rescheduleTask(taskQuery, newTime, newDate);
        return { tool: action, success: res.success, message: res.message, data: res.task };
      }

      case 'CREATE_TASK': {
        const [title, startTime, priority, category] = args;
        const task = secretaryDataManager.createTask({
          title,
          startTime: startTime || '12:00',
          priority: (priority as TaskPriority) || 'medium',
          category: (category as any) || 'work',
        });
        return { tool: action, success: true, message: `Created task "${task.title}" at ${task.startTime}`, data: task };
      }

      case 'COMPLETE_TASK': {
        const [taskQuery] = args;
        const res = secretaryDataManager.completeTask(taskQuery);
        return { tool: action, success: res.success, message: res.message, data: res.task };
      }

      case 'SET_ALARM': {
        const [time, label] = args;
        const alarm = secretaryDataManager.setAlarm(time, label || 'Secretary Alarm');
        return { tool: action, success: true, message: `Alarm set for ${alarm.time} (${alarm.label})`, data: alarm };
      }

      case 'CREATE_REMINDER': {
        const [msg, triggerTime, condition] = args;
        const rem = secretaryDataManager.createReminder(msg, triggerTime || 'Today', condition);
        return { tool: action, success: true, message: `Reminder saved: "${rem.message}" for ${rem.triggerTime}`, data: rem };
      }

      case 'BOOK_APPOINTMENT': {
        const [name, date, time, location, contact] = args;
        const apt = secretaryDataManager.recordAppointment({
          name,
          date,
          time,
          location,
          contactPerson: contact,
        });
        return { tool: action, success: true, message: `Recorded appointment "${apt.name}" on ${apt.date} at ${apt.time}`, data: apt };
      }

      case 'ADD_FOLLOWUP': {
        const [title, targetDate, contactPerson] = args;
        const fol = secretaryDataManager.addFollowUp(title, targetDate, contactPerson);
        return { tool: action, success: true, message: `Follow-up logged: "${fol.title}" due ${fol.targetDate}`, data: fol };
      }

      case 'CHANGE_MODE': {
        const [rawMode] = args;
        const targetMode = rawMode.toUpperCase() as VyshuMode;
        if (['PROFESSIONAL', 'HOME', 'NORMAL', 'STANDBY'].includes(targetMode)) {
          modeManager.setMode(targetMode);
          return { tool: action, success: true, message: `Switched mode to ${targetMode}`, data: { mode: targetMode } };
        }
        return { tool: action, success: false, message: `Unknown mode "${rawMode}"` };
      }

      case 'SAVE_MEMORY': {
        const [key, value] = args;
        const mem = memoryManager.savePersonalMemory(key, value);
        return { tool: action, success: true, message: `Saved to memory: ${key} = ${value}`, data: mem };
      }

      default:
        return { tool: action, success: false, message: `Unhandled action: ${action}` };
    }
  }
}

export const toolExecutor = ToolExecutor.getInstance();
