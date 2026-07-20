# Releasing

1. Confirm SDK pin, MariaDB baseline, compatibility matrix, and protected live
   integration results.
2. Update package version documentation and create a reviewed v-prefixed
   semantic-version tag.
3. Push the tag. CI rebuilds the external SDK release, checks out the clean
   pinned MariaDB tag, builds and validates the relocatable plugin, and creates
   a MariaDB-version-specific archive and checksum.
4. The release job publishes those exact CI artifacts. Preview tags containing
   `-` are marked as prereleases.

The plugin archive deliberately excludes MariaDB, the SDK, Arrow, and OpenSSL.
Its manifest records exact compatibility and SONAME requirements.
