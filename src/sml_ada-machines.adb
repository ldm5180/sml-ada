package body Sml_Ada.Machines
  with SPARK_Mode
is

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness     := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State            := State'First) return Machine is
   begin
      if Complete = Total then
         for S in State loop
            for K in Event_Kind loop
               if (for all T of Table => T.From /= S or else T.On /= K) then
                  raise Incomplete_Table
                    with "missing transition: " & S'Image & " on " & K'Image;
               end if;
            end loop;
         end loop;
      end if;

      return M : Machine (Count => Table'Length) do
         M.Current      := Initial;
         M.On_Unhandled := On_Unhandled;
         M.Default      := Default;
         M.Table        := Table;
      end return;
   end Make;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      K : constant Event_Kind := Kind_Of (Evt);
   begin
      for T of M.Table loop
         if T.From = M.Current and then T.On = K
           and then Evaluate (T.Guard, Ctx, Evt)
         then
            Execute (T.Action, Ctx, Evt);
            M.Current := T.To;
            return;
         end if;
      end loop;

      case M.On_Unhandled is
         when Stay =>
            null;

         when Raise_Error =>
            raise Unhandled_Event with M.Current'Image & " on " & K'Image;

         when Go_To_Default =>
            M.Current := M.Default;
      end case;
   end Process_Event;

end Sml_Ada.Machines;
