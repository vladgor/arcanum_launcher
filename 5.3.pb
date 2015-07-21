; arcanum launcher � ������ ������������� �����

;version 5.3

;+ ������������� ��������
;+ ������� ���������� ������ ��� ��������� � ����������� ����
;+ ���������, �� �������� �� ��������� �������� � ����� �����
;+ ���������, ���� �� ���������� � ����������
;
;* arcanumN.dat � arcanum.patchN ������ �� �����������������
;* ����� /maps ������ ���������, � �� �����������
; ������������ ���������


;TODO: ������ �������� � �������
;      �������� ������ ���� (������� ������ ���������)
;      ��������

Global lVersion.s = "0.5.3"

Global lProcessPid = 0 ;����������� �����
Global lProcessName.s = GetFilePart(ProgramFilename())
Global lDirectory.s = GetPathPart(ProgramFilename())

;���� ��� ��� ������� ��� �� ��������� �������, �� ��������� ���
ExamineProcesses()

Repeat
  process = NextProcess()
  If GetProcessName() = lProcessName
    If GetPathPart(GetProcessFileName()) = lDirectory
      If lProcessPid = 0
        lProcessPid = GetProcessPID()
      Else
        If GetProcessPID() <> lProcessPid
          MessageRequester("Error :(", "You can't run several launchers for one Arcanum", #MB_ICONERROR)
          End
        EndIf
      EndIf
    EndIf
  EndIf
Until process = 0

; �������, ����� ��� ���������, ���� ��������� ���� ������� � ����������
argMod.s = ProgramParameter()

;Constants
;{
;- Window Constants
Enumeration
  #wnd
  #wndGetMod
EndEnumeration

;- Gadget Constants
;
Enumeration
  #lstMods
  #btnGo
  #btnGetMod
  
  #menu
  #menuDeleteMod
  #menuCheckVersion
  #menuModDescription
  ;--------get mod-------
  #lstGetModList
  #wbGetMod
  #lblDownloading
  #pbDownloading
  #btnAbortDownloading
EndEnumeration
;}

Structure mod
  name.s
  desc.s ;description
  version.s
  isDownloaded.b ;#true or #false
  List files.s()
EndStructure


Global NewList mods.mod()

;������ �����, ������� ��� ������ ��������.
;������������ � activateMod() � deactivateMod()
;!�����! � � makeModsList() ����� ��� ���� ���� ��������� ������� (���, ��� mkDir)
;!     ! � ���� ����� ����������� ������ ���� � ����� � �����, �� � ���� �������� � makeModsList()
Global NewList DirsToReplace.s() 

;{ to replace

AddElement(DirsToReplace())
DirsToReplace() = "modules\Arcanum\save"

;AddElement(DirsToReplace())
;DirsToReplace() = "modules\Arcanum\maps"

AddElement(DirsToReplace())
DirsToReplace() = "data\proto"
;}

Global NewList DirsToRemove.s()
Global NewList DirsToClear.s()


;{ to clear
AddElement(DirsToClear())
DirsToClear() = "modules\Arcanum\maps"
;}

Global NewList FilesToBackup.s()


;Global NewList arcanumDatNumber.i() ; ����� ����� ��������� ������ ��� arcanumN.dat
;Global NewList arcanumPatchNumber.i() ; � arcanum.patchN

Global activatedMod.s = ""
;wtf? bullshitty code here
Global dMod.s = ""
Global dModTempFile.s = ""
Global dThread = 0

Global ListIsFilled = #False


IncludeFile "download.pb"
IncludeFile "debug.pb"
IncludeFile "common.pb"


; �������, ���� �� ������ ��� ������ ��������� �����
; ���� ���, ������ ��
ForEach DirsToReplace()
  If FileSize(DirsToReplace()) = -1
    If mkDir(DirsToReplace()) = #True
      d("Directory " + Chr(34) + DirsToReplace() + Chr(34) + " was created")
    Else
      d("!ERROR: can't create " + Chr(34) + DirsToReplace() + Chr(34) + " directory")
    EndIf
  EndIf
Next

If FileSize("mods\NoMod") = -1 
  If mkDir("mods\NoMod")
    d("Directory " + Chr(34) + "mods\NoMod" + Chr(34) + " was created")
  Else 
    d("!ERROR: can't create " + Chr(34) + "mods\NoMod" + Chr(34) + " directory")
  EndIf
EndIf

;������ �������, ����� ����� (�����-�����) �������� � �������� ������� �������
;���� ��������, ����������
;(����� ���� ��������� � ���������� ������, �� ����� ����� �������� ������)
ForEach DirsToReplace()
  If directoryIsEmpty(DirsToReplace() + "Backup") = 1 ;���� ���� ������ �����-�����
    If DeleteDirectory(DirsToReplace() + "Backup","",#PB_FileSystem_Recursive | #PB_FileSystem_Force)
      d("Directory " + Chr(34) + DirsToReplace() + "Backup" + Chr(34) + " was deleted")
    Else
      d("!ERROR: can't delete " + Chr(34) + "mods\NoMod" + Chr(34) + " directory")
    EndIf
  ElseIf directoryIsEmpty(DirsToReplace() + "Backup") = 0 ;���� ����, �� �� ������
    newName.s = DirsToReplace() + Str(checkForCustomNumber(DirsToReplace()))
    If RenameFile(DirsToReplace(), newName)
      d("Directory " + Chr(34) + DirsToReplace() + Chr(34) + " was renamed to " + Chr(34) + newName + Chr(34))
    Else
      d("!ERROR: can't rename " + Chr(34) + DirsToReplace() + Chr(34) + " to " + Chr(34) + newName + Chr(34))
    EndIf
    
    If RenameFile(DirsToReplace() + "Backup", DirsToReplace())
      d("Directory " + Chr(34) + DirsToReplace() + "Backup" + Chr(34) + " was renamed to " + Chr(34) + DirsToReplace() + Chr(34))
    Else
      d("!ERROR: can't rename " + Chr(34) + DirsToReplace() + "Backup" + Chr(34) + " to " + Chr(34) + DirsToReplace() + Chr(34))
    EndIf
  EndIf
Next

d("")

InitNetwork()

;��������� ����� � ������
Procedure makeModsList()
  ;�������, ����� ���� ����� � ���������� mods\
  ;�� ���� ����� ���������� ������ �����
  ;(������ ����� - ��������� ���)
  
  Directory$ = "mods\"
  If ExamineDirectory(0, Directory$, "*.*")  
    
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory And DirectoryEntryName(0) <> "." And DirectoryEntryName(0) <> ".."
        
        ;{ ������ ����������� �����
        mkDir("mods\" + DirectoryEntryName(0) + "\modules\Arcanum\Save")
        ;mkDir("mods\" + DirectoryEntryName(0) + "\modules\Arcanum\Maps")
        ;}
          
        AddElement(mods())
        mods()\name = DirectoryEntryName(0)
        mods()\isDownloaded = #True
        
        AddGadgetItem(#lstMods,-1,DirectoryEntryName(0))
      EndIf
    Wend
    FinishDirectory(0)
  EndIf

EndProcedure


Procedure openWnd(hidden.b)
  If OpenWindow(#wnd, 374, 199, 360, 340, "ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_Invisible)
    ListIconGadget(#lstMods, 10, 10, 340, 280,"name", 250, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#lstMods,1, "version", 85)
    
    makeModsList()
    
    ButtonGadget(#btnGo, 250, 300, 100, 25, "������") 
    ButtonGadget(#btnGetMod, 10, 300, 100, 25, "������� ����") 
    
    If (hidden = 0)
      HideWindow(#wnd, 0)
    EndIf
  EndIf
EndProcedure

; ������� ��������� ����� ��� ����� arcanumN.dat
Procedure.i checkForArcanumDatNumber()
  output.i = 1
  While FileSize("arcanum" + Str(output) + ".dat") <> -1
    output = output + 1
  Wend
  
  ProcedureReturn output
EndProcedure

; ������� ��������� ����� ��� ����� arcanum.patchN
Procedure.i checkForArcanumPatchNumber()
  output.i = 1
  While FileSize("modules\arcanum.patch" + Str(output)) <> -1
    output = output + 1
  Wend
  
  ProcedureReturn output
EndProcedure

;���������� ����� ���� � ����� � ���������
Procedure.i activateMod(name.s)
  ; ������� ������ ���
  ForEach mods()
    If mods()\name = name
      Break
    EndIf
  Next
  
  modFolder.s = "mods\" + mods()\name + "\"
  errors.i = 0 ;counts errors
  
  ;��������� ����� � �����
  SearchFilesInit(modFolder,"*.*",1)
  Repeat
    file.s=SearchFilesGet()
    
    If file="" : Break : EndIf
    
    shouldIaddThisFileToListOrNot.b = 1
    
    temp.s = Right(file,Len(file) - Len(RTrim(modFolder,"\")) - 1)
              
    ForEach DirsToReplace()
      If (beginsWith(temp,DirsToReplace())) ;���� ���� ����� � ����� �� ����� dirsToReplace
        shouldIaddThisFileToListOrNot = 0 ;�� ��� �� ���������
      EndIf
    Next
    
    If shouldIaddThisFileToListOrNot = 1
      AddElement(mods()\files())
      mods()\files() = file
    EndIf
  ForEver
  
  d("activate")
  d("---")

  ;���������� �����, ��������� � DirsToReplace()
  ForEach DirsToReplace()
    ;���� � ������������ ��� ���� ������ �����, �� ��������������� �
    If FileSize(DirsToReplace()) = -2 And FileSize(modFolder + DirsToReplace()) = -2      
      If RenameFile(DirsToReplace(), DirsToReplace() + "Backup")
        d("folder backuped: " + DirsToReplace())
      Else
        d("!ERROR: can't make backup " + DirsToReplace())
        errors = errors + 1
      EndIf
    EndIf
    
    ; ���������� �����
    If FileSize(modFolder + DirsToReplace()) = -2
      If RenameFile(modFolder + DirsToReplace(), DirsToReplace())
        d("folder replaced: " + modFolder + DirsToReplace() + " -> " + DirsToReplace())
      Else
        d("!ERROR: can't replace folder " + modFolder + DirsToReplace() + " -> " + DirsToReplace())
        errors = errors + 1
      EndIf 
    EndIf 
  Next
  
  ; ���������� ����� ����, ������� �������������� ��������� �� ���
  ; (arcanumN.dat, modules\arcanum.patchN)
  ForEach mods()\files()
    oldPath.s = mods()\files()
    newPath.s = RemoveString(oldPath, modFolder)
    
    ;���� ���� arcanumN.dat
    ;If (LCase(Left(newPath, 7)) = "arcanum") And (Right(newPath,4) = ".dat")
      ; ��������� ����� ��� ��� �����
    ;  newPath = "arcanum" + Str(checkForArcanumDatNumber()) + ".dat"
    ;  ; ���������� ������
    ;  AddElement(arcanumDatNumber())
    ;  arcanumDatNumber() = checkForArcanumDatNumber()
    ;EndIf
    
    ; ���� ���� modules\arcanum.patchN
    ;If (LCase(Left(newPath, 21)) = "modules\arcanum.patch")
    ;  ; ��������� ����� ��� ��� �����
    ;  newPath = "modules\arcanum.patch" + Str(checkForArcanumPatchNumber()) 
    ;  ; ���������� ������
    ;  AddElement(arcanumPatchNumber())
    ;  arcanumPatchNumber() = checkForArcanumPatchNumber()
    ;EndIf
    
    ;���� ��� ����� �����, ���� ����������, �� ������ � ���������� �
    If (FileSize(GetPathPart(newPath)) > -2 And LTrim(GetPathPart(newPath),"\") + "Backup") And GetPathPart(newPath) <> ""
      AddElement(DirsToRemove())
      DirsToRemove() = retFirstDir(RTrim(GetPathPart(newPath),"\"))
      mkDir(GetPathPart(newPath))
      d("created: " + GetPathPart(newPath))
    EndIf

    If (FileSize(newPath) > -1)
      If RenameFile(newPath, newPath + ".backup") 
         d("backuped: "+ newPath)
         AddElement(FilesToBackup())
         FilesToBackup() = newPath
       Else
         d("!ERROR: can't make backup "+ oldPath + " �> " + newPath)
         errors = errors + 1
      EndIf
    EndIf
    
    If RenameFile(oldPath, newPath)
      d("replaced: "+ oldPath + " �> " + newPath)
    Else
      d("!ERROR: can't rename "+ oldPath + " �> " + newPath)
      errors = errors + 1
    EndIf
  Next
  
  FlushFileBuffers(0)
  ProcedureReturn errors
EndProcedure

;���������� ����� ���� �������
;���������� ���������� ������
Procedure.i deactivateMod(name.s)
  ; ������� ������ ���
  ForEach mods()
    If mods()\name = name
      Break
    EndIf
  Next
  
  dIndent(3)
  d("DEactivate")
  d("---")
  
  modFolder.s = "mods\" + mods()\name + "\"
  errors.i = 0
  
  
  ;number.i = 1 ; ������ ��� arcanumN.dat � modules\arcanum.patchN
  oldPath.s
  newPath.s
  
  ;������ ���������� arcanumN.dat �����
  ;ForEach arcanumDatNumber()
  ;  oldPath = "arcanum" + Str(arcanumDatNumber()) + ".dat"
  ;  newPath = modFolder + "arcanum" + Str(number) + ".dat"
  ;  
  ;  If RenameFile(oldPath, newPath)
  ;    d("replaced: "+ oldPath + " �> " + newPath)
  ;  Else
  ;    d("!ERROR: "+ oldPath + " �> " + newPath)
  ;  EndIf
    
  ;  number = number + 1
  ;Next
  
  ;number = 1
  
  ;����� modules\arcanum.patchN
  ;ForEach arcanumPatchNumber()
  ;  oldPath = "modules\arcanum.patch" + Str(arcanumPatchNumber())
  ;  newPath = modFolder + "modules\arcanum.patch" + Str(number)
  ;  
  ;  If RenameFile(oldPath, newPath)
  ;    d("replaced: "+ oldPath + " �> " + newPath)
  ;  Else
  ;    d("!ERROR: "+ oldPath + " �> " + newPath)
  ;  EndIf
  ;  
  ;  number = number + 1
  ;Next
  
  ;����� ������ �����
  ForEach DirsToReplace()
    If FileSize(DirsToReplace()) = -2 And FileSize(DirsToReplace() + "Backup") = -2
      mkDir(modFolder + Left(DirsToReplace(),findLastMatch(DirsToReplace(),"\")))
      
      If RenameFile(DirsToReplace(), modFolder + DirsToReplace())
        d("folder replaced: "+ DirsToReplace() + " �> " + modFolder + DirsToReplace())
      Else
        d("!ERROR: "+ oldPath + " �> " + newPath)
        errors = errors + 1
      EndIf
      
      If RenameFile(DirsToReplace() + "Backup", DirsToReplace())
        d("folder unbackuped: "+ DirsToReplace() + "Backup")
      Else
        d("!ERROR: can't make unbackup "+ oldPath + "Backup")
        errors = errors + 1
      EndIf
 
    EndIf
  Next
  
  
  ; ���������� ���������� ����
  ForEach mods()\files()
    oldPath = RemoveString(mods()\files(), modFolder)
    newPath = mods()\files()
    
    ; ���� �� arcanumN.dat ��� arcanum.patchN
    ;If Not(((LCase(Left(oldPath, 7)) = "arcanum") And (Right(oldPath,4) = ".dat")) Or (LCase(Left(oldPath, 21)) = "modules\arcanum.patch"))
      If RenameFile(oldPath, newPath)
        d("replaced: "+ oldPath + " �> " + newPath)
      Else
        d("!ERROR: "+ oldPath + " �> " + newPath)
        errors = errors + 1
      EndIf
    ;EndIf
  Next
  
  ; ������� ��������� ����� �����
  ForEach DirsToRemove()
    If DirsToRemove() <> "" And DirsToRemove() <> "\"
      If DeleteDirectory(DirsToRemove(),"",#PB_FileSystem_Recursive | #PB_FileSystem_Force)
        d("folder deleted: " + DirsToRemove())
      EndIf
    EndIf
  Next
  
  ;��������������� ������� �����-�����
  ForEach FilesToBackup()
    If RenameFile(FilesToBackup() + ".backup", FilesToBackup())
      d("unbackuped: " + FilesToBackup() + ".backup")
    Else
      d("!ERROR: can't make unbackup" + FilesToBackup() + ".backup")
      errors = errors + 1
    EndIf
  Next
  
  ForEach DirsToClear()
    If clearDirectory(DirsToClear()) = 1
      d("cleaned: " + DirsToClear())
    Else
      d("!ERROR: cann't clean: " + DirsToClear())
      errors = errors + 1
    EndIf
  Next
  
  ProcedureReturn errors
EndProcedure 

Procedure runArcanum(modToActivate.s)
  
If modToActivate = ""
  modToActivate = "noMod"
EndIf

errors.i = activateMod(modToActivate)
activatedMod = modToActivate

If errors > 0 
  temp.s = " errors have "
  If errors = 1 : temp = " error has " : EndIf
  MessageRequester("Ooops :(", Str(errors) + temp + "occured. See ''launcherDebug.txt'' for details", #MB_ICONERROR)
EndIf

; ��������� �������
;{
  Program = RunProgram("Arcanum.exe","", "", #PB_Program_Open)
  If Program
    HideWindow(#wnd,1)
    While ProgramRunning(Program)
      Delay(1000)
    Wend
    
    CloseProgram(Program)
    
    errors = deactivateMod(activatedMod)
    If errors = 0
      MessageRequester("Weee :)","Closed and restored successfully", #MB_ICONINFORMATION)
    Else
      temp = " errors have "
      If errors = 1 : temp = " error has " : EndIf
      MessageRequester("Ooops :(", Str(errors) + temp + "occured. See ''launcherDebug.txt'' for details", #MB_ICONERROR)
    EndIf
   
    CloseFile(0)
    End  
  Else
    deactivateMod(activatedMod)
    CloseFile(0)
    End ; ���� �� ������� ��������� �������
  EndIf
;}
EndProcedure

Procedure deleteMod(name.s)
  ForEach mods()
    If mods()\name = name
      DeleteElement(mods())
      ProcedureReturn #True
    EndIf
  Next
  
  ProcedureReturn #False  
EndProcedure


;{ GetMod's section
Procedure.s readHTTPFile(file.s) ;���������� ���� � ����� � ������
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

Procedure fillGetModsList()
  text.s = ReadHTTPFile("http://arcanummods.net23.net/mods.zip")

  ;������ ���� � ���������� �����
  count = CountString(text, Chr(13))
  desc.s = ""
  skip = #False
  i = 1
  
  While i < count
    key.s = StringField(text, i, Chr(13))
    keyLen = Len(Trim(key))
    
    
    If beginsWith(key, "[[name]]") = 1
      
      skip = #False
      If desc <> ""
        mods()\desc = desc
        desc = ""
      EndIf

      name.s = Right(Trim(key),KeyLen - 8)
      isThere = #False 
      ForEach mods() ;--���� ��� ���� �����, �� ����������
        If mods()\name = name And mods()\isDownloaded = #True
            skip = #True
        EndIf
      Next
      
      If skip = #False
        AddGadgetItem(#lstGetModList,-1,name)
        AddElement(mods())
        mods()\name = name
        mods()\isDownloaded = #False
      EndIf
      
    ElseIf beginsWith(key,"[[version]]") = 1
      If skip = #False
        mods()\version = Right(Trim(key),KeyLen - 11)
      EndIf
      
    Else
      If skip = #False
        desc = desc + key + Chr(13)
      EndIf
    EndIf
    
    mods()\desc = desc
    
    i = i + 1
  Wend
EndProcedure

Procedure downloadAndUnzipMod(*mod)
  tempName.s = GetTemporaryDirectory() + "ArcanumLauncher\" + Str(Random(10000000)) + ".zip"
  d(">downloading from http://arcanummods.net23.net/" + dMod + ".zip")
  d(">downloading to " + Chr(34) + tempName + Chr(34))
  
  d("Thread was successfully created")
  
  If FileSize(GetTemporaryDirectory() + "ArcanumLauncher\") <> -2 
    If CreateDirectory(GetTemporaryDirectory() + "ArcanumLauncher\")
      d("Directory " + Chr(34) + GetTemporaryDirectory() + "ArcanumLauncher\" + Chr(34) + " was created")
    Else
      d("!ERROR: can't create " + Chr(34) + GetTemporaryDirectory() + "ArcanumLauncher\" + Chr(34) + " directory")
    EndIf
  EndIf
  
  dModTempFile = tempName
  
  SetGadgetText(#lblDownloading, "Downloading " + dMod + "...")

  d("Receiving file...")
  If UrlToFileWithProgress(tempName, "http://arcanummods.net23.net/" + dMod + ".zip")
    DisableGadget(#btnAbortDownloading,1)
    SetGadgetState(#pbDownloading, 100)
    d("Unzipping file...")
    SetGadgetText(#lblDownloading, "Unzipping " + dMod + "...")
    If PureZIP_ExtractFiles(tempName,"*.*", lDirectory + "mods\" + dMod + "\",#True) <> #Null
      d("Success!")
      SetGadgetText(#lblDownloading, "Installing of " + dMod + " was successfully finished")
    
      ForEach mods()
        If mods()\name = dMod
          mods()\isDownloaded = #True
          Break
        EndIf
      Next
      
      AddGadgetItem(#lstMods,-1, dMod)
      RemoveGadgetItem(#lstGetModList,GetGadgetState(#lstGetModList))
      SetGadgetState(#lstGetModList, -1)
      
    Else
      d("!ERROR: can't unzip")
      d("Aborted!")
      SetGadgetText(#lblDownloading, "ERROR: Can't unzip " + dMod)
    EndIf
  Else
    d("!ERROR: receiving failed...")
    d("Aborted!")
    SetGadgetText(#lblDownloading, "ERROR: Can't download " + dMod)
  EndIf
  
  
  If DeleteFile(dModTempFile)
    d("Temp file deleted")
  Else 
    d("!ERROR: can't delete temp file")
  EndIf
  
  dIndent(3)
  FlushFileBuffers(0)
  SetWindowTitle(#wndGetMod,"ArcanumLauncher " + lVersion + ", Mod Downloader")
  Delay(2000)
  
  HideGadget(#lstGetModList,0)
  HideGadget(#wbGetMod,0)
  HideGadget(#lblDownloading,1)
  HideGadget(#pbDownloading, 1)
  HideGadget(#btnAbortDownloading, 1)
  
EndProcedure

Procedure installMod(mod.s)
  
  dMod = mod
  
  d("installing " + dMod)
  d("---")
  
  d(">mod's name: " + mod)
  d(">mod size: " + Str(dModSize) + " bytes")
  
  DisableGadget(#btnAbortDownloading,0)
  SetGadgetState(#pbDownloading, 0)
  
  dThread = CreateThread(@downloadAndUnzipMod(), 0)
  
  If dThread
    SetGadgetItemText(#wbGetMod,#PB_Web_HtmlCode,"")
    HideGadget(#lstGetModList,1)
    HideGadget(#wbGetMod,1)
    HideGadget(#lblDownloading,0)
    HideGadget(#pbDownloading, 0)
    HideGadget(#btnAbortDownloading, 0)
    
    SetWindowTitle(#wndGetMod,"Downloading " + mod + "...")
  EndIf
  
EndProcedure

Procedure onUrlChanged(Gadget, Url.s) 
  If Url = "about:blank#install"
    installMod(GetGadgetText(#lstGetModList))
  EndIf 
  
  ProcedureReturn #False
EndProcedure 

Procedure openWndGetMod()
  If OpenWindow(#wndGetMod, 222, 231, 764, 480, "ArcanumLauncher " + lVersion + ", Mod Downloader",  #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible | #PB_Window_TitleBar, WindowID(#wnd))
    ListViewGadget(#lstGetModList, 5, 5, 220, 470)
    
    If ListIsFilled = #False
      fillGetModsList()
      ListIsFilled  = #True
    Else
      ForEach mods()
        If mods()\isDownloaded = #False
          AddGadgetItem(#lstGetModList,-1, mods()\name)
        EndIf
      Next
    EndIf
    
    WebGadget(#wbGetMod, 230, 5, 530, 470, "about:blank")
    SetGadgetAttribute(#wbGetMod, #PB_Web_NavigationCallback, @onUrlChanged())
    
    TextGadget(#lblDownloading,220,200,350,20,"Downloading...")
    HideGadget(#lblDownloading,1)
    
    ProgressBarGadget(#pbDownloading,220,220,250,25,0,100, #PB_ProgressBar_Smooth)
    HideGadget(#pbDownloading,1)
    
    ButtonGadget(#btnAbortDownloading,480,220,100,25, "Abort")
    HideGadget(#btnAbortDownloading, 1)
    
    HideWindow(#wndGetMod, 0)
  EndIf
EndProcedure
  
;}

If (argMod = "")
  OpenWnd(0)
  
  If CreatePopupMenu(#menu)
    MenuItem(#menuModDescription, "Open description")
    MenuItem(#menuCheckVersion, "Check for updates")
    MenuItem(#menuDeleteMod, "Delete")
  EndIf
  
  ;If checkConnection("www.arcanummods.net23.net", 80) = #False
  ;  DisableGadget(#btnGetMod, 1)
  ;  d("!Warning: can't connect to the server. Check your firewall settings")
  ;EndIf
  
  SetGadgetState(#lstMods, 0)
Else
  OpenWnd(1)
  
  ForEach mods()
    If (mods()\name = argMod)
      runArcanum(argMod)
    EndIf
  Next
  
  ;����������, ���� ��� �� ����� ������
  MessageRequester("Ooops :(","Can't find specified mod",#MB_ICONERROR)
  End 
EndIf

;Events Handler
;{
Repeat 
    Event = WaitWindowEvent(10) 
    EventGadget = EventGadget()
    
    If Event = #PB_Event_Gadget
      Select EventGadget
        Case #btnGo
          runArcanum(GetGadgetText(#lstMods))
          
        Case #btnGetMod
          OpenWndGetMod()
          DisableWindow(#wnd, 1)
          
        Case #btnAbortDownloading
          If IsThread(dThread)
            CloseFile(1)
            KillThread(dThread)
            DeleteFile(dModTempFile)
            HideGadget(#lstGetModList,0)
            HideGadget(#wbGetMod,0)
            HideGadget(#lblDownloading,1)
            HideGadget(#pbDownloading, 1)
            HideGadget(#btnAbortDownloading, 1)
            d("Aborted!")
            dIndent(3)
            FlushFileBuffers(0)
            SetWindowTitle(#wndGetMod,"ArcanumLauncher " + lVersion + ", Mod Downloader")
          EndIf
          
        Case #lstMods
          If EventType() = #PB_EventType_RightClick
            DisplayPopupMenu(#menu,WindowID(#wnd))
          EndIf
          
        Case #lstGetModList
          If EventType() = #PB_EventType_LeftClick
            name.s = GetGadgetText(#lstGetModList)
            
            ForEach mods()
              If mods()\name = name
                  SetGadgetItemText(#wbGetMod,#PB_Web_HtmlCode,mods()\desc)
                  Break
              EndIf
            Next
          EndIf
      EndSelect
      
      
    ElseIf Event = #PB_Event_Menu
      Select EventMenu()
          
        Case #menuDeleteMod
          If MessageRequester("", "Are you sure you want to delete this mod? Saves will be deleted as well", #PB_MessageRequester_YesNo  | #MB_ICONQUESTION) = #PB_MessageRequester_Yes
            modName.s = GetGadgetText(#lstMods)
            If deleteMod(modName) = #True
              If DeleteDirectory("mods\" + modName, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force )
                RemoveGadgetItem(#lstMods, GetGadgetState(#lstMods))
              Else
                MessageRequester("Ooops :(", "Can't delete mod", #MB_ICONERROR)
              EndIf
            EndIf
          EndIf
        
      EndSelect
      
      
    ElseIf Event = #PB_Event_CloseWindow
      If EventWindow() = #wnd 
        End
      Else
        DisableWindow(#wnd, 0)
        CloseWindow(EventWindow())
      EndIf
    EndIf
    
ForEver
  
If activatedMod <> ""
  errors.i = deactivateMod(activatedMod)
  If errors = 0
     MessageRequester("Weee :)","Closed and restored successfully", #MB_ICONINFORMATION)
   Else
     temp.s = " errors have "
     If errors = 1 : temp = " error has " : EndIf
     MessageRequester("Ooops :(", Str(errors) + temp + "occured. See ''launcherDebug.txt'' for details", #MB_ICONERROR)
  EndIf
  CloseFile(0)
  MessageRequester("closed","closed and restored", #MB_ICONINFORMATION)
  End
EndIf
;}
; IDE Options = PureBasic 4.51 (Windows - x86)
; CursorPosition = 122
; FirstLine = 95
; Folding = RAq+
; EnableXP
; UseIcon = kjefo84u.ico
; Executable = C:\Documents and Settings\vladgor\������� ����\launcher.exe
; EnableCompileCount = 86
; EnableBuildCount = 16