import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/harry_controller.dart';
import '../services/gamification/gamification_service.dart';
import '../widgets/pointsWidget.dart';
import '../widgets/profile_initials_widget.dart';

/// Builds the screen a challenge card opens, from the rule's `screen_name`
/// (e.g. "agenda", "scanner"). Returns null for keys the caller can't open.
typedef RewardScreenBuilder = Widget? Function(String screenKey);

/// Points, challenges and the leaderboard.
///
/// Everything here is read from the gamification Flows; nothing is computed or
/// awarded on the device. See docs/features/gamification-backend.md.
class RewardsPage extends StatefulWidget {
  final int userID;
  final RewardScreenBuilder? screenBuilder;

  const RewardsPage({required this.userID, this.screenBuilder, super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final GamificationService _service = GamificationService.instance;
  bool _loading = true;
  bool _failed = false;

  Future<Leaderboard>? _leaderboard;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _reload();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _service.progress == null;
      _failed = false;
    });
    final p = await _service.refresh();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = p == null && _service.progress == null;
      _leaderboard = _service.fetchLeaderboard(userId: widget.userID);
    });
  }

  void _open(RewardRule rule) {
    final key = rule.screen;
    if (key == _harryKey) {
      // Harry is the floating assistant, not a screen: open its chat panel.
      context.read<HarryController>().open();
      return;
    }
    final screen = key == null ? null : widget.screenBuilder?.call(key);
    if (screen == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _service.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final progress = _service.progress;
    return Theme(
      data: _rewardsTheme(Theme.of(context)),
      child: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Rewards'),
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                bottom: const TabBar(
                  labelColor: kRewardsGold,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: kRewardsGold,
                  dividerColor: Colors.white12,
                  tabs: [
                    Tab(text: 'Today'),
                    Tab(text: 'Challenges'),
                    Tab(text: 'Leaderboard'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _Header(progress: progress),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _failed
                            ? _Message(
                                icon: Icons.cloud_off_rounded,
                                text:
                                    "Couldn't load your rewards. Check your connection.",
                                onRetry: _reload,
                              )
                            : TabBarView(
                                children: [
                                  _RuleList(
                                    rules: _today(progress!),
                                    empty: progress.dayNumber == null
                                        ? 'Daily challenges open on each day of the event.'
                                        : "You've done everything for today. See you tomorrow!",
                                    onRefresh: _reload,
                                    onTap: _open,
                                    canOpen: _canOpen,
                                  ),
                                  _RuleList(
                                    rules: _challenges(progress),
                                    empty: 'No challenges yet.',
                                    onRefresh: _reload,
                                    onTap: _open,
                                    canOpen: _canOpen,
                                    grouped: true,
                                  ),
                                  _LeaderboardTab(
                                    future: _leaderboard,
                                    myId: widget.userID,
                                    onRefresh: _reload,
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dark "awards night" theme over the statue backdrop: light text and
  /// translucent cards, keeping the app's fonts.
  static ThemeData _rewardsTheme(ThemeData base) {
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: kRewardsGold,
        surface: const Color(0xFF15120C),
        onSurface: Colors.white,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
      cardTheme:
          base.cardTheme.copyWith(color: Colors.black.withValues(alpha: 0.45)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kRewardsGold,
          side: const BorderSide(color: kRewardsGold),
        ),
      ),
    );
  }

  /// `screen_name` that opens the Harry chat instead of pushing a screen.
  static const String _harryKey = 'harry';

  bool _canOpen(RewardRule r) =>
      r.screen == _harryKey ||
      (r.screen != null && widget.screenBuilder?.call(r.screen!) != null);

  /// Day-scoped rules and live quests, unfinished first.
  static List<RewardRule> _today(RewardsProgress p) {
    final list = p.rules
        .where((r) =>
            !r.expired && (r.category == RewardCategory.daily || r.isQuest))
        .toList();
    list.sort(_byOpenFirst);
    return list;
  }

  /// Quick wins then challenges, unfinished first within each.
  static List<RewardRule> _challenges(RewardsProgress p) {
    final list = p.rules
        .where((r) => r.category != RewardCategory.daily && !r.isQuest)
        .toList();
    list.sort((a, b) {
      final c = a.category.index.compareTo(b.category.index);
      return c != 0 ? c : _byOpenFirst(a, b);
    });
    return list;
  }

  static int _byOpenFirst(RewardRule a, RewardRule b) {
    if (a.complete != b.complete) return a.complete ? 1 : -1;
    if (a.upcoming != b.upcoming) return a.upcoming ? 1 : -1;
    return b.fraction.compareTo(a.fraction);
  }
}

class _Header extends StatelessWidget {
  final RewardsProgress? progress;

  const _Header({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final day = p?.dayNumber;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD4A437).withValues(alpha: 0.9),
            const Color(0xFF6E4B12).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRewardsGold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: kRewardsGold.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: -4),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p == null ? '— pts' : '${p.total} pts',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  p?.rank == null
                      ? 'Earn points to join the leaderboard'
                      : 'Rank #${p!.rank} of ${p.players}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (day != null && p != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Day $day of ${p.eventDays.length}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _RuleList extends StatelessWidget {
  final List<RewardRule> rules;
  final String empty;
  final Future<void> Function() onRefresh;
  final void Function(RewardRule) onTap;
  final bool Function(RewardRule) canOpen;
  final bool grouped;

  const _RuleList({
    required this.rules,
    required this.empty,
    required this.onRefresh,
    required this.onTap,
    required this.canOpen,
    this.grouped = false,
  });

  static String _title(RewardCategory c) {
    switch (c) {
      case RewardCategory.quick:
        return 'Quick wins';
      case RewardCategory.challenge:
        return 'Challenges';
      case RewardCategory.daily:
        return 'Every day';
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    RewardCategory? section;
    for (final r in rules) {
      if (grouped && r.category != section) {
        section = r.category;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(_title(section).toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ));
      }
      children.add(
          RewardRuleCard(rule: r, onTap: canOpen(r) ? () => onTap(r) : null));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: rules.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              _Message(icon: Icons.celebration_rounded, text: empty),
            ])
          : ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 32),
              children: children),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final Future<Leaderboard>? future;
  final int myId;
  final Future<void> Function() onRefresh;

  const _LeaderboardTab(
      {required this.future, required this.myId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Leaderboard>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _Message(
              icon: Icons.cloud_off_rounded,
              text: '${snap.error}',
              onRetry: onRefresh);
        }
        final board = snap.data!;
        if (!board.enabled) {
          return const _Message(
              icon: Icons.lock_clock_rounded,
              text: 'The leaderboard is hidden for now. Keep earning!');
        }
        final pinMe =
            board.me != null && !board.entries.any((e) => e.userId == myId);
        return Column(
          children: [
            if (board.frozen)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Final standings — the leaderboard is frozen.',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: kConnectedOrange)),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: board.entries.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        _Message(
                            icon: Icons.leaderboard_rounded,
                            text: 'No points on the board yet. Be the first!'),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: board.entries.length,
                        itemBuilder: (_, i) => _LeaderRow(
                            entry: board.entries[i],
                            isMe: board.entries[i].userId == myId),
                      ),
              ),
            ),
            if (pinMe)
              Material(
                elevation: 8,
                color: const Color(0xFF15120C),
                child: SafeArea(
                    top: false,
                    child: _LeaderRow(entry: board.me!, isMe: true)),
              ),
          ],
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderRow({required this.entry, required this.isMe});

  static const _medals = [
    Color(0xFFFFB300),
    Color(0xFF9E9E9E),
    Color(0xFFA0522D)
  ];

  @override
  Widget build(BuildContext context) {
    final medal = entry.rank <= 3 ? _medals[entry.rank - 1] : null;
    final subtitle =
        [entry.role, entry.company].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      color: isMe ? kRewardsGold.withValues(alpha: 0.16) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: medal == null
                ? Text('${entry.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15))
                : Icon(Icons.workspace_premium_rounded, color: medal, size: 28),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FittedBox(
              child: entry.profilePhoto == null
                  ? AttendeeProfileInitials(
                      firstName:
                          entry.firstName.isEmpty ? '.' : entry.firstName,
                      lastName: entry.lastName)
                  : AttendeeProfilePicWidget(profileID: entry.profilePhoto!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe
                      ? '${entry.firstName} ${entry.lastName} (you)'
                      : '${entry.firstName} ${entry.lastName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          Text('${entry.points} pts',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;

  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gold used for accents on the Rewards screen, picked from the statue.
const kRewardsGold = Color(0xFFE8B84A);

/// The trophy photo, heavily blurred into a gold glow. The blur also hides the
/// stock-photo watermark tiled across the image, and the gradient keeps text
/// readable over it.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: 14, sigmaY: 14, tileMode: TileMode.decal),
            // Scaled up so the blurred edges fall outside the screen.
            child: Transform.scale(
              scale: 1.15,
              child: Image.asset('assets/images/backgrounds/statue.png',
                  fit: BoxFit.cover),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.4, 1],
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
