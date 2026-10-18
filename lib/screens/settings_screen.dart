import 'package:flutter/material.dart';
import '../ai/llm_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedProviderId = 'gemini';
  final TextEditingController _labelCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();
  int _selectedPriority = 1;
  bool _obscureInput = true;
  String? _testingKeyId;

  @override
  void initState() {
    super.initState();
    providerManager.addListener(_onManagerUpdate);
    providerManager.init();
  }

  @override
  void dispose() {
    providerManager.removeListener(_onManagerUpdate);
    _labelCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleAddKey() async {
    final keyText = _keyCtrl.text.trim();
    if (keyText.isEmpty) {
      _showSnack('Paste an API key first.', isError: true);
      return;
    }

    final entry = await providerManager.addKey(
      providerId: _selectedProviderId,
      label: _labelCtrl.text.trim().isEmpty
          ? '${_selectedProviderId.toUpperCase()} Key'
          : _labelCtrl.text.trim(),
      apiKey: keyText,
      priority: _selectedPriority,
    );

    _keyCtrl.clear();
    _labelCtrl.clear();
    _showSnack('Key added to Vault! Testing connectivity...');
    await _handleTestKey(entry.id);
  }

  Future<void> _handleTestKey(String id) async {
    setState(() => _testingKeyId = id);
    final res = await providerManager.testSpecificKey(id);
    if (!mounted) return;
    setState(() => _testingKeyId = null);

    if (res.success) {
      _showSnack('Key verified WORKING (${res.providerId})!');
    } else {
      _showSnack('Key test failed: ${res.error}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: isError ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00CCFF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _statusColor(KeyHealthStatus status) {
    switch (status) {
      case KeyHealthStatus.working:
        return Colors.greenAccent;
      case KeyHealthStatus.rateLimited:
        return Colors.orangeAccent;
      case KeyHealthStatus.invalid:
        return Colors.redAccent;
      case KeyHealthStatus.disabled:
        return Colors.grey;
      case KeyHealthStatus.untested:
        return const Color(0xFF00CCFF);
    }
  }

  String _statusLabel(KeyHealthStatus status) {
    switch (status) {
      case KeyHealthStatus.working:
        return 'WORKING';
      case KeyHealthStatus.rateLimited:
        return 'RATE-LIMITED';
      case KeyHealthStatus.invalid:
        return 'INVALID';
      case KeyHealthStatus.disabled:
        return 'DISABLED';
      case KeyHealthStatus.untested:
        return 'UNTESTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = providerManager.registeredProviders
        .where((p) => p.id != 'on_device')
        .toList();
    final keys = providerManager.keys;

    return Scaffold(
      backgroundColor: const Color(0xFF070914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F24),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF00CCFF)),
            SizedBox(width: 8),
            Text(
              'Vyshu Key Vault',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                providerManager.hasAnyUsableKey ? 'AGENT READY' : 'NO-KEY MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: providerManager.hasAnyUsableKey
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // No-Key / Limited Mode Banner
          if (!providerManager.hasAnyUsableKey)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add an API key in Vault to unlock full intelligence. Direct rule commands (torch, volume, alarm, open app, call, time) work without a key.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Add New Key Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1530),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Provider API Key',
                  style: TextStyle(
                    color: Color(0xFF00CCFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProviderId,
                  dropdownColor: const Color(0xFF0E1530),
                  decoration: const InputDecoration(
                    labelText: 'Choose LLM Provider',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: providers
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.displayName, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProviderId = val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Label (e.g. Gemini #1)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _selectedPriority,
                        dropdownColor: const Color(0xFF0E1530),
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [1, 2, 3, 4, 5]
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('P$p'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPriority = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _keyCtrl,
                  obscureText: _obscureInput,
                  decoration: InputDecoration(
                    labelText: 'API Secret Key',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureInput ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureInput = !_obscureInput),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CCFF),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _handleAddKey,
                    icon: const Icon(Icons.add_moderator),
                    label: const Text(
                      'Save & Test Key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Configured Key Pool (Priority & Rotation)',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          if (keys.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No keys added yet. Add a Gemini, Groq, OpenRouter, or Mistral key above.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...keys.map((k) {
              final sColor = _statusColor(k.status);
              final isTesting = _testingKeyId == k.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1026),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${k.label} (${k.providerId.toUpperCase()})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'P${k.priority} · ${_statusLabel(k.status)}',
                          style: TextStyle(
                            color: sColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      k.maskedKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (k.lastError != null && k.lastError!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          k.lastError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: isTesting ? null : () => _handleTestKey(k.id),
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check, size: 16, color: Color(0xFF00CCFF)),
                          label: const Text('Test', style: TextStyle(fontSize: 12)),
                        ),
                        PopupMenuButton<int>(
                          tooltip: 'Set Priority',
                          onSelected: (p) => providerManager.updateKeyPriority(k.id, p),
                          itemBuilder: (_) => [1, 2, 3, 4, 5]
                              .map((p) => PopupMenuItem(
                                    value: p,
                                    child: Text('Priority P$p'),
                                  ))
                              .toList(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              'Priority',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ),
                        Switch(
                          value: k.enabled,
                          activeColor: const Color(0xFF00CCFF),
                          onChanged: (_) => providerManager.toggleKeyEnabled(k.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => providerManager.removeKey(k.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
