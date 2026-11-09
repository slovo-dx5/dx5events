import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/dx5veScreens/eventAgendaScreen.dart';
import '../../services/active_event/active_event.dart';
import '../../services/active_event/active_event_service.dart';
import 'glitch_frame.dart';

/// FCM topic every device joins for ACLS hype pushes (sent from the Firebase
/// Console). Pushes with custom data `targetPage=acls` open the ACLS agenda.
const String kAclsTopic = 'acls';

/// The companion event's (ACLS) agenda, on the regular agenda screen.
Widget companionAgendaScreen(ActiveEvent companion) => EventAgendaScreen(
      eventID: companion.id,
      eventName: '${ActiveEvent.aclsShortName} AGENDA',
      eventDay: companion.dateFrom.day,
      eventMonth: companion.dateFrom.month,
      eventYear: companion.dateFrom.year,
      eventLocation: companion.displayLocation,
      eventDayOfWeek: companion.dayOfWeek,
    );

/// Opens the ACLS agenda if a companion event is configured.
void openCompanionAgenda(BuildContext context) {
  final companion = ActiveEventService.instance.companion;
  if (companion == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => companionAgendaScreen(companion)),
  );
}

/// Strip under the agenda's date tabs. On the main event's agenda it links to
/// the ACLS agenda on ACLS day only; on the ACLS agenda (e.g. opened from a
/// hype push before the day) it always brands the page.
/// Renders nothing when no companion is configured.
class CompanionAgendaBanner extends StatelessWidget {
  const CompanionAgendaBanner({super.key, required this.eventID});

  final String eventID;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ActiveEventService>();
    final companion = service.companion;
    if (companion == null) return const SizedBox.shrink();

    final isCompanionAgenda = eventID == companion.id;
    if (!isCompanionAgenda &&
        (eventID != service.current.id || !service.isCompanionDay)) {
      return const SizedBox.shrink();
    }

    final when = service.isCompanionDay
        ? 'TODAY'
        : '${companion.dateFrom.day} ${ActiveEvent.dayLabel(companion.dateFrom).split(', ')[1]}';
    final text = isCompanionAgenda
        ? '${ActiveEvent.aclsTitle} · $when · at CIO100'
        : '${ActiveEvent.aclsShortName} · $when  ·  ${ActiveEvent.aclsTitle} agenda';

    final strip = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(left: BorderSide(color: kAclsTeal, width: 4)),
      ),
      child: Row(children: [
        const Icon(Icons.podcasts, size: 18, color: kAclsGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        if (!isCompanionAgenda)
          const Icon(Icons.chevron_right, color: kAclsTeal, size: 20),
      ]),
    );

    if (isCompanionAgenda) return strip;
    return Material(
      color: Colors.black,
      child: InkWell(onTap: () => openCompanionAgenda(context), child: strip),
    );
  }
}
