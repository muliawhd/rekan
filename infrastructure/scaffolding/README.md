# Pending scaffold overlays

These are authored source templates, **not runnable Flutter or Laravel projects**. The architecture kit requires official generation using installed toolchains and stopping when tools are absent. Use [bootstrap](../../scripts/bootstrap.ps1) after installing the prerequisites in the [README](../../README.md).

`api` targets the Laravel 12 skeleton; `mobile` targets the Flutter stable generator with Dart 3. The bootstrap process applies these files after official generation. Application validation and formatter execution are pending. Once the real scaffolds exist, application changes belong in `services/api` and `apps/mobile`; these templates are a one-time setup mechanism, not a second maintained application.
