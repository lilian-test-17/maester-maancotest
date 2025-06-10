  Describe "CUS" -Tag "Custom", "Security", "All" {
    It "CUS.001 - BreakGlass" {
        $MtCaEmergencyAccessExists = Test-MtCaEmergencyAccessExists

        if ($null -ne $MtCaEmergencyAccessExists){
          $MtCaEmergencyAccessExists | Should -Be $true -Because "It is recommended to have at least one emergency/break glass account or account group excluded from all conditional access policies."
          }
        }
      }
