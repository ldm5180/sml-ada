--  The spec-driven generator.  Reads hello_world.fsm (text) and emits:
--    * hello_world_defs.ads      -- the State/Event_Kind/Guard_Kind/Action_Kind
--                                   enums, derived from the transitions
--    * hello_world_machine.ad{s,b} -- a self-contained machine whose
--                                   Process_Event is a jump-table `case`
--    * hello_world.dot           -- a Graphviz diagram
--
--  It is pure text in, text out: it does not depend on the definition being
--  valid Ada, which is exactly what lets it generate the enums you'd otherwise
--  hand-write.  Run it from this directory.

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings;           use Ada.Strings;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Vectors;

procedure Generate is

   package String_Vectors is new
     Ada.Containers.Indefinite_Vectors (Positive, String);

   type Transition is record
      From, On, Guard, Action, To : Unbounded_String;
   end record;

   package Transition_Vectors is new
     Ada.Containers.Indefinite_Vectors (Positive, Transition);

   States  : String_Vectors.Vector;
   Events  : String_Vectors.Vector;
   Guards  : String_Vectors.Vector;
   Actions : String_Vectors.Vector;
   Trans   : Transition_Vectors.Vector;
   Initial : Unbounded_String;

   procedure Add_Unique (V : in out String_Vectors.Vector; Item : String) is
   begin
      if Item /= "" and then not V.Contains (Item) then
         V.Append (Item);
      end if;
   end Add_Unique;

   function Joined (V : String_Vectors.Vector) return String is
      R : Unbounded_String;
   begin
      for I in V.First_Index .. V.Last_Index loop
         if I > V.First_Index then
            Append (R, ", ");
         end if;
         Append (R, V (I));
      end loop;
      return To_String (R);
   end Joined;

   --  Parse one "From + Event [Guard] / Action -> To" line.
   procedure Parse_Transition (Line : String) is
      Arrow  : constant Natural := Index (Line, "->");
      To_S   : constant String := Trim (Line (Arrow + 2 .. Line'Last), Both);
      Left   : constant String := Trim (Line (Line'First .. Arrow - 1), Both);
      Plus   : constant Natural := Index (Left, "+");
      From_S : constant String := Trim (Left (Left'First .. Plus - 1), Both);
      Rest   : Unbounded_String :=
        To_Unbounded_String (Trim (Left (Plus + 1 .. Left'Last), Both));
      Guard_S, Action_S : Unbounded_String;
      LB, RB, Sl        : Natural;
   begin
      LB := Index (To_String (Rest), "[");
      if LB > 0 then
         RB := Index (To_String (Rest), "]");
         Guard_S :=
           To_Unbounded_String (Trim (Slice (Rest, LB + 1, RB - 1), Both));
         Delete (Rest, LB, RB);
      end if;

      Sl := Index (To_String (Rest), "/");
      if Sl > 0 then
         Action_S :=
           To_Unbounded_String (Trim (Slice (Rest, Sl + 1, Length (Rest)), Both));
         Delete (Rest, Sl, Length (Rest));
      end if;

      Add_Unique (States, From_S);
      Add_Unique (States, To_S);
      Add_Unique (Events, Trim (To_String (Rest), Both));
      Add_Unique (Guards, To_String (Guard_S));
      Add_Unique (Actions, To_String (Action_S));
      Trans.Append
        (Transition'
           (From   => To_Unbounded_String (From_S),
            On     => To_Unbounded_String (Trim (To_String (Rest), Both)),
            Guard  => Guard_S,
            Action => Action_S,
            To     => To_Unbounded_String (To_S)));
   end Parse_Transition;

   procedure Read_Spec (Path : String) is
      Spec : File_Type;
   begin
      Open (Spec, In_File, Path);
      while not End_Of_File (Spec) loop
         declare
            Line : constant String := Trim (Get_Line (Spec), Both);
         begin
            if Line = "" or else Line (Line'First) = '#' then
               null;
            elsif Line'Length >= 7
              and then Line (Line'First .. Line'First + 6) = "initial"
            then
               declare
                  After : constant String :=
                    Trim (Line (Line'First + 7 .. Line'Last), Both);
                  Val   : constant String :=
                    (if After'Length > 0 and then After (After'First) = ':'
                     then Trim (After (After'First + 1 .. After'Last), Both)
                     else After);
               begin
                  Initial := To_Unbounded_String (Val);
               end;
            else
               Parse_Transition (Line);
            end if;
         end;
      end loop;
      Close (Spec);
      if Length (Initial) = 0 and then not States.Is_Empty then
         Initial := To_Unbounded_String (States (States.First_Index));
      end if;
   end Read_Spec;

   procedure Emit_Defs is
      F : File_Type;
   begin
      Create (F, Out_File, "hello_world_defs.ads");
      Put_Line (F, "--  Generated from hello_world.fsm.  Do not edit.");
      Put_Line (F, "package Hello_World_Defs is");
      Put_Line (F, "   type State is (" & Joined (States) & ");");
      Put_Line (F, "   type Event_Kind is (" & Joined (Events) & ");");
      if not Guards.Is_Empty then
         Put_Line (F, "   type Guard_Kind is (" & Joined (Guards) & ");");
      end if;
      if not Actions.Is_Empty then
         Put_Line (F, "   type Action_Kind is (" & Joined (Actions) & ");");
      end if;
      Put_Line (F, "end Hello_World_Defs;");
      Close (F);
   end Emit_Defs;

   procedure Emit_Machine_Spec is
      F : File_Type;
   begin
      Create (F, Out_File, "hello_world_machine.ads");
      Put_Line (F, "--  Generated from hello_world.fsm.  Do not edit.");
      Put_Line (F, "with Hello_World_Defs;  use Hello_World_Defs;");
      Put_Line (F, "with Hello_World_Logic; use Hello_World_Logic;");
      Put_Line (F, "package Hello_World_Machine is");
      Put_Line (F, "   type Machine is record");
      Put_Line (F, "      Current : State;");
      Put_Line (F, "   end record;");
      Put_Line
        (F,
         "   function Make (Initial : State := "
         & To_String (Initial)
         & ") return Machine;");
      Put_Line (F, "   function State_Of (M : Machine) return State;");
      Put_Line (F, "   procedure Process_Event");
      Put_Line
        (F, "     (M : in out Machine; Ctx : in out Context; Evt : Event);");
      Put_Line (F, "end Hello_World_Machine;");
      Close (F);
   end Emit_Machine_Spec;

   procedure Emit_Machine_Body is
      F : File_Type;
   begin
      Create (F, Out_File, "hello_world_machine.adb");
      Put_Line (F, "--  Generated from hello_world.fsm.  Do not edit.");
      Put_Line (F, "package body Hello_World_Machine is");
      Put_Line
        (F,
         "   function Make (Initial : State := "
         & To_String (Initial)
         & ") return Machine is");
      Put_Line (F, "     ((Current => Initial));");
      Put_Line
        (F, "   function State_Of (M : Machine) return State is (M.Current);");
      Put_Line (F, "   procedure Process_Event");
      Put_Line
        (F, "     (M : in out Machine; Ctx : in out Context; Evt : Event) is");
      Put_Line (F, "   begin");
      Put_Line (F, "      case M.Current is");
      for I in States.First_Index .. States.Last_Index loop
         declare
            St  : constant String := States (I);
            Any : Boolean := False;
         begin
            Put_Line (F, "         when " & St & " =>");
            for J in Trans.First_Index .. Trans.Last_Index loop
               declare
                  T    : constant Transition := Trans (J);
                  Cond : Unbounded_String;
               begin
                  if To_String (T.From) = St then
                     Any := True;
                     Cond :=
                       To_Unbounded_String ("Evt.Kind = " & To_String (T.On));
                     if Length (T.Guard) > 0 then
                        Append
                          (Cond,
                           " and then Evaluate ("
                           & To_String (T.Guard)
                           & ", Ctx, Evt)");
                     end if;
                     Put_Line
                       (F, "            if " & To_String (Cond) & " then");
                     if Length (T.Action) > 0 then
                        Put_Line
                          (F,
                           "               Execute ("
                           & To_String (T.Action)
                           & ", Ctx, Evt);");
                     end if;
                     Put_Line
                       (F,
                        "               M.Current := "
                        & To_String (T.To)
                        & ";");
                     Put_Line (F, "               return;");
                     Put_Line (F, "            end if;");
                  end if;
               end;
            end loop;
            if not Any then
               Put_Line (F, "            null;");
            end if;
         end;
      end loop;
      Put_Line (F, "      end case;");
      Put_Line (F, "   end Process_Event;");
      Put_Line (F, "end Hello_World_Machine;");
      Close (F);
   end Emit_Machine_Body;

   procedure Emit_Dot is
      F : File_Type;
   begin
      Create (F, Out_File, "hello_world.dot");
      Put_Line (F, "digraph hello_world {");
      Put_Line (F, "   rankdir = LR;");
      Put_Line (F, "   node [shape = box, style = rounded];");
      Put_Line (F, "   __start [shape = point];");
      Put_Line (F, "   __start -> " & To_String (Initial) & ";");
      for J in Trans.First_Index .. Trans.Last_Index loop
         declare
            T   : constant Transition := Trans (J);
            Lbl : Unbounded_String := T.On;
         begin
            if Length (T.Guard) > 0 then
               Append (Lbl, " [" & To_String (T.Guard) & "]");
            end if;
            if Length (T.Action) > 0 then
               Append (Lbl, " / " & To_String (T.Action));
            end if;
            Put_Line
              (F,
               "   "
               & To_String (T.From)
               & " -> "
               & To_String (T.To)
               & " [label="""
               & To_String (Lbl)
               & """];");
         end;
      end loop;
      Put_Line (F, "}");
      Close (F);
   end Emit_Dot;

begin
   Read_Spec ("hello_world.fsm");
   Emit_Defs;
   Emit_Machine_Spec;
   Emit_Machine_Body;
   Emit_Dot;
   Put_Line
     ("generated hello_world_defs.ads, hello_world_machine.{ads,adb}, "
      & "hello_world.dot");
end Generate;
