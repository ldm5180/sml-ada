package body Sml_Ada.State_Machines is

   function Make return Machine is (Current => Initial);

   procedure Process_Event (M : in out Machine; On : Event) is
   begin
      M.Current := Next (M.Current, On);
   end Process_Event;

end Sml_Ada.State_Machines;
