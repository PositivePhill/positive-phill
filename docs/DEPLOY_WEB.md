# 🌟 Positive Phill — Web Deployment Runbook

## 🧭 Overview
- 🏠 **Hosting:** GitHub Pages (legacy branch build, HTTPS enforced)
- 🌿 **Source branch:** `main`
- 📁 **Pages folder:** `/docs`
- 🚀 **Flutter app folder:** `/docs/app/`
- 🏡 **Landing page:** `/docs/index.html` **(DO NOT overwrite!)**
- 🔗 **Live app:** https://positivephill.github.io/positive-phill/app/
- 🧾 **Caching:** GitHub Pages serves every file with `Cache-Control: max-age=600`

Pages source was confirmed as `main:/docs` (build type `legacy`) on 2026-11-05 with
`gh api repos/PositivePhill/positive-phill/pages`. Re-check it before each release.

---

## 🎯 Current Release: v1.6.0+160

| Field | Value |
|---|---|
| `pubspec.yaml` version | `1.6.0+160` |
| Build name / build number | `1.6.0` / `160` |
| Settings label | `Version 1.6.0 (160)` |
| Pinned toolchain | Flutter 3.47.1 stable, Dart 3.13.1 |

Natural Voice Studio is a future feature and is **not** part of v1.6. Voice playback in
v1.6 is the existing TTS implementation only.

The Settings label is built in `lib/screens/settings_screen.dart` as
`Version ${info.version} (${info.buildNumber})` from `package_info_plus`. On web that
plugin reads `version` and `build_number` from the deployed `version.json`. If
`build_number` is missing, the label renders as `Version 1.6.0 ()`. The live v1.5
`version.json` has no `build_number`, so with the same formatter it renders
`Version 1.5.0 ()`.

---

## 🛡️ Repository and Branch Safety

### What GitHub actually enforces on `main`
Checked on 2026-11-05:

- **Classic branch protection is not configured.**
  `gh api repos/PositivePhill/positive-phill/branches/main/protection` returns
  `404 Branch not protected`.
- **An active repository ruleset, "Protect Main" (id `12521606`), targets the default
  branch.** The branches API therefore reports `main` as `protected: true`. The ruleset:
  - blocks branch deletion;
  - blocks non-fast-forward pushes (no force-push);
  - requires a pull request to change `main`;
  - requires **0** approving reviews, no code-owner review, no status checks;
  - has no bypass actors.

GitHub forces changes through a PR, but it does **not** require a reviewer approval or
passing CI. Review and validation are enforced by this process, not by GitHub. Re-check
with:

```powershell
gh api repos/PositivePhill/positive-phill/rules/branches/main
gh api repos/PositivePhill/positive-phill/branches/main/protection
```

Do not change rulesets, branch protection, or Pages settings as part of a release.

### Required before any merge to `main`
- ✅ Changes reviewed by the release owner (the PR diff, not just the summary).
- ✅ Clean Git state: `git status --porcelain=v1 -uall` prints nothing, no unexplained stash.
- ✅ Validation passed on the **exact commit being merged** (see below).
- ✅ Explicit release authorization from the release owner for this version.
- ✅ No force-push, no history rewrite, no destructive `git reset`.
- ✅ No unrelated changes in the PR.

### Release flow (two PRs, matching v1.4.x–v1.5.1 history)
1. **Source PR**: feature, fix, and release-prep commits are merged into `main`.
   Source PRs never touch `docs/app/`.
2. **Deploy PR**: a `deploy/<version>-web-app` branch cut from the merged `main` commit.
   It changes **only** `docs/app/` and contains the accepted release artifact.

Keep deploy/config commits separate from logic commits.

---

## 🧰 Toolchain and Dependency Validation

Pinned release toolchain:
- Flutter **3.47.1** stable
- Dart **3.13.1**
- `pubspec.lock` is committed and enforced; do not upgrade packages during a release.

```powershell
flutter --version
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
git status --porcelain=v1 -uall
```

Required: Flutter/Dart versions match the pins, `pub get` resolves without changing
`pubspec.lock`, the analyzer reports zero issues, all tests pass, and `git status` is clean
afterwards. Record the command output and the commit hash it ran on.

A passing result from an older report does not apply to a changed commit. Re-run
validation whenever the commit changes.

---

## ✅ Build Options

### 🟢 Build (Production – Safe Default, authoritative for v1.6.0)
> `--no-tree-shake-icons` prevents missing icons (🔥💭❤️) in release builds.

```powershell
flutter build web --release --no-pub --build-name=1.6.0 --build-number=160 --base-href "/positive-phill/app/" --no-tree-shake-icons
```

