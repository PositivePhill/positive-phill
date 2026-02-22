# 🌟 Positive Phill — Web Deployment Runbook

## 🧭 Overview
- 🏠 **Hosting:** GitHub Pages
- 🌿 **Source branch:** `main`
- 📁 **Pages folder:** `/docs`
- 🚀 **Flutter app folder:** `/docs/app/`
- 🏡 **Landing page:** `/docs/index.html` **(DO NOT overwrite!)**
- 🔗 **Live app:** https://positivephill.github.io/positive-phill/app/

---

## ✅ Build Options

### 🟢 Build (Production – Safe Default)
> Use this by default to prevent missing icons (🔥💭❤️) in release builds.

```powershell
flutter build web --release --base-href "/positive-phill/app/" --no-tree-shake-icons
```

## 🟡 Build (Optimized – Optional)

Smaller build, but only use if icons are confirmed stable on GitHub Pages.
```powershell
flutter build web --release --base-href "/positive-phill/app/"
```
---
## 🧪 Preflight Checklist

- 🧠 On main

- 🔄 git pull is clean (no surprises)

- 🌐 App runs locally: flutter run -d chrome

- 🧼 No accidental edits to docs/index.html

---

## 🚢 Deploy Steps (PowerShell)
1) Build (release)
   flutter build web --release --base-href "/positive-phill/app/" --no-tree-shake-icons

2) Stage into /docs/app/ (do NOT touch landing page)
   if (!(Test-Path "docs\app")) { New-Item -ItemType Directory -Force -Path "docs\app" }
   Remove-Item -Recurse -Force "docs\app\*" -ErrorAction SilentlyContinue
   Copy-Item -Recurse -Force ".\build\web\*" ".\docs\app\"

3) Ship via PR (main is protected 🛡️)
   git checkout main
   git pull
   git checkout -b chore/deploy-web-app
   git add docs/app
   git commit -m "Deploy: update web app in docs/app"
   git push -u origin chore/deploy-web-app


➡️ Then open the PR on GitHub and Merge ✅

---
## 🔍 Post-Deploy Verification

- 🔄 Hard refresh (Ctrl + F5)

- 🔥💭❤️ Icons render (no mystery squares)

- 💡 Backlight toggle persists after refresh

- ⚙️ Settings opens & behaves normally

- 🧪 Quick sanity: tap heart/share/sound once each

---
## 🧯 If Anything Looks Wrong

- 🧹 Try Ctrl+F5 again

- 🕵️ If still broken: open DevTools → Application → Service Workers → Unregister → refresh

- 🧊 Worst case: wait 2–5 min (GitHub Pages cache + SW update lag)


