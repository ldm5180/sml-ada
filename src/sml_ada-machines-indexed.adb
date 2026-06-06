package body Sml_Ada.Machines.Indexed
  with SPARK_Mode
is

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine is
   begin
      return M : Machine (Count => Table'Length) do
         M.Current := Initial;
         M.On_Unhandled := On_Unhandled;
         M.Default := Default;
         M.Table := Table;
         M.Index := [others => [others => 0]];

         declare
            Pos : Positive := 1;
         begin
            for I in Table'Range loop
               if M.Index (Table (I).From, Table (I).On) /= 0 then
                  raise Duplicate_Transition
                    with Table (I).From'Image & " on " & Table (I).On'Image;
               end if;
               M.Index (Table (I).From, Table (I).On) := Pos;
               Pos := Pos + 1;
            end loop;
         end;

         if Complete = Total then
            for S in State loop
               for K in Event_Kind loop
                  if M.Index (S, K) = 0 then
                     raise Incomplete_Table
                       with
                         "missing transition: " & S'Image & " on " & K'Image;
                  end if;
               end loop;
            end loop;
         end if;
      end return;
   end Make;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      K : constant Event_Kind := Kind_Of (Evt);
      R : constant Natural := M.Index (M.Current, K);
   begin
      if R /= 0 and then Evaluate (M.Table (R).Guard, Ctx, Evt) then
         Execute (M.Table (R).Action, Ctx, Evt);
         M.Current := M.Table (R).To;
      else
         case M.On_Unhandled is
            when Stay          =>
               null;

            when Raise_Error   =>
               raise Unhandled_Event with M.Current'Image & " on " & K'Image;

            when Go_To_Default =>
               M.Current := M.Default;
         end case;
      end if;
   end Process_Event;

end Sml_Ada.Machines.Indexed;
