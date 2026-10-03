import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vault/vault_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await vyshuVaultManager.init();
  runApp(const VyshuVaultApp());
}

class VyshuVaultApp extends StatelessWidget {
  const VyshuVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyshu Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00CCFF),
          secondary: Color(0xFF7C4DFF),
        ),
      ),
      home: const MultiProviderVaultScreen(),
    );
  }
}

class MultiProviderVaultScreen extends StatefulWidget {
  const MultiProviderVaultScreen({super.key});

  @override
  State<MultiProviderVaultScreen> createState() => _MultiProviderVaultScreenState();
}

class _MultiProviderVaultScreenState extends State<MultiProviderVaultScreen> {
  KeyCategory _selectedCategory = KeyCategory.ai;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    await vyshuVaultManager.init();
    setState(() => _isLoading = false);
  }

  void _showAddKeyDialog(ProviderSpec provider) {
    final aliasController = TextEditingController(text: '${provider.displayName} Key');
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1226),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Credential: ${provider.displayName}', style: const TextStyle(fontSize: 16, color: Color(0xFF00CCFF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.freeTierSummary, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(
                labelText: 'Key Label / Alias',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Secret / Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CCFF)),
            onPressed: () async {
              if (keyController.text.trim().isNotEmpty) {
                await vyshuVaultManager.addCredential(
                  providerId: provider.id,
                  keyAlias: aliasController.text.trim(),
                  rawKey: keyController.text.trim(),
                );
                Navigator.pop(ctx);
                _reload();
              }
            },
            child: const Text('Save & Encrypt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = VyshuVaultRegistry.SUPPORTED_PROVIDERS.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F24),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF00CCFF)),
            SizedBox(width: 8),
            Text('Vyshu Vault', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00CCFF)),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Selector Tabs
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: const Color(0xFF0A0F24),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(KeyCategory.ai, 'AI / LLM Brain', Icons.psychology),
                _buildCategoryChip(KeyCategory.webSearch, 'Web Search', Icons.search),
                _buildCategoryChip(KeyCategory.maps, 'Maps & GPS', Icons.map),
                _buildCategoryChip(KeyCategory.image, 'Image AI', Icons.image),
                _buildCategoryChip(KeyCategory.audio, 'Voice & Speech', Icons.mic),
                _buildCategoryChip(KeyCategory.communication, 'Communication', Icons.chat),
              ],
            ),
          ),

          // Provider & Key List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      final creds = vyshuVaultManager.getCredentialsForProvider(provider.id);

                      return Card(
                        color: const Color(0xFF0E1530),
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: const Color(0xFF00CCFF).withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          provider.freeTierSummary,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF00CCFF)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00CCFF).withOpacity(0.15),
                                      foregroundColor: const Color(0xFF00CCFF),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    onPressed: () => _showAddKeyDialog(provider),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Key', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 20),

                              if (creds.isEmpty)
                                const Text(
                                  'No credentials in pool yet. Tap "Add Key" to enroll a free-tier key.',
                                  style: TextStyle(fontSize: 12, color: Colors.white38),
                                )
                              else
                                Column(
                                  children: creds.map((c) => _buildKeyRow(c)).toList(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(KeyCategory cat, String label, IconData icon) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white70),
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF00CCFF),
        backgroundColor: const Color(0xFF131B3A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedCategory = cat);
        },
      ),
    );
  }

  Widget _buildKeyRow(ManagedCredential cred) {
    Color badgeColor;
    String badgeText;

    switch (cred.state) {
      case RotationState.active:
        badgeColor = Colors.greenAccent;
        badgeText = 'ACTIVE';
        break;
      case RotationState.available:
        badgeColor = const Color(0xFF00CCFF);
        badgeText = 'AVAILABLE';
        break;
      case RotationState.cooldown:
        badgeColor = Colors.orangeAccent;
        badgeText = 'COOLDOWN';
        break;
      case RotationState.disabled:
        badgeColor = Colors.grey;
        badgeText = 'DISABLED';
        break;
      case RotationState.invalid:
        badgeColor = Colors.redAccent;
        badgeText = 'INVALID';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cred.keyAlias,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cred.maskedValue,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              cred.state == RotationState.disabled ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: Colors.white54,
            ),
            tooltip: 'Toggle Enable/Disable',
            onPressed: () async {
              await vyshuVaultManager.toggleCredentialState(cred.id);
              _reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            tooltip: 'Delete Key',
            onPressed: () async {
              await vyshuVaultManager.deleteCredential(cred.id);
              _reload();
            },
          ),
        ],
      ),
    );
  }
}
