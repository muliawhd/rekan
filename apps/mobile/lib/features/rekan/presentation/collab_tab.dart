import 'package:material_ui/material_ui.dart';

import '../../../core/theme/rekan_theme.dart';
import '../data/rekan_models.dart';

/// 04 COLLAB (Tab 3: Kolaborasi) — Collaboration Rooms (Chat, Tasks, Batch Materials)
/// and Collaboration Invitations (Pending / Accepted / Declined), live from Supabase.
class RekanCollabTab extends StatefulWidget {
  const RekanCollabTab({
    super.key,
    required this.rooms,
    required this.invitations,
    required this.currentUserName,
    required this.onCreateRoom,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onSendRoomMessage,
    required this.onUpdateInvitation,
    required this.onRefresh,
  });

  final List<CollaborationRoom> rooms;
  final List<InvitationItem> invitations;
  final String currentUserName;
  final Future<void> Function({
    required String title,
    required String courseCode,
    required String intent,
    required String description,
    required String nextSessionLabel,
  }) onCreateRoom;
  final Future<void> Function(String taskId, bool isDone) onToggleTask;
  final Future<void> Function(String roomId, String title, String dueLabel)
      onAddTask;
  final Future<void> Function(String roomId, String body) onSendRoomMessage;
  final Future<void> Function(String invitationId, String status)
      onUpdateInvitation;
  final Future<void> Function() onRefresh;

  @override
  State<RekanCollabTab> createState() => _RekanCollabTabState();
}

class _RekanCollabTabState extends State<RekanCollabTab> {
  int _segment = 0; // 0: Daftar Room, 1: Undangan

