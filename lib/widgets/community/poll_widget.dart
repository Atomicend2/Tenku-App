import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/phase3_models.dart';
import '../../services/poll_service.dart';

// ─── Interactive Poll Widget ──────────────────────────────────

class PollWidget extends StatelessWidget {
  final PollModel poll;
  final String currentUserId;
  final PollService pollService;

  const PollWidget({
    super.key,
    required this.poll,
    required this.currentUserId,
    required this.pollService,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasVoted(currentUserId);
    final canVote = !poll.isClosed &&
        (poll.expiresAt == null || DateTime.now().isBefore(poll.expiresAt!));

    return StreamBuilder<PollModel?>(
      stream: pollService.streamPoll(poll.id),
      builder: (context, snap) {
        final livePoll = snap.data ?? poll;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.poll_rounded, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    livePoll.isClosed ? 'Poll Closed' : 'Poll',
                    style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${livePoll.totalVotes} vote${livePoll.totalVotes != 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question
              Text(
                livePoll.question,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Options
              ...livePoll.options.map((option) {
                final percent = livePoll.getOptionPercent(option);
                final iVoted = option.hasVoted(currentUserId);
                final isLeading = livePoll.options.isNotEmpty &&
                    option.voteCount == livePoll.options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);

                return GestureDetector(
                  onTap: canVote
                      ? () => pollService.vote(
                          pollId: livePoll.id,
                          optionId: option.id,
                          userId: currentUserId,
                          isMultipleChoice: livePoll.isMultipleChoice)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: iVoted ? AppColors.primary.withOpacity(0.1) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iVoted ? AppColors.primary : AppColors.divider,
                        width: iVoted ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        children: [
                          // Progress bar
                          if (hasVoted || livePoll.isClosed)
                            FractionallySizedBox(
                              widthFactor: percent,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: iVoted
                                      ? AppColors.primary.withOpacity(0.15)
                                      : AppColors.bgElevated.withOpacity(0.5),
                                ),
                              ),
                            ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                if (!hasVoted && canVote)
                                  Container(
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      shape: livePoll.isMultipleChoice ? BoxShape.rectangle : BoxShape.circle,
                                      borderRadius: livePoll.isMultipleChoice ? BorderRadius.circular(4) : null,
                                      border: Border.all(
                                        color: iVoted ? AppColors.primary : AppColors.textMuted,
                                        width: 1.5,
                                      ),
                                      color: iVoted ? AppColors.primary : Colors.transparent,
                                    ),
                                    child: iVoted ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                                  )
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: GoogleFonts.dmSans(
                                      color: iVoted ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: iVoted ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (hasVoted || livePoll.isClosed) ...[
                                  if (isLeading && livePoll.totalVotes > 0)
                                    const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(percent * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.dmSans(
                                      color: iVoted ? AppColors.primary : AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Footer
              if (livePoll.isClosed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Poll closed', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              else if (livePoll.expiresAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Expires ${_timeUntil(livePoll.expiresAt!)}',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return 'in ${diff.inDays}d';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'in ${diff.inMinutes}m';
  }
}

// ─── Create Poll Dialog ───────────────────────────────────────

class CreatePollSheet extends StatefulWidget {
  final String chatId;
  final String creatorId;
  final String creatorName;
  final bool isCommunityPoll;
  final PollService pollService;

  const CreatePollSheet({
    super.key,
    required this.chatId,
    required this.creatorId,
    required this.creatorName,
    required this.isCommunityPoll,
    required this.pollService,
  });

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isMultipleChoice = false;
  bool _isAnonymous = false;
  bool _hasExpiry = false;
  Duration _expiryDuration = const Duration(hours: 24);
  bool _loading = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) return;
    final options = _optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 options'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    await widget.pollService.createPoll(
      chatId: widget.chatId,
      creatorId: widget.creatorId,
      creatorName: widget.creatorName,
      question: question,
      optionTexts: options,
      isMultipleChoice: _isMultipleChoice,
      isAnonymous: _isAnonymous,
      expireAfter: _hasExpiry ? _expiryDuration : null,
      isCommunityPoll: widget.isCommunityPoll,
    );
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Poll', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: _loading ? null : _create,
                    child: Text('Post', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  TextField(
                    controller: _questionCtrl,
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                      filled: true, fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Options', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  ..._optionCtrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.value,
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Option ${e.key + 1}',
                              hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                              filled: true, fillColor: AppColors.bgInput,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              prefixText: '${e.key + 1}. ',
                              prefixStyle: GoogleFonts.dmSans(color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (_optionCtrls.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                            onPressed: () => setState(() { _optionCtrls[e.key].dispose(); _optionCtrls.removeAt(e.key); }),
                          ),
                      ],
                    ),
                  )),
                  if (_optionCtrls.length < 6)
                    TextButton.icon(
                      onPressed: () => setState(() => _optionCtrls.add(TextEditingController())),
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      label: Text('Add option', style: GoogleFonts.dmSans(color: AppColors.primary)),
                    ),
                  const SizedBox(height: 16),
                  _SwitchTile(label: 'Multiple choice', value: _isMultipleChoice, onChanged: (v) => setState(() => _isMultipleChoice = v)),
                  _SwitchTile(label: 'Anonymous voting', value: _isAnonymous, onChanged: (v) => setState(() => _isAnonymous = v)),
                  _SwitchTile(label: 'Set expiry', value: _hasExpiry, onChanged: (v) => setState(() => _hasExpiry = v)),
                  if (_hasExpiry) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ExpiryChip(label: '1h', selected: _expiryDuration.inHours == 1, onTap: () => setState(() => _expiryDuration = const Duration(hours: 1))),
                        _ExpiryChip(label: '6h', selected: _expiryDuration.inHours == 6, onTap: () => setState(() => _expiryDuration = const Duration(hours: 6))),
                        _ExpiryChip(label: '24h', selected: _expiryDuration.inHours == 24, onTap: () => setState(() => _expiryDuration = const Duration(hours: 24))),
                        _ExpiryChip(label: '7d', selected: _expiryDuration.inDays == 7, onTap: () => setState(() => _expiryDuration = const Duration(days: 7))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14)),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ],
  );
}

class _ExpiryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ExpiryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      )),
    ),
  );
}
