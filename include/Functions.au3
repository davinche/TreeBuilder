#include-once
#include <GUITreeView.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>

;---------- TreeView Helper Functions -------------------
Func IsValidFileName($str)
	Return StringRegExp($str, '^[^<>\:/\\\|\?\*"]+$')
EndFunc   ;==>IsValidFileName

Func IsFolder($hTree, $node)
	Return _GUICtrlTreeView_GetChecked($hTree, $node)
EndFunc   ;==>IsFolder

Func GetDOMDocument()
	Local $domdoc, $x
	For $x = 6 To 3 Step -1
		$domdoc = ObjCreate("Msxml2.DOMDocument." & $x & ".0")
		If IsObj($domdoc) Then
			Return $domdoc
		EndIf
	Next
	$domdoc = ObjCreate("Msxml2.DOMDocument")
	If Not IsObj($domdoc) Then Return SetError(1)
	Return $domdoc
EndFunc   ;==>GetDOMDocument

Func GUICtrlGetFocused($hWnd)
	Local $h = ControlGetHandle($hWnd, "", ControlGetFocus($hWnd))
	Local $return = DllCall("user32", "int", "GetDlgCtrlID", "hWnd", $h)
	Return $return[0]
EndFunc   ;==>GUICtrlGetFocused

;---------- Other Helper Functions -------------------
Func LOWORD($param)
	Return BitAND($param, 0xFFFF)
EndFunc

Func HIWORD($param)
	Return BitShift($param, 16)
EndFunc

Func CreateBitmapFromIcon($path, $index, $width, $height)
	Local $hDC = _WinAPI_GetDC(0)
	Local $mDC = _WinAPI_CreateCompatibleDC($hDC)
	Local $hBitmap = _WinAPI_CreateSolidBitmap(0, _WinAPI_GetSysColor($COLOR_MENU), $width, $height)
	Local $hbmOLD = _WinAPI_SelectObject($mDC, $hBitmap)
	Local $hIcon = _ShellExtractIcon($path, $index, $width, $height)
	If Not @error Then
		_WinAPI_DrawIconEx($mDC, 0, 0, $hIcon, 0, 0, 0, 0, 3)
	EndIf
	_WinAPI_DestroyIcon($hIcon)
	_WinAPI_SelectObject($mDC, $hbmOLD)
	_WinAPI_DeleteDC($mDC)
	_WinAPI_ReleaseDC(0, $hDC)
	Return $hBitmap
EndFunc   ;==>CreateBitmapFromIcon

Func _ShellExtractIcon($path, $index, $width, $height)
	Local $Ret = DllCall('shell32.dll', 'int', 'SHExtractIconsW', 'wstr', $path, 'int', $index, 'int', $width, 'int', $height, 'ptr*', 0, 'ptr*', 0, 'int', 1, 'int', 0)
	If (@error) Or (Not $Ret[0]) Or (Not $Ret[5]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[5]
EndFunc   ;==>_ShellExtractIcon

