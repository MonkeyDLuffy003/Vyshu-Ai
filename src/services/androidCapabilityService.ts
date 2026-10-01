// Android Capability & Library Service
// Represents the Android OS orchestration layer:
// Maps installed Android capabilities to Virtual Library Books and executes actions via Android Intents.

export type LibraryCategory =
  | 'entertainment'
  | 'music'
  | 'communication'
  | 'memories'
  | 'knowledge'
  | 'planning'
  | 'camera'
  | 'documents'
  | 'system'
  | 'navigation'
  | 'study_work';

export interface AndroidLibraryBook {
  id: string;
  bookTitle: string; // e.g., "Entertainment Book"
  appName: string; // e.g., "YouTube"
  category: LibraryCategory;
  packageName: string; // Android package id e.g. "com.google.android.youtube"
  intentUri: string; // Deep-link or android intent string
  fallbackWebUrl: string;
  icon: string; // Emoji or Lucide icon name
  spineColor: string; // Book spine hex code
  glowColor: string;
  description: string;
  voiceKeywords: string[]; // Triggers e.g. ["youtube", "video", "watch"]
  isDefault: boolean;
  actionCount: number;
}

const STORAGE_KEY_LIBRARY = 'vyshu_android_library_v2';
const STORAGE_KEY_LAUNCHER_MODE = 'vyshu_is_launcher_mode';

