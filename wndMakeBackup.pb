Procedure openWndMakeBackup(mod.s)
  findMod(mod)
  mod = mods()\realName
  
  If OpenWindow(#wndMakeBackup, 379, 180, 335, 345, mod + " — " + localWndBackupTitle + ", ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered )
    StringGadget(#txtMakeBackupName, 10, 26, 315, 20, "")
    TextGadget(#lblMakeBackupName, 10, 10, 40, 15, localLblBackupName)
    
    SetGadgetText(#txtMakeBackupName, "(" + FormatDate("%dd.%mm", Date()) + ") ")
    
    TextGadget(#lblMakeBackupDescription, 10, 57, 99, 15, localLblBackupDescription)
    EditorGadget(#txtMakeBackupDescription, 10, 72, 315, 234)
    SetGadgetText(#txtMakeBackupDescription, FormatDate("%dd/%mm/%yyyy, %hh:%ii", Date()) + Chr(13) + LSet("",10, "-") + Chr(13))
    
    TextGadget(#lblMakeBackupStatus, 10, 316, 205, 16, "", #PB_Text_Right)
    ButtonGadget(#btnMakeBackup, 225, 312, 100, 24, localBtnBackup)
    
    SetActiveGadget(#txtMakeBackupName)
    SimulateKeyPress(#VK_END, 0, #False, #False, #False) 
  EndIf
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 18
; Folding = -
; EnableXP