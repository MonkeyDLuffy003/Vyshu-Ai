/**
 * LLMProvider Layer & ProviderManager (TypeScript)
 * Strictly isolates all LLM calls behind the LLMProvider interface.
 */

export type ProviderCostTier = 'free' | 'cheap' | 'standard' | 'on_device';
export type KeyHealthStatus = 'working' | 'rate_limited' | 'invalid' | 'disabled' | 'untested';

export interface LLMResponse {
  success: boolean;
  text: string;
  providerId: string;
  keyId?: string;
  error?: string;
  isRateLimited?: boolean;
  isInvalidKey?: boolean;
}

export interface LLMProvider {
  id: string;
  displayName: string;
  baseUrl: string;
  defaultModel: string;
  supportsVision: boolean;
  supportsJson: boolean;
  costTier: ProviderCostTier;
  complete(params: {
    prompt: string;
    systemPrompt: string;
    apiKey: string;
    keyId?: string;
    jsonSchema?: Record<string, unknown>;
    modelOverride?: string;
  }): Promise<LLMResponse>;
  testKey(apiKey: string): Promise<LLMResponse>;
}

export class GeminiProvider implements LLMProvider {
  public id = 'gemini';
  public displayName = 'Google Gemini 2.5 Flash';
  public baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  public defaultModel = 'gemini-2.5-flash';
  public supportsVision = true;
  public supportsJson = true;
  public costTier: ProviderCostTier = 'free';

  public async complete(params: {
    prompt: string;
    systemPrompt: string;
    apiKey: string;
    keyId?: string;
    jsonSchema?: Record<string, unknown>;
    modelOverride?: string;
  }): Promise<LLMResponse> {
    const model = params.modelOverride || this.defaultModel;
    console.info(`VYSHU_AGENT: [GeminiProvider] Calling ${model}`);
    try {
      const url = `${this.baseUrl}/models/${model}:generateContent?key=${params.apiKey.trim()}`;
      const generationConfig: Record<string, unknown> = {
        temperature: params.jsonSchema ? 0.1 : 0.65,
      };
      if (params.jsonSchema) {
        generationConfig.responseMimeType = 'application/json';
      }

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: params.systemPrompt }] },
          contents: [{ role: 'user', parts: [{ text: params.prompt }] }],
          generationConfig,
        }),
        signal: AbortSignal.timeout(18000),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
        return {
          success: true,
          text: text.trim(),
          providerId: this.id,
          keyId: params.keyId,
        };
      }
      if (res.status === 429) {
        return {
          success: false,
          text: '',
          providerId: this.id,
          keyId: params.keyId,
          error: 'Rate limit reached (429)',
          isRateLimited: true,
        };
      }
      if (res.status === 400 || res.status === 403) {
        const body = await res.text();
        return {
          success: false,
          text: '',
          providerId: this.id,
          keyId: params.keyId,
          error: 'Invalid or unauthorized Gemini key',
          isInvalidKey: body.includes('API_KEY_INVALID') || res.status === 403,
        };
      }
      return {
        success: false,
        text: '',
        providerId: this.id,
        keyId: params.keyId,
        error: `Gemini HTTP ${res.status}`,
      };
    } catch (e: any) {
      return {
        success: false,
        text: '',
        providerId: this.id,
        keyId: params.keyId,
        error: e?.message || 'Network error',
      };
    }
  }

  public async testKey(apiKey: string): Promise<LLMResponse> {
    return this.complete({
      prompt: 'Reply with the single word OK.',
      systemPrompt: 'Connectivity test.',
      apiKey,
    });
  }
}

export class OpenAICompatibleProvider implements LLMProvider {
  public id: string;
  public displayName: string;
  public baseUrl: string;
  public defaultModel: string;
  public supportsVision: boolean;
  public supportsJson: boolean;
  public costTier: ProviderCostTier;

