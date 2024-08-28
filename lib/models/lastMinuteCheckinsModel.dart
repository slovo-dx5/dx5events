class ConferenceRoom {
  final List<RoomData> data;

  ConferenceRoom({required this.data});

  factory ConferenceRoom.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<RoomData> dataList = list.map((i) => RoomData.fromJson(i)).toList();
    return ConferenceRoom(data: dataList);
  }
}

class RoomData {
  final int id;
  final String roomName;
  final String attendeeData;

  RoomData({required this.id, required this.roomName, required this.attendeeData});

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      id: json['id'],
      roomName: json['room_name'],
      attendeeData: json['attendee_data'],
    );
  }


  // Extracts the numerical ID from the attendeeData string.
  int get attendeeId {
    var parts = attendeeData.split(':');
    return int.tryParse(parts.first) ?? 0; // Returns 0 if parsing fails
  }

  //Get event regid
  int get eventRegId {
    var parts = attendeeData.split(':');
    return int.tryParse(parts.last) ?? 0; // Returns 0 if parsing fails
  }
}
