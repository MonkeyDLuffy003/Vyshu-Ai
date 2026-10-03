/**
 * VYSHU AI MULTI-PROVIDER VAULT REGISTRY & ROTATION STATE MACHINE (TYPESCRIPT)
 * Provides provider management, quota tracking, state transitions, and key leases
 * for the AI Orchestration layer.
 */

export type KeyCategory =
  | 'ai'
  | 'webSearch'
  | 'news'
  | 'maps'
  | 'navigation'
  | 'image'
  | 'video'
  | 'voice'
  | 'audio'
  | 'translation'
  | 'cloud'
  | 'communication';

export type RotationState = 'AVAILABLE' | 'ACTIVE' | 'COOLDOWN' | 'DISABLED' | 'INVALID';

export interface ManagedCredential {
  id: string;
  providerId: string;
  keyAlias: string;
  rawKey: string;
  state: RotationState;
  cooldownUntil: number; // timestamp ms
  lastUsedTimestamp: number;
  errorCountToday: number;
  dailyRequestCount: number;
}

export interface ProviderSpec {
  id: string;
  displayName: string;
  category: KeyCategory;
  documentationUrl: string;
  freeTierSummary: string;
  defaultCooldownSeconds: number;
  isDefaultFree: boolean;
}

export const SUPPORTED_PROVIDERS: ProviderSpec[] = [
  // --- AI / LLM BRAIN ---
  {
    id: 'gemini',
    displayName: 'Google Gemini 2.5 Flash',
    category: 'ai',
    documentationUrl: 'https://aistudio.google.com/apikey',
    freeTierSummary: '15 RPM, 1M TPM, 1,500 RPD free allowance',
    defaultCooldownSeconds: 60,
    isDefaultFree: true,
  },
  {
    id: 'groq',
    displayName: 'Groq Cloud (Llama 3.3 70B)',
    category: 'ai',
    documentationUrl: 'https://console.groq.com/keys',
    freeTierSummary: '30 RPM, 14,400 RPD free allowance',
    defaultCooldownSeconds: 60,
    isDefaultFree: true,
  },
  {
    id: 'huggingface',
    displayName: 'Hugging Face Serverless Inference',
    category: 'ai',
    documentationUrl: 'https://huggingface.co/settings/tokens',
    freeTierSummary: 'Free user token serverless rate limited access',
    defaultCooldownSeconds: 120,
    isDefaultFree: true,
  },

  // --- WEB SEARCH ---
  {
    id: 'duckduckgo',
    displayName: 'DuckDuckGo Instant Answers',
    category: 'webSearch',
    documentationUrl: 'https://duckduckgo.com',
    freeTierSummary: 'Zero key required / Open fair-use query API',
    defaultCooldownSeconds: 30,
    isDefaultFree: true,
  },
  {
    id: 'tavily',
    displayName: 'Tavily Search API',
    category: 'webSearch',
    documentationUrl: 'https://tavily.com',
    freeTierSummary: '1,000 free search API queries per month',
    defaultCooldownSeconds: 60,
    isDefaultFree: true,
  },

  // --- MAPS / NAVIGATION ---
  {
    id: 'openstreetmap',
    displayName: 'OpenStreetMap / Nominatim',
    category: 'maps',
    documentationUrl: 'https://nominatim.org',
    freeTierSummary: '1 req/sec free geocoding and location resolution',
    defaultCooldownSeconds: 10,
    isDefaultFree: true,
  },
  {
    id: 'osrm',
    displayName: 'OSRM Route Machine',
    category: 'navigation',
    documentationUrl: 'https://project-osrm.org',
    freeTierSummary: 'Free open routing & travel time calculation',
    defaultCooldownSeconds: 10,
    isDefaultFree: true,
  },

  // --- IMAGE AI ---
  {
    id: 'pollinations',
    displayName: 'Pollinations.ai Free Image Gen',
    category: 'image',
    documentationUrl: 'https://pollinations.ai',
    freeTierSummary: 'Free open tier image synthesis / zero key required',
    defaultCooldownSeconds: 30,
    isDefaultFree: true,
  },

  // --- COMMUNICATION ---
  {
    id: 'discord',
    displayName: 'Discord Bot Gateway',
    category: 'communication',
    documentationUrl: 'https://discord.com/developers/applications',
    freeTierSummary: 'Standard free Discord Bot Gateway token',
    defaultCooldownSeconds: 60,
    isDefaultFree: true,
  },
];

const VAULT_STORAGE_KEY = 'vyshu_vault_multiprovider_credentials_v1';

