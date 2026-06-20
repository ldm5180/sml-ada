pragma Ada_2022;

--  Demonstrates orthogonal regions: one device that is SIMULTANEOUSLY in two
--  independent concurrent regions, each its own machine, both advanced by the
--  same event stream.  Here a media player has a Playback region
--  (Stopped/Playing/Paused) and a Volume region (Normal/Muted): Mute toggles
--  volume regardless of playback, Play/Pause/Stop move playback regardless of
--  volume, so the device's state is the *combination* of the two -- e.g. you
--  can be (Playing, Muted) or (Paused, Normal) independently.
--
--  Because the regions are DIFFERENT machines they are dispatched by hand (each
--  ignores events it doesn't own).  When instead you have N *identical* regions,
--  Sml.Machines.Regions.Broadcast fans one event out to all of them -- the
--  homogeneous case, shown briefly at the end.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Machines.Regions;

procedure Orthogonal_Regions is

   --  Both regions share one event vocabulary and context.
   type Event_Kind is (E_Play, E_Pause, E_Stop, E_Mute);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   --  Region 1: playback.  Has no row for Mute, so it ignores it.
   type Playback_State is (Stopped, Playing, Paused);
   package Playback_SM is new
     Sml.Machines
       (Playback_State,
        Event_Kind,
        Event,
        Context,
        Guard_Kind,
        Action_Kind,
        Kind_Of,
        Evaluate,
        Execute);
   package Playback_Op is new
     Playback_SM.Operators (Always => Always, Nothing => Nothing);

   --  Region 2: volume.  Has no row for Play/Pause/Stop, so it ignores them.
   type Volume_State is (Normal, Muted);
   package Volume_SM is new
     Sml.Machines
       (Volume_State,
        Event_Kind,
        Event,
        Context,
        Guard_Kind,
        Action_Kind,
        Kind_Of,
        Evaluate,
        Execute);
   package Volume_Op is new
     Volume_SM.Operators (Always => Always, Nothing => Nothing);

   --  Operators from both layers; each row resolves by its operand types.
   use Playback_Op, Volume_Op;

   Play  : constant Playback_Op.Ev := (Kind => E_Play);
   Pause : constant Playback_Op.Ev := (Kind => E_Pause);
   Stop  : constant Playback_Op.Ev := (Kind => E_Stop);
   Mute  : constant Volume_Op.Ev := (Kind => E_Mute);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Playback_Table : constant Playback_SM.Transition_Table :=
     [Stopped + Play  >= Playing,
      Playing + Pause >= Paused,
      Playing + Stop  >= Stopped,
      Paused  + Play  >= Playing,
      Paused  + Stop  >= Stopped];

   Volume_Table : constant Volume_SM.Transition_Table :=
     [Normal + Mute >= Muted,
      Muted  + Mute >= Normal];
   --!format on

   Playback : Playback_SM.Machine :=
     Playback_SM.Make (Playback_Table, Initial => Stopped);
   Volume   : Volume_SM.Machine :=
     Volume_SM.Make (Volume_Table, Initial => Normal);
   Ctx      : Context;

   --  Offer one event to BOTH regions; each leaves itself unchanged for an
   --  event it doesn't own (unhandled -> the default Stay policy).
   procedure Dispatch (Evt : Event) is
   begin
      Playback_SM.Process_Event (Playback, Ctx, Evt);
      Volume_SM.Process_Event (Volume, Ctx, Evt);
   end Dispatch;

   procedure Show (Label : String) is
   begin
      Put_Line
        (Label
         & ":  playback="
         & Playback_SM.State_Of (Playback)'Image
         & "  volume="
         & Volume_SM.State_Of (Volume)'Image);
   end Show;

begin
   Show ("start");

   Dispatch ((Kind => E_Play));   --  playback advances; volume ignores it
   Show ("play ");
   pragma Assert (Playback_SM.State_Of (Playback) = Playing);
   pragma Assert (Volume_SM.State_Of (Volume) = Normal);

   Dispatch ((Kind => E_Mute));   --  volume toggles; playback ignores it
   Show ("mute ");
   pragma Assert (Playback_SM.State_Of (Playback) = Playing);
   pragma Assert (Volume_SM.State_Of (Volume) = Muted);

   Dispatch ((Kind => E_Pause));  --  playback advances; volume stays muted
   Show ("pause");
   pragma Assert (Playback_SM.State_Of (Playback) = Paused);
   pragma Assert (Volume_SM.State_Of (Volume) = Muted);
   --  The regions are independent: (Paused, Muted) is one combined state.

   --  Contrast -- the homogeneous case: when the regions are IDENTICAL replicas
   --  of one machine, Sml.Machines.Regions.Broadcast fans one event to all of
   --  them.  Three identical volume knobs, all muted by a single Mute:
   declare
      package Reg is new Volume_SM.Regions (Count => Volume_Table'Length);
      use Reg;
      Knobs : Region_Array :=
        [Volume_SM.Make (Volume_Table, Initial => Normal),
         Volume_SM.Make (Volume_Table, Initial => Normal),
         Volume_SM.Make (Volume_Table, Initial => Normal)];
      C     : Context;
   begin
      Broadcast (Knobs, C, (Kind => E_Mute));
      Put_Line
        ("broadcast Mute to 3 identical knobs -> all "
         & (if All_In (Knobs, Muted) then "Muted" else "mixed"));
      pragma Assert (All_In (Knobs, Muted));
   end;
end Orthogonal_Regions;
