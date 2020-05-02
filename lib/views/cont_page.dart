// views/contact_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validators/validators.dart' as validator;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';

class ContactPage extends StatefulWidget {
  ContactPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ContactPageState createState() => new _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  Contact newContact = new Contact();

  var data;
  bool autoValidate = true;
  bool readOnly = false;
  bool isChanged = false;
  bool showSegmentedControl = true;
  bool okay;

  bool nameInvalid = false;
  bool mailInvalid = false;
  String errorMessage;
  FocusNode nameFocus = FocusNode();
  FocusNode mailFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text("Form Validation"),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              FormBuilder(
                key: _fbKey,
                readOnly: readOnly,
                autovalidate: autoValidate,
                initialValue: {
                  'date': DateTime.now(),
                  'accept_terms': false,
                },
                onChanged: (val) => isChanged = true,
                onWillPop: () => _exitApp(context),

                child: Column(
                  children: <Widget>[
                    FormBuilderTextField(
                      attribute: 'name',
                      autofocus: true,
                      validators: [FormBuilderValidators.required()],
                      focusNode: nameFocus,
                      maxLines: 1,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        errorText: nameInvalid ? errorMessage : null,
                      ),
                      onSaved: (name) {
                        setState(() {
                          newContact.name = name;
                        });
                      },
                    ),
                    FormBuilderTextField(
                      attribute: 'email',
                      enabled: true,
                      //validators: [ validateEmail ],
                      focusNode: mailFocus,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "E-Mail",
                        errorText: mailInvalid ? errorMessage : null,),
                      onSaved: (mail) {
                        setState(() {
                          newContact.email = mail;
                        });
                      },
                    ),
                    FormBuilderDateTimePicker(
                      attribute: "date",
                      inputType: InputType.date,
                      validators: [FormBuilderValidators.required()],
                      //format: DateFormat("dd-MM-yyyy"),
                      format: DateFormat("dd.MM.yyyy"),
                      decoration: InputDecoration(labelText: "Date of Birth"),
                      onSaved: (dob) {
                        setState(() {
                          newContact.dob = dob;
                        });
                      },
                    ),
                    FormBuilderDropdown(
                      attribute: "gender",
                      decoration: InputDecoration(labelText: "Gender"),
                      // initialValue: 'Male',
                      hint: Text('Select Gender'),
                      validators: [FormBuilderValidators.required()],
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                              value: gender, child: Text("$gender")))
                          .toList(),
                    ),
                    FormBuilderTextField(
                      attribute: "age",
                      decoration: InputDecoration(labelText: "Age"),
                      keyboardType: TextInputType.number,
                      validators: [
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.max(70),
                      ],
                    ),
                    FormBuilderSlider(
                      attribute: "slider",
                      validators: [FormBuilderValidators.min(6)],
                      min: 0.0,
                      max: 10.0,
                      initialValue: 1.0,
                      divisions: 20,
                      decoration: InputDecoration(
                          labelText: "Number of Family Members"),
                    ),
                    FormBuilderSegmentedControl(
                      decoration: InputDecoration(labelText: "Rating"),
                      attribute: "movie_rating",
                      options: List.generate(5, (i) => i + 1)
                          .map(
                              (number) => FormBuilderFieldOption(value: number))
                          .toList(),
                    ),
                    FormBuilderStepper(
                      decoration: InputDecoration(labelText: "Stepper"),
                      attribute: "stepper",
                      initialValue: 10,
                      step: 1,
                    ),
                    FormBuilderCheckboxList(
                      decoration:
                          InputDecoration(labelText: "Languages you know"),
                      attribute: "languages",
                      initialValue: ["English"],
                      options: [
                        FormBuilderFieldOption(value: "English"),
                        FormBuilderFieldOption(value: "German"),
                        FormBuilderFieldOption(value: "Other")
                      ],
                    ),
                    FormBuilderSignaturePad(
                      decoration: InputDecoration(labelText: "Signature"),
                      attribute: "signature",
                      height: 100,
                    ),
                    FormBuilderRate(
                      decoration: InputDecoration(labelText: "Rate this site"),
                      attribute: "rate",
                      iconSize: 32.0,
                      initialValue: 1,
                      max: 5,
                    ),
                    FormBuilderCheckbox(
                      attribute: 'accept_terms',
                      label: Text(
                          "I have read and agree to the terms and conditions"),
                      validators: [
                        FormBuilderValidators.requiredTrue(
                          errorText:
                              "You must accept terms and conditions to continue",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text("Submit"),
                    onPressed: () {
                      _fbKey.currentState.save();
                      if (_fbKey.currentState.validate()) {
                        //print(_fbKey.currentState.value);
                        _submitForm(_fbKey);
                      } else {
                        showMessage('Form is not valid!  Please review and correct.');
                      }
                    },
                  ),
                  MaterialButton(
                    child: Text("Reset"),
                    onPressed: () {
                      _fbKey.currentState.reset();
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Enter Valid Email';
    else
      return null;
  }

  void _submitForm(_fbKey) {
    nameInvalid = false;
    mailInvalid = false;
    errorMessage = null;

    // final checks
    if (newContact.email.isEmpty) {
      mailInvalid = true;
      errorMessage = 'Bitte EMail-Adresse eingeben';
      FocusScope.of(context).requestFocus(mailFocus);
      showMessage(errorMessage, Colors.deepOrange);
      return;
    } else {
      errorMessage = validateEmail(newContact.email);
      if( errorMessage != null) {
        mailInvalid = true;
        FocusScope.of(context).requestFocus(mailFocus);
        showMessage(errorMessage, Colors.deepOrange);
        return;
      }
    }
    if (newContact.name != "peter") {
      nameInvalid = true;
      errorMessage = 'Falscher Name!';
      FocusScope.of(context).requestFocus(nameFocus);
      showMessage('Das ist der falsche Name: ${newContact.name}!', Colors.red);
      return;
    }

    print('Form save called, newContact is now up to date...');
    print('Name: ${newContact.name}');
    print('Dob: ${newContact.dob}');
    print('Phone: ${newContact.phone}');
    print('Email: ${newContact.email}');
    print('Favorite Color: ${newContact.favoriteColor}');
    print('========================================');
    print('Submitting to back end...');

    var contactService = new ContactService();
    contactService.createContact(newContact).then((value) =>
        showMessage('New contact created for ${value.name}!', Colors.lightGreen));
  }

  void showMessage(String message, [MaterialColor color = Colors.red]) {
    _scaffoldKey.currentState.showSnackBar(
        new SnackBar(backgroundColor: color, content: new Text(message)));
  }

  Future<bool> _exitApp(BuildContext context) {
    if (isChanged) {
      return showDialog(
        context: context,
        child: new AlertDialog(
          title: new Text('Do you want to exit this application?'),
          content: new Text('You have changed data!'),
          actions: <Widget>[
            new FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: new Text('No'),
            ),
            new FlatButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: new Text('Yes'),
            ),
          ],
        ),
      ) ??
      false;
    } else {
      Navigator.of(context).pop(true);
    }
  }

}
