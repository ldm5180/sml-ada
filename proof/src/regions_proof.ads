pragma Ada_2022;

--  A concrete Sml.Machines.Regions instance so gnatprove verifies the broadcast
--  layer: Broadcast and All_In are proved free of run-time errors, and
--  Broadcast is proved to propagate only Unhandled_Event.  (As elsewhere, a
--  proof function does not call Broadcast, since it could raise by design.)

with Sml.Machines;
with Sml.Machines.Regions;

package Regions_Proof
  with SPARK_Mode
is

   type State is (Off, On);
   type Event_Kind is (E_Toggle);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

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

   package Reg is new SM.Regions (Count => 2);

   --  An empty region set is vacuously all-Off; exercises All_In without
   --  constructing a machine (whose discriminant check is not the point here).
   function Run return Boolean
   with Post => Run'Result;

end Regions_Proof;
