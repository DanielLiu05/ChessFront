# Game Design & Technical Blueprint

- Working title: Chessfront
- Engine: Godot 4
- Language: GDScript
- Target platforms: Windows, Linux, Android, iOS (web export optional)
- Genre: Turn-based tactical strategy / chess-inspired battlefield game
- Game modes: Single-player versus AI first; online multiplayer later. No shared-screen (hotseat) play.
- Tooling: Standalone Map Editor (separate tool entry point, excluded from game builds)

## 1. Project Vision

Create a casual, relatively fast-paced, turn-based strategy game inspired by chess.

The game takes place on a large, irregular, point-symmetric battlefield. Players command familiar chess pieces, supplemented by two special units: Scouts and Engineers.

Battlefields are handcrafted maps authored in the standalone Map Editor. They contain forests, hills, water and gold mines. Players must explore the map, manage their visibility, capture resources, recruit additional units and manoeuvre around terrain.

The game retains the deterministic movement and tactical positioning of chess but removes conventional check and checkmate rules. The objective is to capture the opponent's King.

Core design principles:

- Preserve the recognizable movement patterns and identities of traditional chess pieces.
- Make terrain, positioning and information important strategic resources.
- Keep the economy slow and recruitment meaningful.
- Avoid random combat outcomes, dice rolls, hit points and unnecessary complexity.
- Make every action deterministic and understandable. The game contains no randomness.
- Make games relatively short and accessible, ideally around 15–25 minutes.
- Prioritize replayability through a varied library of authored maps.

This is not intended to be a conventional chess engine with additional visual effects. It is a new strategy game using chess-inspired units and mechanics.

## 2. Board and Geometry

### 2.1 Board shape

The board should be a two-dimensional grid displayed in a three-dimensional environment.

The board must be point-symmetric (180-degree rotational symmetry) around its centre.

The initial board should be an irregular rectangle that widens towards the middle and narrows towards both ends.

Recommended initial dimensions:

- Maximum width: 16 tiles.
- Length: 16 rows.
- Width of the rows, from one end to the other:

```text
8, 10, 12, 14, 16, 16, 16, 16, 16, 16, 16, 16, 14, 12, 10, 8
```

This creates a battlefield with narrow starting areas and a wide central region.

Represent the board using a coordinate system with a maximum 16×16 bounding box. Not every coordinate corresponds to a playable tile.

Each tile should have:

- Grid coordinates.
- Terrain type.
- Elevation.
- Optional bridge state.
- Optional occupying piece.
- Exploration state for each player.
- Current visibility state for each player.
- Optional ground resource (uncollected gold).

Do not assume every coordinate within the bounding rectangle is playable.

### 2.2 Symmetry and fairness

Every map must preserve point symmetry.

For every terrain tile, its rotationally corresponding tile must have equivalent terrain properties.

Starting positions, starting resources and initial recruitment areas must also be symmetric.

Maps must not contain terrain that:

- Completely blocks access to the central battlefield.
- Traps a player inside their starting area.
- Prevents both players from reaching at least two shared gold mines with ordinary units (Section 5.5).
- Creates an unavoidable positional advantage.
- Places impassable terrain on initial deployment squares.

### 2.3 Starting armies and map-defined deployment

Each player starts with the conventional 16-piece chess army:

- 1 King
- 1 Queen
- 2 Rooks
- 2 Bishops
- 2 Knights
- 8 Pawns

Initial piece positions are defined by the map, not by a fixed formation. Different maps may define different starting layouts. Each map file specifies one starting tile per starting piece, for both players.

Starting layout rules:

- The two players' layouts must be point-symmetric.
- Every starting tile must be playable, passable, and not unbridged water.
- All of a player's starting tiles must lie within that player's home half of the board.
- No two pieces may share a tile.
- No starting piece may be capturable by an enemy piece on the first turn.

The conventional back-rank arrangement (Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook, with eight Pawns in the row in front) is the default template in the Map Editor, not a requirement.

Home deployment areas for recruitment remain the first two rows of each player's end, independent of the starting layout.

## 3. Units and Movement

There are eight unit types:

- King
- Queen
- Rook
- Bishop
- Knight
- Pawn
- Scout
- Engineer

The original six chess pieces retain their familiar movement patterns, with movement constrained by terrain, board geometry and the unit's permitted movement range.

Scouts and Engineers introduce additional tactical capabilities.

### 3.1 General movement rules

- Players alternate turns.
- Each turn allows exactly one primary action.
- Moving a piece consumes one turn.
- Recruiting a piece consumes one turn.
- Building or destroying a bridge consumes one turn.
- A player may not move an enemy piece.
- Pieces cannot move outside playable board coordinates.
- Occupied squares block movement, except for captures by eligible units.
- Ordinary pieces cannot enter water unless a bridge makes it passable.
- No unit may move through another unit, except the Knight, which jumps.
- Adjacent means any of the eight surrounding tiles (Chebyshev distance 1).
- A movement action must be validated by the rules engine before changing game state. Player-facing move options under fog of war follow Section 3.6.

### 3.2 Traditional chess pieces

#### King

- Moves one tile in any of the eight directions.
- Can be captured by the opponent.
- The game ends immediately when the King is captured.
- The King is not purchasable.

#### Queen

- Moves horizontally, vertically or diagonally.
- Uses ray-based movement.
- Movement distance is limited by explored territory (Section 3.3).
- Cannot be recruited.

#### Rook

- Moves horizontally or vertically.
- Uses ray-based movement.
- Movement distance is limited by explored territory (Section 3.3).

#### Bishop

- Moves diagonally.
- Uses ray-based movement.
- Movement distance is limited by explored territory (Section 3.3).

#### Knight

- Retains the conventional chess L-shaped movement: two tiles in one direction and one perpendicular.
- Can jump over intervening pieces and terrain.
- Destination must be a valid playable tile and must not be unbridged water.

#### Pawn

- Moves one or two tiles forward. This is available on every move, not only the first.
- A two-tile move is a step, not a jump: the intermediate tile must be playable, passable and unoccupied.
- Captures diagonally forward by one tile.
- Cannot move backwards.
- Promotes upon reaching the opponent's final playable row.
- Promotion options: Queen, Rook, Bishop or Knight.
- Pawn vision range is two tiles.
- Forward moves are subject to ambush (Section 3.7). Diagonal captures are not.
- Because the board is irregular, pawn forward direction must be defined relative to its player rather than inferred from the board's changing width.
- For the initial implementation, omit castling and en passant. These rules can be considered later if they prove useful.

### 3.3 Movement range for sliding pieces

Queens, Rooks and Bishops move along their permitted directions with no fixed distance limit.

A sliding unit may only travel through tiles that are explored by its owner.

Every tile within a unit's effective vision is explored, so a sliding unit can always move at least as far as it can see.

At the frontier of its player's explored territory, a sliding unit's reach therefore equals its effective vision. For example:

- A Rook on ordinary ground at the frontier can move at most two tiles along an unobstructed ray.
- A Rook on a hill at the frontier can move at most three tiles.

Behind the frontier, along previously explored ground, the ray is unlimited.

A Queen follows the same principle along all eight directions.

A Bishop follows the same principle along four diagonal directions.

Exploration is permanent and independent per player, so a player's sliding reach grows as they scout.

The movement ray stops at:

- The board boundary.
- The first unexplored tile.
- An impassable tile.
- An occupied tile.

A friendly piece blocks the ray. An enemy piece can be captured if the moving unit is eligible to capture it.

These stopping rules describe authoritative execution. Player-facing highlights are computed from the acting player's knowledge; see Section 3.6.

