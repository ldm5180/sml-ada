pragma Ada_2022;

--  A machine definition: the single source of truth the generator reads.
--  The transition table plus the named guard/action behaviour, all public so
--  the generated compiled package can reuse Kind_Of/Evaluate/Execute.

with Sml_Ada.Machines;

package Tcp_Defs is

   type State is (Established, Fin_Wait_1, Fin_Wait_2, Timed_Wait, Closed);
   type Event_Kind is (Release, Ack, Fin, Timeout);

   type Event (Kind : Event_Kind := Timeout) is record
      case Kind is
         when Ack =>
            Ack_Valid : Boolean;

         when Fin =>
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

   Initial : constant State := Established;

   --!format off
   Table : constant SM.Transition_Table :=
     [(Established, Release, Always,   Send_Fin, Fin_Wait_1),
      (Fin_Wait_1,  Ack,     Is_Valid, Nothing,  Fin_Wait_2),
      (Fin_Wait_2,  Fin,     Is_Valid, Send_Ack, Timed_Wait),
      (Timed_Wait,  Timeout, Always,   Nothing,  Closed)];
   --!format on

end Tcp_Defs;
