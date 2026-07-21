with AUnit.Test_Cases;

with Sml_Machines_Tests;
with Sml_Simple_Machines_Tests;
with Sml_Regions_Tests;
with Sml_Reactive_Tests;
with Sml_Deferring_Tests;
with Sml_Composite_Tests;
with Sml_Bundled_Tests;
with Sml_Tracing_Tests;
with Sml_Trace_Gate_Tests;
with Sml_Effects_Loop_Tests;

package body Sml_Suite is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;

      procedure Add (T : AUnit.Test_Cases.Test_Case_Access) is
      begin
         AUnit.Test_Suites.Add_Test (Result, T);
      end Add;
   begin
      Add (new Sml_Machines_Tests.Test);
      Add (new Sml_Simple_Machines_Tests.Test);
      Add (new Sml_Regions_Tests.Test);
      Add (new Sml_Reactive_Tests.Test);
      Add (new Sml_Deferring_Tests.Test);
      Add (new Sml_Composite_Tests.Test);
      Add (new Sml_Bundled_Tests.Test);
      Add (new Sml_Tracing_Tests.Test);
      Add (new Sml_Trace_Gate_Tests.Test);
      Add (new Sml_Effects_Loop_Tests.Test);
      return Result;
   end Suite;

end Sml_Suite;
