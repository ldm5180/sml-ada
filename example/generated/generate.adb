--  The spec-driven generator.  Reads hello_world.fsm (text) and emits:
--    * hello_world_defs.ads      -- the State/Event_Kind enums, derived from
--                                   the transitions
--    * hello_world_machine.ad{s,b} -- a self-contained machine whose
--                                   Process_Event is a jump-table `case`
--    * hello_world.dot           -- a Graphviz diagram
--
--  The spec's rows use the SAME operator notation as the Ada engine's table
--  (From + Event (Guard) / Action >= To), and a row pasted from that table --
--  brackets, commas and all -- is accepted, so moving from the engine version
--  to the generated version is copy-paste.  Run it from this directory.
--
--  A malformed spec is rejected with a diagnostic and a non-zero exit status
--  rather than producing partial or non-compiling output.

with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Strings;             use Ada.Strings;
with Ada.Strings.Fixed;       use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Containers.Vectors;
with Ada.Containers.Indefinite_Vectors;

procedure Generate is

   Spec_Error : exception;

   package String_Vectors is new
     Ada.Containers.Indefinite_Vectors (Positive, String);

   type Transition is record
      From, On, Guard, Action, To : Unbounded_String;
   end record;

   package Transition_Vectors is new
     Ada.Containers.Indefinite_Vectors (Positive, Transition);

   States  : String_Vectors.Vector;
   Events  : String_Vectors.Vector;
   Trans   : Transition_Vectors.Vector;
   Initial : Unbounded_String;

   function Is_Ident_Char (C : Character) return Boolean
   is (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_');

   procedure Add_Unique (V : in out String_Vectors.Vector; Item : String) is
   begin
      if not V.Contains (Item) then
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

   --  A row tokenizes to a flat stream of these.  Copy-paste punctuation from
   --  the Ada table ('[', ']', ',', ';') and whitespace are skipped; '+', '/',
   --  '(', ')' and ">=" are the operators; an identifier run is a state, event,
   --  guard or action name.  Anything else is a malformed row.
   type Token_Kind is (Ident, Plus, Slash, L_Paren, R_Paren, Arrow);

   type Token is record
      Kind : Token_Kind;
      Text : Unbounded_String;
   end record;

   package Token_Vectors is new Ada.Containers.Vectors (Positive, Token);

   function Tokenize (Row : String) return Token_Vectors.Vector is
      Result : Token_Vectors.Vector;
      P      : Natural := Row'First;
   begin
      while P <= Row'Last loop
         declare
            C : constant Character := Row (P);
         begin
            if C in ' ' | ASCII.HT | '[' | ']' | ',' | ';' then
               P := P + 1;
            elsif C = '+' then
               Result.Append (Token'(Plus, Null_Unbounded_String));
               P := P + 1;
            elsif C = '/' then
               Result.Append (Token'(Slash, Null_Unbounded_String));
               P := P + 1;
            elsif C = '(' then
               Result.Append (Token'(L_Paren, Null_Unbounded_String));
               P := P + 1;
            elsif C = ')' then
               Result.Append (Token'(R_Paren, Null_Unbounded_String));
               P := P + 1;
            elsif C = '>' and then P < Row'Last and then Row (P + 1) = '=' then
               Result.Append (Token'(Arrow, Null_Unbounded_String));
               P := P + 2;
            elsif Is_Ident_Char (C) then
               declare
                  Start : constant Positive := P;
               begin
                  while P <= Row'Last and then Is_Ident_Char (Row (P)) loop
                     P := P + 1;
                  end loop;
                  Result.Append
                    (Token'
                       (Ident, To_Unbounded_String (Row (Start .. P - 1))));
               end;
            else
               raise Spec_Error
                 with "unexpected character '" & C & "' in row: " & Row;
            end if;
         end;
      end loop;
      return Result;
   end Tokenize;

   --  Parse one "From + Event (Guard) / Action >= To" row; (Guard) and
   --  "/ Action" are optional.  Any other shape raises Spec_Error.
   procedure Parse_Transition (Row : String) is
      Toks : constant Token_Vectors.Vector := Tokenize (Row);
      Pos  : Positive := Toks.First_Index;
      Tr   : Transition;

      function Peek return Token_Kind
      is (if Pos <= Toks.Last_Index then Toks (Pos).Kind else Arrow);
      --  The fallback only has to differ from the kind each Eat expects; the
      --  end-of-row Eat (Arrow) check below catches a genuinely short row.

      procedure Eat (K : Token_Kind) is
      begin
         if Pos > Toks.Last_Index or else Toks (Pos).Kind /= K then
            raise Spec_Error with "malformed transition row: " & Row;
         end if;
         Pos := Pos + 1;
      end Eat;

      function Eat_Ident return Unbounded_String is
      begin
         if Pos > Toks.Last_Index or else Toks (Pos).Kind /= Ident then
            raise Spec_Error with "expected a name in row: " & Row;
         end if;
         return Text : constant Unbounded_String := Toks (Pos).Text do
            Pos := Pos + 1;
         end return;
      end Eat_Ident;
   begin
      Tr.From := Eat_Ident;
      Eat (Plus);
      Tr.On := Eat_Ident;
      if Peek = L_Paren then
         Eat (L_Paren);
         Tr.Guard := Eat_Ident;
         Eat (R_Paren);
      end if;
      if Peek = Slash then
         Eat (Slash);
         Tr.Action := Eat_Ident;
      end if;
      Eat (Arrow);
      Tr.To := Eat_Ident;
      if Pos <= Toks.Last_Index then
         raise Spec_Error with "trailing tokens in row: " & Row;
      end if;

      Add_Unique (States, To_String (Tr.From));
      Add_Unique (States, To_String (Tr.To));
      Add_Unique (Events, To_String (Tr.On));
      Trans.Append (Tr);
   end Parse_Transition;

   --  "Initial => X" / "Initial: X" / "Initial = X" names the start state.  A
   --  transition whose From state is itself called Initial is distinguished by
   --  its separator: a directive uses ':' '=' '>', a transition uses '+'.
   --  Returns the (single identifier) start state, or "" if Line is not the
   --  directive.  Only called when Line begins with the "initial" keyword.
   function Initial_State (Line : String) return String is
      P : Natural := Line'First + 7;  --  past "initial"
   begin
      while P <= Line'Last and then Line (P) in ' ' | ASCII.HT loop
         P := P + 1;
      end loop;
      if P > Line'Last or else Line (P) not in ':' | '=' | '>' then
         return "";
      end if;
      while P <= Line'Last
        and then Line (P) in ':' | '=' | '>' | ' ' | ASCII.HT
      loop
         P := P + 1;
      end loop;
      declare
         Start : constant Positive := P;
      begin
         while P <= Line'Last and then Is_Ident_Char (Line (P)) loop
            P := P + 1;
         end loop;
         return Line (Start .. P - 1);
      end;
   end Initial_State;

   procedure Read_Spec (Path : String) is
      Spec : File_Type;
   begin
      Open (Spec, In_File, Path);
      while not End_Of_File (Spec) loop
         declare
            Line          : constant String := Trim (Get_Line (Spec), Both);
            Looks_Initial : constant Boolean :=
              Line'Length >= 7
              and then To_Lower (Line (Line'First .. Line'First + 6))
                       = "initial"
              and then (Line'Length = 7
                        or else not Is_Ident_Char (Line (Line'First + 7)));
            Start_State   : constant String :=
              (if Looks_Initial then Initial_State (Line) else "");
         begin
            if Line = "" or else Line (Line'First) = '#' then
               null;
            elsif Start_State /= "" then
               Initial := To_Unbounded_String (Start_State);
            elsif Index (Line, ">=") > 0 then
               Parse_Transition (Line);
            else
               null;  --  e.g. a stray "Table : ... :=" wrapper line
            end if;
         end;
      end loop;
      Close (Spec);

      if Trans.Is_Empty then
         raise Spec_Error with "no transitions found in " & Path;
      end if;
      if Length (Initial) = 0 then
         Initial := To_Unbounded_String (States (States.First_Index));
      elsif not States.Contains (To_String (Initial)) then
         raise Spec_Error
           with "initial state " & To_String (Initial) & " is not a state";
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
      Put_Line (F, "   pragma Inline (Make, State_Of, Process_Event);");
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
                           " and then " & To_String (T.Guard) & " (Ctx, Evt)");
                     end if;
                     Put_Line
                       (F, "            if " & To_String (Cond) & " then");
                     if Length (T.Action) > 0 then
                        Put_Line
                          (F,
                           "               "
                           & To_String (T.Action)
                           & " (Ctx, Evt);");
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
exception
   when E : Spec_Error =>
      Put_Line (Standard_Error, "generate: " & Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Generate;
