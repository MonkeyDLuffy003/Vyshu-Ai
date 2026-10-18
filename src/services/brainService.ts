import { storageService } from './storageService';
import { modeManager } from './assistant/ModeManager';
import { memoryManager } from './assistant/MemoryManager';
import { secretaryDataManager } from './assistant/SecretaryDataManager';
import { toolExecutor } from './assistant/ToolExecutor';
import { vyshuVaultManager } from './vault/VaultRegistry';
import { REGISTERED_LLM_PROVIDERS } from './ai/LLMProvider';
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

    return `${modePrompt}

=== VYSHU EXECUTIVE SECRETARY ENGINE ===
CURRENT_TIME: ${new Date().toLocaleString()}
ACTIVE_MODE: ${activeMode}

${secretaryState}

=== RELEVANT MEMORY ===
${relevantMemory}

=== STRUCTURED ACTION TAGS ===
When performing a secretary or phone action, append the appropriate tag at the end of your reply:
- [ACTION: CREATE_TASK:title|HH:MM|priority|category]
- [ACTION: RESCHEDULE_TASK:taskQuery|newTime|newDate]
- [ACTION: COMPLETE_TASK:taskQuery]
- [ACTION: SET_ALARM:HH:MM|label]
- [ACTION: CREATE_REMINDER:message|triggerTime|condition]
- [ACTION: BOOK_APPOINTMENT:name|date|time|location|contact]
- [ACTION: SWITCH_MODE:PROFESSIONAL|HOME]
- [ACTION: SAVE_MEMORY:category|content]
`;
  }

  public getOfflineResponse(userMessage: string, mode: VyshuMode): string {
    const lower = userMessage.toLowerCase().trim();
    const salutation = mode === 'PROFESSIONAL' ? 'Sir' : 'Teja';

    // Direct Rule Commands (Work with Zero API Keys!)
    if (lower === 'time' || lower.includes('what time is it') || lower.includes('current time')) {
      return `It is ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}, ${salutation}. (Add an API key in Vault to unlock full intelligence.)`;
    }
    if (lower.includes('torch on') || lower.includes('turn on torch') || lower.includes('flashlight on')) {
      return `Torch turned on, ${salutation}. (Add an API key in Vault to unlock full intelligence.)`;
    }
    if (lower.includes('torch off') || lower.includes('turn off torch') || lower.includes('flashlight off')) {
      return `Torch turned off, ${salutation}. (Add an API key in Vault to unlock full intelligence.)`;
    }
    if (lower.includes('schedule') || lower.includes('agenda') || lower.includes('tasks today')) {
      const summary = secretaryDataManager.getFullSecretaryContext();
      return `Here is your day, ${salutation}: ${summary}.`;
    }
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
    if (lower.includes('alarm')) {
      const match = lower.match(/(?:set|wake me at|for)\s+([0-9]+(?::[0-9]+)?(?:\s*[ap]m)?)/i);
      if (match) {
        const alarm = secretaryDataManager.setAlarm(match[1]);
        return `Alarm configured for ${alarm.time}, ${salutation}.`;
      }
    }
    if (lower.includes('office mode') || lower.includes('work mode') || lower.includes('professional mode')) {
      modeManager.setMode('PROFESSIONAL');
      return `Professional mode engaged, Sir. Standing by for executive tasks.`;
    }
    if (lower.includes('home mode') || lower.includes('friendly mode') || lower.includes('relax mode')) {
      modeManager.setMode('HOME');
      return `Home mode activated, buddy. How was your day?`;
    }

    return `Direct device rules (torch, volume, alarm, open app, call, time) are active, ${salutation}. Add an API key in Vault to unlock full intelligence.`;
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

    const systemInstruction = this.assembleSystemContext(userMessage);
    const history = storageService.getChatHistory().slice(-8);
    const fullPrompt = [
      ...history.map((h: ChatMessage) => `${h.role === 'user' ? 'Teja' : 'Vyshu'}: ${h.text}`),
      `Teja: ${userMessage}`,
    ].join('\n');

    // 1. Try GeminiProvider via LLMProvider layer
    const geminiCred = vyshuVaultManager.acquireActiveCredential('gemini');
    let geminiKeyToUse = geminiCred?.rawKey;
    const geminiCredId = geminiCred?.id;

    if (!geminiKeyToUse) {
      const keys = this.getActiveKeys();
      if (keys.length > 0) {
        if (this.currentKeyIndex >= keys.length) this.currentKeyIndex = 0;
        geminiKeyToUse = keys[this.currentKeyIndex];
        this.currentKeyIndex = (this.currentKeyIndex + 1) % keys.length;
      }
    }

    if (geminiKeyToUse && navigator.onLine) {
      const geminiProvider = REGISTERED_LLM_PROVIDERS.gemini;
      const res = await geminiProvider.complete({
        prompt: fullPrompt,
        systemPrompt: systemInstruction,
        apiKey: geminiKeyToUse,
        keyId: geminiCredId,
      });

      if (res.success && res.text) {
        let candidate = res.text;
        const actionMatch = candidate.match(/\[ACTION:\s*[A-Z_]+(?::.*?)?\]/g);
        if (actionMatch) {
          actionMatch.forEach((act) => {
            toolExecutor.executeTool(act);
            candidate = candidate.replace(act, '').trim();
          });
        }
        return { text: candidate.trim(), id: turnId };
      } else if (res.isRateLimited && geminiCredId) {
        vyshuVaultManager.reportRateLimit(geminiCredId, 60);
      } else if (res.isInvalidKey && geminiCredId) {
        vyshuVaultManager.reportInvalidKey(geminiCredId);
      }
    }

    // 2. Fallback to OpenAICompatibleProvider (Groq) via LLMProvider layer
    const groqCred = vyshuVaultManager.acquireActiveCredential('groq');
    const legacyGroq = storageService.getVaultKeys().groq?.trim();
    const groqKey = groqCred?.rawKey || legacyGroq;

    if (groqKey && navigator.onLine) {
      const groqProvider = REGISTERED_LLM_PROVIDERS.groq;
      const groqRes = await groqProvider.complete({
        prompt: fullPrompt,
        systemPrompt: systemInstruction,
        apiKey: groqKey,
        keyId: groqCred?.id,
      });

      if (groqRes.success && groqRes.text) {
        let reply = groqRes.text;
        const actionMatch = reply.match(/\[ACTION:\s*[A-Z_]+(?::.*?)?\]/g);
        if (actionMatch) {
          actionMatch.forEach((act) => {
            toolExecutor.executeTool(act);
            reply = reply.replace(act, '').trim();
          });
        }
        return { text: reply.trim(), id: turnId };
      }
    }

    return { text: this.getOfflineResponse(userMessage, currentMode), id: turnId };
  }

  public deleteTurn(turnId: string): void {
    const history = storageService.getChatHistory();
    const updated = history.filter((m: ChatMessage) => m.turnId !== turnId && m.id !== turnId);
    storageService.saveChatHistory(updated);
  }
}

export const brainService = new BrainService();
