import 'package:flutter/material.dart';
import '../ai/sub_agent_dispatcher.dart';
import '../ai/vyshu_brain.dart';

/// LiveTaskOverlay — Floating HUD Banner + Expandable Drawer + Safety Confirmation Modal
/// Displays active goal, step progress, last action, step logs, and a big red STOP button.
class LiveTaskOverlay extends StatefulWidget {
  const LiveTaskOverlay({super.key});

  @override
  State<LiveTaskOverlay> createState() => _LiveTaskOverlayState();
}

class _LiveTaskOverlayState extends State<LiveTaskOverlay> {
  bool _expanded = false;
  final TextEditingController _goalInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    vyshuBrain.addListener(_onBrainUpdate);
    subAgentDispatcher.addListener(_onBrainUpdate);
  }

  @override
  void dispose() {
    vyshuBrain.removeListener(_onBrainUpdate);
    subAgentDispatcher.removeListener(_onBrainUpdate);
    _goalInput.dispose();
    super.dispose();
  }

  void _onBrainUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = vyshuBrain.isRunningTask;
    final hasLogs = vyshuBrain.liveStepLogs.isNotEmpty;
    final pendingConfirm = vyshuBrain.pendingConfirmationPrompt;
    final activeSubAgents = subAgentDispatcher.activeTasks
        .where((t) => t.status == 'running')
        .toList();

    if (!isRunning && !hasLogs && pendingConfirm == null && activeSubAgents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 8,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F24).withOpacity(0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pendingConfirm != null
                  ? Colors.orangeAccent
                  : (isRunning ? const Color(0xFF00CCFF) : Colors.white24),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Goal + Step Counter + Expand + BIG STOP Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isRunning ? Icons.bolt : Icons.check_circle_outline,
                      color: isRunning ? const Color(0xFF00CCFF) : Colors.greenAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vyshuBrain.currentGoal.isEmpty
                                  ? 'Sub-Agent Active'
                                  : vyshuBrain.currentGoal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isRunning
                                  ? 'Step ${vyshuBrain.currentStep}/${VyshuBrain.maxAgentSteps} · ${vyshuBrain.lastActionSummary}'
                                  : vyshuBrain.lastActionSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                    const SizedBox(width: 4),
                    // Big Emergency STOP Button
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2A4B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await vyshuBrain.emergencyStop(reason: 'Tapped STOP button');
                          await subAgentDispatcher.stopAll();
                        },
                        icon: const Icon(Icons.stop_circle_outlined, size: 18),
                        label: const Text(
                          'STOP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Safety Confirmation Prompt Gate (if waiting on risky action)
              if (pendingConfirm != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAFETY CONFIRMATION REQUIRED',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendingConfirm,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => vyshuBrain.resolveConfirmation(false),
                            child: const Text(
                              'Cancel Action',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => vyshuBrain.resolveConfirmation(true),
                            child: const Text(
                              'Approve & Execute',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Active Timed Sub-Agents Bar
              if (activeSubAgents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    children: activeSubAgents
                        .map((sub) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sub-Agent ${sub.agent}: ${sub.task} (${sub.durationMinutes}m)',
                                  style: const TextStyle(
                                    color: Color(0xFF00CCFF),
                                    fontSize: 11,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => subAgentDispatcher.stopTask(sub.id),
                                  child: const Text(
                                    'Stop Sub-Agent',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 11),
                                  ),
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),

              // Expanded Live Step Log Drawer
              if (_expanded)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white12),
                      const Text(
                        'LIVE AGENT EXECUTION LOG (VYSHU_AGENT)',
                        style: TextStyle(
                          color: Color(0xFF00CCFF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: vyshuBrain.liveStepLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No steps recorded yet.',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              )
                            : ListView.builder(
                                itemCount: vyshuBrain.liveStepLogs.length,
                                itemBuilder: (context, idx) {
                                  final log = vyshuBrain.liveStepLogs[idx];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '[#${log.stepNumber}] ${log.action} -> ${log.resultDetail}\nThought: ${log.thought}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: log.success ? Colors.white70 : Colors.redAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
