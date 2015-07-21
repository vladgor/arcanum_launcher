Procedure openWndMakeBackup()
  If OpenWindow(#wndMakeBackup, 379, 180, 524, 375, "saf",  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget | #PB_Window_TitleBar )
    ListViewGadget(#lstMakeBackup, 9, 15, 187, 348)
    StringGadget(#txtMakeBackupName, 210, 46, 295, 20, "")
    TextGadget(#lblMakeBackupName, 210, 30, 40, 15, "Name:")
    TextGadget(#lblMakeBackupDescription, 213, 72, 99, 15, "Description:")
    StringGadget(#txtMakeBackupDescription, 210, 87, 297, 234, "")
    Frame3DGadget(#frMakeBackup, 201, 9, 315, 321, "Backup settings")
    ButtonGadget(#btnMakeBackup, 393, 339, 123, 24, "Make backup")
  EndIf
EndProcedure
; IDE Options = PureBasic 4.51 (Windows - x86)
; CursorPosition = 10
; Folding = -
; EnableXP