- Run it only after the release commit is merged and validated, from a clean tree, with
  the pinned SDK.
- `--build-name` / `--build-number` must match `pubspec.yaml`.
- Do **not** pass `--pwa-strategy`. It is deprecated and hidden in Flutter 3.47.1, and
  `--pwa-strategy=none` removes the build token. The bootstrap then refuses to start (see C2).
- Output lands in `build/web/`.

## 🟡 Build (Optimized – Optional)

Smaller build, but only use if icons are confirmed stable on GitHub Pages.
Not approved for v1.6.0.
```powershell
flutter build web --release --base-href "/positive-phill/app/"
```

---

## 🔎 Build Output Verification

Inspect the generated files. Do not assume their contents.

### `build/web/version.json`
Expected:

```json
{"app_name":"positive_phill","version":"1.6.0","build_number":"160","package_name":"positive_phill"}
```

```powershell
Get-Content build\web\version.json -Raw
```

Any mismatch (wrong version, missing `build_number`, wrong name) is a **HOLD**.

### `build/web/index.html` (C2 bootstrap)
- [ ] Exactly one `<base href="/positive-phill/app/">`; no `$FLUTTER_BASE_HREF` left.
- [ ] The bootstrap is **inline** in `index.html`; there is no
      `<script src="flutter_bootstrap.js">` tag.
- [ ] Exactly one `_flutter.loader.load(` call (one bootstrap initialization).
- [ ] No unresolved template placeholders: no `{{flutter_*}}` and no `$FLUTTER_BASE_HREF`.
      Do not search for bare `}}`, because minified `flutter.js` contains it legitimately.
- [ ] `var build = "<digits>"`: a numeric build token is present, not `null`.
- [ ] The rewritten entrypoint is `main.dart.js?pp=<same digits>`. The bootstrap appends the
      token at runtime to the `mainJsPath` from Flutter's build config.

```powershell
$html = Get-Content build\web\index.html -Raw
([regex]::Matches($html, '<base href="/positive-phill/app/">')).Count   # expect 1
([regex]::Matches($html, '_flutter\.loader\.load\(')).Count            # expect 1
([regex]::Matches($html, '\{\{\s*flutter_[a-z_]+\s*\}\}|\$FLUTTER_BASE_HREF')).Count   # expect 0
([regex]::Matches($html, 'src="flutter_bootstrap\.js"')).Count         # expect 0
[regex]::Match($html, 'var build = "([0-9]+)"').Groups[1].Value         # expect digits
```

### `build/web/flutter_service_worker.js`
Must be Flutter 3.47.1's **cleanup worker**. It is a small file that, on `activate`, calls
`self.registration.unregister()` and then `client.navigate(client.url)` for open windows.
It must have **no** `RESOURCES` map or `flutter-app-cache`. A caching worker here is a HOLD.

### Critical assets
`main.dart.js`, `flutter.js`, `manifest.json`, `favicon.png`, `icons/`,
`assets/AssetManifest.bin`, `assets/FontManifest.json`, `assets/fonts/MaterialIcons-Regular.otf`,
`assets/assets/affirmations/`, `assets/assets/audio/`, `assets/assets/videos/`,
`assets/assets/images/posters/`, `assets/assets/icons/icon.png` must all be present.
App assets from `pubspec.yaml` land under `assets/assets/`. During browser QA, the network panel must show no 404s for them.

---

## 🧩 C2 Bootstrap and Cache Integrity

Accepted implementation: commit `72c89da`
(`build(web): version main.dart.js per build and inline the bootstrap`), touching only
`web/flutter_bootstrap.js` and `web/index.html`.

**Problem it addresses.** With `max-age=600` on every file, a revalidated `index.html`
could pair with a cached `main.dart.js` from the previous release. During the legacy
service-worker cleanup reload, that ran old video code that deleted the saved background
preference.

**How it works.**
- `web/index.html` inlines `{{flutter_bootstrap_js}}`. The shell and its entrypoint URL
  always come from the same build.
- `web/flutter_bootstrap.js` takes Flutter's `{{flutter_service_worker_version}}` build
  token and appends it as `?pp=<token>` to every `mainJsPath` in Flutter's build config. It
  drops entries without a `mainJsPath`.
- If the token is missing or not numeric, or no entrypoint exists, it dispatches
  `pp-bootstrap-failed` and throws. It fails closed instead of loading an unversioned
  entrypoint, and the splash shows "couldn't finish loading" with a Reload button.
- The entrypoint path comes from Flutter's build configuration. Never hardcode the main
  script path in application source.
