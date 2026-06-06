package body Turnstile_Proof
  with SPARK_Mode
is

   function Coin_Then_Push return State is
      M : Turnstile.Machine := Turnstile.Make;
   begin
      Turnstile.Process_Event (M, Coin);
      Turnstile.Process_Event (M, Push);
      return Turnstile.State_Of (M);
   end Coin_Then_Push;

end Turnstile_Proof;
