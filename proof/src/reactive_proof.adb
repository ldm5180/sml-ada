package body Reactive_Proof
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
     [(Idle,    E_Dial,    Always, Nothing, Dialing),
      (Dialing, E_Connect, Always, Nothing, Connected)];
   --!format on

   --  RC.Run_To_Completion's body is proved through the instantiation; Run only
   --  anchors Make's Post, since Run_To_Completion could raise by design.
   function Run return State is
      M : constant Machine := Make (Table, Initial => Idle);
   begin
      return State_Of (M);
   end Run;

end Reactive_Proof;
