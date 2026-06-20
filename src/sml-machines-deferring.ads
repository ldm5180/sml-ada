--  Deferred events: an event a state can't (or shouldn't) handle yet is queued
--  and re-tried after the next handled event.  Because Event is indefinite,
--  the queue holds event KINDS, not full payloads; Rebuild turns a kind back
--  into an event for re-delivery (exact for payload-free machines).  Capacity
--  bounds the queue -- overflow raises Deferral_Overflow -- so it stays
--  SPARK-provable.
--
--     package Def is new SM.Deferring
--       (Deferred => Deferred, Rebuild => Rebuild);
--     Q : Def.Deferral_Queue := Def.Empty_Queue;
--     Def.Post (M, Q, Ctx, Evt);   --  M and Q are the user's own variables

generic
   Capacity : Positive := 8;
   --  Should event E be deferred (queued) when it is unhandled in state S?
   with function Deferred (S : State; E : Event_Kind) return Boolean;
   --  Rebuild an event from its kind, for re-delivering a deferred one.
   with function Rebuild (E : Event_Kind) return Event;
package Sml.Machines.Deferring with SPARK_Mode is

   Deferral_Overflow : exception;

   type Deferral_Queue is private;
   Empty_Queue : constant Deferral_Queue;

   function Pending (Q : Deferral_Queue) return Natural;

   --  Process Evt; if it was handled, re-deliver the queue (handled deferrals
   --  drop out); if it was unhandled and Deferred there, queue it (raising
   --  Deferral_Overflow when the queue is full).
   procedure Post
     (M   : in out Machine;
      Q   : in out Deferral_Queue;
      Ctx : in out Context;
      Evt : Event)
   with Exceptional_Cases => (Deferral_Overflow => True);

private

   subtype Count_Of is Natural range 0 .. Capacity;
   type Kind_Buffer is array (1 .. Capacity) of Event_Kind;

   type Deferral_Queue is record
      Items : Kind_Buffer := [others => Event_Kind'First];
      Len   : Count_Of := 0;
   end record;

   Empty_Queue : constant Deferral_Queue :=
     (Items => [others => Event_Kind'First], Len => 0);

   function Pending (Q : Deferral_Queue) return Natural
   is (Q.Len);

end Sml.Machines.Deferring;
