using namespace System.IO
using namespace System.Collections.Generic
using namespace System.Management.Automation

function New-ReactProject {
    # .SYNOPSIS
    #     create react app
    # .DESCRIPTION
    #     An abstraction function for create-react-app and vite create
    # .LINK
    #     https://vitejs.dev
    # .EXAMPLE
    #     New-ReactProject
    #     creates a vanilla react project with name my-react-app
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = "my-react-app",

        # community teplates: https://github.com/vitejs/awesome-vite#templates
        [Parameter(Mandatory = $false)]
        [string]$template = 'vanilla',

        # Supported name for js packagemanager: [JsPackageManager].GetEnumValues()
        [Parameter(Mandatory = $false)]
        [ValidateScript({ if (!($_ -as 'JsPackageManager' -is [JsPackageManager])) { throw "Please provide a valid name for 'Javascript package manager'." } })]
        [string]$PackageManager = 'pnpm'
    )
    begin {
        enum viteTemplate : int {
            vanilla
            vanilla_ts
            vue
            vue_ts
            react
            react_ts
            react_swc
            react_swc_ts
            preact
            preact_ts
            lit
            lit_ts
            svelte
            svelte_ts
            solid
            solid_ts
            qwik
            qwik_ts
        }

        enum JsPackageManager {
            npm
            yarn
            pnpm
            bun
        }
        class viteBootstrapHelper {
            [ValidateNotNullOrEmpty()][string]$template
            [ValidateNotNullOrEmpty()][string]$command
            [ValidateNotNullOrEmpty()][string]$projectName
            hidden [JsPackageManager]$PackageManager = 'pnpm'
            hidden [string]$ghLinkMatch = 'github.com/'
            hidden [string]$defaultBanch = 'main'

            viteBootstrapHelper([string]$projectName, [string]$template, [string]$PackageManager) {
                $this.template = $template
                $this.projectName = $projectName
                $this.PackageManager = $PackageManager
                $this.setCommand()
            }
            [void] setCommand() {
                $_command = [System.Text.StringBuilder]::new(); [bool]$UseghTemplate = $this.template -like "*$($this.ghLinkMatch)*" -and ($this.template -as 'viteTemplate' -isnot [viteTemplate])
                if (!$UseghTemplate) { [string]$this.template = $this.template.replace('_', '-') }
                switch ($true) {
                    $($this.PackageManager -eq 'npm') {
                        if ($UseghTemplate) {
                            $ghpLink = $this.template.Substring($this.template.IndexOf($($this.ghLinkMatch)) + 10).Split('/')
                            $gitUser = $ghpLink[1]
                            $project = $ghpLink[2]
                            $_command.Append("npx degit $gitUser/$project").Append('#').Append($this.defaultBanch).Append(" $($this.projectName)");
                        } else {
                            $_command.Append('npm create vite@latest').Append(" $($this.projectName)").Append(' -- --template ').Append(" $($this.template)")
                        }
                        break;
                    }
                    $($this.PackageManager -eq 'yarn') {
                        $_command.Append("yarn create vite $($this.projectName) --template $($this.template)")
                        break;
                    }
                    $($this.PackageManager -eq 'pnpm') {
                        $_command.Append("pnpm create vite $($this.projectName) --template $($this.template)")
                        break;
                    }
                    $($this.PackageManager -eq 'bun') {
                        $_command.Append("bun create vite $($this.projectName) --template $($this.template)")
                        break;
                    }
                    Default {
                        throw "could not resolve javascript package manager."
                    }
                }
                $this.command = $_command.ToString()
            }
        }
    }
    process {
        $command = [viteBootstrapHelper]::new($Name, $template, $PackageManager).command
        Write-Verbose "Running command : $command"
        $result = [scriptblock]::Create("$command").Invoke()
    }
    end {
        return $result
    }
}