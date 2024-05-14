import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class Dx5veAnalytics{
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  logdx5veEvent({required String eventName})async{
    await analytics.logEvent(name: eventName).then((value) => (printInfo));
    
  }

  logEditingButtonClicked({required String editingButton})async{
    await analytics.logEvent(name: editingButton);
  }

  logEditingCancelled({required String cancelledAction})async{
    await analytics.logEvent(name: cancelledAction);
  }

}