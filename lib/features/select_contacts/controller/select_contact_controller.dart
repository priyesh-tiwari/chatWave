import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../repository/select_contacts_repository.dart';



final getContactsProvider=FutureProvider((ref) {
  final selectContactRepository=ref.watch(selectContactRepositoryProvider);
  return selectContactRepository.getContacts();
});

final selectContactControllerProvider=Provider((ref){
  final selectContactRepository=ref.watch(selectContactRepositoryProvider);
  return SelectContactController(ref: ref, selectContactRepository: selectContactRepository);
});

class SelectContactController{
  final ProviderRef ref;
  final SelectContactsRepository selectContactRepository;

  SelectContactController({
    required this.ref ,
    required this.selectContactRepository
  });

  void selectContact(Contact selectedContact , BuildContext context){
    selectContactRepository.selectContact(selectedContact, context);
  }


}