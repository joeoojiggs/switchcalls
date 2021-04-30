import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:switchcalls/models/user.dart';
import 'package:switchcalls/provider/contacts_provider.dart';

class ContactsScreenProvider extends ChangeNotifier {
  Map<String, Color> contactsColorMap = new Map();

  List<User> filterIdentifiedCL(
      List<User> identified, List<Contact> contacts, String query) {
    Iterable<String> nwe =
        contacts.map((e) => e.phones.first.value.substring(1));

    identified.retainWhere(
        (element) => nwe.contains(element.phoneNumber.substring(4)));

    identified
        .where((element) => element.username.toLowerCase().contains(query));
    return identified;
  }

  List<Contact> getAllContacts(List<Contact> contactList) {
    List colors = [Colors.green, Colors.indigo, Colors.yellow, Colors.orange];
    int colorIndex = 0;
    List<Contact> _contacts = contactList;
    //(await ContactsService.getContacts()).toList();
    print('\n\n\n HERE \n\n');
    _contacts.forEach((contact) {
      // print(colorIndex);
      Color baseColor = colors[colorIndex];
      // print(baseColor);
      contactsColorMap[contact.displayName] = baseColor;
      colorIndex++;
      if (colorIndex == colors.length) {
        colorIndex = 0;
      }
    });
    return _contacts;
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }
}
