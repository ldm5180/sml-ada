with AUnit.Assertions; use AUnit.Assertions;

with Sml_Ada.Machines;
with Sml_Ada.Machines.Indexed;

package body Sml_Ada_Indexed_Tests is

   use AUnit.Test_Cases.Registration;

   type St is (Idle, Busy, Done);
   type Ev_Kind is (Go, Chunk, Stop);

   type Evt (Kind : Ev_Kind := Stop) is record
      case Kind is
         when Chunk =>
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

   function Kind_Of (E : Evt) return Ev_Kind
   is (E.Kind);

   function Evaluate (G : G_Kind; C : Ctx_T; E : Evt) return Boolean
   is (case G is
         when Always    => True,
         when Below_Cap => C.Sum + E.N <= C.Cap);

   procedure Execute (A : A_Kind; C : in out Ctx_T; E : Evt) is
   begin
      case A is
         when Nothing =>
            null;

         when Add     =>
            C.Sum := @ + E.N;
      end case;
   end Execute;

   package M is new
     Sml_Ada.Machines
       (St,
        Ev_Kind,
        Evt,
        Ctx_T,
        G_Kind,
        A_Kind,
        Kind_Of,
        Evaluate,
        Execute);
   package MI is new M.Indexed;

   --!format off
   Table : constant M.Transition_Table :=
     [(Idle, Go,    Always,    Nothing, Busy),
      (Busy, Chunk, Below_Cap, Add,     Busy),
      (Busy, Stop,  Always,    Nothing, Done)];
   --!format on

   procedure Test_Indexed (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Mac : MI.Machine := MI.Make (Table, Initial => Idle);
      C   : Ctx_T;
   begin
      Assert (MI.State_Of (Mac) = Idle, "starts Idle");
      MI.Process_Event (Mac, C, (Kind => Go));
      Assert (MI.State_Of (Mac) = Busy, "Go -> Busy");
      MI.Process_Event (Mac, C, (Kind => Chunk, N => 30));
      Assert (C.Sum = 30, "Chunk accumulates");
      MI.Process_Event (Mac, C, (Kind => Chunk, N => 80));
      Assert (C.Sum = 30, "over-cap Chunk blocked by guard");
      MI.Process_Event (Mac, C, (Kind => Stop));
      Assert (MI.State_Of (Mac) = Done, "Stop -> Done");
   end Test_Indexed;

   procedure Test_Duplicate_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      --!format off
      Dup : constant M.Transition_Table :=
        [(Idle, Go, Always, Nothing, Busy),
         (Idle, Go, Always, Nothing, Done)];   --  duplicate (Idle, Go)
      --!format on
   begin
      declare
         Mac : constant MI.Machine := MI.Make (Dup, Initial => Idle);
         pragma Unreferenced (Mac);
      begin
         Assert (False, "duplicate (State, Event) should be rejected");
      end;
   exception
      when MI.Duplicate_Transition =>
         null;
   end Test_Duplicate_Rejected;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine (T, Test_Indexed'Access, "O(1) indexed dispatch");
      Register_Routine
        (T,
         Test_Duplicate_Rejected'Access,
         "Duplicate (State, Event) rejected by Make");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml_Ada.Machines.Indexed");
   end Name;

end Sml_Ada_Indexed_Tests;
