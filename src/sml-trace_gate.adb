with Sml.Tracing;

package body Sml.Trace_Gate
  with SPARK_Mode
is

   package Trace is new
     Sml.Tracing
       (State       => State,
        Event_Kind  => Event_Kind,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Name        => Name,
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Put_Line);

   procedure On_Event (Evt : Event_Kind; From : State) is
   begin
      if Enabled then
         Trace.On_Event (Evt, From);
      end if;
   end On_Event;

   procedure On_Guard (Guard : Guard_Kind; Passed : Boolean) is
   begin
      if Enabled then
         Trace.On_Guard (Guard, Passed);
      end if;
   end On_Guard;

   procedure On_Action (Action : Action_Kind; From, To : State) is
   begin
      if Enabled then
         Trace.On_Action (Action, From, To);
      end if;
   end On_Action;

   procedure On_Unhandled (Evt : Event_Kind; From : State) is
   begin
      if Enabled then
         Trace.On_Unhandled (Evt, From);
      end if;
   end On_Unhandled;

end Sml.Trace_Gate;
