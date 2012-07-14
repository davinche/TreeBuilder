#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GuiComboBox.au3>
#include <GUIConstantsEx.au3>
#include <GuiImageList.au3>
#include <GUIListBox.au3>
#include <GuiToolbar.au3>
#include <StaticConstants.au3>
#include <StructureConstants.au3>
#include <ToolbarConstants.au3>
#include <WindowsConstants.au3>
#include "include\Functions.au3"

Dim $TreeBuilder, $TMITEM_Exit
Dim $toolBar, $addContentBtn, $deleteContentBtn, $contentTypeList, $nameText, $keywordText, $type, $editText, $saveBtn
Dim Enum $idNew = 1000, $idDelete

Func ContentManager()
	;---------- Content Manager GUI Code -------------------
	Local $group, $Lname, $Lkeyword, $Ltype, $Ltext
	Local $guiWidth = 862, $guiHeight = 620
	Local $toolbarImageList
	Local $addico = "res\add.ico", $deleteico = "res\delete.ico"

	$ContentManager = GUICreate("TreeBuilder - Content Manager", $guiWidth, $guiHeight, (@DesktopWidth - $guiWidth)/2, (@DesktopHeight-$guiHeight)/2,  $WS_SIZEBOX, 0, $TreeBuilder)
	GUISetFont(10, 400, 0, "Arial", $ContentManager)

	;---------- Toolbar / Toolbar buttons -------------------
	$toolBar = _GUICtrlToolbar_Create($ContentManager, BitOR($BTNS_AUTOSIZE, $BTNS_BUTTON, $TBSTYLE_LIST, $TBSTYLE_FLAT))
	$toolbarImageList = _GUIImageList_Create(16, 16, 5)
	_GUIImageList_Add($toolbarImageList, CreateBitmapFromIcon($addico, 0, 16, 16))
	_GUIImageList_Add($toolbarImageList, CreateBitmapFromIcon($deleteico, 0, 16, 16))
	_GUICtrlToolbar_SetImageList($toolBar, $toolbarImageList)
	_GUICtrlToolbar_AddString($toolBar, "New Content")
	_GUICtrlToolbar_AddString($toolBar, "Delete Selected Content")
	$addContentBtn = _GUICtrlToolbar_AddButton($toolBar, $idNew, 0, 0, $BTNS_AUTOSIZE)
	$deleteContentBtn = _GUICtrlToolbar_AddButton($toolBar, $idDelete, 1, 1, $BTNS_AUTOSIZE)

	;---------- List of Content Types -------------------
	$contentTypeList = GUICtrlCreateList("", 8, 30, 273, 518, BitOR($LBS_SORT,$LBS_STANDARD,$WS_GROUP,$WS_VSCROLL,$WS_BORDER))
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")

	;---------- New Content Type Controls -------------------
	$group = GUICtrlCreateGroup("", 288, 30, 561, 521)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	$Lname = GUICtrlCreateLabel("Name:", 304, 62, 45, 20, $WS_GROUP)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	$nameText = GUICtrlCreateInput("No Selection", 304, 86, 529, 24, BitOR($ES_AUTOHSCROLL,$WS_GROUP))
	GUICtrlSetState(-1, $GUI_DISABLE)
	$Lkeyword = GUICtrlCreateLabel("Keyword:", 304, 118, 64, 20, $WS_GROUP)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	$keywordText = GUICtrlCreateInput("No Selection", 304, 142, 385, 24, BitOR($ES_AUTOHSCROLL,$WS_GROUP))
	GUICtrlSetState(-1, $GUI_DISABLE)
	$type = GUICtrlCreateCombo("Content", 696, 142, 137, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL,$WS_GROUP))
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetData($type, "File Download")
	$Ltype = GUICtrlCreateLabel("Type:", 696, 118, 39, 20, $WS_GROUP)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	$Ltext = GUICtrlCreateLabel("Text:", 304, 182, 36, 20, $WS_GROUP)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	$editText = GUICtrlCreateEdit("", 304, 206, 529, 329, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_GROUP,$WS_VSCROLL))
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$saveBtn = GUICtrlCreateButton("Save Changes", 744, 558, 107, 25, BitOR($BS_DEFPUSHBUTTON,$WS_GROUP))
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetFont(-1, 10, 800, 0, "Arial")
	GUISetState(@SW_SHOW)
	GUIRegisterMsg($WM_NOTIFY, "_WM_NOTIFY")
	GUIRegisterMsg($WM_COMMAND, "_CHECK_EDITCHANGE");

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
		EndSwitch

		Switch TrayGetMsg()
			Case $TMITEM_Exit
				Exit
		EndSwitch
	WEnd
		GUIDelete($ContentManager)
