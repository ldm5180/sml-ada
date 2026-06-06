--  A port of the Boost.SML "hello world" example, a TCP-teardown machine:
--  https://github.com/boost-ext/sml/blob/master/example/hello_world.cpp
--
--  Read this top-to-bottom as a recipe for building your own machine.

with Ada.Text_IO; use Ada.Text_IO;

with Sml_Ada.Machines;

procedure Hello_World is

   --  1. Name the states and the kinds of event.
   type State is (Established, Fin_Wait_1, Fin_Wait_2, Timed_Wait, Closed);
   type Event_Kind is (Release, Ack, Fin, Timeout);

   --  2. Give events their payloads with a variant record (like the C++
   --     structs ack{valid} and fin{id, valid}).  Events with no data just
   --     carry the tag.
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

   --  3. Context is your extended state.  This machine needs none.
   type Context is null record;

   --  4. Name your guards and actions.  Include an "always-true" guard and a
   --     "do-nothing" action for transitions that need neither.
   type Guard_Kind is (Always, Is_Valid);
   type Action_Kind is (Nothing, Send_Fin, Send_Ack);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   --  5. Map each guard name to a predicate over the context and event.
   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (Ctx);
   begin
      return
        (case G is
           when Always   => True,
           when Is_Valid =>
             (case Evt.Kind is
                when Ack    => Evt.Ack_Valid,
                when Fin    => Evt.Fin_Valid,
                when others => False));
   end Evaluate;

   --  6. Map each action name to its effect (here, "sending" a segment).
   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      case A is
         when Nothing  =>
            null;

         when Send_Fin =>
            Put_Line ("send: fin");

         when Send_Ack =>
            Put_Line ("send: ack");
      end case;
   end Execute;

   --  7. Instantiate the engine with your types and dispatchers.
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
   use SM;

   --  8. Spell out the machine as a table: one transition per row.  Wrapped
   --     in "--!format off/on" so gnatformat leaves the hand-aligned columns
   --     alone.  Read each row in Boost.SML / UML notation:
   --
   --         From  + On  [ Guard ]  / Action  = To
   --
   --     (the initial state is SML's *, given to Make; a state with no
   --     outgoing row is terminal, SML's X).
   --!format off
   --     From         On       Guard     Action    To
   Table : constant Transition_Table :=
     [(Established, Release, Always,   Send_Fin, Fin_Wait_1),
      (Fin_Wait_1,  Ack,     Is_Valid, Nothing,  Fin_Wait_2),
      (Fin_Wait_2,  Fin,     Is_Valid, Send_Ack, Timed_Wait),
      (Timed_Wait,  Timeout, Always,   Nothing,  Closed)];
   --!format on

   M   : Machine := Make (Table, Initial => Established);
   Ctx : Context := (null record);
begin
   --  9. Drive it: build events (with payloads) and process them.
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => Release));
   Process_Event (M, Ctx, (Kind => Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Hello_World;