### 3.4 Scout

The Scout is a reconnaissance unit.

Movement:

- A Scout moves in a straight line in one of the eight directions (horizontal, vertical, or diagonal) by up to three tiles.
- A Scout may move up to five tiles in a straight line if every tile along the path, including the destination, is explored by its owner.
- A multi-tile move is a step, not a jump: every intermediate tile must be playable, passable, and unoccupied.
- The destination must be a playable tile and must not contain a friendly unit.
- Scouts cannot capture enemy units. A move whose destination contains a detected enemy unit is illegal.
- Scouts are subject to ambush when entering a concealed enemy position (Section 3.7).
- Scouts can be captured by enemy units.

Water rules:

- A water tile with a bridge counts as ordinary ground for all Scout movement rules.
- A Scout may enter unbridged water only as the destination of a one-tile move.
- A Scout standing in unbridged water may move only one tile per action. Extended explored-territory reach is unavailable while in unbridged water.
- A multi-tile move may not start in, pass through, or end in unbridged water. In particular, a land → water → land move is not allowed.
- A Scout may leave water with a one-tile move to any adjacent playable tile, including another water tile.
- A Scout loses one tile of effective vision while standing in unbridged water.

Scouts have the largest base vision of any unit and are particularly valuable for discovering enemy positions and terrain.

### 3.5 Engineer

The Engineer is an infrastructure unit.

Movement:

- May move up to two tiles in a straight line in any of the eight directions.
- May move up to four tiles in a straight line if every tile along the path, including the destination, is explored by its owner.
- A multi-tile move is a step, not a jump: every intermediate tile must be playable, passable, and unoccupied.
- Cannot capture enemy units.
- Is subject to ambush when entering a concealed enemy position (Section 3.7).
- Can be captured by enemy units.
- Cannot enter ordinary water tiles.

Special ability: bridge construction and destruction.

Building:

- Must be adjacent to an eligible water tile.
- Can build a bridge on that water tile.
- Building consumes the Engineer's entire turn.
- The target tile must not contain another piece.
- Bridges are permanent until destroyed.

Destroying:

- Must be adjacent to an existing bridge.
- Consumes the Engineer's entire turn.
- Cannot destroy a bridge currently occupied by a unit.

Bridges convert their associated water tile into a passable tile for ordinary units.

An Engineer cannot build or destroy multiple bridges in one turn.

### 3.6 Movement under fog of war

The rules engine holds the authoritative state, but the acting player only knows their own visible and explored information. Player-facing move options and actual move execution are therefore separated.

#### Knowledge evaluation timing

- The acting player's knowledge, including forest detection, is evaluated once, at the moment the action is committed. It determines only which destinations are offered.
- Execution is authoritative and resolves tile by tile against the real board state. Knowledge and detection are not recomputed while the unit is moving.
- A unit does not detect a concealed enemy mid-move simply because its path passes closer to that enemy.

#### Highlight computation (player knowledge)

- Legal destination highlights are computed from the acting player's knowledge, never from the authoritative hidden state.
- Concealed enemy units are treated as absent.
- Unexplored tiles are treated as passable ordinary ground.
- Explored tiles use their known terrain.
- Friendly units are always known and block highlights normally.
- Extended explored-territory reach is computed from the acting player's own exploration map.
- A highlighted destination is a move attempt, not a guarantee.

#### Turn cost of an attempt

- Every committed movement action consumes the turn, including an action that stops short of the selected destination or produces no movement at all.
- There is no free retry. A failed attempt still costs the turn, so hidden terrain and hidden units cannot be probed at no cost.

#### Move execution (authoritative state)

Ray-based moves (Queen, Rook, Bishop) resolve tile by tile along the chosen direction, up to the chosen distance:

- The unit stops before an unexplored tile, an impassable tile or a friendly unit.
- The unit captures the first enemy unit on its path and stops on that tile, even if a farther destination was selected.
- Otherwise the unit reaches the selected destination.

Path-based step moves (Pawn, Scout, Engineer) resolve tile by tile along the chosen direction, up to the chosen distance:

- The unit stops before the first tile that is impassable, contains a friendly unit, or contains an enemy unit that does not trigger ambush.
- The unit is destroyed by ambush if it enters a tile holding a concealed enemy capture-capable unit (Section 3.7).
- A Pawn's forward move may not end on any occupied tile. Its diagonal capture requires a detected enemy unit on the target tile.
- Otherwise the unit reaches the selected destination.
- A partial move is a completed action. Visibility, gold collection and promotion are resolved from the tile the unit actually ends on.

Jump move (Knight):

- The Knight resolves its destination only; intervening tiles are irrelevant.
- The Knight captures a concealed enemy on its destination normally.
- If the destination is not playable, is unbridged water, or contains a friendly unit, the Knight does not move. The turn is consumed.

Single-tile move (King):

- The King resolves its destination tile and captures a concealed enemy there normally.

A move that stops early, captures a concealed unit, or produces no movement reveals information only through the normal visibility recalculation and the reported action outcome. This is acceptable because the attempt consumes a turn.

Every unit's effective vision is at least one tile, and forest detection is at least one tile, so the first tile of any path is always fully known to the mover. A no-progress outcome therefore only arises from a Knight jumping to a destination beyond its effective vision.

### 3.7 Ambush

Units that cannot capture are destroyed if they blindly enter a tile held by a concealed enemy.

Ambush applies to:

- Scout: any move.
- Engineer: any move.
- Pawn: forward moves only. Diagonal captures are unaffected.

Trigger conditions, all of which must hold:

- The moving unit enters a tile on its path, including the destination.
- That tile contains an enemy unit.
- That enemy unit was not detected by the moving player at action commit time.
- That enemy unit is capable of capturing (King, Queen, Rook, Bishop, Knight or Pawn).

Resolution:

- The moving unit is destroyed and removed from the board.
- The ambushing unit is unharmed and does not move.
- The action consumes the turn.
- The ambush is reported to the moving player, revealing the ambushing unit's type and tile. Persistent knowledge afterwards follows the normal visibility rules in Section 4.4.
- No gold is awarded for an ambush.

An ambushing unit may ambush from any direction. Ambush is not a normal capture and does not use the ambushing unit's capture movement pattern.

Concealed enemy Scouts and Engineers do not ambush. They block normally and the moving unit stops before them (Section 3.6).

Capture-capable movers (King, Queen, Rook, Bishop, Knight, and Pawn diagonal captures) are never ambushed. They capture concealed enemies normally.

Ambush is fully deterministic and contains no randomness.

## 4. Vision and Fog of War

Fog of war is a central game mechanic, not merely a visual effect.

Each player has an independent visibility and exploration map.

There are three states for every tile:

- **Unexplored**: terrain and enemy positions are unknown.
- **Explored but not currently visible**: terrain remains known, but enemy positions are hidden.
- **Currently visible**: terrain and enemy positions can be observed, subject to forest concealment.

### 4.1 Base vision ranges

Vision is measured in tiles.

A vision radius of N means a square of (2N+1) × (2N+1) tiles around the unit, using Chebyshev distance.

| Unit | Base vision | Area |
| --- | --- | --- |
| Pawn | 2 | 5×5 |
| King | 2 | 5×5 |
| Queen | 2 | 5×5 |
| Rook | 2 | 5×5 |
| Bishop | 2 | 5×5 |
| Knight | 2 | 5×5 |
| Engineer | 2 | 5×5 |
| Scout | 3 | 7×7 |

A tile is considered visible if it falls within the effective vision radius of at least one friendly unit.

Vision must be calculated independently for both players.

