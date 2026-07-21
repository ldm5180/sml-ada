--  The effects protocol's request block, defined once for every sml machine.
--  A machine's guards read its context; its actions write only *requests*
--  into it -- a command for the shell to run (Pending), or a tick to schedule
--  (Tick_Scheduled + Wait_For).  The runner (Sml.Effects_Loop) turns those
--  requests into IO and posts the resulting events back.  Every machine's
--  context carries the same three slots, so they live here as one generic
--  record instantiated over the machine's own Command enumeration.
--
--  Well_Formed is the house invariant, proved once and applied by each
--  machine that can honour it (as a Dynamic_Predicate over its context): a
--  command and a tick are never both pending -- the runner would have to
--  arbitrate -- and a scheduled tick always waits a real interval, so the
--  zero-wait busy loop is unrepresentable.  The Block type itself carries no
--  predicate: a machine may legitimately need the save-then-tick shape
--  (Pending AND Tick together), so it can reuse the fields without the
--  invariant.  The invariant's accepted and rejected shapes are anchored as
--  proved facts in Request_Block_Proof.

generic
   type Command is (<>);
   None : Command;
package Sml.Request_Block with SPARK_Mode is

   type Block is record
      Pending        : Command := None;
      Tick_Scheduled : Boolean := False;
      Wait_For       : Natural := 0;
   end record;

   --  A plain expression function, NOT Ghost: consumers may compile with
   --  -gnata, making a machine's Dynamic_Predicate a live runtime check,
   --  and a ghost function is not permitted in one.
   function Well_Formed (B : Block) return Boolean
   is (not (B.Pending /= None and then B.Tick_Scheduled)
       and then (if B.Tick_Scheduled then B.Wait_For > 0));

end Sml.Request_Block;
