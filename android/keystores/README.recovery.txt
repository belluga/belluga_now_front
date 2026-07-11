Android flavor signing recovery template

This directory is gitignored. The real signing files were local-only.

Approved Android flavor contract:

- committed public file: `android/flavors/<flavor>.public.properties`
- ignored secret file: `android/keystores/<flavor>.signing.properties`
- fixed ignored keystore path: `android/keystores/<flavor>.jks`
- supported CI fallback: `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`

The public file owns:

- applicationId
- appLinkHosts

The secret signing file owns:

- keyAlias
- keyPassword
- storePassword

Recovery flow:

1. Recreate `android/flavors/<flavor>.public.properties` with the real `applicationId` and `appLinkHosts`.
2. Start from `android/keystores/tenant.signing.properties.example` to rebuild the secret signing file.
3. Save the secret file as `android/keystores/<flavor>.signing.properties` with the real alias and passwords.
4. Restore the real keystore as `android/keystores/<flavor>.jks`.
5. Do not add `storeFile` back into the secret properties; the keystore path is fixed by contract.
6. Expect the build to fail closed if the public file is missing, if `applicationId` or `appLinkHosts` is missing from that public file, or if neither the local signing pair nor the Codemagic signing environment is available.

Important:

- Keep public flavor identity in `android/flavors/`, not in `android/keystores/`.
- Keep only signing secrets in `*.signing.properties`.
- Keep the keystore file name equal to the flavor name: `<flavor>.jks`.
- When Codemagic Android code signing is enabled, it may provide the release keystore and secrets through `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, and `CM_KEY_PASSWORD` instead of a local `<flavor>.signing.properties` file.
- Use the generic example/template names `android/flavors/tenant.public.properties.example` and `android/keystores/tenant.signing.properties.example`; only the real committed or local runtime files should carry the concrete flavor name.
