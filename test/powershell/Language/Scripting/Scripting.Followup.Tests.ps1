# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
Describe "Scripting.Followup.Tests" -Tags "CI" {
    It "'[void](New-Item) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            [void](New-Item $testFile -ItemType File) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
            ## file should be created
            $testFile | Should -Exist
        } finally {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    ## cast non-void method call to [void]
    It "'[void]`$arraylist.Add(1) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        [void]$arraylist.Add(1) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        ## $arraylist.Add(1) should be executed
        $arraylist.Count | Should -Be 1
        $arraylist[0] | Should -Be 1
    }

    ## void method call
    It "'`$arraylist2.Clear() | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        $arraylist.Add(1) > $null
        $arraylist.Clear() | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        ## $arraylist.Clear() should be executed
        $arraylist.Count | Should -Be 0
    }

    ## fix https://github.com/PowerShell/PowerShell/issues/17165
    It "([bool] `$var = 42) should return the varaible value" {
        ([bool]$var = 42).GetType().FullName | Should -Be "System.Boolean"
        . { ([bool]$var = 42).GetType().FullName } | Should -Be "System.Boolean"
    }

    It "Setting property using 'ForEach' method should work on a scalar object" {
        $obj = [pscustomobject] @{ p = 1 }
        $obj.ForEach('p', 32) | Should -BeNullOrEmpty
        $obj.p | Should -Be 32
    }

    It "Test the special type name 'ordered'" {
        class ordered {
            [hashtable] $Member
            ordered([hashtable] $hash) {
                $this.Member = $hash
            }
        }

        ## `<expr> -as\-is [ordered]` resolves 'ordered' as a normal type name.
        $hash = @{ key = 2 }
        $result = $hash -as [ordered]
        $result.GetType().FullName | Should -BeExactly ([ordered].FullName)
        $result -is [ordered] | Should -BeTrue
        $result.Member['key'] | Should -Be 2
        $result.Member.Count | Should -Be 1

        ## `[ordered]$hash` causes parsing error.
        $err = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput('[ordered]$hash', [ref]$null, [ref]$err)
        $err.Count | Should -Be 1
        $err[0].ErrorId | Should -BeExactly 'OrderedAttributeOnlyOnHashLiteralNode'

        ## `[ordered]@{ key = 1 }` creates 'OrderedDictionary'
        $result = [ordered]@{ key = 1 }
        $result | Should -BeOfType 'System.Collections.Specialized.OrderedDictionary'
    }
}
