package body Turnstile_Proof
  with SPARK_Mode
is

   use SM, D;

   --  The turnstile's only guard is "Always", so it ignores its inputs.
   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   Coin : constant Ev := (Kind => E_Coin);
   Push : constant Ev := (Kind => E_Push);

   --!format off
   Table : constant Transition_Table :=
     [Locked   + Coin >= Unlocked,
      Unlocked + Push >= Locked];
   --!format on

   --  Make's Post (State_Of (Make'Result) = Initial) chains to Run's result.
   --  Process_Event's body is proved free of run-time errors by virtue of the
   --  SM instantiation (gnatprove analyses the instance), so it need not be
   --  called here -- and calling it would oblige Run, a function, to handle the
   --  by-design Unhandled_Event (functions can't carry Exceptional_Cases).
   function Run return State is
      M : constant Machine := Make (Table, Initial => Locked);
   begin
      return State_Of (M);
   end Run;

end Turnstile_Proof;