- Flutter's generated cleanup service worker is unchanged.

**Known limitations. Do not overstate C2.**
- The token is Flutter's **deprecated** service-worker version token. In 3.47.1 it is a
  random 32-bit integer generated per build (`Random().nextInt(1 << 32)`). It is **not** a
  content hash. It is not guaranteed unique, only very unlikely to repeat. Two builds of
  the same source normally get different tokens. Never compare tokens between separate
  builds.
- Only `main.dart.js` is versioned. Other assets still rely on normal HTTP caching.
- The token exists only for the default (`offline-first`) service-worker strategy.
  `flutter run` (including `flutter run -d chrome`) uses no service-worker strategy, so the
  token is `null` there. Per the 3.47.1 tool source, the C2 bootstrap then fails closed with
  `missing build token`. Do browser verification on a served `flutter build web` output,
  not on `flutter run`.
- Any Flutter SDK upgrade requires re-validating bootstrap compatibility. Check the token
  format, the `_flutter.buildConfig.builds[].mainJsPath` shape, the placeholder
  substitution, and the cleanup worker before releasing on a new SDK.

---

## 🧹 Legacy Service-Worker Upgrade

Two historical caching service workers may be registered in users' browsers:

1. **App scope `/positive-phill/app/`**: the deployed v1.5 worker
   (`docs/app/flutter_service_worker.js`, a caching worker with a `RESOURCES` map).
   v1.6 replaces this file with the cleanup worker. On its next update check, the browser
   installs the cleanup worker, which unregisters itself and reloads open app tabs.
2. **Root scope `/positive-phill/`**: an older worker from the historical root-level
   Flutter build (`docs/flutter_service_worker.js`, v1.0.0 era). v1.6 does **not** change
   this file. It remains a separate release-validation concern: the rehearsal must show
   the app at `/positive-phill/app/` starts and behaves correctly when this worker is
   registered.

### Upgrade rehearsal (where applicable, both scopes)
Run against a served copy of the accepted artifact, starting from browser profiles that
have the v1.5 app-scope worker, the root-scope worker, and both.

Required evidence:
- [ ] Correct worker cleanup: the app-scope registration is gone after the reload.
- [ ] No infinite reload loop. Watch for repeated navigations for at least a few minutes,
      including while a stale `index.html` can still come from HTTP cache (up to 600 s).
- [ ] No mixed old/new JavaScript shell: `main.dart.js?pp=<token>` matches the
      `index.html` token, and `version.json` reports 1.6.0 / 160.
- [ ] No unexpected preference deletion.
- [ ] Saved backgrounds preserved through a controlled upgrade.
- [ ] No missing critical resources (no 404s).

### Known historical limitation
Legacy v1.5 code that is **already running** in a tab can delete a selected video
preference before the updated code executes. v1.6 cannot reconstruct a choice whose only
stored copy has already been deleted. C2 reduces the old/new mixing window. It does
**not** remove this possibility entirely.

Do not replace Flutter's cleanup worker or add custom service-worker code to work around
this.

---

## 🧱 GitHub Pages Deployment Boundary

The deployment surface is **`docs/app/` only**.

Never modify during an app release:
- `docs/index.html` (marketing landing page)
- `docs/privacy.html`, `docs/support.html`, `docs/terms.html`
- Other root-level website files in `docs/`
- Unrelated studio files (for example `docs/AGENT_HANDOFF.md`, this runbook in a deploy PR)
- Historical root-level Flutter assets in `docs/` (`docs/main.dart.js`, `docs/flutter.js`,
  `docs/flutter_bootstrap.js`, `docs/flutter_service_worker.js`, `docs/version.json`,
  `docs/assets/`, `docs/canvaskit/`, `docs/icons/`, `docs/manifest.json`,
  `docs/favicon.png`, `docs/.last_build_id`)

A deploy PR diff must list only paths under `docs/app/`:

```powershell
git diff --name-only main...HEAD | Where-Object { $_ -notlike 'docs/app/*' }   # expect no output
```

---

## 📦 Reproducible Release Artifact (single-artifact policy)

After all feature and release-prep changes are accepted and merged:

1. **Build once** with the approved SDK and the authoritative command above.
2. **Verify** the entire output (Build Output Verification + release QA).
3. **Record a manifest** of every file: relative path, size in bytes, SHA-256.
4. **Record an aggregate fingerprint**: the SHA-256 of the manifest file, written
   deterministically (ordinal path sort, `/` separators, LF line endings, UTF-8 without BOM).
