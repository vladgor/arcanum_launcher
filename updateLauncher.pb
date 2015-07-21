

;returns new version of launcher, if current version is not actual anymore
;else procedure return 0
Procedure.s checkLauncherForUpdate()
  newVersion.s = readHTTPFile("http://www.x1a7.ru/arcanumLauncher/version.txt")
  If newVersion <> lVersion
    ProcedureReturn newVersion
  Else
    ProcedureReturn "0"
  EndIf
EndProcedure


;returns #false if updating has failed
Procedure.i updateLauncher()
  If ReceiveHTTPFile("http://www.x1a7.ru/arcanumLauncher/bin/launcher.exe", "newLauncher.exe")
    file.i = CreateFile(#PB_Any, "update.bat")
    
    If file <> 0 
      WriteStringN(file, "@echo waiting for launcher to close...")
      WriteStringN(file, "@ping 192.0.2.2 -n 1 -w 5000 > nul")
      WriteStringN(file, "@echo deleting old version...")
      WriteStringN(file, "@del " + GetFilePart(ProgramFilename())) 
      WriteStringN(file, "@echo renaming downloaded version...")
      WriteStringN(file, "@ren newLauncher.exe " + GetFilePart(ProgramFilename()))
      WriteStringN(file, "@echo update was successfully done!")
      WriteStringN(file, "@echo new version of launcher is being started...")
      WriteStringN(file, "@ping 192.0.2.2 -n 1 -w 3000 > nul")
      WriteStringN(file, "@start /d " + Chr(34) + "/" + Chr(34) + " " + GetFilePart(ProgramFilename()))
      
      CloseFile(file)
      RunProgram("update.bat")
      
      ProcedureReturn #True
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 25
; FirstLine = 6
; Folding = -
; EnableXP
; EnablePurifier