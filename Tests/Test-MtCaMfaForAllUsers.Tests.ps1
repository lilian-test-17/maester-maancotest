  Describe "Cus" -Tag "Custom", "Security" {
    It "CUS 002 - Checks if the tenant has at least one conditional access policy requiring multifactor authentication for all users" {
      $result = Test-MtCaMfaForAllUsers

      if ($null -ne $result) {
        $result | Should -Be $true -Because "MFA for all users conditional access policy can be used to require MFA for all users in the tenant."

      }
   }
}
