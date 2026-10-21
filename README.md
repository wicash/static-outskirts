# Static Outskirts (working title)

A cozy, lonely exploration game set on the outskirts of a city a few months
after several nearby nuclear strikes. The world shows the horror; playing it
should feel gentle. A radio keeps picking up a broadcast that shouldn't exist,
and the signal gets stronger toward the forest.

This is the first small test scene, built in **Godot 4.4** (MIT licensed).

![Street](docs/street.png)
![Home](docs/home.png)

![Packed car](docs/car-carin.png)

## Running it

1. Download Godot 4.4 or newer (standard version, not .NET) from https://godotengine.org/download
2. Open Godot, click **Import**, and pick this folder's `project.godot`.
3. Press **F5** (or the play button).

## Controls

| Key | Action |
| --- | --- |
| Click | Capture the mouse to look around |
| WASD / arrows | Move |
| Shift | Run |
| E | Interact |
| V | Switch first / third person |
| Esc | Free the mouse |

## What's in the scene

Alder Street, a few months after the strikes. Every house has real window and
door openings, a roof with gutters and a chimney, a porch, inner walls and a
small story inside.

- **No. 4, your house:** bedroom, kitchen with a working kettle, the radio on
  the table, a map with the tower circled, Biscuit's blanket by the door, and
  the one warm lamp on the street.
- **No. 6, the Okafors:** Grace's note asking someone to feed Biscuit, the cat
  food in the cupboard, family photos, and Biscuit's collar on the nightstand.
- **No. 8, the Patels:** locked, boxes packed and labelled. Their car is
  outside with WAIT FOR US written in the dust.
- **No. 3, the Bells:** a broken window, breakfast never eaten, the calendar
  that says "drill?", a child's drawing with three suns, and a walkie-talkie
  with a frequency taped to it.
- **No. 5:** Mr. Lindqvist's burnt-out house.
- **No. 7:** boarded up from the inside. NO ONE HERE.
- **The empty lot:** a swing set, one swing still moving, and a buried tin.
- **The street:** cracked road, kerbs and pavements, power poles with sagging
  and snapped wires, one streetlight that still flickers, picket fences,
  mailboxes, bins, hydrants, missing-person posters, and the evacuation bus
  stop with suitcases left in a row.
- **Five detailed cars** with see-through windows and furnished interiors.
- **Nature:** dead grass, bushes, bare trees, a dark pine forest to the north
  with a blinking radio tower, and the hazy city to the south.
- **Biscuit** walks, sits and looks around; **Sam** has an animated body in
  third person. Footsteps and wind are generated in code for now.

![Kitchen](docs/street/kitchen.png)
![Your house](docs/street/yourhouse.png)

## How the look works

- `scripts/kit.gd` holds the shared shapes and materials; `furniture.gd`,
  `houses.gd`, `cars.gd` and `street.gd` build everything from them.
- `scripts/main.gd` renders the 3D world at 1/3 resolution and scales it up with hard pixels.
- `shaders/ps1.gdshader` snaps vertices to a coarse grid (the PS1 wobble), warps
  textures (affine mapping), lights per vertex, and fades to fog.
- `shaders/screen.gdshader` reduces colour depth with ordered dithering.

Everything is built from placeholder blocks in code, so it is easy to move
things around while we find the feel. Real models can replace them later.

## Screenshots from the command line

```
godot --path . -- --shot=out.png [--home | --kitchen | --bedroom | --yourhouse | --okafor | --street | --lot | --busstop | --cat | --car | --crash | --van] [--third]
```
