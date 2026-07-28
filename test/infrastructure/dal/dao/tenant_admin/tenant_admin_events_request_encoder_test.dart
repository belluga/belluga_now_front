import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_events_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'does not emit legacy flat related account payloads without canonical profile groups',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
          relatedAccountProfileIdValues: [
            TenantAdminAccountProfileIdValue('artist-1'),
            TenantAdminAccountProfileIdValue('artist-2'),
          ],
        ),
      );

      expect(payload.containsKey('artist_ids'), isFalse);
      expect(payload.containsKey('artists'), isFalse);
      expect(payload.containsKey('artistProfiles'), isFalse);
      expect(payload.containsKey('event_parties'), isFalse);
      expect(payload['profile_groups'], isEmpty);
    },
  );

  test(
    'encodes root profile_groups from the single canonical occurrence without event_parties',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
              relatedAccountProfileIdValues: [
                TenantAdminAccountProfileIdValue('ignored-occurrence-flat-id'),
              ],
              profileGroups: [
                TenantAdminNestedProfileGroup(
                  idValue: TenantAdminNestedProfileGroupTextValue('convidados'),
                  labelValue: TenantAdminNestedProfileGroupTextValue(
                    'Convidados',
                  ),
                  orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                  accountProfileIdValues: [
                    TenantAdminNestedProfileGroupTextValue('artist-2'),
                  ],
                ),
              ],
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
          relatedAccountProfileIdValues: [
            TenantAdminAccountProfileIdValue('ignored-flat-id'),
          ],
          profileGroups: [
            TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue('atracoes'),
              labelValue: TenantAdminNestedProfileGroupTextValue('Atrações'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              accountProfileIdValues: [
                TenantAdminNestedProfileGroupTextValue('artist-1'),
              ],
            ),
          ],
        ),
      );

      expect(payload['profile_groups'], [
        {
          'id': 'convidados',
          'label': 'Convidados',
          'order': 0,
          'account_profile_ids': ['artist-2'],
        },
      ]);
      expect(payload.containsKey('event_parties'), isFalse);

      final occurrence =
          (payload['occurrences'] as List<Object?>).first
              as Map<String, dynamic>;
      expect(occurrence['profile_groups'], [
        {
          'id': 'convidados',
          'label': 'Convidados',
          'order': 0,
          'account_profile_ids': ['artist-2'],
        },
      ]);
      expect(occurrence.containsKey('event_parties'), isFalse);
    },
  );

  test(
    'omits root profile_groups when many occurrences exist even if a stale root mirror is present',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
              profileGroups: [
                TenantAdminNestedProfileGroup(
                  idValue: TenantAdminNestedProfileGroupTextValue('artists'),
                  labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
                  orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                  accountProfileIdValues: [
                    TenantAdminNestedProfileGroupTextValue('artist-1'),
                  ],
                ),
              ],
            ),
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 6, 20)),
              profileGroups: [
                TenantAdminNestedProfileGroup(
                  idValue: TenantAdminNestedProfileGroupTextValue('sponsors'),
                  labelValue: TenantAdminNestedProfileGroupTextValue(
                    'Sponsors',
                  ),
                  orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                  accountProfileIdValues: [
                    TenantAdminNestedProfileGroupTextValue('sponsor-1'),
                  ],
                ),
              ],
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
          profileGroups: [
            TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue('stale-root'),
              labelValue: TenantAdminNestedProfileGroupTextValue('Stale Root'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              accountProfileIdValues: [
                TenantAdminNestedProfileGroupTextValue('stale-1'),
              ],
            ),
          ],
        ),
      );

      expect(payload['profile_groups'], isEmpty);
      final occurrences = payload['occurrences'] as List<Object?>;
      expect((occurrences.first as Map<String, dynamic>)['profile_groups'], [
        {
          'id': 'artists',
          'label': 'Artists',
          'order': 0,
          'account_profile_ids': ['artist-1'],
        },
      ]);
      expect((occurrences[1] as Map<String, dynamic>)['profile_groups'], [
        {
          'id': 'sponsors',
          'label': 'Sponsors',
          'order': 0,
          'account_profile_ids': ['sponsor-1'],
        },
      ]);
    },
  );

  test(
    'encodes empty canonical profile_groups payload when no related account profiles are selected',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
        ),
      );

      expect(payload.containsKey('profile_groups'), isTrue);
      expect(payload['profile_groups'], isEmpty);
    },
  );

  test(
    'encodes occurrence identity and explicit empty occurrence arrays for full-form clears',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              occurrenceIdValue: tenantAdminOptionalText(
                '507f1f77bcf86cd799439011',
              ),
              occurrenceSlugValue: tenantAdminOptionalText('evento-abc-0'),
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
        ),
      );

      final occurrence =
          (payload['occurrences'] as List<Object?>).first
              as Map<String, dynamic>;

      expect(occurrence['occurrence_id'], '507f1f77bcf86cd799439011');
      expect(occurrence['occurrence_slug'], 'evento-abc-0');
      expect(occurrence['profile_groups'], isEmpty);
      expect(occurrence['taxonomy_terms'], isEmpty);
      expect(occurrence['programming_items'], isEmpty);
    },
  );

  test('encodes occurrence-owned profiles and programação place refs', () {
    const encoder = TenantAdminEventsRequestEncoder();
    final payload = encoder.encodeDraft(
      TenantAdminEventDraft(
        titleValue: tenantAdminRequiredText('Evento'),
        contentValue: tenantAdminOptionalText('Conteudo'),
        type: TenantAdminEventType(
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        occurrences: [
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
            taxonomyTerms: _taxonomyTermsFromRaw({
              'sport': ['football'],
            }),
            relatedAccountProfileIdValues: [
              TenantAdminAccountProfileIdValue('artist-1'),
            ],
            profileGroups: [
              TenantAdminNestedProfileGroup(
                idValue: TenantAdminNestedProfileGroupTextValue('bandas'),
                labelValue: TenantAdminNestedProfileGroupTextValue('Bandas'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                accountProfileIdValues: [
                  TenantAdminNestedProfileGroupTextValue('artist-1'),
                ],
              ),
            ],
            programmingItems: [
              TenantAdminEventProgrammingItem(
                timeValue: tenantAdminOptionalText('17:00'),
                endTimeValue: tenantAdminOptionalText('18:30'),
                titleValue: tenantAdminOptionalText('Abertura'),
                accountProfileIdValues: [
                  TenantAdminAccountProfileIdValue('artist-1'),
                ],
                placeRef: TenantAdminEventPlaceRef(
                  typeValue: tenantAdminRequiredText('account_profile'),
                  idValue: tenantAdminRequiredText('venue-1'),
                ),
              ),
            ],
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
      ),
    );

    final occurrence =
        (payload['occurrences'] as List<Object?>).first as Map<String, dynamic>;

    expect(occurrence['profile_groups'], [
      {
        'id': 'bandas',
        'label': 'Bandas',
        'order': 0,
        'account_profile_ids': ['artist-1'],
      },
    ]);
    expect(occurrence.containsKey('event_parties'), isFalse);
    expect(occurrence['taxonomy_terms'], [
      {'type': 'sport', 'value': 'football'},
    ]);
    expect(occurrence.containsKey('location'), isFalse);
    expect(occurrence['programming_items'], [
      {
        'time': '17:00',
        'end_time': '18:30',
        'title': 'Abertura',
        'account_profile_ids': ['artist-1'],
        'place_ref': {'type': 'account_profile', 'id': 'venue-1'},
      },
    ]);
  });

  test(
    'encodes empty occurrence profile_groups when no canonical occurrence group is present',
    () {
      const encoder = TenantAdminEventsRequestEncoder();
      final payload = encoder.encodeDraft(
        TenantAdminEventDraft(
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 5, 20)),
              relatedAccountProfileIdValues: [
                TenantAdminAccountProfileIdValue('legacy-occurrence-profile'),
              ],
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
        ),
      );

      final occurrence =
          (payload['occurrences'] as List<Object?>).first
              as Map<String, dynamic>;

      expect(occurrence.containsKey('event_parties'), isFalse);
      expect(occurrence['profile_groups'], isEmpty);
    },
  );
}

TenantAdminTaxonomyTerms _taxonomyTermsFromRaw(
  Map<String, List<String>> termsByTaxonomy,
) {
  final taxonomyTerms = TenantAdminTaxonomyTerms();
  for (final entry in termsByTaxonomy.entries) {
    for (final value in entry.value) {
      taxonomyTerms.add(
        tenantAdminTaxonomyTermFromRaw(type: entry.key, value: value),
      );
    }
  }
  return taxonomyTerms;
}
