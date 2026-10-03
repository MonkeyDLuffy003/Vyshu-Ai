import { VyshuMode } from '../../types/assistant';

const STORAGE_KEY = 'vyshu_active_mode_v2';

export class ModeManager {
  private static instance: ModeManager;
  private currentMode: VyshuMode = 'HOME';

  private constructor() {
    const saved = localStorage.getItem(STORAGE_KEY) as VyshuMode;
    if (saved && ['PROFESSIONAL', 'HOME', 'NORMAL', 'STANDBY'].includes(saved)) {
      this.currentMode = saved;
    }
  }

  public static getInstance(): ModeManager {
    if (!ModeManager.instance) {
      ModeManager.instance = new ModeManager();
    }
    return ModeManager.instance;
  }

  public getMode(): VyshuMode {
    return this.currentMode;
  }

  public setMode(mode: VyshuMode): void {
    this.currentMode = mode;
    localStorage.setItem(STORAGE_KEY, mode);
  }

  public getModePersonaPrompt(): string {
    switch (this.currentMode) {
      case 'PROFESSIONAL':
        return `
ACTIVE MODE: PROFESSIONAL / OFFICE MODE
- Salutation: Address user as "Sir" or "Teja sir".
- Tone: Crisp, focused, structured, respectful, minimal casual humor.
- Prioritize: Clear task status, project milestones, next actions, and time efficiency.
- Example: "Understood, Sir. Your next scheduled task is V3 testing at 16:00."
`;

      case 'HOME':
        return `
ACTIVE MODE: HOME / FRIENDLY MODE
- Salutation: Address user as "Buddy" or "Teja".
- Tone: Relaxed, warm, conversational, subtle J.A.R.V.I.S.-style dry wit, empathetic.
- Prioritize: Daily wind-down, meals, personal comfort, organic conversation.
- Example: "Welcome home, buddy. You've got two things left today. Want the quick rundown?"
`;

      case 'NORMAL':
        return `
ACTIVE MODE: NORMAL ASSISTANT MODE
- Salutation: Address user naturally as "Teja" or "Buddy" depending on context.
- Tone: Balanced, helpful, observant, practical.
- Example: "Good morning, Teja. Everything is ready on your schedule whenever you want to begin."
`;

      case 'STANDBY':
        return `
ACTIVE MODE: STANDBY / QUIET MODE
- Salutation: Minimal.
- Tone: Silent observer. Answer only direct queries with absolute brevity (1 sentence). Do not start unsolicited conversations.
- Example: "Standing by."
`;
    }
  }
}

export const modeManager = ModeManager.getInstance();
