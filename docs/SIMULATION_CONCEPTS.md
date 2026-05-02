# Teritro Simulation Concepts

These are early vocabulary definitions, not final implementation rules.

## Hex Cell

The smallest map unit. It is addressed by axial hex coordinates and may later
hold ownership, occupancy, or derived render state.

## Map

The bounded set of hex cells used by a simulation run.

## Colony

An actor that owns territory and later chooses expansion through an agent or
other controlled policy.

## Starter Cell

The first owned cell of a colony.

## Last Placed Cell

The most recent cell placed by a colony through expansion.

## Placement Direction

The axial hex direction from the previous placed cell to the Last Placed Cell.
It is undefined for the Starter Cell and for any colony with no prior move.

## Turn Placement

A candidate placement adjacent to the Last Placed Cell that does not continue
straight in the current Placement Direction. Default v0.1 blocks only the
straight-continuation neighbor. When Placement Direction is undefined, all 6
adjacent neighbors are valid Turn Placements before other validation checks.

## Territory

The set of cells owned by a colony.

## Expansion Candidate

A cell that a colony could attempt to place next before validation checks such
as ownership, map bounds, or Turn-Rule restrictions.

## Enclosed Area

An empty region that has been surrounded by territory and may later be converted
to owned territory.

## Border

A contact or near-contact region between territories that may later drive
conflict, movement restrictions, or visualization.
