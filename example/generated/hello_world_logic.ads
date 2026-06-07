--  The hand-written half: the parts of a machine that can't be derived from
--  the transition table -- the event payloads, the extended-state Context, and
--  the actual guard predicates / action effects.  Everything structural (the
--  enums and the dispatch) is generated from hello_world.fsm; this is just the
--  behaviour.  The State/Event_Kind/Guard_Kind/Action_Kind enums come from the
--  generated Hello_World_Defs.

with Hello_World_Defs; use Hello_World_Defs;

package Hello_World_Logic is

   --  Event payloads.  The discriminant MUST be named Kind (the generated
   --  dispatch matches on Evt.Kind).
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

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;
   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);

end Hello_World_Logic;
