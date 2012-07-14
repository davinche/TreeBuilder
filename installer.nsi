!define SNAME "TreeBuilder 0.1 Installer"

!include Registry.nsh

CRCCheck off
AutoCloseWindow true
SilentInstall silent
XPStyle on
WindowIcon off
SetOverwrite on

SetCompress force
SetDatablockOptimize on

Name "${SNAME}"
Icon "icon.ico"
Caption "${SNAME}"
OutFile "${SNAME}.exe"

VIProductVersion "0.0.0.1"
VIAddVersionKey ProductName "${SNAME}"
VIAddVersionKey FileVersion "0.0.0.1"
VIAddVersionKey FileDescription "${SNAME}"

Section "main"
	InitPluginsDir
	SetOutPath $PLUGINSDIR
	File /r "res"
	File TreeBuilder.exe
	CopyFiles "$PLUGINSDIR\res" "$PROGRAMFILES\TreeBuilder\res"
	CopyFiles $PLUGINSDIR\TreeBuilder.exe "$PROGRAMFILES\TreeBuilder\"
	CreateShortCut "$DESKTOP\TreeBuilder.lnk" "$PROGRAMFILES\TreeBuilder\TreeBuilder.exe"
	MessageBox MB_OK "Installation was successful."
SectionEnd