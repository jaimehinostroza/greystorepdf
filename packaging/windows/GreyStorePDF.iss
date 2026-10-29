; Inno Setup script for the GreyStore PDF Windows installer.
; Built by .github/workflows/windows-installer.yml:
;   iscc /DAppVersion=<version> /DStageDir=<folder with jar, runtime and scripts> GreyStorePDF.iss

#define AppName "GreyStore PDF"
#define AppPublisher "GreyStoreChile"
#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef StageDir
  #define StageDir "..\..\build\windows\app"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\windows\installer"
#endif

#define PowerShell "{sys}\WindowsPowerShell\v1.0\powershell.exe"
#define PsArgs "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File"

[Setup]
; AppId identifies the product for upgrades and uninstall: never change it.
AppId={{DA3C480C-3CF0-41C7-8A13-910ACE8F20C0}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\GreyStore PDF
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=GreyStorePDF-Setup-{#AppVersion}
SetupIconFile=GreyStorePDF.ico
UninstallDisplayIcon={app}\GreyStorePDF.ico
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
LicenseFile={#StageDir}\LICENSE.txt

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "GreyStorePDF.ico"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; Old runtime/JAR files must not survive an upgrade next to the new ones.
Type: filesandordirs; Name: "{app}\runtime"

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{#PowerShell}"; Parameters: "{#PsArgs} ""{app}\GreyStorePDF.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\GreyStorePDF.ico"; Comment: "Abrir GreyStore PDF"
Name: "{autoprograms}\Cerrar {#AppName}"; Filename: "{#PowerShell}"; Parameters: "{#PsArgs} ""{app}\Cerrar-GreyStorePDF.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\GreyStorePDF.ico"; Comment: "Detener GreyStore PDF"
Name: "{autodesktop}\{#AppName}"; Filename: "{#PowerShell}"; Parameters: "{#PsArgs} ""{app}\GreyStorePDF.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\GreyStorePDF.ico"; Tasks: desktopicon

[Run]
Filename: "{#PowerShell}"; Parameters: "{#PsArgs} ""{app}\GreyStorePDF.ps1"""; Description: "Abrir GreyStore PDF ahora"; Flags: postinstall nowait skipifsilent runhidden

[UninstallRun]
Filename: "{#PowerShell}"; Parameters: "{#PsArgs} ""{app}\Cerrar-GreyStorePDF.ps1"" -Quiet"; Flags: runhidden waituntilterminated; RunOnceId: "StopGreyStorePDF"

[Code]
// The running server keeps GreyStorePDF.jar and runtime\ locked, so an upgrade must stop it first.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  StopScript: String;
  ResultCode: Integer;
begin
  Result := '';
  StopScript := ExpandConstant('{app}\Cerrar-GreyStorePDF.ps1');
  if FileExists(StopScript) then
    Exec(ExpandConstant('{#PowerShell}'), '{#PsArgs} "' + StopScript + '" -Quiet', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
