with AUnit.Assertions; use AUnit.Assertions;

with Sml.Simple_Machines;

package body Sml_Simple_Machines_Tests is

   use AUnit.Test_Cases.Registration;

   --  A coin gate with NO event payloads -- the whole point of the layer: no
   --  variant record and no Kind_Of, just the event enumeration.  Guards read
   --  the Context (Paid = some coins in) and actions mutate it (Insert/Clear).
   type St is (Closed, Open);
   type Ev is (Coin, Push, Reset);

   type Ctx_T is record
      Coins : Natural := 0;
   end record;

   type G_Kind is (Always, Paid);
   type A_Kind is (Nothing, Insert, Clear);

   function Evaluate (G : G_Kind; C : Ctx_T; E : Ev) return Boolean is
      pragma Unreferenced (E);
   begin
      return
        (case G is
           when Always => True,
           when Paid   => C.Coins > 0);
   end Evaluate;

   procedure Execute (A : A_Kind; C : in out Ctx_T; E : Ev) is
      pragma Unreferenced (E);
   begin
      case A is
         when Nothing =>
            null;

         when Insert  =>
            C.Coins := C.Coins + 1;

         when Clear   =>
            C.Coins := 0;
      end case;
   end Execute;

   package M is new
     Sml.Simple_Machines
       (State       => St,
        Event       => Ev,
        Context     => Ctx_T,
        Guard_Kind  => G_Kind,
        Action_Kind => A_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute);
   use M;

   --!format off
   Table : constant Transition_Table :=
     [(Closed, Coin,  Always, Insert, Open),
      (Open,   Coin,  Always, Insert, Open),
      (Open,   Push,  Paid,   Clear,  Closed),
      (Closed, Reset, Always, Clear,  Closed)];
   --!format on

   procedure Test_No_Payload_Flow (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Closed);
      C   : Ctx_T;
   begin
      Assert (State_Of (Mac) = Closed, "starts Closed");
      Process_Event (Mac, C, Coin);
      Assert (State_Of (Mac) = Open and then C.Coins = 1, "Coin -> Open, 1");
      Process_Event (Mac, C, Coin);
      Assert
        (State_Of (Mac) = Open and then C.Coins = 2, "second Coin tallied");
      Process_Event (Mac, C, Push);
      Assert
        (State_Of (Mac) = Closed and then C.Coins = 0,
         "paid Push -> Closed, coins cleared");
   end Test_No_Payload_Flow;

   procedure Test_Guard_Blocks (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Open);
      C   : Ctx_T;  --  Coins = 0, so Paid is False
   begin
      Process_Event (Mac, C, Push);
      Assert
        (State_Of (Mac) = Open,
         "unpaid Push is blocked by its guard (stays Open)");
   end Test_Guard_Blocks;

   procedure Test_Unhandled_Stay (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Closed);
      C   : Ctx_T;
   begin
      Process_Event (Mac, C, Push);  --  no Closed+Push row
      Assert (State_Of (Mac) = Closed, "unhandled event stays put");
   end Test_Unhandled_Stay;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_No_Payload_Flow'Access,
         "No-payload machine: guards read and actions mutate Context");
      Register_Routine
        (T, Test_Guard_Blocks'Access, "Guard gates a transition");
      Register_Routine
        (T, Test_Unhandled_Stay'Access, "Unhandled event: Stay policy");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Simple_Machines (no-payload events)");
   end Name;

end Sml_Simple_Machines_Tests;
