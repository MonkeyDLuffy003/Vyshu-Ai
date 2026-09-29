import React, { useState } from 'react';
import {
  Newspaper,
  Volume2,
  VolumeX,
  Play,
  Pause,
  Search,
  ExternalLink,
  ShieldAlert,
  Briefcase,
  Trophy,
  Film,
  Cpu,
  Globe,
  Bell,
} from 'lucide-react';
import { audioService } from '../../services/audioService';
import { NewsArticle } from '../../types';

const INITIAL_NEWS: NewsArticle[] = [
  {
    id: 'n1',
    category: 'Tech',
    title: 'Next-Generation Autonomous AI Systems Advance Multilingual Processing',
    summary: 'New benchmarks reveal edge neural networks now handle 18 languages simultaneously with sub-50ms latency across mobile hardware.',
    source: 'Tech Daily',
    timeAgo: '15m ago',
  },
  {
    id: 'n2',
    category: 'Business',
    title: 'Global Markets Rally as Tech Sector Reaches New Milestones',
    summary: 'Cloud infrastructure investments and clean energy sectors surged 4.2% following quarterly earnings reports.',
    source: 'Financial Wire',
    timeAgo: '1h ago',
  },
  {
    id: 'n3',
    category: 'Sports',
    title: 'Championship Finals Set with Thrilling Last-Minute Winner',
    summary: 'A dramatic 92nd-minute strike propelled the underdogs into next week’s continental championship final.',
    source: 'Sports Hub',
    timeAgo: '2h ago',
  },
  {
    id: 'n4',
    category: 'Entertainment',
    title: 'Sci-Fi Cyberpunk Blockbuster Smashes Opening Weekend Box Office',
    summary: 'Featuring mind-bending visual effects and immersive futuristic soundscapes, the premiere crossed 100M globally.',
    source: 'Cinema Scoop',
    timeAgo: '3h ago',
  },
  {
    id: 'n5',
    category: 'Crime',
    title: 'Cybersecurity Task Force Dismantles International Phishing Ring',
    summary: 'Coordinated cyber defense operations prevented unauthorized access across 12,000 servers worldwide.',
    source: 'Global Bureau',
    timeAgo: '4h ago',
  },
  {
    id: 'n6',
    category: 'World',
    title: 'International Space Station Welcomes New Multination Crew',
    summary: 'Astronauts and scientists from four continents docked safely to conduct advanced zero-gravity biology experiments.',
    source: 'World News Net',
    timeAgo: '5h ago',
  },
];

const SIMULATED_NOTIFICATIONS = [
  { id: 'notif-1', app: 'WhatsApp', sender: 'Mom', text: 'Teja, remember to drink water and take your evening walk!', time: '2m ago' },
  { id: 'notif-2', app: 'Discord', sender: 'Vyshu Bot Server', text: 'Channel #general active with 18 translations', time: '10m ago' },
  { id: 'notif-3', app: 'Calendar', sender: 'Schedule', text: 'Workout Session scheduled for today (Consistency Day 5)', time: '25m ago' },
];

