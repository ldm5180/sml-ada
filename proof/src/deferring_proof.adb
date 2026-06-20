package body Deferring_Proof
  with SPARK_Mode
is

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Stopped, E_Play,  Always, Nothing, Playing),
      (Playing, E_Pause, Always, Nothing, Paused),
      (Playing, E_Stop,  Always, Nothing, Stopped),
      (Paused,  E_Play,  Always, Nothing, Playing),
      (Paused,  E_Stop,  Always, Nothing, Stopped)];
   --!format on

   function Run return State is
      M : constant Machine := Make (Table, Initial => Stopped);
   begin
      return State_Of (M);
   end Run;

end Deferring_Proof;
