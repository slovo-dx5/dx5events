import '../dioServices/base_url.dart';
import '../dioServices/dioFetchService.dart';
import '../models/eventModel.dart';
import '../models/speakersModel.dart';

/// Mirrors the JS `getSpeakers` utility.
///
/// Given the raw speaker-association list from an event (or agenda session),
/// this function:
///   1. Extracts speaker IDs and records their original display order.
///   2. Fetches all speaker records in a single API call.
///   3. Resolves photo UUIDs to full asset URLs.
///   4. Merges back [assumedRole] and [uniqueStylingProperty] from each
///      association onto the fetched speaker.
///   5. Returns the list sorted by original order.
Future<List<EnrichedSpeaker>> getSpeakers(
    List<SpeakerAssociation> associations) async {
  if (associations.isEmpty) return [];

  // Step 1 — record order and extra props keyed by speaker ID.
  final orderMap = <int, int>{};
  final propsMap = <int, _SpeakerProps>{};

  for (var i = 0; i < associations.length; i++) {
    final id = associations[i].speaker.key;
    orderMap[id] = i;
    propsMap[id] = _SpeakerProps(
      assumedRole: associations[i].assumedRole,
      uniqueStylingProperty: associations[i].uniqueStylingProperty,
    );
  }

  // Step 2 — single bulk fetch.
  final response =
      await DioFetchService().fetchSpeakersByIds(orderMap.keys.toList());
  final speakersModel = SpeakersModel.fromJson(response.data);

  if (speakersModel.data.isEmpty) return [];

  // Step 3-4 — resolve photo URLs and merge association metadata.
  final enriched = speakersModel.data.map((speaker) {
    final resolvedPhoto = _resolvePhotoUrl(speaker.photo);
    final props = propsMap[speaker.id];

    return EnrichedSpeaker(
      speaker: resolvedPhoto != speaker.photo
          ? _copyWithPhoto(speaker, resolvedPhoto)
          : speaker,
      order: orderMap[speaker.id] ?? 0,
      assumedRole: props?.assumedRole,
      uniqueStylingProperty: props?.uniqueStylingProperty,
    );
  }).toList();

  // Step 5 — restore original order.
  enriched.sort((a, b) => a.order.compareTo(b.order));
  return enriched;
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class EnrichedSpeaker {
  final IndividualSpeaker speaker;
  final int order;
  final String? assumedRole;
  final String? uniqueStylingProperty;

  const EnrichedSpeaker({
    required this.speaker,
    required this.order,
    this.assumedRole,
    this.uniqueStylingProperty,
  });
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _SpeakerProps {
  final String? assumedRole;
  final String? uniqueStylingProperty;

  const _SpeakerProps({this.assumedRole, this.uniqueStylingProperty});
}

/// Prepends the Directus assets base URL when [photo] is a bare UUID/ID
/// rather than an already-resolved URL.
String _resolvePhotoUrl(String photo) {
  if (photo.startsWith('http')) return photo;
  return '${BaseURL.Baseurl}/assets/$photo';
}

/// Returns a copy of [speaker] with [photo] replaced.
IndividualSpeaker _copyWithPhoto(IndividualSpeaker speaker, String photo) {
  return IndividualSpeaker(
    id: speaker.id,
    firstName: speaker.firstName,
    lastName: speaker.lastName,
    workEmail: speaker.workEmail,
    personalEmail: speaker.personalEmail,
    workPhone: speaker.workPhone,
    personalPhone: speaker.personalPhone,
    company: speaker.company,
    role: speaker.role,
    bio: speaker.bio,
    photo: photo,
    linkedinProfile: speaker.linkedinProfile,
    website: speaker.website,
    allowedContactMethods: speaker.allowedContactMethods,
  );
}