export class VyshuVaultManager {
  private credentials: ManagedCredential[] = [];

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    try {
      const raw = localStorage.getItem(VAULT_STORAGE_KEY);
      if (raw) {
        this.credentials = JSON.parse(raw);
      } else {
        this.migrateLegacyKeys();
      }
    } catch {
      this.credentials = [];
    }
    this.cleanExpiredCooldowns();
  }

  private saveToStorage(): void {
    try {
      localStorage.setItem(VAULT_STORAGE_KEY, JSON.stringify(this.credentials));
    } catch (e) {
      console.error('Failed to save credentials to vault storage', e);
    }
  }

  private migrateLegacyKeys(): void {
    try {
      const legacyRaw = localStorage.getItem('vyshu_vault_keys');
      if (legacyRaw) {
        const keys = JSON.parse(legacyRaw);
        const geminiKeys = [keys.gemini_1, keys.gemini_2, keys.gemini_3, keys.gemini_4, keys.gemini_5];
        geminiKeys.forEach((k, idx) => {
          if (k && k.trim().length > 8) {
            this.credentials.push({
              id: `gemini-${idx + 1}-${Date.now()}`,
              providerId: 'gemini',
              keyAlias: `Gemini Key #${idx + 1}`,
              rawKey: k.trim(),
              state: 'AVAILABLE',
              cooldownUntil: 0,
              lastUsedTimestamp: 0,
              errorCountToday: 0,
              dailyRequestCount: 0,
            });
          }
        });

        if (keys.groq && keys.groq.trim().length > 8) {
          this.credentials.push({
            id: `groq-1-${Date.now()}`,
            providerId: 'groq',
            keyAlias: 'Groq Primary Key',
            rawKey: keys.groq.trim(),
            state: 'AVAILABLE',
            cooldownUntil: 0,
            lastUsedTimestamp: 0,
            errorCountToday: 0,
            dailyRequestCount: 0,
          });
        }
        this.saveToStorage();
      }
    } catch {
      // Ignored
    }
  }

  private cleanExpiredCooldowns(): void {
    const now = Date.now();
    let changed = false;
    for (const c of this.credentials) {
      if (c.state === 'COOLDOWN' && c.cooldownUntil <= now) {
        c.state = 'AVAILABLE';
        changed = true;
      }
    }
    if (changed) this.saveToStorage();
  }

  public acquireActiveCredential(providerId: string): ManagedCredential | null {
    this.cleanExpiredCooldowns();
    const pool = this.credentials.filter((c) => c.providerId === providerId);

    // 1. If there's an ACTIVE key already, reuse it
    for (const c of pool) {
      if (c.state === 'ACTIVE') {
        c.lastUsedTimestamp = Date.now();
        c.dailyRequestCount++;
        this.saveToStorage();
        return c;
      }
    }

    // 2. Otherwise promote the first AVAILABLE key
    for (const c of pool) {
      if (c.state === 'AVAILABLE') {
        c.state = 'ACTIVE';
        c.lastUsedTimestamp = Date.now();
        c.dailyRequestCount++;
        this.saveToStorage();
        return c;
      }
    }

    return null;
  }

  public reportRateLimit(credentialId: string, cooldownSeconds?: number): void {
    const cred = this.credentials.find((c) => c.id === credentialId);
    if (!cred) return;

    const spec = SUPPORTED_PROVIDERS.find((p) => p.id === cred.providerId);
    const duration = cooldownSeconds ?? (spec ? spec.defaultCooldownSeconds : 60);

    cred.state = 'COOLDOWN';
    cred.cooldownUntil = Date.now() + duration * 1000;
    cred.errorCountToday++;
    this.saveToStorage();
  }

  public reportInvalidKey(credentialId: string): void {
    const cred = this.credentials.find((c) => c.id === credentialId);
    if (cred) {
      cred.state = 'INVALID';
      this.saveToStorage();
    }
  }

  public getCredentialsForProvider(providerId: string): ManagedCredential[] {
    this.cleanExpiredCooldowns();
    return this.credentials.filter((c) => c.providerId === providerId);
  }

  public getAllCredentials(): ManagedCredential[] {
    this.cleanExpiredCooldowns();
    return [...this.credentials];
  }

  public addCredential(providerId: string, keyAlias: string, rawKey: string): ManagedCredential {
    const cred: ManagedCredential = {
      id: `cred-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      providerId,
      keyAlias: keyAlias.trim(),
      rawKey: rawKey.trim(),
      state: 'AVAILABLE',
      cooldownUntil: 0,
      lastUsedTimestamp: 0,
      errorCountToday: 0,
      dailyRequestCount: 0,
    };
    this.credentials.push(cred);
    this.saveToStorage();
    return cred;
  }

  public deleteCredential(id: string): void {
    this.credentials = this.credentials.filter((c) => c.id !== id);
    this.saveToStorage();
  }

  public toggleCredentialState(id: string): void {
    const cred = this.credentials.find((c) => c.id === id);
    if (cred) {
      cred.state = cred.state === 'DISABLED' ? 'AVAILABLE' : 'DISABLED';
      this.saveToStorage();
    }
  }

  public maskKey(raw: string): string {
    if (!raw) return '(empty)';
    if (raw.length <= 8) return '****';
    return `${raw.substring(0, 4)}...${raw.substring(raw.length - 4)}`;
  }
}

export const vyshuVaultManager = new VyshuVaultManager();
