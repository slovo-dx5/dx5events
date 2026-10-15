import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../services/gamification/gamification_models.dart';

/// One card on the Rewards screen: what to do, how far along the user is, and
/// what it pays. Tiered rules show a chip per tier; daily rules show a chip per
/// event day.
class RewardRuleCard extends StatelessWidget {
  final RewardRule rule;

  /// Null when the rule has no screen to open (the card is then not tappable).
  final VoidCallback? onTap;

  const RewardRuleCard({super.key, required this.rule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? kTextColorGrey;
    final accent = rule.complete ? kConnectedGreen : kPrimaryColor;
    final dimmed = rule.expired && !rule.complete;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: rule.complete || dimmed ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleIcon(rule: rule, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rule.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PointsBadge(rule: rule, color: accent),
                        ],
                      ),
                      if (rule.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(rule.description, style: TextStyle(fontSize: 12, color: muted)),
                      ],
                      if (_windowLabel(rule) case final label?) ...[
                        const SizedBox(height: 4),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: rule.expired ? muted : kConnectedOrange)),
                      ],
                      const SizedBox(height: 8),
                      if (rule.days.isNotEmpty)
                        _DayChips(days: rule.days, color: accent)
                      else if (rule.tiers.isNotEmpty)
                        _TierChips(rule: rule, color: accent)
                      else
                        _ProgressLine(rule: rule, color: accent, muted: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _windowLabel(RewardRule r) {
    final fmt = DateFormat('EEE HH:mm');
    if (r.upcoming && r.activeFrom != null) return 'Opens ${fmt.format(r.activeFrom!)}';
    if (r.expired) return 'Closed';
    if (r.activeTo != null && !r.complete) {
      final left = r.activeTo!.difference(DateTime.now());
      if (left.inHours < 24) {
        final h = left.inHours, m = left.inMinutes % 60;
        return h > 0 ? 'Ends in ${h}h ${m}m' : 'Ends in ${m}m';
      }
      return 'Ends ${fmt.format(r.activeTo!)}';
    }
    return null;
  }
}

class _RuleIcon extends StatelessWidget {
  final RewardRule rule;
  final Color color;

  const _RuleIcon({required this.rule, required this.color});

  IconData get _fallback {
    if (rule.complete) return Icons.check_rounded;
    switch (rule.category) {
      case RewardCategory.daily:
        return Icons.today_rounded;
      case RewardCategory.quick:
        return Icons.bolt_rounded;
      case RewardCategory.challenge:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(_fallback, color: color, size: 26);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: rule.icon == null || rule.complete
          ? fallback
          : Image.network(rule.icon!,
              width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final RewardRule rule;
  final Color color;

  const _PointsBadge({required this.rule, required this.color});

  @override
  Widget build(BuildContext context) {
    // "40/150" once something is earned on a multi-step rule, else "+150".
    final multi = rule.maxPoints > rule.points || rule.tiers.isNotEmpty || rule.days.isNotEmpty;
    final text = rule.complete
        ? '${rule.earned} pts'
        : (multi && rule.earned > 0)
            ? '${rule.earned}/${rule.maxPoints}'
            : '+${rule.maxPoints}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final RewardRule rule;
  final Color color;
  final Color muted;

  const _ProgressLine({required this.rule, required this.color, required this.muted});

  @override
  Widget build(BuildContext context) {
    final target = rule.target;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rule.fraction,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        if (target != null && target > 1) ...[
          const SizedBox(width: 8),
          Text('${rule.current}/$target', style: TextStyle(fontSize: 12, color: muted)),
        ],
      ],
    );
  }
}

class _TierChips extends StatelessWidget {
  final RewardRule rule;
  final Color color;

  const _TierChips({required this.rule, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressLine(
          rule: rule,
          color: color,
          muted: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? kTextColorGrey,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final t in rule.tiers)
              _Chip(
                label: '${t.count} → ${t.points}',
                done: t.done,
                color: color,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChips extends StatelessWidget {
  final List<RewardDay> days;
  final Color color;

  const _DayChips({required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < days.length; i++)
          _Chip(label: 'Day ${i + 1}', done: days[i].done, color: color),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;

  const _Chip({required this.label, required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: done ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: done ? 1 : 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check, size: 12, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: done ? Colors.white : color)),
        ],
      ),
    );
  }
}
