import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/search_service.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../models/community_model.dart';
import '../../widgets/common/tenku_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchService = SearchService();
  late TabController _tabCtrl;
  Timer? _debounce;

  List<SearchResult> _results = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchCtrl.text.trim();
      if (q == _query) return;
      setState(() { _query = q; _loading = q.isNotEmpty; });
      if (q.isEmpty) { setState(() => _results = []); return; }
      _doSearch(q);
    });
  }

  Future<void> _doSearch(String q) async {
    final results = await _searchService.globalSearch(q);
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<SearchResult> get _userResults => _results.where((r) => r.type == SearchResultType.user).toList();
  List<SearchResult> get _communityResults => _results.where((r) => r.type == SearchResultType.community).toList();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search people, communities...',
            hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 16),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              onPressed: () { _searchCtrl.clear(); setState(() { _results = []; _query = ''; }); },
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'All'), Tab(text: 'People'), Tab(text: 'Communities')],
        ),
      ),
      body: _query.isEmpty
          ? _SearchSuggestions()
          : _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ResultsList(results: _results, currentUser: user, onUserTap: (u) => _openUserChat(context, u, user?.uid ?? '')),
                    _ResultsList(results: _userResults, currentUser: user, onUserTap: (u) => _openUserChat(context, u, user?.uid ?? '')),
                    _ResultsList(results: _communityResults, currentUser: user, onUserTap: (_) {}),
                  ],
                ),
    );
  }

  Future<void> _openUserChat(BuildContext context, UserModel other, String currentUserId) async {
    if (currentUserId.isEmpty) return;
    final chatService = ChatService();
    final chatId = await chatService.getOrCreateDirectChat(currentUserId, other.uid);
    if (context.mounted) {
      context.pop();
      context.push('/chat/$chatId', extra: {'name': other.displayName, 'avatar': other.avatarUrl, 'participantId': other.uid});
    }
  }
}

class _SearchSuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text('Search Tenku', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Find people and communities', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final UserModel? currentUser;
  final Function(UserModel) onUserTap;

  const _ResultsList({required this.results, required this.currentUser, required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(child: Text('No results found', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 72),
      itemBuilder: (_, i) {
        final r = results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: TenkuAvatar(imageUrl: r.imageUrl, name: r.title, size: 48),
          title: Text(r.title, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text(r.subtitle, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)),
          trailing: r.type == SearchResultType.user
              ? _MessageBtn(onTap: () {
                  if (r.data is UserModel) onUserTap(r.data as UserModel);
                })
              : r.type == SearchResultType.community
                  ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                  : null,
          onTap: () {
            if (r.type == SearchResultType.user && r.data is UserModel) {
              onUserTap(r.data as UserModel);
            } else if (r.type == SearchResultType.community) {
              context.pop();
              context.push('/community/${r.id}');
            }
          },
        );
      },
    );
  }
}

class _MessageBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _MessageBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Message', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