export const NewsReader: React.FC = () => {
  const [news, setNews] = useState<NewsArticle[]>(INITIAL_NEWS);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [readingId, setReadingId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'news' | 'notifications'>('news');

  const categories = ['All', 'Tech', 'Business', 'Sports', 'Entertainment', 'Crime', 'World'];

  const filteredNews = news.filter((item) => {
    const matchesCat = selectedCategory === 'All' || item.category === selectedCategory;
    const matchesQuery =
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.summary.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCat && matchesQuery;
  });

  const handleReadAloud = (article: NewsArticle) => {
    if (readingId === article.id) {
      audioService.stopSpeaking();
      setReadingId(null);
      return;
    }

    setReadingId(article.id);
    const speechText = `${article.title}. In ${article.category} news from ${article.source}: ${article.summary}`;
    audioService.speak(speechText, 'en-IN', () => {
      setReadingId(null);
    });
  };

  const handleReadNotification = (notif: typeof SIMULATED_NOTIFICATIONS[0]) => {
    const speechText = `Notification from ${notif.app}, sent by ${notif.sender}: ${notif.text}`;
    audioService.speak(speechText, 'en-IN');
  };

  const handleReadAllNews = () => {
    if (filteredNews.length === 0) return;
    const allTitles = filteredNews.map((n, i) => `Story ${i + 1}: ${n.title}. ${n.summary}`).join('. Next story: ');
    audioService.speak(`Reading your ${selectedCategory} news briefing. ${allTitles}`, 'en-IN');
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'Tech':
        return <Cpu className="w-3.5 h-3.5 text-cyan-400" />;
      case 'Business':
        return <Briefcase className="w-3.5 h-3.5 text-amber-400" />;
      case 'Sports':
        return <Trophy className="w-3.5 h-3.5 text-emerald-400" />;
      case 'Entertainment':
        return <Film className="w-3.5 h-3.5 text-purple-400" />;
      case 'Crime':
        return <ShieldAlert className="w-3.5 h-3.5 text-rose-400" />;
      default:
        return <Globe className="w-3.5 h-3.5 text-blue-400" />;
    }
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Newspaper className="w-4 h-4" /> News &amp; Notification Voice Reader
          </h2>
          <p className="text-xs text-slate-400">
            Categorized topics with hands-free voice read-aloud
          </p>
        </div>

        <div className="flex items-center gap-1 bg-slate-900 p-1 rounded-xl border border-slate-800">
          <button
            onClick={() => setActiveTab('news')}
            className={`px-3 py-1 rounded-lg text-xs font-semibold transition ${
              activeTab === 'news' ? 'bg-cyan-500/20 text-cyan-300' : 'text-slate-400'
            }`}
          >
            News Topics
          </button>
          <button
            onClick={() => setActiveTab('notifications')}
            className={`px-3 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition ${
              activeTab === 'notifications' ? 'bg-cyan-500/20 text-cyan-300' : 'text-slate-400'
            }`}
          >
            <Bell className="w-3 h-3" /> Notifications
          </button>
        </div>
      </div>

      {activeTab === 'news' ? (
        <>
          {/* Category Chips & Read All */}
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex flex-wrap gap-1.5">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={`text-xs px-3 py-1.5 rounded-xl border transition ${
                    selectedCategory === cat
                      ? 'bg-cyan-400 text-slate-950 font-bold border-cyan-400 shadow-sm shadow-cyan-500/20'
                      : 'bg-[#0b0b16] text-slate-300 border-slate-800 hover:border-slate-700'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>

            <button
              onClick={handleReadAllNews}
              className="text-xs px-3 py-1.5 rounded-xl bg-cyan-500/20 border border-cyan-500/40 text-cyan-300 font-semibold hover:bg-cyan-500/30 flex items-center gap-1.5 transition shrink-0"
            >
              <Volume2 className="w-3.5 h-3.5" /> Read Briefing Aloud
            </button>
          </div>

          {/* Search bar */}
          <div className="relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search news headline or keyword..."
              className="w-full bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-400"
            />
            <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
          </div>

          {/* News articles */}
          <div className="space-y-3 max-h-[55vh] overflow-y-auto pr-1">
            {filteredNews.map((article) => {
              const isReading = readingId === article.id;
              return (
                <div
                  key={article.id}
                  className={`p-4 rounded-2xl border transition ${
                    isReading
                      ? 'bg-cyan-500/10 border-cyan-400 shadow-md shadow-cyan-500/10'
                      : 'bg-[#0b0b16] border-slate-800/80 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="space-y-1.5">
                      <div className="flex items-center gap-2 text-[11px]">
                        <span className="flex items-center gap-1 font-semibold text-slate-300 bg-slate-800/80 px-2 py-0.5 rounded-md">
                          {getCategoryIcon(article.category)} {article.category}
                        </span>
                        <span className="text-slate-500">•</span>
                        <span className="text-slate-400">{article.source}</span>
                        <span className="text-slate-500">•</span>
                        <span className="text-slate-500 font-mono">{article.timeAgo}</span>
                      </div>

                      <h3 className="text-sm font-bold text-white leading-snug">{article.title}</h3>
                      <p className="text-xs text-slate-300 leading-relaxed">{article.summary}</p>
                    </div>

                    <button
                      onClick={() => handleReadAloud(article)}
                      className={`p-2.5 rounded-xl border transition shrink-0 ${
                        isReading
                          ? 'bg-cyan-400 text-slate-950 font-bold border-cyan-400'
                          : 'bg-[#0e1422] border-slate-800 text-cyan-400 hover:border-cyan-500/40'
                      }`}
                      title={isReading ? 'Stop Reading' : 'Read Aloud'}
                    >
                      {isReading ? <Pause className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </>
      ) : (
        /* Notifications Reader Tab */
        <div className="space-y-3">
          <div className="text-xs text-slate-400 bg-[#0b0b16] p-3 rounded-xl border border-slate-800">
            Vyshu reads incoming phone notifications out loud so you don&apos;t have to touch your screen.
          </div>

          <div className="space-y-2.5">
            {SIMULATED_NOTIFICATIONS.map((notif) => (
              <div
                key={notif.id}
                className="p-3.5 bg-[#0b0b16] border border-slate-800 rounded-2xl flex items-center justify-between"
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-cyan-400">{notif.app}</span>
                    <span className="text-[10px] text-slate-500">{notif.time}</span>
                  </div>
                  <div className="text-xs font-semibold text-slate-200">{notif.sender}</div>
                  <div className="text-xs text-slate-300">{notif.text}</div>
                </div>

                <button
                  onClick={() => handleReadNotification(notif)}
                  className="px-3 py-1.5 rounded-xl bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 text-xs font-semibold hover:bg-cyan-500/30 flex items-center gap-1.5 transition shrink-0"
                >
                  <Volume2 className="w-3.5 h-3.5" /> Speak
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
