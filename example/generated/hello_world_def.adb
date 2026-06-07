with Ada.Text_IO; use Ada.Text_IO;

package body Hello_World_Def is

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

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
                when E_Ack  => Evt.Ack_Valid,
                when E_Fin  => Evt.Fin_Valid,
                when others => False));
   end Evaluate;

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

end Hello_World_Def;
