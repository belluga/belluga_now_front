# belluga_gallery

Reusable Belluga gallery presentation for photos and canonical YouTube video
identities.

The package owns horizontal static previews, the selected-index viewer, one
active YouTube IFrame controller, lifecycle cleanup, and bounded playback
events through `EventTrackerRepositoryContract` resolved from `GetIt` at event
time.

The host application owns gallery groups, CRUD, backend capabilities, plan
limits, authoring errors, and navigation/dialog presentation.
