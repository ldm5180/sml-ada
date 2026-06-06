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

## Two layers

| Unit | Use it when | Notes |
|------|-------------|-------|
| `Sml_Ada.State_Machines` | plain state graph, no guards/actions | tiny; a `Machine` is one enum; **formally proven** (see `proof/`) |
| `Sml_Ada.Machines` | guards, actions, payload-carrying events | the layer shown above |

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

GNAT + `gprbuild` (via Alire). The test suite needs `aunit`; the proofs need
`gnatprove`; the diagram is generated with Graphviz (`dot`).
