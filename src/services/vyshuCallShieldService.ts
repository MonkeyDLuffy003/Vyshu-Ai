// Vyshu AI Call Screening & Identity Protection Shield Service
// Protects Teja from spam, scammers, telemarketers, and unknown callers.
// Vyshu answers the call in her own voice, conceals Teja's real identity,
// questions the caller, extracts the transcript/intent, and only rings Teja if verified safe.

export type CallThreatLevel = 'SAFE_CONTACT' | 'SCREENING_IN_PROGRESS' | 'SPAM_BLOCKED' | 'SCAMMER_DEFLECTED' | 'VERIFIED_VIP';

export interface ScreenedCallRecord {
  id: string;
  callerNumber: string;
  callerName?: string;
  timestamp: string;
  status: 'BLOCKED' | 'DEFLECTED' | 'TRANSFERRED_TO_TEJA' | 'VOICEMAIL_RECORDED' | 'SCREENING';
  threatLevel: CallThreatLevel;
  durationSeconds: number;
  vyshuSpokenIntro: string;
  callerTranscript: string[];
  vyshuAiSummary: string;
  isSpamDetected: boolean;
  identityShieldActive: boolean; // When true, Teja's name and location were completely concealed
}

export interface CallShieldSettings {
  autoScreenUnknownNumbers: boolean;
  autoBlockKnownSpam: boolean;
  concealTejaIdentity: boolean;
  aiVoiceAvatar: 'vyshu-executive' | 'vyshu-playful' | 'vyshu-cyber';
  recordingEnabled: boolean;
  autoSpamDatabaseCheck: boolean;
  vipWhitelistNumbers: string[];
}

const STORAGE_KEY_SHIELD_SETTINGS = 'vyshu_call_shield_settings_v1';
const STORAGE_KEY_CALL_LOGS = 'vyshu_screened_call_logs_v1';

export const DEFAULT_SHIELD_SETTINGS: CallShieldSettings = {
  autoScreenUnknownNumbers: true,
  autoBlockKnownSpam: true,
  concealTejaIdentity: true,
  aiVoiceAvatar: 'vyshu-executive',
  recordingEnabled: true,
  autoSpamDatabaseCheck: true,
  vipWhitelistNumbers: ['Mom', 'Dad', 'Work Priority'],
};

// Initial realistic call logs demonstrating Vyshu in action
export const SAMPLE_SCREENED_CALLS: ScreenedCallRecord[] = [
  {
    id: 'call-101',
    callerNumber: '+91 98480 22338',
    callerName: 'Potential Credit Card Telemarketer',
    timestamp: 'Today at 09:12 AM',
    status: 'DEFLECTED',
    threatLevel: 'SPAM_BLOCKED',
    durationSeconds: 42,
    vyshuSpokenIntro: 'Hello. You have reached the executive AI gateway of this mobile terminal. The device owner is currently unavailable. Please state your name, organization, and the explicit purpose of your call.',
    callerTranscript: [
      'Caller: Hello sir? Am I speaking to the card holder? We have a pre-approved personal loan at zero percent interest...',
      'Vyshu AI: Notice: This terminal is protected by Vyshu AI Security Protocol. Your solicitation has been flagged as unverified telemarketing. Your number is logged and restricted. Have a productive day.',
    ],
    vyshuAiSummary: 'Blocked pre-approved loan spam. Teja’s name was never revealed. Number flagged and silenced.',
    isSpamDetected: true,
    identityShieldActive: true,
  },
  {
    id: 'call-102',
    callerNumber: '+91 80002 91104',
    callerName: 'Electricity Bill Urgency Scam',
    timestamp: 'Yesterday at 04:30 PM',
    status: 'BLOCKED',
    threatLevel: 'SCAMMER_DEFLECTED',
    durationSeconds: 28,
    vyshuSpokenIntro: 'Hello, this is Vyshu AI, autonomous secretary. Who is calling and what is the reference ticket number?',
    callerTranscript: [
      'Caller: Urgent alert! Your power connection will be disconnected by 9 PM tonight unless you pay immediately via APK link...',
      'Vyshu AI: Fraudulent script detected matching known phishing attack vector. Disconnecting and reporting to Telecom Registry.',
    ],
    vyshuAiSummary: 'Phishing scam detected. Scammer hung up after Vyshu requested utility verification credentials.',
    isSpamDetected: true,
    identityShieldActive: true,
  },
  {
    id: 'call-103',
    callerNumber: '+91 94401 55672',
    callerName: 'Amazon Delivery Courier',
    timestamp: 'Yesterday at 01:15 PM',
    status: 'TRANSFERRED_TO_TEJA',
    threatLevel: 'SAFE_CONTACT',
    durationSeconds: 35,
    vyshuSpokenIntro: 'Hello, this is Vyshu AI. How may I direct your call?',
    callerTranscript: [
      'Caller: Hi madam, I am from Amazon Delivery. I am outside the building gate with the package.',
      'Vyshu AI: Verified delivery courier for incoming parcel. Ringing Teja right now.',
    ],
    vyshuAiSummary: 'Verified Amazon delivery agent at gate. Vyshu patched call through to Teja with priority beep.',
    isSpamDetected: false,
    identityShieldActive: true,
  },
];

