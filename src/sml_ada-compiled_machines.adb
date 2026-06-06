package body Sml_Ada.Compiled_Machines
  with SPARK_Mode
is

   function Make (Initial : State) return Machine
   is (Current => Initial);

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event) is
   begin
      Step (M.Current, Ctx, Evt);
   end Process_Event;

end Sml_Ada.Compiled_Machines;
