import { vyshuVaultManager, ManagedCredential } from './VaultRegistry';

export interface AdapterResult<T> {
  success: boolean;
  data?: T;
  error?: string;
  isRateLimited?: boolean;
  isInvalidKey?: boolean;
}

export interface ProviderAdapter<Req, Resp> {
  providerId: string;
  execute(request: Req): Promise<AdapterResult<Resp>>;
}

/**
 * GEMINI 2.5 FLASH FREE-TIER ADAPTER
 */
export class GeminiAdapter implements ProviderAdapter<string, string> {
  public providerId = 'gemini';

  public async execute(prompt: string, systemInstruction?: string): Promise<AdapterResult<string>> {
    const cred: ManagedCredential | null = vyshuVaultManager.acquireActiveCredential('gemini');
    if (!cred || !cred.rawKey) {
      return { success: false, error: 'No active Gemini key available in Vault' };
    }

    try {
      const contents = [
        ...(systemInstruction
          ? [
              {
                role: 'user',
                parts: [{ text: systemInstruction }],
              },
              {
                role: 'model',
                parts: [{ text: 'Understood. Standing by for command.' }],
              },
            ]
          : []),
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ];

      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${cred.rawKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents }),
        signal: AbortSignal.timeout(16000),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        return { success: true, data: text || '' };
      }

      if (res.status === 429) {
        vyshuVaultManager.reportRateLimit(cred.id, 60);
        return { success: false, isRateLimited: true, error: 'Quota or rate limit reached on Gemini key' };
      }

      if (res.status === 400 || res.status === 403) {
        const errBody = await res.text();
        if (errBody.includes('API_KEY_INVALID')) {
          vyshuVaultManager.reportInvalidKey(cred.id);
          return { success: false, isInvalidKey: true, error: 'Gemini API key is invalid' };
        }
      }

      return { success: false, error: `Gemini HTTP ${res.status}` };
    } catch (e: any) {
      return { success: false, error: e?.message || 'Network failure' };
    }
  }
}

/**
 * GROQ CLOUD FREE-TIER ADAPTER (Llama 3.3 70B)
 */
export class GroqAdapter implements ProviderAdapter<string, string> {
  public providerId = 'groq';

  public async execute(prompt: string, systemInstruction?: string): Promise<AdapterResult<string>> {
    const cred: ManagedCredential | null = vyshuVaultManager.acquireActiveCredential('groq');
    if (!cred || !cred.rawKey) {
      return { success: false, error: 'No active Groq key available in Vault' };
    }

    try {
      const messages = [
        ...(systemInstruction ? [{ role: 'system', content: systemInstruction }] : []),
        { role: 'user', content: prompt },
      ];

      const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${cred.rawKey}`,
        },
        body: JSON.stringify({
          model: 'llama-3.3-70b-versatile',
          messages,
          temperature: 0.7,
        }),
        signal: AbortSignal.timeout(15000),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.choices?.[0]?.message?.content;
        return { success: true, data: text || '' };
      }

      if (res.status === 429) {
        vyshuVaultManager.reportRateLimit(cred.id, 60);
        return { success: false, isRateLimited: true, error: 'Groq rate limit reached' };
      }

      if (res.status === 401) {
        vyshuVaultManager.reportInvalidKey(cred.id);
        return { success: false, isInvalidKey: true, error: 'Groq API Key invalid' };
      }

      return { success: false, error: `Groq HTTP ${res.status}` };
    } catch (e: any) {
      return { success: false, error: e?.message || 'Network failure' };
    }
  }
}

/**
 * DUCKDUCKGO FREE WEB SEARCH ADAPTER (Zero-Key Fair Use)
 */
export class DuckDuckGoSearchAdapter implements ProviderAdapter<string, string[]> {
  public providerId = 'duckduckgo';

  public async execute(query: string): Promise<AdapterResult<string[]>> {
    try {
      const url = `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1&skip_disambig=1`;
      const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
      if (res.ok) {
        const data = await res.json();
        const results: string[] = [];
        if (data.AbstractText) results.push(data.AbstractText);
        if (Array.isArray(data.RelatedTopics)) {
          data.RelatedTopics.slice(0, 4).forEach((topic: any) => {
            if (topic.Text) results.push(topic.Text);
          });
        }
        return { success: true, data: results };
      }
      return { success: false, error: `Search HTTP ${res.status}` };
    } catch (e: any) {
      return { success: false, error: e?.message || 'Search failed' };
    }
  }
}

/**
 * OPENSTREETMAP / NOMINATIM FREE GEOCODING ADAPTER
 */
export class NominatimMapsAdapter implements ProviderAdapter<string, { lat: string; lon: string; name: string }> {
  public providerId = 'openstreetmap';

  public async execute(locationQuery: string): Promise<AdapterResult<{ lat: string; lon: string; name: string }>> {
    try {
      const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(locationQuery)}&format=json&limit=1`;
      const res = await fetch(url, {
        headers: { 'User-Agent': 'VyshuAI-WebHybrid/1.0' },
        signal: AbortSignal.timeout(8000),
      });

      if (res.ok) {
        const list = await res.json();
        if (Array.isArray(list) && list.length > 0) {
          const item = list[0];
          return {
            success: true,
            data: { lat: item.lat, lon: item.lon, name: item.display_name },
          };
        }
        return { success: false, error: 'Location not found' };
      }
      return { success: false, error: `Nominatim HTTP ${res.status}` };
    } catch (e: any) {
      return { success: false, error: e?.message || 'Maps service unavailable' };
    }
  }
}

export const geminiAdapter = new GeminiAdapter();
export const groqAdapter = new GroqAdapter();
export const searchAdapter = new DuckDuckGoSearchAdapter();
export const mapsAdapter = new NominatimMapsAdapter();
