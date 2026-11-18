# Chessfront Online Runbook

Phase 9 adds human-vs-human play. The static Web client is served from GitHub Pages; the authoritative Godot server runs on this PC. For testing, a Cloudflare quick tunnel exposes the local server to the players. The client never receives a full `GameState`: it gets only its own fog-limited view, own gold and public match state.

## Topology

```text
Browser A (GitHub Pages) ── wss:// ─┐
                                    ├─ Cloudflare quick tunnel ── ws://127.0.0.1:9000 ── Godot headless server
Browser B (GitHub Pages) ── wss:// ─┘
```

The server is one process and owns all rooms. The GitHub Pages host cannot run the server. ENet is not available in Web exports; both sides use WebSocket JSON (`NetProtocol`, version 1).

## Start the server

From the repository root on this PC:

```bash
GODOT="/d/Program Files/Godot/godot.exe"
"$GODOT" --headless --path . --script res://scripts/net/server_main.gd -- --port 9000 --bind 127.0.0.1
```

Options:

- `--port <port>`: default `9000`.
- `--bind <address>`: default `127.0.0.1`. Keep localhost; the tunnel connects locally.
- Optional server-test knob: `--grace-seconds <seconds>` (used by acceptance tests; production default is 90).

The process prints `Chessfront online server listening on ws://127.0.0.1:<port>`. Keep it running for the whole session. Stop it with Ctrl+C. Rooms are in memory only; a server restart loses every room (save/load is excluded).

## Expose it with a Cloudflare quick tunnel

Install `cloudflared`, then run:

```bash
cloudflared tunnel --url http://127.0.0.1:9000
```

Copy the printed `https://<random>.trycloudflare.com` URL. In the game choose **Play Online**, paste that URL, and press Connect. The client normalizes `https://` to `wss://`; from an HTTPS page a `ws://` URL is rejected with a clear error.

Important:

- The tunnel URL changes every time `cloudflared` starts. Paste the current URL; do not reuse an old one.
- Quick tunnels are public and have no SLA. Anyone with the URL can reach the server (room codes/tokens still protect rooms). Use only for testing.
- Keep the PC awake, online and connected. Sleep, network loss or a tunnel restart ends the session.
- Do not expose other local services through the tunnel. The Godot server binds `127.0.0.1` and only the WebSocket port is forwarded.
- A permanent server/domain is not part of Phase 9 (U-20).

## Play flow

1. Both players open the same Pages URL (or local `http://localhost:8060/index.html`) and choose **Play Online**.
2. Enter the same tunnel/server URL and connect.
3. One player creates a room and shares the six-character code; the other joins it.
4. The room owner selects the map. The joiner sees the selection and waits.
5. The owner starts when both players are connected. The server randomly assigns Player 1/Player 2 and the first player; the assignment is shown to both clients.
6. Play. Draw offers are server-authoritative. After game over, **Another Match** returns both players to the lobby (the owner re-selects the map); **Leave Room** closes the room.

## Rooms, tokens and limits

- Six-character codes use an unambiguous alphabet. Treat codes as semi-public.
- Each player receives a private token. The Web client stores it in `sessionStorage` and resumes with it after a reload; intentional leave clears it. Do not paste tokens into chat or logs.
- Limits: 32 clients, 16 rooms, 64 KB messages and 40 messages/second per connection. The server also bounds action ids, room codes and payload fields.
- Reconnect covers client drops only: the server pauses a running match for 90 seconds, lets the same token resume, and closes the room with no winner if the window expires. It does not survive a server or tunnel restart.

## Version and build checks

- The protocol version is `1`. A mismatched client/server receives a clear error and cannot use a room.
- Ship the client and server from the same commit/build. Balance values (2 starting gold, 6-ply mine cycles, 200-ply limit) and map data must match.
- Map ids and format versions are validated by the server; a missing or differently versioned map is rejected at selection/start.

## GitHub Pages deployment

The workflow `.github/workflows/pages.yml` installs Godot 4.7.2 and its Web templates, exports the `Web` preset, writes `.nojekyll`, and deploys `builds/web` through GitHub Pages. In the repository settings set **Pages → Build and deployment → Source: GitHub Actions**. The workflow runs on pushes to `main` and can be started manually.

The client uses relative `index.js`, `index.wasm` and `index.pck` paths, so it works under `https://<user>.github.io/<repo>/`. Do not commit `builds/` to `main`; the workflow uploads it as an artifact.

Manual fallback if CI template provisioning is unavailable:

```bash
GODOT="/d/Program Files/Godot/godot.exe"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "Web" builds/web/index.html
touch builds/web/.nojekyll
npx gh-pages -d builds/web --dotfiles -m "Deploy Chessfront web client"
```

Then set Pages to serve the `gh-pages` branch. Keep `.nojekyll` in the deployed artifact. The host must serve `.wasm` as `application/wasm`; GitHub Pages does. Enable compression where available (the wasm is about 39.5 MB uncompressed).

## Two-browser acceptance

For a local end-to-end check, serve the Web build and start the server:

```bash
python3 -m http.server 8060 --directory builds/web
"/d/Program Files/Godot/godot.exe" --headless --path . --script res://scripts/net/server_main.gd -- --port 9000 --bind 127.0.0.1
```

Open two separate browser contexts at `http://localhost:8060/index.html`, connect both to `ws://127.0.0.1:9000`, create/join, select a map and start. Verify:

- Both HUDs show You/Opponent labels and own gold only (`Opponent ?`); enemy gold never appears.
- Hidden units/terrain/tokens are absent; logs only show actions the local player is entitled to see.
- Moves, promotion, recruitment, bridges, pass and draws round-trip through the server; invalid actions show a rejection.
- Game over offers **Another Match** and **Leave Room**; another match returns to the lobby and re-rolls sides/first.
- Reload one client and reconnect within 90 seconds: the match resumes with the current view. After expiry the room aborts with no winner.
- Desktop and mobile-emulated layouts have no console errors and controls remain inside the safe area. Screenshots should be inspected.

`web/online_acceptance_test.js` automates this with two browser contexts and the local server; see the script header for the required environment. Real-phone thermal/performance is not claimed by emulation (P7-05/U-22 remain open).

## Known boundaries

- No save/load, replay or takeback.
- No accounts, matchmaking, chat, spectators, rankings or public room browser.
- No native Android online client in this phase.
- No server restart recovery and no persistence across tunnel restarts.
- Quick tunnels are testing-only; a permanent host/domain remains U-20.
