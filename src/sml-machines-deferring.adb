package body Sml.Machines.Deferring
  with SPARK_Mode
is

   --  Re-deliver every queued kind once, compacting those still unhandled
   --  to the front in place.  The invariant keeps the write index (New_Len)
   --  behind the read index (I), so each slot is read before it can be
   --  overwritten.
   procedure Drain
     (M : in out Machine; Q : in out Deferral_Queue; Ctx : in out Context)
   is
      Old_Len : constant Count_Of := Q.Len;
      New_Len : Count_Of := 0;
   begin
      for I in 1 .. Old_Len loop
         pragma Loop_Invariant (New_Len < I);
         declare
            K       : constant Event_Kind := Q.Items (I);
            Handled : Boolean;
         begin
            Process_Event (M, Ctx, Rebuild (K), Handled);
            if not Handled then
               New_Len := New_Len + 1;
               Q.Items (New_Len) := K;
            end if;
         end;
      end loop;
      Q.Len := New_Len;
   end Drain;

   procedure Post
     (M   : in out Machine;
      Q   : in out Deferral_Queue;
      Ctx : in out Context;
      Evt : Event)
   is
      K       : constant Event_Kind := Kind_Of (Evt);
      Handled : Boolean;
   begin
      Process_Event (M, Ctx, Evt, Handled);

      if Handled then
         Drain (M, Q, Ctx);
      elsif Deferred (State_Of (M), K) then
         if Q.Len >= Capacity then
            raise Deferral_Overflow;
         end if;
         Q.Len := Q.Len + 1;
         Q.Items (Q.Len) := K;
      end if;
   end Post;

end Sml.Machines.Deferring;
