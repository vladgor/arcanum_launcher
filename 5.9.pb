; arcanum launcher — запуск арканумовских модов

;version 5.4
; относительно стабильна

;TODO: после нескольких открытий перестаёт появляться сообщение "У вас нет бэкапов для этого мода"
;      исправить! (запилить очистку списка с бэкапами)

;описание ошибок, возвращаемых функциями
Enumeration 0 Step  -1
  #L_BACKUPMOD_CANTCREATEFILE
  
  #L_UNBACKUPMOD_CANTUNZIP
  
  #L_TUPDATEMOD_CANTBACKUP
EndEnumeration

;TODO: запуск арканума с ключами
;      дебагинг

Global lVersion.s = "0.5.4"

Global lProcessPid = 0 ;назначается позже
Global lProcessName.s = GetFilePart(ProgramFilename())
Global lDirectory.s = GetPathPart(ProgramFilename())

;если ещё раз запущен тот же экземпляр лончера, то закрываем его
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

; смотрим, какой мод запускать, если программа была вызвана с аргументом
Global argMod.s = LCase(ProgramParameter())
Global argKeys.s = ProgramParameter()

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
  #menuCreateShortcut
  #menuBackupMod
  #menuUnbackupMod
  
  ;--------get mod-------
  #lstGetModList
  #wbGetMod
  #lblDownloading
  #pbDownloading
  #btnAbortDownloading
  
  ;--------description--------
  #wndDescription
  #wbDescription
  
  ;--------shortcut-----------
  #wndShortcut
  
  #btnShortcutCreate
  #txtShortcut
  #lblShortcut
  #lblShortcutList
  #lblShortcutFullScreen
  #lblShortcutFPS
  #lblShortcutNoSound
  #lblShortcutNoRandom
  #lblShortcutScrollFps
  #lblShortcutScrollDist
  #lblShortcutMod
  #lblShortcutNo3D
  #lblShortcutVidFreed
  #lblShortcutDoubleBuffer
  #lblShortcutMpAutoJoin
  #lblShortcutMpNoBcast
  #lblShortcutDialogNumber
  #lblShortcutDialogCheck
  #lblShortcutGenderCheck
  #lblShortcutLogCheck
  
  ;-----backupMod---------
  #wndMakeBackup
  
  #txtMakeBackupName
  #lblMakeBackupName
  #lblMakeBackupDescription
  #txtMakeBackupDescription
  #lblMakeBackupStatus
  
  #btnMakeBackup
  
  ;-----unbackupMod------
  #wndUnbackupMod
  
  #lblUnbackupMod
  #lblUnbackupModStatus
  #btnUnbackupMod
  #lstUnbackupMod
EndEnumeration
;}

Structure mod
  name.s
  desc.s ;description

  isDownloaded.b ;#true or #false
  
  size.q
  version.s
  newversion.s
  whatsnew.s
  link.s
  
  List files.s()
EndStructure


Global NewList mods.mod()

;список папок, которые мод должен заменить.
;используется в activateMod() и deactivateMod()
;!ВАЖНО! — в makeModsList() папки для мода надо добавлять вручную (там, где mkDir)
;!     ! — если папка обязательно должна быть в папке с модом, то её надо добавить в makeModsList()
Global NewList DirsToReplace.s() 

;{ to replace
AddElement(DirsToReplace())
DirsToReplace() = "modules\Arcanum\save"
;}

Global NewList DirsToRemove.s()
Global NewList DirsToClear.s()


;{ to clear
AddElement(DirsToClear())
DirsToClear() = "modules\Arcanum\maps"
;}

Global NewList FilesToBackup.s()


;Global NewList arcanumDatNumber.i() ; здесь будут храниться номера для arcanumN.dat
;Global NewList arcanumPatchNumber.i() ; и arcanum.patchN

Global activatedMod.s = ""
;wtf? bullshitty code here
Global dMod.s = ""
Global dModTempFile.s = ""
Global dThread = 0

Global ListIsFilled = #False

IncludeFile "localizations.pb"
IncludeFile "shortcut.pb"
IncludeFile "debug.pb"
IncludeFile "common.pb"
IncludeFile "wndShortcut.pb"
IncludeFile "download.pb"
IncludeFile "wndMakeBackup.pb"
IncludeFile "wndUnbackupMod.pb"



; смотрим, есть ли нужные для работы программы папки
; если нет, создаём их
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

