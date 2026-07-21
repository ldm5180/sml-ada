procedure Sml.Effects_Loop (Max_Steps : Natural) with SPARK_Mode is

   --  Run the machine's next request, or sleep to the next tick;
   --  Progressed False once the machine is quiescent (nothing pending
   --  or scheduled).
   procedure Advance (Progressed : out Boolean) is
   begin
      if Pending /= None then
         declare
            Next : constant Command := Pending;
         begin
            Clear_Pending;
            Dispatch (Next);
         end;
         Progressed := True;
      elsif Tick_Scheduled then
         Clear_Tick;
         Sleep (Wait_For);
         Tick;
         Progressed := True;
      else
         Progressed := False;
      end if;
   end Advance;

   Steps      : Natural := 0;
   Progressed : Boolean;

begin
   loop
      --  Steps counts only in the bounded mode: at the increment it is
      --  strictly below Max_Steps, so the counter can never overflow --
      --  and the forever mode never counts at all.
      if Max_Steps /= 0 then
         exit when Steps >= Max_Steps;
         Steps := Steps + 1;
      end if;
      exit when Stop;  --  cooperative shutdown, even in forever mode
      Advance (Progressed);
      exit when not Progressed;
      After_Step;
   end loop;
end Sml.Effects_Loop;