### 4.2 Terrain modifiers

#### Hills

Standing on a hill increases the unit's vision radius by exactly one tile.

Examples:

- Pawn: 2 → 3.
- Rook: 2 → 3.
- Scout: 3 → 4.

#### Forests

Standing on a forest tile decreases the unit's vision radius by exactly one tile.

Examples:

- Pawn: 2 → 1.
- Rook: 2 → 1.
- Scout: 3 → 2.

This penalty affects vision only. It does not change the forest detection distances in Section 4.3.

#### Water

A Scout standing in water loses exactly one tile of vision.

Examples:

- Scout on ordinary ground: 3.
- Scout on a hill: 4.
- Scout in water: 2.

Other units cannot normally stand in water.

These modifiers are additive.

### 4.3 Forest concealment

Trees provide concealment for units occupying forest tiles.

A unit inside a forest cannot be detected by ordinary enemy vision unless the observing unit is sufficiently close.

Detection distance:

- Ordinary units: one tile.
- Scouts: two tiles.

This rule applies independently of the ordinary vision radius.

For example, an enemy Rook may have its square covered by a player's vision, but if the Rook is hidden inside a forest and no friendly unit is within one tile, its position remains concealed.

Scouts can detect forest-hidden enemy units at a distance of up to two tiles.

For the initial implementation, forests should conceal units but should not block the entire vision calculation. This keeps vision understandable and avoids complicated ray-tracing rules.

### 4.4 Persistent exploration

When a player discovers a tile:

- Its terrain is revealed.
- Its terrain information remains permanently known to that player.
- If the tile stops being visible, the terrain remains displayed, but under fog.
- Enemy unit positions disappear when they are no longer visible.

Friendly units always remain visible to their owner.

Previously explored terrain must not be confused with currently visible enemy information.

The two players must never share exploration state.

### 4.5 Vision updates

Recalculate visibility whenever:

- A unit moves.
- A unit is recruited.
- An Engineer builds or destroys a bridge.
- A unit is captured.
- A unit is destroyed by ambush.
- A unit changes its terrain position.

Use an efficient visibility update system rather than repeatedly rebuilding the entire scene.

## 5. Terrain

The initial game contains four terrain types.

### 5.1 Ordinary ground

- Passable by all units.
- No special effects.
- Default terrain.

### 5.2 Forests / Trees

- Passable by all units.
- Conceals occupying units.
- Reduces the vision radius of a unit standing on the forest tile by exactly one tile.
- Enemy detection follows the forest concealment rules.
- Does not block ordinary vision calculations.

### 5.3 Hills

- Passable by all units.
- Increases the vision radius of a unit standing on the hill by exactly one tile.
- Does not increase combat strength.
- Does not grant a movement bonus directly. Because sliding reach at the explored frontier equals effective vision (Section 3.3), a hill extends how far a sliding unit can move into territory its owner has not yet explored.

### 5.4 Water

- Impassable by ordinary units.
- Scouts may enter and leave water under their special movement restrictions.
- Engineers can construct bridges.
- Bridges make water tiles passable to ordinary units.

### 5.5 Gold mines

- Passable.
- Can be occupied by any unit.
- Generate gold through the periodic income system described below.
- Must be placed symmetrically.
- Gold mines are strategically important locations and should generally be positioned away from the starting areas.

Mine accessibility requirements:

- Every map must contain at least two gold mines that are accessible to both players using ordinary units (units that cannot enter unbridged water).
- Accessible means a continuous path of playable, non-water tiles from each player's home deployment area to the mine, requiring no bridge construction.
- Additional mines may be placed on islands or in locations reachable only by Scouts or via bridges. These are optional bonus objectives and do not count toward the two-mine minimum.

## 6. Economy and Gold

The economy should be deliberately slow.

Gold is used exclusively for recruiting units.

There are no:

- Technology trees.
- Unit upgrades.
- Random loot drops.
- Passive income from ordinary terrain.
- Purchasable Queens or Kings.

### 6.1 Recruitment prices

Use the following initial balancing values:

| Unit | Cost |
| --- | --- |
| Pawn | 1 gold |
| Scout | 2 gold |
| Knight | 3 gold |
| Bishop | 4 gold |
| Engineer | 4 gold |
| Rook | 5 gold |
| Queen | Cannot be purchased |
| King | Cannot be purchased |

These values are initial tunable configuration, not permanent balance decisions.

Each player starts with 0 gold.

### 6.2 Recruitment

Recruitment:

- Costs the corresponding amount of gold.
- Consumes the player's entire turn.
- Creates the selected unit inside the player's home deployment area.
- Cannot create a Queen or King.
- Requires sufficient gold.
- Requires an empty playable deployment tile.
- The player chooses an available spawn tile within their first two home rows.
- A newly recruited unit cannot move until the next turn, naturally enforced by the turn system.
- If the home deployment area has no available tile, recruitment is unavailable.

The maximum number of pieces is naturally constrained by available board space. Do not introduce an arbitrary army cap in the initial version.

### 6.3 Gold mine production

Each mine operates independently.

One gold is generated every two rounds, where one round means each player has completed one turn.

Therefore, one production cycle consists of four completed player actions (four plies).

The important rule is that gold does not accumulate.

Detailed mine state:

- `cycle_progress`
- `gold_available`
- `occupied_by`
- `mine_owner` (optional derived information)

At the start of the game, every mine begins its first production cycle.

When four completed player actions have passed:

- If the mine is occupied:
  - The player owning the occupying unit receives one gold immediately.
  - The mine's production cycle resets.
- If the mine is unoccupied:
  - One gold token appears on the mine.
  - Production pauses.
  - No additional gold can accumulate.
  - The first unit to occupy the mine collects the token.
  - The owner of that unit receives one gold.
  - The production cycle resets only after the token has been collected.

If a mine is occupied when its production cycle completes, the occupying unit receives the gold. It does not matter which player originally occupied the mine.

This means the player who receives the income can change between cycles.

For example:

1. Player A occupies a mine.
2. A production cycle completes.
3. Player A receives one gold.
4. The mine's timer resets.
5. Player B captures the mine.
6. The next production cycle completes.
7. Player B receives one gold.

If a mine is empty when gold is generated, the token remains available until collected.

Do not let an uncollected gold token trigger additional production cycles.

Gold mine timing must be deterministic and tied to completed player actions, not real-world elapsed time.

## 7. Victory Conditions and Game Rules

The only primary victory condition is capturing the enemy King.

Unlike conventional chess:

- There is no check.
- There is no checkmate.
- Players are not required to respond to attacks on their King.
- A King can move into a threatened position.
- The King can be captured like any other eligible target.

Capturing a King immediately ends the game.

The game must not automatically prevent a move because it leaves the moving player's King threatened.

This is intentional: fog of war makes conventional check rules unsuitable.

### 7.1 Draw rules

The game ends in a draw under any of the following conditions:

- **Turn limit**: if no King has been captured after 120 completed plies (60 turns per player), the game is a draw. The limit is a tunable configuration value.
- **Threefold repetition**: if an identical position occurs for the third time, the game is a draw automatically. A position consists of piece placement, bridge states, player gold, mine states, and the player to move. Exploration and vision maps are excluded from the comparison.
- **Mutual agreement**: a player may offer a draw and the opponent may accept. Offering, declining, or accepting a draw does not consume a turn and is handled outside the primary action system.

King capture takes precedence over all draw conditions: if a King is captured, the capturing player wins.

If a player has no legal action, a pass action consumes their turn. The turn limit guarantees that games terminate even when players pass repeatedly.

## 8. Turn and Action System