5. **Package** the verified build.
6. **Record the archive SHA-256**.
7. **Retain** the manifest, fingerprint, and archive as release evidence outside the repo.
8. **Deploy those same accepted bytes.** Stage `docs/app/` from the archive and confirm the
   staged manifest fingerprint equals the accepted one.

Never rebuild after artifact acceptance. A rebuild is a new artifact: it gets a new
token and must be fully re-verified.

> ⚠️ **Line endings.** The release workstation has `core.autocrlf=true` and the repo has
> no `.gitattributes`. Working-tree copies of `docs/app/*.html` / `*.js` are CRLF, while
> Git and GitHub Pages hold LF. A default `git archive` also emits CRLF. For byte-exact
> evidence, always pass `-c core.autocrlf=false` to `git add` / `git archive` for
> `docs/app/`, and verify **committed** bytes, never working-tree copies.

```powershell
function Write-ReleaseManifest {
  param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Out)
  $root = (Resolve-Path -LiteralPath $Dir).Path.TrimEnd('\')
  $rows = foreach ($f in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
    [pscustomobject]@{
      Path = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
      Size = $f.Length
      Sha  = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
  }
  $list = [System.Collections.Generic.List[object]]::new([object[]]$rows)
  $list.Sort([Comparison[object]]{ param($a, $b) [string]::CompareOrdinal($a.Path, $b.Path) })
  $text = (($list | ForEach-Object { "$($_.Sha)  $($_.Size)  $($_.Path)" }) -join "`n") + "`n"
  [System.IO.File]::WriteAllText($Out, $text, [System.Text.UTF8Encoding]::new($false))
  (Get-FileHash -LiteralPath $Out -Algorithm SHA256).Hash.ToLowerInvariant()
}

$evidence = "$env:USERPROFILE\pp-release-evidence\v1.6.0+160"
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
Write-ReleaseManifest -Dir build\web -Out "$evidence\build-manifest.txt"   # aggregate fingerprint
tar.exe -C build\web -cf "$evidence\positive_phill-web-1.6.0+160.tar" .
(Get-FileHash "$evidence\positive_phill-web-1.6.0+160.tar" -Algorithm SHA256).Hash.ToLowerInvariant()
```

Keep evidence outside the repository so it never gets committed.

---

## 🚢 Deploy Steps (PowerShell) — future release step

Requires explicit release authorization, the merged and validated source commit, and an
accepted artifact. Not part of source or release-prep PRs.

1) Preserve rollback evidence (see Rollback) **before** touching `docs/app/`.

2) Cut the deploy branch from the merged `main` commit
   ```powershell
   git checkout main
   git pull --ff-only
   git checkout -b deploy/v1.6-web-app
   ```

3) Stage the accepted artifact into `docs/app/` (do NOT touch anything else)
   - Extract the accepted archive to a temporary folder and confirm its manifest
     fingerprint equals the accepted fingerprint.
   - Delete only the files listed in the **old** `docs/app/` manifest that are absent from
     the new artifact manifest. Never run an unscoped recursive delete.
   - Copy the extracted artifact into `docs/app/`.
   - Re-run `Write-ReleaseManifest -Dir docs\app ...`. The fingerprint must equal the
     accepted artifact fingerprint.

4) Commit the exact bytes and verify what was committed
   ```powershell
   git -c core.autocrlf=false add docs/app
   git diff --cached --name-only | Where-Object { $_ -notlike 'docs/app/*' }   # expect no output
   git commit -m "deploy: update v1.6 web app"
   $chk = Join-Path $env:TEMP "pp-committed-docs-app"
   New-Item -ItemType Directory -Force -Path $chk | Out-Null
   git -c core.autocrlf=false archive -o "$chk.tar" HEAD docs/app
   tar.exe -C $chk -xf "$chk.tar"
   Write-ReleaseManifest -Dir "$chk\docs\app" -Out "$evidence\committed-manifest.txt"   # must equal accepted fingerprint
   ```
   Use a fresh, empty `$chk` folder for each check.

5) Ship via PR (the ruleset requires a PR; reviewer approval is a process requirement)
   ```powershell
   git push -u origin deploy/v1.6-web-app
   ```

➡️ Open the PR, review the diff (only `docs/app/`), get explicit authorization, then merge ✅

---

## ⏪ Rollback (exact-artifact restore)

### Preserve before deploying
- The previous production Git commit: `git rev-parse origin/main` before the deploy PR.
- The previous deployed `docs/app/` contents, as committed (LF) bytes:
  `git -c core.autocrlf=false archive -o "$evidence\previous-docs-app.tar" <previous-commit> docs/app`.
