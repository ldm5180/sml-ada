with AUnit.Test_Cases;

with Sml_Machines_Tests;
with Sml_Simple_Machines_Tests;

package body Sml_Suite is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (Result,
         AUnit.Test_Cases.Test_Case_Access'(new Sml_Machines_Tests.Test));
      AUnit.Test_Suites.Add_Test
        (Result,
         AUnit.Test_Cases.Test_Case_Access'
           (new Sml_Simple_Machines_Tests.Test));
      return Result;
   end Suite;

end Sml_Suite;
