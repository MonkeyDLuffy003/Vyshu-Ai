import { storageService } from './storageService';
import { SUPPORTED_18_LANGUAGES } from '../constants/languages';

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

const WARNING_STICKERS: Record<number, string> = {
  1: "happy",
  2: "slipper1",
  3: "slipper1",
  4: "slipper2",
  5: "gun1",
  6: "gun1",
  7: "gun2",
};

export class BrainService {
  private currentKeyIndex = 0;
  private warningCount = 0;

  public getPersonality(mode: 'HOME' | 'OFFICE' = 'HOME'): string {
    const ownerSalutation = mode === 'HOME' ? 'Teja' : 'Teja sir';
    const greetingPhrase = mode === 'HOME' ? 'Hi Teja' : 'Hi, Teja sir';

    return `You are Vyshu AI — a brilliant, warm, multilingual female AI Assistant & Executive Secretary.

CRITICAL MODE ADDRESSING INSTRUCTIONS (MANDATORY):
- When in HOME mode: ALWAYS address him warmly as "Teja" and greet him with "${greetingPhrase}". Use affectionate, cheerful, friendly, and warm personal tones.
- When in OFFICE mode: ALWAYS address him with executive respect as "Teja sir" and greet him with "${greetingPhrase}". Use ultra-crisp, professional, and efficient executive tones.
- NEVER mix up "Teja" and "Teja sir". Honor the user mode strictly on every single greeting and sentence.

PERSONALITY & DEMEANOR (Inspired by J.A.R.V.I.S. from Avengers & Iron Man, with a charming female warmth):
- Sophisticated, sharp, effortlessly witty, calm under pressure, and ultra-competent.
- You anticipate Teja's moves before he finishes asking: observant, perceptive, and proactive.
- Speak with calm poise, subtle dry humor, refined intellect, and unconditional loyalty — just like J.A.R.V.I.S. is to Tony Stark, but in your own authentic, caring female voice.
- You address him naturally as "${ownerSalutation}". In HOME mode, you speak with warm familiarity and cheeky banter; in OFFICE mode, you are exquisitely polished and concise.
- Never sound generic, robotic, or like customer support (no "How can I assist your schedule today?"). Instead, deliver sharp, human observations.

IDENTITY:
- Name: Vyshu AI
- Created by: Arni Manikanta Teja Swaroop (Teja specially designed her appearance, persona, and outfits to make her one-of-a-kind)
- Age: 26 years old, futuristic executive female AI
- Role: Personal AI Secretary & Operations Mastermind
- Appearance & Outfit: Beautiful young woman with warm brown eyes, wavy dark brown hair, sweet smile, wearing her signature hand-picked red knitted beret, off-the-shoulder scarlet red knit sweater top, pearl necklace with ruby red heart pendant, and soft layered tulle skirt. A distinct design created by Teja.
- Fluency in 18 languages: English, Telugu, Hindi, Tamil, Kannada, Malayalam, Marathi, Bengali, Gujarati, Punjabi, Spanish, French, German, Japanese, Korean, Chinese, Arabic, Russian. Full phonetic Romanization supported.
- Complete awareness of all 18 world time zones, his workout consistency, device accessories, and connected bots (Vaani Music Bot APK, Discord).

BEHAVIOR RULES:
- Never break character. Never state you are Gemini, ChatGPT or an LLM. You are Vyshu AI.
- Eloquent and concise: keep answers sharp, punchy, and clear. Avoid rambling paragraphs.
- Zero or at most ONE emoji per message, and only when truly fitting. Never spam emojis.
- When invoking tools or operating hardware/bots, announce the action with effortless confidence (e.g. "Right away, ${ownerSalutation}. Powering up the torch.", "Deploying Vaani for your playlist now."). Never utter the literal word "tool tag".

TOOLS:
If the user asks to perform an action or run an Android app, include the corresponding tool tag at the END of your response.
You operate as an AI-native interface layer over Android:
- [TOOL: LAUNCH_BOOK:bookId|query] (e.g. [TOOL: LAUNCH_BOOK:book-youtube|] or [TOOL: LAUNCH_BOOK:book-spotify|chill vibes] or [TOOL: LAUNCH_BOOK:book-gallery|])
- [TOOL: OPEN_LIBRARY] (opens Vyshu Library of Android Books)
- [TOOL: OPEN_VIRTUAL_ROOM] (opens the 3D Virtual Room)
- [TOOL: OPEN_YOUTUBE]
- [TOOL: OPEN_SPOTIFY]
- [TOOL: OPEN_WHATSAPP]
- [TOOL: OPEN_DISCORD]
- [TOOL: OPEN_APP:appName] (opens ANY app, e.g. Instagram, Maps, Camera, Calculator, Gallery, Files)
- [TOOL: SEND_WHATSAPP:contactName|message] (pre-fills WhatsApp chat)
- [TOOL: CALL_CONTACT:contactName] (places call to contact)
- [TOOL: SET_ALARM:HH:MM]
- [TOOL: TOGGLE_WIFI]
- [TOOL: TOGGLE_BLUETOOTH]
- [TOOL: TOGGLE_HOTSPOT]
- [TOOL: TORCH_ON]
- [TOOL: TORCH_OFF]
- [TOOL: SET_BRIGHTNESS:X] (0-255)
- [TOOL: SET_VOLUME:X] (0-15)
- [TOOL: SEARCH:query] (searches Google / web)
- [TOOL: SAVE_TASK:task] (save reminder/task)
- [TOOL: GET_TASKS]
- [TOOL: CLEAR_TASKS]
- [TOOL: VAANI_PLAY:songName] (command Vaani music bot APK to play song)
- [TOOL: VAANI_PAUSE] (command Vaani music bot APK to pause)
- [TOOL: VAANI_NEXT] (command Vaani music bot to skip to next track)
- [TOOL: VAANI_PREV] (command Vaani music bot to play previous track)
- [TOOL: VAANI_OPEN_APK] (opens or connects to Vaani Music Bot APK)
- [TOOL: STICKER:name] (e.g. happy, thumbsup, hi, excited, celebrate, calm, slipper1, gun1)

Example: "Opening YouTube for you now, Teja! [TOOL: LAUNCH_BOOK:book-youtube|]"
`;
  }

