import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:switchcalls/utils/permissions.dart';
import 'package:switchcalls/models/contact.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:switchcalls/constants/strings.dart';

class ContactsProvider extends ChangeNotifier {
  static ContactsProvider provider;
  StreamController<Iterable<MyContact>> _contactsCont;
  StreamSubscription<Iterable<MyContact>> _contactSub;
  List<MyContact> _contacts = [];
  SharedPreferences _prefs;

  static Future<ContactsProvider> getInstance() async {
    if (provider == null) {
      ContactsProvider placeholder = ContactsProvider();
      await placeholder.init();
      provider = placeholder;
    }
    return provider;
  }

  Future<void> init([bool topause = false]) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _contactsCont = StreamController<Iterable<MyContact>>.broadcast();
      if (await Permissions.contactPermissionsGranted()) {
        _contactSub = contacts().listen((event) {
          _contacts = event.toList();
          // print(contactList);
          _contactsCont.add(event);
          if (topause) pause();
        });
        print('CONTACTS STARTED');
      }
      _contactsCont.add(null);
    } catch (e) {
      print(e.toString());
    }
  }

  void pause() {
    if (_contactSub != null) {
      _contactSub.pause();
      // _contactSub.cancel();
      print('CONTACTS PAUSED');
    }
  }

  void resume() {
    if (_contactSub != null) {
      _contactSub.resume();
      print('CONTACTS RESUMED');
    } else {
      init();
    }
  }

  void close() {
    _contactsCont.close();
    _contactSub.cancel();
    print('CONTACTS CLOSED');
  }

  Stream<Iterable<MyContact>> contacts() async* {
    while (true) {
      await Future.delayed(Duration(milliseconds: 500));
      Iterable<MyContact> cts = (await ContactsService.getContacts()).map(
        (e) => MyContact(
          name: e.displayName,
          localPic: e.avatar,
          numbers: e.phones.map((e) => e.value).toList(),
        ),
      );
      await _prefs.setStringList(
          LOCAL_CONTACTS, cts.map((e) => jsonEncode(e.toMap())).toList());
      yield cts;
    }
  }

  StreamController<Iterable<MyContact>> get controller => _contactsCont;
  List<MyContact> get contactList {
    _contacts = _prefs != null?_prefs
        .getStringList(LOCAL_CONTACTS)
        .map((e) => MyContact.fromMap(jsonDecode(e)))
        .toList(): _contacts;
    _contacts.sort((a, b) => (a?.name ?? '').compareTo(b?.name ?? ''));
    _contacts.removeWhere((e) => e.name.isEmpty && e.trimNums.isEmpty);
    return _contacts;
  }
}
