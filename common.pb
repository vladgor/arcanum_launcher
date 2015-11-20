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

Procedure runOnlyOneInstance()
  *a = CreateSemaphore_(NULL, 0, 1, GetProgramName()) 
  If *a <> 0 And GetLastError_()= #ERROR_ALREADY_EXISTS
    MessageRequester("Error", localMsgCantRunSeveralCopies, #MB_ICONERROR)
    CloseHandle_(*a) 
    End
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

Procedure.s readFromHTTPFile(file.s) ;необходимо быть в папке с файлом
  output.s = ""
  pathToDownload.s = GetTemporaryDirectory() + "ArcanumLauncher\" + Str(Random(10000000)) + ".txt"
  
  If FileSize(GetTemporaryDirectory() + "ArcanumLauncher\") <> -2
    CreateDirectory(GetTemporaryDirectory() + "ArcanumLauncher\")
  EndIf
  
  If ReceiveHTTPFile(file, pathToDownload)
    If ReadFile(1, pathToDownload)
      While Eof(1) = 0 
        output = output + ReadString(1, #PB_UTF8) + Chr(10) + Chr(13)
      Wend        
    Else
      ProcedureReturn ""
    EndIf
    output = Left(output, Len(output) - 1)
    CloseFile(1)
    DeleteFile(pathToDownload)
    ProcedureReturn output
  Else
    ProcedureReturn ""
  EndIf
EndProcedure

Procedure.s UnicodeToAscii(src.s)
  output.s
  slen = Len(src)
  For i = 0 To slen
    output = output + Chr(Asc(Mid(src, i, 1)))
  Next i
  
  ProcedureReturn output
EndProcedure
  

Procedure.i ExtractFilesFromZip(src.s, path.s)
  pathLen = Len(path)
  If Left(path, 1) = "\"
    path = Right(path, pathLen - 1)
  EndIf
            
  If Right(path, 1) <>  "\"
    path = path + "\"
  EndIf
  
  If FileSize(path) <> -2
    mkDir(path)
  EndIf       

  If OpenPack(0, src, #PB_PackerPlugin_Zip) 
    If ExaminePack(0)
      While NextPackEntry(0)
        If PackEntryType(0) = #PB_Packer_Directory
          If FileSize(path + PackEntryName(0)) <> -2
            mkDir(path + PackEntryName(0))
          EndIf
        Else
          Debug UnicodeToAscii(PackEntryName(0))
          UncompressPackFile(0, path + PackEntryName(0))
        EndIf
      Wend
    Else
      ProcedureReturn #Null
    EndIf
    ClosePack(0)
  Else
    ProcedureReturn #Null
  EndIf
  
  ProcedureReturn 1
EndProcedure

Procedure.i AddFilesToZip(pack.i, path.s, pattern.s)
  If Right(path, 1) <> "\"
    path = path + "\"
  EndIf
  
  index.i = ExamineDirectory(#PB_Any, path, pattern)
  If index
    While NextDirectoryEntry(index)
      filename.s = DirectoryEntryName(index)
      If DirectoryEntryName(index) = "." Or DirectoryEntryName(index) = ".."
        Continue
      EndIf
      
      If DirectoryEntryType(index) = #PB_DirectoryEntry_File
        AddPackFile(pack, path + filename, path + filename)
      Else
        AddFilesToZip(pack, path + filename, "*.*")
      EndIf
    Wend
    FinishDirectory(index)
  Else
    ProcedureReturn #Null
  EndIf
  
  ProcedureReturn 1
EndProcedure
;}
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 219
; FirstLine = 58
; Folding = Dgs
; EnableXP
; Executable = C:\Users\Р С’Р Т‘Р СР С‘Р Р…Р С‘РЎРѓРЎвЂљРЎР‚Р В°РЎвЂљР С•РЎР‚\Desktop\111\launcher.exe