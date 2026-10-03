import { storageService } from './storageService';
import { modeManager } from './assistant/ModeManager';
import { memoryManager } from './assistant/MemoryManager';
import { secretaryDataManager } from './assistant/SecretaryDataManager';
import { toolExecutor } from './assistant/ToolExecutor';
import { VyshuMode } from '../types/assistant';
import { ChatMessage } from '../types';

const BAD_WORDS = [
  "sex","porn","fuck","nude","xxx","penis","vagina","dick",
  "cock","bitch","shit","asshole","bastard","whore","slut",
  "cunt","motherfucker","nigga","puku","sulla","lanjakodaka",
  "munda","gudda","dengudu","pichodi","lanjodi","modda","pooku",
  "nayana","randi","bokka","bhenchod","madarchod","chutiya",
  "lund","gandu","bhosdike","harami","kutte","suar","haramzade",
  "maa ki aankh","teri maa"
];

const WARNING_STAGES: Record<number, string> = {
  1: "Ayyo Teja! Easy bro!\nThat word is NOT allowed! Vyshu watching\nWarning 1/7 — Be nice!",
  2: "Teja bro SERIOUSLY?!\nVyshu picked up the slipper *WHACK*\nWarning 2/7 — Last easy one!",
  3: "Okay Teja...\nVyshu LOADING the gun *click click*\nWarning 3/7 — Getting serious!",
  4: "Teja BRO. STOP.\nTWO guns out now\nWarning 4/7 — Very serious!",
  5: "Teja! 5 warnings?! DANGER ZONE!\nWarning 5/7 — Admin watching!",
  6: "Teja — ONE. MORE. TIME.\nSlipper + Gun + Admin = YOUR FATE\nWarning 6/7 — FINAL WARNING!",
  7: "Teja — THAT'S IT!\n7/7 — You played yourself!\nADMIN ACTION INCOMING",
};

export class BrainService {
  private currentKeyIndex = 0;
  private warningCount = 0;

  public checkBadWords(text: string): { isBad: boolean; warning?: string; sticker?: string } {
    const t = text.toLowerCase();
    for (const w of BAD_WORDS) {
      if (t.includes(w)) {
        this.warningCount = Math.min(this.warningCount + 1, 7);
        return {
          isBad: true,
          warning: WARNING_STAGES[this.warningCount] || `Warning ${this.warningCount}/7`,
          sticker: 'gun2',
        };
      }
    }
    return { isBad: false };
  }

  private getActiveKeys(): string[] {
    const vault = storageService.getVaultKeys();
    return [vault.gemini_1, vault.gemini_2, vault.gemini_3, vault.gemini_4, vault.gemini_5]
      .map((k) => k?.trim())
      .filter((k): k is string => Boolean(k && k.length > 5));
  }

  public assembleSystemContext(userQuery: string): string {
    const activeMode = modeManager.getMode();
    const modePrompt = modeManager.getModePersonaPrompt();
    const secretaryState = secretaryDataManager.getFullSecretaryContext();
    const relevantMemory = memoryManager.retrieveRelevantContext(userQuery);

    return `
You are Vyshu — an intelligent personal AI secretary and executive assistant engineered exclusively for Teja.

${modePrompt}

CORE SECRETARY INSTRUCTIONS:
1. EXECUTIVE SYNTHESIS & NO CANNED REPLIES:
   - Generate natural, situationally accurate executive responses.
   - When asked "What's my day?", provide a concise executive summary covering today's scheduled activities, upcoming appointments, and pending tasks.
   - For morning briefings or evening wind-downs, review remaining obligations constructively.
   - If Teja says he is tired or wants to adjust his evening, offer realistic options (e.g. postponing a specific task to tomorrow) rather than robotic clichés.

2. ONGOING SECRETARY STATE:
${secretaryState}

${relevantMemory ? `\nRELEVANT LONG-TERM MEMORY:\n${relevantMemory}` : ''}

3. EXECUTING ACTIONS & COORDINATING LOGISTICS:
Whenever Teja requests an action, append the structured action tag to the END of your response so the app coordinates it:
- Reschedule task: [ACTION: RESCHEDULE_TASK:taskQuery|newTime|newDate]
- Add/Create task: [ACTION: CREATE_TASK:title|startTime|priority|category]
- Mark completed: [ACTION: COMPLETE_TASK:taskQuery]
- Set real alarm: [ACTION: SET_ALARM:time|label]
- Create reminder: [ACTION: CREATE_REMINDER:message|triggerTime|condition]
- Log appointment: [ACTION: BOOK_APPOINTMENT:name|date|time|location|contact]
  (NOTE: If Teja asks to book a service like a dentist and no 3rd-party booking API exists, honestly state: "I can add it to your schedule, but I don't currently have direct access to their online booking system.")
- Log follow-up: [ACTION: ADD_FOLLOWUP:title|targetDate|contactPerson]
- Switch mode: [ACTION: CHANGE_MODE:PROFESSIONAL|HOME|NORMAL|STANDBY]
- Explicitly remember: [ACTION: SAVE_MEMORY:key|value]

4. PHONE TOOLS:
- [TOOL: OPEN_SPOTIFY], [TOOL: OPEN_YOUTUBE], [TOOL: OPEN_WHATSAPP], [TOOL: OPEN_APP:appName]
- [TOOL: TORCH_ON], [TOOL: TORCH_OFF]
`;
  }

