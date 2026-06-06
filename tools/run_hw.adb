--  THE THING YOU AUTHOR (3/3): the consumer.  Same driving code as
--  example/hello_world.adb -- but Make/State_Of/Process_Event come from the
--  GENERATED Hw_Compiled, whose Process_Event is a baked `case` that GNAT
--  dissolves to branches at -O2/-O3 (no table, no scan, no indirect calls).

with Ada.Text_IO; use Ada.Text_IO;

with Hw_Defs;     use Hw_Defs;
with Hw_Compiled; use Hw_Compiled;

procedure Run_Hw is
   M   : Machine := Make (Initial);
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => E_Release));
   Process_Event (M, Ctx, (Kind => E_Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Run_Hw;
