with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Reactive;

package body Sml_Reactive_Tests is

   use AUnit.Test_Cases.Registration;

   type Null_Ctx is null record;
   type G is (Always);
   type A is (Nothing);

   --  Phone: dialling settles to Connected on its own via an entry event.
   type P_St is (Idle, Dialing, Connected);
   type P_Ev is (E_Dial, E_Connect);

   type P_Event is record
      Kind : P_Ev;
   end record;

   function P_Kind (E : P_Event) return P_Ev
   is (E.Kind);

   function P_Eval (Gk : G; C : Null_Ctx; E : P_Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end P_Eval;

   procedure P_Exec (Ak : A; C : in out Null_Ctx; E : P_Event) is null;

   package P_SM is new
     Sml.Machines
       (P_St,
        P_Ev,
        P_Event,
        Null_Ctx,
        G,
        A,
        P_Kind,
        P_Eval,
        P_Exec);

   function P_Has (S : P_St) return Boolean
   is (S = Dialing);

   function P_Entry (S : P_St) return P_Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Connect);
   end P_Entry;

   package P_RC is new
     P_SM.Reactive (Has_Entry_Event => P_Has, Entry_Event => P_Entry);

   --!format off
   Phone : constant P_SM.Transition_Table :=
     [(Idle,    E_Dial,    Always, Nothing, Dialing),
      (Dialing, E_Connect, Always, Nothing, Connected)];
   --!format on

   --  Ping/Pong: every state has an entry event, so the chain is cyclic and is
   --  cut off by Max_Steps rather than looping forever.
   type T_St is (Ping, Pong);
   type T_Ev is (E_Beat);

   type T_Event is record
      Kind : T_Ev;
   end record;

   function T_Kind (E : T_Event) return T_Ev
   is (E.Kind);

   function T_Eval (Gk : G; C : Null_Ctx; E : T_Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end T_Eval;

   procedure T_Exec (Ak : A; C : in out Null_Ctx; E : T_Event) is null;

   package T_SM is new
     Sml.Machines
       (T_St,
        T_Ev,
        T_Event,
        Null_Ctx,
        G,
        A,
        T_Kind,
        T_Eval,
        T_Exec);

   function T_Has (S : T_St) return Boolean is
      pragma Unreferenced (S);
   begin
      return True;
   end T_Has;

   function T_Entry (S : T_St) return T_Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Beat);
   end T_Entry;

   package T_RC is new
     T_SM.Reactive
       (Max_Steps       => 3,
        Has_Entry_Event => T_Has,
        Entry_Event     => T_Entry);

   --!format off
   Toggle : constant T_SM.Transition_Table :=
     [(Ping, E_Beat, Always, Nothing, Pong),
      (Pong, E_Beat, Always, Nothing, Ping)];
   --!format on

   procedure Test_Run_To_Completion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      C  : Null_Ctx;
      M1 : P_SM.Machine := P_SM.Make (Phone, Initial => Idle);
      M2 : P_SM.Machine := P_SM.Make (Phone, Initial => Idle);
   begin
      --  One plain event only advances one step.
      P_SM.Process_Event (M1, C, (Kind => E_Dial));
      Assert (P_SM.State_Of (M1) = Dialing, "a single event lands in Dialing");

      --  Run-to-completion processes Dialing's entry event too.
      P_RC.Run_To_Completion (M2, C, (Kind => E_Dial));
      Assert
        (P_SM.State_Of (M2) = Connected,
         "run-to-completion reaches Connected via the entry event");
   end Test_Run_To_Completion;

   procedure Test_Bounded (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      C : Null_Ctx;
      M : T_SM.Machine := T_SM.Make (Toggle, Initial => Ping);
   begin
      --  A cyclic entry-event chain: this must terminate (not hang) at the cap.
      --  Ping -beat-> Pong, then 3 entry steps: Pong->Ping->Pong->Ping.
      T_RC.Run_To_Completion (M, C, (Kind => E_Beat));
      Assert
        (T_SM.State_Of (M) = Ping,
         "cyclic entry events stop after Max_Steps without looping forever");
   end Test_Bounded;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Run_To_Completion'Access,
         "Run_To_Completion follows entry events to a settled state");
      Register_Routine
        (T,
         Test_Bounded'Access,
         "Max_Steps bounds a cyclic entry-event chain");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Reactive (run-to-completion)");
   end Name;

end Sml_Reactive_Tests;