  constructor(config: {
    id: string;
    displayName: string;
    baseUrl: string;
    defaultModel: string;
    supportsVision?: boolean;
    supportsJson?: boolean;
    costTier?: ProviderCostTier;
  }) {
    this.id = config.id;
    this.displayName = config.displayName;
    this.baseUrl = config.baseUrl;
    this.defaultModel = config.defaultModel;
    this.supportsVision = config.supportsVision ?? false;
    this.supportsJson = config.supportsJson ?? true;
    this.costTier = config.costTier ?? 'free';
  }

  public async complete(params: {
    prompt: string;
    systemPrompt: string;
    apiKey: string;
    keyId?: string;
    jsonSchema?: Record<string, unknown>;
    modelOverride?: string;
  }): Promise<LLMResponse> {
    const model = params.modelOverride || this.defaultModel;
    console.info(`VYSHU_AGENT: [OpenAICompat:${this.id}] Calling ${model}`);
    try {
      const body: Record<string, unknown> = {
        model,
        messages: [
          { role: 'system', content: params.systemPrompt },
          { role: 'user', content: params.prompt },
        ],
        temperature: params.jsonSchema ? 0.1 : 0.65,
      };
      if (params.jsonSchema && this.supportsJson) {
        body.response_format = { type: 'json_object' };
      }

      const res = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${params.apiKey.trim()}`,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(18000),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.choices?.[0]?.message?.content || '';
        return {
          success: true,
          text: text.trim(),
          providerId: this.id,
          keyId: params.keyId,
        };
      }
      if (res.status === 429) {
        return {
          success: false,
          text: '',
          providerId: this.id,
          keyId: params.keyId,
          error: 'Rate limit reached (429)',
          isRateLimited: true,
        };
      }
      if (res.status === 401 || res.status === 403) {
        return {
          success: false,
          text: '',
          providerId: this.id,
          keyId: params.keyId,
          error: 'Invalid API key',
          isInvalidKey: true,
        };
      }
      return {
        success: false,
        text: '',
        providerId: this.id,
        keyId: params.keyId,
        error: `${this.displayName} HTTP ${res.status}`,
      };
    } catch (e: any) {
      return {
        success: false,
        text: '',
        providerId: this.id,
        keyId: params.keyId,
        error: e?.message || 'Network error',
      };
    }
  }

  public async testKey(apiKey: string): Promise<LLMResponse> {
    return this.complete({
      prompt: 'Reply with the single word OK.',
      systemPrompt: 'Connectivity test.',
      apiKey,
    });
  }
}

export class OnDeviceProvider implements LLMProvider {
  public static isEnabledFlag = false;
  public id = 'on_device';
  public displayName = 'On-Device Local Model (Stub)';
  public baseUrl = 'local://mediapipe';
  public defaultModel = 'gemma-2b-it-int4';
  public supportsVision = false;
  public supportsJson = true;
  public costTier: ProviderCostTier = 'on_device';

  public async complete(): Promise<LLMResponse> {
    return {
      success: false,
      text: '',
      providerId: this.id,
      error: 'On-device model weights disabled behind flag.',
    };
  }

  public async testKey(): Promise<LLMResponse> {
    return this.complete();
  }
}

export const REGISTERED_LLM_PROVIDERS: Record<string, LLMProvider> = {
  gemini: new GeminiProvider(),
  groq: new OpenAICompatibleProvider({
    id: 'groq',
    displayName: 'Groq Cloud (Llama 3.3 70B)',
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
  }),
  openrouter: new OpenAICompatibleProvider({
    id: 'openrouter',
    displayName: 'OpenRouter (Multi-Model Free)',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'meta-llama/llama-3.3-70b-instruct:free',
  }),
  mistral: new OpenAICompatibleProvider({
    id: 'mistral',
    displayName: 'Mistral AI',
    baseUrl: 'https://api.mistral.ai/v1',
    defaultModel: 'mistral-small-latest',
  }),
  on_device: new OnDeviceProvider(),
};
