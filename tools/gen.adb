--  Generator: reads Tcp_Defs (the table is the source of truth) and writes a
--  dissolved compiled package plus a Graphviz diagram.

with Ada.Text_IO; use Ada.Text_IO;

with Tcp_Defs;
with Sml_Ada.Machines.Codegen;

procedure Gen is
   package Cg is new Tcp_Defs.SM.Codegen;
   F : File_Type;
begin
   Create (F, Out_File, "tcp_compiled.ads");
   Cg.Put_Compiled_Spec (F, Defs_Unit => "Tcp_Defs", Unit => "Tcp_Compiled");
   Close (F);

   Create (F, Out_File, "tcp_compiled.adb");
   Cg.Put_Compiled_Body
     (F, Tcp_Defs.Table, Defs_Unit => "Tcp_Defs", Unit => "Tcp_Compiled");
   Close (F);

   Create (F, Out_File, "tcp.dot");
   Cg.Put_Dot (F, Tcp_Defs.Table, Tcp_Defs.Initial, Name => "tcp");
   Close (F);

   Put_Line ("generated tcp_compiled.ads, tcp_compiled.adb, tcp.dot");
end Gen;
