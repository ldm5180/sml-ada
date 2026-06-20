pragma Ada_2022;

--  Demonstrates Sml.Simple_Machines: a turnstile whose Coin/Push events carry
--  no payload, so there is no variant record and no Kind_Of to write -- you
--  instantiate with the event enumeration directly.  The table uses the same
--  operator notation as the full engine, via the inner Engine's Operators.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Simple_Machines;
with Sml.Machines.Operators;

procedure Simple_Turnstile is

   type State is (Locked, Unlocked);
   --  E_-prefixed so the operator wrappers below can be Coin/Push.
   type Event is (E_Coin, E_Push);

   --  Extended state: how many coins the turnstile has taken.
   type Context is record
      Coins : Natural := 0;
   end record;

   type Guard_Kind is (Always);
   type Action_Kind is (Nothing, Take_Coin);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Evt);
   begin
      case A is
         when Nothing   =>
            null;

         when Take_Coin =>
            Ctx.Coins := Ctx.Coins + 1;
      end case;
   end Execute;

   package M is new
     Sml.Simple_Machines
       (State       => State,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute);

   --  Operators come from the underlying engine instance.
   package Op is new M.Engine.Operators (Always => Always, Nothing => Nothing);
   use M, Op;

   Coin : constant Ev := (Kind => E_Coin);
   Push : constant Ev := (Kind => E_Push);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Locked   + Coin / Take_Coin >= Unlocked,
      Unlocked + Push             >= Locked];
   --!format on

   M_Inst : Machine := Make (Table, Initial => Locked);
   Ctx    : Context;
begin
   Put_Line ("start:  " & State_Of (M_Inst)'Image);
   pragma Assert (State_Of (M_Inst) = Locked);

   --  Events are the bare enumeration (no payload to carry).
   Process_Event (M_Inst, Ctx, E_Coin);
   Put_Line ("coin -> " & State_Of (M_Inst)'Image);
   pragma Assert (State_Of (M_Inst) = Unlocked);

   Process_Event (M_Inst, Ctx, E_Push);
   Put_Line ("push -> " & State_Of (M_Inst)'Image);
   pragma Assert (State_Of (M_Inst) = Locked);

   Put_Line ("coins taken:" & Ctx.Coins'Image);
   pragma Assert (Ctx.Coins = 1);
end Simple_Turnstile;
