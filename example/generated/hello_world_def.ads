pragma Ada_2022;

--  THE ONLY FILE YOU WRITE: the state machine definition.  Everything else --
--  Process_Event, Make, State_Of, and a Graphviz diagram -- is produced from
--  the Table below by the generator (see generate.adb).  The table uses the
--  operator notation; everything is public so the generated unit can reuse
--  Kind_Of/Evaluate/Execute and the generator can read Table and Initial.

with Sml_Ada.Machines;
with Sml_Ada.Machines.Operators;

package Hello_World_Def is

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

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   Release : constant Ev := (Kind => E_Release);
   Ack     : constant Ev := (Kind => E_Ack);
   Fin     : constant Ev := (Kind => E_Fin);
   Timeout : constant Ev := (Kind => E_Timeout);

   Initial : constant State := Established;

   --  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Established + Release            / Send_Fin >= Fin_Wait_1,
      Fin_Wait_1  + Ack     (Is_Valid)            >= Fin_Wait_2,
      Fin_Wait_2  + Fin     (Is_Valid) / Send_Ack >= Timed_Wait,
      Timed_Wait  + Timeout                       >= Closed];
   --!format on

end Hello_World_Def;
