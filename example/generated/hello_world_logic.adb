with Ada.Text_IO; use Ada.Text_IO;

package body Hello_World_Logic is

   function Is_Valid (Ctx : Context; Evt : Event) return Boolean is
      pragma Unreferenced (Ctx);
   begin
      return
        (case Evt.Kind is
           when Ack    => Evt.Ack_Valid,
           when Fin    => Evt.Fin_Valid,
           when others => False);
   end Is_Valid;

   procedure Send_Fin (Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      Put_Line ("send: fin");
   end Send_Fin;

   procedure Send_Ack (Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      Put_Line ("send: ack");
   end Send_Ack;

end Hello_World_Logic;
