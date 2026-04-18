import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import 'member_report_screen.dart';
import 'package:share_plus/share_plus.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    await Future.wait([
      provider.fetchMembers(),
      provider.fetchDashboard(),
    ]);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareInviteCode(String code) {
    Share.share(
      'Join my family on WiseWallet using this code: $code',
      subject: 'WiseWallet Family Invite',
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final inviteCode = familyProvider.dashboardData?['inviteCode'] ?? '------';
    final isHead = familyProvider.dashboardData?['isHead'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Family', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) => _handleMenuAction(value, isHead),
            itemBuilder: (context) => [
              if (!isHead)
                const PopupMenuItem(value: 'leave', child: Text('Leave Family')),
              if (isHead) ...[
                const PopupMenuItem(value: 'transfer', child: Text('Transfer Head Role')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Family', style: TextStyle(color: Colors.red))),
              ],
              const PopupMenuItem(value: 'settings', child: Text('Family Settings')),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (familyProvider.isLoading && familyProvider.members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (familyProvider.error != null && familyProvider.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${familyProvider.error}'),
                  TextButton(onPressed: _loadData, child: const Text('Retry')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Invite Code Card
                _buildInviteCodeCard(inviteCode, familyProvider.dashboardData?['familyName'] ?? '', isHead),

                // Add Member Section (Dashed Border)
                _buildAddMemberSection(inviteCode),

                // List Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Family Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),

                // Member List
                if (familyProvider.members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: Text('No members in family yet', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...familyProvider.members.map((member) => _buildMemberItem(member, isHead, currentUser?['_id'])),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInviteCodeCard(String code, String familyName, bool isHead) {
    return InkWell(
      onTap: () => _copyToClipboard(code),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Family Invite Code',
                      style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (isHead)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit, color: Color(0xFF1976D2), size: 18),
                        onPressed: () => _showEditFamilyNameDialog(familyName),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              code,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this code with your family members\nTap to copy',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberSection(String inviteCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: DashedRectPainter(color: Colors.blue.shade300),
        child: InkWell(
          onTap: () => _showAddMemberOptions(inviteCode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Invite Family Member',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberItem(dynamic member, bool isCurrentUserHead, String? currentUserId) {
    final name = member['name'] ?? 'Unknown';
    final email = member['email'] ?? '';
    final role = member['role']?.toString().toLowerCase() ?? 'individual';
    final isHead = role == 'family_head';
    final memberId = member['_id'];
    final isMe = memberId == currentUserId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24, // 48px width/height
          backgroundColor: const Color(0xFFBBDEFB),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isMe ? '$name (You)' : name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ),
            if (isHead)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text('Head', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: !isMe && !isHead
            ? IconButton(
                icon: const Icon(Icons.person_remove, color: Color(0xFFF44336), size: 26),
                onPressed: () => _confirmRemove(member),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
        onTap: () => _showMemberDetailDialog(member, isCurrentUserHead, currentUserId),
      ),
    );
  }

  void _showEditFamilyNameDialog(String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Family Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter new family name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              final provider = Provider.of<FamilyProvider>(context, listen: false);
              final result = await provider.updateSettings(name: newName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success'] ? 'Family name updated!' : result['message']),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberOptions(String inviteCode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Family Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.share, color: Colors.blue),
              ),
              title: const Text('Share Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Send the 6-digit code via any app'),
              onTap: () {
                Navigator.pop(ctx);
                _shareInviteCode(inviteCode);
              },
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.email, color: Colors.green),
              ),
              title: const Text('Enter Member Email', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Send a direct invitation email'),
              onTap: () {
                Navigator.pop(ctx);
                _showEmailInviteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite via Email'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We will send a join link to this email address.', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'email@example.com',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final email = _emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) return;
              Navigator.pop(ctx);
              _handleSendInvite(email);
            },
            child: const Text('Send Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendInvite(String email) async {
    setState(() => _isSending = true);
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final result = await provider.sendInvite(email);
    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] ? 'Invitation sent to $email!' : (result['message'] ?? 'Failed to send invite')),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleMenuAction(String value, bool isHead) {
    switch (value) {
      case 'leave':
        _confirmLeave();
        break;
      case 'delete':
        _confirmDelete();
        break;
      case 'transfer':
        _showTransferHeadDialog();
        break;
      case 'settings':
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family Settings coming soon!')));
        break;
    }
  }

  void _showTransferHeadDialog() {
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    final members = provider.members.where((m) => m['role'] != 'family_head').toList();

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No other members to transfer to.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Head Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(child: Text(member['name'][0])),
                title: Text(member['name']),
                subtitle: Text(member['email']),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRoleTransfer(member);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  void _confirmRoleTransfer(dynamic member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('Do you want to transfer the Family Head role to ${member['name']}? You will no longer have admin permissions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Provider.of<FamilyProvider>(context, listen: false).transferHeadRole(member['_id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success'] ? 'Role transferred!' : result['message']),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                ));
              }
            }, 
            child: const Text('Transfer', style: TextStyle(color: Colors.blue))
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Family?'),
        content: const Text('Are you sure you want to leave this family group? You will lose access to shared data and budgets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<FamilyProvider>(context, listen: false);
              final result = await provider.leaveFamily();
              if (mounted) {
                if (result['success']) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left family successfully'), backgroundColor: Colors.blue));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Family?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('WARNING: This will permanently delete the family group and all shared data for all members. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<FamilyProvider>(context, listen: false);
              final result = await provider.deleteFamily();
              if (mounted) {
                if (result['success']) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family deleted permanently'), backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(dynamic member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove ${member['name']} from the family? They will lose access to all shared features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<FamilyProvider>(context, listen: false);
              final result = await provider.removeMember(member['_id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success'] ? 'Member removed successfully' : result['message']),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMemberDetailDialog(dynamic member, bool isCurrentUserHead, String? currentUserId) {
    final isMe = member['_id'] == currentUserId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFBBDEFB),
              child: Text(member['name'][0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            ),
            const SizedBox(height: 16),
            Text(member['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(member['email'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: Colors.green),
              title: const Text('View Spending Report'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MemberReportScreen(memberId: member['_id'], memberName: member['name'])),
                );
              },
            ),
            // New logic: anyone in family can remove anyone except the head and themselves
            if (!isMe && member['role'] != 'family_head')
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
                title: const Text('Remove from Family'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemove(member);
                },
              ),
            // Head-only administrative actions
            if (isCurrentUserHead && member['role'] != 'family_head')
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: const Text('Make Family Head'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRoleTransfer(member);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(size.width, startY);
      path.lineTo(size.width, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }
    startX = size.width;
    while (startX > 0) {
      path.moveTo(startX, size.height);
      path.lineTo(startX - dashWidth, size.height);
      startX -= dashWidth + dashSpace;
    }
    startY = size.height;
    while (startY > 0) {
      path.moveTo(0, startY);
      path.lineTo(0, startY - dashWidth);
      startY -= dashWidth + dashSpace;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
