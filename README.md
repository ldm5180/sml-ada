# SML/Ada

Declarative, low-overhead **state machines for Ada**, inspired by
[boost-ext/sml](https://github.com/boost-ext/sml). The goal is to describe a
machine as a table you can read top-to-bottom — the way a UML state chart reads —
while pushing as much work as possible to compile time so the generated code
stays small and fast.

The example below (`example/hello_world.adb`, a port of Boost.SML's TCP-teardown
example) is exactly this diagram:

![hello_world state machine](docs/hello_world.svg)

```ada
--  Read each row in Boost.SML / UML notation:  From + On [Guard] / Action = To
--     From         On       Guard     Action    To
Table : constant Transition_Table :=
  [(Established, Release, Always,   Send_Fin, Fin_Wait_1),
   (Fin_Wait_1,  Ack,     Is_Valid, Nothing,  Fin_Wait_2),
   (Fin_Wait_2,  Fin,     Is_Valid, Send_Ack, Timed_Wait),
   (Timed_Wait,  Timeout, Always,   Nothing,  Closed)];
```

## Why this design

You can't reproduce Boost.SML's `src + event[guard] / action = dst` operator DSL
in Ada (`=` must return `Boolean`, there is no user-definable `[]`, and operator
symbols are a fixed set). But the *at-a-glance* quality of SML lives in the table
layout, not the operators — and that ports cleanly. So states and events are
enumeration types, transitions are a flat array (one row each), and guards and
actions are **named** rather than stored as subprogram pointers. Naming them
keeps the table pure data, lets the compiler inline the dispatch, makes the
`case` arms exhaustiveness-checked, and keeps the engine provable with SPARK.

## Layers

| Unit | Use it when | Notes |
|------|-------------|-------|
| `Sml_Ada.State_Machines` | plain state graph, no guards/actions | tiny; a `Machine` is one enum; **formally proven** (see `proof/`) |
| `Sml_Ada.Machines` | guards, actions, payload-carrying events | the layer shown above |
| `Sml_Ada.Machines.Indexed` | same table as `Machines`, O(1) dispatch | precomputed `(State, Event_Kind)` lookup; one transition per cell |
| `Sml_Ada.Compiled_Machines` | max performance; transition written as code | a `Machine` is one enum; dispatch dissolves to branches at `-O2/-O3` |

The core operation is `Process_Event` (matching Boost.SML's `process_event`).

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
type Event (Kind : Event_Kind := Timeout) is record
   case Kind is
      when Ack    => Ack_Valid : Boolean;
      when Fin    => Id : Integer; Fin_Valid : Boolean;
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
event: the current state, each guard tried and its result, the action, and the
resulting state. When `Debug` is `False` the trace calls — *including building
the message strings* — are statically eliminated, so disabled tracing costs
nothing. Build the example with tracing on to see it:

```console
$ alr exec -- gprbuild -XTRACE=on -P example/example.gpr && ./example/bin/hello_world
start: ESTABLISHED
[trace]event RELEASE in state ESTABLISHED
[trace]  guard ALWAYS => TRUE
[trace]  action SEND_FIN; ESTABLISHED -> FIN_WAIT_1
send: fin
...
final: CLOSED
```

### Optional operator DSL

For a Boost.SML-style reading, instantiate the `Sml_Ada.Machines.Dsl` child and
write each row as `From + Event (Guard) / Action >= To`:

```ada
package D is new SM.Dsl (Always => Always, Nothing => Nothing);
use SM, D;

Release : constant Ev := (Kind => E_Release);   --  one wrapper per event
--  Ack, Fin, Timeout : likewise

Table : constant Transition_Table :=
  [Established + Release            / Send_Fin >= Fin_Wait_1,
   Fin_Wait_1  + Ack     (Is_Valid)            >= Fin_Wait_2,
   Fin_Wait_2  + Fin     (Is_Valid) / Send_Ack >= Timed_Wait,
   Timed_Wait  + Timeout                       >= Closed];
```

A row is just a `Transition`, so the table is an ordinary array aggregate fed to
the usual `Make` — it stays in the SPARK subset and needs only GNAT 14+ (the
project itself builds with the current toolchain, GNAT 15.2). Costs: a
wrapper constant per event (its name must differ from the `Event_Kind` literal,
hence the `E_*` prefix), and `>=` rather than SML's `=` for the target. See
`example/hello_world_dsl.adb` versus the plain-table `example/hello_world.adb`.

### Compiled layer (dissolved dispatch)

When you need Boost.SML-style codegen, `Sml_Ada.Compiled_Machines` takes the
transition as a `Step` procedure — guards are `if`s, actions are inline
statements, the next state is an assignment:

```ada
procedure Step (Current : in out State; Ctx : in out Context; Evt : Event) is
begin
   case Current is
      when Established =>
         if Evt.Kind = Release then Send_Fin; Current := Fin_Wait_1; end if;
      --  ...
   end case;
end Step;

package SM is new Sml_Ada.Compiled_Machines (State, Event, Context, Step);
M : Machine := Make (Established);
```

`Process_Event` just calls `Step`, which GNAT inlines at `-O2/-O3` to a branch
sequence — no transition table, no scan, no indirect calls, and a `Machine` is
one enum. (Checked in the generated assembly: the dispatch becomes compares + a
jump, with zero `call`/`loop`.) The trade is you give up the at-a-glance table.
See `example/hello_world_compiled.adb`.

### O(1) dispatch (indexed)

`Sml_Ada.Machines.Indexed` takes the *same* table but has `Make` precompute a
`(State, Event_Kind) -> row` lookup, so `Process_Event` is one indexed read
rather than an O(N) scan. Instantiate it on your `Machines` instance:

```ada
package SMI is new SM.Indexed;
M : SMI.Machine := SMI.Make (Table, Initial => Established);
```

It requires at most one transition per `(State, Event_Kind)` cell (`Make` raises
`Duplicate_Transition` otherwise). Keeps the readable table and stays in SPARK.

### Generating the compiled form (and a diagram)

You don't have to hand-write the compiled machine. `Sml_Ada.Machines.Codegen`
reads a transition table — the single source of truth — and emits it.
Instantiate it on your `Machines` instance and drive it from a small generator
program (see `tools/`):

```ada
package Cg is new My_Defs.SM.Codegen;
Cg.Put_Compiled_Spec (Spec_File, Defs_Unit => "My_Defs", Unit => "My_Compiled");
Cg.Put_Compiled_Body (Body_File, My_Defs.Table, "My_Defs", "My_Compiled");
Cg.Put_Dot           (Dot_File,  My_Defs.Table, My_Defs.Initial, "my_machine");
```

The emitted `Process_Event` is a baked `case` (no scan) that calls your existing
`Evaluate`/`Execute`, so the behaviour isn't duplicated and the dispatch
dissolves to branches at `-O2/-O3`. The Graphviz diagram is generated from the
very same table, so code and picture can't drift.

The generator only consumes the `Transition_Table` (plus `Initial` for the
diagram); how you *build* that table is up to you. `tools/` carries two demos of
the same TCP-teardown machine: `tcp_*` defines the table inline, while `hw_*`
defines it with the operator DSL (`From + Event (Guard) / Action >= To`) and
feeds the resulting table to the same generator — DSL and codegen compose
because a DSL row is just a `Transition`.

### Formal verification (SPARK)

The whole engine is written in the SPARK subset. `proof/` instantiates Layer 0
and `gnatprove` verifies it has no run-time errors and that the `Make` /
`Process_Event` contracts hold (`gnatprove` only analyses a generic through a
concrete instance).

## Building, testing, proving, formatting

```console
alr build                                   # build the library
alr test                                    # build + run the AUnit suite
alr exec -- gnatprove -P proof/proof.gpr    # run the SPARK proofs
alr exec -- gprbuild -P example/example.gpr && ./example/bin/hello_world
gnatformat --check src/*.ad? tests/src/*.ad? example/src/*.ad? proof/src/*.ad?
```

Transition tables are wrapped in `--!format off`/`--!format on` so `gnatformat`
keeps their hand-aligned columns.

## Layout

```
src/      sml_ada.ads, sml_ada-state_machines.{ads,adb}, sml_ada-machines.{ads,adb}
tests/    AUnit suite (test_sml_ada.gpr)
proof/    SPARK proof target (proof.gpr)
example/  hello_world.adb + TRACE on/off config (example.gpr)
docs/     hello_world.dot/.svg (state diagram)
```

## Requirements

GNAT + `gprbuild` (via Alire); the crate compiles as **Ada 2022**. The test suite needs `aunit`; the proofs need
`gnatprove`; the diagram is generated with Graphviz (`dot`).
