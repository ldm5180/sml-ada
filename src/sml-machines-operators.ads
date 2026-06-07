--  Opt-in operators for Sml.Machines, letting a transition read close to
--  Boost.SML:  From + Event (Guard) / Action >= To.
--
--  A row built this way is just a Transition, so a table is an ordinary array
--  aggregate fed to the usual Make -- no extra container.  Everything here is
--  in the SPARK subset and builds on GNAT 14+.
--
--     package SM is new Sml.Machines (...);
--     package Op is new SM.Operators (Always => Always, Nothing => Nothing);
--     use SM, Op;
--
--     --  One wrapper constant per event (enables the "()" guard; its name
--     --  must differ from the Event_Kind literal, hence the E_ prefix here).
--     Release : constant Ev := (Kind => E_Release);
--
--     Table : constant Transition_Table :=
--       [Established + Release / Send_Fin >= Fin_Wait_1, ...];
--     M : Machine := Make (Table, Initial => Established);

generic
   Always : Guard_Kind;
   Nothing : Action_Kind;
package Sml.Machines.Operators with SPARK_Mode is

   type Ev is tagged record
      Kind : Event_Kind;
   end record
   with Constant_Indexing => With_Guard;

   type Ev_Guard is record
      Kind  : Event_Kind;
      Guard : Guard_Kind;
   end record;

   type Ev_Built is record
      Kind   : Event_Kind;
      Guard  : Guard_Kind;
      Action : Action_Kind;
   end record;

   type Source is record
      From   : State;
      Kind   : Event_Kind;
      Guard  : Guard_Kind;
      Action : Action_Kind;
   end record;

   function With_Guard (E : Ev; G : Guard_Kind) return Ev_Guard
   is ((E.Kind, G));

   function "/" (E : Ev; A : Action_Kind) return Ev_Built
   is ((E.Kind, Always, A));
   function "/" (E : Ev_Guard; A : Action_Kind) return Ev_Built
   is ((E.Kind, E.Guard, A));

   function "+" (From : State; E : Ev) return Source
   is ((From, E.Kind, Always, Nothing));
   function "+" (From : State; E : Ev_Guard) return Source
   is ((From, E.Kind, E.Guard, Nothing));
   function "+" (From : State; E : Ev_Built) return Source
   is ((From, E.Kind, E.Guard, E.Action));

   function ">=" (S : Source; To : State) return Transition
   is ((S.From, S.Kind, S.Guard, S.Action, To));

end Sml.Machines.Operators;
