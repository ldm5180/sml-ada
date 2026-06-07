with Ada.Text_IO; use Ada.Text_IO;

package body Hello_World_Logic is

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (Ctx);
   begin
      return
        (case G is
           when Is_Valid =>
             (case Evt.Kind is
                when Ack    => Evt.Ack_Valid,
                when Fin    => Evt.Fin_Valid,
                when others => False));
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      case A is
         when Send_Fin =>
            Put_Line ("send: fin");

         when Send_Ack =>
            Put_Line ("send: ack");
      end case;
   end Execute;

end Hello_World_Logic;
