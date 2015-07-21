Structure backup
  name.s
  description.s
EndStructure

Global NewList Backups.backup()

Procedure fillUnbackupModsList(mod.s)
  result = ExamineDirectory(#PB_Any, "mods\!backups\" + mod, "*.zip")
  
  If result
    While NextDirectoryEntry(result)
      AddElement(Backups())
      name.s = DirectoryEntryName(result)
      name = Left(name, findLastMatch(name, ".") - 1)
      Backups()\name = name
      Backups()\description = GetFileContent("mods\!backups\" + mod + "\" + name + ".txt")
      
      AddGadgetItem(#lstUnbackupMod, -1, name)
    Wend
  Else
    ProcedureReturn #False
  EndIf
  
EndProcedure

Procedure openWndUnbackupMod(mod.s)
  
  findMod(mod)
  mod = mods()\realName
  
  If OpenWindow(#wndUnbackupMod, 0, 0, 560, 330,  mod + " — " + localWndUnbackupTitle + ", Arcanum Launcher " + lVersion, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_Invisible | #PB_Window_ScreenCentered, WindowID(wnd))
    TextGadget(#lblUnbackupMod, 190, 10, 360, 270, "", #PB_Text_Border)
    
    ButtonGadget(#btnUnbackupMod, 420, 290, 130, 24, localBtnUnbackup)
    TextGadget(#lblUnbackupModStatus, 190, 294, 220, 16, "", #PB_Text_Right)
    
    ListViewGadget(#lstUnbackupMod, 10, 10, 170, 310)
    fillUnbackupModsList(mod)
    
    
    If ListSize(Backups()) = 0
      MessageRequester("", localMsgYouHaveNoBackup, #MB_ICONINFORMATION)
      CloseWindow(#wndUnbackupMod)
      DisableWindow(#wnd, 0)
      SetActiveGadget(#lstMods)
      ProcedureReturn #False
    EndIf
    
    HideWindow(#wndUnbackupMod, 0)
  EndIf
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 35
; FirstLine = 9
; Folding = -
; EnableXP