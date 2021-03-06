function Unzip-File {

<#
.SYNOPSIS
   Unzip-File is a function which extracts the contents of a zip file.

.DESCRIPTION
   Unzip-File is a function which extracts the contents of a zip file specified via the -File parameter to the
location specified via the -Destination parameter. This function first checks to see if the .NET Framework 4.5
is installed and uses it for the unzipping process, otherwise COM is used.

.PARAMETER File
    The complete path and name of the zip file in this format: C:\zipfiles\myzipfile.zip

.PARAMETER Destination
    The destination folder to extract the contents of the zip file to. If a path is no specified, the current path
is used.

.PARAMETER ForceCOM
    Switch parameter to force the use of COM for the extraction even if the .NET Framework 4.5 is present.

.EXAMPLE
   Unzip-File -File C:\zipfiles\AdventureWorks2012_Database.zip -Destination C:\databases\

.EXAMPLE
   Unzip-File -File C:\zipfiles\AdventureWorks2012_Database.zip -Destination C:\databases\ -ForceCOM

.EXAMPLE
   'C:\zipfiles\AdventureWorks2012_Database.zip' | Unzip-File

.EXAMPLE
    Get-ChildItem -Path C:\zipfiles | ForEach-Object {$_.fullname | Unzip-File -Destination C:\databases}

.INPUTS
   String

.OUTPUTS
   None

.NOTES
   Author:  Mike F Robbins
   Website: http://mikefrobbins.com
   Twitter: @mikefrobbins

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({
            If ((Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.zip")) {
                $true
            }
            else {
                Throw "$_ is not a valid zip file. Enter in 'c:\folder\file.zip' format"
            }
        })]
        [string]$File,

        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If (Test-Path -Path $_ -PathType Container) {
                $true
            }
            else {
                Throw "$_ is not a valid destination folder. Enter in 'c:\destination' format"
            }
        })]
        [string]$Destination = (Get-Location).Path,

        [switch]$ForceCOM
    )


    If (-not $ForceCOM -and ($PSVersionTable.PSVersion.Major -ge 3) -and
       ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or
       (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) {

        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using .NET 4.5"

        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$File", "$Destination")
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }


    }
    else {

        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using COM"

        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destination).copyhere(($shell.NameSpace($file)).items())
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }

    }

}

$id = Read-Host 'ID del projecto'
$ProjectPath = "E:\Proyectos\$id"
$ProjectDesarrolloPath = "$ProjectPath\Desarrollo"
$ProjectWebPath = "E:\wamp\vhosts\$id.localwamp.dev\web"

if(Test-Path -path $ProjectPath){
	Remove-Item $ProjectPath\* -Force -Recurse
	Remove-Item $ProjectPath -Force -Recurse
}
if(Test-Path -path $ProjectWebPath){
	Remove-Item $ProjectWebPath\* -Force -Recurse
	Remove-Item $ProjectWebPath -Force -Recurse
}

New-Item -ItemType Directory -Force -Path $ProjectPath
New-Item -ItemType Directory -Force -Path $ProjectDesarrolloPath
New-Item -ItemType Directory -Force -Path $ProjectWebPath

$title = "GIT"
$message = "Utiliza Git?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Solicitara y clonara el repositorio."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Creara las carpetas limpias"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
$git = $host.ui.PromptForChoice($title, $message, $options, 0)

if($git){
	$gitUrl = Read-Host 'Repositorio GIT'
	git clone "$gitUrl" $ProjectDesarrolloPath
}

$title = "Laravel"
$message = "Implementa Laravel?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Descarga Laravel"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Creara un proyecto vacio"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
$laravel = $host.ui.PromptForChoice($title, $message, $options, 0)

if($laravel){
	$storageDir = $pwd
	$webclient = New-Object System.Net.WebClient
	$url = "https://github.com/laravel/laravel/archive/master.zip"
	$laravelZip = "$ProjectPath\laravelBase.zip"
	$webclient.DownloadFile($url,$laravelZip)
	Unzip-File -File $laravelZip -Destination $ProjectPath
	Move-Item $ProjectPath\laravel-master\* $ProjectDesarrolloPath
	composer install -d $ProjectDesarrolloPath
	Remove-Item $ProjectPath\laravel-master -Force -Recurse
	Remove-Item $laravelZip -Force -Recurse
	New-Item -ItemType Directory -Force -Path $ProjectDesarrolloPath\app\views\home
	New-Item -ItemType Directory -Force -Path $ProjectDesarrolloPath\app\views\layouts
}

if(!$laravel){
	New-Item -ItemType Directory -Force -Path $ProjectDesarrolloPath\public
}

cmd /c mklink /J $ProjectWebPath\content $ProjectDesarrolloPath\public

$title = "MySQL"
$message = "Crear base de datos?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Se crea la base de datos"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "No crea base de datos"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
$mysql = $host.ui.PromptForChoice($title, $message, $options, 0)

if($mysql){
	& E:\wamp\bin\mysql\mysql5.6.17\bin\mysql.exe --host=127.0.0.1 --user=root -e "CREATE SCHEMA $id ;"
}

$arguments = "& echo 127.0.0.1       $id.localwamp.dev >> C:\Windows\System32\drivers\etc\hosts"
Start-Process powershell -Verb runAs -ArgumentList $arguments

& ipconfig /flushdns
& ipconfig /registerdns

