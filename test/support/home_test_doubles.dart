import 'dart:async';

import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/database/vault_repository.dart';
import 'package:realmguard/features/home/data/credential_draft.dart';

/// Faux [CredentialEditor] : pilote le flux réactif à la main et enregistre les
/// écritures, pour vérifier ce que la vue / le ViewModel a réellement demandé.
class FakeCredentialEditor implements CredentialEditor {
  final StreamController<CredentialWithProfile?> controller =
      StreamController<CredentialWithProfile?>.broadcast();
  List<Profile> profilesToReturn = const [];

  int? updatedId;
  CredentialDraft? updatedDraft;
  int? deletedId;
  bool throwOnUpdate = false;

  @override
  Stream<CredentialWithProfile?> watchCredential(int id) => controller.stream;

  @override
  Future<List<Profile>> getAllProfiles() async => profilesToReturn;

  @override
  Future<bool> updateCredential(int id, CredentialDraft draft) async {
    if (throwOnUpdate) throw Exception('db');
    updatedId = id;
    updatedDraft = draft;
    return true;
  }

  @override
  Future<int> deleteCredential(int id) async {
    deletedId = id;
    return 1;
  }
}

/// Construit un enregistrement d'identifiant tel que le renvoie le dépôt.
CredentialWithProfile credentialWithProfile(
  int id,
  String title, {
  String notes = '',
  String? username,
  String? password,
  bool favorite = false,
  int? profileId,
  Profile? profile,
}) => CredentialWithProfile(
  Credential(
    id: id,
    title: title,
    username: username,
    password: password,
    notes: notes,
    customFields: '[]',
    favorite: favorite,
    profileId: profileId,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  profile,
);
