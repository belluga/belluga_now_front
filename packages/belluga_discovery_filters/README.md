# Belluga Discovery Filters

Canonical Flutter primitives for tenant-authored discovery filters.

This package owns the reusable filter vocabulary shared by Map, Home Events,
and Profile Discovery surfaces:

- typed filter definitions with entity/type/taxonomy targets;
- surface policies for primary and taxonomy selection modes;
- persisted public selection state;
- deterministic repair for stale tenant configuration or obsolete saved filters.

The package intentionally does not own surrounding search docks, lists, maps, or
result rendering. Host surfaces compose those concerns around the canonical
filter widget and state contracts.
