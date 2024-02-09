import 'package:flutter/cupertino.dart';

import 'constants.dart';

class ProfileProvider with ChangeNotifier {
  String firstName="";
  String lastName="";
  String email="";
  String phone="";
  String company="";
  String role="";
  String isAdmin="false";
  String ?profileId;
  int ?userID;

  ProfileProvider(){
    loadUserProfile();
  }


  loadUserProfile()async{
    firstName=await getStringPref(kFirstName);
    lastName=await getStringPref(kLastName);
    email=await getStringPref(kEmail);
    phone=await getStringPref(kPhone);
    company=await getStringPref(kCompany);
    role=await getStringPref(kRole);
    userID=await getIntPref(kUserID);
    profileId=await getStringPref(kProfileID);
    isAdmin=await getStringPref(kIsAdmin);
    notifyListeners();
  }

  editCompany({required String newcompany})async{
    await setStringPref(key: kCompany, value: newcompany);
    company=newcompany;
    notifyListeners();
  }
  editRole({required String newRole})async{
    await setStringPref(key: kRole, value: newRole);
    role=newRole;
    notifyListeners();
  }
  editProfile({required String newProfileId})async{
    await setStringPref(key: kProfileID, value: newProfileId);
    profileId=newProfileId;
    notifyListeners();
  }
}