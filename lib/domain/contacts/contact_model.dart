import 'package:equatable/equatable.dart';

class ContactModel extends Equatable {
  const ContactModel({
    required this.id,
    required this.displayName,
    this.phones = const [],
    this.emails = const [],
    this.avatar,
  });

  final String id;
  final String displayName;
  final List<String> phones;
  final List<String> emails;
  final List<int>? avatar;

  @override
  List<Object?> get props => [id, displayName, phones, emails, avatar];
}
