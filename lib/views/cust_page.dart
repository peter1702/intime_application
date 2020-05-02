//https://pub.dev/packages/preferences
import 'package:flutter/material.dart';
import '../helpers/translations.dart';
import 'package:preferences/preferences.dart';
//import 'package:validators/validators.dart';
import '../globals.dart' as globals;
import '../helpers/helpers.dart';


class Customizing extends StatefulWidget {
  static String tag = 'setting-page';
  @override
  _CustomizingState createState() => new _CustomizingState();
}

bool isNotAdmin = false;

class _CustomizingState extends State<Customizing> {

  Future<Null> getPrefs() async {
    if (PrefService != null) {
      await PrefService.init(prefix: globals.prefPrefix);
    }
  }

  @override
  void initState() {
    super.initState();
    getPrefs();
    if( globals.loginName.toString() != 'admin') {
      isNotAdmin = true;
    }
  }

  @override
  Widget build(BuildContext context) {

    return new WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: globals.primaryColor,
          title: Text(AppLocalizations.of(context).translate('setting_title')),
          leading: new IconButton(
              icon: new Icon(Icons.arrow_back_ios),
              onPressed: () {
                _exitApp(context);
              }),
        ),
        
        body:
        
          PreferencePage([
            PreferenceTitle(
              H.getText(context, 'dev_settings'),
                style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)
              ),
            PreferencePageLink(
              H.getText(context, 'dev_settings'),
              trailing: Icon(Icons.keyboard_arrow_right),
              page: PreferencePage([
                PreferenceTitle(
                  H.getText(context, 'dev_settings'), 
                  //style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)
                  ),
                TextFieldPreference(
                  H.getText(context, 'device_id'),
                  'device_id',
                  /*
                  style: TextStyle(color: globals.primaryColor),
                  labelStyle: TextStyle(color: globals.primaryColor),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: globals.primaryColor)),
                  ),
                  */
                ),
                TextFieldPreference(
                  H.getText(context, 'printer'),
                  'printer',
                ),
                /*
                SwitchPreference(
                  'Demo-Modus',
                  'demo_modus',
                  //switchActiveColor: globals.primaryColor,
                  //defaultVal: false,
                ),
                */
              ]),
            ),
            PreferenceTitle(
              H.getText(context, 'user_settings'),
              style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)),
            DropdownPreference(
              H.getText(context, 'language'),
              'user_language',
              defaultVal: 'DE',
              values: ['DE', 'EN'],
            ),
            DropdownPreference(
              H.getText(context, 'deci_format'),
              'user_dec_sep',
              defaultVal: '123.456,789',
              values: ['123,456.789', '123.456,789'],
            ),
            DropdownPreference(
              H.getText(context, 'date_format'),
              'user_format_date',
              defaultVal: 'TT.MM.JJJJ',
              values: ['TT.MM.JJJJ', 'MM/DD/YYYY'],
            ),
            PreferenceTitle('SAP', 
              style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)),
            PreferencePageLink(
              'SAP Connection',
              leading: Icon(Icons.message),
              trailing: Icon(Icons.keyboard_arrow_right),
              page: PreferencePage([
                PreferenceTitle('SAP System',
                  style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)),
                TextFieldPreference(
                  'Host (URL)',
                  'sap_host',
                ),
                TextFieldPreference(
                  'Port',
                  'sap_port',
                ),
                TextFieldPreference(
                  'Service',
                  'sap_service',
                ),
                TextFieldPreference(
                  H.getText(context, 'client'),
                  'sap_mandant',
                ),
              ]),
            ),
            PreferencePageLink(
              H.getText(context, 'auth'),
              leading: Icon(Icons.message),
              trailing: Icon(Icons.keyboard_arrow_right),
              page: PreferencePage([
                PreferenceTitle(
                  H.getText(context, 'auth'),
                  style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)),
                SwitchPreference(
                  H.getText(context, 'sap_anonym'),
                  'sap_anonym',
                  disabled: isNotAdmin,
                ),
                TextFieldPreference(
                  'SAP User',
                  'sap_user',
                  disabled: isNotAdmin,
                ),
                TextFieldPreference(
                  'SAP Password',
                  'sap_password',
                  disabled: isNotAdmin,
                  obscureText: true,
                ),
                SwitchPreference(
                  H.getText(context, 'login_with_sap'),
                  'login_with_sap',
                  defaultVal: false,
                ),
                SwitchPreference(
                  H.getText(context, 'login_with_sec'),
                  'login_with_sec',
                  defaultVal: false,
                ),
                SwitchPreference(
                  H.getText(context, 'login_with_loc'),
                  'login_with_loc',
                  defaultVal: false,
                ),
                TextFieldPreference(
                  H.getText(context, 'local_user'),
                  'local_user1',
                  disabled: isNotAdmin,
                ),
                TextFieldPreference(
                  H.getText(context, 'local_user'),
                  'local_user2',
                  disabled: isNotAdmin,
                ),
              ]),
            ),                
            PreferencePageLink(
              H.getText(context, 'appl_param'),
              leading: Icon(Icons.message),
              trailing: Icon(Icons.keyboard_arrow_right),
              page: PreferencePage([
                PreferenceTitle(
                  H.getText(context, 'appl_param'),
                  style: TextStyle(color: globals.primaryColor, fontWeight: FontWeight.bold)),
                TextFieldPreference(
                  H.getText(context, 'plant'),
                  'sap_plant',
                ),
                TextFieldPreference(
                  H.getText(context, 'warehouseNumber'),
                  'sap_lgnum',
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _exitApp(BuildContext context) {
    Helpers.loadGlobals();
    Navigator.pop(context, true);
  }
}
