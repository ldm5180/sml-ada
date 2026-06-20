with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Regions;

package body Sml_Regions_Tests is

   use AUnit.Test_Cases.Registration;

   --  Several independent toggle lamps that all react to one Toggle event.
   --  Each lamp keeps its own state; the shared Context tallies every flip.
   type St is (Off, On);
   type Ev_Kind is (E_Toggle);

   type Evt is record
      Kind : Ev_Kind;
   end record;

   type Ctx_T is record
      Toggles : Natural := 0;
   end record;

   type G_Kind is (Always);
   type A_Kind is (Tally);

   function Kind_Of (E : Evt) return Ev_Kind
   is (E.Kind);

   function Evaluate (G : G_Kind; C : Ctx_T; E : Evt) return Boolean is
      pragma Unreferenced (G, C, E);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : A_Kind; C : in out Ctx_T; E : Evt) is
      pragma Unreferenced (A, E);
   begin
      C.Toggles := C.Toggles + 1;
   end Execute;

   package SM is new
     Sml.Machines
       (State       => St,
        Event_Kind  => Ev_Kind,
        Event       => Evt,
        Context     => Ctx_T,
        Guard_Kind  => G_Kind,
        Action_Kind => A_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);
   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Off, E_Toggle, Always, Tally, On),
      (On,  E_Toggle, Always, Tally, Off)];
   --!format on

   package Reg is new SM.Regions (Count => Table'Length);
   use Reg;

   Toggle : constant Evt := (Kind => E_Toggle);

   procedure Test_Broadcast (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      --  Three lamps in mixed initial states.
      R : Region_Array :=
        [Make (Table, Initial => Off),
         Make (Table, Initial => Off),
         Make (Table, Initial => On)];
      C : Ctx_T;
   begin
      Broadcast (R, C, Toggle);
      Assert
        (State_Of (R (1)) = On
         and then State_Of (R (2)) = On
         and then State_Of (R (3)) = Off,
         "each region steps independently from its own state");
      Assert
        (C.Toggles = 3, "every region's action ran against shared Context");

      Broadcast (R, C, Toggle);
      Assert
        (State_Of (R (1)) = Off and then State_Of (R (3)) = On,
         "second broadcast flips them back");
      Assert (C.Toggles = 6, "actions tally across broadcasts");
   end Test_Broadcast;

   procedure Test_All_In (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Region_Array :=
        [Make (Table, Initial => Off), Make (Table, Initial => Off)];
      C : Ctx_T;
   begin
      Assert (All_In (R, Off), "all start Off");
      Assert (not All_In (R, On), "not all On yet");
      Broadcast (R, C, Toggle);
      Assert (All_In (R, On), "all On after a shared toggle");
   end Test_All_In;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Broadcast'Access,
         "Broadcast steps every region against the shared Context");
      Register_Routine
        (T, Test_All_In'Access, "All_In reports a uniform region set");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Regions (orthogonal regions)");
   end Name;

end Sml_Regions_Tests;
