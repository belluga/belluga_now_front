import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/invite_flow_page_metadata.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildInviteFlowPageMetadata uses invite content for public share tags',
    () {
      final invite = buildInviteModelFromPrimitives(
        id: 'invite-1',
        eventId: 'event-1',
        eventSlug: 'evento-teste',
        eventName: 'Festival de Inverno',
        eventDateTime: DateTime.parse('2026-07-09T20:00:00Z'),
        eventImageUrl: 'https://tenant.example/assets/event.jpg',
        location: 'Praia do Morro',
        hostName: 'Guarapari',
        message: 'Chega cedo',
        tags: const <String>['show'],
        inviterName: 'Marina',
      );

      final payload = buildInviteFlowPageMetadata(
        invite: invite,
        currentUrl: Uri.parse('https://tenant.example/invite?code=abc123'),
        tenantName: 'Guarapari',
      );

      expect(payload.title, 'Festival de Inverno');
      expect(payload.description, contains('Marina'));
      expect(payload.description, contains('Festival de Inverno'));
      expect(payload.url, 'https://tenant.example/invite?code=abc123');
      expect(payload.imageUrl, 'https://tenant.example/assets/event.jpg');
    },
  );

  test(
    'buildInviteFlowPageDescription falls back to host and tenant naming',
    () {
      final invite = buildInviteModelFromPrimitives(
        id: 'invite-2',
        eventId: 'event-2',
        eventSlug: 'evento-sem-inviter',
        eventName: 'Feira Noturna',
        eventDateTime: DateTime.parse('2026-07-09T22:00:00Z'),
        eventImageUrl: 'https://tenant.example/assets/night.jpg',
        location: 'Centro',
        hostName: 'Anchieta',
        message: 'Vamos?',
        tags: const <String>['feira'],
      );

      final description = buildInviteFlowPageDescription(
        invite: invite,
        tenantName: 'Guarapari',
      );

      expect(description, 'Convite para Feira Noturna em Anchieta.');
    },
  );
}
