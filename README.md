# SML/Ada

Declarative, low-overhead **state machines for Ada**, inspired by
[boost-ext/sml](https://github.com/boost-ext/sml). The goal is to describe a
machine as a table you can read top-to-bottom — the way a UML state chart reads —
while keeping the engine small, fast, and provable.

The example (`example/hello_world.adb`, a port of Boost.SML's TCP-teardown
example) is exactly this diagram:

![hello_world state machine](docs/hello_world.svg)

```ada
--  Each row reads:  From + Event (Guard) / Action >= To
Table : constant Transition_Table :=
  [Established + Release            / Send_Fin >= Fin_Wait_1,
   Fin_Wait_1  + Ack     (Is_Valid)            >= Fin_Wait_2,
   Fin_Wait_2  + Fin     (Is_Valid) / Send_Ack >= Timed_Wait,
   Timed_Wait  + Timeout                       >= Closed];
```

## Why this design

You can't reproduce Boost.SML's `src + event[guard] / action = dst` operator DSL
exactly in Ada (`=` must return `Boolean`, there is no user-definable `[]`, and
operator symbols are a fixed set) — but `Sml_Ada.Machines.Operators` gets close
with `+`, `(...)`, `/` and `>=`, because the *at-a-glance* quality of SML lives in the
row layout, not the exact operators. States and events are enumeration types,
transitions are a flat array (one row each), and guards and actions are **named**
rather than stored as subprogram pointers. Naming them keeps the table pure
data, lets the compiler inline the dispatch, makes the `case` arms
exhaustiveness-checked, and keeps the engine provable with SPARK.

`Sml_Ada.Machines` is the engine; `Sml_Ada.Machines.Operators` is the opt-in
operator layer that produces the rows above. The core operation is
`Process_Event` (matching Boost.SML's `process_event`).

## Operator notation

Instantiate the `Sml_Ada.Machines.Operators` child on your `Machines` instance,
naming the "always" guard and "do nothing" action used by rows that omit them:

```ada
package SM is new Sml_Ada.Machines (...);
package Op is new SM.Operators (Always => Always, Nothing => Nothing);
use SM, Op;

Release : constant Ev := (Kind => E_Release);   --  one wrapper per event
--  Ack, Fin, Timeout : likewise
```

A row built this way is just a `Transition`, so the table is an ordinary array
aggregate fed to the usual `Make` — no special container, and it stays in the
SPARK subset. (The engine also accepts plain tuple rows
`(Established, Release, Always, Send_Fin, Fin_Wait_1)` without these operators —
that's what the tests use.) Costs: a wrapper constant per event (its name
must differ from the `Event_Kind` literal, hence the `E_*` prefix), and `>=`
rather than SML's `=` for the target. The initial state is given to `Make`
(SML's `*`); a state with no outgoing row is terminal (SML's `X`).

### Guards & actions

`Guard_Kind` and `Action_Kind` are your own enumerations; you supply one
`Evaluate` and one `Execute` dispatcher mapping a name to its behaviour:

```ada
function Evaluate (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean is
  (case G is
      when Always   => True,
      when Is_Valid => ...);

procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);
```

`Context` is your *extended state* — whatever the guards read and the actions
modify (a counter, a buffer, …). Guards are read-only (`Ctx` is `in`); actions
may modify it (`in out`).

### Events with payloads

Events are a variant record; `Kind_Of` extracts the discrete tag the table
matches on:

```ada
type Event (Kind : Event_Kind := E_Timeout) is record
   case Kind is
      when E_Ack  => Ack_Valid : Boolean;
      when E_Fin  => Id : Integer; Fin_Valid : Boolean;
      when others => null;
   end case;
end record;
```

### Completeness & unhandled events

`Make` takes two policy knobs:

- `Complete => Total` makes `Make` reject a table that doesn't cover every
  `(State, Event_Kind)` (raising `Incomplete_Table`); `Partial` (default) allows
  gaps.
- `On_Unhandled` decides what `Process_Event` does when no row matches: `Stay`
  (default), `Raise_Error`, or `Go_To_Default`.

### Tracing (zero-overhead when off)

Instantiate with `Debug => True` and a `Trace` procedure to log, for every
event: the event kind, the current state, each guard tried and its result, the
action, and the resulting state. When `Debug` is `False` the trace calls —
*including building the message strings* — are statically eliminated, so
disabled tracing costs nothing. Build the example with tracing on to see it:

```console
$ alr exec -- gprbuild -XTRACE=on -P example/example.gpr && ./example/bin/hello_world
start: ESTABLISHED
[trace]event E_RELEASE in state ESTABLISHED
[trace]  guard ALWAYS => TRUE
[trace]  action SEND_FIN; ESTABLISHED -> FIN_WAIT_1
send: fin
...
final: CLOSED
```

### Formal verification (SPARK)

The engine is written in the SPARK subset. `proof/` instantiates the engine and
its operators for a turnstile and `gnatprove` verifies it: `Process_Event` is proved free of
run-time errors, and `Make`'s contract (`State_Of (Make'Result) = Initial`)
holds (`gnatprove` only analyses a generic through a concrete instance). `Make`'s
body is excluded from proof because its `Total`-completeness check raises
`Incomplete_Table` by design — that raise is part of its contract for callers.

## Generating an optimized machine

The table engine scans the transition table on every event — O(n) in the number
of transitions — and stores the table in each `Machine`. For hot paths you can
instead **generate** a specialized machine from the same definition.
`Sml_Ada.Machines.Codegen` reads a `Transition_Table` and emits a self-contained
package whose `Process_Event` is a `case` on the current state:

```ada
case M.Current is
   when ESTABLISHED =>
      if K = E_RELEASE and then Evaluate (ALWAYS, Ctx, Evt) then
         Execute (SEND_FIN, Ctx, Evt);
         M.Current := FIN_WAIT_1;
         return;
      end if;
   --  ... one arm per state ...
end case;
```

### Why generate

- **O(1) dispatch instead of O(n).** The `case` on the current state compiles to
  a jump table, so an event goes straight to its state's arm rather than scanning
  the whole table. At `-O2/-O3` GNAT dissolves the result to branches — no table,
  no scan, no indirect calls, and a `Machine` is just one enum. This is how the
  generated form reaches hand-written C++ Boost.SML performance.
- **Much less boilerplate.** You write only the definition — states, events,
  guards/actions, and the table
  (`example/generated/hello_world_def.ads`, ~40 lines). The generator writes
  `Make`, `State_Of`, `Process_Event`, and a Graphviz diagram, reusing your
  `Evaluate`/`Execute` so behaviour is never duplicated. Code and diagram both
  come from the one table, so they can't drift.

### How to generate and build the binary

The generated example lives in `example/generated/`. The generated sources are
**not** committed — producing them is the whole point — so it is a two-phase
build: run the generator, then compile the consumer against what it emitted.

```console
# 1. build & run the generator -> emits hello_world_compiled.{ads,adb} + .dot
alr exec -- gprbuild -P example/generated/generated.gpr generate.adb
(cd example/generated && bin/generate)

# 2. build & run the consumer of the generated machine
alr exec -- gprbuild -P example/generated/generated.gpr run.adb
./example/generated/bin/run        # start: ESTABLISHED ... final: CLOSED
```

The only file you edit is `hello_world_def.ads`; re-run step 1 whenever it
changes.

## Building, testing, proving, formatting

```console
alr build                                   # build the library
alr test                                    # build + run the AUnit suite
alr exec -- gnatprove -P proof/proof.gpr    # run the SPARK proof
alr exec -- gprbuild -P example/example.gpr && ./example/bin/hello_world
gnatformat --check src/*.ad? tests/src/*.ad? example/src/*.ad? proof/src/*.ad?
```

Transition tables are wrapped in `--!format off`/`--!format on` so `gnatformat`
keeps their hand-aligned columns.

## Layout

```
src/      sml_ada.ads, sml_ada-machines.{ads,adb}, sml_ada-machines-operators.ads,
          sml_ada-machines-codegen.{ads,adb} (the generator)
tests/    AUnit suite (test_sml_ada.gpr)
proof/    SPARK proof target (proof.gpr)
example/  hello_world.adb + TRACE on/off config (example.gpr)
example/generated/  definition + generator + generated machine (generated.gpr)
docs/     hello_world.dot/.svg (state diagram)
```

## Requirements

GNAT + `gprbuild` (via Alire); the crate compiles as **Ada 2022**. The test
suite needs `aunit`; the proof needs `gnatprove`. The diagram in `docs/` is
rendered with Graphviz (`dot`).
