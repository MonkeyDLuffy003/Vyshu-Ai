import 'package:flutter/foundation.dart';
import '../../services/output_policy_service.dart';

/// Screened Call Record
class ScreenedCall {
  final String id;
  final String callerNumber;
  final String callerName;
  final String transcript;
  final String intent;
  final bool isEmergency;
  final bool isSpam;
  final DateTime timestamp;
  final String disposition; // 'silenced' | 'alerted' | 'transcribed'

  ScreenedCall({
    required this.id,
    required this.callerNumber,
    required this.callerName,
    required this.transcript,
    required this.intent,
    required this.isEmergency,
    required this.isSpam,
    required this.disposition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// CallIntelligenceAgent — Feature Agent 6
/// Bridges incoming call screening with VyshuBrain.
/// Evaluates urgency and enforces strict Sleep Mode call filtering.
class CallIntelligenceAgent extends ChangeNotifier {
  static final CallIntelligenceAgent instance = CallIntelligenceAgent._internal();
  factory CallIntelligenceAgent() => instance;
  CallIntelligenceAgent._internal();

  final List<ScreenedCall> _callHistory = [];
  List<ScreenedCall> get callHistory => List.unmodifiable(_callHistory);

  /// Priority Contacts who can break through Sleep Mode
  final Set<String> _priorityContacts = {'Mom', 'Dad', 'Wife', 'Emergency Contact', 'Home'};

  void addPriorityContact(String name) {
    _priorityContacts.add(name.trim());
    notifyListeners();
  }

  /// Processes an incoming call event and returns an action disposition.
  ScreenedCall processIncomingCall({
    required String callerNumber,
    required String callerName,
    required String transcript,
  }) {
    final lowerTranscript = transcript.toLowerCase();
    final isEmergency = lowerTranscript.contains('emergency') ||
        lowerTranscript.contains('urgent') ||
        lowerTranscript.contains('hospital') ||
        lowerTranscript.contains('accident') ||
        lowerTranscript.contains('critical');

    final isSpam = lowerTranscript.contains('loan offer') ||
        lowerTranscript.contains('insurance agent') ||
        lowerTranscript.contains('credit card pre-approved');

    final isPriorityContact = _priorityContacts.any((c) => callerName.toLowerCase().contains(c.toLowerCase()));

    final isSleep = outputPolicyService.isSleepModeActive;
    final allowPriority = outputPolicyService.settings.allowPriorityAlarms;

    String disposition;
    if (isSleep) {
      if ((isEmergency || isPriorityContact) && allowPriority) {
        disposition = 'alerted'; // Priority breach allowed during Sleep Mode!
        debugPrint('VYSHU_AGENT: [CallIntelligenceAgent] PRIORITY CALL BREACH ALLOWED for $callerName during Sleep Mode!');
      } else {
        disposition = 'silenced'; // Routine calls muted silently
        debugPrint('VYSHU_AGENT: [CallIntelligenceAgent] Call from $callerName silently logged due to Sleep Mode.');
      }
    } else {
      disposition = isSpam ? 'silenced' : 'alerted';
    }

    final record = ScreenedCall(
      id: 'call_${DateTime.now().millisecondsSinceEpoch}',
      callerNumber: callerNumber,
      callerName: callerName,
      transcript: transcript,
      intent: isEmergency ? 'Emergency' : (isSpam ? 'Spam' : 'General Message'),
      isEmergency: isEmergency,
      isSpam: isSpam,
      disposition: disposition,
    );

    _callHistory.insert(0, record);
    notifyListeners();
    return record;
  }

  /// Returns overnight screened call summary for morning review
  List<ScreenedCall> getOvernightCalls() {
    return _callHistory.where((c) => c.disposition == 'silenced').toList();
  }
}

final callIntelligenceAgent = CallIntelligenceAgent.instance;
