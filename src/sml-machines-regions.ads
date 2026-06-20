--  Orthogonal regions: several machines of one instance that all react to
--  the same event (N independent connections, or a composite state's
--  concurrent sub-regions).  Broadcast feeds one event to every region in
--  turn against the shared Context.  Heterogeneous regions (genuinely
--  different machines) are composed by hand -- just call each one's
--  Process_Event.
--
--  Machine is discriminated by its table length, so an array of regions fixes
--  that length as the generic's Count (= the rows' Table'Length):
--
--     package Reg is new SM.Regions (Count => Table'Length);
--     R : Reg.Region_Array := [Make (Table, Off), Make (Table, On)];
--     Reg.Broadcast (R, Ctx, Toggle);   --  both regions step

generic
   Count : Natural;
package Sml.Machines.Regions with SPARK_Mode is

   subtype Region is Machine (Count);
   type Region_Array is array (Positive range <>) of Region;

   --  Feed one event to every region, in order, against the shared Context.
   procedure Broadcast
     (Regions : in out Region_Array; Ctx : in out Context; Evt : Event)
   with Exceptional_Cases => (Unhandled_Event => True);

   --  True when every region is in state S (vacuously true for none).
   function All_In (Regions : Region_Array; S : State) return Boolean
   is (for all R of Regions => State_Of (R) = S);

end Sml.Machines.Regions;
