with Sml.Effects_Loop;

package body Effects_Loop_Proof
  with SPARK_Mode
is

   Pending_Now : Command := None;
   Tick_Now    : Boolean := False;
   Wait_Now    : Natural := 0;
   Work        : Natural := 0;
   Slept       : Natural := 0;

   function Pending return Command
   is (Pending_Now);

   procedure Clear_Pending is
   begin
      Pending_Now := None;
   end Clear_Pending;

   function Tick_Scheduled return Boolean
   is (Tick_Now);

   procedure Clear_Tick is
   begin
      Tick_Now := False;
   end Clear_Tick;

   function Wait_For return Natural
   is (Wait_Now);

   --  Saturating sinks, as in Tracing_Proof's Count: the proof is about
   --  the driver, but null effects would leave it with nothing to do.
   procedure Dispatch (Next : Command) is
   begin
      if Next = Do_Work and then Work < Natural'Last then
         Work := Work + 1;
      end if;
   end Dispatch;

   procedure Sleep (Seconds : Natural) is
   begin
      if Slept < Natural'Last - Seconds then
         Slept := Slept + Seconds;
      else
         Slept := Natural'Last;
      end if;
   end Sleep;

   procedure Tick is
   begin
      Pending_Now := Do_Work;  --  the posted tick event requests work
   end Tick;

   procedure Drive is new
     Sml.Effects_Loop
       (Command        => Command,
        None           => None,
        Pending        => Pending,
        Clear_Pending  => Clear_Pending,
        Tick_Scheduled => Tick_Scheduled,
        Clear_Tick     => Clear_Tick,
        Wait_For       => Wait_For,
        Dispatch       => Dispatch,
        Sleep          => Sleep,
        Tick           => Tick);

   procedure Run is
   begin
      Pending_Now := None;
      Tick_Now := True;
      Wait_Now := 3;
      Drive (Max_Steps => 8);
   end Run;

end Effects_Loop_Proof;
