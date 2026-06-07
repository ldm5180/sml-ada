--  Drives the GENERATED machine.  Make/State_Of/Process_Event come from the
--  generated Hello_World_Machine, whose Process_Event is a jump-table `case`
--  on the current state (O(1) dispatch) that GNAT dissolves to branches at
--  -O2/-O3 -- no transition table, no scan.  Make defaults to the spec's
--  initial state.

with Ada.Text_IO;         use Ada.Text_IO;

with Hello_World_Defs;    use Hello_World_Defs;
with Hello_World_Logic;   use Hello_World_Logic;
with Hello_World_Machine; use Hello_World_Machine;

procedure Run is
   M   : Machine := Make;
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => Release));
   Process_Event (M, Ctx, (Kind => Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Run;
