package body Sml.Machines
  with SPARK_Mode
is

   --  Excluded from proof: the Total-completeness check raises
   --  Incomplete_Table by design.  Make's Post (State_Of (Make'Result) =
   --  Initial) is the contract gnatprove assumes for callers; Process_Event
   --  below is fully analysed.
   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine
   with SPARK_Mode => Off
   is
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

      --  One Debug-gated trace sink.  The message is built at the call site
      --  regardless of Debug, so at -O0 the concatenation runs even when
      --  tracing is off; it folds away only with inlining (-O2/-O3).  That
      --  -O0 cost is accepted in exchange for the simpler call sites.
      procedure Log (Message : String) is
      begin
         if Debug then
            Trace (Message);
         end if;
      end Log;
   begin
      Log ("event " & K'Image & " in state " & M.Current'Image);

      for T of M.Table loop
         if T.From = M.Current and then T.On = K then
            declare
               Pass : constant Boolean := Evaluate (T.Guard, Ctx, Evt);
            begin
               Log ("  guard " & T.Guard'Image & " => " & Pass'Image);

               if Pass then
                  Log
                    ("  action "
                     & T.Action'Image
                     & "; "
                     & M.Current'Image
                     & " -> "
                     & T.To'Image);

                  Execute (T.Action, Ctx, Evt);
                  M.Current := T.To;
                  return;
               end if;
            end;
         end if;
      end loop;

      Log ("  unhandled; policy " & M.On_Unhandled'Image);

      case M.On_Unhandled is
         when Stay          =>
            null;

         when Raise_Error   =>
            raise Unhandled_Event with M.Current'Image & " on " & K'Image;

         when Go_To_Default =>
            M.Current := M.Default;
      end case;
   end Process_Event;

end Sml.Machines;
