--  THE THING YOU AUTHOR (2/3): the generator driver.  Instantiate Codegen on
--  your Machines instance (Hw_Defs.SM) and write the three files.  Run it from
--  the directory where you want the generated sources to land.

with Ada.Text_IO; use Ada.Text_IO;

with Hw_Defs;
with Sml_Ada.Machines.Codegen;

procedure Gen_Hw is
   package Cg is new Hw_Defs.SM.Codegen;
   F : File_Type;
begin
   Create (F, Out_File, "hw_compiled.ads");
   Cg.Put_Compiled_Spec (F, Defs_Unit => "Hw_Defs", Unit => "Hw_Compiled");
   Close (F);

   Create (F, Out_File, "hw_compiled.adb");
   Cg.Put_Compiled_Body
     (F, Hw_Defs.Table, Defs_Unit => "Hw_Defs", Unit => "Hw_Compiled");
   Close (F);

   Create (F, Out_File, "hw.dot");
   Cg.Put_Dot (F, Hw_Defs.Table, Hw_Defs.Initial, Name => "hello_world");
   Close (F);

   Put_Line ("generated hw_compiled.ads, hw_compiled.adb, hw.dot");
end Gen_Hw;
