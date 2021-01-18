import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:switchcalls/provider/contacts_provider.dart';
import 'package:switchcalls/utils/permissions.dart';
import 'package:switchcalls/widgets/quiet_box.dart';

class ContactListScreen extends StatefulWidget {
  ContactListScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  Map<String, Color> contactsColorMap = new Map();
  TextEditingController searchController = new TextEditingController();
  ContactsProvider _contactsProvider;

  @override
  void initState() {
    _contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
    _contactsProvider.resume();

    super.initState();
    getPermissions();
  }

  @override
  void dispose() {
    _contactsProvider.pause();
    super.dispose();
  }

  void getPermissions() async {
    if (await Permissions.contactPermissionsGranted()) {
      getAllContacts();
      searchController.addListener(() {
        filterContacts();
      });
    }
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  void getAllContacts() async {
    List colors = [Colors.green, Colors.indigo, Colors.yellow, Colors.orange];
    int colorIndex = 0;
    List<Contact> _contacts = _contactsProvider.contactList;
    //(await ContactsService.getContacts()).toList();
    print('\n\n\n HERE \n\n');
    _contacts.forEach((contact) {
      Color baseColor = colors[colorIndex];
      contactsColorMap[contact.displayName] = baseColor;
      colorIndex++;
      if (colorIndex == colors.length) {
        colorIndex = 0;
      }
    });
    if (mounted) {
      setState(() {
        contacts = _contacts;
      });
    }
  }

  void filterContacts() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlatten = flattenPhoneNumber(searchTerm);
        String contactName = contact.displayName.toLowerCase();
        bool nameMatches = contactName.contains(searchTerm);
        if (nameMatches == true) {
          return true;
        }

        if (searchTermFlatten.isEmpty) {
          return false;
        }

        var phone = contact.phones.firstWhere((phn) {
          String phnFlattened = flattenPhoneNumber(phn.value);
          return phnFlattened.contains(searchTermFlatten);
        }, orElse: () => null);

        return phone != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: StreamBuilder<Iterable<Contact>>(
          stream: _contactsProvider.controller.stream,
          builder: (BuildContext context, snapshot) {
            if (contacts.isNotEmpty) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Container(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                            labelText: 'Search',
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(
                                    color: Theme.of(context).primaryColor)),
                            prefixIcon: Icon(Icons.search,
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: isSearching == true
                            ? contactsFiltered.length
                            : contacts.length,
                        itemBuilder: (context, index) {
                          Contact contact = isSearching == true
                              ? contactsFiltered[index]
                              : contacts[index];

                          var baseColor =
                              contactsColorMap[contact.displayName] as dynamic;

                          Color color1 = baseColor[800];
                          Color color2 = baseColor[400];
                          return ListTile(
                            title: Text(contact.displayName),
                            subtitle: Text(contact.phones.length > 0
                                ? contact.phones.elementAt(0).value
                                : ''),
                            leading: (contact.avatar != null &&
                                    contact.avatar.length > 0)
                                ? CircleAvatar(
                                    backgroundImage:
                                        MemoryImage(contact.avatar),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                            colors: [
                                              color1,
                                              color2,
                                            ],
                                            begin: Alignment.bottomLeft,
                                            end: Alignment.topRight)),
                                    child: CircleAvatar(
                                      child: Text(contact.initials(),
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                contacts.isEmpty)
              return Center(child: CircularProgressIndicator());

            return QuietBox();
          },
        ),
      ),
    );
  }
}
