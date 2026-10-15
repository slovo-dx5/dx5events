/**
 * G4 "Gamification — Meeting Mirror" · Run Script operation · key: `mirror`
 *
 * Event Hook on app_activity_logs items.create. A meeting is accepted by one
 * person, but both people earn "Deal maker" progress. When the acceptor's app
 * logs `meeting_accepted` (metadata.requested_by_id = the other person), this
 * writes the same log for the requester. G1 then scores it like any other log.
 *
 * The mirrored row's client_event_id is derived from the original, so a replay
 * hits the unique constraint instead of double counting, and `mirrored: true`
 * stops it being mirrored again.
 *
 * Returns { rows: [...] } for a Create Data operation on app_activity_logs
 * (Emit Events: ON — G1 must see it). Empty rows → the Condition skips it.
 */
module.exports = async function (data) {
  const log = (data.$trigger && data.$trigger.payload) || {};
  if (log.action !== 'meeting_accepted') return { rows: [] };

  let meta = log.metadata;
  if (typeof meta === 'string') {
    try {
      meta = JSON.parse(meta);
    } catch (_) {
      meta = null;
    }
  }
  meta = meta && typeof meta === 'object' ? meta : {};
  if (meta.mirrored) return { rows: [] };

  const requester = Number(meta.requested_by_id);
  if (!Number.isFinite(requester) || requester <= 0) return { rows: [] };
  if (String(requester) === String(log.user_id)) return { rows: [] };

  return {
    rows: [
      {
        client_event_id: `${log.client_event_id}-mirror`,
        user_id: requester,
        event_id: log.event_id || null,
        action: 'meeting_accepted',
        target_type: log.target_type || 'meeting',
        target_id: log.target_id || null,
        metadata: { mirrored: true, accepted_by: log.user_id },
        platform: 'server',
        occurred_at: log.occurred_at || new Date().toISOString(),
      },
    ],
  };
};
