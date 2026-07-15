# belluga_contact_channels

Canonical Belluga contact-channel primitives and runtime deeplink resolution for
bounded public/admin contact flows.

The package has a closed `BellugaContactChannelDefinition` registry. Persisted
channels are data-only; labels, icons, normalization, metadata and launch
behaviour are derived from their definition. `BellugaContactChannelDraft` is
client-only authoring state: new channels carry a request-local `draftKey` and
never invent a persisted id. `BellugaContactBubbleSelectionMutation` encodes
the exact `omit | clear | persisted-id | draft-key` PATCH contract.

`fixtures/contact_channels.v1.json` is intentionally byte-identical to the
cross-stack canonical corpus in Foundation Documentation.