The game is strictly turn-based.

Every turn consists of exactly one primary action:

- Move a unit.
- Recruit a unit.
- Build a bridge.
- Destroy a bridge.
- Pass, if no other legal action is available.

Actions cannot be chained.

All game events must be resolved in a consistent order:

1. Validate the action against the authoritative state (Section 3.6).
2. Apply the action to the authoritative game state.
3. Resolve captures and ambushes, if any.
4. If a King was captured, end the game immediately and skip all remaining steps.
5. Resolve gold collection.
6. Update bridge and terrain state.
7. Recalculate visibility and exploration.
8. Advance the turn.
9. Advance gold mine production counters.
10. Resolve mine production and rewards.
11. Check draw conditions (turn limit, threefold repetition).
12. Update the presentation.

The ordering of gold collection and mine production must be consistent across the entire game.

King capture terminates the game before any economy, turn advancement, or draw checks are processed.

## 9. Maps and Map Files

Maps are authored in the standalone Map Editor (Section 10) and shipped with the game as map files. The game does not generate maps at runtime and contains no random map generation.

The game ships with a library of authored maps. Replayability comes from map variety rather than procedural generation.

Each map file defines: format version, board mask, per-tile terrain, gold mine positions, home deployment areas, and both players' starting layouts.

Map files use a deterministic, versioned text format (Section 10.3).

The game must validate a map file before starting a match and reject invalid or incompatible files with a clear error.

Map selection happens at match setup. Both players use the same map.

Every map must satisfy the symmetry, accessibility and starting-layout rules in Sections 2 and 5.

Map authoring guidelines:

- Terrain should form recognizable geographical features: forest clusters, rivers and lakes, individual hills or hill groups.
- Water should generally form connected bodies or rivers rather than isolated scattered water tiles.
- Gold mines should be placed at interesting contested positions.
- Avoid excessive terrain noise; readability and strategic clarity come first.

## 10. Standalone Map Editor

Map editing is performed in a dedicated standalone tool, not inside the game. The game itself contains no map editing functionality.

### 10.1 Tool separation

- The Map Editor is a separate application entry point with its own main scene, developed in the same repository and built as its own tool export.
- It reuses the shared Board System, terrain definitions, map validation and map file serialization code. It must not duplicate validation logic.
- Editor code, scenes and assets must be excluded from all game exports (desktop and mobile).
- The game must never import editor UI or tooling code.

### 10.2 Editor capabilities

- Create a new board from the standard geometry mask.
- Paint terrain types (ordinary ground, forest, hill, water) on individual tiles.
- Place and remove gold mines.
- Place both players' starting units. The standard 16-piece composition per player is enforced. The conventional chess arrangement is available as a default template.
- Edits are automatically mirrored to the rotationally corresponding tile so point symmetry is always preserved. This applies to terrain, mines and starting layouts. The initial editor does not support asymmetric maps.
- Display the reserved home deployment areas (read-only; they are fixed by the standard geometry).
- Validate the current map: connectivity, shared-mine accessibility (Section 5.5), deployment legality, starting-layout legality (Section 2.3), and symmetry.
- Show validation errors directly on the affected tiles.
- Save, load and export maps. Export must be blocked while validation fails.

### 10.3 Map file format

Maps are stored in a deterministic, versioned text format (for example JSON), independent of the scene tree.

A map file contains: format version, board mask, per-tile terrain, gold mine positions, home deployment areas, and both players' starting layouts.

The game loads a map file at match setup.

The game must validate a map file before starting a match and reject invalid or incompatible files with a clear error.

### 10.4 Shared code contract

Board data, terrain definitions, validation and map file serialization live in shared core modules used by both the game and the editor.

Changes to terrain or validation rules are made once, in the shared modules, never separately in the editor.

## 11. Technical Architecture

The architecture must separate game logic from visual presentation.

The rules engine must not depend on Godot Nodes, scenes, meshes or UI components.

It should be possible to run and test the entire game simulation without rendering the 3D board.

### 11.1 Main subsystems

#### Board System

- Board dimensions and playable coordinate mask.
- Tile data.
- Terrain.
- Elevation.
- Bridges.
- Occupancy.
- Neighbour and coordinate queries.

#### Unit System

- Unit definitions.
- Ownership.
- Position.
- Movement rules.
- Vision properties.
- Recruitment prices.
- Special abilities.

#### Rules Engine

- Legal movement generation.
- Knowledge-based destination generation for highlights.
- Explored-territory movement range.
- Fog-aware move execution.
- Capture validation.
- Ambush resolution.
- Water restrictions.
- Movement range.
- Promotion.
- Bridge operations.
- Recruitment validation.
- King capture.
- Draw conditions.

#### Vision System

- Per-player vision.
- Forest concealment.
- Forest vision penalty.
- Hill modifiers.
- Water modifiers.
- Persistent exploration.
- Enemy visibility.

#### Economy System

- Player gold.
- Recruitment.
- Mine state.
- Production cycles.
- Gold collection.

#### Turn Manager

- Active player.
- Turn progression.
- Action validation.
- Event resolution.
- Game termination.

#### Map System

- Map file loading and validation.
- Map library management.
- Starting layout application.
- Shared with the standalone Map Editor.

#### Map Editor (standalone tool)

- Separate application entry point, excluded from game exports.
- Terrain painting with enforced point symmetry.
- Mine placement.
- Starting layout placement.
- Validation display.
- Map file save, load and export.

#### Presentation Layer

- 3D terrain.
- Piece models.
- Board highlighting.
- Camera controls.
- Fog of war rendering.
- Animations.
- Audio.
- Mobile touch input.

### 11.2 Suggested project structure

```text
res://
  scenes/
    main/
      Main.tscn
    board/
      Board.tscn
      Tile.tscn
    pieces/
      Piece.tscn
    ui/
      HUD.tscn
      RecruitmentMenu.tscn
      GameOver.tscn
  scripts/
    core/
      game_state.gd
      turn_manager.gd
      game_rules.gd
      action_resolver.gd
    board/
      board_data.gd
      tile_data.gd
      terrain_type.gd
      map_io.gd
      map_validator.gd
    units/
      unit_data.gd
      unit_type.gd
      movement_rules.gd
      unit_registry.gd
    systems/
      vision_system.gd
      economy_system.gd
      gold_mine.gd
      recruitment_system.gd
    presentation/
      board_renderer.gd
      piece_controller.gd
      fog_renderer.gd
      camera_controller.gd
    ui/
      hud_controller.gd
      recruitment_controller.gd
  editor/
    MapEditor.tscn
    map_editor_controller.gd
    editor_ui/
  resources/
    units/
    terrain/
    materials/
  tests/
    test_movement.gd
    test_vision.gd
    test_economy.gd
    test_mines.gd
    test_map_validation.gd
    test_map_io.gd
    test_turns.gd
    test_draws.gd
  assets/
    models/
    textures/
    audio/
  project.godot
```

This is a suggested starting structure. Keep it practical: avoid creating empty abstractions or unnecessary classes merely to match the directory layout.

The `editor/` directory is the standalone Map Editor entry point and must be excluded from all game export presets.

### 11.3 Data-driven unit definitions

Unit properties should be data-driven wherever practical.

A unit definition should contain:

- Unit type.
- Base vision.
- Recruitment price.
- Movement category.
- Base movement reach.
- Explored-territory movement reach, if any.
- Capture capability.
- Special abilities.

Do not hardcode unit prices, vision ranges or movement reaches throughout multiple scripts.

Terrain definitions should similarly contain:

- Terrain type.
- Passability.
- Vision modifiers.
- Concealment properties.
- Special interactions.

