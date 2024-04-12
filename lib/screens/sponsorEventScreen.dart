import 'package:dx5veevents/constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../helpers/helper_functions.dart';

class SponsorEventScreen extends StatefulWidget {
  const SponsorEventScreen({super.key});

  @override
  State<SponsorEventScreen> createState() => _SponsorEventScreenState();
}

class _SponsorEventScreenState extends State<SponsorEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController workEmailController = TextEditingController();
  TextEditingController reasonController = TextEditingController();
  bool isEmail(String input) => EmailValidator.validate(input);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Sponsorship Form"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              verticalSpace(height: 5),
              const Text("We organise events that attract top professionals in various industries. When you become a sponsor of an"
                "event you get the following in return: an opportunity to increase your brand visibility, network with awesome"
                "individuals and increase your client base.",textAlign: TextAlign.center,style: TextStyle(fontSize: 13),),verticalSpace(height: 15),
              TextFormField(
                controller: workEmailController,
                decoration: const InputDecoration(labelText: "Work Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  } else if (!isEmail(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),

              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                controller: companyController,
                decoration: const InputDecoration(labelText: "Company"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'The company you represent is required';
                  }
                  return null;
                },
              ),
              verticalSpace(height: 10),
              TextFormField(
                controller: roleController,
                decoration: const InputDecoration(labelText: "Role"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Your role is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),              verticalSpace(height: 10),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: reasonController, maxLines: null,
                decoration: const InputDecoration(labelText: "Reason of interest",      contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),),

              ),

              verticalSpace(height: 10),
              primaryButton2(context: context, onPressedFunction: ()async{
                submitSponsorProposal(firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  workEmail: workEmailController.text, workPhone: phoneController.text,
                  company: companyController.text,
                  role: roleController.text, reason_of_interest: reasonController.text, eventID: '4',);
              }, buttonText: "SUBMIT", backgroundColor: kPrimaryColor),              verticalSpace(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}
