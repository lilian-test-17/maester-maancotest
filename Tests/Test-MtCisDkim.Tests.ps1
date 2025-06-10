  Describe "CUS" -Tag "Custom", "Security", "All" {
    It "CUS.003 - Checks state of DKIM for all EXO domains" {
        $test = Test-MtCisDkim

        if ($null -ne $test){
          $test | Should -Be $DKIM SHOULD be enabled for all domains. CIS Microsoft 365 Foundations Benchmark v4.0.0"
          }
        }
      }