Use enums and Resources where appropriate.

### 11.4 State representation

The game state should be serializable and independent of the scene tree.

It should include:

- Board layout.
- All unit positions and ownership.
- Active player.
- Player gold.
- Gold mine production states.
- Bridge states.
- Exploration maps.
- Current visibility maps.
- Turn number.
- Map identifier and map file version.
- Game-over state.

Support saving and loading games in a later phase.

Use a deterministic state representation so that a game can be reproduced from its initial map file and action history.

Map data alone must also be serializable as a standalone map file (Section 10.3) that both the game and the Map Editor can read and write.

### 11.5 Action-based architecture

Represent player actions as explicit data objects or dictionaries with validated fields.

Examples:

- `MoveAction`
- `RecruitAction`
- `BuildBridgeAction`
- `DestroyBridgeAction`
- `PassAction`

All actions must pass through one central validation and resolution interface.

The UI must never directly modify unit positions, gold or board occupancy.

This will make AI opponents, replays, undo systems and eventual online multiplayer much easier to implement.

## 12. User Interface and Controls

The game must support both mouse and touchscreen input.

The game does not support shared-screen (hotseat) play. Human-versus-human matches require online multiplayer, with each player on their own device.

### Desktop

- Left-click to select a unit.
- Highlight legal destinations.
- Left-click a destination to move.
- Display unit information on selection.
- Recruitment menu accessible from the HUD.
- Clear indication of whose turn it is.
- Display current gold and resource income.
- Offer or accept a draw from the HUD.
- Camera rotation, zoom and panning.

### Mobile

- Tap to select a unit.
- Tap a highlighted destination to move.
- Touch-friendly recruitment menu.
- Touch-friendly draw offer controls.
- Camera drag and pinch-to-zoom.
- UI elements must remain usable in both portrait and landscape where practical.

### Visual information

The UI should clearly distinguish:

- Currently visible terrain.
- Previously explored terrain.
- Unexplored terrain.
- Visible enemy units.
- Forest tiles (which may conceal enemy units).
- Legal movement destinations.
- Gold mines and available gold.
- Unit ownership.
- Active player.

Fog rendering states:

- Unexplored tiles are rendered as neutral grey terrain under fog. Their real terrain is not shown.
- Explored but not currently visible tiles are rendered as their known terrain under fog.
- Currently visible tiles are rendered as their terrain with no fog overlay.
- Enemy units are rendered only where they are currently detected.

Ambush events must be reported to the moving player, showing the tile and the ambushing unit's type.

Legal destination highlights are computed from the acting player's knowledge (Section 3.6) and must never reveal concealed enemy positions.

Never leak enemy positions through UI elements, animations, shadows, minimaps or other visual effects when those positions should be hidden.

## 13. Development Roadmap

Implement the game incrementally. Do not attempt to build the entire game in one pass.

### Phase 1 — Core simulation

Implement:

- Board geometry and playable tile mask.
- Map file loading (hand-authored test maps).
- Unit data structures.
- Map-defined initial deployment.
- Traditional piece movement.
- Scout and Engineer movement.
- Captures.
- King capture and victory.
- Turn management.

Use a simple 2D or console representation initially.

Acceptance criteria:

- Every piece follows its specified movement rules.
- Invalid moves are rejected.
- Friendly pieces cannot be captured.
- Scouts and Engineers cannot capture.
- Pawns may move one or two tiles forward on any move.
- Starting layouts load correctly from map files.
- The game ends immediately when a King is captured.
- No check or checkmate restrictions are applied.

### Phase 2 — Terrain

Implement:

- Forests.
- Hills.
- Water.
- Bridges.
- Gold mines as board objects.

Acceptance criteria:

- Water blocks ordinary movement.
- Scouts obey water restrictions, including the multi-tile move rules.
- Hills affect vision.
- Forests reduce vision.
- Engineers can construct and destroy bridges.
- Bridges correctly change passability.

### Phase 3 — Vision and fog of war

Implement:

- Unit-specific vision.
- Hill modifiers.
- Forest vision penalty.
- Scout water penalty.
- Forest concealment.
- Persistent exploration.
- Independent player visibility.
- Knowledge-based destination generation.
- Explored-territory movement range for sliding pieces, Scouts and Engineers.
- Fog-aware move execution (Section 3.6).
- Ambush (Section 3.7).

Acceptance criteria:

- Vision areas match the specified square dimensions.
- Forest concealment works correctly.
- Explored terrain remains visible under fog.
- Enemy pieces disappear when they are no longer detected.
- Highlights never reveal concealed enemy units.
- Sliding reach equals effective vision at the explored frontier and is unlimited along explored ground.
- Moves resolve correctly against hidden blockers, including blind captures, ambushes and partial moves.
- Every attempted move consumes the turn, including partial and no-progress outcomes.
- Knowledge is evaluated at commit time and is not recomputed during execution.
- The two players cannot access each other's hidden information.

### Phase 4 — Economy

Implement:

- Starting gold.
- Recruitment prices.
- Recruitment actions.
- Home deployment.
- Gold mine timers.
- Ground gold tokens.
- Gold collection.

Acceptance criteria:

- Recruitment consumes exactly one turn.
- Queens and Kings cannot be recruited.
- Gold mine production occurs after exactly four completed player actions.
- Unclaimed gold does not accumulate.
- Mine cycles restart only after gold is collected.
- The player occupying a mine at the production boundary receives the reward.

### Phase 5 — Standalone Map Editor and map library

Implement:

- Standalone Map Editor entry point (separate from the game).
- Terrain painting with enforced point symmetry.
- Mine placement tools.
- Starting layout placement with symmetry enforcement.
- Map validation (symmetry, connectivity, shared-mine accessibility, starting-layout legality).
- Map file save, load and export.
- An initial library of validated maps.

Acceptance criteria:

- The editor runs without launching a match and is excluded from game exports.
- Maps exported from the editor load and play correctly in the game.
- The editor rejects invalid maps on export.
- Every shipped map has at least two mines accessible to both players with ordinary units.
- Starting layouts are symmetric and contain no first-turn captures.

### Phase 6 — 3D presentation

Implement:

- 3D board and tile models.
- Terrain models.
- Chess piece models.
- Movement animations.
- Fog of war rendering.
- Camera controls.
- UI, including draw offer controls.

Prioritize readability over visual complexity.

### Phase 7 — Mobile support

Implement:

- Touch selection and movement.
- Touch-friendly menus.
- Mobile camera controls.
- Android export and testing.
- Performance optimization.

Test on an actual mobile device, not just the editor.

### Phase 8 — Basic AI

Implement:

- A basic single-player AI opponent.
- AI decision-making using only the AI player's visible and explored information.

Acceptance criteria:

- A complete match can be played against the AI.
- The AI never accesses hidden enemy positions through the underlying game state.
- The AI explores, contests mines, and attempts to capture the enemy King.

### Phase 9 — Online multiplayer and persistence

Implement:

- Online multiplayer with each player on their own device.
- Per-player fog of war over the network.
- Save/load and replay functionality.

Acceptance criteria:

- Each client receives only the information its player is entitled to see.
- Matches remain deterministic and validated by the rules engine.
- Replays reproduce matches exactly from the map file and action history.

## 14. Testing Requirements

Automated tests are essential, particularly because many mechanics interact.

At minimum, test:

### Movement

