--  Whole-program driver, mirroring Boost.SML's hello_world main: a baked event
--  sequence with an assertion on the state after each step (the C++ uses
--  assert(sm.is(...))).  There are no runtime inputs, so at -O3 with cross-unit
--  inlining (-gnatn) GNAT dissolves the machine entirely -- Process_Event, the
--  guards and the actions all fold away -- leaving only the action side effects,
--  exactly like the optimized C++ main.  The only output is what the actions
--  print.

with Hello_World_Defs;    use Hello_World_Defs;
with Hello_World_Logic;   use Hello_World_Logic;
with Hello_World_Machine; use Hello_World_Machine;

procedure Run is
   M   : Machine := Make;             --  initial state: Established
   Ctx : Context := (null record);
begin
   pragma Assert (State_Of (M) = Established);

   Process_Event (M, Ctx, (Kind => Release));
   pragma Assert (State_Of (M) = Fin_Wait_1);

   Process_Event (M, Ctx, (Kind => Ack, Ack_Valid => True));
   pragma Assert (State_Of (M) = Fin_Wait_2);

   Process_Event (M, Ctx, (Kind => Fin, Id => 42, Fin_Valid => True));
   pragma Assert (State_Of (M) = Timed_Wait);

   Process_Event (M, Ctx, (Kind => Timeout));
   pragma Assert (State_Of (M) = Closed);   --  terminated
end Run;
