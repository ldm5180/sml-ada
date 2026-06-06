package body Sml_Ada.Machines
  with SPARK_Mode
is

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine is
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
         M.Current := Initial;
         M.On_Unhandled := On_Unhandled;
         M.Default := Default;
         M.Table := Table;
      end return;
   end Make;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      K : constant Event_Kind := Kind_Of (Evt);

      --  'Image of a composite is multi-line; flatten it for one-line traces.
      function One_Line (S : String) return String is
         R : String (S'Range) := S;
      begin
         for I in R'Range loop
            if R (I) = ASCII.LF then
               R (I) := ' ';
            end if;
         end loop;
         return R;
      end One_Line;

   begin
      if Debug then
         Trace
           ("event " & One_Line (Evt'Image) & " in state " & M.Current'Image);
      end if;

      for T of M.Table loop
         if T.From = M.Current and then T.On = K then
            declare
               Pass : constant Boolean := Evaluate (T.Guard, Ctx, Evt);
            begin
               if Debug then
                  Trace ("  guard " & T.Guard'Image & " => " & Pass'Image);
               end if;

               if Pass then
                  if Debug then
                     Trace
                       ("  action "
                        & T.Action'Image
                        & "; "
                        & M.Current'Image
                        & " -> "
                        & T.To'Image);
                  end if;

                  Execute (T.Action, Ctx, Evt);
                  M.Current := T.To;

                  if Debug then
                     Trace ("  context " & One_Line (Ctx'Image));
                  end if;

                  return;
               end if;
            end;
         end if;
      end loop;

      if Debug then
         Trace ("  unhandled; policy " & M.On_Unhandled'Image);
      end if;

      case M.On_Unhandled is
         when Stay          =>
            null;

         when Raise_Error   =>
            raise Unhandled_Event with M.Current'Image & " on " & K'Image;

         when Go_To_Default =>
            M.Current := M.Default;
      end case;
   end Process_Event;

end Sml_Ada.Machines;