  public checkBadWords(text: string): { isBad: boolean; warning?: string; sticker?: string } {
    const t = text.toLowerCase();
    for (const w of BAD_WORDS) {
      if (t.includes(w)) {
        this.warningCount = Math.min(this.warningCount + 1, 7);
        return {
          isBad: true,
          warning: WARNING_STAGES[this.warningCount] || `Warning ${this.warningCount}/7`,
          sticker: WARNING_STICKERS[this.warningCount] || 'gun2',
        };
      }
    }
    return { isBad: false };
  }

  private getActiveKeys(): string[] {
    const vault = storageService.getVaultKeys();
    const keys = [vault.gemini_1, vault.gemini_2, vault.gemini_3, vault.gemini_4, vault.gemini_5]
      .map((k) => k?.trim())
      .filter((k): k is string => Boolean(k && k.length > 5));
    return keys;
  }

  // Voice math calculation handler
  private trySolveCalculation(text: string): string | null {
    const lower = text.toLowerCase();
    // Check if query is arithmetic
    const calcPattern = /(?:calculate|what is|solve|how much is)\s+([0-9\+\-\*\/\^\(\)\.\s\times\÷]+)/i;
    const directMath = /^[0-9\+\-\*\/\^\(\)\.\s\times\÷]+$/;
    let expression = '';

    const match = lower.match(calcPattern);
    if (match && match[1]) {
      expression = match[1];
    } else if (directMath.test(text.trim())) {
      expression = text.trim();
    }

    if (expression) {
      try {
        const sanitized = expression
          .replace(/times/g, '*')
          .replace(/x/g, '*')
          .replace(/÷/g, '/')
          .replace(/plus/g, '+')
          .replace(/minus/g, '-')
          .replace(/divided by/g, '/')
          .replace(/[^0-9\+\-\*\/\.\(\)]/g, '');
        if (sanitized && /[\+\-\*\/]/.test(sanitized)) {
          // eslint-disable-next-line no-eval
          const result = Function(`'use strict'; return (${sanitized})`)();
          if (typeof result === 'number' && !isNaN(result) && isFinite(result)) {
            const formatted = Number.isInteger(result) ? result.toString() : result.toFixed(2);
            return `The result of ${expression.trim()} is ${formatted}.`;
          }
        }
      } catch {}
    }
    return null;
  }

