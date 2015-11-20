;for debuging
If cfgStoreLogs
  ; it is supposed that existing of "launcher" directory is guaranteed
  If FileSize("launcher\logs") <> -2
    CreateDirectory("launcher\logs")
  EndIf
  
  RenameFile("launcher\debug.txt", "launcher\logs\" + FormatDate("(%dd.%mm, %hh-%ii-%ss)", Date()) + " debug.txt")
EndIf

CreateFile(0, "launcher\debug.txt")
FileBuffersSize(0, 204800)
WriteStringN(0, "last launch — " + FormatDate("%dd\%mm\%yyyy" + ", " + "%hh:%ii:%ss", Date()))
WriteStringN(0, "launcher version: " + lVersion)
WriteStringN(0, "-------------------------------")
WriteStringN(0, "")



Procedure d(a.s)
  WriteStringN(0,a)
EndProcedure

Procedure dIndent(count)
  For i = 1 To count
    WriteStringN(0, "")
  Next
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 7
; Folding = -
; EnableXP