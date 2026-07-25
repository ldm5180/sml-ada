# Thin wrapper around Alire + gprbuild so the common flows are one word.  Every
# target runs through `alr` (so the aunit/gnatprove dependencies resolve).  The
# example builds on all cores (-j0, set in example/example.gpr) and has two
# profiles: release (-O3, tracing off) and debug (-O0, tracing on).

EX := -P example/example.gpr

.PHONY: all build test prove format example release debug run run-trace run-named-trace clean help

all: build

## build       Build the library
build:
	alr build

## test        Build and run the AUnit suite in both modes (per-test output)
test:
	alr exec -- gprbuild -p -j0 -XMODE=debug -P tests/test_sml.gpr
	alr exec -- tests/bin/debug/test_runner
	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_sml.gpr
	alr exec -- tests/bin/release/test_runner

## prove       Run the SPARK proof (same flags as CI)
prove:
	alr exec -- gnatprove -P proof/proof.gpr -j0 --level=2 --checks-as-errors=on \
	  --warnings=error

## format      Check formatting (per project, explicit files; no warnings)
format:
	alr exec -- gnatformat -P sml.gpr --check $$(git ls-files 'src/*.ad[sb]')
	alr exec -- gnatformat -P tests/test_sml.gpr --check $$(git ls-files 'tests/src/*.ad[sb]')
	alr exec -- gnatformat -P example/example.gpr --check $$(git ls-files 'example/src/*.ad[sb]' 'example/cfg/release/*.ad[sb]')
	alr exec -- gnatformat -P example/example.gpr -XMODE=debug --check $$(git ls-files 'example/cfg/debug/*.ad[sb]')
	alr exec -- gnatformat -P proof/proof.gpr --check $$(git ls-files 'proof/src/*.ad[sb]' 'support/src/*.ad[sb]')

## example     Build the example both ways
example: release debug

## release     Build the example (-O3, tracing off)
release:
	alr exec -- gprbuild -p -XMODE=release $(EX)

## debug       Build the example (-O0, tracing on)
debug:
	alr exec -- gprbuild -p -XMODE=debug $(EX)

## run         Build and run the release hello_world
run: release
	./example/bin/release/hello_world

## run-trace   Build and run the debug hello_world_with_tracing
run-trace: debug
	./example/bin/debug/hello_world_with_tracing

## run-named-trace  Build and run the debug named_tracing (Sml.Tracing)
run-named-trace: debug
	./example/bin/debug/named_tracing

## clean       Remove all build artifacts
clean:
	-alr exec -- gprclean -XMODE=release $(EX)
	-alr exec -- gprclean -XMODE=debug $(EX)
	alr clean

## help        List targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'