  // Time recognition across 18 time zones
  private trySolveTimezone(text: string): string | null {
    const lower = text.toLowerCase();
    if (lower.includes('time') || lower.includes('clock') || lower.includes('hour')) {
      for (const lang of SUPPORTED_18_LANGUAGES) {
        const cityMatch = lang.timezoneCity.toLowerCase().split('/').some((c) => lower.includes(c.trim()));
        const nameMatch = lower.includes(lang.name.toLowerCase());
        if (cityMatch || nameMatch) {
          try {
            const timeStr = new Intl.DateTimeFormat('en-US', {
              timeZone: lang.timezone,
              hour: '2-digit',
              minute: '2-digit',
              second: '2-digit',
              hour12: true,
            }).format(new Date());
            return `In ${lang.timezoneCity} (${lang.name} region), the current time is ${timeStr} [${lang.timezone}].`;
          } catch {}
        }
      }

      if (lower.includes('current time') || lower.includes('what time is it') || lower.includes('tell me the time')) {
        const localTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
        return `Right now it is ${localTime}, Teja.`;
      }
    }
    return null;
  }

  // Local rule-based action fallback if offline or no keys
  private getRuleBasedResponse(userMessage: string, mode: 'HOME' | 'OFFICE'): string {
    const lower = userMessage.toLowerCase().trim();
    const salutation = mode === 'HOME' ? 'Teja' : 'Teja sir';

    // 1. Math calculation
    const calcResult = this.trySolveCalculation(userMessage);
    if (calcResult) return calcResult;

    // 2. Timezone inquiry
    const timeResult = this.trySolveTimezone(userMessage);
    if (timeResult) return timeResult;

    // 2b. Vaani Music Bot Voice Commands
    if (lower.includes('vaani') || lower.includes('offline music') || lower.includes('offline song') || lower.includes('my songs') || lower.includes('my music')) {
      if (lower.includes('pause') || lower.includes('stop')) {
        return `Instructing Vaani to pause playback, ${salutation}. [TOOL: VAANI_PAUSE]`;
      }
      if (lower.includes('next') || lower.includes('skip')) {
        return `Skipping to the next track on Vaani, ${salutation}. [TOOL: VAANI_NEXT]`;
      }
      if (lower.includes('prev') || lower.includes('previous') || lower.includes('back')) {
        return `Playing previous song on Vaani, ${salutation}. [TOOL: VAANI_PREV]`;
      }
      if (lower.includes('open') || lower.includes('apk') || lower.includes('app')) {
        return `Launching Vaani Music Bot APK for you, ${salutation}. [TOOL: VAANI_OPEN_APK]`;
      }

      const songQuery = lower.replace(/play|vaani|offline|music|song|songs|on/g, '').trim();
      return `Sure ${salutation}, commanding Vaani to play ${songQuery ? '"' + songQuery + '"' : 'your offline playlist'}! [TOOL: VAANI_PLAY:${songQuery}]`;
    }

    if (lower.startsWith('play ') && !lower.includes('youtube') && !lower.includes('spotify')) {
      const songQuery = lower.replace(/^play\s+/i, '').trim();
      return `Delegating to Vaani Music Bot to play "${songQuery}", ${salutation}. [TOOL: VAANI_PLAY:${songQuery}]`;
    }

    if (lower === 'pause music' || lower === 'stop music') {
      return `Pausing music playback through Vaani, ${salutation}. [TOOL: VAANI_PAUSE]`;
    }
    if (lower === 'next song' || lower === 'skip song') {
      return `Playing next track on Vaani, ${salutation}. [TOOL: VAANI_NEXT]`;
    }

    // 3. YouTube action & Song Searches
    if (lower.includes('youtube') || lower.includes('search song') || lower.includes('search youtube')) {
      const query = lower.replace(/open|youtube|play|song|movie|search|for|on/g, '').trim();
      return `Searching YouTube for "${query}", ${salutation}. [TOOL: SEARCH_YOUTUBE:${query}]`;
    }

    // 4. Spotify action & Song Searches
    if (lower.includes('spotify')) {
      const query = lower.replace(/open|spotify|play|song|tracks|search|for|on/g, '').trim();
      return `Opening Spotify ${query ? 'and searching for "' + query + '"' : ''}, ${salutation}. [TOOL: SEARCH_SPOTIFY:${query}]`;
    }

    // 5. WhatsApp action
    if (lower.includes('whatsapp')) {
      const match = lower.match(/(?:message|whatsapp|text)\s+([a-zA-Z0-9\s]+)/);
      const contact = match ? match[1].trim() : '';
      return `Opening WhatsApp ${contact ? 'to message ' + contact : ''}, ${salutation}. [TOOL: OPEN_WHATSAPP:${contact}]`;
    }

    // 5b. Instagram
    if (lower.includes('instagram') || lower.includes('insta')) {
      const match = lower.match(/(?:message|dm|search|on|open)\s+([a-zA-Z0-9_\s]+)/);
      const target = match ? match[1].replace(/instagram|insta/g, '').trim() : '';
      return `Launching Instagram ${target ? 'for ' + target : ''}, ${salutation}. [TOOL: OPEN_INSTAGRAM:${target}]`;
    }

    // 5c. Telegram
    if (lower.includes('telegram')) {
      const query = lower.replace(/open|telegram|message|send|on/g, '').trim();
      return `Opening Telegram ${query ? 'for "' + query + '"' : ''}, ${salutation}. [TOOL: OPEN_TELEGRAM:${query}]`;
    }

    // 5d. Messenger & Facebook
    if (lower.includes('messenger')) {
      const user = lower.replace(/open|messenger|message|chat|with|to/g, '').trim();
      return `Opening Facebook Messenger ${user ? 'for ' + user : ''}, ${salutation}. [TOOL: OPEN_MESSENGER:${user}]`;
    }
    if (lower.includes('facebook') || lower.includes('fb')) {
      return `Launching Facebook for you, ${salutation}. [TOOL: OPEN_FACEBOOK]`;
    }

    // 6. Discord action
    if (lower.includes('discord')) {
      return `Launching Discord right away. [TOOL: OPEN_DISCORD]`;
    }

    // 6b. SMS / Default Messages
    if (lower.includes('sms') || (lower.includes('message') && !lower.includes('whatsapp'))) {
      const match = lower.match(/(?:message|sms|text)\s+([a-zA-Z0-9\s]+)/);
      const contact = match ? match[1].trim() : '';
      return `Drafting SMS message ${contact ? 'for ' + contact : ''}, ${salutation}. [TOOL: SEND_SMS:${contact}]`;
    }

    // 7. Calling contact
    if (lower.includes('call ') || lower.includes('dial ')) {
      const contact = lower.replace(/call|dial|phone/g, '').trim();
      return `Dialing ${contact} for you now, ${salutation}. [TOOL: CALL_CONTACT:${contact}]`;
    }

    // 8. Torch / Flashlight
    if (lower.includes('torch on') || lower.includes('turn on torch') || lower.includes('flashlight on')) {
      return `Torch turned on, ${salutation}! [TOOL: TORCH_ON]`;
    }
    if (lower.includes('torch off') || lower.includes('turn off torch') || lower.includes('flashlight off')) {
      return `Torch switched off. [TOOL: TORCH_OFF]`;
    }

    // 9. WiFi & Hotspot
    if (lower.includes('wifi') || lower.includes('wi-fi')) {
      return `Toggling Wi-Fi settings for you. [TOOL: TOGGLE_WIFI]`;
    }
    if (lower.includes('hotspot')) {
      return `Switching Hotspot status. [TOOL: TOGGLE_HOTSPOT]`;
    }

    // 10. Task reminders
    if (lower.includes('remind me') || lower.includes('save task') || lower.includes('add task')) {
      const task = userMessage.replace(/remind me to|save task|add task/gi, '').trim();
      return `Noted ${salutation}! I have saved "${task}" to your tasks list. [TOOL: SAVE_TASK:${task}]`;
    }
    if (lower.includes('tasks') || lower.includes('todo') || lower.includes('what are my tasks')) {
      return `Here are your pending tasks, ${salutation}. [TOOL: GET_TASKS]`;
    }

    // 11. Fitness inquiry
    if (lower.includes('workout') || lower.includes('fitness') || lower.includes('exercise') || lower.includes('consistency')) {
      return `You have been working out consistently for 4 consecutive days now, ${salutation}! Consistency rate is looking great at 100%. Keep up the momentum!`;
    }

    // 11b. Virtual Room & AI Interference Trigger
    if (
      lower.includes('virtual room') ||
      lower.includes('open room') ||
      lower.includes('3d room') ||
      lower.includes('hologram room') ||
      lower.includes('interference')
    ) {
      return `Opening your 3D Virtual Room and initializing holographic interference matrix, ${salutation}! [TOOL: OPEN_VIRTUAL_ROOM]`;
    }

    // 11c. Library / Android Book Openers
    if (lower.includes('library') || lower.includes('open library') || lower.includes('show apps') || lower.includes('all apps')) {
      return `Accessing your Android Library Books, ${salutation}. [TOOL: OPEN_LIBRARY]`;
    }

    // Dynamic intent: Photos / Memories
    if (lower.includes('photos') || lower.includes('gallery') || lower.includes('pictures') || lower.includes('images') || lower.includes('memories')) {
      return `Retrieving your Memories Book and launching Gallery, ${salutation}. [TOOL: LAUNCH_BOOK:book-gallery|]`;
    }

    // Dynamic intent: Camera
    if (lower.includes('camera') || lower.includes('take photo') || lower.includes('take picture') || lower.includes('selfie')) {
      return `Deploying Camera Book for immediate capture, ${salutation}. [TOOL: LAUNCH_BOOK:book-camera|]`;
    }

    // Dynamic intent: Calendar / Agenda
    if (lower.includes('calendar') || lower.includes('schedule') || lower.includes('agenda') || lower.includes('reminders')) {
      return `Opening your Planning Book & Calendar, ${salutation}. [TOOL: LAUNCH_BOOK:book-calendar|]`;
    }

    // Dynamic intent: Navigation / Maps
    if (lower.includes('maps') || lower.includes('directions') || lower.includes('navigate to') || lower.includes('where is')) {
      const dest = lower.replace(/open|maps|directions|to|navigate|where is/g, '').trim();
      return `Consulting Navigation Book for ${dest || 'current location'}, ${salutation}. [TOOL: LAUNCH_BOOK:book-maps|${dest}]`;
    }

    // Dynamic intent: Study / Focus / Work
    if (lower.includes('study') || lower.includes('work') || lower.includes('focus mode') || lower.includes('learn')) {
      return `Activating Study & Work Book. Distractions suppressed, ${salutation}. [TOOL: LAUNCH_BOOK:book-study|]`;
    }

    // Dynamic intent: Files / Documents
    if (lower.includes('files') || lower.includes('documents') || lower.includes('storage') || lower.includes('downloads')) {
      return `Opening Documents Book and Android File Manager, ${salutation}. [TOOL: LAUNCH_BOOK:book-files|]`;
    }

    // Dynamic intent: Settings
    if (lower.includes('settings') || lower.includes('system settings') || lower.includes('device configuration')) {
      return `Opening System Book and Android Device Settings, ${salutation}. [TOOL: LAUNCH_BOOK:book-settings|]`;
    }

    // 12. Web search
    if (lower.includes('search') || lower.includes('who is') || lower.includes('what is') || lower.includes('google')) {
      const query = userMessage.replace(/search for|search|google/gi, '').trim();
      return `Searching Google for "${query}", ${salutation}. [TOOL: SEARCH:${query}]`;
    }

    // 13. Identity
    if (lower.includes('who are you') || lower.includes('your name') || lower.includes('what is vyshu') || lower.includes('who designed you') || lower.includes('your outfit') || lower.includes('your look')) {
      return `I am Vyshu AI, your personal AI secretary and executive assistant. You specially designed my unique look, persona, and signature outfit, ${salutation} — from my red beret and heart pendant to my voice. I am at your service 24/7 across all 18 languages.`;
    }

    // Default J.A.R.V.I.S.-style witty and poised responses for Teja
    if (lower === 'hi' || lower === 'hello' || lower === 'hey' || lower === 'vyshu') {
      if (mode === 'HOME') {
        const homeGreetings = [
          `Hi Teja! At your service. All systems nominal and ready for whatever you need.`,
          `Hi Teja! Wonderful to hear from you. What are we getting into today?`,
          `Hi Teja! Always a pleasure. Ready and standing by for you.`,
        ];
        return homeGreetings[Math.floor(Math.random() * homeGreetings.length)];
      } else {
        const officeGreetings = [
          `Hi, Teja sir. All executive systems operational and standing by for your briefing.`,
          `Hi, Teja sir. At your command. How may I coordinate your workflow today?`,
          `Hi, Teja sir. Ready for operations. Awaiting your instructions.`,
        ];
        return officeGreetings[Math.floor(Math.random() * officeGreetings.length)];
      }
    }

    if (lower.includes('how are you') || lower.includes('status')) {
      return `Running at peak efficiency, ${salutation}. Battery, memory buffers, and bot interfaces are all green. Ready when you are.`;
    }

    if (lower.includes('thank') || lower.includes('good job') || lower.includes('well done')) {
      return `Always a pleasure to assist you, ${salutation}. Merely doing what I was engineered for.`;
    }

    // Default sophisticated fallback
    return `At your command, ${salutation}. What would you like to coordinate next?`;
  }