EndFunc

;-----------------------------------------------------
; Handle WM_NOTIFY Messages (Toolbar Button Clicks)
;-----------------------------------------------------
Func _WM_NOTIFY($hWndGUI, $MsgID, $wParam, $lParam)
	#forceref $hWndGUI, $MsgID, $wParam
	Local $nmtoolbar = DLLStructCreate($tagNMTOOLBAR, $lParam)
	Local $hWndFrom = DllStructGetData($nmtoolbar, "hWndFrom"), $idFrom = DllStructGetData($nmtoolbar, "idFrom"), $code = DllStructGetData($nmtoolbar, "code"), $iItem =DllStructGetData($nmtoolbar, "iItem")
	Switch $hWndFrom
		Case $toolBar
			If $code = $NM_CLICK Then
				Switch $iItem
					Case $idNew
						AddContentType()
					Case $idDelete
						Local $currSel = _GUICtrlListBox_GetCurSel($contentTypeList)
						If $currSel <> -1 Then
							_GUICtrlListBox_DeleteString($contentTypeList, $currSel)
							ResetInputs()
						EndIf
				EndSwitch
			EndIf
	EndSwitch
EndFunc   ;==>_WM_NOTIFY

Func _CHECK_EDITCHANGE($hWnd, $msg, $wParam, $lParam)
	;---------- Changes in the Name text field are reflected in the ListBox -------------------
	Local $hWndFrom = LOWORD($wParam), $nmCode = HIWORD($wParam), $currSel
	If $hWndFrom = $nameText And $nmCode = $EN_UPDATE Then
		$currSel = _GUICtrlListBox_GetCurSel($contentTypeList)
		If $currSel <> -1 Then
			_GUICtrlListBox_ReplaceString($contentTypeList, $currSel, GUICtrlRead($nameText))
			_GUICtrlListBox_SetCurSel($contentTypeList, $currSel)
		EndIf
	EndIf
EndFunc

Func ResetInputs()
	GUICtrlSetData($nameText, "No Selection")
	GUICtrlSetData($keywordText, "No Selection")
	_GUICtrlComboBox_SetCurSel($type, 0)
	GUICtrlSetData($editText, "")
	GUICtrlSetState($nameText, $GUI_DISABLE)
	GUICtrlSetState($keywordText, $GUI_DISABLE)
	GUICtrlSetState($type, $GUI_DISABLE)
	GUICtrlSetState($editText, $GUI_DISABLE)
	GUICtrlSetState($saveBtn, $GUI_DISABLE)
EndFunc

Func AddContentType()
	Local $newDefaultText = "New Content Type"
	Local $newListItem
	$newListItem = _GUICtrlListBox_InsertString($contentTypeList, $newDefaultText)
	_GUICtrlListBox_SetCurSel($contentTypeList, $newListItem)

	GUICtrlSetData($nameText, $newDefaultText)
	GUICtrlSetData($editText, "")
	GUICtrlSetState($nameText, $GUI_ENABLE)
	GUICtrlSetState($keywordText, $GUI_ENABLE)
	GUICtrlSetState($type, $GUI_ENABLE)
	GUICtrlSetState($editText, $GUI_ENABLE)
	GUICtrlSetState($saveBtn, $GUI_ENABLE)
	ControlFocus("", "", $nameText)
EndFunc