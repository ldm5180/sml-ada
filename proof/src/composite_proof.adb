package body Composite_Proof
  with SPARK_Mode
is

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure No_Child
     (Ctx : in out Context; Evt : Event; Handled : out Boolean)
   is
      pragma Unreferenced (Ctx, Evt);
   begin
      Handled := False;
   end No_Child;

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Off, E_Power, Always, Nothing, On),
      (On,  E_Power, Always, Nothing, Off)];
   --!format on

   function Run return State is
      M : constant Machine := Make (Table, Initial => Off);
   begin
      return State_Of (M);
   end Run;

end Composite_Proof;
