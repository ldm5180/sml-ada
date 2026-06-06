with AUnit.Assertions; use AUnit.Assertions;

with Sml_Ada.Compiled_Machines;

package body Sml_Ada_Compiled_Tests is

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

   --  The whole machine as inline code: guards are `if`s, the action is an
   --  assignment, the next state is an assignment.
   procedure Step (Current : in out St; C : in out Ctx_T; E : Evt) is
   begin
      case Current is
         when Idle =>
            if E.Kind = Go then
               Current := Busy;
            end if;

         when Busy =>
            case E.Kind is
               when Chunk  =>
                  if C.Sum + E.N <= C.Cap then
                     C.Sum := @ + E.N;
                  end if;

               when Stop   =>
                  Current := Done;

               when others =>
                  null;
            end case;

         when Done =>
            null;
      end case;
   end Step;

   package M is new Sml_Ada.Compiled_Machines (St, Evt, Ctx_T, Step);
   use M;

   procedure Test_Compiled (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Mac : Machine := Make (Idle);
      C   : Ctx_T;
   begin
      Assert (State_Of (Mac) = Idle, "starts Idle");
      Process_Event (Mac, C, (Kind => Go));
      Assert (State_Of (Mac) = Busy, "Go -> Busy");
      Process_Event (Mac, C, (Kind => Chunk, N => 30));
      Assert (C.Sum = 30, "Chunk accumulates");
      Process_Event (Mac, C, (Kind => Chunk, N => 80));
      Assert (C.Sum = 30, "over-cap Chunk blocked by the inline guard");
      Process_Event (Mac, C, (Kind => Stop));
      Assert (State_Of (Mac) = Done, "Stop -> Done");
   end Test_Compiled;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Compiled'Access,
         "Compiled layer: inline guards, actions and context");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml_Ada.Compiled_Machines");
   end Name;

end Sml_Ada_Compiled_Tests;