- All conventional piece movements.
- Irregular board boundaries.
- Sliding movement restricted to explored tiles.
- Sliding reach equals effective vision at the explored frontier.
- Sliding reach is unlimited along contiguous explored ground.
- Pawn one-tile and two-tile forward steps on any move.
- Pawn two-tile step blocked by an occupied intermediate tile.
- Pawn promotion.
- Knight jumping.
- Scout three-tile base reach and five-tile explored reach.
- Engineer two-tile base reach and four-tile explored reach.
- Extended reach refused when any path tile is unexplored.
- Multi-tile intermediate-tile rules for Pawn, Scout and Engineer.
- Scout water restrictions, including the land → water → land prohibition.
- Extended reach disabled while a Scout stands in unbridged water.
- Water restrictions.

### Vision

- All base vision radii, including Pawn vision 2.
- Hill bonus.
- Forest vision penalty.
- Additive stacking of hill and forest modifiers.
- Scout water penalty.
- Forest concealment.
- Scout forest detection.
- Forest detection distance unchanged by the forest vision penalty.
- Persistent exploration.
- Independent player visibility.
- Knowledge-based highlights never reveal concealed units.

### Fog-aware execution

- Ray truncation at hidden blockers.
- Blind captures by rays, Kings and Knights.
- Every committed movement attempt consumes the turn, including partial and no-progress outcomes.
- Multi-tile step moves stop before hidden blockers and complete as partial moves.
- A partial move resolves visibility, gold collection and promotion from the actual ending tile.
- A Knight whose destination is invalid does not move, and the turn is consumed.
- Pawn forward moves into hidden non-capturing units stop before them.
- Knowledge is evaluated at commit time and not recomputed mid-move.
- No sequence of attempts reveals hidden terrain or hidden units without spending turns.

### Ambush

- Scout destroyed by a concealed capture-capable enemy on its destination.
- Engineer destroyed by a concealed capture-capable enemy on its destination.
- Pawn destroyed by a concealed capture-capable enemy on a forward move.
- Ambush triggers on an intermediate path tile, not only the destination.
- Ambush consumes the turn.
- The ambushing unit is unharmed and does not move.
- The ambush event is reported to the moving player.
- A detected enemy blocks the move instead of triggering an ambush.
- A concealed enemy Scout or Engineer blocks the move without ambushing; the mover stops before it.
- Capture-capable movers are never ambushed.
- Pawn diagonal captures are never ambushed.

### Economy

- Recruitment prices.
- Insufficient gold.
- Invalid deployment positions.
- Recruitment turn consumption.
- Gold mine four-ply cycle.
- Occupied mine payout.
- Unoccupied mine token.
- Paused production while gold is unclaimed.
- Cycle restart after collection.

### Engineers

- Bridge construction.
- Bridge destruction.
- Occupied bridge restrictions.
- Turn consumption.

### Map Editor and map files

- Save/load round-trip preserves the map exactly.
- Exported maps load in the game and produce the intended board and starting layouts.
- Symmetry enforcement during editing, including starting layouts.
- Maps without two shared accessible mines are rejected.
- Island mines are permitted beyond the two-mine minimum.
- Maps with first-turn-capturable starting pieces are rejected.
- Invalid maps cannot be exported.
- The game rejects invalid or incompatible map files.

### Draw rules

- Turn limit triggers a draw at the configured ply count.
- Threefold repetition is detected correctly.
- Draw offers and acceptance.
- King capture takes precedence over draw conditions.

### Game state

- King capture.
- Game termination.
- Turn alternation.
- Pass when no legal action exists.
- Deterministic action replay from a map file and action history.

Add integration tests for interactions between mechanics, not just isolated functions.

## 15. Coding Agent Instructions

Follow these requirements throughout development:

- Inspect the existing repository before making changes.
- Do not rewrite unrelated components or introduce unnecessary dependencies.
- Use Godot 4 and GDScript unless there is a concrete technical reason to choose otherwise.
- Keep the rules engine independent of Godot's rendering and scene systems.
- Follow Godot conventions and use typed GDScript where practical.
- Avoid excessively complicated inheritance structures. Prefer composition and data-driven definitions.
- Do not duplicate movement, vision or economy logic in UI scripts.
- Compute player-facing move options from the acting player's knowledge, never from hidden authoritative state.
- Evaluate knowledge once at action commit time; never recompute detection during move execution.
- Every committed movement attempt consumes a turn. Never implement a free retry.
- Do not introduce randomness into the game or rules engine. Maps come exclusively from authored map files.
- Do not add shared-screen (hotseat) multiplayer.
- Keep the Map Editor a standalone tool. Do not add map editing functionality to the game runtime or game UI.
- Exclude editor code, scenes and assets from all game export presets.
- Share validation and map file code between the game and the editor; do not fork that logic.
- Do not hardcode board dimensions into movement or vision calculations.
- Keep all configurable balance values in centralized configuration or resource definitions.
- Write automated tests for every significant mechanic.
- Run tests after each implementation phase.
- Do not claim a feature is complete until it has been tested.
- Do not implement future roadmap features prematurely.
- Update the project README and technical documentation when architecture or behavior changes.
- Keep the project runnable after every development milestone.
- When a specification is ambiguous, choose the simplest implementation that preserves the intended gameplay. Document the decision rather than silently introducing new mechanics.
- If two requirements conflict, prioritize the explicit game design requirements in this document and report the conflict.

## 16. Initial MVP Definition

The first playable version should contain:

- A small library of authored, symmetrical 16-row battlefields with map-defined starting layouts.
- Loading of map files exported by the standalone Map Editor.
- Traditional chess pieces.
- Scout and Engineer.
- All four terrain types.
- Bridge construction and destruction.
- Unit-specific vision.
- Fog of war with persistent terrain exploration and knowledge-based highlights.
- Explored-territory movement range and ambush.
- Gold mines and slow recruitment economy.
- King capture victory condition.
- Draw rules (turn limit, threefold repetition, agreed draw).
- Single-player versus a basic AI opponent.
- Basic 3D rendering and desktop controls.

Do not include online multiplayer, sophisticated AI, unit upgrades, combat animations with damage calculations, technology trees or additional unit types in the MVP.

No shared-screen multiplayer is included in any version.

The standalone Map Editor is a separate tool and is never included in the game build.

The MVP is successful when a player can play a complete, deterministic match against the basic AI, explore the map, compete for gold mines, recruit units, use terrain strategically and capture the opposing King or reach a draw.

# 17. Phase 10 — Presentation Polish

## 17.0 Scope and hard constraints

Phase 10 changes only how the game looks, sounds and feels. It must not change what the game does.

- No rule, balance, validation or state-semantics changes. The full Section 14 suite and the existing replay corpus must pass unchanged, with byte-identical state hashes before and after every polish slice.
- All polish is driven by the action event stream from the resolver (Section 11.5). The presentation layer never reads authoritative state directly to decide what to draw; it reads the local player's knowledge projection.
- Cosmetic randomness is permitted in the presentation layer only. Seed every cosmetic effect deterministically from `(ply, tile, event_type)` so replays look identical on every playback. Cosmetic randomness must never feed back into game state.
- **Information budget is absolute.** Section 12's no-leak rule outranks every visual ambition below. Any effect that reveals a concealed unit is a defect, not a trade-off. Specifically forbidden: shadows, reflections, ambient occlusion contact darkening, bloom, rim light, particles, decals, footprints, positional audio, or music intensity derived from undetected units.
- Concealed enemy units are culled from rendering entirely (`visible = false`, no attached lights, no audio emitters, no particle systems). Never hide a unit by fading opacity, scaling to zero, or moving it off-screen — those leave shadows and reflections behind.

## 17.1 Decisions to resolve before polishing

These are existing spec ambiguities that the renderer cannot resolve on its own. Decide, document in the blueprint, then polish.

