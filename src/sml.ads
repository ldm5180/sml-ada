package Sml
  with Pure, SPARK_Mode
is

   --  The do-nothing default for cooperative-stop formals (Sml.Effects_Loop's
   --  Stop): a loop that wires nothing runs until quiescence alone ends it.
   function Never return Boolean
   is (False);

end Sml;
