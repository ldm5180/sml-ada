with AUnit.Assertions; use AUnit.Assertions;

with Sml.Effects_Loop;

package body Sml_Effects_Loop_Tests is

   use AUnit.Test_Cases.Registration;

   --  A minimal machine context standing in for a runner's: the
   --  driver's whole contract is visible through it -- run the pending
   --  command, or sleep to the scheduled tick and post it, until
   --  quiescent (or Max_Steps / Stop bound the run).
   type Command is (None, Do_Work);

   Pending_Now    : Command := None;
   Tick_Now       : Boolean := False;
   Wait_Now       : Natural := 0;
   Dispatches     : Natural := 0;
   Ticks          : Natural := 0;
   Slept          : Natural := 0;
   Stop_After     : Natural := Natural'Last;  --  Stop trips at N checks
   Stop_Checks    : Natural := 0;
   Refill_Pending : Boolean := False;         --  Dispatch re-requests work

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

   procedure Dispatch (Next : Command) is
   begin
      if Next = Do_Work then
         Dispatches := Dispatches + 1;
         if Refill_Pending then
            Pending_Now := Do_Work;  --  an action requesting more work

         end if;
      end if;
   end Dispatch;

   procedure Sleep (Seconds : Natural) is
   begin
      Slept := Slept + Seconds;
   end Sleep;

   procedure Tick is
   begin
      Ticks := Ticks + 1;
   end Tick;

   function Stop return Boolean is
   begin
      Stop_Checks := Stop_Checks + 1;
      return Stop_Checks > Stop_After;
   end Stop;

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
        Tick           => Tick,
        Stop           => Stop);

   procedure Reset is
   begin
      Pending_Now := None;
      Tick_Now := False;
      Wait_Now := 0;
      Dispatches := 0;
      Ticks := 0;
      Slept := 0;
      Stop_After := Natural'Last;
      Stop_Checks := 0;
      Refill_Pending := False;
   end Reset;

   --  One pending command is dispatched exactly once, then the machine
   --  is quiescent and the loop returns on its own.
   procedure Test_Pending_Then_Quiescent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Reset;
      Pending_Now := Do_Work;
      Drive (Max_Steps => 0);
      Assert (Dispatches = 1, "the pending command ran exactly once");
      Assert (Ticks = 0 and then Slept = 0, "no tick was scheduled");
   end Test_Pending_Then_Quiescent;

   --  A scheduled tick sleeps its wait and posts the tick event.
   procedure Test_Tick_Sleeps_And_Posts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Reset;
      Tick_Now := True;
      Wait_Now := 3;
      Drive (Max_Steps => 0);
      Assert (Slept = 3, "the loop slept the scheduled wait");
      Assert (Ticks = 1, "and posted the tick");
   end Test_Tick_Sleeps_And_Posts;

   --  Max_Steps bounds a machine that never goes quiescent (each
   --  dispatch re-requests work) -- the tests-only escape hatch.
   procedure Test_Max_Steps_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Reset;
      Refill_Pending := True;
      Pending_Now := Do_Work;
      Drive (Max_Steps => 5);
      Assert
        (Dispatches = 5, "Max_Steps bounds the run; got" & Dispatches'Image);
   end Test_Max_Steps_Bounds;

   --  Stop ends even the forever (Max_Steps = 0) mode -- the cooperative
   --  shutdown path.
   procedure Test_Stop_Ends_Forever_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Reset;
      Refill_Pending := True;
      Pending_Now := Do_Work;
      Stop_After := 3;
      Drive (Max_Steps => 0);
      Assert
        (Dispatches <= 4,
         "Stop ended the forever mode; got" & Dispatches'Image);
   end Test_Stop_Ends_Forever_Mode;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Pending_Then_Quiescent'Access,
         "a pending command runs once, then quiescence returns");
      Register_Routine
        (T,
         Test_Tick_Sleeps_And_Posts'Access,
         "a scheduled tick sleeps its wait and posts");
      Register_Routine
        (T, Test_Max_Steps_Bounds'Access, "Max_Steps bounds a busy machine");
      Register_Routine
        (T,
         Test_Stop_Ends_Forever_Mode'Access,
         "Stop ends the forever mode (cooperative shutdown)");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String
   is (AUnit.Format ("Sml.Effects_Loop (the machine driver)"));

end Sml_Effects_Loop_Tests;