  void _openCreateRoomSheet() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'IF2110');
    final descCtrl = TextEditingController();
    final schedCtrl = TextEditingController(text: 'Jumat, 19:30 WIB');
    String intent = 'study_group';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Buat Ruang Kolaborasi Baru',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nama ruang (mis. Study Group Basis Data)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Kode mata kuliah / lomba (mis. IF2240)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('study_group', 'Study Group'),
                      ('competition', 'Tim Lomba'),
                      ('research', 'Riset'),
                    ].map((opt) {
                      return ChoiceChip(
                        label: Text(opt.$2),
                        selected: intent == opt.$1,
                        selectedColor: RekanPalette.lemon,
                        onSelected: (_) =>
                            setSheetState(() => intent = opt.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Deskripsi singkat fokus belajar / lomba',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: schedCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Jadwal sesi berikutnya',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      Navigator.of(ctx).pop();
                      await widget.onCreateRoom(
                        title: titleCtrl.text.trim(),
                        courseCode: codeCtrl.text.trim(),
                        intent: intent,
                        description: descCtrl.text.trim(),
                        nextSessionLabel: schedCtrl.text.trim(),
                      );
                    },
                    child: const Text('Simpan Ruang ke Supabase'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRoomWorkspace(CollaborationRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RoomWorkspaceScreen(
          roomId: room.id,
          initialRoom: room,
          roomsProvider: () => widget.rooms,
          onToggleTask: widget.onToggleTask,
          onAddTask: widget.onAddTask,
          onSendRoomMessage: widget.onSendRoomMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: RekanPalette.blue,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kolaborasi & Ruang',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: RekanPalette.ink,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _openCreateRoomSheet,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('+ Room'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segment selector: Daftar Room vs Undangan
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: 'Ruang (${widget.rooms.length})',
                  active: _segment == 0,
                  onTap: () => setState(() => _segment = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentButton(
                  label: 'Undangan (${widget.invitations.length})',
                  active: _segment == 1,
                  onTap: () => setState(() => _segment = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_segment == 0) ...[
            if (widget.rooms.isEmpty)
              const _EmptyCard('Belum ada ruang kolaborasi di Supabase.')
            else
              ...widget.rooms.map((room) {
                final doneCount = room.tasks.where((t) => t.isDone).length;
                return InkWell(
                  onTap: () => _openRoomWorkspace(room),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: RekanPalette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: RekanPalette.border),
                      boxShadow: RekanPalette.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: RekanPalette.lemonTint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: RekanPalette.lemonSoft),
                              ),
                              child: Text(
                                room.courseCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: RekanPalette.lemonDark,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              room.nextSessionLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: RekanPalette.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          room.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: RekanPalette.ink,
                          ),
                        ),
                        if (room.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            room.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: RekanPalette.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatBadge(
                              'Tugas $doneCount/${room.tasks.length}',
                            ),
                            const SizedBox(width: 8),
                            _StatBadge(
                              'Materi ${room.materials.length}',
                            ),
                            const SizedBox(width: 8),
                            _StatBadge(
                              'Pesan ${room.messages.length}',
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: RekanPalette.muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ] else ...[
            if (widget.invitations.isEmpty)
              const _EmptyCard(
                'Belum ada undangan kolaborasi. Ajak rekan lewat tab Jelajah atau Cari!',
              )
            else
              ...widget.invitations.map(
                (inv) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: RekanPalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RekanPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inv.targetName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: RekanPalette.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: inv.status == 'accepted'
                                  ? RekanPalette.lemonTint
                                  : RekanPalette.blueTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inv.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: inv.status == 'accepted'
                                    ? RekanPalette.lemonDark
                                    : RekanPalette.blueDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (inv.goalNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          inv.goalNote,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: RekanPalette.inkSecondary,
                          ),
                        ),
                      ],
                      if (inv.status == 'pending') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => widget.onUpdateInvitation(
                                  inv.id,
                                  'declined',
                                ),
                                child: const Text('Batalkan'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => widget.onUpdateInvitation(
                                  inv.id,
                                  'accepted',
                                ),
                                child: const Text('Tandai Aktif'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoomWorkspaceScreen extends StatefulWidget {
  const _RoomWorkspaceScreen({
    required this.roomId,
    required this.initialRoom,
    required this.roomsProvider,
    required this.onToggleTask,
    required this.onAddTask,
    required this.onSendRoomMessage,
  });

  final String roomId;
  final CollaborationRoom initialRoom;
  final List<CollaborationRoom> Function() roomsProvider;
  final Future<void> Function(String taskId, bool isDone) onToggleTask;
  final Future<void> Function(String roomId, String title, String dueLabel)
      onAddTask;
  final Future<void> Function(String roomId, String body) onSendRoomMessage;

  @override
  State<_RoomWorkspaceScreen> createState() => _RoomWorkspaceScreenState();
}

class _RoomWorkspaceScreenState extends State<_RoomWorkspaceScreen> {
  int _tab = 0; // 0: Chat, 1: Tugas, 2: Materi (Batch)
  final _msgCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();
  final _dueCtrl = TextEditingController(text: 'Minggu ini');
  final Set<String> _selectedMaterials = {};
  late CollaborationRoom _room;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    for (final m in _room.materials) {
      _selectedMaterials.add(m.id);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _taskCtrl.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  void _syncLatestRoom() {
    final latest = widget
        .roomsProvider()
        .where((r) => r.id == widget.roomId)
        .firstOrNull;
    if (latest != null && mounted) {
      setState(() => _room = latest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RekanPalette.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _room.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_room.courseCode} · ${_room.nextSessionLabel}',
              style: const TextStyle(fontSize: 11.5, color: RekanPalette.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: RekanPalette.surface,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Chat',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentButton(
                    label: 'Tugas (${_room.tasks.length})',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentButton(
                    label: 'Materi (${_room.materials.length})',
                    active: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => _buildChatPane(),
              1 => _buildTasksPane(),
              _ => _buildMaterialsPane(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatPane() {
    return Column(
      children: [
        Expanded(
          child: _room.messages.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pesan di ruang ini.',
                    style: TextStyle(color: RekanPalette.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _room.messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = _room.messages[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RekanPalette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RekanPalette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: RekanPalette.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.body,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: RekanPalette.ink,
                            ),
                          ),
                        ],
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
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan ke ruang kolaborasi...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final text = _msgCtrl.text.trim();
                    if (text.isEmpty) return;
                    _msgCtrl.clear();
                    await widget.onSendRoomMessage(_room.id, text);
                    _syncLatestRoom();
                  },
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
    );
  }

  Widget _buildTasksPane() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tambah checklist tugas baru...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final t = _taskCtrl.text.trim();
                if (t.isEmpty) return;
                _taskCtrl.clear();
                await widget.onAddTask(_room.id, t, _dueCtrl.text.trim());
                _syncLatestRoom();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(52, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('+'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._room.tasks.map(
          (task) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: RekanPalette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RekanPalette.border),
            ),
            child: CheckboxListTile(
              value: task.isDone,
              activeColor: RekanPalette.blue,
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration:
                      task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                'Deadline: ${task.dueLabel}',
                style: const TextStyle(fontSize: 12, color: RekanPalette.muted),
              ),
              onChanged: (val) async {
                if (val == null) return;
                await widget.onToggleTask(task.id, val);
                _syncLatestRoom();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsPane() {
    return Column(
      children: [
        Expanded(
          child: _room.materials.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada file materi di ruang ini.',
                    style: TextStyle(color: RekanPalette.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _room.materials.length,
                  itemBuilder: (context, index) {
                    final item = _room.materials[index];
                    final checked = _selectedMaterials.contains(item.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: RekanPalette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: checked
                              ? RekanPalette.blue
                              : RekanPalette.border,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: checked,
                        activeColor: RekanPalette.blue,
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${item.fileType} · ${item.sizeLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: RekanPalette.muted,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedMaterials.add(item.id);
                            } else {
                              _selectedMaterials.remove(item.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        if (_room.materials.isNotEmpty)
          Container(
            color: RekanPalette.surface,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedMaterials.isEmpty
                      ? null
                      : () {
                          final totalKb = _room.materials
                              .where((m) => _selectedMaterials.contains(m.id))
                              .fold<int>(0, (s, m) => s + m.fileSizeKb);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: RekanPalette.ink,
                              content: Text(
                                'Menyiapkan bundel ${_selectedMaterials.length} materi (${(totalKb / 1024).toStringAsFixed(1)} MB)...',
                              ),
                            ),
                          );
                        },
                  child: Text(
                    'Unduh Batch (${_selectedMaterials.length} File Terpilih)',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? RekanPalette.lemon : RekanPalette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? RekanPalette.lemonVivid : RekanPalette.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? RekanPalette.lemonInk : RekanPalette.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: RekanPalette.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: RekanPalette.inkSecondary,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RekanPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RekanPalette.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: RekanPalette.muted),
      ),
    );
  }
}

