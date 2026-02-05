import '../models/contact.dart';
import '../models/group.dart';
import 'local_storage_service.dart';

class ContactService {
  final LocalStorageService _localStorage;
  final String userId;

  ContactService({
    required LocalStorageService localStorage,
    required this.userId,
  }) : _localStorage = localStorage;

  // ============ CONTACTS ============

  /// Get all contacts for user
  Future<List<Contact>> getContacts() async {
    return await _localStorage.loadContacts(userId);
  }

  /// Get contact by ID
  Future<Contact?> getContactById(String contactId) async {
    final contacts = await getContacts();
    try {
      return contacts.firstWhere((c) => c.id == contactId);
    } catch (e) {
      return null;
    }
  }

  /// Get multiple contacts by IDs
  Future<List<Contact>> getContactsByIds(List<String> contactIds) async {
    final contacts = await getContacts();
    return contacts.where((c) => contactIds.contains(c.id)).toList();
  }

  /// Create a new contact
  Future<Contact> createContact({
    required String name,
    String? phone,
    String? email,
  }) async {
    final contact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      createdAt: DateTime.now(),
    );

    final contacts = await getContacts();
    contacts.add(contact);
    await _localStorage.saveContacts(userId, contacts);

    return contact;
  }

  /// Update existing contact
  Future<Contact> updateContact(Contact contact) async {
    final contacts = await getContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);

    if (index == -1) {
      throw Exception('Contact not found');
    }

    final updatedContact = contact.copyWith(updatedAt: DateTime.now());
    contacts[index] = updatedContact;
    await _localStorage.saveContacts(userId, contacts);

    return updatedContact;
  }

  /// Delete contact
  Future<void> deleteContact(String contactId) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.id == contactId);
    await _localStorage.saveContacts(userId, contacts);

    // Also remove from all groups
    final groups = await getGroups();
    bool groupsModified = false;

    for (var group in groups) {
      if (group.memberIds.contains(contactId)) {
        final updatedGroup = group.copyWith(
          memberIds: group.memberIds.where((id) => id != contactId).toList(),
          updatedAt: DateTime.now(),
        );
        final index = groups.indexWhere((g) => g.id == group.id);
        groups[index] = updatedGroup;
        groupsModified = true;
      }
    }

    if (groupsModified) {
      await _localStorage.saveGroups(userId, groups);
    }
  }

  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    if (query.trim().isEmpty) {
      return await getContacts();
    }

    final contacts = await getContacts();
    final lowerQuery = query.toLowerCase();

    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowerQuery) ||
          (contact.phone?.contains(query) ?? false) ||
          (contact.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Import contacts from phone (to be implemented with permission_handler & contacts_service)
  Future<List<Contact>> importPhoneContacts() async {
    // TODO: Implement phone contacts import
    // Requires: permission_handler, contacts_service packages
    // For now, return empty list
    throw UnimplementedError(
      'Phone contacts import requires additional packages. '
      'Add permission_handler and contacts_service to pubspec.yaml',
    );
  }

  /// Check if contact name already exists
  Future<bool> isContactNameExists(String name, {String? excludeId}) async {
    final contacts = await getContacts();
    return contacts.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() && c.id != excludeId);
  }

  // ============ GROUPS ============

  /// Get all groups for user
  Future<List<Group>> getGroups() async {
    return await _localStorage.loadGroups(userId);
  }

  /// Get group by ID
  Future<Group?> getGroupById(String groupId) async {
    final groups = await getGroups();
    try {
      return groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  /// Create a new group
  Future<Group> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
  }) async {
    // Validate that all members exist
    final contacts = await getContacts();
    final validMemberIds = memberIds
        .where((id) => contacts.any((c) => c.id == id))
        .toList();

    if (validMemberIds.isEmpty) {
      throw Exception('Group must have at least one valid member');
    }

    final group = Group(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name.trim(),
      memberIds: validMemberIds,
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    final groups = await getGroups();
    groups.add(group);
    await _localStorage.saveGroups(userId, groups);

    return group;
  }

  /// Update existing group
  Future<Group> updateGroup(Group group) async {
    final groups = await getGroups();
    final index = groups.indexWhere((g) => g.id == group.id);

    if (index == -1) {
      throw Exception('Group not found');
    }

    // Validate members still exist
    final contacts = await getContacts();
    final validMemberIds = group.memberIds
        .where((id) => contacts.any((c) => c.id == id))
        .toList();

    final updatedGroup = group.copyWith(
      memberIds: validMemberIds,
      updatedAt: DateTime.now(),
    );

    groups[index] = updatedGroup;
    await _localStorage.saveGroups(userId, groups);

    return updatedGroup;
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == groupId);
    await _localStorage.saveGroups(userId, groups);
  }

  /// Get group members (full Contact objects)
  Future<List<Contact>> getGroupMembers(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      return [];
    }

    return await getContactsByIds(group.memberIds);
  }

  /// Add member to group
  Future<Group> addMemberToGroup(String groupId, String contactId) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    if (group.memberIds.contains(contactId)) {
      return group; // Already a member
    }

    // Verify contact exists
    final contact = await getContactById(contactId);
    if (contact == null) {
      throw Exception('Contact not found');
    }

    final updatedGroup = group.copyWith(
      memberIds: [...group.memberIds, contactId],
      updatedAt: DateTime.now(),
    );

    return await updateGroup(updatedGroup);
  }

  /// Remove member from group
  Future<Group> removeMemberFromGroup(String groupId, String contactId) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    final updatedMemberIds =
        group.memberIds.where((id) => id != contactId).toList();

    if (updatedMemberIds.isEmpty) {
      throw Exception('Group must have at least one member');
    }

    final updatedGroup = group.copyWith(
      memberIds: updatedMemberIds,
      updatedAt: DateTime.now(),
    );

    return await updateGroup(updatedGroup);
  }

  /// Check if group name already exists
  Future<bool> isGroupNameExists(String name, {String? excludeId}) async {
    final groups = await getGroups();
    return groups.any(
        (g) => g.name.toLowerCase() == name.toLowerCase() && g.id != excludeId);
  }

  /// Get groups that contain a specific contact
  Future<List<Group>> getGroupsWithContact(String contactId) async {
    final groups = await getGroups();
    return groups.where((g) => g.memberIds.contains(contactId)).toList();
  }
}
