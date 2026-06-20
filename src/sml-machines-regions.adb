package body Sml.Machines.Regions
  with SPARK_Mode
is

   procedure Broadcast
     (Regions : in out Region_Array; Ctx : in out Context; Evt : Event) is
   begin
      for I in Regions'Range loop
         Process_Event (Regions (I), Ctx, Evt);
      end loop;
   end Broadcast;

end Sml.Machines.Regions;
