package body Sml.Machines.Composite
  with SPARK_Mode
is

   procedure Process
     (Parent : in out Machine; Ctx : in out Context; Evt : Event)
   is
      Handled : Boolean;
   begin
      Process_Child (Ctx, Evt, Handled);
      if not Handled then
         Process_Event (Parent, Ctx, Evt);
      end if;
   end Process;

end Sml.Machines.Composite;
