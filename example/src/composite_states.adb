pragma Ada_2022;

--  Demonstrates Sml.Machines.Composite: a power tool with a parent machine
--  (Off/On, the Power button) wrapping a child machine (Low/High speed, the
--  Tick).  An event tries the child first, then bubbles to the parent -- so
--  Tick adjusts speed and Power toggles the tool.  Run it; the Asserts document
--  which level handled each event.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Machines.Composite;

procedure Composite_States is

   type Event_Kind is (E_Power, E_Tick);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   type Parent_State is (Off, On);
   package Parent_SM is new
     Sml.Machines
       (Parent_State,
        Event_Kind,
        Event,
        Context,
        Guard_Kind,
        Action_Kind,
        Kind_Of,
        Evaluate,
        Execute);
   package Parent_Op is new
     Parent_SM.Operators (Always => Always, Nothing => Nothing);

   type Child_State is (Low, High);
   package Child_SM is new
     Sml.Machines
       (Child_State,
        Event_Kind,
        Event,
        Context,
        Guard_Kind,
        Action_Kind,
        Kind_Of,
        Evaluate,
        Execute);
   package Child_Op is new
     Child_SM.Operators (Always => Always, Nothing => Nothing);

   --  Operators from both layers; each row resolves by its operand types.
   use Parent_Op, Child_Op;

   Power : constant Parent_Op.Ev := (Kind => E_Power);
   Tick  : constant Child_Op.Ev := (Kind => E_Tick);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Parent_Table : constant Parent_SM.Transition_Table :=
     [Off + Power >= On,
      On  + Power >= Off];

   Child_Table : constant Child_SM.Transition_Table :=
     [Low  + Tick >= High,
      High + Tick >= Low];
   --!format on

   Child : Child_SM.Machine := Child_SM.Make (Child_Table, Initial => Low);

   procedure Process_Child
     (Ctx : in out Context; Evt : Event; Handled : out Boolean) is
   begin
      Child_SM.Process_Event (Child, Ctx, Evt, Handled);
   end Process_Child;

   package Comp is new Parent_SM.Composite (Process_Child => Process_Child);

   Parent : Parent_SM.Machine := Parent_SM.Make (Parent_Table, Initial => Off);
   Ctx    : Context;

   procedure Show (Label : String) is
   begin
      Put_Line
        (Label
         & ":  parent="
         & Parent_SM.State_Of (Parent)'Image
         & "  child="
         & Child_SM.State_Of (Child)'Image);
   end Show;

begin
   Show ("start ");

   Comp.Process (Parent, Ctx, (Kind => E_Tick));   --  child handles
   Show ("tick  ");
   pragma Assert (Child_SM.State_Of (Child) = High);
   pragma Assert (Parent_SM.State_Of (Parent) = Off);

   Comp.Process (Parent, Ctx, (Kind => E_Power));   --  bubbles to parent
   Show ("power ");
   pragma Assert (Parent_SM.State_Of (Parent) = On);
   pragma Assert (Child_SM.State_Of (Child) = High);
end Composite_States;
