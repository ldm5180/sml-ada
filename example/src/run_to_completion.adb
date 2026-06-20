pragma Ada_2022;

--  Demonstrates Sml.Machines.Reactive: a phone whose Dialing state emits a
--  Connect event on entry, so one outside Dial event runs to completion all the
--  way to Connected.  Run it to see the single Dial settle two states forward.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Machines.Reactive;

procedure Run_To_Completion is

   type State is (Idle, Dialing, Connected);
   type Event_Kind is (E_Dial, E_Connect);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   --  Dialing settles itself by emitting Connect on entry.
   function Has_Entry_Event (S : State) return Boolean
   is (S = Dialing);

   function Entry_Event (S : State) return Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Connect);
   end Entry_Event;

   package SM is new
     Sml.Machines
       (State       => State,
        Event_Kind  => Event_Kind,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);
   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   Dial    : constant Ev := (Kind => E_Dial);
   Connect : constant Ev := (Kind => E_Connect);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Idle    + Dial    >= Dialing,
      Dialing + Connect >= Connected];
   --!format on

   package RC is new
     SM.Reactive
       (Has_Entry_Event => Has_Entry_Event,
        Entry_Event     => Entry_Event);

   M   : Machine := Make (Table, Initial => Idle);
   Ctx : Context;
begin
   Put_Line ("start:                 " & State_Of (M)'Image);

   --  One Dial, run to completion: Idle -> Dialing -> (entry) -> Connected.
   RC.Run_To_Completion (M, Ctx, (Kind => E_Dial));
   Put_Line ("after Dial (complete): " & State_Of (M)'Image);
   pragma Assert (State_Of (M) = Connected);
end Run_To_Completion;
