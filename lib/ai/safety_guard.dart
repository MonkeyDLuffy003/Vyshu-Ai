import 'package:flutter/foundation.dart';

/// SafetyEvaluation returned before executing any agent step or screen observation
class SafetyEvaluation {
  final bool isBlocked;
  final bool requiresConfirmation;
  final String reason;

  const SafetyEvaluation({
    this.isBlocked = false,
    this.requiresConfirmation = false,
    this.reason = '',
  });

  static const SafetyEvaluation safe = SafetyEvaluation();
}

/// SafetyGuard — Enforces mandatory security & privacy rules for Vyshu Agent:
/// 1. Blocks UPI, banking, payment apps, and password managers completely.
/// 2. Scrubs sensitive/password fields from screen dumps before any LLM call.
/// 3. Flags risky actions (sending messages, calling, changing settings, deleting/installing)
///    for explicit spoken or on-screen confirmation.
class SafetyGuard {
  static const List<String> blockedPackages = [
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'com.phonepe.app', // PhonePe
    'net.one97.paytm', // Paytm
    'in.org.npci.upiapp', // BHIM UPI
    'in.amazon.mShop.android.shopping.pay',
    'com.whatsapp.payments',
    'com.sbi.lotusintouch', // YONO SBI
    'com.snapwork.hdfc', // HDFC Bank
    'com.csam.icici.bank.imobile', // iMobile ICICI
    'com.axis.mobile', // Axis Mobile
    'com.bitwarden.mobile',
    'com.agilebits.onepassword',
    'com.lastpass.lpandroid',
  ];

  static const List<String> blockedKeywords = [
    'enter upi pin',
    'enter mpin',
    'cvv',
    'netbanking password',
    'one time password',
    'confirm payment',
  ];

  static const Set<String> riskyActions = {
    'send_whatsapp',
    'call_contact',
    'set_toggle',
  };

  /// Checks if the current foreground app or screen content is a restricted banking/UPI/password surface.
  static SafetyEvaluation checkScreenObservation(Map<String, dynamic> observation) {
    final pkg = (observation['package']?.toString() ?? '').toLowerCase();
    for (final blocked in blockedPackages) {
      if (pkg.contains(blocked.toLowerCase())) {
        debugPrint('VYSHU_AGENT: [SafetyGuard] BLOCKED banking/payment package: $pkg');
        return SafetyEvaluation(
          isBlocked: true,
          reason: 'Safety Lock: Banking, UPI, and payment apps ($pkg) are strictly off-limits.',
        );
      }
    }

    final nodes = observation['nodes'] as List? ?? [];
    for (final rawNode in nodes) {
      if (rawNode is Map) {
        final text = (rawNode['text']?.toString() ?? '').toLowerCase();
        final desc = (rawNode['desc']?.toString() ?? '').toLowerCase();
        for (final kw in blockedKeywords) {
          if (text.contains(kw) || desc.contains(kw)) {
            debugPrint('VYSHU_AGENT: [SafetyGuard] BLOCKED sensitive screen keyword: $kw');
            return SafetyEvaluation(
              isBlocked: true,
              reason: 'Safety Lock: Payment PIN or sensitive credential screen detected.',
            );
          }
        }
      }
    }

    return SafetyEvaluation.safe;
  }

  /// Scrubs any password fields or sensitive tokens from the screen dump before sending to an LLM.
  static Map<String, dynamic> sanitizeObservationForLLM(Map<String, dynamic> rawObs) {
    final cleanNodes = <Map<String, dynamic>>[];
    final nodes = rawObs['nodes'] as List? ?? [];

    for (final item in nodes) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final isPassword = map['password'] == true;
        if (isPassword) {
          map['text'] = '[REDACTED_PASSWORD]';
          map['desc'] = '[REDACTED_PASSWORD]';
        }
        cleanNodes.add(map);
      }
    }

    return {
      'package': rawObs['package'] ?? '',
      'nodeCount': cleanNodes.length,
      'nodes': cleanNodes,
    };
  }

  /// Evaluates a planned action before execution.
  static SafetyEvaluation evaluatePlannedAction(String action, Map<String, dynamic> args) {
    final cleanAction = action.trim().toLowerCase();

    // Block launching banking/payment apps by name
    if (cleanAction == 'launch_app') {
      final appName = (args['app_name'] ?? args['name'] ?? '').toString().toLowerCase();
      if (appName.contains('gpay') ||
          appName.contains('google pay') ||
          appName.contains('phonepe') ||
          appName.contains('paytm') ||
          appName.contains('bhim') ||
          appName.contains('bank')) {
        debugPrint('VYSHU_AGENT: [SafetyGuard] Blocked launch of payment app: $appName');
        return SafetyEvaluation(
          isBlocked: true,
          reason: 'Safety Lock: Vyshu never opens or interacts with UPI or banking apps.',
        );
      }
    }

    // Check if tapping or typing involves delete/uninstall/pay keywords
    if (cleanAction == 'tap' || cleanAction == 'type_text') {
      final target = (args['text'] ?? args['desc'] ?? '').toString().toLowerCase();
      if (target.contains('pay now') || target.contains('send money') || target.contains('transfer')) {
        return const SafetyEvaluation(
          isBlocked: true,
          reason: 'Safety Lock: Financial transfer actions are blocked.',
        );
      }
      if (target.contains('delete') || target.contains('uninstall') || target.contains('erase')) {
        return SafetyEvaluation(
          requiresConfirmation: true,
          reason: 'Confirm destructive action on "$target"?',
        );
      }
    }

    // Check risky actions (messages, calls, settings toggles)
    if (riskyActions.contains(cleanAction)) {
      String summary = cleanAction;
      if (cleanAction == 'send_whatsapp') {
        summary = 'Send WhatsApp message to ${args['contact'] ?? 'contact'}: "${args['message'] ?? ''}"';
      } else if (cleanAction == 'call_contact') {
        summary = 'Place phone call to ${args['contact'] ?? 'contact'}';
      } else if (cleanAction == 'set_toggle') {
        summary = 'Change device setting: ${args['toggle'] ?? 'system toggle'}';
      }
      debugPrint('VYSHU_AGENT: [SafetyGuard] Confirmation required for: $summary');
      return SafetyEvaluation(
        requiresConfirmation: true,
        reason: summary,
      );
    }

    return SafetyEvaluation.safe;
  }
}
