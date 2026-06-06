package body Sml_Ada.State_Machines is

   ----------
   -- Make --
   ----------

   function Make return Machine
   is (Current => Initial);

   ----------
   -- Fire --
   ----------

   procedure Fire (M : in out Machine; On : Event) is
   begin
      M.Current := Next (M.Current, On);
   end Fire;

end Sml_Ada.State_Machines;
