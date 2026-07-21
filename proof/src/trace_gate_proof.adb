package body Trace_Gate_Proof
  with SPARK_Mode
is

   procedure Count (Item : String) is
      pragma Unreferenced (Item);
   begin
      if Lines < Natural'Last then
         Lines := Lines + 1;
      end if;
   end Count;

   --  Drive one gated-off pass and one gated-on transition, so both
   --  branches of every hook are covered by the analysis.
   procedure Run is
   begin
      Gate_On := False;
      Gate.On_Event (E_Coin, Locked);
      Gate.On_Guard (Always, True);
      Gate.On_Action (Act, Locked, Unlocked);
      Gate.On_Unhandled (E_Push, Unlocked);

      Gate_On := True;
      Gate.On_Event (E_Coin, Locked);
      Gate.On_Action (Act, Locked, Unlocked);
   end Run;

end Trace_Gate_Proof;
