with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Composite;

package body Sml_Composite_Tests is

   use AUnit.Test_Cases.Registration;

   --  A power tool.  Parent: Off/On (the Power event).  Child: Low/High speed
   --  (the Tick event).  Tick is a child concern, Power a parent concern; the
   --  composite routes each to the right level.
   type Event_Kind is (E_Power, E_Tick);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Null_Ctx is null record;
   type G is (Always);
   type A is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate (Gk : G; C : Null_Ctx; E : Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end Evaluate;

   procedure Execute (Ak : A; C : in out Null_Ctx; E : Event) is null;

   type P_St is (Off, On);
   package Parent_SM is new
     Sml.Machines
       (P_St,
        Event_Kind,
        Event,
        Null_Ctx,
        G,
        A,
        Kind_Of,
        Evaluate,
        Execute);

   type C_St is (Low, High);
   package Child_SM is new
     Sml.Machines
       (C_St,
        Event_Kind,
        Event,
        Null_Ctx,
        G,
        A,
        Kind_Of,
        Evaluate,
        Execute);

   --!format off
   Parent_Table : constant Parent_SM.Transition_Table :=
     [(Off, E_Power, Always, Nothing, On),
      (On,  E_Power, Always, Nothing, Off)];

   Child_Table : constant Child_SM.Transition_Table :=
     [(Low,  E_Tick, Always, Nothing, High),
      (High, E_Tick, Always, Nothing, Low)];
   --!format on

   --  The composite's child is this enclosing machine; each test resets it.
   Child : Child_SM.Machine := Child_SM.Make (Child_Table, Initial => Low);

   procedure Process_Child
     (Ctx : in out Null_Ctx; Evt : Event; Handled : out Boolean) is
   begin
      Child_SM.Process_Event (Child, Ctx, Evt, Handled);
   end Process_Child;

   package Comp is new Parent_SM.Composite (Process_Child => Process_Child);

   procedure Test_Child_First (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent : Parent_SM.Machine :=
        Parent_SM.Make (Parent_Table, Initial => Off);
      C      : Null_Ctx;
   begin
      Child := Child_SM.Make (Child_Table, Initial => Low);

      --  Tick is handled by the child; the parent is untouched.
      Comp.Process (Parent, C, (Kind => E_Tick));
      Assert
        (Child_SM.State_Of (Child) = High, "child handles Tick (Low->High)");
      Assert (Parent_SM.State_Of (Parent) = Off, "parent untouched by Tick");

      --  Power is not a child concern; it bubbles up to the parent.
      Comp.Process (Parent, C, (Kind => E_Power));
      Assert
        (Parent_SM.State_Of (Parent) = On,
         "child ignores Power, so the parent handles it (Off->On)");
      Assert (Child_SM.State_Of (Child) = High, "child untouched by Power");

      --  And Tick still goes to the child.
      Comp.Process (Parent, C, (Kind => E_Tick));
      Assert (Child_SM.State_Of (Child) = Low, "child handles Tick again");
   end Test_Child_First;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Child_First'Access,
         "Child handles its events; the parent handles what the child ignores");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Composite (hierarchical states)");
   end Name;

end Sml_Composite_Tests;
