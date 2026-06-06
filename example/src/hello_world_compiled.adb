pragma Ada_2022;

--  The same TCP-teardown machine as hello_world.adb, but written for the
--  fully-dissolved layer (Sml_Ada.Compiled_Machines): the whole machine is one
--  Step procedure -- guards are `if`s, actions are inline statements, the next
--  state is an assignment.  No table, no scan; GNAT compiles it to branches.

with Ada.Text_IO; use Ada.Text_IO;

with Sml_Ada.Compiled_Machines;

procedure Hello_World_Compiled is

   type State is (Established, Fin_Wait_1, Fin_Wait_2, Timed_Wait, Closed);
   type Event_Kind is (Release, Ack, Fin, Timeout);

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

   procedure Step (Current : in out State; Ctx : in out Context; Evt : Event)
   is
      pragma Unreferenced (Ctx);
   begin
      case Current is
         when Established =>
            if Evt.Kind = Release then
               Put_Line ("send: fin");
               Current := Fin_Wait_1;
            end if;

         when Fin_Wait_1  =>
            if Evt.Kind = Ack and then Evt.Ack_Valid then
               Current := Fin_Wait_2;
            end if;

         when Fin_Wait_2  =>
            if Evt.Kind = Fin and then Evt.Fin_Valid then
               Put_Line ("send: ack");
               Current := Timed_Wait;
            end if;

         when Timed_Wait  =>
            if Evt.Kind = Timeout then
               Current := Closed;
            end if;

         when Closed      =>
            null;
      end case;
   end Step;

   package SM is new Sml_Ada.Compiled_Machines (State, Event, Context, Step);
   use SM;

   M   : Machine := Make (Established);
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => Release));
   Process_Event (M, Ctx, (Kind => Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Hello_World_Compiled;
