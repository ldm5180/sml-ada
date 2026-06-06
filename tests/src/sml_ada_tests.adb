with AUnit.Assertions; use AUnit.Assertions;

with Sml_Ada.State_Machines;

package body Sml_Ada_Tests is

   --  Register_Routine lives in the nested package AUnit.Test_Cases.
   --  Registration (AUnit.Test_Cases is withed by the spec).
   use AUnit.Test_Cases.Registration;

   --  A classic turnstile machine, reused across the routines below.

   type Turnstile_State is (Locked, Unlocked);
   type Turnstile_Event is (Coin, Push);

   function Next
     (From : Turnstile_State; On : Turnstile_Event) return Turnstile_State
   is (case From is
         when Locked   => (if On = Coin then Unlocked else Locked),
         when Unlocked => (if On = Push then Locked else Unlocked));

   package Turnstile is new
     Sml_Ada.State_Machines
       (State   => Turnstile_State,
        Event   => Turnstile_Event,
        Initial => Locked,
        Next    => Next);

   use Turnstile;

   --  Test routines ---------------------------------------------------------

   procedure Test_Initial_State (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : constant Machine := Make;
   begin
      Assert (State_Of (M) = Locked, "a fresh machine should be Locked");
   end Test_Initial_State;

   procedure Test_Coin_Unlocks (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      M : Machine := Make;
   begin
      Fire (M, Coin);
      Assert (State_Of (M) = Unlocked, "Coin should unlock the turnstile");
   end Test_Coin_Unlocks;

   procedure Test_Push_Locks (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      M : Machine := Make;
   begin
      Fire (M, Coin);
      Fire (M, Push);
      Assert (State_Of (M) = Locked, "Push after Coin should re-lock");
   end Test_Push_Locks;

   procedure Test_Irrelevant_Events_Ignored
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make;
   begin
      Fire (M, Push);
      Assert (State_Of (M) = Locked, "Push while Locked is a no-op");
      Fire (M, Coin);
      Fire (M, Coin);
      Assert (State_Of (M) = Unlocked, "a second Coin is a no-op");
   end Test_Irrelevant_Events_Ignored;

   --  Registration ----------------------------------------------------------

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T, Test_Initial_State'Access, "Initial state is Locked");
      Register_Routine (T, Test_Coin_Unlocks'Access, "Coin unlocks");
      Register_Routine (T, Test_Push_Locks'Access, "Push re-locks");
      Register_Routine
        (T,
         Test_Irrelevant_Events_Ignored'Access,
         "Irrelevant events are ignored");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml_Ada.State_Machines (turnstile)");
   end Name;

end Sml_Ada_Tests;