class VyshuCallShieldService {
  private settings: CallShieldSettings = DEFAULT_SHIELD_SETTINGS;
  private callLogs: ScreenedCallRecord[] = [];

  constructor() {
    this.loadState();
  }

  private loadState() {
    try {
      const savedSettings = localStorage.getItem(STORAGE_KEY_SHIELD_SETTINGS);
      if (savedSettings) {
        this.settings = { ...DEFAULT_SHIELD_SETTINGS, ...JSON.parse(savedSettings) };
      }
      const savedLogs = localStorage.getItem(STORAGE_KEY_CALL_LOGS);
      if (savedLogs) {
        this.callLogs = JSON.parse(savedLogs);
      } else {
        this.callLogs = SAMPLE_SCREENED_CALLS;
        this.saveLogs();
      }
    } catch {
      this.settings = DEFAULT_SHIELD_SETTINGS;
      this.callLogs = SAMPLE_SCREENED_CALLS;
    }
  }

  public getSettings(): CallShieldSettings {
    return this.settings;
  }

  public updateSettings(partial: Partial<CallShieldSettings>): void {
    this.settings = { ...this.settings, ...partial };
    localStorage.setItem(STORAGE_KEY_SHIELD_SETTINGS, JSON.stringify(this.settings));
  }

  public getCallLogs(): ScreenedCallRecord[] {
    return this.callLogs;
  }

  public saveLogs(): void {
    localStorage.setItem(STORAGE_KEY_CALL_LOGS, JSON.stringify(this.callLogs));
  }

  // Simulate or process an incoming phone call
  public simulateIncomingCall(callerNumber: string, callerName?: string, isSpamSimulation: boolean = true): ScreenedCallRecord {
    const isSpam = isSpamSimulation || callerNumber.startsWith('+1800') || callerNumber.includes('9999');
    const id = `call-${Date.now()}`;
    const newRecord: ScreenedCallRecord = {
      id,
      callerNumber,
      callerName: callerName || (isSpam ? 'Suspicious Robocaller' : 'Unknown Caller'),
      timestamp: 'Just now',
      status: isSpam ? 'DEFLECTED' : 'TRANSFERRED_TO_TEJA',
      threatLevel: isSpam ? 'SPAM_BLOCKED' : 'SAFE_CONTACT',
      durationSeconds: isSpam ? 24 : 18,
      vyshuSpokenIntro: 'Hello, this is Vyshu AI, executive secretary. Who is calling and what is the matter regarding?',
      callerTranscript: isSpam
        ? [
            `Caller (${callerNumber}): "Congratulations! You have been selected for free insurance upgrade..."`,
            'Vyshu AI: "Identity Shield active. Unsolicited commercial caller intercepted. Teja will not be disturbed."',
          ]
        : [
            `Caller (${callerNumber}): "Hi, I am calling regarding the project review schedule."`,
            'Vyshu AI: "Verified legitimate inquiry. Notifying Teja with your caller note."',
          ],
      vyshuAiSummary: isSpam
        ? 'Spam detected and deflected. Call automatically terminated. Teja remained undisturbed.'
        : 'Legitimate caller verified. Forwarded to Teja with transcript.',
      isSpamDetected: isSpam,
      identityShieldActive: true,
    };

    this.callLogs.unshift(newRecord);
    this.saveLogs();
    return newRecord;
  }

  public deleteLog(id: string): void {
    this.callLogs = this.callLogs.filter((c) => c.id !== id);
    this.saveLogs();
  }

  public clearAllLogs(): void {
    this.callLogs = [];
    this.saveLogs();
  }
}

export const vyshuCallShieldService = new VyshuCallShieldService();
