--  The generator.  Instantiate Codegen on the definition's Machines instance
--  and emit the compiled machine package plus a Graphviz diagram.  Run it from
--  this directory so the files land beside the sources.

with Ada.Text_IO; use Ada.Text_IO;

with Hello_World_Def;
with Sml_Ada.Machines.Codegen;

procedure Generate is
   package Cg is new Hello_World_Def.SM.Codegen;
   F : File_Type;
begin
   Create (F, Out_File, "hello_world_compiled.ads");
   Cg.Put_Compiled_Spec
     (F, Defs_Unit => "Hello_World_Def", Unit => "Hello_World_Compiled");
   Close (F);

   Create (F, Out_File, "hello_world_compiled.adb");
   Cg.Put_Compiled_Body
     (F,
      Hello_World_Def.Table,
      Defs_Unit => "Hello_World_Def",
      Unit      => "Hello_World_Compiled");
   Close (F);

   Create (F, Out_File, "hello_world.dot");
   Cg.Put_Dot
     (F, Hello_World_Def.Table, Hello_World_Def.Initial, Name => "hello_world");
   Close (F);

   Put_Line ("generated hello_world_compiled.{ads,adb} and hello_world.dot");
end Generate;
