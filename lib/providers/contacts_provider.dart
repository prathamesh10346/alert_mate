import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class ContactsProvider with ChangeNotifier {
  List<Contact> _contacts = [];
  
  List<Contact> get contacts => [..._contacts];

  List<String> get circles => _contacts
      .map((contact) => contact.circleType)
      .toSet()
      .toList();

  List<Contact> getContactsByCircle(String circleType) {
    return _contacts.where((contact) => contact.circleType == circleType).toList();
  }

  int getContactCountByCircle(String circleType) {
    return _contacts.where((contact) => contact.circleType == circleType).length;
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> decoded = json.decode(contactsJson);
      _contacts = decoded.map((item) => Contact.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> saveContact(Contact contact) async {
    _contacts.add(contact);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((contact) => contact.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = json.encode(_contacts.map((e) => e.toJson()).toList());
    await prefs.setString('contacts', contactsJson);
  }
}