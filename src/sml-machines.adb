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
     (M       : in out Machine;
      Ctx     : in out Context;
      Evt     : Event;
      Handled : out Boolean)
   is
      K : constant Event_Kind := Kind_Of (Evt);
   begin
      On_Event (K, M.Current);

      for T of M.Table loop
         if T.From = M.Current and then T.On = K then
            declare
               Pass : constant Boolean := Evaluate (T.Guard, Ctx, Evt);
            begin
               On_Guard (T.Guard, Pass);

               if Pass then
                  On_Action (T.Action, M.Current, T.To);
                  Execute (T.Action, Ctx, Evt);
                  M.Current := T.To;
                  Handled := True;
                  return;
               end if;
            end;
         end if;
      end loop;

      Handled := False;
   end Process_Event;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      Handled : Boolean;
   begin
      Process_Event (M, Ctx, Evt, Handled);

      if not Handled then
         declare
            K : constant Event_Kind := Kind_Of (Evt);
         begin
            On_Unhandled (K, M.Current);

            case M.On_Unhandled is
               when Stay          =>
                  null;

               when Raise_Error   =>
                  raise Unhandled_Event
                    with M.Current'Image & " on " & K'Image;

               when Go_To_Default =>
                  M.Current := M.Default;
            end case;
         end;
      end if;
   end Process_Event;

end Sml.Machines;
