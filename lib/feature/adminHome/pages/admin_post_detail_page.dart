import 'package:cctv_app/core/network/models/active_post.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/feature/home/widgets/home_post_container.dart';
import 'package:cctv_app/core/components/space.dart';
import 'package:cctv_app/core/extensions/context.dart';
import 'package:cctv_app/core/network/services/case_post_service.dart';
import 'package:cctv_app/core/network/services/admin_control_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:flutter/material.dart';

class AdminPostDetailPage extends StatelessWidget {
  final ActivePost post;
  final VoidCallback? onPostUpdated;

  const AdminPostDetailPage({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: kWhiteColor,
        foregroundColor: kBlackColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 16),
        children: [
          HomePostContainer(
            isAdmin: true,
            post: post,
            onClickProfile: () {},
            onPostUpdated: onPostUpdated ?? () {},
          ),
          Space.vertical(20),
          _buildModerationPanel(context),
        ],
      ),
    );
  }

  Widget _buildModerationPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moderation Actions', style: context.bold.copyWith(fontSize: 16)),
          Space.vertical(12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionButton(
                context,
                icon: Icons.visibility_off,
                label: 'Hide Post',
                color: Colors.orange,
                onTap: () => _hidePost(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.delete_forever,
                label: 'Delete Post',
                color: Colors.red,
                onTap: () => _deletePost(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.warning,
                label: 'Warn Author',
                color: Colors.amber.shade700,
                onTap: () => _warnAuthor(context),
              ),
              _buildActionButton(
                context,
                icon: Icons.poll,
                label: 'Hide Voting',
                color: Colors.purple,
                onTap: () => _hideVoting(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _hidePost(BuildContext context) async {
    final confirm = await _showConfirmDialog(context, 'Hide this post from public view?');
    if (confirm != true) return;
    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      await CasePostService().hidePost(accessToken: token, postId: post.postId, hidden: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post hidden')));
      onPostUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await _showConfirmDialog(context, 'Permanently delete this post?');
    if (confirm != true) return;
    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      await CasePostService().deletePost(accessToken: token, postId: post.postId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
      onPostUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _warnAuthor(BuildContext context) async {
    final confirm = await _showConfirmDialog(context, 'Send a warning to the author of this post?');
    if (confirm != true) return;
    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      await AdminControlService().sendWarningToUser(
        accessToken: token,
        userId: post.createdBy ?? 0,
        alertNote: 'Warning regarding your post: ${post.postDescription}',
        attachedMetaId: post.postId,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning sent')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _hideVoting(BuildContext context) async {
    final confirm = await _showConfirmDialog(context, 'Hide voting results for this post?');
    if (confirm != true) return;
    try {
      final token = await const AuthStorage().readAccessToken() ?? '';
      await CasePostService().hideVotingResults(accessToken: token, postId: post.postId, hidden: true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voting hidden')));
      onPostUpdated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }
}
