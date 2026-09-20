# DefenceTest mathematics

## SPRT

Strength tests use the Sequential Probability Ratio Test: games stream in
until the evidence crosses an upper bound (accept: patch is stronger) or a
lower bound (reject). Bounds come from the requested Elo window, e.g.
`[0, 5]` means "prove +5 Elo or stop". SPRT needs far fewer games than a
fixed game count for the same confidence.

## Elo model

Results are scored pentanomially (pairs of games: WW, WD+DW, WL+LW, DD,
LL…) which halves variance versus trinomial scoring. Elo differences and
error bars derive from the pentanomial likelihood.

## SPSA

Parameter tuning runs use Simultaneous Perturbation Stochastic
Approximation; the mathematics behind it is covered in
https://github.com/vdbergh/spsa_simul (see `doc/theoretical_basis.pdf`).
