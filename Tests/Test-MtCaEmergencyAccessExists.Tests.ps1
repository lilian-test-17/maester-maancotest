  Describe "CUS" -Tag "Custom", "Security", "All" {
    It "Checks if the tenant has at least one emergency/break glass account or account group excluded from all conditional access policies" {
        $MtCaEmergencyAccessExists = Test-MtCaEmergencyAccessExists

        if ($null -ne $MtCaEmergencyAccessExists){
          $MtCaEmergencyAccessExists | Should -Be $false -Because "It is recommended to have at least one emergency/break glass account or account group excluded from all conditional access policies."
          }
        }
      }
