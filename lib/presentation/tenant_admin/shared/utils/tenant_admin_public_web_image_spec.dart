const tenantAdminPublicWebDefaultImageWidth = 1200;
const tenantAdminPublicWebDefaultImageHeight = 630;

// Keep the crop target derived from the canonical OG dimensions so a typo such
// as "1.19:1" cannot silently drift the picker away from the saved payload.
const tenantAdminPublicWebDefaultImageAspectRatio =
    tenantAdminPublicWebDefaultImageWidth /
        tenantAdminPublicWebDefaultImageHeight;
