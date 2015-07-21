Procedure openWndShortcut(properties.b) ; properies.b = #True or #False
  title.s = localWndShortcutTitle
  
  If properties
    title = localWndPropertiesTitle    
  EndIf
  
  modName.s = GetGadgetText(#lstMods)
  findMod(modName)
  
  If OpenWindow(#wndShortcut, 524, 380, 445, 231, modName + " — " + title + ", ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_TitleBar | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered, WindowID(#wnd))
    color = RGB(150,0,0)
    
    If properties
      ButtonGadget(#btnSaveModProperties, 325, 200, 110, 25, localBtnSaveModProperties)
    Else
      ButtonGadget(#btnShortcutCreate, 325, 200, 110, 25, localBtnCreateShortcut)
    EndIf
    
    StringGadget(#txtShortcut, 10, 25, 425, 20, "")
    TextGadget(#lblShortcut, 10, 10, 425, 15, localLblShortcutLine)
    TextGadget(#lblShortcutList, 10, 55, 295, 15, localLblShortcutList)
    HyperLinkGadget(#lblShortcutFullScreen, 20, 75, 145, 15, "-fullscreen", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutFullScreen, localTtFullScreen)
    HyperLinkGadget(#lblShortcutFPS, 20, 95, 145, 15, "-fps", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutFPS, localTtFPS)
    HyperLinkGadget(#lblShortcutNoSound, 20, 115, 145, 15, "-nosound", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutNoSound, localTtNoSound)
    HyperLinkGadget(#lblShortcutNoRandom, 20, 135, 145, 15, "-norandom", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutNoRandom, localTtNoRandomEnc)
    HyperLinkGadget(#lblShortcutScrollFps, 20, 155, 145, 15, "-scrollfps:[number]", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutScrollFps, localTtScrollFps)
    HyperLinkGadget(#lblShortcutScrollDist, 20, 175, 145, 15, "-scrolldist:[number]", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutScrollDist, localTtScrolDist)
    HyperLinkGadget(#lblShortcutMod, 175, 175, 145, 15, "-mod:[name of a module]", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutMod, localTtMod)
    HyperLinkGadget(#lblShortcutNo3D, 175, 75, 145, 15, "-no3d", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutNo3D, localTtNo3d)
    HyperLinkGadget(#lblShortcutVidFreed, 175, 95, 145, 15, "-vidfreed:[number]", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutVidFreed, localTtVidFreed)
    HyperLinkGadget(#lblShortcutDoubleBuffer, 175, 115, 145, 15, "-doublebuffer", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutDoubleBuffer, localTtDoubleBuffer)
    HyperLinkGadget(#lblShortcutMpAutoJoin, 175, 135, 145, 15, "-mpautojoin", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutMpAutoJoin, localTtMpAutoJoin)
    HyperLinkGadget(#lblShortcutMpNoBcast, 175, 155, 130, 15, "-mpnobcast", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutMpNoBcast, localTtMpNoBcast)
    HyperLinkGadget(#lblShortcutDialogNumber, 325, 135, 135, 15, "-dialognumber", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutDialogNumber, localTtDialogNumber)
    HyperLinkGadget(#lblShortcutDialogCheck, 325, 115, 130, 15, "-dialogcheck", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutDialogCheck, localTtDialogCheck)
    HyperLinkGadget(#lblShortcutGenderCheck, 325, 75, 130, 15, "-gendercheck", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutGenderCheck, localTtGenderCheck)
    HyperLinkGadget(#lblShortcutLogCheck, 325, 95, 130, 15, "-logcheck", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutLogCheck, localTtLogCheck)
    HyperLinkGadget(#lblShortcutWindowed, 325, 155, 130, 15, "-lwindowed", color, #PB_HyperLink_Underline)
    GadgetToolTip(#lblShortcutWindowed, localTtLwindowed)
    
    DisableGadget(#lblShortcutWindowed, 1)
    If FileSize("launcher\fixes\windowed\ddraw.dll") >= 0 
      If FileSize("launcher\fixes\windowed\arcanum-w.exe") >= 0
        If FileSize("launcher\fixes\windowed\aqrit.cfg") >= 0
          DisableGadget(#lblShortcutWindowed, 0)
        EndIf
      EndIf
    EndIf
    
    If properties
      SetGadgetText(#txtShortcut, mods()\commands + " ")
      SimulateKeyPress(#VK_END, 0, #False, #False, #False) 
    EndIf
    
    SetActiveGadget(#txtShortcut)
  EndIf
EndProcedure

Procedure createModShortcut(mod.s, arg.s)
  p.s = ProgramFilename()
  createShellLink(p, SaveFileRequester(localMsgSaveShortcut, "Arcanum (" + mod + ").lnk", "*.lnk", 0), Chr(34) + mod + Chr(34) + " " + Chr(34) + arg + Chr(34),"",GetPathPart(p), p, 0)
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 61
; FirstLine = 39
; Folding = -
; EnableXP
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\temporary\launcher.exe