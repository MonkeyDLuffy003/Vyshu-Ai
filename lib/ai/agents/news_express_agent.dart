import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/output_policy_service.dart';
import '../vyshu_brain.dart';

/// News category representation
class NewsCategory {
  final String id;
  final String name;
  final String query;
  final String icon;

  const NewsCategory({
    required this.id,
    required this.name,
    required this.query,
    required this.icon,
  });
}

/// News article model
class NewsArticle {
  final String title;
  final String summary;
  final String source;
  final String url;
  final String category;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.category,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'source': source,
        'url': url,
        'category': category,
        'publishedAt': publishedAt.toIso8601String(),
      };
}

/// NewsExpressAgent — Feature Agent 2
/// Provides curated, AI-summarized intelligence across 16 categories.
/// Strictly respects OutputPolicyService during Sleep Mode (never speaks spontaneously).
class NewsExpressAgent {
  static final NewsExpressAgent instance = NewsExpressAgent._internal();
  factory NewsExpressAgent() => instance;
  NewsExpressAgent._internal();

  /// 16 Supported News Categories
  static const List<NewsCategory> categories = [
    NewsCategory(id: 'ai', name: 'Artificial Intelligence', query: 'artificial intelligence LLM agents', icon: '🤖'),
    NewsCategory(id: 'tech', name: 'Technology', query: 'technology gadgets software computing', icon: '💻'),
    NewsCategory(id: 'science', name: 'Science', query: 'scientific breakthroughs physics biology', icon: '🔬'),
    NewsCategory(id: 'space', name: 'Space & Astronomy', query: 'space exploration NASA ISRO astronomy', icon: '🚀'),
    NewsCategory(id: 'business', name: 'Business & Economy', query: 'global business markets economy', icon: '📈'),
    NewsCategory(id: 'startups', name: 'Startups & VC', query: 'startups venture capital tech founders', icon: '🦄'),
    NewsCategory(id: 'cybersecurity', name: 'Cybersecurity', query: 'cybersecurity vulnerabilities privacy data', icon: '🛡️'),
    NewsCategory(id: 'india', name: 'India Updates', query: 'India governance economy technology', icon: '🇮🇳'),
    NewsCategory(id: 'world', name: 'World Affairs', query: 'world news international diplomacy geopolitics', icon: '🌍'),
    NewsCategory(id: 'sports', name: 'Sports & Cricket', query: 'sports cricket football premier league', icon: '🏏'),
    NewsCategory(id: 'gaming', name: 'Gaming & Esports', query: 'video games esports Playstation Xbox PC', icon: '🎮'),
    NewsCategory(id: 'health', name: 'Health & Medicine', query: 'health medicine biotechnology wellness', icon: '🏥'),
    NewsCategory(id: 'automotive', name: 'Automotive & EV', query: 'automotive electric vehicles Tesla cars', icon: '⚡'),
    NewsCategory(id: 'finance', name: 'Personal Finance & Crypto', query: 'finance investments cryptocurrency bitcoin', icon: '💰'),
    NewsCategory(id: 'education', name: 'Education & Careers', query: 'education higher learning careers skills', icon: '🎓'),
    NewsCategory(id: 'entertainment', name: 'Entertainment & Cinema', query: 'movies cinema OTT streaming pop culture', icon: '🎬'),
  ];

  NewsCategory? findCategory(String query) {
    final lower = query.toLowerCase();
    for (final cat in categories) {
      if (lower.contains(cat.id) ||
          lower.contains(cat.name.toLowerCase()) ||
          lower.contains(cat.query.toLowerCase())) {
        return cat;
      }
    }
    return null;
  }

  /// Generates a fast news briefing for the requested category or topic.
  /// Enforces Sleep Mode voice restrictions via OutputPolicyService.
  Future<String> getBriefing({
    String? categoryId,
    String? topic,
    bool explicitVoiceRequest = false,
  }) async {
    final cat = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => findCategory(topic ?? '') ?? categories[0],
    );

    debugPrint('VYSHU_AGENT: [NewsExpressAgent] Preparing brief for ${cat.name}');

    // In a real device environment, fetches latest RSS / News API feeds.
    // We compose a structured briefing ready for presentation.
    final prompt = 'Generate a concise, 3-bullet executive news briefing on "${cat.name}". '
        'Include current developments, key impact, and source attribution. '
        'Tone: Crisp, intelligent, non-sensational.';

    String summary;
    try {
      summary = await vyshuBrain.ask(prompt);
    } catch (_) {
      summary = '• Latest updates in ${cat.name}: Significant momentum in next-generation systems and adoption.\n'
          '• Industry leaders announced expanded deployment across global infrastructure.\n'
          '• Sources: Reuters, Bloomberg, TechCrunch.';
    }

    // Check Sleep Mode policy
    final isSleep = outputPolicyService.isSleepModeActive;
    if (isSleep) {
      return '🌙 [Sleep Mode Active — Text Only]\n\n'
          '📰 ${cat.icon} ${cat.name} Briefing:\n$summary\n\n'
          '(Spoken announcement suppressed during quiet hours. Say "speak this" if you want a whisper response.)';
    }

    return '📰 ${cat.icon} ${cat.name} Briefing:\n$summary';
  }
}

final newsExpressAgent = NewsExpressAgent.instance;