// Dynamic default Android capability books based on Android Core Apps
export const DEFAULT_ANDROID_BOOKS: AndroidLibraryBook[] = [
  {
    id: 'book-youtube',
    bookTitle: 'Entertainment Book',
    appName: 'YouTube',
    category: 'entertainment',
    packageName: 'com.google.android.youtube',
    intentUri: 'vnd.youtube://',
    fallbackWebUrl: 'https://youtube.com',
    icon: 'PlaySquare',
    spineColor: '#ef4444',
    glowColor: 'rgba(239, 68, 68, 0.4)',
    description: 'Video streaming, entertainment, live broadcasts & tutorials',
    voiceKeywords: ['youtube', 'video', 'watch', 'videos', 'stream', 'entertainment'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-spotify',
    bookTitle: 'Music Book',
    appName: 'Spotify / Music',
    category: 'music',
    packageName: 'com.spotify.music',
    intentUri: 'spotify://',
    fallbackWebUrl: 'https://open.spotify.com',
    icon: 'Music',
    spineColor: '#10b981',
    glowColor: 'rgba(16, 185, 129, 0.4)',
    description: 'Music playlists, audio tracks, offline playback & podcasts',
    voiceKeywords: ['music', 'spotify', 'song', 'songs', 'playlist', 'tune', 'audio'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-whatsapp',
    bookTitle: 'Communication Book',
    appName: 'WhatsApp',
    category: 'communication',
    packageName: 'com.whatsapp',
    intentUri: 'whatsapp://',
    fallbackWebUrl: 'https://web.whatsapp.com',
    icon: 'MessageCircle',
    spineColor: '#22c55e',
    glowColor: 'rgba(34, 197, 94, 0.4)',
    description: 'Instant messaging, voice calls, video chats & groups',
    voiceKeywords: ['whatsapp', 'chat', 'message', 'text', 'wa'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-dialer',
    bookTitle: 'Phone & Contacts Book',
    appName: 'Phone Dialer',
    category: 'communication',
    packageName: 'com.google.android.dialer',
    intentUri: 'tel:',
    fallbackWebUrl: 'tel:',
    icon: 'PhoneCall',
    spineColor: '#3b82f6',
    glowColor: 'rgba(59, 130, 246, 0.4)',
    description: 'Cellular calling, emergency dialer & address book',
    voiceKeywords: ['call', 'dial', 'phone', 'ring', 'contact'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-gallery',
    bookTitle: 'Memories Book',
    appName: 'Photos / Gallery',
    category: 'memories',
    packageName: 'com.google.android.apps.photos',
    intentUri: 'content://media/internal/images/media',
    fallbackWebUrl: 'https://photos.google.com',
    icon: 'Image',
    spineColor: '#f59e0b',
    glowColor: 'rgba(245, 158, 11, 0.4)',
    description: 'Photo gallery, memories, camera roll, screenshot storage',
    voiceKeywords: ['photos', 'photo', 'gallery', 'memories', 'pictures', 'images', 'pics'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-camera',
    bookTitle: 'Camera Book',
    appName: 'Camera',
    category: 'camera',
    packageName: 'com.android.camera',
    intentUri: 'intent:#Intent;action=android.media.action.IMAGE_CAPTURE;end',
    fallbackWebUrl: '',
    icon: 'Camera',
    spineColor: '#ec4899',
    glowColor: 'rgba(236, 72, 153, 0.4)',
    description: 'HD Photo capture, 4K video recording & portrait mode',
    voiceKeywords: ['camera', 'take photo', 'snap', 'capture', 'selfie', 'record video'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-calendar',
    bookTitle: 'Planning Book',
    appName: 'Calendar & Reminders',
    category: 'planning',
    packageName: 'com.google.android.calendar',
    intentUri: 'content://com.android.calendar/time/',
    fallbackWebUrl: 'https://calendar.google.com',
    icon: 'Calendar',
    spineColor: '#6366f1',
    glowColor: 'rgba(99, 102, 241, 0.4)',
    description: 'Daily schedules, meetings, reminders & agenda planning',
    voiceKeywords: ['calendar', 'schedule', 'planning', 'reminder', 'remind', 'agenda', 'meeting'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-maps',
    bookTitle: 'Navigation Book',
    appName: 'Google Maps',
    category: 'navigation',
    packageName: 'com.google.android.apps.maps',
    intentUri: 'geo:0,0?q=',
    fallbackWebUrl: 'https://maps.google.com',
    icon: 'Compass',
    spineColor: '#06b6d4',
    glowColor: 'rgba(6, 182, 212, 0.4)',
    description: 'GPS turn-by-turn navigation, traffic updates & places',
    voiceKeywords: ['maps', 'map', 'directions', 'navigate', 'location', 'gps', 'traffic'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-browser',
    bookTitle: 'Knowledge Book',
    appName: 'Web Browser / Chrome',
    category: 'knowledge',
    packageName: 'com.android.chrome',
    intentUri: 'googlechrome://',
    fallbackWebUrl: 'https://google.com',
    icon: 'Globe',
    spineColor: '#8b5cf6',
    glowColor: 'rgba(139, 92, 246, 0.4)',
    description: 'World Wide Web, research papers, searches & Wikipedia',
    voiceKeywords: ['search', 'google', 'browser', 'internet', 'chrome', 'web', 'research'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-files',
    bookTitle: 'Documents Book',
    appName: 'Files & Storage',
    category: 'documents',
    packageName: 'com.google.android.apps.nbu.files',
    intentUri: 'content://com.android.externalstorage.documents/',
    fallbackWebUrl: '',
    icon: 'FolderArchive',
    spineColor: '#eab308',
    glowColor: 'rgba(234, 179, 8, 0.4)',
    description: 'Local filesystem, PDFs, downloads & document archives',
    voiceKeywords: ['files', 'documents', 'storage', 'downloads', 'pdf', 'docs'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-settings',
    bookTitle: 'System Book',
    appName: 'Android Settings',
    category: 'system',
    packageName: 'com.android.settings',
    intentUri: 'intent:#Intent;action=android.settings.SETTINGS;end',
    fallbackWebUrl: '',
    icon: 'Settings',
    spineColor: '#64748b',
    glowColor: 'rgba(100, 116, 139, 0.4)',
    description: 'Android system settings, hardware toggles, battery & network',
    voiceKeywords: ['settings', 'system', 'bluetooth', 'display', 'battery', 'device'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-study',
    bookTitle: 'Study & Work Book',
    appName: 'Study & Focus Suite',
    category: 'study_work',
    packageName: 'com.google.android.keep',
    intentUri: 'https://keep.google.com',
    fallbackWebUrl: 'https://keep.google.com',
    icon: 'BookOpen',
    spineColor: '#14b8a6',
    glowColor: 'rgba(20, 184, 166, 0.4)',
    description: 'Focus timer, study materials, notes, coding & projects',
    voiceKeywords: ['study', 'work', 'focus', 'learn', 'notes', 'coding', 'project'],
    isDefault: true,
    actionCount: 0,
  },
  // --- NON-GOOGLE THIRD-PARTY ANDROID ECOSYSTEM APPS ---
  {
    id: 'book-instagram',
    bookTitle: 'Visual Social Book',
    appName: 'Instagram',
    category: 'entertainment',
    packageName: 'com.instagram.android',
    intentUri: 'instagram://',
    fallbackWebUrl: 'https://instagram.com',
    icon: 'Camera',
    spineColor: '#e1306c',
    glowColor: 'rgba(225, 48, 108, 0.4)',
    description: 'Stories, reels, feed posts, direct messages & creator network',
    voiceKeywords: ['instagram', 'insta', 'reels', 'stories', 'ig'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-telegram',
    bookTitle: 'Encrypted Comms Book',
    appName: 'Telegram',
    category: 'communication',
    packageName: 'org.telegram.messenger',
    intentUri: 'tg://',
    fallbackWebUrl: 'https://web.telegram.org',
    icon: 'Send',
    spineColor: '#24a1de',
    glowColor: 'rgba(36, 161, 222, 0.4)',
    description: 'Encrypted instant messaging, channels, bots & cloud media storage',
    voiceKeywords: ['telegram', 'tg', 'channels', 'tele'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-netflix',
    bookTitle: 'Cinema Stream Book',
    appName: 'Netflix',
    category: 'entertainment',
    packageName: 'com.netflix.mediaclient',
    intentUri: 'netflix://',
    fallbackWebUrl: 'https://netflix.com',
    icon: 'Film',
    spineColor: '#e50914',
    glowColor: 'rgba(229, 9, 20, 0.4)',
    description: 'Blockbuster movies, anime series, original dramas & offline downloads',
    voiceKeywords: ['netflix', 'movie', 'movies', 'series', 'show', 'shows', 'anime'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-discord',
    bookTitle: 'Discord Community Book',
    appName: 'Discord',
    category: 'communication',
    packageName: 'com.discord',
    intentUri: 'discord://',
    fallbackWebUrl: 'https://discord.com/app',
    icon: 'Headphones',
    spineColor: '#5865f2',
    glowColor: 'rgba(88, 101, 242, 0.4)',
    description: 'Gaming servers, voice channels, developer communities & direct pings',
    voiceKeywords: ['discord', 'server', 'voice channel', 'guild'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-uber',
    bookTitle: 'Mobility & Transit Book',
    appName: 'Uber / Rides',
    category: 'navigation',
    packageName: 'com.ubercab',
    intentUri: 'uber://',
    fallbackWebUrl: 'https://m.uber.com',
    icon: 'Car',
    spineColor: '#000000',
    glowColor: 'rgba(255, 255, 255, 0.3)',
    description: 'Instant ride hailing, airport transfers, city cabs & package transit',
    voiceKeywords: ['uber', 'cab', 'taxi', 'ride', 'book cab'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-amazon',
    bookTitle: 'Commerce & Orders Book',
    appName: 'Amazon',
    category: 'study_work',
    packageName: 'in.amazon.mShop.android.shopping',
    intentUri: 'com.amazon.mobile.shopping://',
    fallbackWebUrl: 'https://amazon.com',
    icon: 'ShoppingBag',
    spineColor: '#ff9900',
    glowColor: 'rgba(255, 153, 0, 0.4)',
    description: 'Prime deliveries, hardware store, parcel tracking & digital orders',
    voiceKeywords: ['amazon', 'shopping', 'orders', 'buy', 'shop', 'package'],
    isDefault: true,
    actionCount: 0,
  },
  {
    id: 'book-call-shield',
    bookTitle: 'AI Call Shield & Security Book',
    appName: 'Vyshu AI Call Screening',
    category: 'system',
    packageName: 'com.vyshu.ai.callshield',
    intentUri: 'vyshu://call-shield',
    fallbackWebUrl: '',
    icon: 'ShieldCheck',
    spineColor: '#00ccff',
    glowColor: 'rgba(0, 204, 255, 0.5)',
    description: 'Autonomous spam call screener, fraud blocker & identity shield',
    voiceKeywords: ['call shield', 'spam call', 'screen calls', 'call screener', 'protect calls', 'who called'],
    isDefault: true,
    actionCount: 0,
  },
];

class AndroidCapabilityService {
  private books: AndroidLibraryBook[] = [];

  constructor() {
    this.loadBooks();
  }

  public getBooks(): AndroidLibraryBook[] {
    return this.books;
  }

  public getBooksByCategory(category: LibraryCategory): AndroidLibraryBook[] {
    return this.books.filter((b) => b.category === category);
  }

  public isLauncherMode(): boolean {
    return localStorage.getItem(STORAGE_KEY_LAUNCHER_MODE) === 'true';
  }

  public setLauncherMode(enabled: boolean): void {
    localStorage.setItem(STORAGE_KEY_LAUNCHER_MODE, enabled ? 'true' : 'false');
  }

  private loadBooks(): void {
    try {
      const raw = localStorage.getItem(STORAGE_KEY_LIBRARY);
      if (!raw) {
        this.books = DEFAULT_ANDROID_BOOKS;
        this.saveBooks();
      } else {
        const parsed = JSON.parse(raw);
        // Merge in any new default books
        const existingIds = new Set(parsed.map((p: any) => p.id));
        const merged = [...parsed];
        for (const def of DEFAULT_ANDROID_BOOKS) {
          if (!existingIds.has(def.id)) {
            merged.push(def);
          }
        }
        this.books = merged;
      }
    } catch {
      this.books = DEFAULT_ANDROID_BOOKS;
    }
  }

  public saveBooks(): void {
    localStorage.setItem(STORAGE_KEY_LIBRARY, JSON.stringify(this.books));
  }

  // Add a dynamically discovered installed app
  public registerInstalledApp(
    appName: string,
    packageName: string,
    category: LibraryCategory = 'study_work',
    intentUri?: string
  ): AndroidLibraryBook {
    const id = `book-${packageName.replace(/[^a-zA-Z0-9]/g, '-').toLowerCase()}`;
    const existing = this.books.find((b) => b.id === id || b.packageName === packageName);
    if (existing) {
      existing.appName = appName;
      if (intentUri) existing.intentUri = intentUri;
      this.saveBooks();
      return existing;
    }

    const newBook: AndroidLibraryBook = {
      id,
      bookTitle: `${appName} Book`,
      appName,
      category,
      packageName,
      intentUri: intentUri || `intent:#Intent;package=${packageName};end`,
      fallbackWebUrl: `https://play.google.com/store/apps/details?id=${packageName}`,
      icon: 'Smartphone',
      spineColor: '#00ccff',
      glowColor: 'rgba(0, 204, 255, 0.4)',
      description: `Installed Android App: ${appName}`,
      voiceKeywords: [appName.toLowerCase(), ...appName.toLowerCase().split(/\s+/)],
      isDefault: false,
      actionCount: 0,
    };

    this.books.push(newBook);
    this.saveBooks();
    return newBook;
  }

  // Find book matching natural language query
  public matchIntentToBook(query: string): AndroidLibraryBook | null {
    const q = query.toLowerCase().trim();

    // 1. Direct app name match
    for (const book of this.books) {
      if (q.includes(book.appName.toLowerCase())) return book;
    }

    // 2. Keyword match
    for (const book of this.books) {
      for (const kw of book.voiceKeywords) {
        if (q.includes(kw.toLowerCase())) return book;
      }
    }

    return null;
  }

  // Launch the Android Capability / Book via Intent
  public launchBook(bookIdOrObj: string | AndroidLibraryBook, params?: { query?: string; extra?: string }): {
    success: boolean;
    executedIntent: string;
    appName: string;
  } {
    const book = typeof bookIdOrObj === 'string' ? this.books.find((b) => b.id === bookIdOrObj) : bookIdOrObj;

    if (!book) {
      return { success: false, executedIntent: 'UNKNOWN', appName: 'Unknown' };
    }

    // Increment usage
    book.actionCount = (book.actionCount || 0) + 1;
    this.saveBooks();

    const q = encodeURIComponent(params?.query || '');

    try {
      // 1. YouTube specialized intent
      if (book.packageName.includes('youtube')) {
        if (params?.query) {
          window.location.href = `vnd.youtube://results?search_query=${q}`;
          setTimeout(() => {
            window.open(`https://www.youtube.com/results?search_query=${q}`, '_blank');
          }, 400);
        } else {
          window.location.href = 'vnd.youtube://';
          setTimeout(() => {
            window.open('https://youtube.com', '_blank');
          }, 400);
        }
        return { success: true, executedIntent: 'vnd.youtube://', appName: book.appName };
      }

      // 2. Spotify specialized intent
      if (book.packageName.includes('spotify')) {
        if (params?.query) {
          window.location.href = `spotify:search:${q}`;
          setTimeout(() => {
            window.open(`https://open.spotify.com/search/${q}`, '_blank');
          }, 400);
        } else {
          window.location.href = 'spotify://';
          setTimeout(() => {
            window.open('https://open.spotify.com', '_blank');
          }, 400);
        }
        return { success: true, executedIntent: 'spotify://', appName: book.appName };
      }

      // 3. WhatsApp specialized intent
      if (book.packageName.includes('whatsapp')) {
        if (params?.query) {
          window.location.href = `whatsapp://send?text=${q}`;
          setTimeout(() => {
            window.open(`https://api.whatsapp.com/send?text=${q}`, '_blank');
          }, 400);
        } else {
          window.location.href = 'whatsapp://';
          setTimeout(() => {
            window.open('https://web.whatsapp.com', '_blank');
          }, 400);
        }
        return { success: true, executedIntent: 'whatsapp://', appName: book.appName };
      }

      // 4. Dialer / Phone
      if (book.category === 'communication' && book.id === 'book-dialer') {
        const phoneParam = params?.query || params?.extra || '';
        window.location.href = `tel:${phoneParam}`;
        return { success: true, executedIntent: `tel:${phoneParam}`, appName: book.appName };
      }

      // 5. Maps / Navigation
      if (book.category === 'navigation') {
        const mapQ = params?.query || 'nearby';
        window.location.href = `geo:0,0?q=${q || mapQ}`;
        setTimeout(() => {
          window.open(`https://www.google.com/maps/search/?api=1&query=${q || mapQ}`, '_blank');
        }, 400);
        return { success: true, executedIntent: `geo:0,0?q=${q}`, appName: book.appName };
      }

      // 6. Generic Android Intent / Fallback Web Link
      if (book.intentUri) {
        window.location.href = book.intentUri;
        if (book.fallbackWebUrl) {
          setTimeout(() => {
            window.open(book.fallbackWebUrl, '_blank');
          }, 500);
        }
      } else if (book.fallbackWebUrl) {
        window.open(book.fallbackWebUrl, '_blank');
      }

      return { success: true, executedIntent: book.intentUri || book.fallbackWebUrl, appName: book.appName };
    } catch {
      if (book.fallbackWebUrl) {
        window.open(book.fallbackWebUrl, '_blank');
        return { success: true, executedIntent: book.fallbackWebUrl, appName: book.appName };
      }
      return { success: false, executedIntent: 'ERROR', appName: book.appName };
    }
  }
}

export const androidCapabilityService = new AndroidCapabilityService();
