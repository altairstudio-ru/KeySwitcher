; ============================================================
;  installer.iss — установщик AltaiR Key Switcher (Inno Setup 6)
;  Сборка:  ISCC.exe build\installer.iss
;  Результат: dist\AltaiR-Key-Switcher-<версия>-setup.exe
; ============================================================

#define MyAppName      "AltaiR Key Switcher"
#define MyAppVersion   "1.2.0"
#define MyAppPublisher "Altair Studio"
#define MyAppURL       "https://github.com/altairstudio-ru/KeySwitcher"
#define MyExeName      "layout-switcher.exe"

[Setup]
AppId={{8A0E9A3C-52D7-4D6B-9E4A-7A4C1B5F0A21}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={localappdata}\LayoutSwitcher
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=AltaiR-Key-Switcher-{#MyAppVersion}-setup
SetupIconFile=..\icon.ico
VersionInfoVersion={#MyAppVersion}
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Ярлык на рабочем столе"; GroupDescription: "Дополнительно:"; Flags: unchecked
Name: "autostart"; Description: "Запускать {#MyAppName} при входе в Windows"; GroupDescription: "Дополнительно:"
Name: "ctxmenu"; Description: "Пункт меню Проводника «Исправить раскладку в имени»"; GroupDescription: "Дополнительно:"

[Files]
Source: "..\{#MyExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\config.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist
; иконки нужны программе в рантайме: logo окна About и иконка трея
Source: "..\icon.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\altair_tray.ico"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
; при обновлении убираем старую «исходниковую» установку
Type: files; Name: "{app}\AutoHotkey64.exe"
Type: files; Name: "{app}\layout-switcher.ahk"
Type: files; Name: "{app}\layout-map.ahk"
Type: filesandordirs; Name: "{app}\src"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: autostart

[Registry]
; ПКМ по файлу или папке в Проводнике -> конвертация имени
Root: HKCU; Subkey: "Software\Classes\*\shell\AltaiRKeySwitcher"; ValueType: string; ValueName: ""; ValueData: "Исправить раскладку в имени"; Flags: uninsdeletekey; Tasks: ctxmenu
Root: HKCU; Subkey: "Software\Classes\*\shell\AltaiRKeySwitcher"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\{#MyExeName}"",0"; Tasks: ctxmenu
Root: HKCU; Subkey: "Software\Classes\*\shell\AltaiRKeySwitcher\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyExeName}"" --convert-filename ""%1"""; Tasks: ctxmenu
Root: HKCU; Subkey: "Software\Classes\Directory\shell\AltaiRKeySwitcher"; ValueType: string; ValueName: ""; ValueData: "Исправить раскладку в имени"; Flags: uninsdeletekey; Tasks: ctxmenu
Root: HKCU; Subkey: "Software\Classes\Directory\shell\AltaiRKeySwitcher"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\{#MyExeName}"",0"; Tasks: ctxmenu
Root: HKCU; Subkey: "Software\Classes\Directory\shell\AltaiRKeySwitcher\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyExeName}"" --convert-filename ""%1"""; Tasks: ctxmenu

[Run]
Filename: "{app}\{#MyExeName}"; Description: "Запустить {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Перед установкой завершить запущенный экземпляр, иначе exe не заменится.
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
    Exec('taskkill.exe', '/F /IM {#MyExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
