package body Sml.Machines.Reactive
  with SPARK_Mode
is

   procedure Run_To_Completion
     (M : in out Machine; Ctx : in out Context; Evt : Event) is
   begin
      Process_Event (M, Ctx, Evt);
      for Step in 1 .. Max_Steps loop
         declare
            S : constant State := State_Of (M);
         begin
            exit when not Has_Entry_Event (S);
            Process_Event (M, Ctx, Entry_Event (S));
         end;
      end loop;
   end Run_To_Completion;

end Sml.Machines.Reactive;
