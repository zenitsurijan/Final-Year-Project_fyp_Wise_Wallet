import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _createController = TextEditingController();
  final _joinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_createController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final result = await provider.createFamily(_createController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family group created!')));
        Navigator.pop(context); // Go back or to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to create family')));
      }
    }
  }

  Future<void> _handleJoin() async {
    if (_joinController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit code')));
      return;
    }
    setState(() => _isLoading = true);
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final result = await provider.joinFamily(_joinController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined family successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Invalid code')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Group Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.group_add, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Manage family finances together',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),

            // Create Section
            const Text('Create New Family', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _createController,
              decoration: const InputDecoration(
                labelText: 'Family Name',
                hintText: 'e.g. The Simpsons',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isLoading ? null : _handleCreate,
              child: const Text('Create Group'),
            ),

            const SizedBox(height: 48),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade400)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 48),

            // Join Section
            const Text('Join Existing Family', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _joinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-Digit Invite Code',
                hintText: '123456',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _handleJoin,
              child: const Text('Join with Code'),
            ),
          ],
        ),
      ),
    );
  }
}