1. **Terrain data model.** Confirm the resolved model from the earlier review: base terrain (ground/water) + cover (forest) + elevation (0/1), with "hill" and "forest" as authoring brushes. Sections 4.2 and 14 require additive stacking, so a single exclusive terrain enum is insufficient.
2. **Known-terrain snapshot.** Section 4.4 says explored terrain remains permanently known. Confirm that explored-but-not-visible tiles render from the player's *last-seen* terrain snapshot, including bridge state — not live state. Otherwise an enemy Engineer building a bridge in fog silently updates your map. This requires per-player known bridge state; if it is missing, treat it as a Phase 3 correctness fix, not polish.
3. **Opponent gold privacy.** Section 12 shows gold in the HUD. If opponent gold is public, a mine payout reveals that they occupy or collected a mine. Recommended: keep it public and accept it as intended strategic intel, like material count in chess. Do not add extra leakage on top — no coin trail from a mine you cannot see.
4. **Promotion timing.** Promotion choice is declared at commit time. The picker is therefore a pre-commit dialog, never a post-move surprise.

## 17.2 Art direction

Target: **a war table made physical.** A carved stone-and-turf diorama floating in a dark void, lit like a campaign map under a warm lamp. Miniature, tactile, restrained. Not realism, not neon, not flat vector.

Every visual decision must survive overview zoom, where a tile is roughly 25dp on a phone. Detail that only reads at tactical zoom is decoration; silhouette, value and hue carry the game.

| Role | Hue | Usage |
|---|---|---|
| Void / background | `#0E1218` | Space around the board, menu backdrop |
| Surface / overlay | `#171C24` | HUD panels, cards, sheets |
| Light army body | `#E8DCC4` | Bone/ivory piece bodies |
| Dark army body | `#2A2F38` | Obsidian piece bodies |
| Player A accent | `#D6453C` | Crimson base ring, banner, HUD identity |
| Player B accent | `#3E8FD6` | Azure base ring, banner, HUD identity |
| Forest | `#4F7A46` | Canopy, moss |
| Hill / rock | `#8A8172` | Warm stone risers |
| Water | `#1C3A44` | Deep teal surface |
| Mine gold | `#F2B544` | The only amber permitted on the board |
| Unexplored slab | `#6B7078` | Cool neutral, untextured |

- Ownership is triple-encoded: body value (light/dark) + accent hue (crimson/azure) + base-ring shape (notched vs smooth). This survives colorblindness and 25dp scale.
- Semantic colors (success `#5FBF7F`, warning `#E8A33D`, danger `#E05252`, info `#6FA8DC`) appear **only in HUD chrome**, never on board tiles. The board's hue budget is reserved for terrain and ownership.
- Board threat indication uses shape and motion (pulsing ring, broken-shield icon), not a new color.

## 17.3 Materials

- One shared PBR material per terrain archetype. No per-tile material instances — 216 tiles must not mean 216 materials.
- Pack occlusion/roughness/metallic into a single ORM texture. Two 1024² atlases (terrain, units) plus one props atlas. Total texture memory under 128 MB on mobile.
- Albedo carries readable shape, not high-frequency noise. Fine grain turns to mud at overview zoom; bake broad value variation into vertex colors instead.
- Metal is reserved for ownership inlay and mine hardware. Stone, turf and wood stay non-metallic with roughness 0.55–0.85.
- No screen-space reflections anywhere. Water uses a scrolling normal map with a static sky cubemap, so it can never mirror an undetected unit.
- Avoid transparency on the board. Use opaque or dithered materials; sorted transparency is the main overdraw cost on mobile.

## 17.4 Board terrain

- **Unexplored tiles render as uniform flat slabs at a single fixed height, with no props.** Never render the real hill mesh, tree meshes or water surface in grey — the silhouette alone leaks elevation, forest and water positions. This is the most likely leak in the entire polish pass.
- **Ground:** turf with gentle vertex-color variation, sparse instanced pebbles and grass tufts via MultiMesh. Density low enough that tile boundaries stay legible (Section 9).
- **Forest:** a single canopy-blob silhouette per tile with 2–3 trunk hints, not individual detailed trees. When a friendly or detected unit occupies a forest tile, shrink and fade the canopy so the piece is fully visible — a legally detected unit must never be hidden by decoration.
- **Hill:** a clear one-step riser with a rock face and a lit top edge. Elevation must read at overview zoom without relying on shadow.
- **Water:** dark, slow normal scroll, subtle shoreline foam. No scene reflections.
- **Bridge:** obviously constructed — plank pontoon with pilings, visually distinct from natural ground, so passability is never ambiguous.
- **Mine:** shaft head with a warm lamp, a four-segment cycle ring, and a physical gold token prop when `gold_available` is true. At overview zoom, add a billboard icon so mine state stays readable.
- Tile grid lines are subtle but present at all zooms; they are the player's coordinate system.

## 17.5 Fog rendering

- Drive fog from a single 16×16 data texture (fog state, terrain id, highlight class, overlay flags) sampled by the board shader. Fog transitions are a texture interpolation, not 216 material updates.
- Render two MultiMesh layers — blank slab and real terrain — and toggle per-instance visibility on fog-state change, with a short shader-driven reveal.
- Three states must be distinguishable in greyscale, not just by hue: unexplored is flat, propless, cool and darkest; explored shows real terrain and props under a desaturating cool veil; visible is fully saturated and key-lit. Adjacent states differ by at least 1.5:1 in luminance **and** by a non-color cue.
- Discovery is a moment: newly explored tiles reveal in a 250ms directional wave from the moving unit. Never animate fog with a continuous pulse — it makes state reading unreliable.

## 17.6 Units

- Preserve chess silhouettes exactly. A Knight must read as a Knight at 25dp. Scout reads light and tall (lantern/hood); Engineer reads stocky and burdened (hammer/pontoon).
- Piece height ≈ 1.35 × tile width, base diameter ≈ 0.68 × tile width.
- Two LOD tiers with hysteresis: below 36dp tile size render an iconic token (extruded piece silhouette on an ownership disc); above 48dp render the full sculpted piece. Hard swap, no crossfade.
- Ownership base ring is always present and always readable from the fixed 60° camera pitch.
- Selected unit lifts slightly and gains a pulsing ring. Units that have already acted are never dimmed — one action per turn makes that meaningless.

## 17.7 Lighting and post

- Locked mobile yaw and fixed pitch allow baked lighting. Bake LightmapGI for static terrain; do not recompute static shadows per frame.
- One warm directional key, cool gradient ambient, subtle rim. Units use cheap blob shadows on Low/Medium mobile tiers; real shadow maps only on High and desktop.
- Post stack: gentle bloom (mine gold and highlight markers only, never ownership accents), mild warm-highlight/cool-shadow grade, soft vignette.
- Forbidden: motion blur, film grain over the board, depth of field at overview zoom. Optional tilt-shift DOF is desktop-High only, off by default, and must never blur highlights or unit silhouettes.
- AA: MSAA 4× desktop, 2× mobile-High, FXAA on mobile-Low.

## 17.8 Interaction feedback

**Destination markers must teach Section 3.6.** This is the highest-value polish item in the phase.

| Marker | Meaning |
|---|---|
| Solid filled | Guaranteed — path fully explored and known clear |
| Dashed ring | Attempt — path crosses unexplored or uncertain tiles; may stop short or trigger ambush |
| Crosshair | Capture of a detected enemy |
| Frontier tick | The first uncertain tile along a ray |

Hover (desktop) and long-press-drag (mobile) preview the path, solid up to the frontier and dashed beyond.

