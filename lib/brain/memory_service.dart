import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class MemoryService {

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${VyshuConfig.memoryFileName}');
  }

  static Future<Map<String,dynamic>> _load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (_) {}
    return _empty();
  }

  static Future<void> _save(Map<String,dynamic> data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data));
  }

  static Map<String,dynamic> _empty() => {
    "reminders":       [],
    "schedules":       [],
    "projects":        [],
    "important_notes": [],
    "process_logs":    [],
    "research":        [],
    "temp_notes":      [],
    "chat_history":    [],
    "planner":         {},
    "consistency":     {},
    "lang_progress":   {},
    "teaching":        {},
  };

  static int _nowTs() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000;

  static int _daysOld(int ts) =>
      ((_nowTs() - ts) / 86400).floor();

  // ── ADD FUNCTIONS ─────────────────────────────────────────────

  static Future<void> addReminder({
    required String text,
    required String time,
    bool notifyDiscord = true,
  }) async {
    final mem = await _load();
    (mem["reminders"] as List).add({
      "id":             _nowTs(),
      "text":           text,
      "time":           time,
      "notify_discord": notifyDiscord,
      "done":           false,
      "created_at":     _nowTs(),
      "created_str":    DateTime.now().toIso8601String(),
    });
    await _save(mem);
  }

  static Future<void> addSchedule({
    required String title,
    required String date,
    required String time,
    String note = "",
  }) async {
    final mem = await _load();
    (mem["schedules"] as List).add({
      "id":          _nowTs(),
      "title":       title,
      "date":        date,
      "time":        time,
      "note":        note,
      "done":        false,
      "created_at":  _nowTs(),
      "created_str": DateTime.now().toIso8601String(),
    });
    await _save(mem);
  }

  static Future<void> addProject({
    required String name,
    required String description,
  }) async {
    final mem = await _load();
    (mem["projects"] as List).add({
      "id":          _nowTs(),
      "name":        name,
      "description": description,
      "status":      "active",
      "created_at":  _nowTs(),
      "created_str": DateTime.now().toIso8601String(),
    });
    await _save(mem);
  }

  static Future<void> addNote(String text) async {
    final mem = await _load();
    (mem["important_notes"] as List).add({
      "id":          _nowTs(),
      "text":        text,
      "created_at":  _nowTs(),
      "created_str": DateTime.now().toIso8601String(),
    });
    await _save(mem);
  }

  static Future<void> addResearch(
      String query, String summary) async {
    final mem = await _load();
    (mem["research"] as List).add({
      "id":          _nowTs(),
      "query":       query,
      "summary":     summary,
      "created_at":  _nowTs(),
      "created_str": DateTime.now().toIso8601String(),
    });
    await _save(mem);
  }

  static Future<void> addChatHistory(
      String userMsg, String vyshuReply) async {
    final mem     = await _load();
    final history = (mem["chat_history"] as List);
    history.add({
      "role": "user", "text": userMsg,
      "created_at": _nowTs(),
    });
    history.add({
      "role": "model", "text": vyshuReply,
      "created_at": _nowTs(),
    });
    if (history.length > 40) {
      mem["chat_history"] = history.sublist(history.length - 40);
    }
    await _save(mem);
  }

  // ── GET FUNCTIONS ─────────────────────────────────────────────

  static Future<List<Map<String,String>>> getRecentChatHistory(
      {int turns = 10}) async {
    final mem     = await _load();
    final history = (mem["chat_history"] as List);
    final recent  = history.length > turns * 2
        ? history.sublist(history.length - turns * 2)
        : history;
    return recent.map((e) => {
      "role": e["role"].toString(),
      "text": e["text"].toString(),
    }).toList();
  }

  static Future<String> getTodaySchedule() async {
    final mem      = await _load();
    final today    = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2,'0')}"
        "-${today.day.toString().padLeft(2,'0')}";

    final reminders = (mem["reminders"] as List)
        .where((r) => !(r["done"] ?? false))
        .toList();
    final schedules = (mem["schedules"] as List)
        .where((s) =>
            !(s["done"] ?? false) &&
            (s["date"] == todayStr || s["date"] == "daily"))
        .toList();

    if (reminders.isEmpty && schedules.isEmpty) {
      return "Nothing scheduled today! Free day 😊";
    }
    final lines = <String>[];
    for (var s in schedules) {
      lines.add("📅 ${s['time']} — ${s['title']}");
    }
    for (var r in reminders) {
      lines.add("⏰ ${r['time']} — ${r['text']}");
    }
    return lines.join("\n");
  }

  static Future<List> getReminders() async {
    final mem = await _load();
    return (mem["reminders"] as List)
        .where((r) => !(r["done"] ?? false))
        .toList();
  }

  // ── EXPIRY ────────────────────────────────────────────────────

  static Future<List<Map<String,dynamic>>> getExpiredEntries() async {
    final mem     = await _load();
    final expired = <Map<String,dynamic>>[];
    for (final cat in VyshuConfig.expirableCategories) {
      final list = (mem[cat] as List?) ?? [];
      for (int i = 0; i < list.length; i++) {
        final entry = list[i];
        final ts    = entry["created_at"] as int? ?? _nowTs();
        if (_daysOld(ts) >= VyshuConfig.memoryExpiryDays) {
          expired.add({
            "category": cat,
            "id":       entry["id"],
            "text":     (entry["text"] ?? entry["query"] ??
                         entry["summary"] ?? "").toString(),
            "age_days": _daysOld(ts),
          });
        }
      }
    }
    return expired;
  }

  static Future<String> showExpired() async {
    final expired = await getExpiredEntries();
    if (expired.isEmpty) {
      return "No expired data! Storage clean ✅\n"
          "💙 Reminders, schedules and projects always safe!";
    }
    final lines = [
      "🗂️ Old temp entries (${expired.length} items):"
    ];
    for (int i = 0; i < expired.length; i++) {
      lines.add(
          "${i+1}. [${expired[i]['category']}] "
          "${expired[i]['text'].toString().substring(0,
            expired[i]['text'].toString().length > 50 ? 50 :
            expired[i]['text'].toString().length)} "
          "(${expired[i]['age_days']} days)");
    }
    lines.add("\n💙 Reminders and projects NOT listed, always safe.");
    lines.add("Say 'archive to gmail' or 'delete expired'");
    return lines.join("\n");
  }

  static Future<String> archiveToGmail() async {
    final prefs  = await SharedPreferences.getInstance();
    final gmail  = prefs.getString(VyshuConfig.kGmailAddress) ?? "";
    final appPwd = prefs.getString(VyshuConfig.kGmailAppPwd)  ?? "";

    if (gmail.isEmpty || appPwd.isEmpty) {
      return "⚠️ Gmail not set up!\n"
          "Go to Settings → Gmail Archive and add details.";
    }

    final expired = await getExpiredEntries();
    if (expired.isEmpty) return "Nothing to archive! All clean ✅";

    final lines = [
      "VYSHU AI V4 MEMORY ARCHIVE",
      "Date: ${DateTime.now().toIso8601String()}",
      "Total: ${expired.length} entries",
      "=" * 40,
    ];
    for (final e in expired) {
      lines.add("[${e['category']}] ${e['text']} (${e['age_days']} days)");
    }

    try {
      final sent = await _sendGmail(
        to:      gmail,
        appPwd:  appPwd,
        subject: "Vyshu AI Archive "
            "${DateTime.now().day}/${DateTime.now().month}/"
            "${DateTime.now().year}",
        body:    lines.join("\n"),
      );
      if (sent) {
        final mem = await _load();
        for (final cat in VyshuConfig.expirableCategories) {
          (mem[cat] as List).removeWhere((e) {
            final ts = e["created_at"] as int? ?? _nowTs();
            return _daysOld(ts) >= VyshuConfig.memoryExpiryDays;
          });
        }
        await _save(mem);
        return "✅ Archived ${expired.length} entries to Gmail!\n"
            "💙 Local storage cleared. Important data safe!";
      }
    } catch (e) {
      return "❌ Gmail archive failed: $e";
    }
    return "❌ Could not send archive email. Try again!";
  }

  static Future<bool> _sendGmail({
    required String to,
    required String appPwd,
    required String subject,
    required String body,
  }) async {
    try {
      final socket = await SecureSocket.connect(
          "smtp.gmail.com", 465,
          timeout: const Duration(seconds: 15));
      Future<void> send(String cmd) async {
        socket.write("$cmd\r\n");
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await send("EHLO gmail.com");
      await send("AUTH LOGIN");
      await send(base64Encode(utf8.encode(to)));
      await send(base64Encode(utf8.encode(appPwd)));
      await send("MAIL FROM:<$to>");
      await send("RCPT TO:<$to>");
      await send("DATA");
      await send("Subject: $subject\r\nFrom: $to\r\nTo: $to\r\n\r\n$body\r\n.");
      await send("QUIT");
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> showMemory() async {
    final mem     = await _load();
    final expired = await getExpiredEntries();
    final lines   = [
      "📋 Vyshu Memory V4:",
      "  ⏰ Reminders   : ${(mem['reminders'] as List).length} (safe ✅)",
      "  📅 Schedules   : ${(mem['schedules'] as List).length} (safe ✅)",
      "  📁 Projects    : ${(mem['projects'] as List).length} (safe ✅)",
      "  📝 Notes       : ${(mem['important_notes'] as List).length} (safe ✅)",
      "  🔍 Research    : ${(mem['research'] as List).length}",
      "  💬 Chat history: ${(mem['chat_history'] as List).length ~/ 2} turns",
    ];
    if (expired.isNotEmpty) {
      lines.add(
          "  ⚠️ Expired temp: ${expired.length} "
          "(say 'archive to gmail')");
    }
    return lines.join("\n");
  }
}
