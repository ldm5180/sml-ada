"""Drop gnatprove's phase-1 ALIs when two of them disagree on a source.

Usage: phase1_guard.py --obj OBJ_DIR [--obj OBJ_DIR]... SOURCE_DIR...
       phase1_guard.py --selftest

gnatprove's bundled gprbuild hangs in its first phase when two phase-1
ALIs carry different D-line checksums for one source -- the state a
``gnatprove -u`` run leaves behind after a spec changed.  Need_To_Compile
then deletes and re-queues a unit whose compilation is already running,
re-reads the ALI the compiler is rewriting with the size it cached
before, and GPR.ALI.Scan_ALI spins on the end-of-buffer sentinel it
finds short of the buffer's end, until something kills it.  With the
phase-1 ALIs gone, every unit's first phase runs afresh and nothing is
re-queued.

Every OBJ_DIR's gnatprove/phase1 is read as one set -- a withed
project's ALIs can disagree with the proof's own as readily as two of
the proof's can -- and all of them are dropped when the check fails.  An
ALI whose unit has no source under any SOURCE_DIR is ignored: nothing
re-reads it.  Stdlib only, and it removes nothing but phase-1
directories.  Run it under the same lock as gnatprove: it deletes what a
running gnatprove reads.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import tempfile

PHASE1 = os.path.join("gnatprove", "phase1")


def source_names(dirs: list[str]) -> set[str]:
    """The file names of every source under DIRS."""
    names: set[str] = set()
    for top in dirs:
        for _, _, files in os.walk(top):
            names.update(files)
    return names


def unit_and_deps(path: str) -> tuple[str | None, list[tuple[str, str]]]:
    """The ALI's own source file, and (source, checksum) for each D line."""
    unit, deps = None, []
    with open(path, encoding="latin-1") as f:
        for line in f:
            fields = line.split()
            if unit is None and fields[:1] == ["U"] and len(fields) > 2:
                unit = fields[2]
            elif fields[:1] == ["D"] and len(fields) > 3:
                deps.append((fields[1], fields[3]))
    return unit, deps


def alis(phase1_dirs: list[str]) -> list[str]:
    """Every ALI in PHASE1_DIRS, in a stable order."""
    return [
        os.path.join(d, name)
        for d in phase1_dirs
        for name in sorted(os.listdir(d))
        if name.endswith(".ali")
    ]


def first_disagreement(phase1_dirs: list[str], known: set[str]) -> str | None:
    """The first source two live ALIs give different checksums, or None."""
    seen: dict[str, tuple[str, str]] = {}
    for path in alis(phase1_dirs):
        unit, deps = unit_and_deps(path)
        if unit not in known:
            continue
        for source, checksum in deps:
            first = seen.setdefault(source, (checksum, path))
            if first[0] != checksum:
                return f"{source} ({first[1]} vs {path})"
    return None


def guard(obj_dirs: list[str], source_dirs: list[str], say=print) -> list[str]:
    """Drop every phase-1 directory when two live ALIs disagree; say which."""
    phase1 = [os.path.join(d, PHASE1) for d in obj_dirs]
    present = [p for p in phase1 if os.path.isdir(p)]
    found = first_disagreement(present, source_names(source_dirs))
    if found is None:
        return []
    say(f"prove: phase-1 ALIs disagree on {found}; dropping "
        + ", ".join(present))
    for p in present:
        shutil.rmtree(p)
    return present


def write_ali(phase1: str, source: str, deps: list[tuple[str, str]]) -> None:
    """A phase-1 ALI for SOURCE's unit, with one D line per (dep, checksum)."""
    os.makedirs(phase1, exist_ok=True)
    unit = source.rsplit(".", 1)[0]
    lines = ['V "GNAT Lib v15"', f"U {unit}%s\t{source}\t0badc0de OO PK"]
    lines += [f"D {d}\t\t20261008000000 {c} {d[:-4]}%s" for d, c in deps]
    path = os.path.join(phase1, unit + ".ali")
    with open(path, "w", encoding="latin-1") as f:
        f.write("\n".join(lines) + "\n")


def checked(obj_dirs: list[str], source_dirs: list[str]) -> list[str]:
    """What guard drops, without its message."""
    return guard(obj_dirs, source_dirs, say=lambda _: None)


def selftest() -> int:
    """Agreeing and orphaned ALIs are kept; a disagreement drops them all."""
    a1, b1 = ("a.ads", "aaaa0001"), ("b.ads", "bbbb0001")
    old, new, newer = (("shared.ads", f"5ea0000{n}") for n in range(3))
    with tempfile.TemporaryDirectory() as root:
        src, obj, lib = (os.path.join(root, d) for d in ("src", "obj", "lib"))
        os.makedirs(src)
        for name in ("a.ads", "b.ads", "shared.ads"):
            open(os.path.join(src, name), "w").close()
        phase1, lib1 = os.path.join(obj, PHASE1), os.path.join(lib, PHASE1)

        #  Agreeing ALIs, and an orphan whose source is gone that still
        #  remembers an older shared.ads: nothing is dropped.
        write_ali(phase1, "a.ads", [a1, new])
        write_ali(phase1, "b.ads", [b1, new])
        write_ali(phase1, "gone.ads", [old])
        assert checked([obj], [src]) == [], "a consistent set was dropped"
        assert os.path.isdir(phase1), "a consistent set was dropped"

        #  No phase-1 directory at all is not an error.
        assert checked([os.path.join(root, "none")], [src]) == []

        #  A withed project's ALI that disagrees drops both directories.
        write_ali(lib1, "b.ads", [b1, newer])
        assert checked([obj, lib], [src]) == [phase1, lib1], "kept across dirs"
        assert not os.path.exists(phase1) and not os.path.exists(lib1)

        #  Two ALIs in one directory that disagree drop it.
        write_ali(phase1, "a.ads", [a1, new])
        write_ali(phase1, "b.ads", [b1, newer])
        assert checked([obj], [src]) == [phase1], "a disagreement was kept"
        assert not os.path.exists(phase1), "a disagreement was kept"
    print("phase1-guard selftest: ok (keeps agreement and orphans,"
          " drops a disagreement)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__.split("\n", 1)[0],
    )
    ap.add_argument(
        "--obj", action="append", default=[], metavar="OBJ_DIR",
        help="an object directory whose gnatprove/phase1 is checked",
    )
    ap.add_argument("sources", nargs="*", metavar="SOURCE_DIR")
    ap.add_argument(
        "--selftest", action="store_true", help="check the rules and exit"
    )
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    if not args.obj or not args.sources:
        ap.error("needs at least one --obj and one SOURCE_DIR")
    guard(args.obj, args.sources)
    return 0


if __name__ == "__main__":
    sys.exit(main())
