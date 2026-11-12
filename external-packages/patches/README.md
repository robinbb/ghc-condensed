# Patches

Record of local changes to vendored packages, as `git diff` output
against the pristine sdist. A package that needs a change is vendored
(not a submodule) so that the change is a plain commit in this tree;
the patch file exists so the change can be reapplied after re-vendoring
a newer release: `git apply external-packages/patches/NAME.patch`.
Each patched package carries a `patched:` line in `manifest.yaml`.