| Event | Timing | Treatment |
|---|---|---|
| Move | 200ms + 40ms/tile, cap 420ms | Ease-out slide, terrain-aware footfall dust |
| Knight jump | 260ms | Arc, landing impact |
| Capture | 60ms hitstop | Captured piece topples into motes; weighty audio |
| Partial move | On stop | Blocked impact, "unknown obstruction" marker on the blocking tile, toast: *Stopped short — turn used* |
| No-progress Knight | 250ms | Bounce-back, invalid-destination marker, toast: *Turn used* |
| Ambush | 120ms slow + 350ms reveal | Mover shatters, camera micro-shake, ambusher revealed with type icon and tile callout, persistent log entry |
| Recruit | 350ms | Piece rises with a dust ring |
| Bridge build / destroy | 450ms | Planks assemble / collapse with splash |
| Promotion | 500ms | Transform after pre-commit choice |
| Gold payout | 500ms | Coin motes to HUD counter **only if the mine tile is visible to you** |
| Turn change | 400ms | Banner sweep, subtle light temperature shift, mobile haptic |

Camera shake amplitude ≤ 0.6% of viewport, duration ≤ 180ms, disabled by Reduce Motion. Never shake the camera for an opponent action you cannot see.

## 17.9 UI

- **Type:** chiseled display serif for headings, clean sans for UI, tabular numerals for gold and ply counters. Ship a CJK-capable fallback (Noto Sans SC) and test string expansion at 150% text scale.
- **Layout:** portrait top bar (turn, ply remaining, both golds, connection, menu); bottom bar (selected-unit card, Recruit, Draw). Desktop uses a side rail with the same components. All interactive UI respects safe-area insets and 44dp minimum targets.
- **Unit card:** glyph, movement diagram, vision radius, capture capability, and *currently applied* modifiers ("Forest: vision 2 → 1", "Water: vision −1"). This is where the rules become learnable.
- **Tile card (long-press / right-click):** terrain, elevation, fog state, mine cycle and token, known bridge state, and "may conceal enemies" for forest.
- **Action log:** last 20 events with icons; tapping focuses the camera. Essential online and for understanding ambush.
- **Opponent move replay:** animate their move only if both origin and destination were visible to you at the time. Otherwise show a neutral "opponent acted" cue. Never animate hidden movement.
- **King threat indicator:** pulsing ring computed only from detected enemies, listing known attackers. It warns; it never blocks a move (Section 7).
- **Draw offer:** non-blocking banner with accept/decline; consumes no turn.
- **Online chrome:** connection pill, opponent-thinking indicator, turn timer ring, rejoin and disconnect states.
- **Menus:** setup (mode, map, side, first player), map picker with pre-rendered thumbnails shipped as assets, pause, settings, game over with match stats (plies, captures, gold earned, mines held, scouts lost to ambush) and rematch.
- **Replay viewer:** scrubber, ply stepping, speed control, and a side selector that renders either player's knowledge. Label it clearly as post-match full information.
- Style every scrollable region's scrollbar in the palette; no browser/engine default tracks.

## 17.10 Audio

- Restrained war-table palette: wood and stone clicks, cloth, low strings. Every sound is tied to a visible event.
- **Music intensity is computed from the local player's knowledge only.** A score that swells because a hidden enemy is near is an information leak.
- Ambience is positional to *known terrain* only — wind, forest birds, water lapping. Never attach audio to undetected units; no footsteps for moves you cannot see.
- Distinct cues for select, move per terrain, capture, ambush (the sharpest sting in the game), gold, recruit, bridge, promotion, turn, victory, defeat, draw.
- One always-visible mute-all control showing current state, plus master/music/SFX sliders, persisted. Handle mobile audio focus and backgrounding.

## 17.11 Accessibility

- Colorblind palettes for deuteranopia, protanopia and tritanopia; ownership remains distinguishable via ring shape and body value.
- Reduce Motion: disables shake, hitstop, reveal waves and long animations; state changes stay instant and legible.
- Text scale 100/125/150%; minimum 14sp body on mobile.
- Full keyboard and gamepad tile-cursor navigation on desktop.
- Haptics on mobile with a toggle.
- Greyscale test: fog states, ownership and highlight classes must all remain distinguishable with color removed.

## 17.12 Performance and quality tiers

| | Low | Medium | High |
|---|---|---|---|
| Unit shadows | Blob | Blob | Real-time |
| Post | Grade only | + bloom | + vignette, DOF (desktop) |
| Prop density | 25% | 60% | 100% |
| Water shader | Static | Scroll | Scroll + foam |
| MSAA | Off/FXAA | 2× | 4× |
| Render scale | 0.75 | 1.0 | 1.0 |

- Auto-detect tier by device, allow manual override, persist the choice.
- Budgets on the named target device: 60fps during camera motion and animations, 30fps floor, under 150 draw calls and 250k triangles on mobile, framebuffer capped near 2.2M pixels.
- Idle at 15fps between actions; 60fps during interaction; stop rendering when backgrounded.
- Reuse geometry and materials; instance all props through MultiMesh; never rebuild meshes per frame.

## 17.13 Map editor parity

The editor must preview terrain using the same shared material definitions as the game, with a "game view" toggle showing fog states and ownership colors. Authors cannot judge readability in flat debug colors. Validation errors stay overlaid on affected tiles. Editor code remains excluded from all game exports.

## 17.14 Do not

No screen-space reflections. No depth of field at overview. No motion blur or grain over the board. No per-tile materials. No opacity-faded hidden units. No particles, decals or audio from undetected units. No bloom on ownership accents. No pulsing fog. No high-frequency albedo noise. No camera shake for invisible events.

---

# 18. Phase 10 Acceptance and Testing

**Regression gate.** Full Section 14 suite plus the replay corpus pass unchanged; state hashes byte-identical to pre-polish.

**Leak audit (automated).** Across a full scripted match, assert for every ply: no concealed enemy node is visible, no concealed enemy shadow caster is enabled, no concealed enemy audio emitter is active, and no UI or music signal derives from concealed state. Add a manual greyscale-and-silhouette pass over all four terrain types in all three fog states.

**Readability gate.** On a 5-inch phone at overview zoom, five new players identify ownership, unit type and fog state within one second at ≥90% accuracy.

**Comprehension gate.** Five external players complete a match unassisted and can afterwards explain: attempt vs guaranteed destinations, why a partial move cost a turn, what an ambush was, and when a mine pays out.

**Performance gate.** Named mid-range device plus a small-screen phone: frame budgets hold through a full 120-ply match with no thermal throttling; resize, backgrounding, rejoin and replay restart are stable; no duplicated listeners, timers or loops after ten consecutive matches.

**Final refinement.** After the gates pass, fix the single worst remaining finding from the readability test before declaring Phase 10 complete.

---

# 19. Phase 10 Coding Agent Instructions

- Implement in slices, each leaving the build runnable: materials and terrain → units → lighting and fog → interaction feedback → UI → audio → performance and accessibility.
- Run the regression gate after every slice. A polish change that alters a rules test is a bug in the polish, not a reason to update the test.
- Resolve Section 17.1 with the human before starting; do not silently pick a behavior.
- Do not modify the rules engine, validator, economy or map format to make an effect easier.
- Keep all polish constants (timings, palette, tier thresholds, LOD sizes) in centralized configuration, not scattered through scripts.
- Every effect must degrade gracefully: if a tier or platform cannot support it, the information it carried must still be conveyed by a cheaper cue.
- Update the README and technical documentation with the palette, tier table and event-to-effect mapping.