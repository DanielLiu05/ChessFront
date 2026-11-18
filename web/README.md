# Chessfront Web Build

The Web target is a single-threaded Godot 4.7 WebAssembly build served as static files. PC browsers use the desktop HUD/camera/mouse presentation; Android/iOS browsers use the Android-style portrait touch presentation.

For online multiplayer (local headless server, Cloudflare quick tunnel, GitHub Pages deployment and two-browser acceptance), see [ONLINE_RUNBOOK.md](ONLINE_RUNBOOK.md).

## Build

The `Web` preset is in `export_presets.cfg`. It exports to `builds/web/index.html`, includes map JSON and mode resources, and excludes `editor/` and `tests/`.

```bash
GODOT="/d/Program Files/Godot/godot.exe"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "Web" builds/web/index.html
```

Use `--export-debug` instead when a console-enabled development build is needed. `builds/` is git-ignored; only source and the export preset are committed.

## Run locally

Serve the directory over HTTP; do not open `index.html` with `file://`.

```bash
python3 -m http.server 8060 --directory builds/web
# open http://localhost:8060/index.html
```

The export produces `index.html`, `index.js`, `index.wasm`, `index.pck`, audio worklets and icons. The local server must return `application/wasm` for `.wasm` (Python 3.11 and current static hosts do).

### Testing on a phone

The Godot web runtime requires a secure context. `http://localhost` is treated as secure, but `http://<PC-LAN-IP>:8060` is not and fails with a "Secure Context" missing-feature error.

**USB, recommended:** keep the local server running on the PC, then forward the port to the phone:

```bash
/d/SDk/platform-tools/adb.exe devices
/d/SDk/platform-tools/adb.exe reverse tcp:8060 tcp:8060
```

Open `http://localhost:8060/index.html` in the phone browser. `adb reverse` is cleared when USB is disconnected; rerun it after reconnecting.

**Wi-Fi:** plain LAN HTTP is not sufficient. Serve the build through HTTPS (for example a static HTTPS host or an HTTPS tunnel) and open the HTTPS URL on the phone. A valid/trusted certificate is required; a self-signed certificate warning is not a reliable secure-context workaround.

## Static hosting

Copy the contents of `builds/web/` to any static host (GitHub Pages, Netlify, Cloudflare Pages, a plain nginx/Apache server, or an itch.io HTML5 upload). The repository includes `.github/workflows/pages.yml`, which exports the Web preset and deploys `builds/web` to GitHub Pages on `main`; see [ONLINE_RUNBOOK.md](ONLINE_RUNBOOK.md).

- **GitHub Pages:** use **Settings → Pages → Source: GitHub Actions**. The export uses relative `index.js`/`index.wasm`/`index.pck` paths and works under the repository subpath. The workflow writes `.nojekyll`; manual deployments must include it. Do not commit `builds/` to `main`.
- **No COOP/COEP headers are required** because thread support is off. If threads are enabled later, add `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
- **Compression:** the uncompressed wasm is about 39.5 MB (measured gzip 10.1 MB, Brotli 6.9 MB). Enable Brotli or gzip on the host; precompressed `index.wasm.br`/`.gz` variants are also suitable if the host serves the correct encoding.
- **MIME types:** `.wasm` → `application/wasm`; `.js` → `text/javascript`; `.pck` → `application/octet-stream`.
- **Caching:** `index.html`, `index.js`, `index.wasm` and `index.pck` use stable names. Disable caching for `index.html` or deploy each build under a versioned directory, and use a revalidation/long-cache policy for the other assets.
- The build has no server-side code, no PWA/service worker and no external runtime dependency.
- No hosting URL, domain or deployment credential is stored in this repository.

## Browser behavior

- **PC browser:** desktop HUD, mouse selection, desktop camera and full desktop presentation.
- **Mobile browser:** MobileHud, touch gestures, portrait layout, safe-area handling and the mobile quality profile.
- The first mobile interaction is a **Tap to play** gate that requests fullscreen and attempts a portrait orientation lock. If the browser rejects either request, the game continues.
- In landscape mobile web, a blocking **Rotate to portrait** overlay pauses input and AI until the device returns to portrait. PC browsers never show these overlays.
- Mobile browsers cap `devicePixelRatio` at 2.0 for Web render performance while keeping 44 CSS-pixel controls. Desktop DPR is unchanged.
- Safe-area insets come from CSS `env(safe-area-inset-*)` and are exposed to Godot through `window.chessfrontGetSafeInsets()`.
- A hidden tab pauses input/AI and resumes without replaying or consuming a turn.

## Acceptance check

The optional browser harness captures desktop, Android-emulated, iOS-emulated and narrow-PC screenshots and checks overlay/fullscreen behavior. It requires Playwright with the Edge channel:

```bash
cd web
npm install --no-save playwright
cd ..
python3 -m http.server 8060 --directory builds/web
node web/acceptance_test.js
```

Screenshots are written to `builds/web/acceptance/` and the script exits non-zero on console errors or failed overlay assertions. It uses Playwright device emulation, not a physical phone browser.

For game-over/rematch, touch gestures and full 200-ply play, use the native UI/mobile/AI tests plus a real phone browser. Real mobile-browser performance and thermal behavior are not claimed by emulation.

## Known boundaries

- Single-threaded only; no SharedArrayBuffer requirement.
- No PWA/offline mode.
- Compatibility renderer; visual parity with Forward+ is approximate.
- Online multiplayer rooms live in the headless server process only; there is no save/load, replay, takeback or server-restart recovery. A quick tunnel is testing-only; see [ONLINE_RUNBOOK.md](ONLINE_RUNBOOK.md).
