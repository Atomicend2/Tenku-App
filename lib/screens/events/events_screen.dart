import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/phase3_models.dart';
import '../../services/event_service.dart';

class EventsScreen extends StatelessWidget {
  final String communityId;
  const EventsScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();
    final eventService = EventService();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary), onPressed: () => context.pop()),
        title: Text('Events', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CreateEventSheet(
                communityId: communityId,
                creatorId: user.uid,
                creatorName: user.displayName,
                eventService: eventService,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: eventService.streamCommunityEvents(communityId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text('No events yet', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Create the first community event!', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (_, i) => EventCard(
              event: events[i],
              currentUserId: user.uid,
              eventService: eventService,
            ),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  final String currentUserId;
  final EventService eventService;

  const EventCard({super.key, required this.event, required this.currentUserId, required this.eventService});

  @override
  Widget build(BuildContext context) {
    final isGoing = event.isAttending(currentUserId);
    final isMaybe = event.isMaybe(currentUserId);
    final isPast = event.isPast;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPast ? AppColors.divider : AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover / Date banner
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              gradient: isPast
                  ? const LinearGradient(colors: [AppColors.bgElevated, AppColors.bgCard])
                  : const LinearGradient(
                      colors: [Color(0xFF1A1A4A), Color(0xFF2A1A4A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Stack(
              children: [
                if (!isPast)
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: isPast ? AppColors.bgElevated : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isPast ? AppColors.divider : AppColors.primary.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd').format(event.startTime),
                              style: GoogleFonts.dmSans(color: isPast ? AppColors.textMuted : AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              DateFormat('MMM').format(event.startTime).toUpperCase(),
                              style: GoogleFonts.dmSans(color: isPast ? AppColors.textMuted : AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEEE, HH:mm').format(event.startTime),
                              style: GoogleFonts.dmSans(color: isPast ? AppColors.textMuted : AppColors.textSecondary, fontSize: 13),
                            ),
                            if (event.endTime != null)
                              Text(
                                'Until ${DateFormat('HH:mm').format(event.endTime!)}',
                                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Past', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(event.description!,
                      style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (event.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(event.location!, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Attendee count + RSVP
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text('${event.attendeeIds.length} going',
                        style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
                    if (event.maybeIds.isNotEmpty)
                      Text(' · ${event.maybeIds.length} maybe',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
                    const Spacer(),
                    if (!isPast) ...[
                      _RSVPButton(
                        label: 'Going', active: isGoing, color: AppColors.success,
                        onTap: () => eventService.rsvp(eventId: event.id, userId: currentUserId, response: isGoing ? 'declined' : 'going'),
                      ),
                      const SizedBox(width: 8),
                      _RSVPButton(
                        label: 'Maybe', active: isMaybe, color: AppColors.warning,
                        onTap: () => eventService.rsvp(eventId: event.id, userId: currentUserId, response: isMaybe ? 'declined' : 'maybe'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RSVPButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _RSVPButton({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : AppColors.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : AppColors.divider),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
        color: active ? color : AppColors.textSecondary,
        fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      )),
    ),
  );
}

// ─── Create Event Sheet ───────────────────────────────────────

class CreateEventSheet extends StatefulWidget {
  final String communityId;
  final String creatorId;
  final String creatorName;
  final EventService eventService;
  const CreateEventSheet({super.key, required this.communityId, required this.creatorId, required this.creatorName, required this.eventService});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime? _endTime;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(context: context, initialDate: _startTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startTime));
    if (time == null) return;
    setState(() => _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.eventService.createEvent(
      communityId: widget.communityId,
      channelId: '',
      creatorId: widget.creatorId,
      creatorName: widget.creatorName,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
    );
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Event', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                TextButton(onPressed: _loading ? null : _create, child: Text('Create', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 16),
            _Field(controller: _titleCtrl, hint: 'Event title', icon: Icons.celebration_rounded),
            const SizedBox(height: 12),
            _Field(controller: _descCtrl, hint: 'Description (optional)', icon: Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 12),
            _Field(controller: _locationCtrl, hint: 'Location (optional)', icon: Icons.location_on_outlined),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickStartTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(DateFormat('EEE, MMM d • HH:mm').format(_startTime),
                        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _Field({required this.controller, required this.hint, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: GoogleFonts.dmSans(color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
      filled: true, fillColor: AppColors.bgInput,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}
