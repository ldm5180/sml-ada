--  The hand-written half: the parts of a machine no transition table can imply
--  -- the event payloads, the extended-state Context, and the guard predicates
--  and action effects.  Each guard/action is a named subprogram the generated
--  machine calls directly (so there is no Guard_Kind/Action_Kind enum and no
--  Evaluate/Execute dispatcher).  State/Event_Kind come from Hello_World_Defs.

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

   --  One guard (predicate) / action (effect) per name used in the spec.
   --  Inline so the whole machine dissolves into a constant-event driver (the
   --  C++ lambdas inline the same way) -- see example/generated/run.adb.
   function Is_Valid (Ctx : Context; Evt : Event) return Boolean;
   procedure Send_Fin (Ctx : in out Context; Evt : Event);
   procedure Send_Ack (Ctx : in out Context; Evt : Event);

   pragma Inline (Is_Valid, Send_Fin, Send_Ack);

end Hello_World_Logic;
