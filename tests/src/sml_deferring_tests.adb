with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Deferring;

package body Sml_Deferring_Tests is

   use AUnit.Test_Cases.Registration;

   --  A media player: Pause makes no sense while Stopped, so it is deferred and
   --  re-delivered once Play moves it to Playing.
   type St is (Stopped, Playing, Paused);
   type Ev is (E_Play, E_Pause, E_Stop);

   type Evt is record
      Kind : Ev;
   end record;

   type Null_Ctx is null record;
   type G is (Always);
   type A is (Nothing);

   function Kind_Of (E : Evt) return Ev
   is (E.Kind);

   function Evaluate (Gk : G; C : Null_Ctx; E : Evt) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end Evaluate;

   procedure Execute (Ak : A; C : in out Null_Ctx; E : Evt) is null;

   function Deferred (S : St; E : Ev) return Boolean
   is (S = Stopped and then E = E_Pause);

   function Rebuild (E : Ev) return Evt
   is ((Kind => E));

   package SM is new
     Sml.Machines (St, Ev, Evt, Null_Ctx, G, A, Kind_Of, Evaluate, Execute);
   use SM;

   package Def is new SM.Deferring (Deferred => Deferred, Rebuild => Rebuild);
   package Def2 is new
     SM.Deferring (Capacity => 2, Deferred => Deferred, Rebuild => Rebuild);

   --!format off
   Table : constant Transition_Table :=
     [(Stopped, E_Play,  Always, Nothing, Playing),
      (Playing, E_Pause, Always, Nothing, Paused),
      (Playing, E_Stop,  Always, Nothing, Stopped),
      (Paused,  E_Play,  Always, Nothing, Playing),
      (Paused,  E_Stop,  Always, Nothing, Stopped)];
   --!format on

   procedure Test_Defer_And_Redeliver
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Stopped);
      Q : Def.Deferral_Queue := Def.Empty_Queue;
      C : Null_Ctx;
   begin
      --  Pause while Stopped: unhandled but deferred, so it is queued.
      Def.Post (M, Q, C, (Kind => E_Pause));
      Assert (State_Of (M) = Stopped, "Pause does not move from Stopped");
      Assert (Def.Pending (Q) = 1, "Pause is deferred (queued)");

      --  Play is handled (-> Playing) and then the deferred Pause re-delivers.
      Def.Post (M, Q, C, (Kind => E_Play));
      Assert
        (State_Of (M) = Paused,
         "Play runs, then the deferred Pause re-delivers to Paused");
      Assert (Def.Pending (Q) = 0, "the queue drained");
   end Test_Defer_And_Redeliver;

   procedure Test_Non_Deferred_Dropped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Stopped);
      Q : Def.Deferral_Queue := Def.Empty_Queue;
      C : Null_Ctx;
   begin
      --  Stop while Stopped is unhandled and not deferred -> dropped, not queued.
      Def.Post (M, Q, C, (Kind => E_Stop));
      Assert (State_Of (M) = Stopped, "Stop stays Stopped");
      Assert
        (Def.Pending (Q) = 0, "a non-deferred unhandled event is dropped");
   end Test_Non_Deferred_Dropped;

   procedure Test_Overflow (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Stopped);
      Q : Def2.Deferral_Queue := Def2.Empty_Queue;
      C : Null_Ctx;
   begin
      Def2.Post (M, Q, C, (Kind => E_Pause));  --  queued (1)
      Def2.Post (M, Q, C, (Kind => E_Pause));  --  queued (2, full)
      Def2.Post (M, Q, C, (Kind => E_Pause));  --  overflow
      Assert (False, "third deferral should overflow the capacity-2 queue");
   exception
      when Def2.Deferral_Overflow =>
         null;  --  expected
   end Test_Overflow;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Defer_And_Redeliver'Access,
         "A deferred event is queued and re-delivered after the next step");
      Register_Routine
        (T,
         Test_Non_Deferred_Dropped'Access,
         "A non-deferred unhandled event is dropped");
      Register_Routine
        (T,
         Test_Overflow'Access,
         "Capacity overflow raises Deferral_Overflow");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Deferring (deferred events)");
   end Name;

end Sml_Deferring_Tests;