;теперь смотрим, какой мусор (бэкап-папки) остались с прошлого запуска лончера
;если возможно, исправляем
;(можно было соединить с предыдущим циклом, но тогда будет неудобно читать)
ForEach DirsToReplace()
  If directoryIsEmpty(DirsToReplace() + "Backup") = 1 ;если есть пустая папка-бэкап
    If DeleteDirectory(DirsToReplace() + "Backup","",#PB_FileSystem_Recursive | #PB_FileSystem_Force)
      d("Directory " + Chr(34) + DirsToReplace() + "Backup" + Chr(34) + " was deleted")
    Else
      d("!ERROR: can't delete " + Chr(34) + "mods\NoMod" + Chr(34) + " directory")
    EndIf
  ElseIf directoryIsEmpty(DirsToReplace() + "Backup") = 0 ;если есть, но не пустая
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



;сканируем папку с модами
Procedure makeModsList()
  ;смотрим, какие есть папки в директории mods\
  ;из этих папок составляем список модов
  ;(каждая папка - отдельный мод)
  
  Directory$ = "mods\"
  If ExamineDirectory(0, Directory$, "*.*")  
    
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory And DirectoryEntryName(0) <> "." And DirectoryEntryName(0) <> ".." And beginsWith(DirectoryEntryName(0), "!") = 0
        
        modName.s = DirectoryEntryName(0)
        ;{ создаём необходимые папки
        mkDir("mods\" + modName + "\modules\Arcanum\Save")
        ;mkDir("mods\" + DirectoryEntryName(0) + "\modules\Arcanum\Maps")
        ;}
          
        AddElement(mods())
        mods()\name = modName
        mods()\version = getFileContent("mods\" + modName + "\modVersion.txt")
        mods()\isDownloaded = #True
        
        AddGadgetItem(#lstMods,-1,modName + Chr(10) + mods()\version)
      EndIf
    Wend
    FinishDirectory(0)
  EndIf

EndProcedure

Procedure openWnd(hidden.b)
  If OpenWindow(#wnd, 374, 199, 360, 340, "ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered | #PB_Window_Invisible)
    ListIconGadget(#lstMods, 10, 10, 340, 280,localColModName, 250, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#lstMods,1, localColModVersion, 85)
    makeModsList()
    
    If findMod(cfgLastUsedMod)
      SetGadgetState(#lstMods, ListIndex(mods()))
      SetActiveGadget(#lstMods)
    Else
      SetGadgetState(#lstMods, -1)
    EndIf
    
    ButtonGadget(#btnGo, 250, 300, 100, 25, localBtnLaunch) 
    ButtonGadget(#btnGetMod, 10, 300, 125, 25, localBtnCheckingConnection)
    DisableGadget(#btnGetMod, 1)
    
    If (hidden = 0)
      HideWindow(#wnd, 0)
    EndIf
  EndIf
EndProcedure

; смотрим доступный номер для файла arcanumN.dat
Procedure.i checkForArcanumDatNumber()
  output.i = 1
  While FileSize("arcanum" + Str(output) + ".dat") <> -1
    output = output + 1
  Wend
  
  ProcedureReturn output
EndProcedure

; смотрим доступный номер для файла arcanum.patchN
Procedure.i checkForArcanumPatchNumber()
  output.i = 1
  While FileSize("modules\arcanum.patch" + Str(output)) <> -1
    output = output + 1
  Wend
  
  ProcedureReturn output
EndProcedure

;перемещаем файлы мода в папку с Арканумом
Procedure.i activateMod(name.s)
  ; находим нужный мод
  ForEach mods()
    If LCase(mods()\name) = LCase(name)
      Break
    EndIf
  Next
  
  modFolder.s = "mods\" + mods()\name + "\"
  errors.i = 0 ;counts errors
  
  ;сканируем папку с модом
  SearchFilesInit(modFolder,"*.*",1)
  Repeat
    file.s=SearchFilesGet()
    
    If file="" : Break : EndIf
    
    shouldIaddThisFileToListOrNot.b = 1
    
    temp.s = Right(file,Len(file) - Len(RTrim(modFolder,"\")) - 1)
              
    ForEach DirsToReplace()
      If (beginsWith(temp,DirsToReplace())) ;если файл лежит в любой из папок dirsToReplace
        shouldIaddThisFileToListOrNot = 0 ;то его не добавляем
      EndIf
    Next
    
    If shouldIaddThisFileToListOrNot = 1
      AddElement(mods()\files())
      mods()\files() = file
    EndIf
  ForEver
  
  d("activate")
  d("---")

  ;перемещаем папки, указанные в DirsToReplace()
  ForEach DirsToReplace()
    ;если у пользователя уже есть данная папка, то переименовываем её
    If FileSize(DirsToReplace()) = -2 And FileSize(modFolder + DirsToReplace()) = -2      
      If RenameFile(DirsToReplace(), DirsToReplace() + "Backup")
        d("folder backuped: " + DirsToReplace())
      Else
        d("!ERROR: can't make backup " + DirsToReplace())
        errors = errors + 1
      EndIf
    EndIf
    
    ; перемещаем папку
    If FileSize(modFolder + DirsToReplace()) = -2
      If RenameFile(modFolder + DirsToReplace(), DirsToReplace())
        d("folder replaced: " + modFolder + DirsToReplace() + " -> " + DirsToReplace())
      Else
        d("!ERROR: can't replace folder " + modFolder + DirsToReplace() + " -> " + DirsToReplace())
        errors = errors + 1
      EndIf 
    EndIf 
  Next
  
  ; перемещаем файлы мода, попутно переименовывая некоторые из них
  ; (arcanumN.dat, modules\arcanum.patchN)
  ForEach mods()\files()
    oldPath.s = mods()\files()
    newPath.s = RemoveString(oldPath, modFolder)
    
    ;если файл arcanumN.dat
    ;If (LCase(Left(newPath, 7)) = "arcanum") And (Right(newPath,4) = ".dat")
      ; формируем новое имя для файла
    ;  newPath = "arcanum" + Str(checkForArcanumDatNumber()) + ".dat"
    ;  ; запоминаем номера
    ;  AddElement(arcanumDatNumber())
    ;  arcanumDatNumber() = checkForArcanumDatNumber()
    ;EndIf
    
    ; если файл modules\arcanum.patchN
    ;If (LCase(Left(newPath, 21)) = "modules\arcanum.patch")
    ;  ; формируем новое имя для файла
    ;  newPath = "modules\arcanum.patch" + Str(checkForArcanumPatchNumber()) 
    ;  ; запоминаем номера
    ;  AddElement(arcanumPatchNumber())
    ;  arcanumPatchNumber() = checkForArcanumPatchNumber()
    ;EndIf
    
    ;если нет такой папки, куда перемещаем, то создаём и запоминаем её
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
         d("!ERROR: can't make backup "+ oldPath + " —> " + newPath)
         errors = errors + 1
      EndIf
    EndIf
    
    If RenameFile(oldPath, newPath)
      d("replaced: "+ oldPath + " —> " + newPath)
    Else
      d("!ERROR: can't rename "+ oldPath + " —> " + newPath)
      errors = errors + 1
    EndIf
  Next
  
  FlushFileBuffers(0)
  ProcedureReturn errors
EndProcedure

;перемещаем файлы мода обратно
;возвращает количество ошибок
Procedure.i deactivateMod(name.s)
  ; находим нужный мод
  ForEach mods()
    If LCase(mods()\name) = LCase(name)
      Break
    EndIf
  Next
  
  dIndent(3)
  d("Deactivate")
  d("---")
  
  modFolder.s = "mods\" + mods()\name + "\"
  errors.i = 0
  
  
  ;number.i = 1 ; номера для arcanumN.dat и modules\arcanum.patchN
  oldPath.s
  newPath.s
  
  ;сперва перемещаем arcanumN.dat файлы
  ;ForEach arcanumDatNumber()
  ;  oldPath = "arcanum" + Str(arcanumDatNumber()) + ".dat"
  ;  newPath = modFolder + "arcanum" + Str(number) + ".dat"
  ;  
  ;  If RenameFile(oldPath, newPath)
  ;    d("replaced: "+ oldPath + " —> " + newPath)
  ;  Else
  ;    d("!ERROR: "+ oldPath + " —> " + newPath)
  ;  EndIf
    
  ;  number = number + 1
  ;Next
  
  ;number = 1
  
  ;затем modules\arcanum.patchN
  ;ForEach arcanumPatchNumber()
  ;  oldPath = "modules\arcanum.patch" + Str(arcanumPatchNumber())
  ;  newPath = modFolder + "modules\arcanum.patch" + Str(number)
  ;  
  ;  If RenameFile(oldPath, newPath)
  ;    d("replaced: "+ oldPath + " —> " + newPath)
  ;  Else
  ;    d("!ERROR: "+ oldPath + " —> " + newPath)
  ;  EndIf
  ;  
  ;  number = number + 1
  ;Next
  
  ;затем нужные папки
  ForEach DirsToReplace()
    If FileSize(DirsToReplace()) = -2 And FileSize(DirsToReplace() + "Backup") = -2
      mkDir(modFolder + Left(DirsToReplace(),findLastMatch(DirsToReplace(),"\")))
      
      If RenameFile(DirsToReplace(), modFolder + DirsToReplace())
        d("folder replaced: "+ DirsToReplace() + " —> " + modFolder + DirsToReplace())
      Else
        d("!ERROR: "+ oldPath + " —> " + newPath)
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
  
  
  ; перемещаем оставшийся хлам
  ForEach mods()\files()
    oldPath = RemoveString(mods()\files(), modFolder)
    newPath = mods()\files()
    
    ; если не arcanumN.dat или arcanum.patchN
    ;If Not(((LCase(Left(oldPath, 7)) = "arcanum") And (Right(oldPath,4) = ".dat")) Or (LCase(Left(oldPath, 21)) = "modules\arcanum.patch"))
      If RenameFile(oldPath, newPath)
        d("replaced: "+ oldPath + " —> " + newPath)
      Else
        d("!ERROR: "+ oldPath + " —> " + newPath)
        errors = errors + 1
      EndIf
    ;EndIf
  Next
  
  ; удаляем созданные ранее папки
  ForEach DirsToRemove()
    If DirsToRemove() <> "" And DirsToRemove() <> "\"
      If DeleteDirectory(DirsToRemove(),"",#PB_FileSystem_Recursive | #PB_FileSystem_Force)
        d("folder deleted: " + DirsToRemove())
      EndIf
    EndIf
  Next
  
  ;переименовываем обратно бэкап-файлы
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
   If cfgLanguage = ""
     temp.s = " errors have "
     If errors = 1 : temp = " error has " : EndIf
     MessageRequester("", Str(errors) + temp + "occured. See " + Chr(34) + "launcherDebug.txt" + Chr(34) + " for details", #MB_ICONERROR)
   Else
     MessageRequester("", ReplaceString(localMsgErrorsOccured, "%errors", Str(errors), #PB_String_NoCase), #MB_ICONERROR)
   EndIf
  EndIf
  
  PreferenceGroup("common")
  WritePreferenceString("lastUsedMod", activatedMod)
  
; запускаем Арканум
;{
  Program = RunProgram("Arcanum.exe",argKeys, "", #PB_Program_Open)
  If Program
    HideWindow(#wnd,1)
    While ProgramRunning(Program)
      Delay(1000)
    Wend
    
    CloseProgram(Program)
    
    errors = deactivateMod(activatedMod)
    If errors > 0
     If cfgLanguage = ""
       temp.s = " errors have "
       If errors = 1 : temp = " error has " : EndIf
       MessageRequester("", Str(errors) + temp + "occured. See " + Chr(34) + "launcherDebug.txt" + Chr(34) + " for details", #MB_ICONERROR)
     Else
       MessageRequester("", ReplaceString(localMsgErrorsOccured, "%errors", Str(errors), #PB_String_NoCase), #MB_ICONERROR)
     EndIf
    EndIf
    
    ClosePreferences()
    CloseFile(0)
    End  
  Else
    deactivateMod(activatedMod)
    ClosePreferences()
    CloseFile(0)
    End ; если не удалось запустить арканум
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
  
  Procedure fillGetModsList()
    text.s = ReadHTTPFile(cfgInfoLink)
  
    ;парсим файл с описаниями модов
    count = CountString(text, Chr(13))
    desc.s = ""
    skip = #False
    i = 1
    
    ForEach mods()
      If mods()\isDownloaded = #False
          DeleteElement(mods())
      EndIf
    Next
    
    While i < count
      key.s = StringField(text, i, Chr(13))
      keyLen = Len(Trim(key))
      
      If beginsWith(key, "[[name]]")
        
        skip = #False
        If desc <> ""
          mods()\desc = desc
          desc = ""
        EndIf
  
        name.s = Right(Trim(key),KeyLen - 8)
        isThere = #False 
        ForEach mods() ;--если уже есть такой, то пропускаем
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
        
      ElseIf beginsWith(key,"[[version]]")
        If skip = #False
          mods()\version = Right(Trim(key),KeyLen - 11)
        EndIf
      ElseIf beginsWith(key, "[[what's new]]")
        
      ElseIf beginsWith(key,"[[link]]")
        If skip = #False
          mods()\link = Right(Trim(key),KeyLen - 8)
        EndIf
        
      ElseIf beginsWith(key,"[[size]]")
        If skip = #False
          mods()\size = ValD(Right(Trim(key),KeyLen - 8))
        EndIf  
        
      ElseIf key <> ""
        If skip = #False
          desc = desc + key + Chr(13)
        EndIf
      EndIf
      
      mods()\desc = desc
      
      i = i + 1
    Wend
  EndProcedure
  
  Procedure downloadAndUnzipMod(*value)
    mod.s = dMod
    
    findMod(mod)
    
    tempName.s = GetTemporaryDirectory() + "ArcanumLauncher\" + Str(Random(10000000)) + ".zip"
    d(">downloading from " + Chr(34) + mods()\link + Chr(34))
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
    
    SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusPreparing, "%mod", mod, #PB_String_NoCase))
  
    d("Receiving file...")
    
    If UrlToFileWithProgress(tempName, mods()\link, mods()\size)
      DisableGadget(#btnAbortDownloading,1)
      SetGadgetState(#pbDownloading, 100)
      
      If mods()\size = FileSize(tempName)
        SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusUnzipping, "%mod", mod, #PB_String_NoCase))
        
        pathToUnzip.s = lDirectory + "mods\" + mod + "\"
        
        If CreateDirectory(pathToUnzip)
          d("Directory " + Chr(34) + pathToUnzip + Chr(34) + " was created")
        Else
          d("!ERROR: can't create " + Chr(34) + pathToUnzip + Chr(34) + " directory")
        EndIf
        
        d("Unzipping file...")
        
        If PureZIP_ExtractFiles(tempName,"*.*", pathToUnzip,#True) <> #Null
          d("Success!")
          SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusInstalled, "%mod", mod, #PB_String_NoCase))
        
          mods()\isDownloaded = #True
          
          AddGadgetItem(#lstMods,-1, mod + Chr(10) + mods()\version)
          RemoveGadgetItem(#lstGetModList,GetGadgetState(#lstGetModList))
          SetGadgetState(#lstGetModList, -1)
          
        Else ;if cant unzip
          d("!ERROR: can't unzip")
          d("Aborted!")
          SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusCantUnzip, "%mod", mod, #PB_String_NoCase))
        EndIf
        
      Else ;if downloaded file is damaged
        d("!ERROR: downloaded file is damaged")
        d("Aborted!")
        SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusFileDamaged, "%mod", mod, #PB_String_NoCase))
      EndIf
    Else ;if cant receive file
      d("!ERROR: receiving failed...")
      d("Aborted!")
      SetGadgetText(#lblDownloading, ReplaceString(localLblGetModStatusCantDownload, "%mod", mod, #PB_String_NoCase))
    EndIf
    
    
    If DeleteFile(tempName)
      d("Temp file deleted")
    Else 
      d("!ERROR: can't delete temp file")
    EndIf
    
    dIndent(3)
    FlushFileBuffers(0)
    SetWindowTitle(#wndGetMod, localWndGetModTitle + ", ArcanumLauncher " + lVersion)
    Delay(2000)
    
    HideGadget(#lstGetModList,0)
    HideGadget(#wbGetMod,0)
    HideGadget(#lblDownloading,1)
    HideGadget(#pbDownloading, 1)
    HideGadget(#btnAbortDownloading, 1)
    
    ProcedureReturn #True
    
  EndProcedure
  
  Procedure installMod(mod.s)
    
    dMod = mod
    
    d("installing " + dMod)
    d("---")
    
    d(">mod's name: " + mod)
    
    DisableGadget(#btnAbortDownloading,0)
    SetGadgetState(#pbDownloading, 0)
    
    dThread = CreateThread(@downloadAndUnzipMod(), 0)
    
    If (dThread)
      SetGadgetItemText(#wbGetMod,#PB_Web_HtmlCode,"")
      HideGadget(#lstGetModList,1)
      HideGadget(#wbGetMod,1)
      HideGadget(#lblDownloading,0)
      HideGadget(#pbDownloading, 0)
      HideGadget(#btnAbortDownloading, 0)
      
      SetWindowTitle(#wndGetMod,localWndGetModDownloadingTitle + " " + mod + "...")
    EndIf
    
  EndProcedure
  
  Procedure onUrlChanged(Gadget, Url.s) 
    If Url = "about:blank#install"
      installMod(GetGadgetText(#lstGetModList))
    EndIf 
    
    ProcedureReturn #False
  EndProcedure 
  
  Procedure openWndGetMod(isUpdate.b)
    If OpenWindow(#wndGetMod, 222, 231, 764, 480, localWndGetModTitle + ", ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_Invisible | #PB_Window_TitleBar, WindowID(#wnd))
      ListViewGadget(#lstGetModList, 5, 5, 220, 470)
      
      WebGadget(#wbGetMod, 230, 5, 530, 470, "about:blank")
      SetGadgetAttribute(#wbGetMod, #PB_Web_NavigationCallback, @onUrlChanged())
      
      TextGadget(#lblDownloading,220,200,350,20,"Downloading...")
      ProgressBarGadget(#pbDownloading,220,220,250,25,0,100, #PB_ProgressBar_Smooth)
      ButtonGadget(#btnAbortDownloading,480,220,100,25, localBtnAbortDownloading)
      
      If isUpdate
        HideGadget(#lstGetModList,1)
        HideGadget(#wbGetMod,1)
      Else
        fillGetModsList()
        
        HideGadget(#lblDownloading,1)
        HideGadget(#pbDownloading,1)
        HideGadget(#btnAbortDownloading, 1)
      EndIf
      
      HideWindow(#wndGetMod, 0)
    EndIf
  EndProcedure
  
  
  Procedure backupMod(mod.s, backupName.s, description.s)
    
    archiveName.s = "mods\!backups\" + mod + "\" + backupName + ".zip"
    modPath.s = "mods\" + mod + "\"
    
    If FileSize(archiveName) <> - 1
      ProcedureReturn #L_BACKUPMOD_CANTCREATEFILE
    EndIf
    
    If FileSize("mods\!backups") <> - 2
      CreateDirectory("mods\!backups")
    EndIf
    
    If FileSize("mods\!backups\" + mod) <> - 2
      CreateDirectory("mods\!backups\" + mod)
    EndIf
    
    PureZIP_Archive_Create(archiveName, #APPEND_STATUS_CREATE)
    
    If FileSize(modPath + "data\Players\") = -2 ; копируем сейвы сетевых персонажей
      PureZIP_AddFiles(archiveName,modPath + "data\Players\" + "*.*",#PureZIP_StorePathAbsolute, #PureZIP_RecursiveZeroDirs)
    EndIf
    
    If ExamineDirectory(0, modPath + "modules\", "*.*") ; копируем сейвы сингловых персонажей
      While NextDirectoryEntry(0)
        If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
          If beginsWith(DirectoryEntryName(0), ".") = 0
            saveFolderName.s = modPath + "modules\" + DirectoryEntryName(0) + "\save\"
            ;Debug saveFolderName
            If FileSize(saveFolderName) = -2
              PureZIP_AddFiles(archiveName,saveFolderName + "*.*",#PureZIP_StorePathAbsolute, #PureZIP_RecursiveZeroDirs)
            EndIf
          EndIf
        EndIf
      Wend
      FinishDirectory(0)
    EndIf
  
    PureZIP_Archive_Close()
    
    setFileContent(GetPathPart(archiveName) + backupName + ".txt", description)
    
    ProcedureReturn #True
  EndProcedure
  
  Procedure unbackupMod(mod.s, backupName.s)
    temp.s = GetTemporaryDirectory() + "ArcanumLauncher\"
    
    If PureZIP_ExtractFiles("mods\!backups\" + mod + "\" + backupName + ".zip","*.*", GetTemporaryDirectory() + "ArcanumLauncher\", #True) = #Null
      ProcedureReturn #L_UNBACKUPMOD_CANTUNZIP  
    EndIf
    
    modPath.s = temp + "mods\" + mod + "\"
    
    If FileSize(modPath + "data\Players\") = -2 ; копируем сейвы сетевых персонажей
      If FileSize("mods\" + mod + "\data\Players\")
        DeleteDirectory("mods\" + mod + "\data\Players\", "*.*", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
      EndIf
      
      If FileSize("mods\" + mod + "\data\") <> -2 
        CreateDirectory("mods\" + mod + "\data\")
      EndIf
      
      RenameFile(modPath + "data\Players\", "mods\" + mod + "\data\Players\")
    EndIf
    
    If ExamineDirectory(0, modPath + "modules\", "*.*") ; копируем сейвы сингловых персонажей
      While NextDirectoryEntry(0)
        If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
          If beginsWith(DirectoryEntryName(0), ".") = 0
            saveFolderName.s = modPath + "modules\" + DirectoryEntryName(0) + "\save\"
            
            If FileSize("mods\" + mod + "\modules\" + DirectoryEntryName(0)) <> -2
              mkDir("mods\" + mod + "\modules\" + DirectoryEntryName(0))
            EndIf
            
            DeleteDirectory("mods\" + mod + "\modules\" + DirectoryEntryName(0) + "\save\", "*.*", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
            RenameFile(saveFolderName, "mods\" + mod + "\modules\" + DirectoryEntryName(0) + "\save\")
           
          EndIf
        EndIf
      Wend
      FinishDirectory(0)
    EndIf
    
    DeleteDirectory(temp,"*.*", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
    
    ProcedureReturn #True
  EndProcedure
  
  ;{ special thread functions
  
  Procedure tUpdateMod(*val)
    
    mod.s = GetGadgetText(#lstMods)
    dMod = mod
    
    findMod(mod)
    
    d("updating " + mod + " from " + mods()\version + " to " + mods()\newversion)
    d("---")
    
    errorText.s = ""
    
    tempName.s = GetTemporaryDirectory() + "ArcanumLauncher\" + Str(Random(10000000)) + ".zip"
    
    SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusBackuping, "%mod", mod, #PB_String_NoCase))
    d("Backuping mod...")
    
    If backupMod(mod, FormatDate("(%dd.%mm) before updating to " + mods()\newversion, Date()), FormatDate("%dd/%mm/%yyyy, %hh:%ii", Date()) + Chr(13) + Chr(10) + LSet("",10, "-") + Chr(13) + Chr(10) + "Updating to new version (from " + mods()\version + " to " + mods()\newversion + ")")
      d("Backuped!")
      
      SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusPreparing, "%mod", mod, #PB_String_NoCase))
      d("Downloading...")
      
      If UrlToFileWithProgress(tempName, mods()\link, mods()\size)
        SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusDeleting, "%mod", mod, #PB_String_NoCase))
        d("Downloaded!")
        
        d("Deleting old mod's folder...")
        
        If DeleteDirectory("mods\" + mod, "*.*", #PB_FileSystem_Force | #PB_FileSystem_Recursive)
          SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusUnzipping, "%mod", mod, #PB_String_NoCase))
          d("Deleted!")
          
          pathToUnzip.s = lDirectory + "mods\" + mod + "\"
          
          d("Unzipping mod...")
          
          If PureZIP_ExtractFiles(tempName,"*.*", pathToUnzip, #True) <> #Null
            d("Unzipped!")
            SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusUnbackuping, "%mod", mod, #PB_String_NoCase))
            
            d("Backuping old saves...")
            
            If unbackupMod(mod, FormatDate("(%dd.%mm) before updating to " + mods()\newversion, Date()))
              SetGadgetText(#lblDownloading, ReplaceString(localLblUpdateStatusOk, "%mod", mod, #PB_String_NoCase))
              d("Backuped!")
              d("Mod has been successfully updated")
              mods()\version = mods()\newversion
              
              
              SetGadgetItemText(#lstMods, GetGadgetState(#lstMods), mod  + Chr(10) + mods()\newversion)
              
              Delay(1500)
              
              HideWindow(#wndGetMod, 1)
              CloseWindow(#wndGetMod)
              
              DisableWindow(#wnd, 0)
              ForegroundWindowSet(WindowID(#wnd))
              
              dIndent(3)
              
              FlushFileBuffers(0)
              
              ProcedureReturn #True
            Else
              d("Can't unbackup mod")
              errorText = ReplaceString(localLblUpdateStatusUnbackupingError, "%mod", mod, #PB_String_NoCase)
            EndIf
          Else ;if not extracted
            d("Can't unzip mod")
            errorText = ReplaceString(localLblUpdateStatusUnzippingError, "%mod", mod, #PB_String_NoCase)
          EndIf
        Else ;if not deleted
          d("Can't delete mod's directory")
          errorText = ReplaceString(localLblUpdateStatusDeletingError, "%mod", mod, #PB_String_NoCase)
        EndIf
        
      Else ;if not downloaded
        d("Can't download mod")
        errorText = ReplaceString(localLblUpdateStatusDownloadingError, "%mod", mod, #PB_String_NoCase)
      EndIf
    Else ;if not backuped
      d("Can't backup mod's files")
      errorText = ReplaceString(localLblUpdateStatusBackupingError, "%mod", mod, #PB_String_NoCase)
    EndIf
    
    SetGadgetText(#lblDownloading, errorText + ". " + localLblUpdateStatusClosingWindow)
    Delay(2000)
    
    HideWindow(#wndGetMod, 1)
    CloseWindow(#wndGetMod)
              
    DisableWindow(#wnd, 0)
    ForegroundWindowSet(WindowID(#wnd))
    
    dIndent(3)
    
    FlushFileBuffers(0)
    
    ProcedureReturn #False
    
  EndProcedure
  
  Procedure tBackupMod(*val)
   SetGadgetText(#lblMakeBackupStatus, localLblBackupStatus)
   
   result = backupMod(GetGadgetText(#lstMods), GetGadgetText(#txtMakeBackupName), GetGadgetText(#txtMakeBackupDescription))
   
   If result
     SetGadgetColor(#lblMakeBackupStatus, #PB_Gadget_FrontColor, RGB(104,163,0))
     SetGadgetText(#lblMakeBackupStatus, localLblBackupStatusOk)
     
     Delay(1000)
     HideWindow(#wndMakeBackup, 1)
     CloseWindow(#wndMakeBackup)
     
     DisableWindow(#wnd, 0)
     ForegroundWindowSet(WindowID(#wnd)) ; потому что не работает стандартное SetActiveWindow()
     
   ElseIf result = #L_BACKUPMOD_CANTCREATEFILE
     SetGadgetColor(#lblMakeBackupStatus, #PB_Gadget_FrontColor, RGB(206,23,23))
     SetGadgetText(#lblMakeBackupStatus, localLblBackupStatusError)
     Delay(1500)
     SetGadgetText(#lblMakeBackupStatus, "")
     DisableGadget(#btnMakeBackup, 0)
   EndIf
   
  
  EndProcedure
  
  Procedure tUnbackupMod(*val)
    
    SetGadgetText(#lblMakeBackupStatus, localLblUnbackupStatus)
    
    result = unbackupMod(GetGadgetText(#lstMods), GetGadgetText(#lstUnbackupMod))
    
    If result
      SetGadgetColor(#lblUnbackupModStatus, #PB_Gadget_FrontColor, RGB(104,163,0))
      SetGadgetText(#lblUnbackupModStatus, localLblUnbackupStatusOk)
     
      Delay(1000)
      HideWindow(#wndUnbackupMod, 1)
      CloseWindow(#wndUnbackupMod)
      ClearList(Backups())
      DisableWindow(#wnd, 0)
      ForegroundWindowSet(WindowID(#wnd))
    Else
      SetGadgetColor(#lblUnbackupModStatus, #PB_Gadget_FrontColor, RGB(206,23,23))
      
      If result = #L_UNBACKUPMOD_CANTUNZIP
        SetGadgetText(#lblUnbackupModStatus, localLblUnbackupStatusCantUnzip)
      Else
        SetGadgetText(#lblUnbackupModStatus, localLblUnbackupStatusUnspec)
      EndIf
      
      
      Delay(1500)
      DisableGadget(#btnUnbackupMod, 0)
    EndIf
    
  EndProcedure  
     
  Procedure tCheckConnection(*value)
    If (cfgInfoTestHost <> "") And (cfgInfoTestPort <> 0)
      If checkConnection(cfgInfoTestHost, cfgInfoTestPort)
        SetGadgetText(#btnGetMod, localBtnGetMoreMods)
        DisableGadget(#btnGetMod, 0)
      Else
        SetGadgetText(#btnGetMod, localBtnCantConnect)
      EndIf
    Else
      If readHttpFile(cfgInfoTestFile) <> ""
        SetGadgetText(#btnGetMod, localBtnGetMoreMods)
        DisableGadget(#btnGetMod, 0)
      Else
        SetGadgetText(#btnGetMod, localBtnCantConnect)
      EndIf
    EndIf
  EndProcedure
  ;}
  
  Procedure updateMod(name.s)
    openWndGetMod(#True)
    DisableGadget(#btnAbortDownloading, 1)
    CreateThread(@tUpdateMod(), 0)
EndProcedure

  Procedure checkModForUpdates(mod.s)
    text.s = ReadHTTPFile(cfgInfoLink)
    version.s = ""
    
    findMod(mod)
    version = mods()\version
    
    newVersion.s = ""
    whatsnew.s = ""
    link.s = ""
    
    ;[[what's new]] обязательно должно идти после [[version]], [[version]] сразу после [[name]]
    count = CountString(text, Chr(13))
    t = #False
    i = 1
    
    While i < count
      key.s = Trim(StringField(text, i, Chr(13)))
      keyLen = Len(Trim(key))
      
      If key = "[[name]]" + mod
        t = #True
        i = i + 1
        Continue
      EndIf
      
      If t = #True
        If beginsWith(key,"[[version]]") 
          newVersion = Right(Trim(key),KeyLen - 11)
          mods()\newversion = newVersion
          
          If newVersion = version
            MessageRequester("", localMsgYouAlreadyHaveTheNewestVersion, #MB_ICONINFORMATION)
            ProcedureReturn #False
          EndIf  
          
        ElseIf beginsWith(key, "[[what's new]]")
          whatsnew = whatsnew + Right(Trim(key),KeyLen - 14) + Chr(13)
          
        ElseIf beginsWith(key, "[[link]]")
          mods()\link = Right(Trim(key),KeyLen - 8)
          
        ElseIf beginsWith(key, "[[size]]")
          mods()\size = Val(Right(Trim(key),KeyLen - 8))
          
        ElseIf (beginsWith(key, "[[") = 0) And (key <> "")
          Break
        EndIf
      EndIf
      
      i = i + 1
    Wend
    
    If t
      text.s = ReplaceString(localMsgNewVersionAvailable, "%version", version, #PB_String_NoCase)
      text = ReplaceString(text, "%newversion", newVersion, #PB_String_NoCase)
      
      message.s = text + Chr(13)
      message = message + whatsnew + Chr(13)
      message = message + localMsgDoYouWantToUpdate
      answer = MessageRequester("", message, #PB_MessageRequester_YesNo | #MB_ICONQUESTION)
      If answer = #PB_MessageRequester_Yes
        updateMod(mod)
      EndIf
    Else
      MessageRequester("", localMsgCantFindDownloadableMod, #MB_ICONERROR)  
    EndIf
  EndProcedure
;}


Procedure openDescriptionWnd(mod.s)
  If OpenWindow(#wndDescription, 374, 199, 650, 550, mod + " — " + localWndDescriptionTitle + ", ArcanumLauncher " + lVersion,  #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_TitleBar | #PB_Window_ScreenCentered, WindowID(#wnd))
    WebGadget(#wbDescription,0,0,650,550, lDirectory + "mods\" + mod + "\modDescription.html")
    SetActiveGadget(#wbDescription)
  EndIf
EndProcedure


If (argMod = "")
  OpenWnd(#False)
  
  If CreatePopupMenu(#menu)
    MenuItem(#menuModDescription, localMenuOpenDescription)
    MenuItem(#menuCheckVersion, localMenuCheckForUpdates)
    MenuItem(#menuCreateShortcut, localMenuCreateShortcut)
    MenuBar()
    MenuItem(#menuBackupMod, localMenuBackup)
    MenuItem(#menuUnbackupMod, localMenuUnbackup)
    MenuBar()
    MenuItem(#menuDeleteMod, localMenuDelete)
  EndIf
  
  CreateThread(@tCheckConnection(),0)
  
Else
  OpenWnd(#True)
  
  ForEach mods()
    If (LCase(mods()\name) = argMod)
      runArcanum(argMod)
    EndIf
  Next
  
  ;выполнится, если мод не будет найден
  MessageRequester("",localMsgCantFindSpecMod,#MB_ICONERROR)
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
        OpenWndGetMod(#False)
        DisableWindow(#wnd, 1)
        
      Case #btnAbortDownloading
        abortDownloading()
        
      Case #lstMods
        If EventType() = #PB_EventType_RightClick And GetGadgetText(#lstMods) <> ""
          If GetGadgetText(#lstMods) = "NoMod"
            DisableMenuItem(#menu, #menuCheckVersion, 1)
            DisableMenuItem(#menu, #menuModDescription, 1)
            DisableMenuItem(#menu, #menuDeleteMod, 1)
          Else
            DisableMenuItem(#menu, #menuModDescription, 0)
            DisableMenuItem(#menu, #menuCheckVersion, 0)
            DisableMenuItem(#menu, #menuDeleteMod, 0)
          EndIf
          
          DisplayPopupMenu(#menu,WindowID(#wnd))
        EndIf
        
      Case #lstGetModList
        If EventType() = #PB_EventType_LeftClick
          name.s = GetGadgetText(#lstGetModList)
          
          findMod(name)
          SetGadgetItemText(#wbGetMod,#PB_Web_HtmlCode,mods()\desc)
        EndIf
        
      Case #lstUnbackupMod
        If EventType() = #PB_EventType_LeftClick
          name.s = GetGadgetText(#lstUnbackupMod)
          
          ForEach Backups()
            If Backups()\name = name
              SetGadgetText(#lblUnbackupMod, Backups()\description)
              Break
            EndIf
          Next
          
        EndIf

      Case #btnShortcutCreate
        createModShortcut(GetGadgetText(#lstMods), Trim(GetGadgetText(#txtShortcut)))
        DisableWindow(#wnd, 0)
        CloseWindow(EventWindow())
        
      Case #btnMakeBackup
        DisableGadget(#btnMakeBackup, 1)
        CreateThread(@tBackupMod(), 0)
        
      Case #btnUnbackupMod
        DisableGadget(#btnUnbackupMod, 1)
        CreateThread(@tUnbackupMod(), 0)
     
        
      Case 22 To 37 ;если один из ключей для ярлыков
        text.s = GetGadgetText(EventGadget) + " "
        
        If FindString(text,":",0)
          text = StringField(text, 1, ":") + ":"
        EndIf
        
        text2.s = GetGadgetText(#txtShortcut)
        
        If FindString(text2, text, 0) = 0
          SetGadgetText(#txtShortcut, text2 + text)
          SetActiveGadget(#txtShortcut)
          SimulateKeyPress(#VK_END, 0, #False, #False, #False) 
        Else
          MessageRequester("", localMsgArgumentAlreadyWritten, #MB_ICONERROR)
        EndIf
        
    EndSelect
    
    
  ElseIf Event = #PB_Event_Menu
    Select EventMenu()
        
      Case #menuDeleteMod
        If MessageRequester("", localMsgDoYouWantToDeleteMod, #PB_MessageRequester_YesNo  | #MB_ICONQUESTION) = #PB_MessageRequester_Yes
          modName.s = GetGadgetText(#lstMods)
          If deleteMod(modName) = #True
            If DeleteDirectory("mods\" + modName, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force )
              RemoveGadgetItem(#lstMods, GetGadgetState(#lstMods))
            Else
              MessageRequester("", localMsgCantDeleteMod, #MB_ICONERROR)
            EndIf
          EndIf
        EndIf
        
      Case #menuCheckVersion
        checkModForUpdates(GetGadgetText(#lstMods))
        
      Case #menuModDescription
        openDescriptionWnd(GetGadgetText(#lstMods))
        DisableWindow(#wnd, 1)
        
      Case #menuCreateShortcut
        openWndShortcut()
        DisableWindow(#wnd, 1)
        
      Case #menuBackupMod
        openWndMakeBackup(GetGadgetText(#lstMods))
        DisableWindow(#wnd, 1)
        
      Case #menuUnbackupMod
        DisableWindow(#wnd, 1)
        openWndUnbackupMod(GetGadgetText(#lstMods))
        
    EndSelect
    
    
  ElseIf Event = #PB_Event_CloseWindow
    eventWnd = EventWindow()
    If eventWnd = #wnd 
      ClosePreferences()
      CloseFile(0)
      End
    Else
      If eventWnd = #wndGetMod
        abortDownloading()
      ElseIf eventWnd = #wndUnbackupMod
        ClearList(Backups())  
      EndIf
      
      DisableWindow(#wnd, 0)
      CloseWindow(EventWindow())
    EndIf
    
  ElseIf Event = #PB_Event_SizeWindow
    If EventWindow() = #wndDescription
      ResizeGadget(#wbDescription,0,0, WindowWidth(#wndDescription), WindowHeight(#wndDescription))
    EndIf
  EndIf
  
ForEver
  
If activatedMod <> ""
  errors.i = deactivateMod(activatedMod)
  If errors > 0
   If cfgLanguage = ""
     temp.s = " errors have "
     If errors = 1 : temp = " error has " : EndIf
     MessageRequester("", Str(errors) + temp + "occured. See " + Chr(34) + "launcherDebug.txt" + Chr(34) + " for details", #MB_ICONERROR)
   Else
     MessageRequester("", ReplaceString(localMsgErrorsOccured, "%errors", Str(errors), #PB_String_NoCase), #MB_ICONERROR)
   EndIf
  EndIf
   
  ClosePreferences()
  CloseFile(0)
  End
EndIf
;}
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 7
; Folding = RgAwj-
; EnableXP
; UseIcon = kjefo84u.ico
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\launcher.exe
; CurrentDirectory = C:\Documents and Settings\vladgor\Рабочий стол\
; EnableCompileCount = 623
; EnableBuildCount = 243