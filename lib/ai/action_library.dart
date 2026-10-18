import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vyshu_accessibility_bridge.dart';
import 'sub_agent_dispatcher.dart';

/// Standardized return type for every Action Library skill: {success, detail}
class ActionOutcome {
  final bool success;
  final String detail;

  const ActionOutcome({
    required this.success,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'detail': detail,
      };
}

/// ActionLibrary — The 18-skill device action library, called ONLY by VyshuBrain.
class ActionLibrary {
  static const Set<String> allowedActions = {
    'launch_app',
    'open_url',
    'tap',
    'type_text',
    'scroll',
    'swipe',
    'back',
    'home',
    'recents',
    'wait',
    'read_screen',
    'set_toggle',
    'set_alarm',
    'call_contact',
    'send_whatsapp',
    'search_in_app',
    'play_media',
    'dispatch_sub_agent',
    'finish',
  };

  /// Executes a validated skill and returns {success, detail}.
  static Future<ActionOutcome> execute(String action, Map<String, dynamic> args) async {
    final cleanAction = action.trim().toLowerCase();
    debugPrint('VYSHU_AGENT: [ActionLibrary] Executing "$cleanAction" with args=$args');

    try {
      switch (cleanAction) {
        case 'launch_app': {
          final appName = (args['app_name'] ?? args['name'] ?? '').toString().trim();
          if (appName.isEmpty) {
            return const ActionOutcome(success: false, detail: 'Missing app_name parameter');
          }
          final ok = await VyshuAccessibilityBridge.openApp(appName);
          if (ok) {
            return ActionOutcome(success: true, detail: 'Launched app "$appName"');
          }
          // Fallback for common web/deep-link apps if package lookup fails
          final lower = appName.toLowerCase();
          if (lower.contains('youtube')) {
            await launchUrl(Uri.parse('https://www.youtube.com'), mode: LaunchMode.externalApplication);
            return const ActionOutcome(success: true, detail: 'Opened YouTube via URI');
          } else if (lower.contains('spotify')) {
            await launchUrl(Uri.parse('spotify:'), mode: LaunchMode.externalApplication);
            return const ActionOutcome(success: true, detail: 'Opened Spotify via URI');
          } else if (lower.contains('whatsapp')) {
            await launchUrl(Uri.parse('whatsapp:'), mode: LaunchMode.externalApplication);
            return const ActionOutcome(success: true, detail: 'Opened WhatsApp via URI');
          }
          return ActionOutcome(success: false, detail: 'App "$appName" not found on device');
        }

        case 'open_url': {
          final urlStr = (args['url'] ?? '').toString().trim();
          if (urlStr.isEmpty) {
            return const ActionOutcome(success: false, detail: 'Missing url parameter');
          }
          final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          return ActionOutcome(success: ok, detail: ok ? 'Opened $uri' : 'Failed to open $uri');
        }

        case 'tap': {
          final text = (args['text'] ?? args['label'] ?? '').toString().trim();
          final nodeId = (args['id'] ?? args['node_id'] ?? '').toString().trim();
          final x = (args['x'] as num?)?.toInt();
          final y = (args['y'] as num?)?.toInt();

          if (text.isNotEmpty) {
            final ok = await VyshuAccessibilityBridge.tapNodeByText(text);
            return ActionOutcome(
              success: ok,
              detail: ok ? 'Tapped node matching "$text"' : 'Node "$text" not found to tap',
            );
          }
          if (nodeId.isNotEmpty) {
            final ok = await VyshuAccessibilityBridge.tapNodeById(nodeId);
            return ActionOutcome(
              success: ok,
              detail: ok ? 'Tapped node id "$nodeId"' : 'Node id "$nodeId" not found',
            );
          }
          if (x != null && y != null) {
            final ok = await VyshuAccessibilityBridge.tapCoordinates(x, y);
            return ActionOutcome(
              success: ok,
              detail: ok ? 'Tapped coordinates ($x, $y)' : 'Coordinate tap failed ($x, $y)',
            );
          }
          return const ActionOutcome(success: false, detail: 'tap requires text, id, or x/y coordinates');
        }

        case 'type_text': {
          final text = (args['text'] ?? '').toString();
          final targetHint = (args['target'] ?? args['hint'] ?? '').toString();
          final submit = args['submit'] == true;
          final ok = await VyshuAccessibilityBridge.typeText(
            text,
            targetHint: targetHint,
            submit: submit,
          );
          return ActionOutcome(
            success: ok,
            detail: ok ? 'Typed "$text"' : 'Failed to locate editable input field for "$text"',
          );
        }

        case 'scroll': {
          final direction = (args['direction'] ?? 'down').toString().toLowerCase();
          final ok = await VyshuAccessibilityBridge.scrollScreen(direction);
          return ActionOutcome(
            success: ok,
            detail: ok ? 'Scrolled $direction' : 'Scroll $direction failed',
          );
        }

        case 'swipe': {
          final startX = (args['start_x'] as num?)?.toInt() ?? 500;
          final startY = (args['start_y'] as num?)?.toInt() ?? 1400;
          final endX = (args['end_x'] as num?)?.toInt() ?? 500;
          final endY = (args['end_y'] as num?)?.toInt() ?? 400;
          final durationMs = (args['duration_ms'] as num?)?.toInt() ?? 350;
          final ok = await VyshuAccessibilityBridge.swipeCoordinates(
            startX: startX,
            startY: startY,
            endX: endX,
            endY: endY,
            durationMs: durationMs,
          );
          return ActionOutcome(
            success: ok,
            detail: ok ? 'Swiped ($startX,$startY)->($endX,$endY)' : 'Swipe gesture failed',
          );
        }

        case 'back': {
          final ok = await VyshuAccessibilityBridge.pressBack();
          return ActionOutcome(success: ok, detail: ok ? 'Pressed system Back' : 'Back failed');
        }

        case 'home': {
          final ok = await VyshuAccessibilityBridge.pressHome();
          return ActionOutcome(success: ok, detail: ok ? 'Pressed system Home' : 'Home failed');
        }

        case 'recents': {
          final ok = await VyshuAccessibilityBridge.pressRecents();
          return ActionOutcome(success: ok, detail: ok ? 'Opened Recents' : 'Recents failed');
        }

        case 'wait': {
          final seconds = ((args['seconds'] as num?)?.toInt() ?? 2).clamp(1, 10);
          await Future.delayed(Duration(seconds: seconds));
          return ActionOutcome(success: true, detail: 'Waited ${seconds}s');
        }

        case 'read_screen': {
          final obs = await VyshuAccessibilityBridge.dumpScreenCompact();
          final count = (obs['nodes'] as List?)?.length ?? 0;
          return ActionOutcome(
            success: true,
            detail: 'Observed package=${obs['package']} with $count interactive elements',
          );
        }

        case 'set_toggle': {
          final toggle = (args['toggle'] ?? args['name'] ?? '').toString().toLowerCase();
          final state = args['on'] == true || args['state']?.toString().toLowerCase() == 'on';
          if (toggle.contains('torch') || toggle.contains('flash')) {
            final ok = await VyshuAccessibilityBridge.setTorch(state);
            return ActionOutcome(success: ok, detail: 'Torch ${state ? "ON" : "OFF"}');
          } else if (toggle.contains('wifi') || toggle.contains('wi-fi')) {
            final ok = await VyshuAccessibilityBridge.toggleWifi();
            return ActionOutcome(success: ok, detail: 'Toggled Wi-Fi panel');
          } else if (toggle.contains('bluetooth')) {
            final ok = await VyshuAccessibilityBridge.toggleBluetooth();
            return ActionOutcome(success: ok, detail: 'Toggled Bluetooth tile');
          } else if (toggle.contains('hotspot')) {
            final ok = await VyshuAccessibilityBridge.toggleHotspot();
            return ActionOutcome(success: ok, detail: 'Opened Hotspot settings');
          } else if (toggle.contains('brightness')) {
            final val = (args['value'] as num?)?.toInt() ?? (state ? 230 : 70);
            final ok = await VyshuAccessibilityBridge.setBrightness(val);
            return ActionOutcome(success: ok, detail: 'Set brightness to $val');
          } else if (toggle.contains('volume')) {
            final val = (args['value'] as num?)?.toInt() ?? 8;
            final ok = await VyshuAccessibilityBridge.setVolume(3, val);
            return ActionOutcome(success: ok, detail: 'Set media volume to $val');
          }
          return ActionOutcome(success: false, detail: 'Unknown toggle "$toggle"');
        }

        case 'set_alarm': {
          final hour = (args['hour'] as num?)?.toInt() ?? 7;
          final minute = (args['minute'] as num?)?.toInt() ?? 0;
          final label = (args['label'] ?? args['message'] ?? 'Vyshu Alarm').toString();
          final ok = await VyshuAccessibilityBridge.setAlarm(hour, minute, message: label);
          return ActionOutcome(
            success: ok,
            detail: ok
                ? 'Set alarm for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ($label)'
                : 'Failed to set alarm',
          );
        }

        case 'call_contact': {
          final contact = (args['contact'] ?? args['name'] ?? '').toString().trim();
          final ok = await VyshuAccessibilityBridge.callContact(contact);
          return ActionOutcome(
            success: ok,
            detail: ok ? 'Calling "$contact"' : 'Contact "$contact" not found',
          );
        }

        case 'send_whatsapp': {
          final contact = (args['contact'] ?? args['name'] ?? '').toString().trim();
          final message = (args['message'] ?? args['text'] ?? '').toString().trim();
          final ok = await VyshuAccessibilityBridge.sendWhatsAppMessage(contact, message);
          return ActionOutcome(
            success: ok,
            detail: ok
                ? 'Opened WhatsApp chat with "$contact" pre-filled with "$message"'
                : 'Contact "$contact" not found for WhatsApp',
          );
        }

        case 'search_in_app': {
          final appName = (args['app'] ?? args['app_name'] ?? 'YouTube').toString();
          final query = (args['query'] ?? '').toString();
          if (appName.toLowerCase().contains('youtube')) {
            final uri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
            final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
            return ActionOutcome(success: ok, detail: 'Searched YouTube for "$query"');
          }
          final uri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          return ActionOutcome(success: ok, detail: 'Searched web for "$query"');
        }

        case 'play_media': {
          final query = (args['query'] ?? args['title'] ?? '').toString();
          final app = (args['app'] ?? 'YouTube').toString().toLowerCase();
          final durationMinutes = (args['duration_minutes'] as num?)?.toInt() ?? 0;

          if (app.contains('vaani')) {
            final sub = await subAgentDispatcher.dispatch(
              agent: 'Vaani',
              task: 'Play $query',
              durationMinutes: durationMinutes,
            );
            return ActionOutcome(
              success: true,
              detail: 'Dispatched to Vaani sub-agent: ${sub.task} (${durationMinutes}m)',
            );
          }

          final uri = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return ActionOutcome(
            success: true,
            detail: 'Opened YouTube results for "$query"',
          );
        }

        case 'dispatch_sub_agent': {
          final agent = (args['agent'] ?? 'Vaani').toString();
          final task = (args['task'] ?? '').toString();
          final duration = (args['duration'] as num?)?.toInt() ?? 0;
          final res = await subAgentDispatcher.dispatch(
            agent: agent,
            task: task,
            durationMinutes: duration,
          );
          return ActionOutcome(
            success: true,
            detail: 'Sub-agent ${res.agent} started task "${res.task}" (duration=${res.durationMinutes}m)',
          );
        }

        case 'finish': {
          final summary = (args['summary'] ?? 'Task completed.').toString();
          return ActionOutcome(success: true, detail: summary);
        }

        default:
          return ActionOutcome(success: false, detail: 'Unsupported action "$cleanAction"');
      }
    } catch (e) {
      debugPrint('VYSHU_AGENT: [ActionLibrary] Exception in "$cleanAction": $e');
      return ActionOutcome(success: false, detail: 'Action error: $e');
    }
  }
}
