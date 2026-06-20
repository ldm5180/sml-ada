package body Simple_Proof
  with SPARK_Mode
is

   use SM;

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   --!format off
   Table : constant Transition_Table :=
     [(Locked,   Coin, Always, Nothing, Unlocked),
      (Unlocked, Push, Always, Nothing, Locked)];
   --!format on

   --  As in Turnstile_Proof: Make's Post chains to Run's result, and
   --  Process_Event's body is proved free of run-time errors through the
   --  instantiation, so it need not be called by this function.
   function Run return State is
      M : constant Machine := Make (Table, Initial => Locked);
   begin
      return State_Of (M);
   end Run;

end Simple_Proof;
