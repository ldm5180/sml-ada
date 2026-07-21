--  Level-gated Sml.Tracing: the four On_* hooks, each a no-op unless
--  Enabled returns True.  Sml.Tracing formats its line eagerly (before
--  a log level could discard it), so on a hot path an ungated hook
--  would build one throwaway string per event.  Gating it here -- once
--  -- is the guard every runner used to hand-write four times apiece;
--  wire these straight into the machine instantiation.

generic
   type State is (<>);
   type Event_Kind is (<>);
   type Guard_Kind is (<>);
   type Action_Kind is (<>);
   Name : String := "";
   Always : Guard_Kind;
   Nothing : Action_Kind;
   with procedure Put_Line (Item : String);
   with function Enabled return Boolean;
package Sml.Trace_Gate with SPARK_Mode is

   procedure On_Event (Evt : Event_Kind; From : State);
   procedure On_Guard (Guard : Guard_Kind; Passed : Boolean);
   procedure On_Action (Action : Action_Kind; From, To : State);
   procedure On_Unhandled (Evt : Event_Kind; From : State);

end Sml.Trace_Gate;