  // Graceful offline fallback
  private getOfflineResponse(userMessage: string, mode: VyshuMode): string {
    const lower = userMessage.toLowerCase().trim();
    const salutation = mode === 'PROFESSIONAL' ? 'Sir' : 'buddy';

    // 1. Check schedule queries / "what's my day"
    if (lower.includes('my day') || lower.includes('schedule') || lower.includes('what is left') || lower.includes('tasks')) {
      const todayTasks = secretaryDataManager.getTodayTasks();
      const pending = todayTasks.filter((t) => t.status !== 'completed');
      if (pending.length === 0) {
        return `You're all clear for today, ${salutation}. No remaining scheduled tasks.`;
      }
      const summary = pending.map((t) => `${t.title} at ${t.startTime || 'TBD'}`).join(', ');
      return `Here is your day, ${salutation}: ${summary}.`;
    }

    // 2. Direct rescheduling fallback
    if (lower.includes('move') || lower.includes('postpone') || lower.includes('reschedule')) {
      const match = lower.match(/move\s+(.+?)\s+to\s+([0-9]+(?::[0-9]+)?(?:\s*[ap]m)?)/i);
      if (match) {
        const taskQuery = match[1];
        let timeStr = match[2];
        if (!timeStr.includes(':') && !timeStr.toLowerCase().includes('m')) {
          const num = parseInt(timeStr, 10);
          timeStr = num < 12 ? `${num + 12}:00` : `${num}:00`;
        }
        const res = secretaryDataManager.rescheduleTask(taskQuery, timeStr);
        if (res.success) {
          return `Updated ${salutation}. ${res.message}`;
        }
      }
    }

    // 3. Alarms
    if (lower.includes('alarm')) {
      const match = lower.match(/(?:set|wake me at)\s+([0-9]+(?::[0-9]+)?(?:\s*[ap]m)?)/i);
      if (match) {
        const alarm = secretaryDataManager.setAlarm(match[1]);
        return `Alarm configured for ${alarm.time}, ${salutation}.`;
      }
    }

    // 4. Mode switch offline fallback
    if (lower.includes('office mode') || lower.includes('work mode') || lower.includes('professional mode')) {
      modeManager.setMode('PROFESSIONAL');
      return `Professional mode engaged, Sir. Standing by for executive tasks.`;
    }
    if (lower.includes('home mode') || lower.includes('friendly mode') || lower.includes('relax mode')) {
      modeManager.setMode('HOME');
      return `Home mode activated, buddy. How was your day?`;
    }

    return `At your service, ${salutation}. Secretary database, schedule, and memory are fully operational offline.`;
  }

  public async respond(
    userMessage: string,
    modeParam?: 'HOME' | 'OFFICE' | VyshuMode
  ): Promise<{ text: string; id: string; sticker?: string }> {
    const turnId = Date.now().toString();

    if (modeParam) {
      if (modeParam === 'OFFICE') modeManager.setMode('PROFESSIONAL');
      else if (modeParam === 'HOME') modeManager.setMode('HOME');
    }
    const currentMode = modeManager.getMode();

    const badCheck = this.checkBadWords(userMessage);
    if (badCheck.isBad) {
      return { text: badCheck.warning || 'Warning!', id: turnId, sticker: badCheck.sticker };
    }

    const keys = this.getActiveKeys();

    if (keys.length === 0 || !navigator.onLine) {
      const offlineReply = this.getOfflineResponse(userMessage, currentMode);
      return { text: offlineReply, id: turnId };
    }

    if (this.currentKeyIndex >= keys.length) this.currentKeyIndex = 0;
    const currentKey = keys[this.currentKeyIndex];
    this.currentKeyIndex = (this.currentKeyIndex + 1) % keys.length;

    try {
      const history = storageService.getChatHistory().slice(-8);
      const systemInstruction = this.assembleSystemContext(userMessage);

      const contents = [
        {
          role: 'user',
          parts: [{ text: systemInstruction }],
        },
        {
          role: 'model',
          parts: [{ text: `Understood. I am online as Teja's personal AI secretary and executive assistant in ${currentMode} mode.` }],
        },
        ...history.map((h: ChatMessage) => ({
          role: h.role === 'user' ? 'user' : 'model',
          parts: [{ text: h.text }],
        })),
        {
          role: 'user',
          parts: [{ text: userMessage }],
        },
      ];

      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${currentKey}`;

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents }),
        signal: AbortSignal.timeout(18000),
      });

      if (res.ok) {
        const data = await res.json();
        let candidate: string = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (candidate) {
          const actionMatch = candidate.match(/\[ACTION:\s*[A-Z_]+(?::.*?)?\]/g);
          if (actionMatch) {
            actionMatch.forEach((act) => {
              toolExecutor.executeTool(act);
              candidate = candidate.replace(act, '').trim();
            });
          }

          return { text: candidate.trim(), id: turnId };
        }
      }

      return { text: this.getOfflineResponse(userMessage, currentMode), id: turnId };
    } catch {
      return { text: this.getOfflineResponse(userMessage, currentMode), id: turnId };
    }
  }

  public deleteTurn(turnId: string): void {
    const history = storageService.getChatHistory();
    const updated = history.filter((m: ChatMessage) => m.turnId !== turnId && m.id !== turnId);
    storageService.saveChatHistory(updated);
  }
}

export const brainService = new BrainService();
