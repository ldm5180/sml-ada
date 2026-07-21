--  The effects-loop protocol, defined once: run the machine's pending
--  command, or sleep to the scheduled tick and post it, until the
--  machine is quiescent (or Max_Steps bounds the run, for tests).  Every
--  runner instantiates this over its own Command type and context
--  accessors, so the protocol cannot drift between machines -- guards
--  read the context, actions write requests (Sml.Request_Block), and
--  this loop is the one place requests become IO.

generic
   type Command is (<>);
   None : Command;

   --  Accessors over the machine context's request block.
   with function Pending return Command;
   with procedure Clear_Pending;
   with function Tick_Scheduled return Boolean;
   with procedure Clear_Tick;
   with function Wait_For return Natural;

   --  The effects.
   with procedure Dispatch (Next : Command);
   with procedure Sleep (Seconds : Natural);
   with procedure Tick;  --  post the machine's tick event

   --  Runs after every executed step (a summary cadence, say); defaults
   --  to nothing.
   with procedure After_Step is null;

   --  Checked once per iteration: True ends the loop even in the forever
   --  (Max_Steps = 0) mode.  Defaults to never -- wire it for cooperative
   --  shutdown.
   with function Stop return Boolean is Sml.Never;
procedure Sml.Effects_Loop (Max_Steps : Natural)
with SPARK_Mode;
