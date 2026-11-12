# Patches

Deliberate exceptions to the rule that corpus packages are not modified,
as unified diffs against the pristine sdist with paths relative to the
repository root. Each patched package carries a `patched:` line in
`manifest.yaml` saying why. `add.rb --fetch` applies them after
vendoring; by hand: `git apply external-packages/patches/NAME.patch`
from the repository root.

- `hashable.patch`: adds ghc-bignum to build-depends for GHC 9.13 and
  later, whose base no longer re-exports GHC.Num.BigNat, GHC.Num.Integer
  and GHC.Num.Natural. Without it hashable, and the roughly half of the
  corpus that depends on it, cannot be built at all.
