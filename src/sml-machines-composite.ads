--  Composite / hierarchical states: an event goes to the child (the active
--  sub-machine) first; if the child doesn't handle it, the parent does.  The
--  child is abstracted behind Process_Child -- which the caller wires to its
--  child machine's handled-reporting Process_Event -- so the child may be a
--  different machine, and Process_Child can pick a different child per parent
--  state.  Parent and child share the Event and Context types.
--
--     procedure Process_Child
--       (Ctx : in out Context; Evt : Event; Handled : out Boolean) is
--     begin
--        Child_SM.Process_Event (Child, Ctx, Evt, Handled);
--     end Process_Child;
--
--     package Comp is new
--       Parent_SM.Composite (Process_Child => Process_Child);
--     Comp.Process (Parent, Ctx, Evt);

generic
   with
     procedure Process_Child
       (Ctx : in out Context; Evt : Event; Handled : out Boolean);
package Sml.Machines.Composite with SPARK_Mode is

   --  Offer Evt to the child; if it's unhandled there, let the parent
   --  handle it (applying the parent's unhandled policy).
   procedure Process
     (Parent : in out Machine; Ctx : in out Context; Evt : Event)
   with Exceptional_Cases => (Unhandled_Event => True);

end Sml.Machines.Composite;
