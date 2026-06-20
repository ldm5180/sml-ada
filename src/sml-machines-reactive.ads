--  Run-to-completion with internal events.  Some states emit a follow-on event
--  on entry (e.g. a "Dialing" state that immediately sends Connect); Reactive
--  feeds the outside event, then keeps processing each entered state's entry
--  event until one settles with none.  The chain is bounded by Max_Steps, so a
--  cyclic configuration stops instead of looping forever (and SPARK proves
--  termination).  Opt-in: existing machines are untouched.
--
--     package RC is new SM.Reactive
--       (Has_Entry_Event => Has_Entry_Event, Entry_Event => Entry_Event);
--     RC.Run_To_Completion (M, Ctx, Dial);   --  -> Dialing -> Connected

generic
   --  Upper bound on the entry-event chain after the initial event.
   Max_Steps : Positive := 16;
   --  Does state S emit an event on entry, and if so which one?
   with function Has_Entry_Event (S : State) return Boolean;
   with function Entry_Event (S : State) return Event;
package Sml.Machines.Reactive with SPARK_Mode is

   --  Process Evt, then process the entry event of each state entered, until a
   --  state has none or Max_Steps is reached.
   procedure Run_To_Completion
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   with Exceptional_Cases => (Unhandled_Event => True);

end Sml.Machines.Reactive;
