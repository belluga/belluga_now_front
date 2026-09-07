# belluga_gallery

Reusable Belluga gallery presentation for photos and canonical YouTube video
identities.

The package owns horizontal static previews, the selected-index viewer, one
active YouTube IFrame controller, lifecycle cleanup, and bounded playback
events through `EventTrackerRepositoryContract` resolved from `GetIt` at event
time. `GalleryItem` carries optional title and description metadata; the viewer
renders the available metadata below the selected media and reserves no empty
metadata area for legacy or untitled items.

The host application owns gallery groups, CRUD, backend capabilities, plan
limits, authoring errors, and navigation/dialog presentation.
