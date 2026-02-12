import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class Dx5veAnalytics{
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> logdx5veEvent({required String eventName}) async {
    try {
      await analytics.logEvent(name: eventName);
      print("Event '$eventName' logged successfully");
    } catch (e) {
      print("Error logging event: $e");
    }
  }

  logEditingButtonClicked({required String editingButton})async{
    await analytics.logEvent(name: editingButton);
  }

  logEditingCancelled({required String cancelledAction})async{
    await analytics.logEvent(name: cancelledAction);
  }

}