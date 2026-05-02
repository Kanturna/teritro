# Teritro Vision

Teritro is a small-to-medium territorial hexgrid simulation about colonies that
grow, enclose space, meet borders, and later compete through agents, units, and
economy.

## Core Fantasy

The player or observer watches simple local rules create readable territorial
patterns. A colony should feel like it is drawing living borders across a small
map, not painting arbitrary cells.

## Initial Simulation Direction

- Start with one test colony.
- Later support roughly 20 randomly spawned colonies.
- Each colony begins with one starter cell.
- Growth uses the Turn-Rule: a new cell must be adjacent to the last placed
  cell and must not continue straight in the previous placement direction.
- Default v0.1 blocks only the straight-continuation neighbor, so usually 5 of
  6 adjacent hex neighbors remain valid.
- The Turn-Rule should create continuous snake-like lines as an emergent result.
- Enclosed empty regions should later become owned territory.

## Later Direction

- Learning colony agents choose expansion intentions.
- Border conflicts emerge when colony territories meet.
- Units may later move only through allowed territory and fight around borders.
- Economy may later derive from owned territory, but is not a current concept.

## Design Pillars

- Readable emergence from small rules.
- Debuggability before visual polish.
- Simulation truth separate from rendering and UI.
- Small maps first, scalable architecture later.
- Decisions documented with reasons and re-evaluation triggers.
