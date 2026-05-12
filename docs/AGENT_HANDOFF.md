## Build Safety Rules
- Flutter Web must compile cleanly before and after every patch.
- Do not introduce `dart:io` into web paths.
- Avoid `Image.file` or file-system-only APIs unless protected by conditional imports.
- Keep feature changes isolated from visual polish patches.
- Every new feature must preserve existing XP, streak, theme, and StorageService behavior.