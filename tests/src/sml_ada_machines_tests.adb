with AUnit.Assertions; use AUnit.Assertions;

with Sml_Ada.Machines;

package body Sml_Ada_Machines_Tests is

   use AUnit.Test_Cases.Registration;

   type St is (Idle, Busy, Done);
   type Ev is (Go, Step, Stop);

   type Evt (Kind : Ev := Stop) is record
      case Kind is
         when Step =>
            N : Natural;

         when others =>
            null;
      end case;
   end record;

   type Ctx_T is record
      Sum : Natural := 0;
      Cap : Natural := 100;
   end record;

   type G_Kind is (Always, Below_Cap);
   type A_Kind is (Nothing, Add);

   function Kind_Of (E : Evt) return Ev is (E.Kind);

   function Evaluate (G : G_Kind; C : Ctx_T; E : Evt) return Boolean is
     (case G is
         when Always    => True,
         when Below_Cap => C.Sum + E.N <= C.Cap);

   procedure Execute (A : A_Kind; C : in out Ctx_T; E : Evt) is
   begin
      case A is
         when Nothing =>
            null;

         when Add =>
            C.Sum := C.Sum + E.N;
      end case;
   end Execute;

   package M is new Sml_Ada.Machines
     (State       => St,
      Event_Kind  => Ev,
      Event       => Evt,
      Context     => Ctx_T,
      Guard_Kind  => G_Kind,
      Action_Kind => A_Kind,
      Kind_Of     => Kind_Of,
      Evaluate    => Evaluate,
      Execute     => Execute);
   use M;

   Table : constant Transition_Table :=
     [(Idle, Go, Always, Nothing, Busy),
      (Busy, Step, Below_Cap, Add, Busy),
      (Busy, Stop, Always, Nothing, Done)];

   procedure Test_Guarded_Accumulation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Idle);
      C   : Ctx_T;
   begin
      Assert (State_Of (Mac) = Idle, "starts Idle");
      Process_Event (Mac, C, (Kind => Go));
      Assert (State_Of (Mac) = Busy, "Go -> Busy");
      Process_Event (Mac, C, (Kind => Step, N => 30));
      Assert (C.Sum = 30, "first Step accumulates");
      Process_Event (Mac, C, (Kind => Step, N => 80));
      Assert (C.Sum = 30, "over-cap Step is blocked by its guard");
      Assert (State_Of (Mac) = Busy, "blocked event leaves state unchanged");
      Process_Event (Mac, C, (Kind => Stop));
      Assert (State_Of (Mac) = Done, "Stop -> Done");
   end Test_Guarded_Accumulation;

   procedure Test_Unhandled_Stay (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Idle);
      C   : Ctx_T;
   begin
      Process_Event (Mac, C, (Kind => Stop));
      Assert (State_Of (Mac) = Idle, "unhandled event stays put");
   end Test_Unhandled_Stay;

   procedure Test_Unhandled_Raise (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine := Make (Table, Initial => Idle, On_Unhandled => Raise_Error);
      C   : Ctx_T;
   begin
      Process_Event (Mac, C, (Kind => Stop));
      Assert (False, "Process_Event should have raised Unhandled_Event");
   exception
      when Unhandled_Event =>
         null;
   end Test_Unhandled_Raise;

   procedure Test_Unhandled_Default
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Mac : Machine :=
        Make
          (Table, Initial => Busy, On_Unhandled => Go_To_Default,
           Default => Idle);
      C : Ctx_T;
   begin
      Process_Event (Mac, C, (Kind => Go));
      Assert (State_Of (Mac) = Idle, "unhandled event goes to default state");
   end Test_Unhandled_Default;

   procedure Test_Incomplete_Table_Detected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      declare
         Mac : constant Machine :=
           Make (Table, Initial => Idle, Complete => Total);
         pragma Unreferenced (Mac);
      begin
         Assert (False, "Total should reject the sparse table");
      end;
   exception
      when Incomplete_Table =>
         null;
   end Test_Incomplete_Table_Detected;

   procedure Test_Complete_Table_Accepted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Full : constant Transition_Table :=
        [(Idle, Go, Always, Nothing, Busy),
         (Idle, Step, Always, Nothing, Idle),
         (Idle, Stop, Always, Nothing, Idle),
         (Busy, Go, Always, Nothing, Busy),
         (Busy, Step, Always, Nothing, Busy),
         (Busy, Stop, Always, Nothing, Done),
         (Done, Go, Always, Nothing, Done),
         (Done, Step, Always, Nothing, Done),
         (Done, Stop, Always, Nothing, Done)];
      Mac : Machine := Make (Full, Initial => Idle, Complete => Total);
      C   : Ctx_T;
   begin
      Process_Event (Mac, C, (Kind => Go));
      Assert (State_Of (Mac) = Busy, "complete table is accepted and runs");
   end Test_Complete_Table_Accepted;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T, Test_Guarded_Accumulation'Access,
         "Guards gate transitions; actions accumulate payload");
      Register_Routine
        (T, Test_Unhandled_Stay'Access, "Unhandled event: Stay policy");
      Register_Routine
        (T, Test_Unhandled_Raise'Access, "Unhandled event: Raise_Error policy");
      Register_Routine
        (T, Test_Unhandled_Default'Access,
         "Unhandled event: Go_To_Default policy");
      Register_Routine
        (T, Test_Incomplete_Table_Detected'Access,
         "Total completeness rejects a sparse table");
      Register_Routine
        (T, Test_Complete_Table_Accepted'Access,
         "Total completeness accepts a full table");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml_Ada.Machines (guards, actions, payloads)");
   end Name;

end Sml_Ada_Machines_Tests;
