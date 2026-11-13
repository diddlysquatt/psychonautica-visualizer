# Scene sets, playlists and links

After reading this you can choose which scenes play, in what order and for how long, save that as a small
file, and send someone a link that opens the visualizer on exactly your set.

## In the app

Controls > Scenes > **Edit**. The editor is closed by default and adds nothing permanent to the screen.

- One row per scene: a box to switch it on or off, its name (tap it to go there now), and × on scenes you
  added from a pack.
- **Shuffle | Sequence**. Shuffle: the Auto Show's own running order over the scenes that are on.
  Sequence: exactly the order of the list, looping (A, B, C, D, A, B ...). In Sequence mode each row also
  has a seconds field and a reorder control (drag the grip or use the arrow keys; on a phone, the ▲ ▼
  buttons).
- **All on**, **Save** / **Load** (a playlist file), **Link** (copies a link for the current set),
  **+ Scene** (add a scene pack).

With nothing changed, the show behaves exactly as it always did: every scene, in the Auto Show's order,
for the length chosen under "Time per scene". Scenes only advance by themselves while the Auto Show is on.

## The playlist file

`something.playlist.json`:

```json
{ "format": "hypervisualizer-playlist", "version": 1, "mode": "sequence",
  "order": ["gate", "chroma", "aurora"], "on": ["gate", "chroma"], "secs": { "gate": 30 } }
```

| Field | Meaning |
|---|---|
| `mode` | `"shuffle"` or `"sequence"` |
| `order` | every scene key, in list order |
| `on` | the keys that play; a scene not listed is off |
| `secs` | per-scene length in seconds (5 .. 3600), used in sequence mode; a scene without one uses the global "Time per scene" |

Keys the receiving visualizer does not have are skipped, so a playlist that names a pack scene works for
people who added that pack and degrades gracefully for those who did not.

## Links

```
psychonautica-visualizer.html?scenes=gate,chroma,aurora&mode=sequence&secs=30
```

| Parameter | Meaning |
|---|---|
| `scenes` | comma-separated keys: the scenes that are on, in this order. Unknown keys are skipped. |
| `mode` | `sequence` or `shuffle` (default `shuffle`) |
| `secs` | 5 .. 3600: the length of every scene for this visit |
| `realm` | (older, still works) the key of the scene to open on; wins for the first scene |

A link sets the scene set for that visit only. Nothing is saved unless the person presses "Keep".
The gallery uses these links: "open in the visualizer" on a scene's card is `?scenes=<key>`.

## From a script

`HyperVisualizer.playlist` reads `{ mode, order, on, secs }`; assigning the same shape sets it.
`HyperVisualizer.scenes` lists every scene with its `key`, `name`, whether it is `on`, and whether it was
`added` from a pack.
