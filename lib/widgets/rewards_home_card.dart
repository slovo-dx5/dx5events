import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../constants.dart';
import '../helpers/analytics_helper.dart';
import '../screens/rewardsPage.dart';
import '../services/gamification/gamification_service.dart';

/// Home tile for Rewards: the user's points and rank, opening the Rewards
/// screen. Hidden until the gamification Flows are configured.
class RewardsHomeCard extends StatefulWidget {
  final int? userID;
  final RewardScreenBuilder screenBuilder;

  /// Trims spacing and folds the points/rank into the subtitle so the card can
  /// sit in a half-width row beside the Shop card.
  final bool compact;

  const RewardsHomeCard({
    super.key,
    required this.userID,
    required this.screenBuilder,
    this.compact = false,
  });

  @override
  State<RewardsHomeCard> createState() => _RewardsHomeCardState();
}

class _RewardsHomeCardState extends State<RewardsHomeCard> {
  final GamificationService _service = GamificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    if (_service.isEnabled) {
      // Covers a first login, where init() ran before there was a user id.
      _service.logDailyOpen();
      _service.refresh();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userID;
    if (!_service.isEnabled || userId == null) return const SizedBox.shrink();
    final p = _service.progress;
    final open = p?.rules.where((r) => !r.complete && !r.expired && !r.upcoming).length;
    final compact = widget.compact;

    final subtitle = p == null
        ? 'Earn points all event long'
        : open == null || open == 0
            ? 'Check the leaderboard'
            : '$open challenge${open == 1 ? '' : 's'} waiting';

    return GestureDetector(
      onTap: () async {
        await Dx5veAnalytics().logdx5veEvent(eventName: 'rewards_page_opened');
        if (!context.mounted) return;
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: RewardsPage(userID: userId, screenBuilder: widget.screenBuilder),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
      child: Container(
        height: 84,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPrimaryColor, kNashPurple]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 9 : 10),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: compact ? 24 : 28),
            ),
            SizedBox(width: compact ? 10 : 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rewards',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    // In compact mode the trailing points column is gone, so
                    // surface the points/rank in the subtitle instead.
                    compact
                        ? (p == null
                            ? subtitle
                            : '${p.total} pts${p.rank == null ? '' : ' · #${p.rank}'}')
                        : subtitle,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70, fontSize: compact ? 12 : 13),
                  ),
                ],
              ),
            ),
            if (!compact)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p == null ? '—' : '${p.total}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(p?.rank == null ? 'pts' : 'pts · #${p!.rank}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
