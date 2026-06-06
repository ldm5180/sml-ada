pragma Ada_2022;

--  THE THING YOU AUTHOR (1/3): the machine definition the generator reads.
--  The transition table is written with the operator DSL
--  (Sml_Ada.Machines.Dsl) -- From + Event (Guard) / Action >= To -- which
--  produces a plain SM.Transition_Table, exactly what the generator consumes.
--  Everything is public so the generated package can reuse
--  Kind_Of/Evaluate/Execute and the generator can read Table/Initial.

with Sml_Ada.Machines;
with Sml_Ada.Machines.Dsl;

package Hw_Defs is

   --  Event_Kind literals are E_* so the DSL wrapper constants below
   --  (Release, Ack, ...) don't collide with them.
   type State is (Established, Fin_Wait_1, Fin_Wait_2, Timed_Wait, Closed);
   type Event_Kind is (E_Release, E_Ack, E_Fin, E_Timeout);

   type Event (Kind : Event_Kind := E_Timeout) is record
      case Kind is
         when E_Ack =>
            Ack_Valid : Boolean;

         when E_Fin =>
            Id        : Integer;
            Fin_Valid : Boolean;

         when others =>
            null;
      end case;
   end record;

   type Context is null record;
   type Guard_Kind is (Always, Is_Valid);
   type Action_Kind is (Nothing, Send_Fin, Send_Ack);

   function Kind_Of (E : Event) return Event_Kind;
   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;
   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);

   package SM is new
     Sml_Ada.Machines
       (State       => State,
        Event_Kind  => Event_Kind,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   --  Opt in to the DSL, naming the "always" guard and "do nothing" action.
   package D is new SM.Dsl (Always => Always, Nothing => Nothing);
   use SM, D;

   Release : constant Ev := (Kind => E_Release);
   Ack     : constant Ev := (Kind => E_Ack);
   Fin     : constant Ev := (Kind => E_Fin);
   Timeout : constant Ev := (Kind => E_Timeout);

   Initial : constant State := Established;

   --  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Established + Release            / Send_Fin >= Fin_Wait_1,
      Fin_Wait_1  + Ack (Is_Valid)               >= Fin_Wait_2,
      Fin_Wait_2  + Fin (Is_Valid)     / Send_Ack >= Timed_Wait,
      Timed_Wait  + Timeout                       >= Closed];
   --!format on

end Hw_Defs;
