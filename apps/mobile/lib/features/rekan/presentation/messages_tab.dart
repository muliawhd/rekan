import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../../../core/widgets/rekan_avatar_badge.dart';
import '../data/rekan_models.dart';
import '../data/supabase_rekan_repository.dart';

/// 04 COLLAB (Tab 4: Pesan) — 1-on-1 Chat Inbox & Live Direct Messaging via Supabase.
class RekanMessagesTab extends StatelessWidget {
  const RekanMessagesTab({
    super.key,
    required this.peers,
    required this.repository,
    required this.currentUserName,
  });

  final List<StudentProfile> peers;
  final RekanRepository repository;
  final String currentUserName;

  void _openDirectChat(BuildContext context, StudentProfile peer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectChatScreen(
          peer: peer,
          repository: repository,
          currentUserName: currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const Text(
          'Pesan 1-1 Antar Rekan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: RekanPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Diskusi langsung terkait tugas kuliah, jadwal belajar, dan kompetisi.',
          style: TextStyle(fontSize: 13, color: RekanPalette.muted),
        ),
        const SizedBox(height: 14),
        if (peers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RekanPalette.border),
            ),
            child: const Text(
              'Belum ada kontak rekan tersedia di Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RekanPalette.muted),
            ),
          )
        else
          ...peers.map(
            (peer) => InkWell(
              onTap: () => _openDirectChat(context, peer),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RekanPalette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RekanPalette.border),
                ),
                child: Row(
                  children: [
                    RekanAvatarBadge(
                      name: peer.displayName,
                      size: 46,
                      isOnline: peer.isOnline,
                      useBlueTone: peer.intent == 'competition',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peer.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: RekanPalette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${peer.roleFocus} · ${peer.program}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: RekanPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: RekanPalette.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({
    super.key,
    required this.peer,
    required this.repository,
    required this.currentUserName,
  });

  final StudentProfile peer;
  final RekanRepository repository;
  final String currentUserName;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _msgCtrl = TextEditingController();
  List<DirectMessageItem> _messages = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.repository.fetchDirectMessages(widget.peer.id);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await widget.repository.sendDirectMessage(
      peerProfileId: widget.peer.id,
      senderName: widget.currentUserName,
      body: text,
    );
    await _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = widget.repository.currentUserId;
    return Scaffold(
      backgroundColor: RekanPalette.background,
      appBar: AppBar(
        title: Row(
          children: [
            RekanAvatarBadge(
              name: widget.peer.displayName,
              size: 34,
              isOnline: widget.peer.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peer.displayName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.peer.roleFocus} · ${widget.peer.studyModeLabel}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: RekanPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: RekanPalette.blue),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Mulai obrolan akademik dengan ${widget.peer.displayName} untuk atur jadwal belajar atau diskusi proyek.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: RekanPalette.muted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final isMe = m.senderUserId == myUid;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? RekanPalette.lemon
                                    : RekanPalette.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMe
                                      ? RekanPalette.lemonVivid
                                      : RekanPalette.border,
                                ),
                              ),
                              child: Text(
                                m.body,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isMe
                                      ? RekanPalette.lemonInk
                                      : RekanPalette.ink,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            color: RekanPalette.surface,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan akademik...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

