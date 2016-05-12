param (
    [string]$server = ".",
    [string]$dir = ".",                                   
    [string]$outfile = $(throw "-outfile is required"),
    [string]$user = $(throw "-user is required."),
    [string]$dbName = $(throw "-dbname is required"),
    [string]$pwd = $( Read-Host "Input password, please" )
 )



# set "Option Explicit" to catch subtle errors
set-psdebug -strict

$ErrorActionPreference = "stop"                           # you can opt to stagger on, bleeding, if an error occurs

# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$ms='Microsoft.SqlServer'
$v = [System.Reflection.Assembly]::LoadWithPartialName( "$ms.SMO")
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') 
{
    [System.Reflection.Assembly]::LoadWithPartialName("$ms.SMOExtended") | out-null
}
$My="$ms.Management.Smo" #
$s = new-object ("$My.Server") $server
if ($s.Version -eq  $null ){Throw "Can't find the mssql instance '$server'"}

$db= $s.Databases[$dbName] 
if ($db.name -ne $dbName){Throw "database '$dbName' not found in '$server'"};
$transfer = new-object ("$My.Transfer") $db

# scripting options
$CreationScriptOptions = new-object ("$My.ScriptingOptions") 
$CreationScriptOptions.ExtendedProperties= $true              # yes, we want these
$CreationScriptOptions.DRIAll= $true                          # and all the constraints 
$CreationScriptOptions.Indexes= $true                         # and the indexes
$CreationScriptOptions.Triggers= $true                        # and the triggers
$CreationScriptOptions.Statistics = $true                     # and any statistics
$CreationScriptOptions.ScriptBatchTerminator = $true          # this only goes to the file
$CreationScriptOptions.IncludeHeaders = $false;               # less 'noise' in the output file
$CreationScriptOptions.ToFileOnly = $true                     # no need of string output as well
$CreationScriptOptions.IncludeIfNotExists = $false;           # don't check for existing objects
$CreationScriptOptions.ScriptOwner = $false;                  # don't specify [dbo]. owner
$CreationScriptOptions.SchemaQualify = $true;                 # include schema if one exisets
$CreationScriptOptions.Encoding = [System.Text.Encoding]::UTF8;  # default is UTF-16, and git thinks that's binary     
$CreationScriptOptions.EnforceScriptingOptions = $true;

$path = Convert-Path $dir;
$outFile = "$($path)\$outfile.sql"; 
$CreationScriptOptions.Filename = $outFile;
$transfer = new-object ("$My.Transfer") $s.Databases[$dbname]

$transfer.options=$CreationScriptOptions 
"scripting db '$dbname' to '$outFile' ..."
$transfer.ScriptTransfer()
"done"
