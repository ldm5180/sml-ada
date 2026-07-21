--  A concrete Sml.Request_Block instance so gnatprove verifies the layer,
--  plus the invariant's accepted and rejected shapes anchored as proved
--  facts -- carrying what a unit test would otherwise assert: a command
--  alone is fine, a tick with a real wait is fine, but a zero-wait tick
--  (a busy loop) and a command-plus-tick (the runner would have to
--  arbitrate) are both rejected.

with Sml.Request_Block;

package Request_Block_Proof
  with SPARK_Mode
is

   type Command is (None, Do_Work);

   package Req is new Sml.Request_Block (Command, None);

   Default_Block : constant Req.Block := (others => <>);

   function Invariant_Holds return Boolean
   is (Req.Well_Formed (Default_Block)
       and then Req.Well_Formed
                  ((Pending        => Do_Work,
                    Tick_Scheduled => False,
                    Wait_For       => 0))
       and then Req.Well_Formed
                  ((Pending => None, Tick_Scheduled => True, Wait_For => 5))
       and then not Req.Well_Formed
                      ((Pending        => None,
                        Tick_Scheduled => True,
                        Wait_For       => 0))
       and then not Req.Well_Formed
                      ((Pending        => Do_Work,
                        Tick_Scheduled => True,
                        Wait_For       => 5)))
   with Post => Invariant_Holds'Result;

end Request_Block_Proof;