- A complete old-file manifest with SHA-256 per file, plus its aggregate fingerprint
  (run `Write-ReleaseManifest` on the extracted previous `docs/app`).

### Restore
Rollback is a release action. It needs review and explicit authorization like a deploy.

1. Branch from current `main` (for example `deploy/rollback-v1.6-web-app`).
2. Preferred: `git revert -m 1 <deploy-merge-commit>`. The deploy PR only touched
   `docs/app/`, so the revert must only touch `docs/app/`. Check that.
3. If the revert conflicts or does not reproduce the old file set, restore manually.
   Restore each old file from the preserved archive, and delete only release-owned files
   that are present in the new manifest and absent from the old manifest. Stage with
   `git -c core.autocrlf=false add docs/app`.
4. Verify: the fingerprint of the **committed** `docs/app/` (byte-exact
   `git -c core.autocrlf=false archive`, as in deploy step 4) equals the preserved old
   fingerprint, and no path outside `docs/app/` changed.
5. PR, review, authorization, merge. Never force-push, never `git reset --hard` a shared
   branch, never delete `docs/app/` wholesale.

### Caching caveats
- Merging a revert does **not** invalidate clients' HTTP caches. Files can be served stale
  for up to `max-age=600`, and the Pages rebuild itself takes a few minutes.
- Clients may keep a stale v1.6 shell until reload or cache expiry. Mixed-version risk
  exists in both directions during this window.
- Rolling back to v1.5 restores v1.5's **caching** service worker and its known
  preference-handling behavior. Users who load v1.5 again will re-register that worker.
  Treat rollback as an emergency action, not a free undo.

---

## 🛑 Production Stop Conditions (HOLD or roll back)

- Blank or permanently stalled startup (splash never clears).
- Bootstrap or entrypoint failure (`pp-bootstrap-failed`, `missing build token`, failed
  `main.dart.js` request).
- Unexpected mixed-version JavaScript (token or `version.json` mismatch).
- Repeated service-worker reloads.
- 404s for critical assets.
- New user-preference loss (backgrounds, Reduce Motion, theme, favorites).
- Broken navigation.
- Significant accessibility regression.
- Incorrect release version (Settings label, `version.json`).
- Unexpected modification of unrelated site files.

---

## 🧪 Required Release QA

Mark each item **PASS**, **FAIL**, **NOT RUN**, or **BLOCKED**, with device, OS, and
browser version. Unsupported devices are NOT RUN or BLOCKED. Simulated browser settings
(DevTools emulation, emulated `prefers-reduced-motion`) are recorded as simulated. They
are not real-device results.

- [ ] Fresh install (clean profile) → default background is Rain Window.
- [ ] Returning user (v1.5 profile) → saved preferences preserved.
- [ ] Explicit **None** background stays None after reload.
- [ ] Poster-to-video transition on Home.
- [ ] Video error → poster fallback.
- [ ] System Reduce Motion honored.
- [ ] In-app Reduce Motion honored.
- [ ] No video requests in the network panel while Reduce Motion is in effect.
- [ ] Large-text accessibility: Home cards and Settings without overflow.
- [ ] Settings opens and behaves normally; label reads `Version 1.6.0 (160)`; navigation works.
- [ ] Voice playback with the existing TTS implementation.
- [ ] PNG sharing / export.
- [ ] Android Chrome (real device).
- [ ] iOS Safari, including Low Power Mode (real device).
- [ ] Legacy-worker upgrade: app scope and root scope (see above).
- [ ] Browser console: no uncaught errors. Network: no failed critical requests.

---

## 🔍 Post-Deploy Verification

- 🔄 Hard refresh (Ctrl + F5)

- 🧾 `https://positivephill.github.io/positive-phill/app/version.json` reports `1.6.0` / `160`

- 🔥💭❤️ Icons render (no mystery squares)

- 💡 Backlight toggle persists after refresh

- ⚙️ Settings opens & behaves normally (label `Version 1.6.0 (160)`)

- 🧪 Quick sanity: tap heart/share/sound once each

- 🏡 Landing, privacy, support, and terms pages unchanged

---
## 🧯 If Anything Looks Wrong

- 🧹 Try Ctrl+F5 again

- 🕵️ Local diagnosis only: DevTools → Application → Service Workers → check both
  `/positive-phill/app/` and `/positive-phill/` scopes → Unregister → refresh.
  Users can't be asked to do this, so it does not count as a fix.

- 🧊 Wait up to ~10 min (`max-age=600` plus Pages rebuild and SW update lag)

- 🛑 If a stop condition is met, HOLD and follow Rollback
