;Common procedures
;{

Procedure mkDir(path.s)
temp.s = ""
last.i = CountString(path, "\")

For Counter = 1 To last+1
  temp = temp + StringField(path,counter,"\") + "\"
  If FileSize(temp) = -1
    If Not(CreateDirectory(temp))
      ProcedureReturn #False
    EndIf
  EndIf
Next
ProcedureReturn #True
EndProcedure

Procedure.i checkForCustomNumber(fullname.s)
  output.i = 0
  While FileSize(fullname + Str(output)) <> -1
    output = output + 1
  Wend
  
  ProcedureReturn output
EndProcedure

Procedure.i beginsWith(source.s, sub.s)
  If (Left(source,Len(sub)) = sub)
    ProcedureReturn 1
  Else
    ProcedureReturn 0
  EndIf
EndProcedure

;возвращает первую несуществующую папку в пути (нужно для activateMod(), смотри конец процедуры)
Procedure.s retFirstDir(path.s)
temp.s = ""
last.i = CountString(path, "\")

For Counter = 1 To last+1
  temp = temp + StringField(path,counter,"\") + "\"
  If FileSize(temp) > -2
    ProcedureReturn temp
  EndIf
Next
EndProcedure

Procedure.s getFileContent (path.s)
  file = ReadFile(#PB_Any, path) 
  output.s = ""
  If file <> 0
    While Eof(file) = 0
      output = output + ReadString(file) + Chr(13)  
    Wend
    CloseFile(file)  
    ProcedureReturn Trim(output, Chr(13))
  Else
    ProcedureReturn ""
  EndIf
EndProcedure

Procedure setFileContent (path.s, content.s)
  file = CreateFile(#PB_Any, path)
  If file <> 0
    WriteString(file, content)
    CloseFile(file)
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf

EndProcedure

Procedure.i findLastMatch(Source.s, StringToFind.s)
  srcLen.i = Len(Source)
  stfLen.i = Len(StringToFind)
  
  For counter = srcLen To 1 Step -1
    If (Mid(Source, counter, stfLen) = StringToFind) 
      ProcedureReturn counter
    EndIf
  Next
  
  ProcedureReturn 0
EndProcedure

Procedure.i directoryIsEmpty(fullname.s)
  If ExamineDirectory(0, fullname, "*.*")  
    count.i = 0
    While NextDirectoryEntry(0)
      count = count + 1
    Wend
    
    FinishDirectory(0)
    
    If count = 2
      ProcedureReturn 1
    Else
      ProcedureReturn 0
    EndIf
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

Procedure.i clearDirectory(path.s)
  If Right(path,1) <> "\" 
    path = path + "\"
  EndIf
    
  If ExamineDirectory(0, path, "*.*")  
    count.i = 0
    ;пропускаем первые два элемента ("." и "..")
    NextDirectoryEntry(0)
    NextDirectoryEntry(0)
    While NextDirectoryEntry(0)
      fullpath.s = path + DirectoryEntryName(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory 
        DeleteDirectory(fullpath, "")
      Else
        DeleteFile(fullpath)
      EndIf  
    Wend
    
    FinishDirectory(0)
    
    ProcedureReturn 1
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

Procedure checkConnection(host.s, port.i)
  connection = OpenNetworkConnection(host, port) 
  If connection
    CloseNetworkConnection(connection)
    ProcedureReturn #True
  Else
    ProcedureReturn #False
  EndIf
EndProcedure


Procedure findMod(name.s)
  name = LCase(name)
  ForEach mods()
    If LCase(mods()\Name) = name
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.s readHTTPFile(file.s) ;необходимо быть в папке с файлом
  output.s = ""
  pathToDownload.s = GetTemporaryDirectory() + "ArcanumLauncher\" + Str(Random(10000000)) + ".txt"
  
  If FileSize(GetTemporaryDirectory() + "ArcanumLauncher\") <> -2
    CreateDirectory(GetTemporaryDirectory() + "ArcanumLauncher\")
  EndIf
  
  If ReceiveHTTPFile(file, pathToDownload)
    If ReadFile(1, pathToDownload)
      While Eof(1) = 0 
        output = output + ReadString(1) + Chr(13)
      Wend        
    Else
      ProcedureReturn ""
    EndIf
    output = Left(output,Len(output)-1)
    CloseFile(1)
    DeleteFile(pathToDownload)
    ProcedureReturn output
  Else
    ProcedureReturn ""
  EndIf
EndProcedure
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 26
; Folding = BA-
; EnableXP
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\launcher.exe