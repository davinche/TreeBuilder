#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=icon.ico
#AutoIt3Wrapper_outfile=C:\Users\Vincent\Desktop\TreeBuilder.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.0.0.1
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <Constants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBoxEx.au3>
#include <GUITreeView.au3>
#include <StaticConstants.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>

#include "include\functions.au3"
#include "ContentManager.au3"

FileChangeDir(@ScriptDir)
Opt('MustDeclareVars', 1)
Opt("TrayMenuMode", 1)

;---------- Constants and Global Variables -------------------
Global Const $APPVERSION = "0.1"
Global Const $TEMPLATESDIR = "templates\"
Global $TreeBuilder, $ContentManager
Global $structureTree, $root, $basePathText, $fromTemplate
Global $TMITEM_Open, $TMITEM_Exit
Global $treebuilderico = "icon.ico", $folderico = "res\folder.ico", $fileico = "res\file.ico"

_Init()
_Main()
Exit

Func _Init()
	If Not FileExists($TEMPLATESDIR) Then
		DirCreate($TEMPLATESDIR)
	EndIf
EndFunc   ;==>_Init

Func _Main()
	Local $LbasePath, $Lstructure, $Ltemplate
	Local $browseBtn, $createBtn
	Local $M_FILE, $M_Options, $M_Help, $MITEM_NewFolder, $MITEM_NewFile, $MITEM_SaveTemplate, $MITEM_Exit, $MITEM_ContentManager, $MITEM_Doc, $MITEM_About
	Local $guiWidth = 538, $guiHeight = 546

	;Center the GUI on the screen
	$TreeBuilder = GUICreate("TreeBuilder - " & $APPVERSION, $guiWidth, $guiHeight, (@DesktopWidth - $guiWidth) / 2, (@DesktopHeight - $guiHeight) / 2)

	;---------- Main Menu -------------------
	$M_FILE = GUICtrlCreateMenu("&File")
	$MITEM_NewFile = GUICtrlCreateMenuItem("New File" & @TAB & "Ctrl+N", $M_FILE)
	$MITEM_NewFolder = GUICtrlCreateMenuItem("New Folder" & @TAB & "Ctrl+Shift+N", $M_FILE)
	GUICtrlCreateMenuItem("", $M_FILE)
	$MITEM_SaveTemplate = GUICtrlCreateMenuItem("&Save as Template" & @TAB & "Ctrl+S", $M_FILE)
	GUICtrlCreateMenuItem("", $M_FILE)
	$MITEM_Exit = GUICtrlCreateMenuItem("Exit" & @TAB & "Alt+X", $M_FILE)
	$M_Options = GUICtrlCreateMenu("&Options")
	$MITEM_ContentManager = GUICtrlCreateMenuItem("Content Manager", $M_Options)
	$M_Help = GUICtrlCreateMenu("&Help")
	$MITEM_Doc = GUICtrlCreateMenuItem("Documentation", $M_Help)
	GUICtrlCreateMenuItem("", $M_Help)
	$MITEM_About = GUICtrlCreateMenuItem("About", $M_Help)

	;---------- Tray Menu -------------------
	TraySetIcon($treebuilderico, 0)
	TraySetClick(16)
	$TMITEM_Open = TrayCreateItem("Open Tree Builder")
	TrayCreateItem("")
	$TMITEM_Exit = TrayCreateItem("Exit")

	;---------- TreeBuilder GUI -------------------
	GUISetFont(9, 400, 0, "Arial", $TreeBuilder)
	$LbasePath = GUICtrlCreateLabel("Base Path:", 8, 11, 69, 18)
	$basePathText = GUICtrlCreateInput("", 8, 32, 441, 24)
	$browseBtn = GUICtrlCreateButton("Browse...", 456, 31, 75, 25)
	$Lstructure = GUICtrlCreateLabel("Structure:", 8, 67, 67, 18)
	$Ltemplate = GUICtrlCreateLabel("From Template:", 290, 67, 86, 18)

	;---------- Combobox initiation -------------------
	$fromTemplate = _GUICtrlComboBoxEx_Create($TreeBuilder, "", 384, 64, 145, 200, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	RefreshComboBox($fromTemplate) ;Generates templates listing

	;Create an item in the treeview that will represent the basepath
	$structureTree = GUICtrlCreateTreeView(8, 94, 521, 393, BitOR($GUI_SS_DEFAULT_TREEVIEW, $WS_VSCROLL, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	ResetTree()
	$createBtn = GUICtrlCreateButton("Create", 456, 494, 75, 25)

	;---------- Set Hotkeys for New File, folder and Saving -------------------
	Local $AccelKeys[4][2] = [["^n", $MITEM_NewFile],["^+n", $MITEM_NewFolder],["^s", $MITEM_SaveTemplate],["!x", $MITEM_Exit]]
	GUISetAccelerators($AccelKeys, $TreeBuilder)
	GUISetState(@SW_SHOW)
	GUIRegisterMsg($WM_COMMAND, "_CHECK_COMBOBOX")
	AdlibRegister("CheckWinActivate", 100)
	While 1
		Switch GUIGetMsg()
			Case $browseBtn
				GUISetState(@SW_DISABLE, $TreeBuilder)
				GUICtrlSetData($basePathText, FileSelectFolder("Please select the location of the Base Path", "", 1, @DesktopDir))
				GUISetState(@SW_ENABLE, $TreeBuilder)
				WinActivate($TreeBuilder)
			Case $MITEM_NewFolder
				NewFolder()
			Case $MITEM_NewFile
				NewFile()
			Case $MITEM_SaveTemplate
				SaveAsTemplate()
			Case $MITEM_ContentManager
				GUISetState(@SW_DISABLE, $TreeBuilder)
				ContentManager()
				GuiSetState(@SW_ENABLE, $TreeBuilder)
				WinActivate($TreeBuilder)
			Case $createBtn
				BuildTree()
			Case $GUI_EVENT_CLOSE
				GUISetState(@SW_HIDE, $TreeBuilder)
			Case $MITEM_Exit
				Exit
		EndSwitch

		Switch TrayGetMsg()
			Case $TRAY_EVENT_PRIMARYDOUBLE
				GUISetState(@SW_SHOW, $TreeBuilder)
			Case $TMITEM_Open
				GUISetState(@SW_SHOW, $TreeBuilder)
				TrayItemSetState($TMITEM_Open, $TRAY_UNCHECKED)
			Case $TMITEM_Exit
				Exit
		EndSwitch
	WEnd
EndFunc   ;==>_Main

;-----------------------------------------------------
; COMBOBOX METHODS:
;-----------------------------------------------------
;_WM_COMMAND----------------------------------
;---------------------------------------------
; Listens for combobox "onchange" event
;---------------------------------------------
Func _CHECK_COMBOBOX($hWnd, $msg, $wParam, $lParam)
	Local $nm, $selection, $selectionText
	If $lParam = $fromTemplate Then
		;http://msdn.microsoft.com/en-us/library/bb775821(v=VS.85).aspx
		$nm = HIWORD($wParam)
		Switch $nm
			Case $CBN_SELCHANGE
				$selection = _GUICtrlComboBoxEx_GetCurSel($fromTemplate)
				If $selection <> 0 Then
					_GUICtrlComboBoxEx_GetItemText($fromTemplate, _GUICtrlComboBoxEx_GetCurSel($fromTemplate), $selectionText)
					LoadTree($selectionText)
				EndIf
		EndSwitch
	EndIf
EndFunc   ;==>_WM_COMMAND

;RefreshComboBox------------------------------
;---------------------------------------------
; Refreshes the combobox list with templates
; in the templates folder
;---------------------------------------------
Func RefreshComboBox($combo)
	_GUICtrlComboBoxEx_BeginUpdate($combo)
	_GUICtrlComboBoxEx_ResetContent($combo)
	_GUICtrlComboBoxEx_AddString($combo, "Custom")
	_GUICtrlComboBoxEx_SetCurSel($combo, 0)
	Local $filesList = _FileListToArray($TEMPLATESDIR), $x, $currFile
	; errror does not equal "no files found"
	If @error <> 4 Then
		For $x = 1 To $filesList[0] Step 1
			$currFile = $filesList[$x]
			_GUICtrlComboBoxEx_AddString($combo, StringMid($currFile, 1, StringLen($currFile) - 4))
		Next
	EndIf
	_GUICtrlComboBoxEx_EndUpdate($combo)
EndFunc   ;==>RefreshComboBox

;-----------------------------------------------------
; TREE BUILDING Functions
;-----------------------------------------------------

Func BuildTree()
	Local $basePath = StringStripWS(GUICtrlRead($basePathText), 3)
	If $basePath = "" Then
		MsgBox(48, "Error", "Please enter a valid base folder.")
	ElseIf Not DirCreate($basePath) Then
		MsgBox(48, "Error", "An Error has occured while attempting to build the tree." & @CRLF & "Please enter a new base path and try again.")
	Else
		Local $firstChild = _GUICtrlTreeView_GetFirstChild($structureTree, $root)
		BuildBranch($firstChild, GUICtrlRead($basePathText))
	EndIf
EndFunc   ;==>BuildTree

Func BuildBranch($node, $parentPath)
	While $node <> 0
		Local $fName, $fPath, $fileHandle
		$fName = _GUICtrlTreeView_GetText($structureTree, $node)
		$fPath = $parentPath & "\" & $fName
		If IsFolder($structureTree, $node) Then
			DirCreate($fPath)
			BuildBranch(_GUICtrlTreeView_GetFirstChild($structureTree, $node), $fPath)
		Else
			$fileHandle = FileOpen($fPath, 2)
			FileClose($fileHandle)
		EndIf
		$node = _GUICtrlTreeView_GetNextSibling($structureTree, $node)
	WEnd
EndFunc   ;==>BuildBranch

;-----------------------------------------------------
; TREEVIEW NODE CREATION Functions
;-----------------------------------------------------
Func NewFile()
	;---------- GUI Code for File Name Prompt -------------------
	Local $NewFile, $fileNameText, $fileExtText, $okBtn, $cancelBtn, $LnewFileName, $Lext
	GUISetState(@SW_DISABLE, $TreeBuilder)
	$NewFile = GUICreate("New File", 313, 99, -1, -1)
	$fileNameText = GUICtrlCreateInput("", 8, 32, 233, 21, $GUI_SS_DEFAULT_INPUT)
	GUICtrlSetLimit(-1, 40)
	$fileExtText = GUICtrlCreateInput("", 264, 32, 41, 21)
	GUICtrlSetLimit(-1, 10)
	$okBtn = GUICtrlCreateButton("&OK", 150, 64, 75, 25, BitOR($BS_DEFPUSHBUTTON, $BS_NOTIFY))
	$cancelBtn = GUICtrlCreateButton("&Cancel", 231, 64, 75, 25, $BS_NOTIFY)
	$LnewFileName = GUICtrlCreateLabel("Enter the file name and extension:", 8, 12, 164, 17, 0)
	$Lext = GUICtrlCreateLabel(".", 248, 32, 10, 28)
	GUICtrlSetFont(-1, 16, 800, 0, "Arial")
	GUICtrlSetColor(-1, 0x000000)
	GUISetState(@SW_SHOW, $NewFile)

	While 1
		Switch GUIGetMsg()
			Case $okBtn
				Local $fileName = StringStripWS(GUICtrlRead($fileNameText), 3)
				Local $fileExt = StringStripWS(GUICtrlRead($fileExtText), 3)
				;Make sure there is no blank input
				If $fileName = "" Or $fileExt = "" Then
					MsgBox(48, "Error", "Please enter a valid file name.")
				Else
					$fileName = $fileName & "." & $fileExt
					;Check for valid file name
					If Not IsValidFileName($fileName) Then
						MsgBox(48, "Error", "The file name you specified contain invalid characters." & @CRLF & "Please remove the invalid characters and try again.")
					Else
						Local $childFile, $selection = _GUICtrlTreeView_GetSelection($structureTree)
						_GUICtrlTreeView_BeginUpdate($structureTree)
						;If the selection is a file, then add the file under the same parent, if not add the file under the selection
						If Not IsFolder($structureTree, $selection) Then
							$childFile = _GUICtrlTreeView_Add($structureTree, $selection, $fileName)
						Else
							$childFile = _GUICtrlTreeView_AddChild($structureTree, $selection, $fileName)
						EndIf
						_GUICtrlTreeView_SetIcon($structureTree, $childFile, $fileico)
						_GUICtrlTreeView_Expand($structureTree)
						_GUICtrlTreeView_EndUpdate($structureTree)
						ExitLoop
					EndIf
				EndIf
			Case $cancelBtn, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUISetState(@SW_ENABLE, $TreeBuilder)
	GUIDelete($NewFile)
EndFunc   ;==>NewFile

Func NewFolder()
	;---------- GUI Code for Folder Name Prompt -------------------
	Local $NewFolder, $folderNameText, $okBtn, $cancelBtn, $LfolderName
	GUISetState(@SW_DISABLE, $TreeBuilder)
	$NewFolder = GUICreate("New Folder", 259, 105, -1, -1, -1, -1, $TreeBuilder)
	$folderNameText = GUICtrlCreateInput("", 8, 32, 241, 21, $GUI_SS_DEFAULT_INPUT)
	GUICtrlSetLimit(-1, 40)
	$okBtn = GUICtrlCreateButton("&OK", 94, 64, 75, 25, BitOR($BS_NOTIFY, $BS_DEFPUSHBUTTON))
	$cancelBtn = GUICtrlCreateButton("&Cancel", 175, 64, 75, 25, $BS_NOTIFY)
	$LfolderName = GUICtrlCreateLabel("Please provide a folder name:", 8, 12, 144, 17, 0)
	GUISetState(@SW_SHOW, $NewFolder)

	While 1
		Switch GUIGetMsg()
			Case $okBtn
				Local $folderName = StringStripWS(GUICtrlRead($folderNameText), 3)
				;Make sure input is not blank
				If $folderName = "" Then
					MsgBox(48, "Error", "Please enter a valid folder name.")
					;Check for valid folder name
				ElseIf Not IsValidFileName($folderName) Then
					MsgBox(48, "Error", "The folder name you specified contain invalid characters." & @CRLF & "Please remove the invalid characters and try again.")
				Else
					Local $childFolder, $selection = _GUICtrlTreeView_GetSelection($structureTree)
					_GUICtrlTreeView_BeginUpdate($structureTree)
					;If the selection is a file, then add folder in the same level as the selection, else add a subfolder under selection
					If Not IsFolder($structureTree, $selection) Then
						$childFolder = _GUICtrlTreeView_Add($structureTree, $selection, $folderName)
					Else
						$childFolder = _GUICtrlTreeView_AddChild($structureTree, $selection, $folderName)
					EndIf
					_GUICtrlTreeView_SetIcon($structureTree, $childFolder, $folderico)
					_GUICtrlTreeView_SetChecked($structureTree, $childFolder)
					_GUICtrlTreeView_Expand($structureTree)
					_GUICtrlTreeView_EndUpdate($structureTree)
					ExitLoop
				EndIf
			Case $cancelBtn, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUISetState(@SW_ENABLE, $TreeBuilder)
	GUIDelete($NewFolder)
EndFunc   ;==>NewFolder


;_DeleteNode----------------------------------
;---------------------------------------------
; Removes a file/folder from the structure.
; If deleted was a folder, everything under it
; will also be deleted
;---------------------------------------------

Func DeleteNode()
	If GUICtrlGetFocused($TreeBuilder) = $structureTree Then
		Local $confirmation, $confirmationMsg, $currSelection = _GUICtrlTreeView_GetSelection($structureTree)
		If $currSelection = $root Then
			$confirmationMsg = "Are you sure you want to restart and build from scratch?"
		Else
			$confirmationMsg = "Are you sure you want to delete the file/folder from the structure?"
		EndIf
		$confirmation = MsgBox(36,"Confirm Deletion", $confirmationMsg)
		If $confirmation = 6 Then ; If Yes
			_GUICtrlTreeView_BeginUpdate($structureTree)
			If $currSelection = $root Then
				ResetTree()
			Else
				_GUICtrlTreeView_Delete($structureTree, $currSelection)
			EndIf
			_GUICtrlTreeView_EndUpdate($structureTree)
		EndIf
	EndIf
EndFunc

;-----------------------------------------------------
; TEMPLATE SAVING FUNCTIONS
;-----------------------------------------------------

Func SaveAsTemplate()
	;---------- GUI Code for Folder Name Prompt -------------------
	Local $NewTemplate, $templateNameText, $okBtn, $cancelBtn, $LtemplateName
	GUISetState(@SW_DISABLE, $TreeBuilder)
	$NewTemplate = GUICreate("New Template", 259, 105, -1, -1, -1, -1, $TreeBuilder)
	$templateNameText = GUICtrlCreateInput("", 8, 32, 241, 21, $GUI_SS_DEFAULT_INPUT)
	GUICtrlSetLimit(-1, 40)
	$okBtn = GUICtrlCreateButton("&OK", 94, 64, 75, 25, BitOR($BS_NOTIFY, $BS_DEFPUSHBUTTON))
	$cancelBtn = GUICtrlCreateButton("&Cancel", 175, 64, 75, 25, $BS_NOTIFY)
	$LtemplateName = GUICtrlCreateLabel("Please provide a template name:", 8, 12, 144, 17, 0)
	GUISetState(@SW_SHOW, $NewTemplate)

	While 1
		Switch GUIGetMsg()
			Case $okBtn
				Local $templateName = StringStripWS(GUICtrlRead($templateNameText), 3)
				Local $overwrite
				;Make sure input is not blank
				If $templateName = "" Then
					MsgBox(48, "Error", "Please enter a valid template name.")
					;Make sure provided name is valid
				ElseIf Not IsValidFileName($templateName) Then
					MsgBox(48, "Error", "The template name you specified contain invalid characters." & @CRLF & "Please remove the invalid characters and try again.")
				Else
					;If template with the same name already exists, prompt to overwrite
					If FileExists($TEMPLATESDIR & $templateName & ".xml") Then
						$overwrite = MsgBox(52, "Warning", 'The template named "' & $templateName & '" already exists.' & @CRLF & 'Do you want to overwrite the existing template?')
					EndIf
					If $overwrite <> 7 Then
						SaveTree($TEMPLATESDIR & $templateName & ".xml")
						ExitLoop
					EndIf
				EndIf
			Case $cancelBtn, $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch
	WEnd
	GUISetState(@SW_ENABLE, $TreeBuilder)
	GUIDelete($NewTemplate)
EndFunc   ;==>SaveAsTemplate

;SaveTree----------------------------------
;---------------------------------------------
; Internal function used by SaveAsTemplate
;---------------------------------------------
Func SaveTree($fileName)
	Local $fHandle = FileOpen($fileName, 2)
	If $fHandle = -1 Then
		MsgBox(16, "Error", 'Error saving to file "' & $fileName & '"')
	Else
		FileWrite($fHandle, SaveBranch())
		MsgBox(64, "Success", 'Tree template was successfully saved to "' & $fileName & '"')
	EndIf
	FileClose($fHandle)
EndFunc   ;==>SaveTree

;SaveBranch----------------------------------
;---------------------------------------------
; Internal function used to recursively save
; the branches as XML
;---------------------------------------------

Func SaveBranch($parentNode = $root)
	Local $beginTag, $content = "", $endTag
	Local $childNode = _GUICtrlTreeView_GetFirstChild($structureTree, $parentNode)
	While $childNode <> 0
		If IsFolder($structureTree, $childNode) Then
			$content = $content & SaveBranch($childNode)
		Else
			$content = $content & '<file name="' & _GUICtrlTreeView_GetText($structureTree, $childNode) & '"/>'
		EndIf
		$childNode = _GUICtrlTreeView_GetNextSibling($structureTree, $childNode)
	WEnd
	If $parentNode <> $root Then
		$beginTag = '<folder name="' & _GUICtrlTreeView_GetText($structureTree, $parentNode) & '">'
		$endTag = '</folder>'
	Else
		$beginTag = "<root>"
		$endTag = "</root>"
	EndIf
	Return $beginTag & $content & $endTag
EndFunc   ;==>SaveBranch

;-----------------------------------------------------
; TREE LOADING FUNCTIONS
;-----------------------------------------------------

;LoadTree----------------------------------
;---------------------------------------------
; Called by combobox change. Loads the XML file
; and builds the tree
;---------------------------------------------
Func LoadTree($fileName)
	Local $xmlroot, $domdoc = GetDOMDocument()
	If @error Then Return MsgBox(16, "Error", "Error: MSXML not found. " & @CRLF & "This component is required to use save and load templates.")
	If Not $domdoc.load($TEMPLATESDIR & $fileName & ".xml") Then Return MsgBox(16, "Error", "An error has occured while trying to load the specified template.")
	If $domdoc.parseError.errorCode <> 0 Then Return MsgBox(16, "Error", "There is a syntax error in the template provided: " & $domdoc.parseError.reason )
	_GUICtrlTreeView_DeleteChildren($structureTree, $root)
	$xmlroot = $domdoc.documentElement
	LoadBranch($xmlroot)
	MsgBox(64, "Success", '"' & $fileName & '"was successfully loaded.')
EndFunc   ;==>LoadTree

;LoadBranch----------------------------------
;---------------------------------------------
; Internal function used to recursively load
; branches from the xml
;---------------------------------------------
Func LoadBranch($nodeToBuild, $parentNode = $root)
	Local $x, $childNode, $name, $treeNode
	For $x = 0 To $nodeToBuild.childNodes.length - 1 Step 1
		$childNode = $nodeToBuild.childNodes.item($x)
		$name = $childNode.getAttribute("name")
		$treeNode = _GUICtrlTreeView_AddChild($structureTree, $parentNode, $name)
		If $childNode.nodeName = "file" Then
			_GUICtrlTreeView_SetIcon($structureTree, $treeNode, $fileico)
		Else
			_GUICtrlTreeView_SetIcon($structureTree, $treeNode, $folderico)
			_GUICtrlTreeView_SetChecked($structureTree, $treeNode)
			LoadBranch($childNode, $treeNode)
		EndIf
	Next
	_GUICtrlTreeView_Expand($structureTree)
EndFunc   ;==>LoadBranch

;ResetTree----------------------------------
;---------------------------------------------
; This function is required to get rid of the
; Expand/Collapse icon bug where the icon would
; show even if root contained no children nodes
;---------------------------------------------
Func ResetTree()
	_GUICtrlTreeView_DeleteAll($structureTree)
	$root = _GUICtrlTreeView_Add($structureTree, 0, "Base Path")
	_GUICtrlTreeView_SetIcon($structureTree, $root, $folderico)
	_GUICtrlTreeView_SetChecked($structureTree, $root)
EndFunc


;-----------------------------------------------------
; VIM NAVIGATION Hotkeys
;-----------------------------------------------------
;---------------------------------------------
; Enables VIM style hotkeys when the active
; window is treebuilder
;---------------------------------------------
Func VIMNav()
	If GUICtrlGetFocused($TreeBuilder) = $structureTree Then
		Switch @HotKeyPressed
			Case "i"
				ControlSend($TreeBuilder, "", $structureTree, "{UP}")
			Case "k"
				ControlSend($TreeBuilder, "", $structureTree, "{DOWN}")
			Case "j"
				ControlSend($TreeBuilder, "", $structureTree, "{LEFT}")
			case "l"
				ControlSend($TreeBuilder, "", $structureTree, "{RIGHT}")
		EndSwitch
	EndIf
EndFunc

;Check If Activated window is TreeBuilder-----------------------------
Func CheckWinActivate()
	If WinActive($TreeBuilder) Then
		HotKeySet("i", "VIMNav")
		HotKeySet("k", "VIMNav")
		HotKeySet("j", "VIMNav")
		HotKeySet("l", "VIMNav")
		HotKeySet("{DEL}", "DeleteNode")
	Else
		HotKeySet("i")
		HotKeySet("k")
		HotKeySet("j")
		HotKeySet("l")
		HotKeySet("{DEL}")
	EndIf
EndFunc