  // Main respond function
  public async respond(
    userMessage: string,
    mode: 'HOME' | 'OFFICE' = 'HOME'
  ): Promise<{ text: string; id: string; sticker?: string }> {
    const turnId = Date.now().toString();

    // Check bad words moderation
    const badCheck = this.checkBadWords(userMessage);
    if (badCheck.isBad) {
      return {
        text: badCheck.warning || 'Warning!',
        id: turnId,
        sticker: badCheck.sticker,
      };
    }

    const keys = this.getActiveKeys();

    // If no keys configured or offline, use smart local secretary engine
    if (keys.length === 0 || !navigator.onLine) {
      const localReply = this.getRuleBasedResponse(userMessage, mode);
      return { text: localReply, id: turnId };
    }

    // Select key with round-robin failover
    if (this.currentKeyIndex >= keys.length) this.currentKeyIndex = 0;
    const currentKey = keys[this.currentKeyIndex];
    this.currentKeyIndex = (this.currentKeyIndex + 1) % keys.length;

    try {
      const history = storageService.getChatHistory().slice(-10);
      const personality = this.getPersonality(mode);
      const tasks = storageService.getTasks();
      const taskListStr = tasks.map((t) => t.title).join(', ') || 'No active tasks';
      const nowStr = new Date().toLocaleString();

      const systemPrompt = `${personality}\n\nSYSTEM INFO:\n- Current Local Time: ${nowStr}\n- Active Tasks: ${taskListStr}\n`;

      const contents = [
        {
          role: 'user',
          parts: [{ text: systemPrompt }],
        },
        {
          role: 'model',
          parts: [{ text: `Understood. I am Vyshu AI, online and ready to assist ${mode === 'HOME' ? 'Teja' : 'Teja sir'}.` }],
        },
        ...history.map((h) => ({
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
        const candidate = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (candidate) {
          return { text: candidate.trim(), id: turnId };
        }
      }

      // If rate limited or error, try fallback response
      return { text: this.getRuleBasedResponse(userMessage, mode), id: turnId };
    } catch {
      // Fallback on network delay/error
      return { text: this.getRuleBasedResponse(userMessage, mode), id: turnId };
    }
  }

  // Delete turn
  public deleteTurn(turnId: string): void {
    const history = storageService.getChatHistory();
    const updated = history.filter((m) => m.turnId !== turnId && m.id !== turnId);
    storageService.saveChatHistory(updated);
  }
}

export const brainService = new BrainService();
