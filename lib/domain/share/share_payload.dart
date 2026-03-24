typedef SharePayloadPrimString = String;
typedef SharePayloadPrimInt = int;
typedef SharePayloadPrimBool = bool;
typedef SharePayloadPrimDouble = double;
typedef SharePayloadPrimDateTime = DateTime;
typedef SharePayloadPrimDynamic = dynamic;

class SharePayload {
  const SharePayload({
    required this.message,
    required this.subject,
  });

  final SharePayloadPrimString message;
  final SharePayloadPrimString subject;
}
