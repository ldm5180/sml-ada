pragma Ada_2022;

--  Demonstrates Sml.Machines.Deferring: a media player where Pause arrives too
--  early (while Stopped).  It is deferred, then re-delivered once Play moves the
--  player to Playing, settling at Paused.  Run it to see the queue fill and
--  drain; the pragma Asserts document each step.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Machines.Deferring;

procedure Deferred_Events is

   type State is (Stopped, Playing, Paused);
   type Event_Kind is (E_Play, E_Pause, E_Stop);

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

   --  Pause is deferred while Stopped; everything else unhandled is dropped.
   function Deferred (S : State; E : Event_Kind) return Boolean
   is (S = Stopped and then E = E_Pause);

   function Rebuild (E : Event_Kind) return Event
   is ((Kind => E));

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

   Play  : constant Ev := (Kind => E_Play);
   Pause : constant Ev := (Kind => E_Pause);
   Stop  : constant Ev := (Kind => E_Stop);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Stopped + Play  >= Playing,
      Playing + Pause >= Paused,
      Playing + Stop  >= Stopped,
      Paused  + Play  >= Playing,
      Paused  + Stop  >= Stopped];
   --!format on

   package Def is new SM.Deferring (Deferred => Deferred, Rebuild => Rebuild);

   M   : Machine := Make (Table, Initial => Stopped);
   Q   : Def.Deferral_Queue := Def.Empty_Queue;
   Ctx : Context;
begin
   Put_Line ("start:        " & State_Of (M)'Image);

   Def.Post (M, Q, Ctx, (Kind => E_Pause));
   Put_Line
     ("pause (early): "
      & State_Of (M)'Image
      & "  (deferred:"
      & Def.Pending (Q)'Image
      & ")");
   pragma Assert (State_Of (M) = Stopped and then Def.Pending (Q) = 1);

   Def.Post (M, Q, Ctx, (Kind => E_Play));
   Put_Line
     ("play:         "
      & State_Of (M)'Image
      & "  (deferred:"
      & Def.Pending (Q)'Image
      & ")");
   pragma Assert (State_Of (M) = Paused and then Def.Pending (Q) = 0);
end Deferred_Events;
