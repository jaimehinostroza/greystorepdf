; Inno Setup script for the GreyStore PDF Windows installer.
; Built by .github/workflows/windows-installer.yml:
;   iscc /DAppVersion=<version> /DStageDir=<app folder> [/DSigned /Sgssign=<signtool command>] GreyStorePDF.iss
; StageDir holds GreyStorePDF.exe (launcher), GreyStorePDF.jar, runtime\ and LICENSE.txt, plus
; GreyStoreChile.cer when the build is signed.

#define AppName "GreyStore PDF"
#define AppPublisher "GreyStoreChile"
#define AppUrl "https://greystorechile.cl"
#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef StageDir
  #define StageDir "..\..\build\windows\app"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\windows\installer"
#endif

[Setup]
; AppId identifies the product for upgrades and uninstall: never change it.
AppId={{DA3C480C-3CF0-41C7-8A13-910ACE8F20C0}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppSupportPhone=+56 9 5069 0280
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
UninstallDisplayIcon={app}\GreyStorePDF.exe
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
LicenseFile={#StageDir}\LICENSE.txt
#ifdef Signed
SignTool=gssign
SignedUninstaller=yes
#endif

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"
#ifdef Signed
; Only offered when installing for all users: trusting a certificate machine-wide needs administrator rights.
Name: "trustcert"; Description: "Confiar en el certificado de GreyStoreChile en este equipo (recomendado)"; GroupDescription: "Seguridad:"; Check: IsAdminInstallMode
#endif

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[InstallDelete]
; Old runtime files must not survive an upgrade next to the new ones; the .ps1 launchers predate GreyStorePDF.exe.
Type: filesandordirs; Name: "{app}\runtime"
Type: files; Name: "{app}\GreyStorePDF.ps1"
Type: files; Name: "{app}\Cerrar-GreyStorePDF.ps1"
Type: files; Name: "{app}\GreyStorePDF.ico"

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\GreyStorePDF.exe"; WorkingDir: "{app}"; Comment: "Abrir GreyStore PDF"
Name: "{autoprograms}\Cerrar {#AppName}"; Filename: "{app}\GreyStorePDF.exe"; Parameters: "--stop"; WorkingDir: "{app}"; Comment: "Detener GreyStore PDF"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\GreyStorePDF.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
#ifdef Signed
Filename: "{sys}\certutil.exe"; Parameters: "-f -addstore Root ""{app}\GreyStoreChile.cer"""; Flags: runhidden waituntilterminated; Tasks: trustcert; StatusMsg: "Registrando el certificado de GreyStoreChile..."
Filename: "{sys}\certutil.exe"; Parameters: "-f -addstore TrustedPublisher ""{app}\GreyStoreChile.cer"""; Flags: runhidden waituntilterminated; Tasks: trustcert
#endif
; runasoriginaluser: in an all-users install the server must still start with the signed-in user's
; %LOCALAPPDATA%, not the elevated account's.
Filename: "{app}\GreyStorePDF.exe"; Description: "Abrir GreyStore PDF ahora"; Flags: postinstall nowait skipifsilent runasoriginaluser

[UninstallRun]
Filename: "{app}\GreyStorePDF.exe"; Parameters: "--stop --quiet"; Flags: runhidden waituntilterminated; RunOnceId: "StopGreyStorePDF"

[Code]
// The running server keeps GreyStorePDF.jar and runtime\ locked, so an upgrade must stop it first.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
  LegacyStopScript: String;
begin
  Result := '';
  if FileExists(ExpandConstant('{app}\GreyStorePDF.exe')) then
    Exec(ExpandConstant('{app}\GreyStorePDF.exe'), '--stop --quiet', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  else
  begin
    LegacyStopScript := ExpandConstant('{app}\Cerrar-GreyStorePDF.ps1');
    if FileExists(LegacyStopScript) then
      Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
        '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + LegacyStopScript + '" -Quiet',
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
