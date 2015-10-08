; PureBasic 4.40 - Tailbite 1.4
; Droppy's Lib
; Version 1.32

;{- Declaration
Declare MakeSureDirectoryPathExists(Directory.s)
Declare Hex2Dec(HexNumber.s) 
Declare Timer(TimerId,Delay,ProcedureAdress, windowid)
Declare TimerKill(TimerId, windowid)
Declare Ansi2Uni(string.s)
Declare.s PidToFileName_internal(PID.i)
Declare.s Between_int(string.s, LString.s, RString.s) ;for internal purposes
;}
#SIZEOF_WORD = 2

;{- Common Structures

Structure LOCALGROUP_MEMBERS_INFO_3
  lgrmi3_domainandname.l
EndStructure

Structure LOCALGROUP_INFO_0
  *Nom
EndStructure

Structure MyLUID 
  LowPart.l 
  HighPart.l 
  Attributes.l 
EndStructure 
  
Structure MyTOKEN 
  PrivilegeCount.l 
  LowPart.l 
  HighPart.l 
  Attributes.l 
EndStructure 

;}

;{-Init Procedures Start
Procedure Droopy_Init()
  ;ImpersonateUser
  Global Status.l,Token.l,UsernameG.s,DomainG.s,PasswordG.s,ImpersonateUserRunAsHandle.l,ImpersonateUserRunAsId.l
  ;Log
  Global FichierLog.s
  ;Logoff
  Global hdlProcessHandle.l 
  Global hdlTokenHandle.l 
  Global tmpLuid.MyLUID 
  Global tkp.MyTOKEN 
  Global tkpNewButIgnored.MyTOKEN 
  Global lBufferNeeded.l 
  ;BackgroundTransfert
  Global BGTSource.s,BGTDestination.s,BGTTaillePaquets,BGTTempo,BGTFlag,BGTTailleDestination,BGTTailleSource
  ;Flag
  Global FlagKey.s
  ;MeasureInterval
  Global MeasureIntervalTime.l
  ;MeasureIntervalHiRes
  Global MeasureHiResIntervalTime.l
  ;BigString
  Global BigString_Base, BigString_BaseSize, BigString_OldExceptionHandler 
  ;MouseMove
  Global MousePositionX,MousePositionY
  ;Capture
  Global CaptureScreenWidth , CaptureScreenHeight , CaptureScreenBMPHandle
  ;PrinterEnum
  Global PrinterPort.s
EndProcedure

Procedure Droopy_End()
EndProcedure
;}-Init Procedures End

;{- Common Procedures

Procedure.l L(string.s) ; Convertit une Variable String en Pointeur vers Variable Unicode
  *out = AllocateMemory(Len(string)*2 * #SIZEOF_WORD) 
  MultiByteToWideChar_(#CP_ACP, 0, string, -1, *out, Len(string))  
  ProcedureReturn *out  
EndProcedure 

Procedure.s M(Pointeur) ; Convertit Pointeur Variable Structurée Unicode en Variable String Unicode
  Buffer.s=Space(512)
  WideCharToMultiByte_(#CP_ACP,0,Pointeur,-1,@Buffer,512,0,0)
  ProcedureReturn Buffer
EndProcedure

;}

;{- Common Constant

;{/ ExitWindowsEx
#TOKEN_ADJUST_PRIVILEGES = 32 
#TOKEN_QUERY = 8 
#SE_PRIVILEGE_ENABLED = 2 
#EWX_LOGOFF = 0 
#EWX_SHUTDOWN = 1 
#EWX_REBOOT = 2 
#EWX_FORCE = 4 
#EWX_POWEROFF = 8 
;}


;}


;  _____________________________________________________________________________
;  |                                                                           |
;  |                               Administrator                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Administrator (Start)                                         Librairie n° 1

;/ Deleted in version 1.1 ( replaced by IsUserAnAdmin())

;} Administrator (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Beep                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Beep (Start)                                                  Librairie n° 2
; PureBasic 3.92
; Generates simple tones on the speaker
; Frequency ( Hertz )
; Duration ( ms )


ProcedureDLL Beep(Frequency,Duration)
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x86;not supported in vista and or XP x64
    Beep_(Frequency,Duration)
  CompilerEndIf
EndProcedure

;/ Test
; Beep(500,100)
; Beep(1000,100)
; Beep(2000,100)
; Beep(4000,100)
; Beep(6000,100)
; Beep(8000,100)
; Beep(6000,100)
; Beep(4000,100)
; Beep(2000,100)
; Beep(1000,100)


;} Beep (End)

; BlockInput deleted in DroopyLib 1.28

;  _____________________________________________________________________________
;  |                                                                           |
;  |                              GetComputerName                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetComputerName (Start)                                       Librairie n° 4
; PureBasic 3.92
; Retrieves the NetBIOS name of the local computer

ProcedureDLL.s GetComputerName()
  taille.l=100
  ComputerName.s=Space(taille)
  GetComputerName_(@ComputerName,@taille)
  ProcedureReturn  ComputerName
EndProcedure

;/ Test
; MessageRequester("NetbiosName",GetComputerName())
  

;} GetComputerName (End)
;  _____________________________________________________________________________
;  |                                                                                                                                      |
;  |                            GetCurrentDirectory                            |
;  |                            ___________________                            |
;  |                            
;  |                               REMOVED FOR PB4
;  |___________________________________________________________________________|
;{ GetCurrentDirectory (Start)                                   Librairie n° 5
; PureBasic 3.92
; This function retrieves the current directory for the current process
; Eq : Path where the program was launched

; ProcedureDLL.s GetCurrentDirectory()
; Path.s=Space(500)
; retour=GetCurrentDirectory_(500,Path)
; If retour=0:Path="":EndIf
; If Path<>"" : Path+"\":EndIf ;/ V 1.1 Addon ( Gangsta93 Request )
; ProcedureReturn Path
; EndProcedure

;/ Test
; MessageRequester("Program run from",GetCurrentDirectory())

;} GetCurrentDirectory (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GetDiskFreeSpaceEx                             |
;  |                            __________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetDiskFreeSpaceEx (Start)                                    Librairie n° 6
; PureBasic 3.92
; Code by freak tweaked by Droopy
; Return avalaible Disk free space ( in Mo )
; Return 0 if Drive is not avalaible

ProcedureDLL GetDiskFreeSpaceEx(Drive.s)
  
  Structure union
    LowPart.l
    HighPart.l
  EndStructure
  
  lpFreeBytesAvailable.union
  lpTotalNumberOfBytes.union
  lpTotalNumberOfFreeBytes.union
   
  GetDiskFreeSpaceEx_(@Drive,@lpFreeBytesAvailable,@lpTotalNumberOfBytes,@lpTotalNumberOfFreeBytes)
  
  ; LowPart contient 32 Bits 
  ; On décale à droite de 20 bits ( il reste 12 bits significatifs )
  ; Attention le décalage recopie le bit de signe !
  ; 20 bits --> /1024/1024 --> Résultat en Mo !!!
  
  lpTotalNumberOfFreeBytes\LowPart>>20 
  
  ; On nettoie le bit de signe recopié avec un masque ( de 12 bits bien sur )
  lpTotalNumberOfFreeBytes\LowPart & $FFF
   
  ; On décale HighPart de 12 à gauche
  lpTotalNumberOfFreeBytes\HighPart <<12
  
  ; Et on fusionne le tout avec un OU 
  ; La taille est en Mo
  ProcedureReturn lpTotalNumberOfFreeBytes\LowPart | lpTotalNumberOfFreeBytes\HighPart
  
EndProcedure

;/ Test
; Drive.s="z:"
; FreeSpace=GetDiskFreeSpaceEx(Drive)
; 
; If FreeSpace
  ; MessageRequester("Free Space on "+Drive,Str(FreeSpace)+"Mb")
; Else
  ; MessageRequester(Drive,"Not avalaible or full !")
; EndIf

;} GetDiskFreeSpaceEx (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          GetEnvironmentVariable                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetEnvironmentVariable (Start)                                Librairie n° 7
; Web Code Tweaked ( for Librairie purpose ) 27/05/05
; PB 3.92 / 3.94 fix if Variable don't exist ( return 255 space ! )
; Retrieves the value of the specified variable from the environment block
; Exemple GetEnvironmentVariable("SystemRoot")

; ProcedureDLL.s GetEnvironmentVariable(Name.s)
;   Buffer.s = Space(255) 
;   If GetEnvironmentVariable_(Name, Buffer, 255)<>0
;     ProcedureReturn Buffer 
;   EndIf
; EndProcedure

;/ Test
; MessageRequester("Temp directory",GetEnvironmentVariable("Temp"))

;} GetEnvironmentVariable (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetFileAttributes                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetFileAttributes (Start)                                     Librairie n° 8
; PureBasic 3.92
; Retrieves attributes for a specified file or directory
; Return -1 if file does not exist
; Filter the result with #FILE_ATTRIBUTE_XXXXXX


; ProcedureDLL GetFileAttributes(FileName.s)
;   ProcedureReturn GetFileAttributes_(@FileName)
; EndProcedure

;/ Test
; File.s="C:\boot.ini"
; 
; FileAttributes=GetFileAttributes(File)
; 
; Z.s=""
; If FileAttributes & #FILE_ATTRIBUTE_ARCHIVE   : Z + "A" : EndIf
; If FileAttributes & #FILE_ATTRIBUTE_HIDDEN    : Z + "H" : EndIf
; If FileAttributes & #FILE_ATTRIBUTE_READONLY  : Z + "R" : EndIf
; If FileAttributes & #FILE_ATTRIBUTE_SYSTEM    : Z + "S" : EndIf
; 
; 
; MessageRequester(File,"Attributes = "+Z)



;} GetFileAttributes (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              GetProgramName                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetProgramName (Start)                                        Librairie n° 9
; PureBasic 3.92
; Droopy 28/04/05
; Return the Program Name

ProcedureDLL.s GetProgramName()
  ProgramName.s=Space(256)
  GetModuleFileName_(0,@ProgramName,255) 
  ProcedureReturn GetFilePart(ProgramName)
EndProcedure

;/ Test
; MessageRequester("ProgramName",GetProgramName())

;} GetProgramName (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GetSystemDirectory                             |
;  |                            __________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetSystemDirectory (Start)                                    Librairie n° 10
; This Function retrieves the path of the system directory

ProcedureDLL.s GetSystemDirectory()
  Path.s=Space(501)
  GetSystemDirectory_(@Path,500)
  ProcedureReturn Path
EndProcedure

;/ Test
; MessageRequester("System Directory",GetSystemDirectory())

;} GetSystemDirectory (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GetWindowsDirectory                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetWindowsDirectory (Start)                                   Librairie n° 11
; This Function retrieves the path of the Windows directory

ProcedureDLL.s GetWindowsDirectory()
  Path.s=Space(501)
  GetWindowsDirectory_(@Path,500)
  ProcedureReturn Path
EndProcedure

;/ Test
; MessageRequester("Windows Directory",GetWindowsDirectory())

;} GetWindowsDirectory (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              ImpersonateUser                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ImpersonateUser (Start)                                       Librairie n° 12
; PureBasic 3.92
; Idea from wichtel / Droopy 17/04/05
; Caution : ImpersonateUser may disconnect network map drives while enabled
; Fail when password is blank !

;/ Need Procedure.l L(string.s) procedure !!

ProcedureDLL ImpersonateUser(Username.s,Domain.s,Password.s)
  
  ; Return 1 if the function succeed or 0 if the function fail
  
  
  
  UsernameG.s=Username.s
  DomainG.s=Domain.s
  PasswordG.s=Password.s
  
  ;/ On personifie l'utilisateur
  Ret1= LogonUser_(Username,Domain,Password,2,0,@Token) 
  Ret2= ImpersonateLoggedOnUser_(Token)
  
  If Ret1=0 Or Ret2=0
    Status=0
  Else
    Status=1
  EndIf
  
  ProcedureReturn Status
  
EndProcedure

ProcedureDLL ImpersonateUserDisable()
  
  ; Disable the impersonateUser
  
  Status=0
  RevertToSelf_() 
  CloseHandle_(Token) 
 
EndProcedure

ProcedureDLL ImpersonateUserState()
  ; Return 1 if ImperonateUser is enabled or 0 if not
  ProcedureReturn Status
EndProcedure

;For ImpersonateUserRunasHidden
Prototype.l CreateProcessWithLogonW(lpUsername.p-unicode, lpDomain.p-unicode, lpPassword.p-unicode, dwLogonFlags,lpApplicationName.p-unicode, lpCommandLine.p-unicode,dwCreationFlags, lpEnvironment, lpCurrentDirectory,  *lpStartupInfo.STARTUPINFO,*lpProcessInfo.PROCESS_INFORMATION)

; Import "advapi32lex.lib"
; CreateProcessWithLogon(lpUsername.p-unicode, lpDomain.p-unicode, lpPassword.p-unicode, dwLogonFlags,lpApplicationName.p-unicode, lpCommandLine.p-unicode,dwCreationFlags, lpEnvironment, lpCurrentDirectory,  *lpStartupInfo.STARTUPINFO,*lpProcessInfo.PROCESS_INFORMATION) As "_CreateProcessWithLogonW"
; EndImport

Procedure ImpersonateUserRunasHidden(CommandLine.s,Argument.s)
  
  ; Wichtel modifié par Droopy ( n'exécutait pas d'argument de l'exe )
  ; 16/02/05 /  ; PB 3.92
  ; Execute Runas avec paramètre
  ; renvoie 0 si : commande inexistante / username ou Password incorrect
  ; Renvoie 1 si tout s'est bien passé
  ; 17/04/05 : Modif via L() -> plus simple / Ajout dans la Lib ImpersonateUser
  ; Runas ne peut être lancé en mode Impersonate actif ( on désactive avant !! )
  ; 1.31.2: added compilerif's to try and make better with unicode
  ; 1.31.3 (10/11/06): was giving invalid memory access errors, declared prototype to make it work in unicode and ascii modes
  ; 1.31.3 - (PB4.01 version) moved globals out of procedure (also done on some other functions)
  ;1.31.4 - may need full path to exe
  
  
  lpProcessInfo.PROCESS_INFORMATION
  lpStartUpInfo.STARTUPINFO
  
  ; Ajoute un espace au début de l'argument
  If Left(Argument,1)<>" " 
    Argument=" "+Argument
  EndIf
  
  retour=0
  
  advapi.i = OpenLibrary(#PB_Any, "ADVAPI32.DLL")
  If advapi
    CreateProcessWithLogon.CreateProcessWithLogonW = GetFunction(advapi, "CreateProcessWithLogonW")    
    If CreateProcessWithLogon(UsernameG, DomainG, PasswordG, 0,CommandLine,Argument,0,0,#Null,@lpStartUpInfo,@lpProcessInfo) <> 0
      retour=1
    EndIf
    CloseLibrary(advapi)
  EndIf
  
  ;/ Set the Process Handle of the Run Program in ImpersonateUserRunAsHandle (Global)
  ImpersonateUserRunAsHandle= lpProcessInfo\hProcess
  ;/ Set the Process id of the Run Program in ImpersonateUserRunAsHandle (Global)
  ImpersonateUserRunAsId.l= lpProcessInfo\dwProcessId
  
  ProcedureReturn retour
  
EndProcedure

ProcedureDLL ImpersonateUserRunAsGetProcessHandle() ; Handle to the newly created process
  ProcedureReturn ImpersonateUserRunAsHandle
EndProcedure

ProcedureDLL ImpersonateUserRunAsGetProcessId() ; Value that can be used To identify a Process
  ProcedureReturn ImpersonateUserRunAsId
EndProcedure

ProcedureDLL ImpersonateUserRunAsGetErrorLevel(Delay.l) ; Wait until process end and return ErrorLevel
  Repeat
    Delay(Delay)
    If PidToFileName_Internal(ImpersonateUserRunAsId.l)="" : Break : EndIf
  ForEver
  GetExitCodeProcess_(ImpersonateUserRunAsHandle,@ExitCode.l)
  ProcedureReturn ExitCode
EndProcedure

ProcedureDLL ImpersonateUserRunas(CommandLine.s,Argument.s)
  
  ; Disable ImpersonateUser if enabled because Runas fail if enabled
  ; Run ImpersonateUser if was previously enabled
  
  If ImpersonateUserState()=1
    ImpersonateUserDisable()
    retour=ImpersonateUserRunasHidden(CommandLine.s,Argument.s)
    ImpersonateUser(UsernameG,DomainG,PasswordG)
  EndIf
  
  ProcedureReturn retour
EndProcedure

;/ ErrorLevel Test
; If ImpersonateUser("admin",".","admin") 
  ; Debug "Impersonalisation Success" 
; EndIf
; 
; If ImpersonateUserRunas("d:\end55.exe","") 
  ; Debug "Success Launching END55.EXE"
; EndIf
; 
; Debug ImpersonateUserRunAsGetProcessHandle()
; Debug ImpersonateUserRunAsGetProcessId()
; Debug ImpersonateUserRunAsGetErrorLevel(10)

;/ Test ( you need a user called Bill with password "Password" )

; ImpersonateUser("bill",".","password")
; 
; If ImpersonateUserState()
  ; MessageRequester("Impersonalization","Successfull"+#CRLF$+#CRLF$+"Look at Task Manager to see who launched Notepad !")
  ; ImpersonateUserRunas("Notepad.exe","")
; Else
  ; MessageRequester("Impersonalization","Fail")
; EndIf
; 
; ImpersonateUserDisable()





;} ImpersonateUser (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    Ini                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Ini (Start)                                                   Librairie n° 13
; Droopy 29/04/05
; PureBasic 3.92
; Read / Write INI files

ProcedureDLL IniWrite(INIFile.s,Section.s,Key.s,string.s)
  retour=WritePrivateProfileString_(@Section,@Key,@string,@INIFile)
  If retour<>0 : retour=1:EndIf
  ProcedureReturn retour
EndProcedure

ProcedureDLL.s IniRead(INIFile.s,Section.s,Key.s)
  retour.s=Space(512)
  vide.s
GetPrivateProfileString_(@Section,@Key,@vide,@retour,512,@INIFile)
  ProcedureReturn retour
EndProcedure

;/ Test
; 
; IniWrite("c:\test.ini","section1","Key1Section1","data_Key1Section1")
; IniWrite("c:\test.ini","section1","Key2Section1","data_Key2Section1")
; IniWrite("c:\test.ini","section2","Key1Section2","data_Key1Section2")
; 
; IniRead("c:\test.ini","section1","Key1Section1")
; IniRead("c:\test.ini","section1","Key2Section1")
; IniRead("c:\test.ini","section2","Key1Section2")


;} Ini (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    Log                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Log (Start)                                                   Librairie n° 14
; Droopy 21/02/04
; PureBasic v3.92

; Create & Write Log file

; LogInit(LogFile.s) : Create the LogFile
; ------------------
; If path does not exist, the path is created
; Return 1 if success / 0 if fail

; LogWriteString(Text.s) : Append Text + Date & Time to the log file
; ----------------
; The log file is closed after each write / Because PureBasic cannot open files not closed

;/ Need MakeSureDirectoryPathExists(Directory.s) procedure !!
; 1.31.15: made to use #PB_Any for files.

ProcedureDLL LogInit(LogFile.s)
  FichierLog=LogFile
  a=0
  If MakeSureDirectoryPathExists(GetPathPart(FichierLog))
    a=OpenFile(#PB_Any,FichierLog)
    If a : CloseFile(a) : EndIf
  EndIf
  
  If a<>0 : a=1 : EndIf
  ProcedureReturn a
EndProcedure

ProcedureDLL LogWriteString(Text.s) 
  file = OpenFile(#PB_Any,FichierLog)
  If file
    FileSeek(file, Lof(file))
    WriteStringN(file, FormatDate("%dd/%mm/%yy %hh:%ii:%ss",Date())+" "+Text)
    CloseFile(file)
  EndIf
EndProcedure
  

  
;/ Test
; If LogInit("c:\22\33\55\fichier.log")
  ; LogWriteString("Line 1")
  ; LogWriteString("Line 2")
  ; LogWriteString("Line 3")
; Else
  ; MessageRequester("Log","Error creating Log file")
; EndIf


;} Log (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  Logoff                                   |
;  |                                  ______                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Logoff (Start)                                                Librairie n° 15
; PureBasic 3.92
; BackupUser 19/06/02
; Forced Logoff

ProcedureDLL Logoff() 
 
  ;/ Need ExitWindowsEx Constants

  ;/ Need Structure MyLUID & MyTOKEN  
  
 
  hdlProcessHandle = GetCurrentProcess_() 
  OpenProcessToken_(hdlProcessHandle, #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @hdlTokenHandle) 
  SysName.s=""+Chr(0) 
  Name.s="SeShutdownPrivilege"+Chr(0) 
  Erg.l=LookupPrivilegeValue_(SysName, Name, @tmpLuid) 
  tmpLuid\Attributes = #SE_PRIVILEGE_ENABLED 
  tkp\PrivilegeCount = 1  
  tkp\LowPart = tmpLuid\LowPart 
  tkp\HighPart = tmpLuid\HighPart 
  tkp\Attributes = tmpLuid\Attributes 
  Erg.l = AdjustTokenPrivileges_(hdlTokenHandle,0,@tkp,SizeOf(MyTOKEN),@tkpNewButIgnored,@lBufferNeeded) 
  Erg.l = ExitWindowsEx_((#EWX_LOGOFF | #EWX_FORCE), 0) 
EndProcedure 

;} Logoff (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                        MakeSureDirectoryPathExists                        |
;  |                        ___________________________                        |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MakeSureDirectoryPathExists (Start)                           Librairie n° 16
; PureBasic 3.92
; Create Directory with subdirectory
; Because CreateDirectory doesn't work when SubFolder doesn't exist
; Droopy 26/04/05

Import "shell32.lib"
SHCreateDirectory(*hwnd, pszPath.p-unicode)
EndImport

ProcedureDLL MakeSureDirectoryPathExists(Directory.s)
  
  ; Return 1 If success / 0 If fail 
  
  ;CompilerIf #PB_Compiler_Unicode = 0
    retour = SHCreateDirectory(#Null, directory)
  ;CompilerElse
  ;  retour = SHCreateDirectory_(#Null, directory)
  ;CompilerEndIf
;   If retour = #ERROR_SUCCESS
;     retour = 1
;   Else
;     retour = 0
;   EndIf
 ; ProcedureReturn retour

EndProcedure

;/ Test
; Debug MakeSureDirectoryPathExists("c:\1\2\3\4\5\6")



;} MakeSureDirectoryPathExists (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             NetLocalGroupAdd                              |
;  |                             ________________                              |
;  |                                                                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupAdd (Start)                                      Librairie n° 17

; PureBasic 3.92
; Droopy Avril 2005

;/ Need Procedure.l L(string.s) procedure !!

;/ Need LOCALGROUP_INFO_0 Structure


ProcedureDLL NetLocalGroupAdd(GroupName.s)
  
  ; Renvoie 1 si groupe créé / 0 si erreur de création
  
  buf.LOCALGROUP_INFO_0
  ;CompilerIf #PB_Compiler_Unicode
  ;  buf\Nom=@GroupName
  ;CompilerElse
  ;  buf\Nom=L(GroupName)
  ;CompilerEndIf
  
  parm_err.i
  If NetLocalGroupAdd_(0,0,buf,@parm_err)=0
    retour=1
  Else
    retour=0
  EndIf
  
  ProcedureReturn retour
  
EndProcedure

;/ Test
; Debug NetLocalGroupAdd("test")

;} NetLocalGroupAdd (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          NetLocalGroupAddMembers                          |
;  |                          _______________________                          |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupAddMembers (Start)                               Librairie n° 18
; PureBasic 3.92
; Droopy 19/04/05
; Add Account to LocalGroup

;/ Need Procedure.l L(string.s) procedure !! 

;/ Need LOCALGROUP_MEMBERS_INFO_3 Structure !!

Prototype NetLocalGroupAddMembersproto(servername.p-unicode,	LocalGroupName.p-unicode,	level.l,	*buf,	membercount.l)

ProcedureDLL NetLocalGroupAddMembers(GroupName.s,AccountName.s)
  
  ; Add AccountName to GroupName ( LocalGroup )
  ; Return 1 if success / 0 if error
  
  user.LOCALGROUP_MEMBERS_INFO_3
  CompilerIf #PB_Unicode = 0
    user\lgrmi3_domainandname=L(AccountName)
  CompilerElse
    user\lgrmi3_domainandname=@AccountName
  CompilerEndIf
  
  netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
  ;Retour=CallFunction(netapi,"NetLocalGroupAddMembers",0,L(GroupName),3,user,1)
  my_NetLocalGroupAddMembers.NetLocalGroupAddMembersproto = GetFunction(netapi, "NetLocalGroupAddMembers")
  Retour = my_NetLocalGroupAddMembers("",GroupName,3,user,1)
  CloseLibrary(netapi)
  If Retour=0 : Retour=1: Else : Retour=0 : EndIf
  ProcedureReturn Retour
EndProcedure

; Test
; Debug NetLocalGroupAddMembers("administrateurs","toto")



;} NetLocalGroupAddMembers (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             NetLocalGroupDel                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupDel (Start)                                      Librairie n° 19
; PureBasic 3.92
; Droopy Avril 2005

;/ Need Procedure.l L(string.s) procedure !!

ProcedureDLL NetLocalGroupDel(GroupName.s)

  ; Renvoie 1 si suppression a réussi / 0 si echec de suppression
  
  If NetLocalGroupDel_(0,GroupName)=0
    retour=1
  Else
    retour=0
  EndIf
  
  ProcedureReturn retour
  
EndProcedure

;/ Test
; Debug NetLocalGroupDel("test")

;} NetLocalGroupDel (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          NetLocalGroupDelMembers                          |
;  |                          _______________________                          |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupDelMembers (Start)                               Librairie n° 20
; PureBasic 3.92
; Droopy 19/04/05
; Remove Account from LocalGroup

;/ Need Procedure.l L(string.s) procedure !!

;/ Need LOCALGROUP_MEMBERS_INFO_3 Structure !!
Prototype NetLocalGroupDelMembersproto(*servername, groupname.p-unicode, level.l, *buf, totalentries.l)

ProcedureDLL NetLocalGroupDelMembers(GroupName.s,AccountName.s)
  
  ; Remove an AccountName from a GroupName
  ; Return 1 if success / 0 if error
  
  user.LOCALGROUP_MEMBERS_INFO_3
  CompilerIf #PB_Unicode = 0
    user\lgrmi3_domainandname=L(AccountName)
  CompilerElse
    user\lgrmi3_domainandname=@AccountName
  CompilerEndIf
  
  netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
  ;retour=CallFunction(netapi,"NetLocalGroupDelMembers",0,L(GroupName),3,user,1)
  my_NetLocalGroupDelMembers.NetLocalGroupDelMembersproto = GetFunction(netapi, "NetLocalGroupDelMembers")
  retour=my_NetLocalGroupDelMembers(0, GroupName, 3, user, 1)
  CloseLibrary(netapi)
  If retour=0 : retour=1: Else : retour=0 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test
; Debug NetLocalGroupDelMembers("administrateurs","toto")



;} NetLocalGroupDelMembers (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             NetLocalGroupEnum                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupEnum (Start)                                     Librairie n° 21
; Renvoie la liste des groupes ( groupe par groupe )
; quand plus de groupe -> renvoie chaine vide
; Si on continue reliste les groupes

;/ Need LOCALGROUP_INFO_0 Structure

;/ Need Procedure.s M(Pointeur) !!

ProcedureDLL.s NetLocalGroupEnum()
  Static Flag,Ptr.i,totalentries.l,PtrOriginal.i
  
If Flag=0 ; on n'a jamais lancé la commande 
  *groupe.LOCALGROUP_INFO_0
  Ptr.i=0
  entriesread.l =0
  totalentries.l =0
  resumehandle.i=0
  retour=NetLocalGroupEnum_(#NUL,0,@Ptr,-1,@entriesread,@totalentries,@resumehandle)
  PtrOriginal=Ptr
EndIf
    *groupe=Ptr  
    CompilerIf #PB_Compiler_Unicode = 0
      Output.s=M(*groupe\Nom)
    CompilerElse
      output.s = PeekS(*groupe\Nom)
    CompilerEndIf
    Ptr+SizeOf(LOCALGROUP_INFO_0)
    Flag+1

    If Flag>totalentries 
      Flag=0 
      Output=""
      NetApiBufferFree_(PtrOriginal) ;  Libération du Buffer
    EndIf
    
    ProcedureReturn Output
EndProcedure
  
  ;/ Test
  ; Repeat
    ; LocalGroupName.s=NetLocalGroupEnum()
    ; If LocalGroupName="" : Break : EndIf
    ; LocalGroupList.s+LocalGroupName+#CRLF$
  ; ForEver
  ; 
  ; MessageRequester("LocalGroup list",LocalGroupList)


;} NetLocalGroupEnum (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          NetLocalGroupGetMembers                          |
;  |                          _______________________                          |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetLocalGroupGetMembers (Start)                               Librairie n° 22
; Renvoie la liste des membres d'un groupes 
; quand fin de liste -> renvoie chaine vide
; Si on continue reliste les membres d'un groupes 


Structure LOCALGROUP_MEMBERS_INFO_1
  *lgrmi1_sid
  lgrmi1_sidusage.l
  *lgrmi1_name
EndStructure

;/ Need Procedure.s M(Pointeur) !!

; Need function Ansi2Uni(ansi.s)

ProcedureDLL.s NetLocalGroupGetMembers(groupe.s)

Static Flag,Ptr,totalentries.l,PtrOriginal,retour

If Flag=0
  *User.LOCALGROUP_MEMBERS_INFO_1
  Ptr.i=0
  entriesread.l=0
  totalentries.l=0
  resumehandle.i=0
  
  ;netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
  NetLocalGroupGetMembers_(0,groupe,1,@Ptr,-1,@entriesread,@totalentries,@resumehandle)
  ;CloseLibrary(netapi)
  PtrOriginal=Ptr
EndIf

If retour=0 And totalentries>0 ;  Traiter si Nom groupe correcte / Il contient des utilisateurs
  *User=Ptr
  CompilerIf #PB_Compiler_Unicode = 0
    Output.s=M(*User\lgrmi1_name)
  CompilerElse
    output.s = PeekS(*User\lgrmi1_name)
  CompilerEndIf
  Ptr+SizeOf(LOCALGROUP_MEMBERS_INFO_1)
  Flag+1
  
  If Flag>totalentries
    Flag=0
    Output=""
    ;netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
    ;CallFunction(netapi,"NetApiBufferFree",PtrOriginal)
    NetApiBufferFree_(PtrOriginal)
    ;CloseLibrary(netapi)
  EndIf
  
  ProcedureReturn Output  
EndIf

EndProcedure

;/ Test
; Repeat
  ; Username.s=NetLocalGroupGetMembers("administrateurs")
  ; If Username="" : Break : EndIf
  ; UsernameList.s+Username+#CRLF$
; ForEver
  ; 
; MessageRequester("Members of the Administrator Group",UsernameList)



;} NetLocalGroupGetMembers (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           NetUserChangePassword                           |
;  |                           _____________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetUserChangePassword (Start)                                 Librairie n° 23
; Purebasic 3.92
; 17/04/05
; Change user's password
; pas la peine d'être admin car on connait le compte / password initial !!

;/ Need Procedure.l L(string.s) procedure !!
Prototype NetUserChangePasswordproto(Domain.p-unicode,Username.p-unicode,OldPassword.p-unicode,NewPassword.p-unicode) 

ProcedureDLL NetUserChangePassword(Username.s,Domain.s,OldPassword.s,NewPassword.s)

  ; Return 1 (Success) or 0 (Fail)

netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
;retour= CallFunction(netapi,"NetUserChangePassword",L(Domain),L(Username),L(OldPassword),L(NewPassword)) 
my_NetUserChangePassword.NetUserChangePasswordproto = GetFunction(netapi, "NetUserChangePassword")
my_NetUserChangePassword(Domain, Username, OldPassword, Newpassword)
CloseLibrary(netapi)

If retour=0
  retour=1
Else
  retour=0
EndIf

ProcedureReturn retour
EndProcedure

;/ Test library
; Debug NetUserChangePassword("admin",".","titi","passe")

;} NetUserChangePassword (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                NetUserEnum                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetUserEnum (Start)                                           Librairie n° 24
; Renvoie la liste des utilisateurs ( groupe par groupe )
; quand plus de utilisateurs  -> renvoie chaine vide
; Si on continue reliste les utilisateurs

Structure USER_INFO_0
  Nom.l
EndStructure

;/ Need Procedure.s M(Pointeur) !!

ProcedureDLL.s NetUserEnum() ; Wrap Fixed
  
  Static Flag,Ptr.i,totalentries.l,PtrOriginal ; Les variables sont mémorisées même quand on rapelle la procédure
  
  If Flag=0 ; Si jamais lancé / dépassé on initialise
    *Utilisateur.USER_INFO_0
    Ptr=0
    entriesread.l=0
    totalentries=0
    resumehandle.i=0
    
    ;netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
    ;GetFunction(netapi,"NetUserEnum")
    ;CallFunction(netapi,"NetUserEnum",0,0,0,@Ptr,-1,@entriesread,@totalentries,@resumehandle)
    NetUserEnum_(0,0,0,@Ptr,-1,@entriesread,@totalentries,@resumehandle)
    ;CloseLibrary(netapi)
    PtrOriginal=Ptr
  EndIf
  
  *Utilisateur=Ptr  
  CompilerIf #PB_Compiler_Unicode = 0
    Output.s=M(*Utilisateur\Nom)
  CompilerElse
    output.s = PeekS(*Utilisateur\Nom)
  CompilerEndIf
  
  Ptr+SizeOf(USER_INFO_0)
  Flag+1
  
  If Flag>totalentries
    Flag=0
    Output=""
    ;netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
    ;CallFunction(netapi,"NetApiBufferFree",PtrOriginal)
    NetApiBufferFree_(PtrOriginal)
    ;CloseLibrary(netapi)
  EndIf
  
  ProcedureReturn Output
  
EndProcedure

;/ Test
; Repeat
  ; Username.s=NetUserEnum()
  ; If Username="" : Break : EndIf
  ; UsernameList.s+Username+#CRLF$
; ForEver
  ; 
; MessageRequester("UserName list",UsernameList)

;} NetUserEnum (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    Not                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Not (Start)                                                   Librairie n° 25
; PureBasic 3.92
; Droopy
; 22/02/05

; Just the Boolean Not Function
; if 0  (#False) --> 1 (#True)
; if <>0 (#True) --> 0 (#False)

ProcedureDLL Bool_Not(Boolean)
  If Boolean=0
    Boolean=1
  Else
    Boolean=0
  EndIf
  ProcedureReturn Boolean
EndProcedure

;/ Test
; Debug Not(0)
; Debug Not(1)


;} Not (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               OSVersionText                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ OSVersionText (Start)                                         Librairie n° 26
; Droopy 24/02/05
; PureBasic 3.92
; Return OsVersion in Text Format

; ProcedureDLL.s OSVersionText()
; Select  OSVersion()
;   Case #PB_OS_Windows_NT3_51 
;     retour.s="Windows NT 3.51"
;   Case #PB_OS_Windows_95 
;     retour.s="Windows 95"
;   Case #PB_OS_Windows_NT_4 
;     retour.s="Windows NT4"
;   Case #PB_OS_Windows_98 
;     retour.s="Windows 98"
;   Case #PB_OS_Windows_ME 
;     retour.s="Windows Me"
;   Case #PB_OS_Windows_2000 
;     retour.s="Windows 2000"
;   Case #PB_OS_Windows_XP 
;     retour.s="Windows XP"
;   Case #PB_OS_Windows_Vista
;     retour.s="Windows Vista"
;   Case #PB_OS_Windows_Server_2008
;     retour.s="Windows Server 2008"
;   Case #PB_OS_Windows_Future
;     retour.s="Unknown"
; EndSelect
; ProcedureReturn retour
; EndProcedure

ProcedureDLL.s MyOSVersion()
  Result.s = "Windows Unknown"
 
  osvi.OSVERSIONINFO
  osvi\dwOsVersionInfoSize = SizeOf(OSVERSIONINFO)
  If GetVersionEx_(@osvi)
    Select osvi\dwPlatformId
     
      Case 1
       
        If osvi\dwMajorVersion = 4
          Select osvi\dwMinorVersion
            Case 0
              Result = "Windows 95"
            Case 10
              Result = "Windows 98"
            Case 90
              Result = "Windows ME"
          EndSelect
        EndIf
       
      Case 2
       
        osviex.OSVERSIONINFOEX
        osviex\dwOsVersionInfoSize = SizeOf(OSVERSIONINFOEX)
        If GetVersionEx_(@osviex)
          Select osviex\dwMajorVersion
           
            Case 3
              Result = "Windows NT3"
            Case 4
              Result = "Windows NT4"
            Case 5
              Select osviex\dwMinorVersion
                Case 0
                  Result = "Windows 2000"
                Case 1
                  Result = "Windows XP"
                Case 2
                  If osviex\wProductType = 1
                    Result = "Windows XP x64"; 64Bit
                  Else
                    Result = "Windows Server 2003"
                  EndIf
              EndSelect
            Case 6
              Select osviex\dwMinorVersion
                Case 0
                  If osviex\wProductType = 1
                    Result = "Windows Vista"
                  Else
                    Result = "Windows Server 2008"
                  EndIf
                Case 1
                  If osviex\wProductType = 1
                    Result = "Windows 7"
                  Else
                    Result = "Windows Server 2008 R2"; R2
                  EndIf
              EndSelect
             
          EndSelect
        EndIf
       
    EndSelect
  EndIf
 
  ProcedureReturn Result
EndProcedure 


;/ Test
; MessageRequester("OS Version",OSVersionText())

;} OSVersionText (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  Reboot                                   |
;  |                                  ______                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Reboot (Start)                                                Librairie n° 27
; PureBasic 3.92
; BackupUser 19/06/02
; Forced Reboot

ProcedureDLL Reboot() 

;/ Need ExitWindowsEx Constants
  
;/ Need Structure MyLUID & MyTOKEN  
  

  Global hdlProcessHandle.l 
  Global hdlTokenHandle.l 
  Global tmpLuid.MyLUID 
  Global tkp.MyTOKEN 
  Global tkpNewButIgnored.MyTOKEN 
  Global lBufferNeeded.l 
  hdlProcessHandle = GetCurrentProcess_() 
  OpenProcessToken_(hdlProcessHandle, #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @hdlTokenHandle) 
  SysName.s=""+Chr(0) 
  Name.s="SeShutdownPrivilege"+Chr(0) 
  Erg.l=LookupPrivilegeValue_(SysName, Name, @tmpLuid) 
  tmpLuid\Attributes = #SE_PRIVILEGE_ENABLED 
  tkp\PrivilegeCount = 1  
  tkp\LowPart = tmpLuid\LowPart 
  tkp\HighPart = tmpLuid\HighPart 
  tkp\Attributes = tmpLuid\Attributes 
  Erg.l = AdjustTokenPrivileges_(hdlTokenHandle,0,@tkp,SizeOf(MyTOKEN),@tkpNewButIgnored,@lBufferNeeded) 
  Erg.l = ExitWindowsEx_((#EWX_REBOOT | #EWX_FORCE), 0) 
EndProcedure 



;} Reboot (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Runas                                   |
;  |                                   _____                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Runas (Start)                                                 Librairie n° 28
; BackupUser tweaked by Droopy ( add argument ) 16/02/05
; PureBasic 3.92
; Runas function with Parameters / Password 
; Return 0 if : Command don't exist / incorrect Username or Password
; Return 1 if success

;/ Need Procedure.l L(string.s)

ProcedureDLL Runas(Username.s,Domain.s,Password.s,CommandLine.s,Argument.s)
 
  lpProcessInfo.PROCESS_INFORMATION
  lpStartUpInfo.STARTUPINFO
  
  ; Ajoute un espace au début de l'argument
  If Left(Argument,1)<>" " 
    Argument=" "+Argument
  EndIf
  
  Retour=0
  
  advapi = OpenLibrary(#PB_Any,"ADVAPI32.DLL")
  If advapi
    CreateProcessWithLogon.CreateProcessWithLogonW = GetFunction(advapi, "CreateProcessWithLogonW");from impersonateuser functions
    If CreateProcessWithLogon(Username, Domain, Password, 0, CommandLine,Argument,0,0,0,@lpStartUpInfo,@lpProcessInfo)<>0
      Retour=1
    EndIf
  CloseLibrary(advapi)
  EndIf

  ProcedureReturn Retour
    
EndProcedure

;/ Test
; Runas("toto",".","passe","notepad.exe","")

;} Runas (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                SearchFiles                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SearchFiles (Start)                                           Librairie n° 29
; PureBasic 3.92
; Code from BackupUser 21/04/02
; Modified by Droopy 27/04/05

; Recurse = 1 : Scan SubDirectories of Path
; Recurse = 0 : Don't scan Subdirectories of Path

Declare SearchDirectory(Path.s,Mask.s)
Declare SearchFiles(Path.s,Mask.s)

ProcedureDLL SearchFilesInit(Path.s,Mask.s,Recurse.l) 
  
  ;/ erreur dans précédente version ( recurse non prise en compte )
  ;/ corrigé dans la Droopy Lib 1.28
  
  
  ; Create or Clear the LinkedList
  Static Flag.l
  If Flag=0
    Global NewList Fichiers.s()
    Flag=1
  Else
    ClearList(Fichiers())
  EndIf
  
  SearchFiles(Path,Mask) ; Car le répertoire lui même n'est pas scanné sinon
  If Recurse
    SearchDirectory(Path,Mask)
  EndIf
  
  ProcedureReturn ListSize(Fichiers()) ; number of files found
EndProcedure

Procedure SearchFiles(Path.s,Mask.s)
  
  ;  Fill the LinkedList with the files found
  
  ; Add \ to Path if missing
  If Right(Path,1)<>"\" : Path+"\":EndIf
  
  ; Apply Structure
  lpFindFileData.WIN32_FIND_DATA
  
  ; Add Filter *.*
  Recherche.s=Path+Mask
  
  ; Initiate the Search
  handle.i = FindFirstFile_(Recherche, @lpFindFileData)
  
  ; If search succeeds
  If handle <> #INVALID_HANDLE_VALUE
    
    Repeat
      
      ; Trouve = File or Directory Found
      Trouve.s=PeekS(@lpFindFileData\cFileName)
      
      ; This is a not a directory
      If lpFindFileData\dwFileAttributes & #FILE_ATTRIBUTE_DIRECTORY =#False
        
          ; Display File found
          AddElement(Fichiers.s())
          Fichiers()=Path+Trouve
          ;Debug "--> "+Path+Trouve
          
      EndIf
      
      ; Exit when there is no more files
    Until FindNextFile_(handle, @lpFindFileData)= #False
    
    ; Close the Api search Function
    FindClose_(handle)
    
  EndIf
  
  
EndProcedure
  
Procedure SearchDirectory(Path.s,Mask.s)
  
  ;  Search SubDirectory of Path
  
  ; Add \ to Path if missing
  If Right(Path,1)<>"\" : Path+"\":EndIf
  
; Apply Structure
  lpFindFileData.WIN32_FIND_DATA

; Add Filter *.*
Recherche.s=Path+"*.*"

; Initiate the Search
handle.l = FindFirstFile_(Recherche, @lpFindFileData)

; If search succeeds
If handle <> #INVALID_HANDLE_VALUE

  Repeat
    
    ; Trouve = File or Directory Found
    Trouve.s=PeekS(@lpFindFileData\cFileName)
    
    ; This is a directory
    If lpFindFileData\dwFileAttributes & #FILE_ATTRIBUTE_DIRECTORY
      
      ; And not the . or .. directory
      If Trouve <>"." And Trouve <>".."
        
        ; Call the function itself ( Recursive ) to search in another Directory
        SearchDirectory(Path+Trouve,Mask)
        
        ; Directory found : Search file within this Directory
        SearchFiles(Path+Trouve,Mask)
      
      EndIf

    EndIf
    
  ; Exit when there is no more files
  Until FindNextFile_(handle, @lpFindFileData)= #False
  
  ; Close the Api search Function
  FindClose_(handle)
  
EndIf

EndProcedure

ProcedureDLL.s SearchFilesGet()
  
  ;  Return files found, return empty string if there is no more files
  
  ; 
  Static Pointeur
   
  If Pointeur >= ListSize(Fichiers())
    Pointeur=0
  Else
    SelectElement(Fichiers(),Pointeur)
    Retour.s=Fichiers()
    Pointeur+1
  EndIf
  
  ProcedureReturn Retour.s
EndProcedure

;/ Test

; NbFiles=SearchFilesInit(GetSystemDirectory(),"*.txt")
; 
; Text.s=Str(NbFiles)+" files found"+#CRLF$+#CRLF$
; 
; Repeat
  ; File.s=SearchFilesGet()
  ; If File="" : Break : EndIf
  ; Text + File + #CRLF$
; ForEver
; 
; MessageRequester("*.TXT in SystemDirectory",Text)







;} SearchFiles (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               SearchProcess                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SearchProcess (Start)                                         Librairie n° 30
; Search a Process ( ex MTXAGENT.EXE : Function not case sensitive ) 
; Work under Windows NT / 9x / XP
; Fred code tweaked by Droopy
; PureBasic 3.92
; Return 1 if process found / 0 if not found

Structure PROCESSENTRY33 
  dwSize.l 
  cntUsage.l 
  th32ProcessID.l 
  th32DefaultHeapID.l 
  th32ModuleID.l 
  cntThreads.l 
  th32ParentProcessID.l 
  pcPriClassBase.l 
  dwFlags.l 
  szExeFile.b[#MAX_PATH] 
EndStructure 

#TH32CS_SNAPPROCESS = $2 

ProcedureDLL SearchProcess(Name.s) 
  Name.s=UCase(Name.s)
  Recherche=0
  kernel = OpenLibrary(#PB_Any, "Kernel32.dll") 
  If kernel
    
    CreateToolhelpSnapshot = GetFunction(kernel, "CreateToolhelp32Snapshot") 
    ProcessFirst           = GetFunction(kernel, "Process32First") 
    ProcessNext            = GetFunction(kernel, "Process32Next") 
    
    If CreateToolhelpSnapshot And ProcessFirst And ProcessNext ; Ensure than all the functions are found 
      
      Process.PROCESSENTRY33\dwSize = SizeOf(PROCESSENTRY33) 
      
      Snapshot = CallFunctionFast(CreateToolhelpSnapshot, #TH32CS_SNAPPROCESS, 0) 
      If Snapshot 
        
        ProcessFound = CallFunctionFast(ProcessFirst, Snapshot, Process) 
        While ProcessFound 
          Nom.s=UCase(PeekS(@Process\szExeFile, -1, #PB_Ascii))
          Nom=GetFilePart(Nom)
          If Nom=Name : Recherche =1 : EndIf
          ProcessFound = CallFunctionFast(ProcessNext, Snapshot, Process) 
        Wend 
      EndIf 
      
      CloseHandle_(Snapshot) 
    EndIf 
    
    CloseLibrary(kernel) 
  EndIf 
  
  ProcedureReturn Recherche
EndProcedure 

;  _____________________________________________________________________________
;  |                                                                           |
;  |                             SetFileAttributes                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SetFileAttributes (Start)                                     Librairie n° 34
; PureBasic 3.92
; Sets a file's attributes

; ProcedureDLL SetFileAttributes(FileName.s,FileAttributes)
;   
;   ; 1 Sucess / 0 Fail
;   
;   retour=SetFileAttributes_(@FileName,FileAttributes)
;   If retour<>0 : retour=1 : EndIf
;   ProcedureReturn retour
; EndProcedure
; 
; ;/ Test
; SetFileAttributes("c:\ur1.txt",#FILE_ATTRIBUTE_ARCHIVE|#FILE_ATTRIBUTE_HIDDEN|#FILE_ATTRIBUTE_READONLY|#FILE_ATTRIBUTE_SYSTEM)


;/ Please use this PB Constants 
; #FILE_ATTRIBUTE_ARCHIVE
; #FILE_ATTRIBUTE_HIDDEN
; #FILE_ATTRIBUTE_READONLY
; #FILE_ATTRIBUTE_SYSTEM

;} SetFileAttributes (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            ShutDownAndPowerOff                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ShutDownAndPowerOff (Start)                                   Librairie n° 35
; PureBasic 3.92
; BackupUser 19/06/02
; Forced ShutDown

ProcedureDLL ShutDownAndPowerOff() 
  
  ;/ Need ExitWindowsEx Constants

  ;/ Need Structure MyLUID & MyTOKEN  
  
  Global hdlProcessHandle.l 
  Global hdlTokenHandle.l 
  Global tmpLuid.MyLUID 
  Global tkp.MyTOKEN 
  Global tkpNewButIgnored.MyTOKEN 
  Global lBufferNeeded.l 
  hdlProcessHandle = GetCurrentProcess_() 
  OpenProcessToken_(hdlProcessHandle, #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @hdlTokenHandle) 
  SysName.s=""+Chr(0) 
  Name.s="SeShutdownPrivilege"+Chr(0) 
  Erg.l=LookupPrivilegeValue_(SysName, Name, @tmpLuid) 
  tmpLuid\Attributes = #SE_PRIVILEGE_ENABLED 
  tkp\PrivilegeCount = 1  
  tkp\LowPart = tmpLuid\LowPart 
  tkp\HighPart = tmpLuid\HighPart 
  tkp\Attributes = tmpLuid\Attributes 
  Erg.l = AdjustTokenPrivileges_(hdlTokenHandle,0,@tkp,SizeOf(MyTOKEN),@tkpNewButIgnored,@lBufferNeeded) 
  Erg.l = ExitWindowsEx_((#EWX_SHUTDOWN |#EWX_POWEROFF | #EWX_FORCE), 0) 
EndProcedure 



;} ShutDownAndPowerOff (End)

; Timer & TimerKill replaced by new one in DroopyL Lib 1.28

;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 UserExist                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ UserExist (Start)                                             Librairie n° 37
; BackupUser tweaked by Droopy ( For librairy purpose ) 
; PB 3.92 16/02/05
; Return 1 if User / Password correct --> User exist
; Return 0 if user don't exist / Incorrect password / Empty password !!

ProcedureDLL UserExist(Username.s,Password.s) 
  Domain.s="."
  Result=LogonUser_(@Username,@Domain,@Password,#LOGON32_LOGON_INTERACTIVE,#LOGON32_PROVIDER_DEFAULT,@Token) 
  ProcedureReturn Result
EndProcedure  

;/ Test
; Debug UserExist("toto","passe")

;} UserExist (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              WNetConnection                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WNetConnection (Start)                                        Librairie n° 38
; PureBasic 3.92
; Droopy 19/04/05

; WNetAddConnection : Map Network Drive with password
; WNetCancelConnection : Disconnect Network Map Driver


ProcedureDLL WNetAddConnection(ShareName.s,Password.s,DriveLetter.s)
  ; ShareName : Ex \\ComputerName\SharePoint
  ; Password & Driveletter : Ex F:
  
;mpr = OpenLibrary(#PB_Any,"Mpr.dll")
;retour=CallFunction(mpr,"WNetAddConnectionA",ShareName,Password,DriveLetter)
retour=WNetAddConnection_(ShareName,Password,DriveLetter)
;CloseLibrary(mpr)
If retour=0 : retour=1 : Else : retour=0 : EndIf
ProcedureReturn retour
EndProcedure

ProcedureDLL WNetCancelConnection(DriveLetter.s,force.l)
  
  ; Driveletter : Ex F:
  ; Force = #True or #False ( Deconnect when file is in use )
  
  ;mpr = OpenLibrary(#PB_Any,"Mpr.dll")
  ;retour=CallFunction(mpr,"WNetCancelConnectionA",DriveLetter,force)
  retour=WNetCancelConnection_(DriveLetter,force)
  ;CloseLibrary(mpr)
  If retour=0 : retour=1 : Else : retour=0 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test 
; WNetAddConnection("\\Server\toto","","s:")
; MessageRequester("WNetAddConnection","Drive Mapped")
; WNetCancelConnection("s:",#True)
; MessageRequester("WNetCancelConnection","Drive UnMapped")

;} WNetConnection (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              WNetConnectionNT                             |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WNetConnectionNT (Start)                                      Librairie n° 39
; PureBasic 3.92
; Droopy 20/04/05

; WNetAddConnection2 : Map Network Drive with Username / Password
; use WNetCancelConnection to Disconnect Network Map Drive

ProcedureDLL WNetAddConnectionNT(Username.s,Password.s,ShareName.s,DriveLetter.s,Persistant.l)
  
  ;/ Username / Password
  ;/ Sharename : \\Server\Share
  ;/ DriveLetter : F:
  ;/ Persistant : #True or #False
  ;/ Return 1 if success or 0 if fail
  
  lpNetResource.NETRESOURCE
  lpNetResource\dwtype=1 ; RESOURCETYPE_DISK
  lpNetResource\lpLocalName=@DriveLetter
  lpNetResource\lpRemoteName=@ShareName
  
  ;mpr = OpenLibrary(#PB_Any,"Mpr.dll")
; retour=CallFunction(mpr,"WNetAddConnection2W",lpNetResource,Password,Username,Persistant)
  retour=WNetAddConnection2_(lpNetResource,Password,Username,Persistant)
  ;CloseLibrary(mpr)
  
  If retour=0 : retour=1 : Else : retour=0 : EndIf
  ProcedureReturn retour
  
EndProcedure


;/ Test 
; WNetAddConnectionNT("username","password","\\Server\Share","Z:",#True)
; MessageRequester("Network drive mapped","Click to Unmap")
; WNetCancelConnection("Z:",#True)



;} WNetConnectionNT (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Xdel                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Xdel (Start)                                                  Librairie n° 40

;/ Deleted in 1.1 cause DeleteDirectory has a #PB_FileSystem_Recursive option !

;} Xdel (End)


;/
;/
;/
;/
;/
;/                        VERSION 1.1 FUNCTIONS ADDON
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                              CheckForMedium                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CheckForMedium (Start)                                        
; German forum: http://robsite.de/php/pureboard/viewtopic.php?t=2480&highlight=
; Author: bingo
; Date: 07. October 2003

; Check for a medium in a drive, without getting the requester "Please insert...."
; Network drive report NTFS !

ProcedureDLL CheckForMedium(Drive.s)
  Drive=Left(Drive,1)+":\"
  
  VNB.s=Space(100)     ; Volume Name Buffer 
  VNS=100             ; Volume Name Size 
  VSN=0               ; Volume Serial Number (Hex) 
  MCL=0               ; Max.File Name Len 
  FSF=0               ; File System Flags 
  FSNB.s=Space(100)    ; File System Name Buffer (FAT/NTFS usw) 
  FSNS=100            ; File System Name BufferSize 
  
  GetVolumeInformation_(Drive,@VNB,VNS,@VSN,@MCL,@FSF,@FSNB,FSNS) 
  If VSN<>0 : VSN=1 : EndIf
  ProcedureReturn VSN
EndProcedure

ProcedureDLL.s GetDriveVolumeName(Drive.s)
  Drive=Left(Drive,1)+":\"
  
  VNB.s=Space(100)     ; Volume Name Buffer 
  VNS=100             ; Volume Name Size 
  VSN=0               ; Volume Serial Number (Hex) 
  MCL=0               ; Max.File Name Len 
  FSF=0               ; File System Flags 
  FSNB.s=Space(100)    ; File System Name Buffer (FAT/NTFS usw) 
  FSNS=100            ; File System Name BufferSize 
  
  GetVolumeInformation_(Drive,@VNB,VNS,@VSN,@MCL,@FSF,@FSNB,FSNS) 
  If VSN<>0 : VSN=1 : EndIf
  ProcedureReturn VNB
EndProcedure

ProcedureDLL.s GetDriveFileSystem(Drive.s)
  Drive=Left(Drive,1)+":\"
  
  VNB.s=Space(100)     ; Volume Name Buffer 
  VNS=100             ; Volume Name Size 
  VSN=0               ; Volume Serial Number (Hex) 
  MCL=0               ; Max.File Name Len 
  FSF=0               ; File System Flags 
  FSNB.s=Space(100)    ; File System Name Buffer (FAT/NTFS usw) 
  FSNS=100            ; File System Name BufferSize 
  
  GetVolumeInformation_(Drive,@VNB,VNS,@VSN,@MCL,@FSF,@FSNB,FSNS) 
  If VSN<>0 : VSN=1 : EndIf
  ProcedureReturn FSNB
EndProcedure

;/ Test
; Drive.s="c:\"
; Debug CheckForMedium(Drive)
; Debug GetDriveVolumeName(Drive)
; Debug GetDriveFileSystem(Drive)

;} CheckForMedium (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              CreateShortcut                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CreateShortcut (Start)                                        
; German forum: http://robsite.de/php/pureboard/viewtopic.php?t=3078&highlight=
; Author: Danilo
; Date: 09. December 2003
; create shell links/shortcuts 
; translated from my old example that used CallCOM() 
; by Danilo, 09.12.2003 

Interface _IPersistFile
  QueryInterface(a, b)
  AddRef()
  Release()
  GetClassID(a)
  IsDirty()
  Load(a, b)
  Save(a.p-unicode, b)
  SaveCompleted(a)
  GetCurFile(a)
EndInterface

Interface _IShellLinkW
  QueryInterface(a, b)
  AddRef()
  Release()
  GetPath(a.p-unicode, b, c, d)
  GetIDList(a)
  SetIDList(a)
  GetDescription(a.p-unicode, b)
  SetDescription(a.p-unicode)
  GetWorkingDirectory(a.p-unicode, b)
  SetWorkingDirectory(a.p-unicode)
  GetArguments(a.p-unicode, b)
  SetArguments(a.p-unicode)
  GetHotkey(a)
  SetHotkey(a)
  GetShowCmd(a)
  SetShowCmd(a)
  GetIconLocation(a.p-unicode, b, c)
  SetIconLocation(a.p-unicode, b)
  SetRelativePath(a, b)
  Resolve(a, b)
  SetPath(a.p-unicode)
EndInterface


 
ProcedureDLL CreateShortcut(Path.s, LINK.s, Argument.s, DESCRIPTION.s, WorkingDirectory.s, ShowCommand.l, IconFile.s, IconIndexInFile.l) 
  CoInitialize_(0) 
  If CoCreateInstance_(?CLSID_ShellLink,0,1,?IID_IShellLinkW,@psl._IShellLinkW) = 0 
    
    Set_ShellLink_preferences: 
    
    ; The file TO which is linked ( = target for the Link ) 
    ; 
    psl\SetPath(Path) 
    
    ; Arguments for the Target 
    ; 
    psl\SetArguments(Argument) 
    
    ; Working Directory 
    ; 
    psl\SetWorkingDirectory(WorkingDirectory) 
    
    ; Description ( also used as Tooltip for the Link ) 
    ; 
    psl\SetDescription(DESCRIPTION) 
    
    ; Show command: 
    ;               SW_SHOWNORMAL    = Default 
    ;               SW_SHOWMAXIMIZED = aehmm... Maximized 
    ;               SW_SHOWMINIMIZED = play Unreal Tournament 
    psl\SetShowCmd(ShowCommand) 
    
    ; Hotkey: 
    ; The virtual key code is in the low-order byte, 
    ; and the modifier flags are in the high-order byte. 
    ; The modifier flags can be a combination of the following values: 
    ; 
    ;         HOTKEYF_ALT     = ALT key 
    ;         HOTKEYF_CONTROL = CTRL key 
    ;         HOTKEYF_EXT     = Extended key 
    ;         HOTKEYF_SHIFT   = SHIFT key 
    ; 
    psl\SetHotkey(HotKey) 
    
    ; Set Icon for the Link: 
    ; There can be more than 1 icons in an icon resource file, 
    ; so you have to specify the index. 
    ; 
    psl\SetIconLocation(IconFile, IconIndexInFile) 
    
    
    ShellLink_SAVE: 
    ; Query IShellLink For the IPersistFile interface For saving the 
    ; shortcut in persistent storage. 
    If psl\QueryInterface(?IID_IPersistFile,@ppf._IPersistFile) = 0 
      ; Ensure that the string is Unicode. 
      ;Save the link by calling IPersistFile::Save. 
      hres = ppf\Save(LINK,#True) 
      Result = 1 
      ppf\Release() 
    EndIf 
    psl\Release() 
  EndIf 
  CoUninitialize_() 
  ProcedureReturn Result 
  
  DataSection 
  CLSID_ShellLink: 
  ; 00021401-0000-0000-C000-000000000046 
  Data.l $00021401 
  Data.w $0000,$0000 
  Data.b $C0,$00,$00,$00,$00,$00,$00,$46 
  IID_IShellLink: 
  ; DEFINE_SHLGUID(IID_IShellLinkA,         0x000214EEL, 0, 0); 
  ; C000-000000000046 
  Data.l $000214EE 
  Data.w $0000,$0000 
  Data.b $C0,$00,$00,$00,$00,$00,$00,$46 
  IID_IPersistFile: 
  ; 0000010b-0000-0000-C000-000000000046 
  Data.l $0000010B 
  Data.w $0000,$0000 
  Data.b $C0,$00,$00,$00,$00,$00,$00,$46 
  
  IID_IShellLinkW: ; {000214F9-0000-0000-C000-000000000046}
    Data.l $000214F9
    Data.w $0000, $0000
    Data.b $C0, $00, $00, $00, $00, $00, $00, $46
  EndDataSection 
  
  
EndProcedure 


;/                             CreateShortcut 
;             - TARGET for the Link ("c:\PureBasic\purebasic.exe") 
;             - LINK - Path & name of the Link ("c:\pb.lnk") 
;             - Argument for the target  ("%1") 
;             - Description = Description and Tooltip 
;             - Working Directory  
;             - Show command: #SW_SHOWNORMAL or #SW_SHOWMAXIMIZED or #SW_SHOWMINIMIZED 
;             - IconFile + Index ( "c:\PureBasic\purebasic.exe" , 0 ) 0 = 1st

;/ Test
; CreateShortcut("C:\Windows\System32\Notepad.exe","C:\Super Notepad.lnk","","NotePAD is a lightweight editor","",#SW_SHOWMAXIMIZED,"%SystemRoot%\system32\SHELL32.dll",12) 
; CreateShortcut("c:\windows\system32\notepad.exe","c:\Super Notepad.lnk","","test","",#SW_SHOWNORMAL,"C:\Softs\freevcr\freeVCR.exe",0) 



;} CreateShortcut (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              EmptyRecycleBin                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ EmptyRecycleBin (Start)                                       
; Author: PB tweaked by Droopy

; SHERB_NOCONFIRMATION  1
; SHERB_NOPROGRESSUI    2
; SHERB_NOSOUND         4

; Delete files in RecycleBin in all drives without Sound / Progress Bar / Confirmation

ProcedureDLL EmptyRecycleBin()
  
  shell = OpenLibrary(#PB_Any,"shell32.dll")

  If shell
    
    CompilerIf #PB_Compiler_Unicode = 0
      func = GetFunction(shell,"SHEmptyRecycleBinA")
    CompilerElse
      func = GetFunction(shell,"SHEmptyRecycleBinW")
    CompilerEndIf
    retour=CallFunctionFast(func,0,0,7) 
    CloseLibrary(shell)
    
    If retour=0 : retour = 1 : Else : retour=0 : EndIf
    
  EndIf 
  ProcedureReturn retour
EndProcedure 

;/ Test
; Debug EmptyRecycleBin()


;} EmptyRecycleBin (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          File Time & RecycleBin                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ File Time & RecycleBin (Start)                                
; Code from GPI tweaked by Droopy

;/ Internal procedures

Procedure FileTimeToDate(*FT.FILETIME); - Convert API-Time-Format to PB-Date() 
  FileTimeToLocalFileTime_(*FT.FILETIME,FT2.FILETIME) 
  FileTimeToSystemTime_(FT2,st.SYSTEMTIME) 
  ProcedureReturn Date(st\wYear,st\wMonth,st\wDay,st\wHour,st\wMinute,st\wSecond) 
EndProcedure 

Procedure DateToFileTime(Date,*FT.FILETIME); - Convert PB-Date() to API-Time-Format 
  st.SYSTEMTIME 
  st\wYear=Year(Date) 
  st\wMonth=Month(Date) 
  st\wDayOfWeek=DayOfWeek(Date) 
  st\wDay=Day(Date) 
  st\wHour=Hour(Date) 
  st\wMinute=Minute(Date) 
  st\wSecond=Second(Date) 
  SystemTimeToFileTime_(st,FT2.FILETIME) 
  LocalFileTimeToFileTime_(FT2,*FT) 
EndProcedure 

ProcedureDLL FileGetTime(File.s,Which); - Get the time of a File 
  
  ; Wich specify wich time
  ; 0 = Time the File was created
  ; 1 = Time the file was last accessed
  ; 2 = Time the file was last written 
  
  ; return 0 if fail / Date in Purebasic format if success
  
  Result=0 
  handle=CreateFile_(@File,#GENERIC_READ,#FILE_SHARE_READ|#FILE_SHARE_WRITE,0,#OPEN_EXISTING,#FILE_ATTRIBUTE_NORMAL,0) 
  If handle<>#INVALID_HANDLE_VALUE 
    Select Which
      Case 1
        GetFileTime_(handle,0,FT.FILETIME,0) 
      Case 2
        GetFileTime_(handle,0,0,FT.FILETIME) 
      Default
        GetFileTime_(handle,FT.FILETIME,0,0) 
    EndSelect
    
    Result=FileTimeToDate(FT) 
    CloseHandle_(handle) 
  EndIf 
  ProcedureReturn Result 
EndProcedure 

ProcedureDLL FileSetTime(File.s,Date,Which); - Set the time of a File
  ; Return 1 If succes / 0 If fail
  
  ; Which specify wich time
  ; 0 = Time the File was created
  ; 1 = Time the file was last accessed
  ; 2 = Time the file was last written 
  
  handle=CreateFile_(@File,#GENERIC_WRITE,#FILE_SHARE_READ|#FILE_SHARE_WRITE,0,#OPEN_EXISTING,#FILE_ATTRIBUTE_NORMAL,0) 
  If handle<>#INVALID_HANDLE_VALUE 
    DateToFileTime(Date,FT.FILETIME) 
    
    Select Which
      Case 1
        retour=SetFileTime_(handle,0,FT.FILETIME,0) 
      Case 2
        retour=SetFileTime_(handle,0,0,FT.FILETIME) 
      Default
        retour=SetFileTime_(handle,FT.FILETIME,0,0) 
    EndSelect
    
    CloseHandle_(handle) 
  EndIf 
  
  If retour<>0 : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure 

ProcedureDLL.l DeleteFileToRecycleBin(File.s); - Delete a file and move it in the Recycle-Bin
  ; without confirmation / without ProgressBar
  
  ; return 1 if success / 0 if fail
  
  SHFileOp.SHFILEOPSTRUCT 
  SHFileOp\pFrom=@File 
  SHFileOp\wFunc=#FO_DELETE 
  SHFileOp\fFlags=#FOF_ALLOWUNDO |#FOF_NOCONFIRMATION | #FOF_SILENT	
  retour=SHFileOperation_(SHFileOp) 
  If retour=0 : retour=1 : Else : retour =0 : EndIf
  ProcedureReturn retour
  
EndProcedure


;/ Test
; File.s="c:\TestDate.txt"
; CreateFile(0,File)
; CloseFile(0)
; 
; DateCreated=ParseDate("%dd:%mm:%yy %hh:%ii:%ss","01:01:05 00:00:00")
; DateLastAccessed=ParseDate("%dd:%mm:%yy %hh:%ii:%ss","01:01:05 00:01:00")
; DateLastWritten=ParseDate("%dd:%mm:%yy %hh:%ii:%ss","01:01:05 00:02:00")
; 
; FileSetTime(File,DateCreated,0)
; FileSetTime(File,DateLastAccessed,1)
; FileSetTime(File,DateLastWritten,2)
; 
; FileTime=FileGetTime(File,0)
; Debug "Creation " + FormatDate("%dd:%mm:%yy %hh:%ii:%ss",FileTime)
; 
; FileTime=FileGetTime(File,1)
; Debug "Last Access " + FormatDate("%dd:%mm:%yy %hh:%ii:%ss",FileTime)
; 
; FileTime=FileGetTime(File,2)
; Debug "Last Written " + FormatDate("%dd:%mm:%yy %hh:%ii:%ss",FileTime)
; 
; DeleteFileToRecycleBin(File)

;} File Time & RecycleBin (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                GetCpuSpeed                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetCpuSpeed (Start)                                           
; English forum: http://purebasic.myforums.net/viewtopic.php?t=3811&postdays=0&postorder=asc&start=15
; Author: jack
; Date: 26. September 2003

; from PB forums by Hi-Toro 
; inline asm by jack 

Structure bit64 
  LowPart.l 
  HighPart.l 
EndStructure 

; ProcedureDLL GetCPUSpeed()
;    
;    ; Return CPU Speed in Mhz
;    
;    OneMillion.l=1000000
;    Define.bit64 ulEAX_EDX, ulFreq, ulTicks, ulValue, ulStartCounter, ulResult
;    QueryPerformanceFrequency_(ulFreq)
;    QueryPerformanceCounter_(ulTicks)
;    ! fild qword [p.v_ulFreq] ;ulFreq
;    ! fild qword [p.v_ulTicks] ;ulTicks
;    ! faddp st1,st0       ;ST0=ulFreq+ulTicks
;    ! fistp qword [p.v_ulValue];ST0->ulValue
;    ;ulValue\LowPart = ulTicks\LowPart + ulFreq\LowPart
;    ! RDTSC
;    ! MOV [p.v_ulEAX_EDX], eax ;MOV ulEAX_EDX\LowPart, eax
;    ! MOV [p.v_ulEAX_EDX+4], edx ;MOV ulEAX_EDX\HighPart,edx
;    ! fild qword [p.v_ulEAX_EDX]  ;ulEAX_EDX
;    ! fistp qword [p.v_ulStartCounter];ulStartCounter
;    ;ulStartCounter\LowPart = ulEAX_EDX\LowPart
;    ! fild qword [p.v_ulValue] ;ulValue
;    startloop:
;    ! fild qword [p.v_ulTicks] ;ulTicks
;    ! FCOMP
;    ! FNSTSW ax
;    ! SAHF
;    ! JAE l_endloop
;    ;While (ulTicks\LowPart <= ulValue\LowPart)
;    QueryPerformanceCounter_(ulTicks)
;    ;Wend
;    Goto startloop
;    endloop:
;    ! fstp st0   
;    ! RDTSC
;    ! MOV [p.v_ulEAX_EDX], eax ;MOV ulEAX_EDX\LowPart, eax
;    ! MOV [p.v_ulEAX_EDX+4], edx ;MOV ulEAX_EDX\HighPart,edx
;    ! fild qword [p.v_ulEAX_EDX]  ;ulEAX_EDX
;    ! fild qword [p.v_ulStartCounter] ;ulStartCounter
;    ! fsubp st1,st0       ;ST0=ulEAX_EDX - ulStartCounter
;    ! fild dword [p.v_OneMillion]    ;OneMillion
;    ! fdivp st1,st0       ;ST0=(ulEAX_EDX - ulStartCounter)/1000000
;    ! fistp qword [p.v_ulResult];ST0->ulResult
;    ;ulResult\LowPart = (ulEAX_EDX\LowPart - ulStartCounter\LowPart)/1000000
;    ProcedureReturn ulResult\LowPart; / 1000000
;  EndProcedure; Takes 1 second to calculate...

;by Rescator - added/changed in 1.31.4 because of the Hi-Toro/jack code not working with tailbite
ProcedureDLL.l GetCpuSpeed()
  Global int64val.LARGE_INTEGER
  !FINIT
  !rdtsc
  !MOV dword [v_int64val+4],Edx
  !MOV dword [v_int64val],Eax
  !FILD qword [v_int64val]
  Delay(1000)
  !rdtsc
  !MOV dword [v_int64val+4],Edx
  !MOV dword [v_int64val],Eax
  !FILD qword [v_int64val]
  !FSUBR st1,st0
  int64val\HighPart=0
  int64val\LowPart=1000000
  !FILD qword [v_int64val]
  !FDIVR st0,st2
  !fistp qword [v_int64val]

 ProcedureReturn int64val\LowPart
EndProcedure

;/ Test
; Debug  GetCPUSpeed() 


;} GetCpuSpeed (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           GetFileAttributesText                           |
;  |                           _____________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetFileAttributesText (Start)                                 
; Droopy ( Idea from GPI )

ProcedureDLL.s GetFileAttributesText(FileName.s)
  
  Attributes=GetFileAttributes(FileName)
  
  retour.s=""
  If Attributes <>-1 ; If file or directory found
    If Attributes & #PB_FileSystem_Archive : retour+"A" : Else : retour + "-" :EndIf
    If Attributes & #PB_FileSystem_Compressed  : retour+"C" : Else : retour + "-" :EndIf
    ;If Attributes & #FILE_ATTRIBUTE_DIRECTORY  : retour+"D" : Else : retour + "-" :EndIf
    If Attributes & #PB_FileSystem_Hidden  : retour+"H" : Else : retour + "-" :EndIf
    If Attributes & #PB_FileSystem_ReadOnly  : retour+"R" : Else : retour + "-" :EndIf
    If Attributes & #PB_FileSystem_System  : retour+"S" : Else : retour + "-" :EndIf
    ;If Attributes & #FILE_ATTRIBUTE_TEMPORARY  : retour+"T" : Else : retour + "-" :EndIf
  EndIf
  
  ProcedureReturn retour
  
EndProcedure

;/ Test
; Debug GetFileAttributesText("c:\boot.ini")

;} GetFileAttributesText (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetPidProcess                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetPidProcess (Start)                                         
; Search a Process Pid ( ex MTXAGENT.EXE : Function not case sensitive ) 
; Work under Windows NT / 9x / XP
; Fred code tweaked by Droopy
; PureBasic 3.92
; Return Process Pid if Process exist / 0 if not exist
;1.31.4 - tweaked for unicode and ascii modes by Demonio Ardente

;/ Need Structure PROCESSENTRY33 

#TH32CS_SNAPPROCESS = $2 

ProcedureDLL GetPidProcess(Name.s) 
  Name.s=UCase(Name.s)
  Recherche=0
  If OpenLibrary(0, "Kernel32.dll") 
    
    CreateToolhelpSnapshot = GetFunction(0, "CreateToolhelp32Snapshot") 
    ProcessFirst           = GetFunction(0, "Process32First") 
    ProcessNext            = GetFunction(0, "Process32Next") 
    
    If CreateToolhelpSnapshot And ProcessFirst And ProcessNext ; Ensure than all the functions are found 
      
      Process.PROCESSENTRY33\dwSize = SizeOf(PROCESSENTRY33) 
      
      Snapshot = CallFunctionFast(CreateToolhelpSnapshot, #TH32CS_SNAPPROCESS, 0) 
      If Snapshot 
        
        ProcessFound = CallFunctionFast(ProcessFirst, Snapshot, Process) 
        While ProcessFound 
          Nom.s=UCase(PeekS(@Process\szExeFile, -1, #PB_Ascii))
          Nom=GetFilePart(Nom)
          If Nom=Name 
            Recherche =1 
            PID=Process\th32ProcessID
          EndIf
          ProcessFound = CallFunctionFast(ProcessNext, Snapshot, Process) 
        Wend 
      EndIf 
      
      CloseHandle_(Snapshot) 
    EndIf 
    
    CloseLibrary(0) 
  EndIf 
  
  ProcedureReturn PID
EndProcedure

;/ Test de la procédure
; MessageRequester("Explorer.exe","Pid ="+Str(GetPidProcess("explorer.exe")))


;} GetPidProcess (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              GetProgramPath                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetProgramPath (Start)                                        
; PureBasic 3.92
; Droopy 28/04/05
; Return the Program Path

ProcedureDLL.s GetProgramPath()
  ProgramName.s=Space(255)
  GetModuleFileName_(0,@ProgramName,255) 
  ProcedureReturn GetPathPart(ProgramName)
EndProcedure

;  Test
; MessageRequester("Program launched from",GetProgramPath())

;} GetProgramPath (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetProgramResult                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetProgramResult (Start)                                      
; PureBasic 3.93
; Redirect Outputs into Memory (redirected the pipes)
; coded by Siegfried Rings march 2002 
; Tweaked by Droopy ( 03/05/05 )

; see http://support.microsoft.com/default.aspx?scid=kb;EN-US;q173085 

; Structure used by the CreateProcessA function 
; another then that Fred implemented ! 

Structure MySTARTUPINFO 
  cb.l 
  lpReserved.l 
  lpDesktop.l 
  lpTitle.l 
  dwX.l 
  dwY.l 
  dwXSize.l 
  dwYSize.l 
  dwXCountChars.l 
  dwYCountChars.l 
  dwFillAttribute.l 
  dwFlags.l 
  wShowWindow.w 
  cbReserved2.w 
  lpReserved2.l 
  hStdInput.l 
  hStdOutput.l 
  hStdError.l 
EndStructure 

Procedure.s ConformationAsciiEtenduVersAscii(Text.s)
  ReplaceString(Text,Chr(130),"é",2)
  ReplaceString(Text,Chr(135),"ç",2)
  ReplaceString(Text,Chr(131),"â",2)
  ReplaceString(Text,Chr(133),"à",2)
  ReplaceString(Text,Chr(136),"ê",2)
  ReplaceString(Text,Chr(137),"ë",2)
  ReplaceString(Text,Chr(138),"è",2)
  ReplaceString(Text,Chr(140),"î",2)
  ReplaceString(Text,Chr(150),"û",2)
  ReplaceString(Text,Chr(151),"ù",2)
  ReplaceString(Text,Chr(240),"-",2)
  ReplaceString(Text,Chr(242),"=",2)
  ReplaceString(Text,Chr(255)," ",2)
  
  ; Nettoie des caractères < 31
  For n=1 To 31
    If n=9 : Continue : EndIf
    If n=10 : Continue : EndIf ; LF fout la zone je le supprime
    ; If n=13 : Continue : EndIf 
    ReplaceString(Text,Chr(n),"",2)
  Next
  
  ProcedureReturn Text
EndProcedure

ProcedureDLL.s GetProgramResult(Command.s)
  
  proc.PROCESS_INFORMATION ;Process info filled by CreateProcessA 
  ret.l ;long variable For get the Return value of the 
  start.MySTARTUPINFO ;StartUp Info passed To the CreateProceeeA 
  sa.SECURITY_ATTRIBUTES ;Security Attributes passeed To the 
  hReadPipe.l ;Read Pipe handle created by CreatePipe 
  hWritePipe.l ;Write Pite handle created by CreatePipe 
  lngBytesread.l ;Amount of byte Read from the Read Pipe handle 
  strBuff.s=Space(256) ;String buffer reading the Pipe 
  
  ;Consts For functions 
  #NORMAL_PRIORITY_CLASS = $20 
  #STARTF_USESTDHANDLES = $100 
  #STARTF_USESHOWWINDOW = $1 
  
  ;Create the Pipe 
  sa\nLength =SizeOf(SECURITY_ATTRIBUTES) ;Len(sa) 
  sa\bInheritHandle = 1 
  sa\lpSecurityDescriptor = 0 
  ret = CreatePipe_(@hReadPipe, @hWritePipe, @sa, 0) 
  If ret = 0 
    ;If an error occur during the Pipe creation exit 
    MessageRequester("info", "CreatePipe failed. Error: ",0) 
    ;End 
  EndIf 
  
  
  start\cb = SizeOf(MySTARTUPINFO) 
  start\dwFlags = #STARTF_USESHOWWINDOW | #STARTF_USESTDHANDLES 
  
  ;set the StdOutput And the StdError output To the same Write Pipe handle 
  start\hStdOutput = hWritePipe 
  start\hStdError = hWritePipe 
  
  ;Execute the command 
  ret = CreateProcess_(0, Command, sa, sa, 1, #NORMAL_PRIORITY_CLASS, 0, 0, @start, @proc) 
  
  If ret <> 1 
    retour.s=""
  Else
    
    ;Now We can ... must close the hWritePipe 
    ret = CloseHandle_(hWritePipe) 
    
    mOutputs.s = "" 
    
    ;Read the ReadPipe handle 
    While ret<>0 
      ret = ReadFile_(hReadPipe, strBuff, 255, @lngBytesread, 0) 
      If lngBytesread>0 
        mOutputs = mOutputs + Left(strBuff, lngBytesread) 
      EndIf 
    Wend 
    
    ;Close the opened handles 
    ret = CloseHandle_(proc\hProcess) 
    ret = CloseHandle_(proc\hThread) 
    ret = CloseHandle_(hReadPipe) 
    ;ret=CloseHandle_(hWritePipe) 
    
    retour.s=mOutputs
    
  EndIf
  
  ProcedureReturn ConformationAsciiEtenduVersAscii(mOutputs)
EndProcedure

;/ Test
; Commande.s="Cmd /c dir c:\"
; MessageRequester(Commande,GetProgramResult(Commande))
; Commande.s="net start"
; MessageRequester(Commande,GetProgramResult(Commande))


;} GetProgramResult (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                     GetPureBasicDirectoryInstallation                     |
;  |                     _________________________________                     |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetPureBasicDirectoryInstallation (Start)                     
; Auteur : Fred
; Version de PB : 3.90

; Get PureBasic Installation Directory


ProcedureDLL.s GetPureBasicDirectoryInstallation()
  
  Buffer$ = Space(10000) : BufferSize = Len(Buffer$) - 1
  
  ; Windows NT/XP
  If GetVersion_() & $FF0000
    If RegOpenKeyEx_(#HKEY_CLASSES_ROOT, "Applications\PureBasic.exe\shell\open\command", 0, #KEY_ALL_ACCESS, @Key) = #ERROR_SUCCESS
      If RegQueryValueEx_(Key, "", 0, @Type, @Buffer$, @BufferSize) = #ERROR_SUCCESS
;         OutputDirectory$ = GetPathPart(Mid(Buffer$, 2, Len(Buffer$) - 7))
          OutputDirectory$ = GetPathPart(Between_int(Buffer$,Chr(34), Chr(34)))
      EndIf
    EndIf
  Else ; The same for Win9x
    If RegOpenKeyEx_(#HKEY_LOCAL_MACHINE, "Software\Classes\PureBasic.exe\shell\open\command", 0, #KEY_ALL_ACCESS, @Key) = #ERROR_SUCCESS
      If RegQueryValueEx_(Key, "", 0, @Type, @Buffer$, @BufferSize) = #ERROR_SUCCESS
        OutputDirectory$ = GetPathPart(Mid(Buffer$, 2, Len(Buffer$) - 7))
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn OutputDirectory$
EndProcedure

;/ Test
; Debug GetPureBasicDirectoryInstallation()

;} GetPureBasicDirectoryInstallation (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                GetUserName                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetUserName (Start)                                           

; Return the Name of the User logged on the Workstation
; Return an Empty String if error
; Works only on Windows 2K/XP


ProcedureDLL.s GetUserName()
  
  Username.s = Space(512) 
  nsize.l = 512 
  retour=GetUserName_(@Username, @nsize) 
  If retour=0 : Username="": EndIf ; If error return an Empty String
  ProcedureReturn Username
EndProcedure

;/ Test
; MessageRequester("Logged User",GetUserName())

;} GetUserName (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GlobalMemoryStatus                             |
;  |                            __________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GlobalMemoryStatus (Start)                                    
; Author: Fred (Debug output extended by Andre) / Tweaked by Droopy
; Date: 31. December 2003
; Functions to retrieve memory free ( Physical / Virtual )

;/ MemoryLoad
; Specifies a number between 0 And 100 that gives a general idea of current Memory utilization, in which 0 indicates no Memory use And 100 indicates full Memory use. 
; 
;/ TotalPhys
; indicates the total number of bytes of physical Memory. 
; 
;/ AvailPhys
; indicates the number of bytes of physical Memory available. 
; 
;/ TotalPageFile
; indicates the total number of bytes that can be stored in the paging file. Note that this number does not represent the actual physical size of the paging file on disk. 
; 
;/ AvailPageFile
; indicates the number of bytes available in the paging file. 
; 
;/ TotalVirtual
; indicates the total number of bytes that can be described in the user mode portion of the virtual address space of the calling process. 
; 
;/ AvailVirtual
; indicates the number of bytes of unreserved And uncommitted Memory in the user mode portion of the virtual address space of the calling process. 


ProcedureDLL GlobalMemoryStatusMemoryLoad()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwMemoryLoad
EndProcedure

ProcedureDLL GlobalMemoryStatusTotalPhys()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwTotalPhys /1024/1024
EndProcedure

ProcedureDLL GlobalMemoryStatusAvailPhys()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwAvailPhys/1024/1024
EndProcedure

ProcedureDLL GlobalMemoryStatusTotalPageFile()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwTotalPageFile/1024/1024
EndProcedure

ProcedureDLL GlobalMemoryStatusAvailPageFile()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwAvailPageFile/1024/1024
EndProcedure

ProcedureDLL GlobalMemoryStatusTotalVirtual()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwTotalVirtual/1024/1024
EndProcedure

ProcedureDLL GlobalMemoryStatusAvailVirtual()
  Memory.MEMORYSTATUS
  GlobalMemoryStatus_(@Memory) 
  ProcedureReturn Memory\dwAvailVirtual/1024/1024
EndProcedure

;/ Test
; Debug GlobalMemoryStatusMemoryLoad()
; Debug GlobalMemoryStatusTotalPhys()
; Debug GlobalMemoryStatusAvailPhys()
; Debug GlobalMemoryStatusTotalPageFile()
; Debug GlobalMemoryStatusAvailPageFile()
; Debug GlobalMemoryStatusTotalVirtual()
; Debug GlobalMemoryStatusAvailVirtual()


;} GlobalMemoryStatus (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   GUID                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GUID (Start)                                                  
; PureBasic 3.93
; Droopy
; 20/02/05

; Return a unique GUID ( 12 Hexa codes )
; 8 first chr$  = Date 
; 9-10 chr$     = 3° code of IP Address 
; 11-12 chr$    = 4° code of IP Address 

ProcedureDLL.s GUID()
  InitNetwork()
  ExamineIPAddresses()
  a=NextIPAddress()
  
  ; 3° Champ de l'adresse IP
  code1.s=Hex(IPAddressField(a,2))
  If Len(code1)<2 
    code1=Space(2-Len(code1))+code1
  EndIf
  
  ; 4° champ de l'adresse IP
  code2.s=Hex(IPAddressField(a,3))
  If Len(code2)<2 
    code2=Space(2-Len(code2))+code2
  EndIf
  
  ; Date au format Hexa
  code3.s=Hex(Date())
  If Len(code3)<8 
    code3=Space(8-Len(code3))+code$
  EndIf
  
  ; Conversion au format hexa / remplacement des espaces par des "0"
  codeFinal.s=ReplaceString(code3+code1+code2," ","0")
  
  ProcedureReturn codeFinal.s
EndProcedure

;/ test
; Debug GUID()





;} GUID (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                IsNetDrive                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ IsNetDrive (Start)                                            
; Test if a Drive is a Network Drive

; Returns 0 If the specified Drive is not a network Drive. 
; Returns 1 If the specified Drive is a network Drive that is properly connected. 
; Returns 2 If the specified Drive is a network Drive that is disconnected Or in an error state

ProcedureDLL IsNetDrive(Drive.s)
  Drive.s=UCase(Drive)
  Drive=Left(Drive,1)
  If Asc(Drive)>64 And Asc(Drive)<91 ; Compris entre A et Z
    DriveNum=(Asc(Drive))-65
    retour=IsNetDrive_(DriveNum)
  EndIf
  ProcedureReturn retour
  
EndProcedure

;/ Test
; Drive.s="L:"
; Select IsNetDrive(Drive)
  ; Case 0
    ; MessageRequester(Drive,"Drive is not a network Drive")
  ; Case 1
    ; MessageRequester(Drive,"Drive is a network Drive that is properly connected")
  ; Case 2
    ; MessageRequester(Drive,"Drive is a network Drive that is disconnected")
; EndSelect


;} IsNetDrive (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               IsUserAnAdmin                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ IsUserAnAdmin (Start)                                         

; Require W2K or above

ProcedureDLL IsUserAnAdmin()
  ; Changed in 1.2 because don't work with Impersonate : This version Works great
  ret = OpenSCManager_(#Null,#Null,#SC_MANAGER_ALL_ACCESS) 
  If ret 
    CloseServiceHandle_(ret) 
  EndIf 
  If ret>0 : ret =1 : EndIf
  ProcedureReturn ret 
EndProcedure

;/ Test
; If  IsUserAnAdmin()
  ; MessageRequester("User is","Administrator")
; Else
  ; MessageRequester("User is","Simple User")
; EndIf



;} IsUserAnAdmin (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                KillProcess                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ KillProcess (Start)                                           
; English forum: http://purebasic.myforums.net/viewtopic.php?t=8086&start=15
; Author: Hi-Toro tweaked by Droopy
; Date: 30. November 2003

; Return 1 if success / 0 if fail ( or proccess name don't exist )

#PROCESS_TERMINATE = $1 
#PROCESS_CREATE_THREAD = $2 
#PROCESS_VM_OPERATION = $8 
#PROCESS_VM_READ = $10 
#PROCESS_VM_WRITE = $20 
#PROCESS_DUP_HANDLE = $40 
#PROCESS_CREATE_PROCESS = $80 
#PROCESS_SET_QUOTA = $100 
#PROCESS_SET_INFORMATION = $200 
#PROCESS_QUERY_INFORMATION = $400 
#PROCESS_ALL_ACCESS = #STANDARD_RIGHTS_REQUIRED | #SYNCHRONIZE | $FFF 

ProcedureDLL KillProcess(PID) 
  phandle = OpenProcess_ (#PROCESS_TERMINATE, #False, PID) 
  If phandle <> #Null 
    If TerminateProcess_ (phandle, 1) 
      Result = #True 
    EndIf 
    CloseHandle_ (phandle) 
  EndIf 
  ProcedureReturn Result 
EndProcedure 


;/ Test
; Debug KillProcess( x )
 

;} KillProcess (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                NetUserAdd                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetUserAdd (Start)                                            
; PureBasic 3.92
; Add a User to the Local Workstation
; Traumatic Code tweaked by Droopy 02/05/05

; Sucess return 1 / if creation fail the function return 

;    0 Other errors
;   -1 Access Denied ( you are not an Administrator or a User manager )
;   -2 User exist
;   -3 Password is empty / Password too short than required ( Security )

; The user is in no Group after creation

Structure USER_INFO_1 
  name.l 
  Password.l 
  password_age.l 
  priv.l 
  home_dir.l 
  comment.l 
  flags.l 
  script_path.l 
EndStructure 

;/ Need Procedure.l L(string.s)  

ProcedureDLL NetUserAdd(Username.s,Password.s)
  
  retour=0
  
  If Password="" : retour=-3 : EndIf ; Return password too short 
  If Password<>"" ; Si password vide ne rien faire ( sinon plante )
    
    ui.USER_INFO_1 
    
    dwLevel.l = 1 
    dwError.l = 0 
    
    CompilerIf #PB_Compiler_Unicode = 0
      ui\Name = L(Username) 
      ui\Password = L(Password) 
    CompilerElse
      ui\Name = @Username
      ui\Password = @Password
    CompilerEndIf
    ui\priv = 1 
    ui\flags = 1 
    
    netapi = OpenLibrary(#PB_Any,"Netapi32.dll")
    func = GetFunction(netapi, "NetUserAdd")
    retour = CallFunctionFast(func,#NUL, dwLevel, @ui, @dwError)
    CloseLibrary(netapi)
    
    Select retour
      Case 0
        retour=1
      Case 5      ; Access Denied
        retour=-1
      Case 2224   ; UserExists
        retour =-2
      Case 2245   ; Password too short
        retour=-3
      Default
        retour=0  ; Other errors
    EndSelect
    
  EndIf
  
  ProcedureReturn retour
EndProcedure



;} NetUserAdd (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                NetUserDel                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NetUserDel (Start)                                            
; Delete a local User
; Return 1 if success / 
;  0 if error
; -1 if Access Denied
; -2 if User not found

;/ Need Procedure.l L(string.s) 

ProcedureDLL NetUserDel(Name.s)
  
  retour=NetUserDel_(0,Name)
  Debug retour
  
  Select retour
    Case 0
      retour=1
    Case 5
      retour =-1 ; Access Denied
    Case 2221
      retour=-2 ; User not found
    Default
      retour=0
  EndSelect
  
  ProcedureReturn retour
EndProcedure





;} NetUserDel (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 Registry                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Registry (Start)                                              
; WebCode Tweaked by Droopy
; Read & Change the Registry
; Can read & Write #REG_SZ #REG_DWORD #REG_BINARY #REG_EXPAND_SZ( Return Hex Value / Write Hex Value )

Procedure RegConvertRegKeyToTopKey(Key.s)
  
  topKey.s=StringField(Key,1,"\")
  topKey=UCase(topKey)
  
  Select topKey
    
    Case "HKEY_CLASSES_ROOT"
      retour=#HKEY_CLASSES_ROOT
      
    Case "HKEY_CURRENT_USER"
      retour=#HKEY_CURRENT_USER
      
    Case "HKEY_LOCAL_MACHINE"
      retour=#HKEY_LOCAL_MACHINE
      
    Case "HKEY_USERS"
      retour=#HKEY_USERS 
      
    Case "HKEY_CURRENT_CONFIG"
      retour=#HKEY_CURRENT_CONFIG 
      
  EndSelect
  
  ProcedureReturn retour
  
EndProcedure

Procedure.s RegConvertRegKeyToKeyName(Key.s)
  PositionSlash=FindString(Key,"\",1)
  retour.s=Right(Key,(Len(Key)-PositionSlash))
  ProcedureReturn retour
EndProcedure

ProcedureDLL RegSetValue(Key.s, ValueName.s, Value.s, Type, ComputerName.s) ;  OK
  
  ; Return 1 if success / 0 if fail
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  lpData.s 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKeyEx_(topKey, KeyName, 0, #KEY_ALL_ACCESS, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKeyEx_(lhRemoteRegistry, KeyName, 0, #KEY_ALL_ACCESS, @hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbData = 255 
    lpData = Space(255) 
    
    Select Type 
      
      Case #REG_EXPAND_SZ 
        GetHandle = RegSetValueEx_(hKey, ValueName, 0, #REG_EXPAND_SZ, @Value, StringByteLength(Value) + 1) 
        
      Case #REG_SZ 
        GetHandle = RegSetValueEx_(hKey, ValueName, 0, #REG_SZ, @Value, StringByteLength(Value) + 1) 
        
      Case #REG_DWORD 
        lValue = Val(Value) 
        GetHandle = RegSetValueEx_(hKey, ValueName, 0, #REG_DWORD, @lValue, 4) 
        
      Case #REG_BINARY
        LenBuffer=Len(Value)/2
        *RegBuffer=AllocateMemory(LenBuffer)
        For n=0 To LenBuffer-1
          OctetHexa.s=Mid(Value,(n*2)+1,2)
          Octet=Hex2Dec(OctetHexa)
          PokeB(*RegBuffer+n,Octet)
        Next
        GetHandle= RegSetValueEx_(hKey,ValueName,0,#REG_BINARY,*RegBuffer,LenBuffer) 
        FreeMemory(*RegBuffer)
        
    EndSelect 
    
    RegCloseKey_(hKey) 
    ergebnis = 1 
    ProcedureReturn ergebnis 
  Else 
    RegCloseKey_(hKey) 
    ergebnis = 0 
    ProcedureReturn ergebnis 
  EndIf 
EndProcedure 

Procedure.s RegGetValue_int(Key.s, ValueName.s, ComputerName.s) ;  OK
  
  ; Return an empty string if key or value don't exist
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  lpData.s 
  GetValue.s ="" 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName,@hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbData = 255 
    lpData = Space(255) 
    
    GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @Type, @lpData, @lpcbData) 
    
    If GetHandle = #ERROR_SUCCESS 
      
      Select Type 
        Case #REG_SZ 
          
          GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @Type, @lpData, @lpcbData) 
          
          If GetHandle = 0 
            GetValue = Left(lpData, lpcbData - 1) 
          Else 
            GetValue = "" 
          EndIf 
          
        Case #REG_EXPAND_SZ 
          
          GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @Type, @lpData, @lpcbData) 
          
          If GetHandle = 0 
            GetValue = Left(lpData, lpcbData - 1) 
          Else 
            GetValue = "" 
          EndIf 
          
          
          
        Case #REG_DWORD 
          GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @lpType, @lpDataDWORD, @lpcbData) 
          
          If GetHandle = 0 
            GetValue = Str(lpDataDWORD) 
          Else 
            GetValue = "0" 
          EndIf 
          
        Case #REG_BINARY 
          BinaryBytes=1024
          *RegBinary=AllocateMemory(BinaryBytes) 
          GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @lType, *RegBinary, @BinaryBytes) 
          If GetHandle = 0 ; SUCCESS
            GetValue=""
            For i = 0 To (BinaryBytes-1 )
              Temp3=PeekB(*RegBinary+i)&$000000FF
              If Temp3<16 : GetValue+"0" : EndIf
              GetValue+ Hex(Temp3)
            Next 
            FreeMemory(*RegBinary)
          EndIf 
          
      EndSelect 
    EndIf 
  EndIf 
  RegCloseKey_(hKey) 
  ProcedureReturn GetValue 
EndProcedure 

ProcedureDLL.s RegGetValue(Key.s, ValueName.s, ComputerName.s) ;  OK
  ProcedureReturn RegGetValue_int(key, valuename, computername)
EndProcedure

ProcedureDLL RegGetType(Key.s, ValueName.s, ComputerName.s) ;  OK
  
  ; Return -1 if key or value don't exist / Code of Key Type #REG_SZ #REG_BINARY #REG_DWORD ...
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  lpData.s 
  GetValue.s ="" 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName, @hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbData = 255 
    lpData = Space(255) 
    
    GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @Type, @lpData, @lpcbData) 
    
    zz=-1
    If GetHandle = #ERROR_SUCCESS : zz=Type : EndIf 
    
  EndIf 
  RegCloseKey_(hKey) 
  ProcedureReturn zz
EndProcedure 

Procedure.s RegListSubKey_int(Key.s, index, ComputerName.s) ;  OK
  
  ; Retourne la sous clé qui a l'index ( Index à incrémenter de 0 à ? )
  ; Quand plus de sous clé : chaine vide en retour
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  lpName.s 
  lpftLastWriteTime.FILETIME 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName, @hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbName = 255 
    lpName = Space(255) 
    
    GetHandle = RegEnumKeyEx_(hKey, Index, @lpName, @lpcbName, 0, 0, 0, @lpftLastWriteTime) 
    
    If GetHandle = #ERROR_SUCCESS 
      ListSubKey.s = Left(lpName, lpcbName) 
    Else 
      ListSubKey.s = "" 
    EndIf 
  EndIf 
  RegCloseKey_(hKey) 
  ProcedureReturn ListSubKey 
EndProcedure 

ProcedureDLL.s RegListSubKey(Key.s, index, ComputerName.s) ;  OK
  ProcedureReturn RegListSubKey_int(key, index, computername)
EndProcedure

ProcedureDLL RegDeleteValue(Key.s, ValueName.s, ComputerName.s) ;  OK
  
  ; Return 1 if success / 0 if fail
  ; return 0 if key don't exist
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKeyEx_(topKey, KeyName, 0, #KEY_ALL_ACCESS, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKeyEx_(lhRemoteRegistry, KeyName, 0, #KEY_ALL_ACCESS, @hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    GetHandle = RegDeleteValue_(hKey, @ValueName) 
    If GetHandle = #ERROR_SUCCESS 
      DeleteValue = #True 
    Else 
      DeleteValue = #False 
    EndIf 
  EndIf 
  RegCloseKey_(hKey) 
  ProcedureReturn DeleteValue 
EndProcedure 

ProcedureDLL RegCreateKey(Key.s, ComputerName.s) ;  OK
  
  ; Return 1 if succes / 0 if fail
  ; It create subkey if KeyPath don't exist
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  lpSecurityAttributes.SECURITY_ATTRIBUTES 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegCreateKeyEx_(topKey, KeyName, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_ALL_ACCESS, @lpSecurityAttributes, @hNewKey, @GetHandle) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegCreateKeyEx_(lhRemoteRegistry, KeyName, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_ALL_ACCESS, @lpSecurityAttributes, @hNewKey, @GetHandle) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    GetHandle = RegCloseKey_(hNewKey) 
    CreateKey = #True 
  Else 
    CreateKey = #False 
  EndIf 
  ProcedureReturn CreateKey 
EndProcedure 

ProcedureDLL RegDeleteKey(Key.s, ComputerName.s) ;  OK
  
  ; Return 1 if succes / 0 if fail
  ; Key must be empty
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegDeleteKey_(topKey, @KeyName) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegDeleteKey_(lhRemoteRegistry, @KeyName) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    DeleteKey = #True 
  Else 
    DeleteKey = #False 
  EndIf 
  ProcedureReturn DeleteKey 
EndProcedure 

Procedure.s RegListSubValue_int(Key.s, index, ComputerName.s) ;  OK
  
  ; return an empty string if key don't exit
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  lpName.s 
  lpftLastWriteTime.FILETIME 
  ListSubValue.s 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName,@hKey) 
  EndIf 
  
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbName = 255 
    lpName = Space(255) 
    
    GetHandle = RegEnumValue_(hKey, Index, @lpName, @lpcbName, 0, 0, 0, 0) 
    
    If GetHandle = #ERROR_SUCCESS 
      ListSubValue = Left(lpName, lpcbName) 
    Else 
      ListSubValue = "" 
    EndIf 
    RegCloseKey_(hKey) 
  EndIf 
  ProcedureReturn ListSubValue 
EndProcedure 

ProcedureDLL.s RegListSubValue(Key.s, index, ComputerName.s) ;  OK
  ProcedureReturn RegListSubValue_int(key, index, computername)
EndProcedure

ProcedureDLL.b RegKeyExists(Key.s, ComputerName.s) ;  OK
  
  ; Return 1 if succes / 0 if fail
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName, @hKey) 
  EndIf 
  
  If GetHandle = #ERROR_SUCCESS 
    KeyExists = #True 
  Else 
    KeyExists = #False 
  EndIf 
  ProcedureReturn KeyExists 
EndProcedure 

Procedure RegDeleteKeyWithAllSubInternal(Key.s,ComputerName.s) ;/ OK (Internal )
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  
  i=0 
  a$="" 
  Repeat 
    b$=a$ 
    a$=RegListSubKey_int(Key,0,"") 
    If a$<>"" 
      RegDeleteKeyWithAllSubInternal(Key+"\"+a$,"") 
    EndIf 
  Until a$=b$ 
  RegDeleteKey(Key, ComputerName) 
EndProcedure 

ProcedureDLL RegDeleteKeyWithAllSub(Key.s,ComputerName.s);  OK
  
  ; Return 1 if success / 0 if fail ( Or key to delete don't exist )
  
  retour1 = RegKeyExists(Key.s,ComputerName.s)
  retour2+ RegDeleteKeyWithAllSubInternal(Key,ComputerName)
  
  If retour1=1 And  retour2=0 : retour=1 : EndIf
  
  ProcedureReturn retour
EndProcedure

ProcedureDLL RegCreateKeyValue(Key.s,ValueName.s,Value.s,Type,ComputerName.s) ;  OK
  
  ; Return 1 if succes / 0 if fail
  
  RegCreateKey(Key,ComputerName) 
  ProcedureReturn RegSetValue(Key,ValueName,Value,Type,ComputerName) 
EndProcedure 

ProcedureDLL RegValueExists(Key.s, ValueName.s, ComputerName.s) ;  OK
  
  topKey=RegConvertRegKeyToTopKey(Key)
  KeyName.s=RegConvertRegKeyToKeyName(Key)
  lpData.s 
  GetValue.s ="" 
  
  If Left(KeyName, 1) = "\" 
    KeyName = Right(KeyName, Len(KeyName) - 1) 
  EndIf 
  
  If ComputerName = "." 
    GetHandle = RegOpenKey_(topKey, KeyName, @hKey) 
  Else 
    lReturnCode = RegConnectRegistry_(ComputerName, topKey, @lhRemoteRegistry) 
    GetHandle = RegOpenKey_(lhRemoteRegistry, KeyName, @hKey) 
  EndIf 
  
  retour=0
  
  If GetHandle = #ERROR_SUCCESS 
    lpcbData = 255 
    lpData = Space(255) 
    
    GetHandle = RegQueryValueEx_(hKey, ValueName, 0, @Type, @lpData, @lpcbData) 
    
    If GetHandle = #ERROR_SUCCESS 
      
      retour=1
      
    EndIf 
  EndIf 
  RegCloseKey_(hKey) 
  ProcedureReturn retour 
EndProcedure

;/ Binary Test
; Debug RegSetValue("HKEY_LOCAL_MACHINE\SOFTWARE\BIN","Test","0123456789",#REG_BINARY,".")
; Debug RegGetValue("HKEY_LOCAL_MACHINE\SOFTWARE\BIN","Test",".")
; Debug RegSetValue("HKEY_LOCAL_MACHINE\SOFTWARE\BIN","Test2","00FF00AABB",#REG_BINARY,".")
; Debug RegGetValue("HKEY_LOCAL_MACHINE\SOFTWARE\BIN","Test2",".")
; Debug "---------"
; Debug RegGetType("HKEY_LOCAL_MACHINE\SOFTWARE\BIN","Test2",".")
; Debug #REG_BINARY
  


;/ Test
; ; Create the Test Key
; Debug "Create Key"
; Debug RegCreateKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test",".")
; 
; ; Write Value
; Debug "         Write Value"
; Debug RegSetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test","SZ Value","SZ",#REG_SZ,".")
; Debug RegSetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test","DWord Value","155",#REG_DWORD,".")
; 
; ; Read Value
; Debug "         Read Value"
; Debug RegGetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test","SZ Value",".")
; Debug RegGetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test","DWord Value",".")
; 
; ; Create SubKey
; Debug "         Create SubKey"
; Debug RegCreateKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test\SubKey1",".")
; Debug RegCreateKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test\SubKey2",".")
; 
; ; List SubKey
; Debug "         List SubKey"
; Index=0
; While RegListSubKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test",Index,".")<>""
  ; Debug RegListSubKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test",Index,".")
  ; Index+1
; Wend
; 
; ; Delete Key
; Debug "         Delete Key"
; Debug RegDeleteKey("HKEY_LOCAL_MACHINE\SOFTWARE\Test\SubKey1",".")
; 
; ; List Value Name
; Debug "         List Value Name"
; Index=0
; While RegListSubValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test",Index,".")<>""
  ; Debug RegListSubValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test",Index,".")
  ; Index+1
; Wend
; 
; ; Delete Value
; Debug "         Delete Value"
; Debug RegDeleteValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test","SZ Value",".")
; 
; ; Test if key exist
; Debug "         Test if key exist"
; Debug RegKeyExists("HKEY_LOCAL_MACHINE\SOFTWARE\Test\SubKey2",".")
; 
; ; Create a key and a value in a unique command
; Debug "         Create a key and a value in a unique command"
; Debug RegCreateKeyValue("HKEY_LOCAL_MACHINE\SOFTWARE\Test\SubKeyAuto","SZ Value","SZ",#REG_SZ,".")
; 
; ; Delete Key with all its Sub and its value
; Debug "Delete Key with all its Sub and its value"
; Debug RegDeleteKeyWithAllSub("HKEY_LOCAL_MACHINE\SOFTWARE\Test",".")


;} Registry (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                ShowDesktop                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ShowDesktop (Start)                                           
; Auteur : Inconnu
; Version de PB : 3.90
;
; Explication du programme :
; Réduire toutes les fenêtres dans la barre des tâches

ProcedureDLL ShowDesktop()
  retour=SendMessage_ (FindWindow_("Shell_TrayWnd", NULL), $111, 419, 0)
  If retour<>0 : retour =0 : Else : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test
; Debug ShowDesktop()

;} ShowDesktop (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.2 FUNCTIONS ADDON
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                            BackgroundTransfert                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ BackgroundTransfert (Start)                                   
; Droopy 07/05/05
; PureBasic 3.93

;/ BackgroundTransfertInit(SourceFile.s,DestinationFile.s,PacketSize,Frequency)
; Initialise the Lib
; Return 1 if SourceFile Exist / Enought free space avalaible @ Target Destination

;/ BackgroundTransfertState()
; Return 0 if transfert not finished / not started 
; 1 Transfert finished 
; -1 Error Reading Source File or Writing Destination File ( Transfert stopped ! )

;/ BackGroundTransfertStart()
; Start the Background Transfert

;/ BackGroundTransfertStop()
; Stop the Background Transfert

;/ BackGroundTransfertPercentage()
; Get the transfert state in percentage

;/ BackGroundTransfertVerify()
; When transfert finished, this function test if source = destination : 1 = true

#BGTimerId=0

ProcedureDLL BackGroundTransfertStop(windowid)
  TimerKill(#BGTimerId, windowid)
EndProcedure

ProcedureDLL BackgroundTransfertInit(SourceFile.s,DestinationFile.s,PacketSize,Frequency)
  BGTSource=SourceFile
  BGTDestination=DestinationFile
  BGTTaillePaquets=PacketSize
  BGTTempo=Frequency
  BGTFlag=0
  retour=1
  
  
  If FileSize(BGTSource)=-1 
    retour=0 ; File does not exist
  Else
    ; Source file exist
    ; Test if there is enought space for file copy
    ResteACopier=FileSize(BGTSource)
    If FileSize(BGTDestination)>0 : ResteACopier-FileSize(BGTDestination):EndIf
    ResteACopier/1024/1024
    
    Drive.s=Left(BGTDestination,2)
    SpaceNeeded=GetDiskFreeSpaceEx(Drive)
    SpaceNeeded-ResteACopier
    
    If SpaceNeeded<=0 : retour=0 : EndIf 
  EndIf
  
  ProcedureReturn retour
EndProcedure

ProcedureDLL BackgroundTransfertState()
  ProcedureReturn BGTFlag
EndProcedure

Procedure BackgroundTransfertOnePacket(windowid)
  
  OpenFile(0,BGTSource)
  BGTTailleSource=Lof(0)
  OpenFile(1,BGTDestination.s)
  BGTTailleDestination=Lof(0)
  
  DebutCopie=BGTTailleDestination
  If DebutCopie=BGTTailleSource 
    BGTFlag=1 ; On a déjà tout copié on quitte
    CloseFile(1)
    CloseFile(0)
    BackGroundTransfertStop(windowid) ; Stop Timer when finished
  Else
    
    FinCopie=DebutCopie+BGTTaillePaquets
    If FinCopie>BGTTailleSource : FinCopie=BGTTailleSource : EndIf
    
    OctetsALire=FinCopie-DebutCopie
    *Tampon=AllocateMemory(OctetsALire)
    
    ;UseFile(0)
    FileSeek(0, DebutCopie)
    retour=ReadData(0, *Tampon,OctetsALire)
    
    If retour<>OctetsALire ; Tout n'a pas été lu
      BGTFlag=-1
      CloseFile(0)
      CloseFile(1)
      BackGroundTransfertStop(windowid)
    EndIf
    
    ;UseFile(1)
    FileSeek(1, Lof(1))
    WriteData(1, *Tampon,OctetsALire)
    
    CloseFile(1)
    CloseFile(0)
    
    ; Si l'écriture s'est mal passée
    If FileSize(BGTDestination)<>BGTTailleDestination+OctetsALire
      BGTFlag=-1
      CloseFile(0)
      CloseFile(1)
      BackGroundTransfertStop(windowid)
    EndIf  
    
  EndIf
  
  ProcedureReturn BGTFlag
  
EndProcedure

ProcedureDLL BackGroundTransfertStart(windowid) ; Lance le transfert ( Lance le Timer )
  BGTTimerId=Timer(#BGTimerId,BGTTempo, @BackgroundTransfertOnePacket(), windowid)
EndProcedure

ProcedureDLL BackGroundTransfertPercentage()
  retour.f=(BGTTailleDestination/BGTTailleSource)*100
  If BGTFlag=1 : retour=100 : EndIf
  ProcedureReturn retour
EndProcedure

ProcedureDLL BackGroundTransfertVerify()
  If MD5FileFingerprint(BGTSource) = MD5FileFingerprint(BGTDestination) : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test

; If BackgroundTransfertInit("c:\Sp2.msi","c:\Copie.msi",1024*256,100)=0
  ; MessageRequester("Erreur","Fichier source inexistant ou manque de place !")
  ; End
; EndIf
; 
; BackGroundTransfertStart()
; 
; OpenWindow(0,0,0,320,160,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"Background Transfert") And CreateGadgetList(WindowID(0))
; TextGadget       (0, 10, 10,250, 20, "0 %",#PB_Text_Center)
; ProgressBarGadget(1, 10, 30,250, 30, 0,100,#PB_ProgressBar_Smooth )
; 
; Repeat
  ; Delay(10)
  ; SetGadgetState   (1, BackGroundTransfertPercentage())   ; set 1st progressbar (ID = 0) to 50 of 100
  ; SetGadgetText(0,Str(BackGroundTransfertPercentage())+"%")
; Until WindowEvent()=#PB_Event_CloseWindow Or BackgroundTransfertState()<>0
; 
; If BackgroundTransfertState()=1 And BackGroundTransfertVerify()
  ; MessageRequester("Transfert","Finished and Correct")
; EndIf
  ; 
; If BackgroundTransfertState()=1 And Not(BackGroundTransfertVerify())
  ; MessageRequester("Transfert","Finished and Incorrect")
; EndIf
; 
; ; Error  
; If BackgroundTransfertState()=-1
  ; MessageRequester("Transfert","Stopped ( Serious Error )")
; EndIf





;} BackgroundTransfert (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetSpecialFolders                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetSpecialFolders (Start)                                     
; Code from Soldat Inconnu tweaked by droopy
; PureBasic 3.93

; Get Name / Folder of Windows Special Folders

ProcedureDLL.s GetSpecialFolderLocation(Valeur.l) 
  If SHGetSpecialFolderLocation_(0, Valeur, @Dossier_ID) = 0 
    SpecialFolderLocation.s = Space(#MAX_PATH) 
    SHGetPathFromIDList_(Dossier_ID, @SpecialFolderLocation) 
    If SpecialFolderLocation 
      If Right(SpecialFolderLocation, 1) <> "\" 
        SpecialFolderLocation + "\" 
      EndIf 
    EndIf 
  EndIf 
  ProcedureReturn SpecialFolderLocation.s 
EndProcedure 

;/Test
; For n=0 To 64
  ; If GetSpecialFolderLocation(n) ="" : Continue : EndIf
  ; Debug Str(n) + " "+GetSpecialFolderLocation(n)
; Next


; ;  French XP
; 0 C:\Documents And Settings\Username\Bureau\
; 2 C:\Documents And Settings\Username\Menu Démarrer\Programmes\
; 5 C:\Documents And Settings\Username\Mes Documents\
; 6 D:\Ghost\favoris\
; 7 C:\Documents And Settings\Username\Menu Démarrer\Programmes\Démarrage\
; 8 C:\Documents And Settings\Username\Recent\
; 9 C:\Documents And Settings\Username\SendTo\
; 11 C:\Documents And Settings\Username\Menu Démarrer\
; 13 C:\Documents And Settings\Username\Mes Documents\Ma musique\
; 16 C:\Documents And Settings\Username\Bureau\
; 19 C:\Documents And Settings\Username\Voisinage réseau\
; 20 C:\WINDOWS\Fonts\
; 21 C:\Documents And Settings\Username\Modèles\
; 22 C:\Documents And Settings\All Users\Menu Démarrer\
; 23 C:\Documents And Settings\All Users\Menu Démarrer\Programmes\
; 24 C:\Documents And Settings\All Users\Menu Démarrer\Programmes\Démarrage\
; 25 C:\Documents And Settings\All Users\Bureau\
; 26 C:\Documents And Settings\Username\Application Data\
; 27 C:\Documents And Settings\Username\Voisinage D'impression\
; 28 C:\Documents And Settings\Username\Local Settings\Application Data\
; 31 C:\Documents And Settings\All Users\favoris\
; 32 C:\Documents And Settings\Username\Local Settings\Temporary Internet Files\
; 33 C:\Documents And Settings\Username\Cookies\
; 34 C:\Documents And Settings\Username\Local Settings\Historique\
; 35 C:\Documents And Settings\All Users\Application Data\
; 36 C:\WINDOWS\
; 37 C:\WINDOWS\system32\
; 38 C:\Program Files\
; 39 C:\Documents And Settings\Username\Mes Documents\Mes images\
; 40 C:\Documents And Settings\Username\
; 41 C:\WINDOWS\system32\
; 43 C:\Program Files\Fichiers communs\
; 45 C:\Documents And Settings\All Users\Modèles\
; 46 C:\Documents And Settings\All Users\Documents\
; 47 C:\Documents And Settings\All Users\Menu Démarrer\Programmes\Outils D'administration\
; 53 C:\Documents And Settings\All Users\Documents\Ma musique\
; 54 C:\Documents And Settings\All Users\Documents\Mes images\
; 55 C:\Documents And Settings\All Users\Documents\Mes vidéos\
; 56 C:\WINDOWS\Resources\
; 59 C:\Documents And Settings\Username\Local Settings\Application Data\Microsoft\CD Burning\
; 
; ;  English XP
; 0 C:\Documents And Settings\Username\Desktop\ 
; 2 C:\Documents And Settings\Username\start Menu\Programs\ 
; 5 C:\Documents And Settings\Username\My Documents\ 
; 6 C:\Documents And Settings\Username\Favorites\ 
; 7 C:\Documents And Settings\Username\start Menu\Programs\Startup\ 
; 8 C:\Documents And Settings\Username\Recent\ 
; 9 C:\Documents And Settings\Username\SendTo\ 
; 11 C:\Documents And Settings\Username\start Menu\ 
; 13 C:\Documents And Settings\Username\My Documents\My Music\ 
; 16 C:\Documents And Settings\Username\Desktop\ 
; 19 C:\Documents And Settings\Username\NetHood\ 
; 20 C:\WINDOWS\Fonts\ 
; 21 C:\Documents And Settings\Username\Templates\ 
; 22 C:\Documents And Settings\All Users\start Menu\ 
; 23 C:\Documents And Settings\All Users\start Menu\Programs\ 
; 24 C:\Documents And Settings\All Users\start Menu\Programs\Startup\ 
; 25 C:\Documents And Settings\All Users\Desktop\ 
; 26 C:\Documents And Settings\Username\Application Data\ 
; 27 C:\Documents And Settings\Username\PrintHood\ 
; 28 C:\Documents And Settings\Username\Local Settings\Application Data\ 
; 31 C:\Documents And Settings\All Users\Favorites\ 
; 32 C:\Documents And Settings\Username\Local Settings\Temporary Internet Files\ 
; 33 C:\Documents And Settings\Username\Cookies\ 
; 34 C:\Documents And Settings\Username\Local Settings\History\ 
; 35 C:\Documents And Settings\All Users\Application Data\ 
; 36 C:\WINDOWS\ 
; 37 C:\WINDOWS\system32\ 
; 38 C:\Program Files\ 
; 39 C:\Documents And Settings\Username\My Documents\My Pictures\ 
; 40 C:\Documents And Settings\Username\ 
; 41 C:\WINDOWS\system32\ 
; 43 C:\Program Files\Common Files\ 
; 45 C:\Documents And Settings\All Users\Templates\ 
; 46 C:\Documents And Settings\All Users\Documents\ 
; 47 C:\Documents And Settings\All Users\start Menu\Programs\Administrative Tools\ 
; 53 C:\Documents And Settings\All Users\Documents\My Music\ 
; 54 C:\Documents And Settings\All Users\Documents\My Pictures\ 
; 56 C:\WINDOWS\Resources\ 
; 59 C:\Documents And Settings\Username\Local Settings\Application Data\Microsoft\CD Burning\
; 
; ;  French Windows 98
; 0 C:\WINDOWS\Bureau\
; 2 C:\WINDOWS\Menu Démarrer\Programmes\
; 5 C:\Mes Documents\
; 6 C:\WINDOWS\favoris\
; 7 C:\WINDOWS\Menu Démarrer\Programmes\Démarrage\
; 8 C:\WINDOWS\Recent\
; 9 C:\WINDOWS\SendTo\
; 11 C:\WINDOWS\Menu Démarrer\
; 16 C:\WINDOWS\Bureau\
; 19 C:\WINDOWS\Voisinage réseau\
; 20 C:\WINDOWS\Fonts\
; 21 C:\WINDOWS\ShellNew\
; 26 C:\WINDOWS\Application Data\
; 27 C:\WINDOWS\PrintHood\
; 32 C:\WINDOWS\Temporary Internet Files\
; 33 C:\WINDOWS\Cookies\
; 34 C:\WINDOWS\Historique\


;} GetSpecialFolders (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           GetSystemPowerStatus                            |
;  |                           ____________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetSystemPowerStatus (Start)                                  
; PureBasic 3.92
; Droopy 08/05/05

;/  Utilise la Structure : SYSTEM_POWER_STATUS ( définie ds Pure par défaut ))

ProcedureDLL GetPowerStatus()
  
  ; Return 0 Offline / 1 Online / 255 unknown
  
  GetSystemPowerStatus_(@SystemPowerStatus.SYSTEM_POWER_STATUS)
  ProcedureReturn SystemPowerStatus\ACLineStatus
EndProcedure

ProcedureDLL GetBatteryChargeStatus()
  
  ; Return 1	High / 2	Low / 4	Critical / 8	Charging / 128	No system battery / 255 Unknown
  
  GetSystemPowerStatus_(@SystemPowerStatus.SYSTEM_POWER_STATUS)
  ProcedureReturn SystemPowerStatus\BatteryFlag
EndProcedure

ProcedureDLL GetBatteryLifePercent()
  
  ; Return Percentage of full battery charge remaining
  
  GetSystemPowerStatus_(@SystemPowerStatus.SYSTEM_POWER_STATUS)
  ProcedureReturn SystemPowerStatus\BatteryLifePercent
EndProcedure 

ProcedureDLL GetBatteryLifeTime()
  
  ; Return Number of seconds of battery life remaining : -1 Unknown
  
  GetSystemPowerStatus_(@SystemPowerStatus.SYSTEM_POWER_STATUS)
  ProcedureReturn (SystemPowerStatus\BatteryLifeTime)/60
EndProcedure 

ProcedureDLL GetBatteryFullLifeTime()
  
  ; Number of seconds of battery life when at full charge : -1 Unknown
  
  GetSystemPowerStatus_(@SystemPowerStatus.SYSTEM_POWER_STATUS)
  ProcedureReturn (SystemPowerStatus\BatteryFullLifeTime)/60
EndProcedure

;/ Test
; 
; If GetPowerStatus()
  ; MessageRequester("Status","Online")
; Else
  ; MessageRequester("Status","Offline")
  ; MessageRequester("Percent",Str(GetBatteryLifePercent()))
  ; If GetBatteryLifeTime()<>-1 
    ; MessageRequester("Battery Life Time",FormatDate("%hh:%ii:%ss", GetBatteryLifeTime()))
  ; EndIf
  ; 
  ; If GetBatteryFullLifeTime()<>-1
    ; MessageRequester("Battery Full Life Time",FormatDate("%hh:%ii:%ss", GetBatteryFullLifeTime()))
  ; EndIf
; EndIf
  ; 
; If GetBatteryChargeStatus() & 1
  ; MessageRequester("Charge Status","High")
; EndIf
  ; 
; If GetBatteryChargeStatus() & 2
  ; MessageRequester("Charge Status","Low")
; EndIf
  ; 
; If GetBatteryChargeStatus() & 4
  ; MessageRequester("Charge Status","Critical")
; EndIf
  ; 
; If GetBatteryChargeStatus() & 128
  ; MessageRequester("Charge Status","No System Battery")
; EndIf

  

;} GetSystemPowerStatus (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          InputPasswordRequester                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ InputPasswordRequester (Start)                                
; PureBasic 3.93
; Droopy 12/05/05 / Baldrick 26/09/05
; Same as InputRequester but for Password 
; Return Password

ProcedureDLL.s InputPasswordRequester(Title.s)
  
  Temp=OpenWindow(#PB_Any, 398, 199, 152, 98   , Title, #PB_Window_WindowCentered |#PB_Window_ScreenCentered)
  ;CreateGadgetList(WindowID(temp))
  string = StringGadget(#PB_Any, 10, 10, 130, 20, "",#PB_String_Password)
  button = ButtonGadget(#PB_Any, 10, 40, 130, 50, "OK")
  SetActiveGadget(string)
  
  Repeat 
    Event = WaitWindowEvent()
  Until EventGadget() =button Or EventwParam()=#VK_RETURN
  
  Password.s=GetGadgetText(string)
  CloseWindow(Temp)
  ProcedureReturn Password
EndProcedure

;/ Test
; Password.s=InputPasswordRequester("Mot de passe")


;} InputPasswordRequester (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             SetWindowAboveAll                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SetWindowAboveAll (Start)                                     
; Idea from : Le Soldat Inconnu
; Version de PB : 3.93

; Places the Window above all non-topmost windows
; Return 1 if success / 0 if fail

ProcedureDLL SetWindowAboveAll(handle)
  retour=SetWindowPos_(handle, -1, 0, 0, 0, 0, #SWP_NOSIZE | #SWP_NOMOVE)
  If retour<>0 : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test
; Id=OpenWindow(0, 0, 0, 300, 300, #PB_Window_ScreenCentered | #PB_Window_SystemMenu, "Try to view behind me !")
; SetWindowAboveAll(Id)
; Delay(5000)

  


;} SetWindowAboveAll (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          WaitUntilWindowIsClosed                          |
;  |                          _______________________                          |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WaitUntilWindowIsClosed (Start)                               
; PureBasic 3.93
; Droopy 05/05/05

; Wait until windows is closed
; Return 1 when windows is closed


ProcedureDLL WaitUntilWindowIsClosed()
  Repeat
  Until WaitWindowEvent()= #PB_Event_CloseWindow
  ProcedureReturn 1
EndProcedure

;/ Test
; OpenWindow(0, 100, 200, 300, 200, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered , "PureBasic Window")
; WaitUntilWindowIsClosed()

;} WaitUntilWindowIsClosed (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                WindowEnum                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WindowEnum (Start)                                            
; Author : Le Soldat Inconnu

; List all open Windows by Title
; When retun an empty string : Search is finished

ProcedureDLL.s WindowsEnum()
  Static Flag,hWnd
  
  Repeat
    If Flag=0
      hWnd = FindWindow_( 0, 0 )
      Flag=1
    Else
      hWnd = GetWindow_(hWnd, #GW_HWNDNEXT)
    EndIf
    
    If hWnd <> 0
      If GetWindowLongPtr_(hWnd, #GWL_STYLE) & #WS_VISIBLE = #WS_VISIBLE ; pour lister que les fenêtres visibles
        If GetWindowLongPtr_(hWnd, #GWL_EXSTYLE) & #WS_EX_TOOLWINDOW <> #WS_EX_TOOLWINDOW ; pour lister que les fenêtres qui ne sont pas des ToolWindow ou barre d'outils
          retour.s = Space(256)
          GetWindowText_(hWnd, retour, 256)
          If retour<>"" : Break : EndIf
        EndIf
      EndIf
    Else
      Flag=0 
    EndIf
  Until hWnd=0
  
  ProcedureReturn retour  
EndProcedure

;/ Test
; Repeat
  ; Temp.s=WindowsEnum()
  ; Debug Temp
; Until Temp=""





;} WindowEnum (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               Windows Misc                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Windows Misc (Start)                                          
; PureBasic 3.93
; Auteur : Le Soldat Inconnu ( modifié par Droopy )

; GetHandle : Return the Handle of the Windows specified by name
; Return 0 if windows not found

ProcedureDLL GetHandle(WindowsName.s)
  retour= FindWindow_(0, WindowsName)
  ProcedureReturn retour
EndProcedure


; CloseProgram specified by WindowsName
; 0 don't exist or Error sending message / 1 OK 
ProcedureDLL CloseProgramWindow(WindowsName.s)
  retour = GetHandle(WindowsName)
  If retour <> 0 ; Window Find
    retour = PostMessage_(retour, #WM_CLOSE, 0, 0) ; Close the Window
    If retour<> 0 : retour =1 : EndIf
  EndIf
  ProcedureReturn retour
EndProcedure


; Set Windows Transparency between 1 ( invisible ) and 255 ( visible )
; Works Only with Windows 2000 / XP
; Works for all Windows !
ProcedureDLL SetWindowsTransparency(handle.l, Transparency_Level.l)
  SetWindowLong_(handle, #GWL_EXSTYLE, GetWindowLong_(handle, #GWL_EXSTYLE) | $00080000) ; #WS_EX_LAYERED = $00080000
  user32 = OpenLibrary(#PB_Any, "user32.dll")
  If user32
    func = GetFunction(user32, "SetLayeredWindowAttributes")
    CallFunctionFast(func , handle, 0, Transparency_Level, 2)
    CloseLibrary(user32)
  EndIf
EndProcedure



  
;/ Test  
; RunProgram("calc.exe","","")
; Delay(200)
; handle=GetHandle("calculatrice")
; SetWindowsTransparency(handle,125)
; Delay(2000)
; CloseProgram("Calculatrice")


;} Windows Misc (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.21 FUNCTIONS ADDON
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Flag                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Flag (Start)                                                  
; Droopy
; 21/02/05 / Modified for Droppy's Lib 16/05/05
; PureBasic 3.93
; Flag Management in Registry

; FlagInit        Initialise the Library : Key Specify where to put Flags
                  ; 0 if error / 1 if Success
; FlagSet         Set a Flag value 
; FlagGet         Get Flag Value
; FlagDelete      Delete a Flag
; FlagCreate      Create a Flag ( value = OK )
; FlagExist       Return 1 if Flag exist / 0 instead
; FlagDontExist   Return 1 if Flag don't exist / 0 Instead
; FlagRAZ         Delete All Flags and the Key Specified in FlagInit

ProcedureDLL FlagSet(Flag.s,Value.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  retour=RegSetValue(FlagKey,Flag,Value,#REG_SZ,".")
  ProcedureReturn retour
EndProcedure

ProcedureDLL.s FlagGet(Flag.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn RegGetValue_int(FlagKey,Flag,".")
EndProcedure

ProcedureDLL FlagDelete(Flag.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn RegDeleteValue(FlagKey,Flag,".")
EndProcedure

ProcedureDLL FlagCreate(Flag.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn FlagSet(Flag.s,"OK")
EndProcedure

ProcedureDLL FlagInit(Key.s)
  FlagKey=Key
  
  ; Create the Key
  RegCreateKey(Key.s, ".")
  ; Write a test Key
  FlagSet("Just a test to know if writing is possible","OK")
  ; Read the test Key to know if write success
  If FlagGet("Just a test to know if writing is possible") ="OK"
    retour=1
    ; Delete the Test Key
    FlagDelete("Just a test to know if writing is possible")
  Else
    retour=0
  EndIf
  ProcedureReturn retour  
EndProcedure 

ProcedureDLL FlagExist(Flag.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn RegValueExists(FlagKey,Flag,".")
EndProcedure

ProcedureDLL FlagDontExist(Flag.s)
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn Bool_Not(FlagExist(Flag))
EndProcedure

ProcedureDLL FlagRAZ()
  If FlagKey="" : MessageRequester("Flag Library not initialised","Launch FlagInit Fist",16):EndIf
  ProcedureReturn RegDeleteKeyWithAllSub(FlagKey,".")  
EndProcedure


;/ Test
; Debug "FlagInit"+Str(FlagInit("HKEY_LOCAL_MACHINE\SOFTWARE\Droopy\"))
; Debug "CreateFlag " + Str(FlagCreate("test"))
; Debug "FlagExist "+Str(FlagExist("test"))
; Debug "FlagDontExist "+Str(FlagDontExist("test"))
; Debug "FlagSet "+Str(FlagSet("valeur1","155"))
; Debug "FlagGet "+FlagGet("valeur1")
; Debug "FlagDelete "+Str(FlagDelete("valeur1"))
; Debug "FlagRaz "+Str(FlagRAZ())


;} Flag (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             ForegroundWindow                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ForegroundWindow (Start)                                      

;  Incorporer ces fonctions avec groupe Popup dans windows ( avec Block-Input / Transparency / AvantPlan


; This function returns The handle of The foreground window 
; The window with which The user is currently working
; PureBasic 3.93 
; Author PB tweaked by Droopy

ProcedureDLL ForegroundWindowGet()
  ProcedureReturn GetForegroundWindow_()
EndProcedure

ProcedureDLL ForegroundWindowSet(WindowsHandle) 
  
  thread1=GetWindowThreadProcessId_(GetForegroundWindow_(),0) 
  thread2=GetWindowThreadProcessId_(WindowsHandle,0) 
  If thread1<>thread2 : AttachThreadInput_(thread1,thread2,#True) : EndIf 
  SetForegroundWindow_(WindowsHandle) 
  ;Sleepex_(250,0) ; Delay to stop fast CPU issues. 
  If thread1<>thread2 : AttachThreadInput_(thread1,thread2,#False) : EndIf 
EndProcedure 
; 
; Handle1=OpenWindow(0, 0, 0, 195, 260, #PB_Window_TitleBar ,"Windows #1")
; Handle2=OpenWindow(1, 100, 0, 195, 260, #PB_Window_TitleBar,"Windows #2")
; 
; For n=1 To 6
  ; ForegroundWindowSet(Handle1)
  ; Beep(2000,25)
  ; Delay(500)
  ; ForegroundWindowSet(Handle2)
  ; Beep(400,25)
  ; Delay(250)
; Next

;} ForegroundWindow (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.22 FUNCTIONS ADDON
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                              IsThreadRunning                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ IsThreadRunning (Start)                                       
; Author : Freak
; Return if Thread is running

; WaitThread (PureBasic Function) wait until Thread End itself

ProcedureDLL IsThreadRunning(ThreadID)
  GetExitCodeThread_(ThreadID, @ExitCode.l) 
  
  If ExitCode = #STATUS_PENDING 
    retour=1 ; the thread is still running 
  Else 
    retour=0 ; the thread has quit 
  EndIf
  
  ProcedureReturn retour
  
EndProcedure

;/ Test
; Procedure test()
  ; Repeat
    ; Delay(1)
  ; ForEver
; EndProcedure
; 
; Id=CreateThread(@test(),"")
; Debug IsThreadRunning(Id)
; KillThread(Id)
; Delay(10)
; PauseThread(Id)
; Debug IsThreadRunning(Id)


;} IsThreadRunning (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              MeasureInterval                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MeasureInterval (Start)                                       
; Return the the number of milliseconds between two call
; Cool to Optimize your code
; Idea from Erix14
; Use this functions for measure interval > 1 ms

ProcedureDLL MeasureIntervalStart()
  MeasureIntervalTime=ElapsedMilliseconds()
EndProcedure

ProcedureDLL MeasureIntervalStop()
  Protected retval = ElapsedMilliseconds()-MeasureIntervalTime
  MeasureIntervalTime = 0
  ProcedureReturn retval
EndProcedure

;/ Test
; MeasureIntervalStart()
; Delay(250)
; Debug MeasureIntervalStop()



;} MeasureInterval (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           MeasureIntervalHiRes                            |
;  |                           ____________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MeasureIntervalHiRes (Start)                                  
; Idea from Erix14 / Djes
; Return the time elapsed between Start & Stop in second
; 0.001 = 1 ms
; 0.000001=1 µs
; Caution ! : If the installed hardware supports a high-resolution performance counter
; MeasureHiResIntervalStart return 1 / 0 if no hardware support 
; Use this functions for measure interval < 1 ms

ProcedureDLL MeasureHiResIntervalStart()
  QueryPerformanceFrequency_(@retour)
  If retour <>0 : retour = 1 : EndIf
  QueryPerformanceCounter_(@MeasureHiResIntervalTime)  
  ProcedureReturn retour
EndProcedure

ProcedureDLL.f MeasureHiResIntervalStop()
  QueryPerformanceCounter_(@Temp)
  Difference=Temp-MeasureHiResIntervalTime
  QueryPerformanceFrequency_(@HiResTimerFrequency)
  Periode.f=1/HiResTimerFrequency
  DureeTotale.f=Difference*Periode
  MeasureHiResIntervalTime = 0
  ProcedureReturn DureeTotale
EndProcedure


; ;/ Test1 : For Next
; If MeasureHiResIntervalStart()
  ; For n=0 To 10000
  ; Next n
  ; Debug MeasureHiResIntervalStop()
; EndIf
; 
; ;/ Test2 : Repeat : Until
; If MeasureHiResIntervalStart()
  ; Repeat
    ; a+1
  ; Until a=10000
  ; Debug MeasureHiResIntervalStop()
; EndIf
; 
; Debug "The fastest is For/Next"

;} MeasureIntervalHiRes (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          SignedBinaryToUnsigned                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SignedBinaryToUnsigned (Start)                                
; Author : Fred

ProcedureDLL SignedBinaryToUnsigned(Byte.b)
  ProcedureReturn Byte & $FF
EndProcedure

; ;/                                     Unsigned   Signed
; Debug SignedBinaryToUnsigned(%00000000) ; 0         0
; Debug SignedBinaryToUnsigned(%01111111) ; 127       127
; Debug SignedBinaryToUnsigned(%10000000) ; 128       -128
; Debug SignedBinaryToUnsigned(%11111111) ; 255       -1

;} SignedBinaryToUnsigned (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           SignedWordToUnsigned                            |
;  |                           ____________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SignedWordToUnsigned (Start)                                  
; Author : Fred

ProcedureDLL SignedWordToUnsigned(Word.w)
  ProcedureReturn Word & $FFFF
EndProcedure

; ;/                                           Unsigned   Signed
; Debug SignedWordToUnsigned(%0000000000000000) ; 0         0
; Debug SignedWordToUnsigned(%0111111111111111) ; 32767     27
; Debug SignedWordToUnsigned(%1000000000000000) ; 32768     -32768
; Debug SignedWordToUnsigned(%1111111111111111) ; 65535     -1


;} SignedWordToUnsigned (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 XorEncode                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ XorEncode (Start)                                             
; PureBasic 3.93
; Encode a String with another String ( Key )
; Just a simple Xor Encoding

ProcedureDLL.s XorEncode(Key.s,string.s)
  
  For n=1 To Len(string)
    ChrString=Asc(Mid(string,n,1))
    ChrKey=Asc(Mid(Key,Ptr+1,1))
    If ChrString=ChrKey
      ChrCrypt=ChrString
    Else
      ChrCrypt=ChrString ! ChrKey
    EndIf
    
    retour.s+Chr(ChrCrypt)
    Ptr+1
    If Ptr >Len(Key) : Ptr=0 : EndIf
  Next
  ProcedureReturn retour
EndProcedure

;/ Test
; Key.s="SuperKey"
; xx.s= XorEncode(Key,"This is the String to Crypt")
; Debug xx
; Debug XorEncode(Key,xx)

;} XorEncode (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.23 FUNCTIONS ADDON
;/
;/
;/
;/
;/


;} BarGraph (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                BaseConvert                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ BaseConvert (Start)                                           
; Author : fweil


;/ Intégré à PureBasic 
; Resulat$ = Bin(32) ; Resultat$ est "100000"
; a$ = Hex(12) ; a$ recevra "C"


Structure OneByte 
  a.b 
EndStructure 

; Convertit une chaine de caractères binaire en valeur décimale stockée dans un entier long 
ProcedureDLL.l Bin2Dec(BinaryStringNumber.s) 
  *buf = AllocateMemory(StringByteLength(BinaryStringNumber, #PB_UTF8)+1);we need to make the string utf8 for when compiled as unicode
  ;edit 10/12/2008 changed the above line to account for the null written by the pokes below
  PokeS(*buf, BinaryStringNumber, -1, #PB_UTF8)
  *t.OneByte = *buf;@BinaryStringNumber
  Result.l = 0 
  While *t\a <> 0 
    Result = (Result << 1) + (*t\a - 48) 
    *t + 1 
  Wend 
  FreeMemory(*buf)
  ProcedureReturn Result 
EndProcedure 

 
; Convertit une chaine de caractères héxadécimale en valeur décimale stockée dans un entier long 
ProcedureDLL Hex2Dec(HexNumber.s) 
  *buf = AllocateMemory(StringByteLength(hexnumber, #PB_UTF8)+1);we need to make the string utf8 for when compiled as unicode
  ;edit 10/12/2008 changed the above line to account for the null written by the pokes below
  PokeS(*buf, HexNumber, -1, #PB_UTF8)
  *t.OneByte = *buf;@HexNumber 
  Result.l = 0 
  While *t\a <> 0 
    If *t\a >= '0' And *t\a <= '9' 
      Result = (Result << 4) + (*t\a - 48) 
    ElseIf *t\a >= 'A' And *t\a <= 'F' 
      Result = (Result << 4) + (*t\a - 55) 
    ElseIf *t\a >= 'a' And *t\a <= 'f' 
      Result = (Result << 4) + (*t\a - 87) 
    Else 
      Result = (Result << 4) + (*t\a - 55) 
    EndIf 
    *t + 1 
  Wend 
  FreeMemory(*buf)
  ProcedureReturn Result 
EndProcedure 


;/ Test
; Debug Bin2Dec("10000000000")
; Debug Hex2Dec("FF")


;} BaseConvert (End)


;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 LedGadget                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ LedGadget (Start)                                             
; PureBasic 3.93 
; Idea from Localmotion34 

; De préférence utilisez un gadget ayant un rapport de 11 * 13 ex 110 / 130

Structure SevenSegmentLed 
  x.l 
  y.l 
  width.l 
  height.l 
  Image.l 
  Gadget.l 
  value.l
  point.l
  color1.l 
  color2.l 
  BackgroundColor.l
EndStructure 

;{ Datasection
DataSection
Led:
; Segment a
Data.l 1,1,1,-1,6,0,1,1,-1,1,-6,0,-1,-1,0,0
; Segment g
Data.l 1,6,1,-1,6,0,1,1,-1,1,-6,0,-1,-1,0,0
; Segment d
Data.l 1,11,1,-1,6,0,1,1,-1,1,-6,0,-1,-1,0,0
; Segment f
Data.l 1,1,1,1,0,3,-1,1,-1,-1,0,-3,1,-1,0,0
; Segment b
Data.l 9,1,1,1,0,3,-1,1,-1,-1,0,-3,1,-1,0,0
; Segment e
Data.l 1,6,1,1,0,3,-1,1,-1,-1,0,-3,1,-1,0,0
; Segment c
Data.l 9,6,1,1,0,3,-1,1,-1,-1,0,-3,1,-1,0,0
; Point
Data.l 10,11,1,1,-1,1,-1,-1,1,-1,0,0
; Fin dessin Leds
Data.l 0,0

SegmentA:
Data.l 5,1
SegmentB:
Data.l 9,3
SegmentC:
Data.l 9,8
SegmentD:
Data.l 5,11
SegmentE:
Data.l 1,9
SegmentF:
Data.l 1,4
SegmentG:
Data.l 5,6
SegmentP:
Data.l 10,12

EndDataSection
;}

ProcedureDLL SevenSegmentLed(x,y,width,height,color1,color2,BackgroundColor) 
  
  ; Initialise the LinkedList the first call 
  Static Init 
  If Init=0 
    Global NewList SevenSegmentLedLList.SevenSegmentLed() 
  EndIf 
  Init=1 
  
  ; Fill the Structure 
  AddElement(SevenSegmentLedLList()) 
  SevenSegmentLedLList()\x=x 
  SevenSegmentLedLList()\y=y 
  SevenSegmentLedLList()\width=width 
  SevenSegmentLedLList()\height=height 
  SevenSegmentLedLList()\color1=color1 
  SevenSegmentLedLList()\color2=color2 
  SevenSegmentLedLList()\BackgroundColor=BackgroundColor
  SevenSegmentLedLList()\Image=CreateImage(#PB_Any,width,height) 
  
  PWidth.f=SevenSegmentLedLList()\width/11
  PHeight.f=SevenSegmentLedLList()\height/13
  
  
  ;/ Dessine les Leds
;   UseImage(SevenSegmentLedLList()\Image)
  StartDrawing(ImageOutput(SevenSegmentLedLList()\Image))
  Box(0,0,SevenSegmentLedLList()\width,SevenSegmentLedLList()\height,SevenSegmentLedLList()\BackgroundColor)
  Restore  Led
  Repeat
    Read x
    Read y
    If x=0 And y=0 : Break : EndIf
    Repeat
      Read a
      Read b
      If a=0 And b=0 : Break : EndIf
      Line(x*PWidth,y*PHeight,a*PWidth,b*PHeight,color1)
      x=x+a : y=y+b
    ForEver
  ForEver
  StopDrawing()
  
  ; create the gadget & show the image 
  SevenSegmentLedLList()\Gadget=ImageGadget(#PB_Any,SevenSegmentLedLList()\x,SevenSegmentLedLList()\y,width,height,ImageID(SevenSegmentLedLList()\Image),#PB_Image_Border) 
  
  ; Return the gadget id 
  ProcedureReturn ListIndex(SevenSegmentLedLList()) 
  
EndProcedure 

ProcedureDLL SevenSegmentLedSet(Id,Value) 
  
  SelectElement(SevenSegmentLedLList(),id) 
  
  SevenSegmentLedLList()\value=value 
  
  PWidth.f=SevenSegmentLedLList()\width/11
  PHeight.f=SevenSegmentLedLList()\height/13
  
  ;/ Allume les Segments
;   UseImage(SevenSegmentLedLList()\Image)
  StartDrawing(ImageOutput(SevenSegmentLedLList()\Image))
  
  ; Eteind les segments
  Restore SegmentA
  For n=1 To 8
    Read a
    Read b
    FillArea(a*PWidth,b*PHeight,SevenSegmentLedLList()\color1,SevenSegmentLedLList()\BackgroundColor)
  Next
  
  Select value
    Case 0
      temp.s="abcdef"
    Case 1
      temp="bc"
    Case 2
      temp="abged"
    Case 3
      temp="abgcd"
    Case 4
      temp="fbgc"
    Case 5
      temp="afgcd"
    Case 6
      temp="afedgc"
    Case 7
      temp="abc"
    Case 8
      temp="abcdefg"
    Case 9
      temp="abcdfg"
    Case 10 ; A
      temp="abcefg"
    Case 11 ; b
      temp="fgcde"
    Case 12 ; c
      temp="ged"
    Case 13 ; d
      temp="bcdeg"
    Case 14 ; E
      temp="afged"
    Case 15 ; F
      temp="afeg"
      
      
      
  EndSelect
  
  
  ; Gestion du point
  If SevenSegmentLedLList()\point=1
    temp+"p"
  EndIf
  
  
  For n=1 To Len(temp)
    Select Mid(temp,n,1)
      Case "a"
        Restore SegmentA
      Case "b"
        Restore SegmentB
      Case "c"
        Restore SegmentC
      Case "d"
        Restore SegmentD
      Case "e"
        Restore SegmentE
      Case "f"
        Restore SegmentF
      Case "g"
        Restore SegmentG
      Case "p"
        Restore SegmentP
        
    EndSelect
    
    
    Read a
    Read b
    
    FillArea(a*PWidth,b*PHeight,SevenSegmentLedLList()\color1,SevenSegmentLedLList()\color2)
  Next
  
  StopDrawing()
  
  SetGadgetState(SevenSegmentLedLList()\Gadget,ImageID(SevenSegmentLedLList()\Image)) 
  
EndProcedure 

ProcedureDLL SevenSegmentLedGet(Id) 
  SelectElement(SevenSegmentLedLList(),id) 
  ProcedureReturn SevenSegmentLedLList()\value 
EndProcedure 

ProcedureDLL SevenSegmentLedEvent(Id) 
  SelectElement(SevenSegmentLedLList(),id) 
  ProcedureReturn SevenSegmentLedLList()\Gadget 
EndProcedure  

ProcedureDLL SevenSegmentLedPoint(Id,light)
  SelectElement(SevenSegmentLedLList(),id) 
  SevenSegmentLedLList()\point=light
EndProcedure



;/ Test 
; OpenWindow(0,0,0,580,290,#PB_Window_SystemMenu|#PB_Window_ScreenCentered ,"7 Segment Led")
; CreateGadgetList(WindowID(0))
; SevenSegmentLed(10,10,220,260,8404992,16776960,10485760)
; SevenSegmentLed(250,10,110,130,4227072,65280,4210688)
; SevenSegmentLed(400,10,55,65,1118481,255,0)
; SevenSegmentLed(455,10,55,65,1118481,255,0)
; SevenSegmentLed(510,10,55,65,1118481,255,0)
; 
; For n= 0 To 15
  ; For i=1 To 4
    ; SevenSegmentLedSet(i,Random(9))
    ; SevenSegmentLedPoint(i,Random(1))
  ; Next i 
  ; 
  ; SevenSegmentLedSet(0,n)
  ; For x=1 To 500
    ; a=WindowEvent()
    ; If a=#PB_Event_CloseWindow  : End : EndIf
    ; Delay(Delay(1))
  ; Next x
  ; Beep_(1000,25)
; Next n


;} LedGadget (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    RC4                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RC4 (Start)                                                   
; Author : El_Choni
; RC4 encryption using Windows API

Procedure Error(message$) 
  wError = GetLastError_() 
  If wError 
    *ErrorBuffer = AllocateMemory(1024) 
    FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, 0, wError, 0, *ErrorBuffer, 1024, 0) 
    message$+Chr(10)+PeekS(*ErrorBuffer) 
    FreeMemory(*ErrorBuffer) 
  EndIf 
  MessageRequester("Error", message$) 
EndProcedure 

#PROV_RSA_FULL = 1 
#ALG_SID_MD5 = 3 
#ALG_SID_RC4 = 1 
#ALG_CLASS_DATA_ENCRYPT = 3<<13 
#ALG_CLASS_HASH = 4<<13 
#ALG_TYPE_ANY = 0 
#ALG_TYPE_STREAM = 4<<9 
#CALG_MD5 = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_MD5 
; 
; Valid hashing algorithms: 
; 
; #ALG_SID_HMAC = 9 
; #ALG_SID_MAC = 5 
; #ALG_SID_MD2 = 1 
; #ALG_SID_SHA = 4 
; #ALG_SID_SHA1 = 4 
; #ALG_SID_SSL3SHAMD5 = 8 
; #CALG_HMAC = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_HMAC 
; #CALG_MAC = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_MAC 
; #CALG_MD2 = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_MD2 
; #CALG_SHA = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_SHA 
; #CALG_SHA1 = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_SHA1 
; #CALG_SSL3_SHAMD5 = #ALG_CLASS_HASH|#ALG_TYPE_ANY|#ALG_SID_SSL3SHAMD5 
#CALG_RC4 = #ALG_CLASS_DATA_ENCRYPT|#ALG_TYPE_STREAM|#ALG_SID_RC4 
#CRYPT_EXPORTABLE = 1 
#CRYPT_NEWKEYSET = 8 

ProcedureDLL.s RC4Api(string.s, Password.s) 
  *lpData=@string.s
  DataLength=Len(string)
  If CryptAcquireContext_(@hProv, #Null, #Null, #PROV_RSA_FULL, 0)=0 
    CryptAcquireContext_(@hProv, #Null, #Null, #PROV_RSA_FULL, #CRYPT_NEWKEYSET) 
  EndIf 
  If hProv 
    ; Hashing algorithms defined in the Windows API (constants commented above): 
    ; 
    ; #CALG_HMAC HMAC, a keyed hash algorithm 
    ; #CALG_MAC Message Authentication Code 
    ; #CALG_MD2 MD2 
    ; #CALG_MD5 MD5 
    ; #CALG_SHA US DSA Secure Hash Algorithm 
    ; #CALG_SHA1 Same as CALG_SHA 
    ; #CALG_SSL3_SHAMD5 SSL3 client authentication 
    ; 
    CryptCreateHash_(hProv, #CALG_MD5, 0, 0, @hHash) 
    If hHash 
      CryptHashData_(hHash, Password, Len(Password), 0) 
      ; 
      ; For a list of valid encryption algorithms, check: 
      ; 
      ; http://msdn.microsoft.com/library/en-us/seccrypto/security/alg_id.asp 
      ; 
      ; The constant values can be found in the Platform SDK include file: WinCrypt.h 
      ; 
      ; Here we're using RC4 
      ; 
      CryptDeriveKey_(hProv, #CALG_RC4, hHash, #CRYPT_EXPORTABLE, @hKey) 
      If hKey 
        If CryptEncrypt_(hKey, 0, #True, #Null, *lpData, @DataLength, DataLength) 
          Result = #True 
        Else 
          Error("CryptEncrypt_() failed") 
        EndIf 
        CryptDestroyKey_(hKey) 
      Else 
        Error("CryptDeriveKey_() failed") 
      EndIf 
      CryptDestroyHash_(hHash) 
    Else 
      Error("CryptCreateHash_() failed") 
    EndIf 
    CryptReleaseContext_(hProv, 0) 
  Else 
    Error("CryptAcquireContext_() failed") 
  EndIf 
  ProcedureReturn string 
EndProcedure 


;/ Test
; Debug RC4Api("String","Key")
; Debug RC4Api(RC4Api("String","Key"),"Key")



;} RC4 (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              SendEmail (New)                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SendEmail (New) (Start)                                       
; Author : clipper
; PureBasic 3.93
; Sending Mail with SMTP-AUTH + add multiple attachments
; Don´t fill the Username if you don't want authentification

Enumeration 
  #eHlo 
  #RequestAuthentication 
  #Username 
  #Password 
  #MailFrom 
  #RcptTo 
  #Data 
  #Quit 
  #Complete 
EndEnumeration

ProcedureDLL SendEMailInit()
  Global NewList Attachments.s() 
  Global SendEMailConnectionID.l 
EndProcedure

ProcedureDLL AddAttachment(File.s)
  AddElement(Attachments()) 
  Attachments() =  file
EndProcedure
  
ProcedureDLL NoAttachment()
  ClearList(Attachments())
EndProcedure

Procedure.s GetMIMEType(Extension.s) 
  Extension = "." + Extension 
  hKey.l = 0 
  KeyValue.s = Space(255) 
  DataSize.l = 255 
  If RegOpenKeyEx_(#HKEY_CLASSES_ROOT, Extension, 0, #KEY_READ, @hKey) 
    KeyValue = "application/octet-stream" 
  Else 
    If RegQueryValueEx_(hKey, "Content Type", 0, 0, @KeyValue, @DataSize) 
      KeyValue = "application/octet-stream" 
    Else 
      KeyValue = Left(KeyValue, DataSize-1) 
    EndIf 
    RegCloseKey_(hKey) 
  EndIf 
  ProcedureReturn KeyValue 
EndProcedure 

Procedure.s Base64Encode(strText.s) 
  Define.s Result 
  *B64EncodeBufferA = AllocateMemory(Len(strText)+1) 
  *B64EncodeBufferB = AllocateMemory((Len(strText)*3)+1) 
  PokeS(*B64EncodeBufferA, strText, -1, #PB_UTF8) 
  Base64Encoder(*B64EncodeBufferA, Len(strText), *B64EncodeBufferB, Len(strText)*3) 
  Result = PeekS(*B64EncodeBufferB) 
  FreeMemory(-1) 
  ProcedureReturn Result 
EndProcedure

Procedure Send(msg.s) 
  msg+#CRLF$ 
  SendNetworkData(SendEMailConnectionID, @msg, Len(msg)) 
EndProcedure 

Procedure SendFiles() 
  ResetList(Attachments()) 
  While(NextElement(Attachments())) 
    file.s=Attachments() 
    Send("") 
    If ReadFile(0,file.s) 
      InputBufferLength.l = Lof(0) 
      OutputBufferLength.l = InputBufferLength * 1.4 
      *memin=AllocateMemory(InputBufferLength) 
      If *memin 
        *memout=AllocateMemory(OutputBufferLength) 
        If *memout 
          Boundry.s = "--MyBoundary" 
          Send(Boundry) 
          Send("Content-Type: "+GetMIMEType(GetExtensionPart(file.s)) + "; name=" + Chr(34) + GetFilePart(file.s) + Chr(34)) 
          Send("Content-Transfer-Encoding: base64") 
          Send("Content-Disposition: Attachment; filename=" + Chr(34) + GetFilePart(file) + Chr(34)) 
          Send("") 
          ReadData(0, *memin,InputBufferLength) 
          Base64Encoder(*memin,60,*memout,OutputBufferLength) 
          Send(PeekS(*memout,60)) ; this must be done because For i=0 To OutputBufferLength/60 doesnÂ´t work 
          Base64Encoder(*memin,InputBufferLength,*memout,OutputBufferLength)                
          For i=1 To OutputBufferLength/60 
            temp.s=Trim(PeekS(*memout+i*60,60)) 
            If Len(temp)>0 
              Send(temp) 
            EndIf 
          Next 
        EndIf 
      EndIf 
      FreeMemory(-1) 
      CloseFile(0) 
    EndIf 
  Wend 
  ProcedureReturn 
EndProcedure 

ProcedureDLL SendEmail(Name.s,sender.s,recipient.s,Username.s,Password.s,smtpserver.s,subject.s,body.s) 
  If InitNetwork() 
    SendEMailConnectionID = OpenNetworkConnection(smtpserver, 25) 
    If SendEMailConnectionID 
      loop250.l=0 
      Repeat    
        If NetworkClientEvent(SendEMailConnectionID) 
          ReceivedData.s=Space(9999) 
          ct=ReceiveNetworkData(SendEMailConnectionID ,@ReceivedData,9999) 
          If ct 
            cmdID.s=Left(ReceivedData,3) 
            cmdText.s=Mid(ReceivedData,5,ct-6) 
            Select cmdID 
              Case "220" 
                If Len(Username)>0 
                  Send("Ehlo " + Hostname()) 
                  State=#eHlo 
                Else 
                  Send("HELO " + Hostname()) 
                  State=#MailFrom 
                EndIf    
              Case "221" 
                Send("[connection closed]") 
                State=#Complete 
                quit=1      
              Case "235" 
                Send("MAIL FROM: <" + sender + ">") 
                State=#RcptTo 
                
              Case "334" 
                If State=#RequestAuthentication 
                  Send(Base64Encode(Username)) 
                  State=#Username 
                EndIf 
                If State=#Username 
                  Send(Base64Encode(password)) 
                  state=#Password 
                EndIf 
                
              Case "250" 
                Select state 
                  Case #eHlo 
                    Send("AUTH LOGIN") 
                    state=#RequestAuthentication      
                  Case #MailFrom    
                    Send("MAIL FROM: <" + sender + ">") 
                    state=#RcptTo 
                  Case #RcptTo 
                    Send("RCPT TO: <" + recipient + ">") 
                    state=#Data 
                  Case #Data 
                    Send("DATA") 
                    state=#Quit 
                  Case #Quit 
                    Send("QUIT") 
                EndSelect 
                
              Case "251" 
                Send("DATA") 
                state=#Data 
              Case "354" 
                Send("X-Mailer: eSMTP 1.0") 
                Send("To: " + recipient) 
                Send("From: " + name + " <" + sender + ">") 
                Send("Reply-To: "+sender) 
                Send("Date:" + FormatDate("%dd/%mm/%yyyy @ %hh:%ii:%ss", Date()) ) 
                Send("Subject: " + subject) 
                Send("MIME-Version: 1.0") 
                Send("Content-Type: multipart/mixed; boundary="+Chr(34)+"MyBoundary"+Chr(34)) 
                Send("") 
                Send("--MyBoundary") 
                Send("Content-Type: text/plain; charset=us-ascii") 
                Send("Content-Transfer-Encoding: 7bit") 
                Send("")                      
                Send(body.s) 
                SendFiles() 
                Send("--MyBoundary--") 
                Send(".") 
                
              Case "550" 
                
                quit=1      
            EndSelect 
          EndIf 
        EndIf 
        
      Until quit = 1 
      CloseNetworkConnection(SendEMailConnectionID) 
      
    EndIf 
  EndIf          
EndProcedure 


;/ Test
; SendEMailInit()
; AddAttachment("d:\Commandes API.doc")
; AddAttachment("d:\Voyage italie.xls")
; SendEmail("James Bond","my@email.com","descaves@wanadoo.fr","","","smtp.wanadoo.fr","PureBasic Test","This is the body") 
; NoAttachment()
; SendEmail("Clark Gable","my@email.com","descaves@wanadoo.fr","","","smtp.wanadoo.fr","PureBasic Test","This is the body") 
; Beep_(400,500)


;} SendEmail (New) (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           StringGadgetSetMaxChr                           |
;  |                           _____________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ StringGadgetSetMaxChr (Start)                                 
; author : fweil


ProcedureDLL StringGadgetSetMaxChr(Gadgetid,max)
  SendMessage_(Gadgetid, #EM_SETLIMITTEXT, max, 0) ; adjust to the limit you want to have 
EndProcedure

ProcedureDLL StringGadgetGetMaxChr(Gadgetid)
  ProcedureReturn SendMessage_(Gadgetid, #EM_GETLIMITTEXT, 0, 0) ; Check if the control has got this change, you can remove this line 
EndProcedure
  
;/ Test
; OpenWindow(0, 434, 225, 193, 174,  #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_TitleBar , "Max Input = 5")
; CreateGadgetList(WindowID()) 
; id = StringGadget(0, 43, 28, 112, 21, "") 
; TextGadget(1, 41, 63, 118, 20, "Max 5 chr is allowed", #PB_Text_Center) 
; ActivateGadget(0)
; 
; StringGadgetSetMaxChr(id,5)
; WaitUntilWindowIsClosed()



;} StringGadgetSetMaxChr (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.24 FUNCTIONS ADDON ( 26/08/05 )
;/
;/
;/
;/
;/

; BlockInputW98 deleted in Droopy Lib 1.28

;  _____________________________________________________________________________
;  |                                                                           |
;  |                                FormatDisk                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ FormatDisk (Start)                                            
; Author : PB
; Requires Windows 2000 or higher. 
; Only invokes the format prompt (doesn't format automatically). 
; Drive = A: B: C: ...
; Quick = 0 for Full Format / 1 for Quick format
; Return 0 if Error or Cancel / 1 if successfull

ProcedureDLL FormatDisk(Drive.s,quick) 
  If OSVersion()>#PB_OS_Windows_ME 
    drive$=Left(Drive,1)
    d=Asc(UCase(Drive))-65 
    If (d>-1 And d<26) And (quick=0 Or quick=1) 
      Status=SHFormatDrive_(0,d,0,quick) 
      If Status=-1 : Status=0 : Else : Status=1 : EndIf
    EndIf 
  EndIf 
  ProcedureReturn Status 
EndProcedure 

;/ Test
; Debug FormatDisk("a",0) ; Prompts for full format of A: 
; Debug FormatDisk("a",1) ; Prompts for quick format of A: 


;} FormatDisk (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GetGadgetIdentifier                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetGadgetIdentifier (Start)                                   
; Author : Denis
; PureBasic 3.93
; Return the Gadget Identifier 
; When creating Gadget with #PB_ANY, this function return Number of the Gadget.

ProcedureDLL GetGadgetIdentifier(GadgetHandle)
  ProcedureReturn GetDlgCtrlID_(GadgetHandle)
EndProcedure


;/ TEST
; OpenWindow(0,0,0,270,130,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"CheckBoxGadget") 
; CreateGadgetList(WindowID(0))
; x=CheckBoxGadget(#PB_Any,10,100,250,20,"CheckBox center", #PB_CheckBox_Center)
; Debug GetGadgetIdentifier(x)
; WaitUntilWindowIsClosed()



;} GetGadgetIdentifier (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetPixelColor                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetPixelColor (Start)                                         
; Return the RGB color of the pixel at the specified coordinates
; or #CLR_INVALID (-1) if coordinates is outside the screen

ProcedureDLL GetPixelColor(x,y)
  sysviewDC = GetDC_( hwndSysview ) 
  ProcedureReturn GetPixel_( sysviewDC,x, y ) 
EndProcedure

;/ TEST
; ColorRequester(GetPixelColor(10,760))



;} GetPixelColor (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              GetUserLanguage                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetUserLanguage (Start)                                       
; English forum: http://purebasic.myforums.net/viewtopic.php?t=5289&highlight=greek
; Author: GPI
; Date: 03. March 2003


ProcedureDLL.s GetUserLanguage()
  LangInf= GetUserDefaultLCID_()
  langId_main=LangInf&$FF
  langId_sub=(LangInf&$FF>>8)&$FF
  
  lan$="":sub$=""
  
  Select langId_main
    Case $00: lan$="Neutral"
      Select langId_sub
        Case $01: sub$="Default"
        Case $02: sub$="System Default"
      EndSelect
    Case $01: lan$="Arabic"
      Select langId_sub
        Case $01: sub$="Arabia"
        Case $02: sub$="Iraq"
        Case $03: sub$="Egypt" 
        Case $04: sub$="Libya" 
        Case $05: sub$="Algeria" 
        Case $06: sub$="Morocco" 
        Case $07: sub$="Tunisia" 
        Case $08: sub$="Oman" 
        Case $09: sub$="Yemen" 
        Case $10: sub$="Syria" 
        Case $11: sub$="Jordan" 
        Case $12: sub$="Lebanon" 
        Case $13: sub$="Kuwait" 
        Case $14: sub$="U.A.E." 
        Case $15: sub$="Bahrain"
        Case $16: sub$="Qatar"
      EndSelect
    Case $02: lan$="Bulgarian"
    Case $03: lan$="Catalan"  
    Case $04: lan$="Chinese"
      Select langId_sub
        Case $01: sub$="Traditional"
        Case $02: sub$="Simplified"
        Case $03: sub$="Hong Kong SAR, PRC"
        Case $04: sub$="Singapore"
        Case $05: sub$="Macau"
      EndSelect
    Case $05: lan$="Czech"
    Case $06: lan$="Danish" 
    Case $07: lan$="German" 
      Select langId_sub
        Case $01: sub$=""
        Case $02: sub$="Swiss"
        Case $03: sub$="Austrian"
        Case $04: sub$="Luxembourg"
        Case $05: sub$="Liechtenstein"
      EndSelect
    Case $08: lan$="Greek" 
    Case $09: lan$="English"
      Select langId_sub
        Case $01: sub$="US"
        Case $02: sub$="UK"
        Case $03: sub$="Australian"
        Case $04: sub$="Canadian"
        Case $05: sub$="New Zealand"
        Case $06: sub$="Ireland"
        Case $07: sub$="South Africa"
        Case $08: sub$="Jamaica"
        Case $09: sub$="Caribbean"
        Case $0A: sub$="Belize"
        Case $0B: sub$="Trinidad" 
        Case $0C: sub$="Zimbabwe"
        Case $0D: sub$="Philippines"
      EndSelect
    Case $0A: lan$="Spanish"
      Select langId_sub
        Case $01: sub$="Castilian" 
        Case $02: sub$="Mexican" 
        Case $03: sub$="Modern"
        Case $04: sub$="Guatemala"
        Case $05: sub$="Costa Rica"
        Case $06: sub$="Panama"
        Case $07: sub$="Dominican Republic"
        Case $08: sub$="Venezuela"
        Case $09: sub$="Colombia"
        Case $0A: sub$="Peru"
        Case $0B: sub$="Argentina"
        Case $0C: sub$="Ecuador"
        Case $0D: sub$="Chile"
        Case $0E: sub$="Uruguay"
        Case $0F: sub$="Paraguay" 
        Case $10: sub$="Bolivia"
        Case $11: sub$="El Salvador"
        Case $12: sub$="Honduras"
        Case $13: sub$="Nicaragua"
        Case $14: sub$="Puerto Rico"
      EndSelect
    Case $0B: lan$="Finnish" 
    Case $0C: lan$="French" 
      Select langId_sub
        Case $01: sub$="" 
        Case $02: sub$="Belgian"
        Case $03: sub$="Canadian"
        Case $04: sub$="Swiss"
        Case $05: sub$="Luxembourg"
        Case $06: sub$="Monaco"
      EndSelect
    Case $0D: lan$="Hebrew" 
    Case $0E: lan$="Hungarian" 
    Case $0F: lan$="Icelandic" 
    Case $10: lan$="Italian"
      If langId_sub=$02: sub$="Swiss" :EndIf
    Case $11: lan$="Japanese" 
    Case $12: lan$="Korean" 
    Case $13: lan$="Dutch"
      If langId_sub=$02: sub$="Belgian" :EndIf
    Case $14: lan$="Norwegian"
      Select langId_sub
        Case $01: sub$="Norwegian"
        Case $02: sub$="Nynorsk"
      EndSelect
    Case $15: lan$="Polish" 
    Case $16: lan$="Portuguese"
      If langId_sub=$02: sub$="Brazilian" :EndIf
    Case $18: lan$="Romanian" 
    Case $19: lan$="Russian" 
    Case $1A: lan$="Croatian" 
    Case $1A: lan$="Serbian"
      Select langId_sub
        Case $02: sub$="Latin"
        Case $03: sub$="Cyrillic"
      EndSelect
    Case $1B: lan$="Slovak" 
    Case $1C: lan$="Albanian" 
    Case $1D: lan$="Swedish"
      If langId_sub=$02: sub$="Finland" :EndIf  
    Case $1E: lan$="Thai" 
    Case $1F: lan$="Turkish"  
    Case $20: lan$="Urdu"
      Select langId_sub
        Case $01: sub$="Pakistan"
        Case $02: sub$="India"
      EndSelect
    Case $21: lan$="Indonesian" 
    Case $22: lan$="Ukrainian" 
    Case $23: lan$="Belarusian" 
    Case $24: lan$="Slovenian" 
    Case $25: lan$="Estonian" 
    Case $26: lan$="Latvian" 
    Case $27: lan$="Lithuanian"
      If langId_sub: sub$="Classic" :EndIf
    Case $29: lan$="Farsi" 
    Case $2A: lan$="Vietnamese" 
    Case $2B: lan$="Armenian" 
    Case $2C: lan$="Azeri"
      Select langId_sub
        Case $01: sub$="Latin"
        Case $02: sub$="Cyrillic"
      EndSelect
    Case $2D: lan$="Basque" 
    Case $2F: lan$="Macedonian" 
    Case $36: lan$="Afrikaans" 
    Case $37: lan$="Georgian" 
    Case $38: lan$="Faeroese" 
    Case $39: lan$="Hindi" 
    Case $3E: lan$="Malay"
      Select langId_sub
        Case $01: sub$="Malaysia"
        Case $02: sub$="Brunei Darassalam"
      EndSelect
    Case $3F: lan$="Kazak" 
    Case $41: lan$="Swahili" 
    Case $43: lan$="Uzbek"
      Select langId_sub
        Case $01: sub$="Latin"
        Case $02: sub$="Cyrillic"
      EndSelect 
    Case $44: lan$="Tatar" 
    Case $45: lan$="Bengali" 
    Case $46: lan$="Punjabi" 
    Case $47: lan$="Gujarati" 
    Case $48: lan$="Oriya" 
    Case $49: lan$="Tamil" 
    Case $4A: lan$="Telugu" 
    Case $4B: lan$="Kannada" 
    Case $4C: lan$="Malayalam" 
    Case $4D: lan$="Assamese" 
    Case $4E: lan$="Marathi" 
    Case $4F: lan$="Sanskrit" 
    Case $57: lan$="Konkani" 
    Case $58: lan$="Manipuri" 
    Case $59: lan$="Sindhi" 
    Case $60: lan$="Kashmiri"
      If langId_sub=$02 : sub$="India" : EndIf
    Case $61: lan$="Nepali"
      If langId_sub=$02 : sub$="India" : EndIf
  EndSelect
  
  ProcedureReturn  lan$
EndProcedure

ProcedureDLL.s GetUserSubLanguage()
  LangInf= GetUserDefaultLCID_()
  langId_main=LangInf&$FF
  langId_sub=(LangInf&$FF>>8)&$FF
  
  lan$="":sub$=""
  
  Select langId_main
    Case $00: lan$="Neutral"
      Select langId_sub
        Case $01: sub$="Default"
        Case $02: sub$="System Default"
      EndSelect
    Case $01: lan$="Arabic"
      Select langId_sub
        Case $01: sub$="Arabia"
        Case $02: sub$="Iraq"
        Case $03: sub$="Egypt" 
        Case $04: sub$="Libya" 
        Case $05: sub$="Algeria" 
        Case $06: sub$="Morocco" 
        Case $07: sub$="Tunisia" 
        Case $08: sub$="Oman" 
        Case $09: sub$="Yemen" 
        Case $10: sub$="Syria" 
        Case $11: sub$="Jordan" 
        Case $12: sub$="Lebanon" 
        Case $13: sub$="Kuwait" 
        Case $14: sub$="U.A.E." 
        Case $15: sub$="Bahrain"
        Case $16: sub$="Qatar"
      EndSelect
    Case $02: lan$="Bulgarian"
    Case $03: lan$="Catalan"  
    Case $04: lan$="Chinese"
      Select langId_sub
        Case $01: sub$="Traditional"
        Case $02: sub$="Simplified"
        Case $03: sub$="Hong Kong SAR, PRC"
        Case $04: sub$="Singapore"
        Case $05: sub$="Macau"
      EndSelect
    Case $05: lan$="Czech"
    Case $06: lan$="Danish" 
    Case $07: lan$="German" 
      Select langId_sub
        Case $01: sub$=""
        Case $02: sub$="Swiss"
        Case $03: sub$="Austrian"
        Case $04: sub$="Luxembourg"
        Case $05: sub$="Liechtenstein"
      EndSelect
    Case $08: lan$="Greek" 
    Case $09: lan$="English"
      Select langId_sub
        Case $01: sub$="US"
        Case $02: sub$="UK"
        Case $03: sub$="Australian"
        Case $04: sub$="Canadian"
        Case $05: sub$="New Zealand"
        Case $06: sub$="Ireland"
        Case $07: sub$="South Africa"
        Case $08: sub$="Jamaica"
        Case $09: sub$="Caribbean"
        Case $0A: sub$="Belize"
        Case $0B: sub$="Trinidad" 
        Case $0C: sub$="Zimbabwe"
        Case $0D: sub$="Philippines"
      EndSelect
    Case $0A: lan$="Spanish"
      Select langId_sub
        Case $01: sub$="Castilian" 
        Case $02: sub$="Mexican" 
        Case $03: sub$="Modern"
        Case $04: sub$="Guatemala"
        Case $05: sub$="Costa Rica"
        Case $06: sub$="Panama"
        Case $07: sub$="Dominican Republic"
        Case $08: sub$="Venezuela"
        Case $09: sub$="Colombia"
        Case $0A: sub$="Peru"
        Case $0B: sub$="Argentina"
        Case $0C: sub$="Ecuador"
        Case $0D: sub$="Chile"
        Case $0E: sub$="Uruguay"
        Case $0F: sub$="Paraguay" 
        Case $10: sub$="Bolivia"
        Case $11: sub$="El Salvador"
        Case $12: sub$="Honduras"
        Case $13: sub$="Nicaragua"
        Case $14: sub$="Puerto Rico"
      EndSelect
    Case $0B: lan$="Finnish" 
    Case $0C: lan$="French" 
      Select langId_sub
        Case $01: sub$="" 
        Case $02: sub$="Belgian"
        Case $03: sub$="Canadian"
        Case $04: sub$="Swiss"
        Case $05: sub$="Luxembourg"
        Case $06: sub$="Monaco"
      EndSelect
    Case $0D: lan$="Hebrew" 
    Case $0E: lan$="Hungarian" 
    Case $0F: lan$="Icelandic" 
    Case $10: lan$="Italian"
      If langId_sub=$02: sub$="Swiss" :EndIf
    Case $11: lan$="Japanese" 
    Case $12: lan$="Korean" 
    Case $13: lan$="Dutch"
      If langId_sub=$02: sub$="Belgian" :EndIf
    Case $14: lan$="Norwegian"
      Select langId_sub
        Case $01: sub$="Norwegian"
        Case $02: sub$="Nynorsk"
      EndSelect
    Case $15: lan$="Polish" 
    Case $16: lan$="Portuguese"
      If langId_sub=$02: sub$="Brazilian" :EndIf
    Case $18: lan$="Romanian" 
    Case $19: lan$="Russian" 
    Case $1A: lan$="Croatian" 
    Case $1A: lan$="Serbian"
      Select langId_sub
        Case $02: sub$="Latin"
        Case $03: sub$="Cyrillic"
      EndSelect
    Case $1B: lan$="Slovak" 
    Case $1C: lan$="Albanian" 
    Case $1D: lan$="Swedish"
      If langId_sub=$02: sub$="Finland" :EndIf  
    Case $1E: lan$="Thai" 
    Case $1F: lan$="Turkish"  
    Case $20: lan$="Urdu"
      Select langId_sub
        Case $01: sub$="Pakistan"
        Case $02: sub$="India"
      EndSelect
    Case $21: lan$="Indonesian" 
    Case $22: lan$="Ukrainian" 
    Case $23: lan$="Belarusian" 
    Case $24: lan$="Slovenian" 
    Case $25: lan$="Estonian" 
    Case $26: lan$="Latvian" 
    Case $27: lan$="Lithuanian"
      If langId_sub: sub$="Classic" :EndIf
    Case $29: lan$="Farsi" 
    Case $2A: lan$="Vietnamese" 
    Case $2B: lan$="Armenian" 
    Case $2C: lan$="Azeri"
      Select langId_sub
        Case $01: sub$="Latin"
        Case $02: sub$="Cyrillic"
      EndSelect
    Case $2D: lan$="Basque" 
    Case $2F: lan$="Macedonian" 
    Case $36: lan$="Afrikaans" 
    Case $37: lan$="Georgian" 
    Case $38: lan$="Faeroese" 
    Case $39: lan$="Hindi" 
    Case $3E: lan$="Malay"
      Select langId_sub
        Case $01: sub$="Malaysia"
        Case $02: sub$="Brunei Darassalam"
      EndSelect
    Case $3F: lan$="Kazak" 
    Case $41: lan$="Swahili" 
    Case $43: lan$="Uzbek"
      Select langId_sub
        Case $01: sub$="Latin"
        Case $02: sub$="Cyrillic"
      EndSelect 
    Case $44: lan$="Tatar" 
    Case $45: lan$="Bengali" 
    Case $46: lan$="Punjabi" 
    Case $47: lan$="Gujarati" 
    Case $48: lan$="Oriya" 
    Case $49: lan$="Tamil" 
    Case $4A: lan$="Telugu" 
    Case $4B: lan$="Kannada" 
    Case $4C: lan$="Malayalam" 
    Case $4D: lan$="Assamese" 
    Case $4E: lan$="Marathi" 
    Case $4F: lan$="Sanskrit" 
    Case $57: lan$="Konkani" 
    Case $58: lan$="Manipuri" 
    Case $59: lan$="Sindhi" 
    Case $60: lan$="Kashmiri"
      If langId_sub=$02 : sub$="India" : EndIf
    Case $61: lan$="Nepali"
      If langId_sub=$02 : sub$="India" : EndIf
  EndSelect
  
  ProcedureReturn  sub$
EndProcedure

;/ Test
; MessageRequester("User Language",GetUserLanguage())
; MessageRequester("User SubLanguage",GetUserSubLanguage())

;} GetUserLanguage (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  GuidAPI                                  |
;  |                                  _______                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GuidAPI (Start)                                               
; Author : javabean

; GUID stands For Globally Unique Identifier. 
; It's the Microsoft version of an UUID (Universally Unique Identifier)
; The GUID is a 128bit number given in the following format: 
;  {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx} 
;  {E217B7A4-66C9-4E00-A962-78A20C1B484F} 

;/ Required the function M = Uni2Ansi ( Already include in the Droopy Lib )

ProcedureDLL.s GuidAPI() 
  g.GUID 
  If CoCreateGuid_(@g) = #S_OK 
    unicodeGUID$ = Space(78) 
    GUIDLen = StringFromGUID2_(g, @unicodeGUID$, Len(unicodeGUID$)) 
    ansiGUID$ = Left(M(@unicodeGUID$), GUIDLen-1) 
  EndIf 
  ProcedureReturn ansiGUID$ 
EndProcedure 

;/ Test
; MessageRequester("GUID with API",GuidAPI())


;} GuidAPI (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    Ldb                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Ldb (Start)                                                   
; PureBasic 3.93
; Library for managing little local Database ( Little DataBase = LDB )
; Droopy 08/03/05-19/03/05 and 13/06/05-
; Version 1.1 ( Integration in Droopy Lib)
; Remove LdbInit 
; Translation French to English

;  RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES RES 
;/ #CaseInsensitive=1     ; Need to be in .res
;/ #EveryWhere=2          ; Need to be in .res

;{/ Constants
#Separator=Chr(1)
#FieldSeparator=","
#CRLFSubstitution=Chr(2)
#CaseInsensitive=1
#EveryWhere=2
;}
;  Initialise the Global Variable / LinkedList ( Internal Function )
Procedure LdbInit() 
  Static LdbFlag
  
  If LdbFlag=0
    ;/ Global variables
    LdbFlag=1
    
    Global LdbDatabaseFile.s,LdbFieldCount,LdbSearchStop,LdbSearchReturn,LdbSearchField,LdbSearchPointer,LdbSearchOption,LdbSearchString.s
    Global NewList LdbBdd.s()
    Global NewList LdbField.s()
  EndIf
EndProcedure

;  Get the index of the current record 
ProcedureDLL LdbGetPointer()
  If ListSize(LdbBdd())
    ProcedureReturn ListIndex(LdbBdd())
  EndIf
EndProcedure

;  Set the index of the current record 
ProcedureDLL LdbSetPointer(Record)
  If ListSize(LdbBdd())
    SelectElement(LdbBdd(),Record)
  EndIf
EndProcedure

;  Count the number of Fields
ProcedureDLL LdbCountField()
  If ListSize(LdbBdd())
    tmp=LdbGetPointer()
    FirstElement(LdbBdd())
    LdbFieldCount=CountString(LdbBdd(),#Separator)+1
    LdbSetPointer(tmp)
    ProcedureReturn LdbFieldCount
  EndIf
EndProcedure

;  Open an existing Database ( Return 1 if success / 0 if fail ) Thanks to Baldrick
ProcedureDLL LdbOpen(Database.s)
  LdbInit()
  If ReadFile(0,Database) And Lof(0)
    retour=1
    CloseFile(0)
    LdbDatabaseFile=Database
    ClearList(LdbBdd.s())
    OpenFile(0,LdbDatabaseFile)
    Repeat
      If Eof(0) : Break : EndIf
      AddElement(LdbBdd())
      LdbBdd()=ReadString(0)
    ForEver
    CloseFile(0)
    LdbCountField()
  EndIf
  ProcedureReturn retour
EndProcedure

;  Create a new empty database
ProcedureDLL LdbCreate(Database.s,Fields.s)
  LdbInit()
  LdbDatabaseFile=Database
  ClearList(LdbBdd.s())
  ttmp.s=""
  maxfields=CountString(Fields,#FieldSeparator)+1
  For n=1 To maxfields
    ttmp+StringField(Fields,n,#FieldSeparator)
    If n<>maxfields
      ttmp+#Separator
    EndIf
  Next
  AddElement(LdbBdd())
  LdbBdd()=ttmp
  LdbCountField()
EndProcedure

;  Return the number of records
ProcedureDLL LdbCountRecord()
  If ListSize(LdbBdd())
    ProcedureReturn ListSize(LdbBdd())-1
  EndIf
EndProcedure

;  (Internal procedure) Read the specified field in the current record ( include 0 ) 
Procedure.s LdbRid(Field)
  temp.s=StringField(LdbBdd(),Field,#Separator)
  ; Replace CRLF by #CRLFSubstitution
  temp =ReplaceString(temp,#CRLFSubstitution,#CRLF$)
  ProcedureReturn temp
EndProcedure

;  Read the specified field in the current record ( 0 return "" )
Procedure.s LdbRead_int(Field)
  xx.s=""
  If LdbGetPointer()<>0 : xx.s=LdbRid(Field) : EndIf
  ProcedureReturn xx.s
EndProcedure

ProcedureDLL.s LdbRead(Field)
  ProcedureReturn LdbRead_int(Field)
EndProcedure

;  Write text in the field 'Field'
ProcedureDLL LdbWrite(Field,Text.s)
  ; Verify if trying to overwrite the first record
  If LdbGetPointer()<>0
    ; Replace CRLF by #CRLFSubstitution
    Text=ReplaceString(Text,#CRLF$,#CRLFSubstitution)
    ClearList(LdbField.s())
    For n=1 To LdbFieldCount
      AddElement(LdbField.s())
      LdbField.s()=StringField(LdbBdd(),n,#Separator)
    Next
    SelectElement(LdbField.s(),Field-1)
    LdbField()=Text
    LdbBdd()=""
    ForEach LdbField.s()
      LdbBdd()+LdbField.s()+#Separator
    Next
  EndIf
EndProcedure

;  ( Internal ) Add a record at the end of the database / set the pointer to this record
Procedure LdbAddRecord()
  LastElement(LdbBdd())
  AddElement(LdbBdd())
  For n=1 To LdbFieldCount
    LdbBdd()+#Separator
  Next
  
EndProcedure

;  Delete the current record
ProcedureDLL LdbDeleteRecord()
  DeleteElement(LdbBdd(),1)
EndProcedure

;  Write LinkedList to Disk
ProcedureDLL.b LdbSaveDatabase()
  PointerTemp=LdbGetPointer()
  If IsFile(0)
    CloseFile(0)
  EndIf
  If CreateFile(0,LdbDatabaseFile)
    ForEach LdbBdd()
      WriteStringN(0, LdbBdd())
    Next
    CloseFile(0)
    LdbSetPointer(PointerTemp)
    ProcedureReturn 1
  EndIf
EndProcedure

;  Close the open Database
ProcedureDLL LdbCloseDatabase()
  ClearList(LdbBdd())
EndProcedure

;  Set a field name
ProcedureDLL LDBSetFieldName(Nb,FieldName.s)
  tmp=LdbGetPointer()
  LdbSetPointer(0)
  LdbWrite(Nb,FieldName)
  LdbSetPointer(tmp)
EndProcedure

;  Get a field name
ProcedureDLL.s LdbGetFieldName(Nb)
  tmp=LdbGetPointer()
  LdbSetPointer(0)
  ttt.s=LdbRid(Nb)
  LdbSetPointer(tmp)
  ProcedureReturn ttt
EndProcedure

;  Set the pointer to the previous record
ProcedureDLL LdbPreviousRecord()
  PreviousElement(LdbBdd())
  If LdbGetPointer()=0 : LdbSetPointer(1) : EndIf
EndProcedure

;  Set the pointer to the next record
ProcedureDLL LdbNextRecord()
  NextElement(LdbBdd())
EndProcedure

;  Insert a record at position 'nb' / -1 add a record as the last record
ProcedureDLL LdbInsertRecord(Nb.l)
  If Nb=-1
    LdbAddRecord()
  Else
    LdbSetPointer(Nb)
    InsertElement(LdbBdd())
    For n=1 To LdbFieldCount
      LdbBdd()+#Separator
    Next
  EndIf
  
EndProcedure

;  Add a Field as the last field
ProcedureDLL LdbAddField(FieldName.s)
  tmp=LdbGetPointer()
  LdbFieldCount+1
  ForEach LdbBdd()
    LdbBdd()+#Separator
  Next
  LDBSetFieldName(LdbFieldCount,FieldName)
  LdbSetPointer(tmp)
EndProcedure

;  Delete a field in the database
ProcedureDLL LdbDeleteField(Nb.l)
  tmp=LdbGetPointer()
  ForEach LdbBdd()
    ClearList(LdbField())
    ttmp.s=""
    For n=1 To LdbFieldCount
      If Nb=n : Continue : EndIf
      ttmp+StringField(LdbBdd(),n,#Separator)+#Separator
    Next
    LdbBdd()=ttmp
  Next
  LdbCountField()
  LdbSetPointer(tmp)
EndProcedure  

;  Search with options ( #CaseInsensitive #EveryWhere )
;  Initialise a search in Ldb
ProcedureDLL LdbSearchInit(Field,SearchText.s,Option)
  LdbSearchPointer=1
  LdbSearchString.s=SearchText.s
  LdbSearchOption=Option
  LdbSearchField=Field
  LdbSearchStop=0
  LdbSearchReturn=0
EndProcedure

;  Search and return record that match ( 0 = There is no more record that match  )
;  You must stop call this function
ProcedureDLL LdbSearch()
  ; If there is no records : Quit
  If LdbSearchPointer=1 And LdbCountRecord()=0
    LdbSearchStop=1
    LdbSearchReturn=0
  EndIf
  
  LdbSearchReturn=0
  If LdbSearchPointer>LdbCountRecord() : LdbSearchStop=1 : EndIf
  
  
  If LdbSearchStop=0
    For n= LdbSearchPointer To LdbCountRecord()
      LdbSetPointer(n)
      xxc.s=LdbRead_int(LdbSearchField)
      xxs.s=LdbSearchString
      
      ; Search case Insensitive : Put all stirng to Upper Case
      If LdbSearchOption & #CaseInsensitive
        xxc=UCase(xxc)
        xxs=UCase(xxs)
      EndIf
      
      ; Flag Stop : Quit at the next loop
      If n=LdbCountRecord() : LdbSearchStop=1 : EndIf
      
      If LdbSearchOption & #EveryWhere
        If FindString(xxc,xxs,1)>0 
          LdbSearchPointer=n+1
          LdbSearchReturn=LdbSearchPointer -1
          Break 
        EndIf
      Else
        If xxc=xxs 
          LdbSearchPointer=n+1
          LdbSearchReturn=LdbSearchPointer -1
          Break 
        EndIf
      EndIf
    Next
  EndIf
  ProcedureReturn LdbSearchReturn
EndProcedure
  
;  Sort the database assuming field as Numerical
ProcedureDLL LdbSortNum(Field)
  Nb=LdbCountRecord()
  If Nb>1 ; Si au moins 2 enregistrements
    PointerTemp=LdbGetPointer()
    For n=1 To Nb-1
      For i=n+1 To Nb
        LdbSetPointer(n)
        FirstRecord.f=ValF(LdbRead_int(Field))
        LdbSetPointer(i)
        SecondRecord.f=ValF(LdbRead_int(Field))
        If FirstRecord.f>SecondRecord.f
          SelectElement(LdbBdd(),n)
          temp.s=LdbBdd()
          SelectElement(LdbBdd(),i)
          temp2.s=LdbBdd()
          LdbBdd()=temp
          SelectElement(LdbBdd(),n)
          LdbBdd()=temp2
        EndIf
      Next i
    Next n
    LdbSetPointer(PointerTemp)
  EndIf
EndProcedure

;  Sort the database assuming field as String
;  Défault = CaseSensitive / Just 1 Option = #CaseInsensitive
ProcedureDLL LdbSortAlpha(Field,Option)
  Nb=LdbCountRecord()
  If Nb>1 ; There is at list 2 records
    PointerTemp=LdbGetPointer()
    For n=1 To Nb-1
      For i=n+1 To Nb
        LdbSetPointer(n)
        FirstRecord.s=LdbRead_int(Field)
        LdbSetPointer(i)
        SecondRecord.s=LdbRead_int(Field)
        
        ; Pur all in UpperCase if #CaseInsensitive
        If Option = #CaseInsensitive
          FirstRecord=UCase(FirstRecord)
          SecondRecord=UCase(SecondRecord)
        EndIf
        
        If FirstRecord>SecondRecord
          SelectElement(LdbBdd(),n)
          temp.s=LdbBdd()
          SelectElement(LdbBdd(),i)
          temp2.s=LdbBdd()
          LdbBdd()=temp
          SelectElement(LdbBdd(),n)
          LdbBdd()=temp2
        EndIf
      Next i
    Next n
    LdbSetPointer(PointerTemp)
  EndIf  
EndProcedure


;/
;/
;/                          Testing LDB Functons
;/
;/
;{- F1 Test for the Ldb library ( Little Database )
; ; launch it in debug mode
; 
; ; Create a new Database with 3 fields
; LdbCreate("c:\Drivers.db","Birth Date,Name,Surname")
; ; LdbOpen("c:\Drivers.db")
; 
; ; Add one Record
; LdbInsertRecord(-1)
; ; Write data to this record
; LdbWrite(1,"1969") ; 1st field
; LdbWrite(2,"schumacher") ; 2nd field
; LdbWrite(3,"Mikael") ; 3rd field
; 
; ; Add another Record
; LdbInsertRecord(-1)
; ; Write data to this record
; LdbWrite(1,"1980") ; 1st field
; LdbWrite(2,"Button") ; 2nd field
; LdbWrite(3,"Jenson") ; 3rd field
; 
; ; Add another Record
; LdbInsertRecord(-1)
; ; Write data to this record
; LdbWrite(1,"1981") ; 1st field
; LdbWrite(2,"Alonso") ; 2nd field
; LdbWrite(3,"Fernando") ; 3rd field
; 
; ; Add another Record
; LdbInsertRecord(-1)
; ; Write data to this record
; LdbWrite(1,"1971") ; 1st field
; LdbWrite(2,"Villeneuve") ; 2nd field
; LdbWrite(3,"Jacques") ; 3rd field
; 
; ; Insert a record at 3rd position
; LdbInsertRecord(3)
; ; Write data to this record
; LdbWrite(1,"1975") ; 1st field
; LdbWrite(2,"Schumacher") ; 2nd field
; LdbWrite(3,"Ralph") ; 3rd field
; 
; ; Sort the database by field 1 ( Birth Date )
; LdbSortNum(1)
; 
; ; Show all drivers sorted by birth Date
; Debug "Drivers sorted by birth date"
; For n=1 To LdbCountRecord()
  ; LdbSetPointer(n)
  ; Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
; Next
; Debug ""
; 
; ; Sort the database by Drivers names
; LdbSortAlpha(2,1)
; 
; ; Show all drivers sorted by name
; Debug "Drivers sorted by name"
; For n=1 To LdbCountRecord()
  ; LdbSetPointer(n)
  ; Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
; Next
; Debug ""
; 
; ; Search all name = Schumacher
; LdbSearchInit(2,"Schumacher",1)
; 
; ; Show all drivers = Schumacher
; Debug "Drivers with name = Schumacher"
; Repeat
  ; Champ=LdbSearch()
  ; If Champ=0 : Break : EndIf ; if 0 --> search finished
  ; LdbSetPointer(Champ)
  ; Debug LdbRead(1)+" "+LdbRead(2)+" "+LdbRead(3)
; ForEver
; Debug ""
; 
; ; Database Infos
; Debug "Database Infos"
; Debug "Number of fields "+Str(LdbCountField())
; Debug "Name of field"
; For n=1 To LdbCountField()
  ; Debug "Field n° "+Str(n)+" = "+LdbGetFieldName(n)
; Next
; 
; Debug "Number of records "+Str(LdbCountRecord())
; 
; ; Save Database to disk
; LdbSaveDatabase()
; ; Close the Database
; LdbCloseDatabase()
;}

;/
;/
;/                          Various LDB Tests
;/
;/
;{- String Test
; ;  Create a Database with 7 Fields
; LdbCreate("c:\test.txt","Field 1,Field 2,Field 3,Field 4,Field 5,Field 6,Field 7")
; 
; ;  Add 9 Records
; For n=1 To 9
  ; LdbInsertRecord(-1)
  ; For i= 1 To 7
    ; LdbWrite(i,Str(n)+"-"+Str(i))
  ; Next
; Next
; 
; ;  Insert a record as 2nd record
; LdbInsertRecord(2)
; 
; ;  Write to the 2nd record
; LdbWrite(3,"4444")
; LdbWrite(1,"11111")
; 
; ;  Add a record @ the end of the database & Write to this record
; LdbInsertRecord(-1)
; LdbWrite(1,"fin")
; 
; ;  Search for record that match "2-1" in the 1st Field
; LdbSearchInit(1,"2-1",0)
; Repeat
  ; x= LdbSearch()
  ; If x=0 : Break : EndIf
  ; Debug x
; ForEver
; 
; ;  Save & Close the Database
; LdbSaveDatabase()
; LdbCloseDatabase()
;}

;{- Sort Test
; LdbCreate("D:\test.txt","Champ1,Champ2")
; nnb=500
; For n=1 To nnb
  ; LdbInsertRecord(-1)
  ; LdbWrite(2,Str(Random(10)))
  ; LdbWrite(1,Str(nnb-n))
; Next
; 
; LdbSaveDatabase()
; MessageRequester("tri","Cliquez pour trier")
; 
; LdbSortNum(2)
; 
; LdbSaveDatabase()
; LdbCloseDatabase()
; 
; MessageRequester("tri","fini")
;}

;{- String Sort Test
; LdbCreate("d:\test.txt","Nom,Age")
; nnb=100
; ch=5
; For n=1 To nnb
  ; LdbInsertRecord(-1)
  ; a.s=""
  ; For i=1 To ch
    ; zz.s=Chr(Random(25)+65)
    ; If Random(1)=0 : zz=LCase(zz) : EndIf
    ; a.s+zz
  ; Next
  ; LdbWrite(1,a)
  ; LdbWrite(2,Str(n))
; Next
; LdbSortNum(2)
; LdbSortAlpha(1,#CaseInsensitive)
; 
; LdbSaveDatabase()
; LdbCloseDatabase()
;}


;} Ldb (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               MonitorPower                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MonitorPower (Start)                                          
; Author : thefool
; Turn off the monitor  : 2
; Standby monitor       : 1
; Turn on the monitor   : -1

#SC_MONITORPOWER= $F170 
#WM_SYSCOMMAND = $112 

ProcedureDLL MonitorPower(State.b)
  SendMessage_(ForegroundWindowGet(), #WM_SYSCOMMAND, #SC_MONITORPOWER,State )
EndProcedure

;/ Test
; MonitorPower(2)
; Delay(5000)
; Beep(400,500)
; MonitorPower(-1)



;} MonitorPower (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               RealDriveType                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RealDriveType (Start)                                         
; Require Windows 2K or > 
; Require Windows Me Or >


ProcedureDLL RealDriveType(Drive.s)
 Drive=Left(Drive,1)
 Drive=UCase(Drive)
 a=Asc(Drive)-65
 ProcedureReturn RealDriveType_(a,0)
EndProcedure

;/ Test ( And list of Constant to use )
; Select RealDriveType("c:")
  ; Case #DRIVE_NO_ROOT_DIR 
    ; Debug "DRIVE_NO_ROOT_DIR"
  ; Case #DRIVE_UNKNOWN 
    ; Debug "DRIVE_UNKNOWN"
  ; Case #DRIVE_REMOVABLE
    ; Debug "DRIVE_REMOVABLE"
  ; Case #DRIVE_FIXED 
    ; Debug "DRIVE_FIXED"
  ; Case #DRIVE_REMOTE 
    ; Debug "DRIVE_REMOTE"
  ; Case #DRIVE_CDROM
    ; Debug "DRIVE_CDROM"
  ; Case #DRIVE_RAMDISK
    ; Debug "DRIVE_RAMDISK"
; EndSelect


;} RealDriveType (End)

;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  ToolTip                                  |
;  |                                  _______                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ToolTip (Start)                                               
;/ Author : Andre / Balatro / Berikco

; ToolTipAdd
; Type : 0 = Balloon Tip / 1 Square Tip
; MaxWidth : Max Width of the ToolTip
; Icon : 0 (no Icon) / 1 (information icon) / 2 (warning icon) / 3 (error icon) 

ProcedureDLL ToolTipAdd(Type,MaxWidth,Window, Gadget, Text$ , Title$, Icon,TextColor,BKColor,Font.s,FontSize) 
  
  ;/ Initialise le Tableau au premier appel
  Static Initialised
  If Initialised=0
    Global Dim PtrToolTip(500)
    Initialised=1
  EndIf
  
  
  If Type=0 ;/ Ballon
    Type=#WS_POPUP | #TTS_NOPREFIX | #TTS_BALLOON
  Else      ;/ Or Square
    Type=#WS_POPUP | #TTS_NOPREFIX
  EndIf
  
  If TextColor=0 : TextColor=GetSysColor_(#COLOR_INFOTEXT) : EndIf
  If BKColor=0 : BKColor=GetSysColor_(#COLOR_INFOBK) : EndIf
  ToolTip=CreateWindowEx_(0,"ToolTips_Class32","",Type,0,0,0,0,WindowID(WindowID),0,GetModuleHandle_(0),0) 
  SendMessage_(ToolTip,#TTM_SETTIPTEXTCOLOR,TextColor,0) 
  SendMessage_(ToolTip,#TTM_SETTIPBKCOLOR,BKColor,0) 
  SendMessage_(ToolTip,#TTM_SETMAXTIPWIDTH,0,MaxWidth) 
  Balloon.TOOLINFO\cbSize=SizeOf(TOOLINFO) 
  Balloon\uFlags= #TTF_IDISHWND | #TTF_SUBCLASS
  Balloon\hWnd=WindowID(WindowID) 
  Balloon\uId=GadgetID(Gadget) 
  Balloon\lpszText=@Text$ 
  ;/ Fonts
  If Font>""
    fontnum = LoadFont(#PB_Any, Font, FontSize); : UseFont(1) 
    SendMessage_(ToolTip, #WM_SETFONT, FontID(fontnum), #True) 
  EndIf
  
  SendMessage_(ToolTip, #TTM_ADDTOOL, 0, Balloon) 
  If Title$ > "" 
    SendMessage_(ToolTip, #TTM_SETTITLE, Icon, @Title$) 
  EndIf 
  PtrToolTip(Gadget)=ToolTip
EndProcedure 

ProcedureDLL ToolTipRemove(Gadget.l) 
  ttRemove.TOOLINFO\cbSize = SizeOf(TOOLINFO) 
  ttRemove\hWnd = GetParent_(PtrToolTip(Gadget)) 
  ttRemove\uId = GadgetID(Gadget) 
  SendMessage_(PtrToolTip(Gadget), #TTM_DELTOOL, 0, ttRemove) 
EndProcedure 

ProcedureDLL ToolTipChange(Gadget.l, Text$) 
  ttChange.TOOLINFO\cbSize = SizeOf(TOOLINFO) 
  ttChange\hWnd = GetParent_(PtrToolTip(Gadget))
  ttChange\uId = GadgetID(Gadget) 
  ttChange\lpszText = @Text$ 
  SendMessage_(PtrToolTip(Gadget), #TTM_UPDATETIPTEXT, 0, ttChange) 
EndProcedure 

ProcedureDLL ToolTipShow(Gadget.l,x,y)
  ttChange.TOOLINFO\cbSize = SizeOf(TOOLINFO) 
  ttChange\hWnd = GetParent_(PtrToolTip(Gadget))
  ttChange\uId = GadgetID(Gadget)   
  SendMessage_(PtrToolTip(Gadget), #TTM_TRACKACTIVATE, 1, ttChange) 
  SetWindowPos_(PtrToolTip(Gadget), 0, x, y, -1, -1, #SWP_NOSIZE | #SWP_NOZORDER | #SWP_SHOWWINDOW | #SWP_NOACTIVATE) 
EndProcedure

ProcedureDLL ToolTipHide(Gadget.l)
  ttChange.TOOLINFO\cbSize = SizeOf(TOOLINFO) 
  ttChange\hWnd = GetParent_(PtrToolTip(Gadget))
  ttChange\uId = GadgetID(Gadget)  
  SendMessage_(PtrToolTip(Gadget), #TTM_TRACKACTIVATE, 0,ttChange) 
  
EndProcedure

;/
;/ LIBRARY TEST
;/

; Procedure BackGroundTask()
;   Repeat
;     ToolTipChange(0,FormatDate("%hh:%ii:%ss", Date()))
;     Delay(1000)
;   ForEver
; EndProcedure
; 
; 
; OpenWindow(0,0,0,270,160,"GadgetTooltip",#PB_Window_SystemMenu|#PB_Window_ScreenCentered) 
; CreateGadgetList(WindowID(0))
; ButtonGadget(0,10,5,250,30,"Show/Hide ToolTip")
; ButtonGadget(1,10,40,250,30,"Button 2")
; ButtonGadget(2,10,75,250,30,"Button 3")
; ButtonGadget(3,10,110,250,30,"Button 4")
; ButtonGadget(4,0,0,0,0,"") ;/ ( Hidden Button )
; ToolTipAdd(0,200,0,0,"Tooltip n°1","ClockTip",0,RGB(255,255,0),RGB(255,0,0),"Comic sans ms",34)
; ToolTipAdd(0,200,0,1,"This is a text","Tooltip n°2",3,0,0,"",0)
; ToolTipAdd(0,200,0,2,"TOOLTIP 3"+#CRLF$+"MULTILINE"+#CR$+" INPUT","",0,RGB(0,0,255),RGB(255,255,255),"impact",25)
; ToolTipAdd(1,200,0,3,"This is a text","ToolTip n°4",1,RGB(100, 128, 128),RGB(128, 255, 128),"",0)
; ToolTipAdd(1,300,0,4,"This is a multiline"+#CR$+"Tooltip and i can write"+#CR$+"what i want !","",0,0,65535,"Arial",12)
; 
; 
; CreateThread(@BackGroundTask(),0)
; Repeat
;   Temp=WaitWindowEvent()
;   If Temp=#PB_Event_Gadget And EventGadget()=0 And EventType()=#PB_EventType_LeftClick  
;         Temp2=Bool_Not(Temp2)
;         If Temp2
;           ToolTipShow(4,512,384)
;         Else
;           ToolTipHide(4)
;         EndIf
;   EndIf
; Until Temp=#PB_Event_CloseWindow


;} ToolTip (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             URLDownloadToFile                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ URLDownloadToFile (Start)                                     
; Author : BackupUser
; Downloads files from the Internet and saves them to a file.
; After download the cache is cleared
; Return 1 if success / 0 instead

ProcedureDLL URLDownloadToFile(Url.s,File.s)
  retour=URLDownloadToFile_(0, Url, File, 0, 0)
  DeleteUrlCacheEntry_(Url)
  If retour=0 : retour=1 : Else : retour=0 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test
; Debug URLDownloadToFile("http://www.penguinbyte.com/apps/pbwebstor/files/67/Droopy.exe","c:\Droopy.exe")

;} URLDownloadToFile (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                    WMI                                    |
;  |                                    ___                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WMI (Start)                                                   
; Author : DataMiner 
; Tweaked by Droopy to create a Libary 
; PureBasic 3.93 
; 14/06/05 

;{- WMI Constants 
#COINIT_MULTITHREAD=0 
#RPC_C_AUTHN_LEVEL_CONNECT=2 
#RPC_C_IMP_LEVEL_IDENTIFY=2 
#EOAC_NONE=0 
#RPC_C_AUTHN_WINNT=10 
#RPC_C_AUTHZ_NONE=0 
#RPC_C_AUTHN_LEVEL_CALL=3 
#RPC_C_IMP_LEVEL_IMPERSONATE=3 
#CLSCTX_INPROC_SERVER=1 
#wbemFlagReturnImmediately=16 
#wbemFlagForwardOnly=32 
#IFlags = #wbemFlagReturnImmediately + #wbemFlagForwardOnly 
#WBEM_INFINITE=$FFFFFFFF 
#WMISeparator="," 
;} 

Procedure.l ansi2bstr(ansi.s) 
  size.l=MultiByteToWideChar_(#CP_ACP,0,ansi,-1,0,0) 
  Dim unicode.w(size) 
  MultiByteToWideChar_(#CP_ACP, 0, ansi, Len(ansi), unicode(), size) 
  ProcedureReturn SysAllocString_(@unicode()) 
EndProcedure 

Procedure bstr2string (bstr) 
  Shared WMIResult.s 
  WMIResult.s = "" 
  pos=bstr 
  While PeekW (pos) 
    WMIResult=WMIResult+Chr(PeekW(pos)) 
    pos=pos+2 
  Wend 
  ProcedureReturn @WMIResult 
EndProcedure 

Interface _IWbemLocator
  QueryInterface(a, b)
  AddRef()
  Release()
  ConnectServer(a.p-bstr, b, c, d, e, f, g, h)
EndInterface
Interface _IWbemServices
    QueryInterface(a, b)
    AddRef()
    Release()
    OpenNamespace(a, b, c, d, e)
    CancelAsyncCall(a)
    QueryObjectSink(a, b)
    GetObject(a, b, c, d, e)
    GetObjectAsync(a, b, c, d)
    PutClass(a, b, c, d)
    PutClassAsync(a, b, c, d)
    DeleteClass(a, b, c, d)
    DeleteClassAsync(a, b, c, d)
    CreateClassEnum(a, b, c, d)
    CreateClassEnumAsync(a, b, c, d)
    PutInstance(a, b, c, d)
    PutInstanceAsync(a, b, c, d)
    DeleteInstance(a, b, c, d)
    DeleteInstanceAsync(a, b, c, d)
    CreateInstanceEnum(a, b, c, d)
    CreateInstanceEnumAsync(a, b, c, d)
    ExecQuery(a.p-bstr, b.p-bstr, c, d, e)
    ExecQueryAsync(a, b, c, d, e)
    ExecNotificationQuery(a, b, c, d, e)
    ExecNotificationQueryAsync(a, b, c, d, e)
    ExecMethod(a, b, c, d, e, f, g)
    ExecMethodAsync(a, b, c, d, e, f)
  EndInterface
  Interface _IWbemClassObject
    QueryInterface(a, b)
    AddRef()
    Release()
    GetQualifierSet(a)
    Get(a.p-bstr, b, c, d, e)
    Put(a, b, c, d)
    Delete(a)
    GetNames(a, b, c, d)
    BeginEnumeration(a)
    Next(a, b, c, d, e)
    EndEnumeration()
    GetPropertyQualifierSet(a, b)
    Clone(a)
    GetObjectText(a, b)
    SpawnDerivedClass(a, b)
    SpawnInstance(a, b)
    CompareTo(a, b)
    GetPropertyOrigin(a, b)
    InheritsFrom(a)
    GetMethod(a, b, c, d)
    PutMethod(a, b, c, d)
    DeleteMethod(a)
    BeginMethodEnumeration(a)
    NextMethod(a, b, c, d)
    EndMethodEnumeration()
    GetMethodQualifierSet(a, b)
    GetMethodOrigin(a, b)
  EndInterface



Procedure.s WMI_int(WMICommand.s) 
  ;  WMI Initialize 
  CoInitializeEx_(0,#COINIT_MULTITHREAD) 
  hres=CoInitializeSecurity_(0, -1,0,0,#RPC_C_AUTHN_LEVEL_CONNECT,#RPC_C_IMP_LEVEL_IDENTIFY,0,#EOAC_NONE,0) 
  If hres <> 0: MessageRequester("ERROR", "unable to call CoInitializeSecurity", #MB_OK): Goto cleanup: EndIf 
  hres=CoCreateInstance_(?CLSID_WbemLocator,0,#CLSCTX_INPROC_SERVER,?IID_IWbemLocator,@loc._IWbemLocator) 
  If hres <> 0: MessageRequester("ERROR", "unable to call CoCreateInstance", #MB_OK): Goto cleanup: EndIf 
  hres=loc\ConnectServer("root\cimv2",0,0,0,0,0,0,@svc._IWbemServices) 
  If hres <> 0: MessageRequester("ERROR", "unable to call IWbemLocator::ConnectServer", #MB_OK): Goto cleanup: EndIf 
  hres=svc\QueryInterface(?IID_IUnknown,@pUnk.IUnknown) 
  hres=CoSetProxyBlanket_(svc,#RPC_C_AUTHN_WINNT,#RPC_C_AUTHZ_NONE,0,#RPC_C_AUTHN_LEVEL_CALL,#RPC_C_IMP_LEVEL_IMPERSONATE,0,#EOAC_NONE) 
  If hres <> 0: MessageRequester("ERROR", "unable to call CoSetProxyBlanket", #MB_OK): Goto cleanup: EndIf 
  hres=CoSetProxyBlanket_(pUnk,#RPC_C_AUTHN_WINNT,#RPC_C_AUTHZ_NONE,0,#RPC_C_AUTHN_LEVEL_CALL,#RPC_C_IMP_LEVEL_IMPERSONATE,0,#EOAC_NONE) 
  If hres <> 0: MessageRequester("ERROR", "unable to call CoSetProxyBlanket", #MB_OK): Goto cleanup: EndIf 
  pUnk\Release() 
  
  
  ;  CallData 
  k=CountString(WMICommand,#WMISeparator) 
  Dim wmitxt$(k) 
  For i=0 To k 
    wmitxt$(i) = StringField(WMICommand,i+1,#WMISeparator) 
  Next 
  
  For z=0 To k 
    Debug Str(z)+" "+wmitxt$(z) 
  Next
  
  hres=svc\ExecQuery("WQL",wmitxt$(0), #IFlags,0,@pEnumerator.IEnumWbemClassObject) 
  If hres <> 0: MessageRequester("ERROR", "unable to call IWbemServices::ExecQuery", #MB_OK): Goto cleanup: EndIf 
  hres=pEnumerator\reset() 
  Repeat 
  hres=pEnumerator\Next(#WBEM_INFINITE, 1, @pclsObj._IWbemClassObject, @uReturn) 
  For i=1 To k 
    mem=AllocateMemory(1000) 
    hres=pclsObj\get(wmitxt$(i), 0, mem, 0, 0) 
    Type=PeekW(mem) 
    Select Type 
      Case 8 
        val.s=PeekS(PeekL(mem+8), -1, #PB_Unicode) 
      Case 3 
        val.s=Str(PeekL(mem+8)) 
      Default 
        val.s="" 
    EndSelect 
    If uReturn <> 0: wmi$=wmi$+wmitxt$(i)+" = "+val+Chr(10)+Chr(13): EndIf 
    FreeMemory(mem) 
  Next 
Until uReturn = 0 

;  Cleanup 
cleanup: 
svc\Release() 
loc\Release() 
pEnumerator\Release() 
pclsObj\Release() 
CoUninitialize_() 

ProcedureReturn wmi$ 
EndProcedure 

ProcedureDLL.s WMI(WMICommand.s) 
  ProcedureReturn WMI_int(WMICommand.s) 
EndProcedure

;{- WMI DATASECTION 
DataSection 
CLSID_IEnumWbemClassObject: 
  ;1B1CAD8C-2DAB-11D2-B604-00104B703EFD 
Data.l $1B1CAD8C 
Data.w $2DAB, $11D2 
Data.b $B6, $04, $00, $10, $4B, $70, $3E, $FD 
IID_IEnumWbemClassObject: 
  ;7C857801-7381-11CF-884D-00AA004B2E24 
Data.l $7C857801 
Data.w $7381, $11CF 
Data.b $88, $4D, $00, $AA, $00, $4B, $2E, $24 
CLSID_WbemLocator: 
    ;4590f811-1d3a-11d0-891f-00aa004b2e24 
Data.l $4590F811 
Data.w $1D3A, $11D0 
Data.b $89, $1F, $00, $AA, $00, $4B, $2E, $24 
IID_IWbemLocator: 
    ;dc12a687-737f-11cf-884d-00aa004b2e24 
Data.l $DC12A687 
Data.w $737F, $11CF 
Data.b $88, $4D, $00, $AA, $00, $4B, $2E, $24 
IID_IUnknown: 
    ;00000000-0000-0000-C000-000000000046 
Data.l $00000000 
Data.w $0000, $0000 
Data.b $C0, $00, $00, $00, $00, $00, $00, $46 

EndDataSection 
;} 


;/ TEST 
; MessageRequester("WMI",WMI("Select * FROM Win32_OperatingSystem,Name,CSDVersion,SerialNumber,RegisteredUser,Organization")) 
; MessageRequester("WMI",WMI("SELECT * FROM Win32_BIOS,Manufacturer,Caption,SerialNumber")) 
; MessageRequester("WMI",WMI("SELECT * FROM Win32_VideoController,DeviceID,Caption,AdapterDACType,DriverVersion,InstalledDisplayDrivers,CurrentBitsPerPixel,CurrentRefreshRate,CurrentHorizontalResolution,CurrentVerticalResolution" )) 
; MessageRequester("WMI",WMI("SELECT * FROM Win32_LogicalDisk,DeviceID,Description,VolumeName,FileSystem,size,FreeSpace,VolumeSerialNumber,Compressed")) 


;} WMI (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.25 FUNCTIONS ADDON ( 06/09/05 )
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                           ComputerSerialNumber                            |
;  |                           ____________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ComputerSerialNumber (Start)                                  

;/ Retrieve the Serial Number of Dell Computers

ProcedureDLL.s ComputerSerialNumber()
  Temp.s=WMI_int("SELECT * FROM Win32_BIOS,SerialNumber")
  Temp=StringField(Temp,2,"=")
  Temp=RemoveString(Temp," ")
  ProcedureReturn Temp
EndProcedure

;/ Test
; MessageRequester("DELL Serial Number",ComputerSerialNumber()) 



;} ComputerSerialNumber (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            NovellClientVersion                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NovellClientVersion (Start)                                   
; Return the Novell Client Version ( + Revision ) 
; Like 332SP2 or 490SP1

ProcedureDLL.s NovellClientVersion()
  
  ;/ Windows NT4/2K/XP
  If OSVersion()= #PB_OS_Windows_XP Or OSVersion()=#PB_OS_Windows_NT_4 Or OSVersion()=#PB_OS_Windows_2000
    Version.s= RegGetValue_int("HKEY_LOCAL_MACHINE\SOFTWARE\Novell\NetWareWorkstation\CurrentVersion","MajorVersion",".")
    Version+ RegGetValue_int("HKEY_LOCAL_MACHINE\SOFTWARE\Novell\NetWareWorkstation\CurrentVersion","MinorVersion",".")
    Version+ "SP"
    Version+RegGetValue_int("HKEY_LOCAL_MACHINE\SOFTWARE\Novell\NetWareWorkstation\CurrentVersion","Service Pack",".")
  EndIf
  
  ;/ Windows 95/98/ME
  If OSVersion()=#PB_OS_Windows_95 Or OSVersion()=#PB_OS_Windows_98 Or OSVersion()=#PB_OS_Windows_ME
    Version.s= RegGetValue_int("HKEY_LOCAL_MACHINE\Network\Novell\System Config\Install\Client Version","Major Version",".")
    Version+ RegGetValue_int("HKEY_LOCAL_MACHINE\Network\Novell\System Config\Install\Client Version","Minor Version",".")
    Version+ "SP"
    Version+Str(Hex2Dec(Left(RegGetValue_int("HKEY_LOCAL_MACHINE\Network\Novell\System Config\Install\Client Version","Service Pack","."),2)))
  EndIf
  
  If Version="00SP0" : Version ="":EndIf ; si version inexistante --> raz sortie
  ProcedureReturn Version
EndProcedure

;/ Test
; MessageRequester("Version Novell",NovellClientVersion())

;} NovellClientVersion (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.26 FUNCTIONS ADDON ( 26/09/05 )
;/
;/
;/
;/
;/


;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 BigString                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ BigString (Start)                                             
;/ Author : BugString by Deeém2031 and PureFan 
; Removed 25/05/2008 - PB strings unlimited natively
; You want bigger string than 64000 Kb 
; Or just lower memory-usage whether You use small strings? 
; Use this: (but don't use the big strings with "Debug", 
; the Debugger still have a limit To 64000B) 


; Structure EXCEPTIONREPORTRECORD 
;   ExceptionCode.l 
;   fHandlerFlags.l 
;   *NestedExceptionReportRecord.EXCEPTIONREPORTRECORD 
;   *ExceptionAddress.l 
;   cParameters.l 
;   ExceptionInfo.l[#EXCEPTION_MAXIMUM_PARAMETERS] 
; EndStructure 
; 
; Procedure StringExceptionHandler(*ExceptionInfo.EXCEPTION_POINTERS) 
;   Protected BigString_BaseEnd, tmp 
;   *ExceptionRecord.EXCEPTIONREPORTRECORD = *ExceptionInfo\pExceptionRecord 
;   If *ExceptionRecord\ExceptionCode = #EXCEPTION_ACCESS_VIOLATION 
;     If *ExceptionRecord\cParameters = 2 
;       BigString_BaseEnd = BigString_Base+BigString_BaseSize 
;       If *ExceptionRecord\ExceptionInfo[1]&$FFFFF000 = BigString_BaseEnd-$1000 
;         VirtualProtect_(BigString_BaseEnd-$1000,$1000,#PAGE_READWRITE,@tmp) 
;         If VirtualAlloc_(BigString_BaseEnd,$1000,#MEM_COMMIT,#PAGE_NOACCESS) 
;           BigString_BaseSize+$1000 
;           ProcedureReturn #EXCEPTION_CONTINUE_EXECUTION 
;         EndIf 
;         MessageRequester("Error","Kein Speicher mehr da, der String ist zu groß.",16) 
;       EndIf 
;     EndIf 
;   EndIf 
;   ProcedureReturn CallFunctionFast(BigString_OldExceptionHandler,*ExceptionInfo) 
; EndProcedure 
; 
; ProcedureDLL InitBigString() 
;   If BigString_Base 
;     VirtualFree_(BigString_Base, BigString_BaseSize, #MEM_RELEASE) 
;   EndIf 
;   
;   BigString_Base = VirtualAlloc_(#Null,$10000000,#MEM_RESERVE,#PAGE_READWRITE) 
;   If BigString_Base 
;     BigString_BaseSize = $2000 
;     !PUSH dword[PB_StringBase] 
;     !PUSH 0 
;     !PUSH dword[PB_MemoryBase] 
;     !EXTRN _HeapFree@12 
;     !CALL _HeapFree@12 
;     If VirtualAlloc_(BigString_Base,BigString_BaseSize,#MEM_COMMIT,#PAGE_READWRITE) 
;       !MOV dword[PB_StringBase], eax 
;       VirtualProtect_(BigString_Base+(BigString_BaseSize-$1000),$1000,#PAGE_NOACCESS,@tmp) 
;       BigString_OldExceptionHandler = SetUnhandledExceptionFilter_(@StringExceptionHandler()) 
;       ProcedureReturn #True 
;     EndIf 
;   EndIf 
;   ProcedureReturn #False 
; EndProcedure 
; 
; ProcedureDLL FreeBigString() 
;   VirtualFree_(BigString_Base, BigString_BaseSize, #MEM_RELEASE) 
;   SetUnhandledExceptionFilter_(BigString_OldExceptionHandler) 
;   !PUSH 64000 
;   !PUSH 8 ;HEAP_ZERO_MEMORY 
;   !PUSH dword[PB_MemoryBase] 
;   !EXTRN _HeapAlloc@12 
;   !CALL _HeapAlloc@12 
;   !MOV dword[PB_StringBase], Eax 
; EndProcedure 

;/ BigString Test
; If InitBigString()
  ; x.s=Space(9999999)
  ; MessageRequester("BigString Success","X = "+Str(Len(x))+" bytes")
  ; FreeBigString()
; Else
  ; MessageRequester("BigString Fail","Alloc-Prob",16) 
; EndIf


;} BigString (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 MouseMove                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MouseMove (Start)                                             
;/ Various Functions to Get/Set Mouse Cursor position / Mouse Click
; All tests are made @ 1024x768 / Bottom Taskbar

;{- Constants & Global Variables
#MOUSEEVENTF_WHEEL = $800 
;}

ProcedureDLL GetMouseX() ; Get the X coordinate of the mouse pointer
  Temp.POINT
  GetCursorPos_(Temp)
  ProcedureReturn Temp\x
EndProcedure

ProcedureDLL GetMouseY() ; Get the Y coordinate of the mouse pointer
  temp.POINT
  GetCursorPos_(temp)
  ProcedureReturn temp\y
EndProcedure

ProcedureDLL SetMouseXY(x,y) ; Set the Location of the mouse pointer
  SetCursorPos_(x,y)
EndProcedure

ProcedureDLL SetMouseClick(MouseEvent)
  ; #MOUSEEVENTF_LEFTDOWN
  ; #MOUSEEVENTF_LEFTUP
  ; #MOUSEEVENTF_RIGHTDOWN
  ; #MOUSEEVENTF_RIGHTUP
  mouse_event_(#MOUSEEVENTF_ABSOLUTE | MouseEvent, GetMouseX(),GetMouseY(),0,0)
EndProcedure

ProcedureDLL SetMouseWheel(Direction)
  If Direction ; 1= Wheel UP
    mouse_event_(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_WHEEL , GetMouseX(),GetMouseY(),120,0)
  Else ; 0 = Wheel Down
    mouse_event_(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_WHEEL , GetMouseX(),GetMouseY(),-120,0)
  EndIf
EndProcedure

ProcedureDLL PushMousePosition()
  MousePositionX=GetMouseX()
  MousePositionY=GetMouseY()
EndProcedure

ProcedureDLL PopMousePosition()
  SetMouseXY(MousePositionX,MousePositionY)
EndProcedure

;{/ Test GetMouseX & GetMouseY
; Repeat
  ; Delay(10)
; Debug Str(GetMouseX())+" "+Str(GetMouseY())
; ForEver
;}

;{/ Mouse Cursor follow an invisible circle
; NumBerOfPoints=1000
; CircleSize=200 
; Repeat 
  ; x=CircleSize* Cos( Current*(2*3.1415926/NumBerOfPoints)) 
  ; y=CircleSize* Sin( Current*(2*3.1415926/NumBerOfPoints))
  ; SetMouseXY(512+x,384+y)
  ; Delay(5)
  ; Current+1  
; Until Current=NumBerOfPoints
;} 

;{/ Clic over Start Menu
; SetMouseXY(79,749)
; SetMouseClick(#MOUSEEVENTF_LEFTDOWN)
; SetMouseClick(#MOUSEEVENTF_LEFTUP)
;}

;{/ Double Clic on Clock in Systray ( Conserve the Mouse Location )
; PushMousePosition()
; SetMouseXY(992,750)
; SetMouseClick(#MOUSEEVENTF_LEFTDOWN)
; SetMouseClick(#MOUSEEVENTF_LEFTUP)
; SetMouseClick(#MOUSEEVENTF_LEFTDOWN)
; SetMouseClick(#MOUSEEVENTF_LEFTUP)
; PopMousePosition()
;}

;{/ Right Clic over Start Menu
; SetMouseXY(79,749)
; SetMouseClick(#MOUSEEVENTF_RIGHTDOWN)
; SetMouseClick(#MOUSEEVENTF_RIGHTUP)
;}

;{/ Wheel Test ( 0 Down / 1 Up )
; For n=1 To 5
  ; Delay(250)
  ; Beep(1000,25)
  ; SetMouseWheel(1)
; Next
; For n=1 To 5
  ; Delay(250)
  ; Beep(500,25)
  ; SetMouseWheel(0)
; Next
;}

;} MouseMove (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  NTCore                                   |
;  |                                  ______                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NTCore (Start)                                                
;/ Return 1 if OS has a NT Core ( NT/2K/XP/... ) / 0 if W95/98/ME

ProcedureDLL NTCore() 
  Core=1
  If OSVersion()=#PB_OS_Windows_95 Or OSVersion()=#PB_OS_Windows_98 Or OSVersion()=#PB_OS_Windows_ME
    Core=0
  EndIf
  ProcedureReturn Core
EndProcedure

;/ Test
; If NTCore()
  ; MessageRequester("NTCore","Yes")
; Else
  ; MessageRequester("NTCore","No")
; EndIf


;} NTCore (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          ReturnKeyToButtonClick                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ReturnKeyToButtonClick (Start)                                
;/ Simulate a left click when you press ENTER over an activated Button
;/ Author: Nico & Droopy 

ProcedureDLL ReturnKeyToButtonClick(Window) 
  If EventwParam()=#VK_RETURN
    handle=GetFocus_() 
    Buffer.s=Space(255) 
    GetClassName_(handle,@Buffer,Len(Buffer)) 
    If Buffer="Button" 
      PostMessage_(WindowID(Window),#WM_COMMAND,#PB_EventType_LeftClick<<16,handle) 
    EndIf 
  EndIf
EndProcedure 

;{/ Test
; #Window_0=0 
; #Button_0=1 
; #Button_1=2 
; 
; OpenWindow(#Window_0, 216, 0, 130, 111,  #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_TitleBar |#PB_Window_ScreenCentered, "Return Test") 
; CreateGadgetList(WindowID()) 
; ButtonGadget(#Button_0, 10, 10, 110, 40, "OK") 
; ButtonGadget(#Button_1, 10, 60, 110, 40, "CANCEL") 
; ActivateGadget(#Button_0) 
; 
; Repeat 
  ; 
  ; Select WaitWindowEvent() 
    ; 
    ; ;/ Manage Event when user press RETURN key 
    ; Case #WM_KEYDOWN
      ; ReturnKeyToButtonClick(#Window_0) 
      ; 
      ; ;/ Manage Gadget event 
    ; Case #PB_Event_Gadget 
      ; Select EventGadgetID() 
        ; 
        ; Case #Button_0
          ; beep_(400,250) 
          ; 
        ; Case #Button_1 
          ; beep_(800,250) 
          ; 
      ; EndSelect 
      ; 
    ; Case #WM_CLOSE 
      ; End 
      ; 
  ; EndSelect 
; ForEver
;}

;} ReturnKeyToButtonClick (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              SetMouseCursor                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SetMouseCursor (Start)                                        

; #IDC_ARROW    	    ; Arrow cursor
; #IDC_IBEAM	        ; I-beam cursor
; #IDC_WAIT	          ; Hourglass cursor
; #IDC_CROSS	        ; Crosshair cursor
; #IDC_UPARROW	      ; Up Arrow cursor
; #IDC_SIZENWSE	      ; Sizing cursor, points northwest And southeast
; #IDC_SIZENESW	      ; Sizeing cursor, points northeast And southwest
; #IDC_SIZEWE	        ; Sizing cursor, points west And east
; #IDC_SIZENS	        ; Sizing cursor, points north And south
; #IDC_SIZEALL	      ; Sizing cursor, points north, south, east, And west
; #IDC_NO   	        ; "No" cursor
; #IDC_APPSTARTING    ; Application-starting cursor (Arrow And Hourglass)
; #IDC_HELP	          ; Help cursor (Arrow And question mark)
; #IDI_APPLICATION	  ; Application icon
; #IDI_HAND	          ; Stop sign icon
; #IDI_QUESTION	      ; question-mark icon
; #IDI_EXCLAMATION	  ; Exclamation point icon
; #IDI_ASTERISK	      ; Asterisk icon (letter "i" in a circle)
; #IDI_WINLOGO	      ; Windows logo icon 

ProcedureDLL SetMouseCursor(Type, windowid)
  SetClassLongPtr_(WindowID,#GCL_HCURSOR,LoadCursor_(0,Type))
EndProcedure

;{/ Test
; OpenWindow(0, 0, 0, 400, 300, #PB_Window_ScreenCentered | #PB_Window_SystemMenu  , "PureBasic Window")
; SetMouseCursor(#IDC_NO)
; WaitUntilWindowIsClosed()
;}



;} SetMouseCursor (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 WindowFx                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WindowFx (Start)                                              
; Paul Leischow 
; Cool window FX for your apps (fade in/out, slide,wipe)

;{/ Constants in Droopy.res
#AW_HOR_POSITIVE = $1 ; Animates the window from left To right. This flag can be used with roll Or slide animation.
#AW_HOR_NEGATIVE = $2 ; Animates the window from right To left. This flag can be used with roll Or slide animation.
#AW_VER_POSITIVE = $4 ; Animates the window from top To bottom. This flag can be used with roll Or slide animation.
#AW_VER_NEGATIVE = $8 ; Animates the window from bottom To top. This flag can be used with roll Or slide animation.
#AW_CENTER = $10      ; Makes the window appear To collapse inward If AW_HIDE is used Or expand outward If the AW_HIDE is not used.
#AW_HIDE = $10000     ; Hides the window. By default, the window is shown.
#AW_ACTIVATE = $20000 ; Activates the window.
#AW_SLIDE = $40000    ; Uses slide animation. By default, roll animation is used.
#AW_BLEND = $80000    ; Uses a fade effect. This flag can be used only If hwnd is a top-level window.
;}

ProcedureDLL WindowFx(Id,ms,fx)
  AnimateWindow_(Id,ms,fx)
EndProcedure

;{- WindowFx Tests 
; ;/ 1° Test   
; OpenWindow(0,0,0,100,768,#PB_Window_SystemMenu|#PB_Window_Invisible,"Window FX")
; WindowFx(WindowID(),500,#AW_HOR_POSITIVE|#AW_SLIDE|#AW_ACTIVATE)
; WaitUntilWindowIsClosed()
; AnimateWindow_(WindowID(),500,#AW_HOR_NEGATIVE|#AW_SLIDE|#AW_HIDE)
; Delay(500)
; 
 ; 
; ;/ 2° Test   
; OpenWindow(0,0,0,1024,100,#PB_Window_SystemMenu|#PB_Window_Invisible,"Window FX")
; WindowFx(WindowID(),500,#AW_VER_POSITIVE|#AW_SLIDE|#AW_ACTIVATE)
; WaitUntilWindowIsClosed()
; AnimateWindow_(WindowID(),500,#AW_VER_NEGATIVE|#AW_SLIDE|#AW_HIDE)
; Delay(500)
; 
; ;/ 3° Test
; OpenWindow(0,0,0,200,200,#PB_Window_SystemMenu|#PB_Window_Invisible|#PB_Window_ScreenCentered,"Window FX")
; WindowFx(WindowID(),1000,#AW_BLEND|#AW_ACTIVATE)
; WaitUntilWindowIsClosed()
; AnimateWindow_(WindowID(),1000,#AW_BLEND|#AW_HIDE)
; Delay(500)

;}


;} WindowFx (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.27 FUNCTIONS ADDON ( 12/10/05 )
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetPartOfFile                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetPartOfFile (Start)                                         
;Author : Dr Dri / lionel_om / Droopy
; Return a part of file
; This function replace : GetPathPart() GetFilePart() GetExtensionPart()
; You can use this constants ( Pipe Allowed )
#GFP_Drive=1
#GFP_Path=2
#GFP_File=4
#GFP_Extension=8


ProcedureDLL.s GetPartOfFile(File.s, Part.l)
  
  Protected Temp.s , TempPathPart.s , TempFilePart.s  , TempExtensionPart.s
  
  TempPathPart=GetPathPart(File)
  TempFilePart=GetFilePart(File)
  TempExtensionPart=GetExtensionPart(File)
  
  ;/ Drive
  If Part & #GFP_Drive
    Temp+Left(File,2)
    If Part & #GFP_Path : Temp+"\":EndIf
  EndIf
  
  
  ;/ Path
  If Part & #GFP_Path
    Temp+Mid(TempPathPart,4,Len(TempPathPart)-4)
    If Part & #GFP_File : Temp+"\":EndIf
  EndIf
  
  
  ;/ File
  If Part & #GFP_File
    If Len(TempExtensionPart)
      Temp+Left(TempFilePart, Len(TempFilePart)-1-Len(TempExtensionPart)) 
    Else
      Temp+File
    EndIf
    If Part & #GFP_Extension : Temp+".":EndIf
  EndIf
  
  
  ;/ Extension
  If Part & #GFP_Extension
    Temp+TempExtensionPart
  EndIf
  
  ProcedureReturn Temp
  
EndProcedure    

;/ Test
; #file="C:\Directory\SubDirectory\File.exe"
; MessageRequester("",GetPartOfFile(#file,#GFP_Drive))
; MessageRequester("",GetPartOfFile(#file,#GFP_Path))
; MessageRequester("",GetPartOfFile(#file,#GFP_File))
; MessageRequester("",GetPartOfFile(#file,#GFP_Extension))
; MessageRequester("",GetPartOfFile(#file,#GFP_Drive|#GFP_Path|#GFP_File|#GFP_Extension))



;} GetPartOfFile (End)

; LocaleDate replaced by new one ( Sublang as optional parameters ) in Droopy Lib 1.28

;  _____________________________________________________________________________
;  |                                                                           |
;  |                               NextDirectory                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NextDirectory (Start)                                         
;/ Author : lionel_om
; Same Function as NextDirectoryEntry() but don't return the 2 directories "." and ".." 
ProcedureDLL NextDirectory(directorynum) 
  Protected FileType.b, FileName$ 
  
  FileType = NextDirectoryEntry(directorynum) 
  If FileType = 2 
    FileName$ = DirectoryEntryName(directorynum) 
    If FileName$ = "." Or FileName$ = ".." 
      ProcedureReturn(NextDirectory(directorynum)) 
    EndIf 
  EndIf 
  ProcedureReturn(FileType) 
  
EndProcedure

;/ Test
; ExamineDirectory(0,GetWindowsDirectory(),"*.*")
; While NextDirectory()
  ; Debug DirectoryEntryName()
; Wend


;} NextDirectory (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            RunProgramAtStartup                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RunProgramAtStartup (Start)                                   
;/ RunProgramAtStartup 
; WichUser = 1 : All User / 0 Current User
; RunOrRunOnce = 1 : Run / 0 RunOnce
; Name = Name that appear in Msconfig
; CommandLine = Command to execute
; Return 1 if success / 0 if fail

;/ DelProgramAtStartup
; WichUser = 1 : All User / 0 Current User
; RunOrRunOnce = 1 : Run / 0 RunOnce
; Name = Name that appear in Msconfig
; Return 1 if success / 0 if fail

;/ IsProgramRunAtStartup
; WichUser = 1 : All User / 0 Current User
; RunOrRunOnce = 1 : Run / 0 RunOnce
; Name = Name that appear in Msconfig
; Return the CommandLine if Name Exist / "" if Name don't exist / "Empty" if CommandLine is Empty

ProcedureDLL RunProgramAtStartup(WichUser.l,RunOrRunOnce.l,Name.s,CommandLine.s)
  
  If WichUser=1
    Key.s="HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run"
  Else
    Key="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
  EndIf
  
  If RunOrRunOnce=0
    Key+"Once"
  EndIf
  
  ProcedureReturn RegCreateKeyValue(Key,Name,CommandLine,#REG_SZ ,".")
  
EndProcedure

ProcedureDLL DelProgramAtStartup(WichUser.l,RunOrRunOnce.l,Name.s)
  
  If WichUser=1
    Key.s="HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run"
  Else
    Key="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
  EndIf
  
  If RunOrRunOnce=0
    Key+"Once"
  EndIf
  
  ProcedureReturn RegDeleteValue(Key,Name,".")
  
EndProcedure
  
ProcedureDLL.s IsProgramRunAtStartup(WichUser.l,RunOrRunOnce.l,Name.s)
  
  If WichUser=1
    Key.s="HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run"
  Else
    Key="HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
  EndIf
  
  If RunOrRunOnce=0
    Key+"Once"
  EndIf
  
  If RegValueExists(Key,Name,".")
    retour.s=RegGetValue_int(Key,Name,".")
    If retour="" : retour="Empty" : EndIf
  Else
    retour=""
  EndIf
  
  ProcedureReturn retour
EndProcedure  

;/ Test
; Debug RunProgramAtStartup(1,1,"Abracadabra","c:\windows\regedit.exe") ; Add to Startup
; 
; Temp.s= IsProgramRunAtStartup(1,1,"Abraca dabra")  ; Test if present in Startup
; Select Temp
  ; Case ""
    ; Debug "This entry does not exist"
  ; Case "Empty"
    ; Debug "Entry exist but CommandLine is empty !"
  ; Default
    ; Debug "CommandLine = "+Temp
; EndSelect
; 
; Debug DelProgramAtStartup(1,1,"Abracadabra") ; Remove from Startup

;} RunProgramAtStartup (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Week                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Week (Start)                                                  

;/ Return the week count of the year

ProcedureDLL Week(Date.l)
  
  Compteur=Date(Year(Date),1,1,0,0,1) ;/ New year day
  
  ;/ Goto 1st monday 
  Repeat
    If DayOfWeek(Compteur)=1 : Break : EndIf
    Compteur=AddDate(Compteur,#PB_Date_Day,1)
  ForEver
  
  ;/ Add 1 week / Test if date is reach
  Repeat
    If Compteur>Date : Break : EndIf
    Compteur=AddDate(Compteur,#PB_Date_Week,1)
    Week+1
  ForEver
  
  ProcedureReturn Week
EndProcedure
  
;/ Test  
; MessageRequester("Week n°",Str(Week(Date())),#MB_ICONINFORMATION)



;} Week (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.28 FUNCTIONS ADDON ( 26/11/05 )
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                               AssociateFile                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ AssociateFile (Start)                                         
; English forum: http://purebasic.myforums.net/viewtopic.php?t=6763&highlight=
; Author: GPI (updated for PB3.92+ by Lars)
; Date: 29. June 2003

;  You need to logoff / logon or reboot to view associated icon !?

; Command : like "open" or "print"
; AssociateFileEx(Extension,Extension Description,FullProgramPath&Name,Icon,just programname,command Description,command)

; AssociateFile(Extension,Extension Description,FullProgramPath&Name,Icon) 
; if icon ="" the icon is the same as the exe

Procedure SetKey(fold,Key$,Subkey$,Type,Adr,len) 
  If RegCreateKeyEx_(fold, Key$, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_ALL_ACCESS, 0, @NewKey, @KeyInfo) = #ERROR_SUCCESS 
    RegSetValueEx_(NewKey, Subkey$, 0, Type,  Adr, len) 
    RegCloseKey_(NewKey) 
  EndIf 
EndProcedure 

ProcedureDLL AssociateFileEx(ext$,ext_description$,programm$,Icon$,prgkey$,cmd_description$,cmd_key$) 
  cmd$=Chr(34)+programm$+Chr(34)+" "+Chr(34)+"%1"+Chr(34) 
  If NTCore()  ;  Windows NT/XP 
    SetKey(#HKEY_CLASSES_ROOT, "Applications\"+prgkey$+"\shell\"+cmd_description$+"\command","",#REG_SZ    ,@cmd$,Len(cmd$)+1) 
    If ext_description$ 
      Key$=ext$+"_auto_file" 
      SetKey(#HKEY_CLASSES_ROOT  ,"."+ext$           ,"",#REG_SZ,@Key$,Len(Key$)+1) 
      SetKey(#HKEY_CLASSES_ROOT  ,Key$               ,"",#REG_SZ,@ext_description$,Len(ext_description$)+1) 
      If Icon$ 
        SetKey(#HKEY_CLASSES_ROOT,Key$+"\DefaultIcon","",#REG_SZ,@Icon$,Len(Icon$)+1) 
      EndIf 
    EndIf 
    SetKey(#HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\."+ext$,"Application",#REG_SZ,@prgkey$         ,Len(prgkey$)+1) 
  Else ;  Windows 9x 
    SetKey(#HKEY_LOCAL_MACHINE,"Software\Classes\."+ext$                        ,"",#REG_SZ,@prgkey$         ,Len(prgkey$)+1) 
    If ext_description$ 
      SetKey(#HKEY_LOCAL_MACHINE,"Software\Classes\"+prgkey$                   ,"",#REG_SZ,@ext_description$,Len(ext_description$)+1) 
    EndIf 
    If Icon$ 
      SetKey(#HKEY_LOCAL_MACHINE,"Software\Classes\"+prgkey$+"\DefaultIcon"    ,"",#REG_SZ,@Icon$           ,Len(Icon$)+1) 
    EndIf 
    If cmd_description$<>cmd_key$ 
      SetKey(#HKEY_LOCAL_MACHINE,"Software\Classes\"+prgkey$+"\shell\"+cmd_key$,"",#REG_SZ,@cmd_description$,Len(cmd_description$)+1) 
    EndIf 
    SetKey(#HKEY_LOCAL_MACHINE,"Software\Classes\"+prgkey$+"\shell\"+cmd_key$+"\command","",#REG_SZ,@cmd$   ,Len(cmd$)+1) 
  EndIf 
EndProcedure 

ProcedureDLL AssociateFile(ext$,ext_description$,programm$,Icon$) 
  AssociateFileEx(ext$,ext_description$,programm$,Icon$,GetFilePart(programm$),"open","open")  
EndProcedure 

ProcedureDLL RemoveAssociateFile(ext$,prgkey$) 
  If NTCore() ; Windows NT/XP 
    RegDeleteKeyWithAllSub("HKEY_CLASSES_ROOT\Applications\"+prgkey$,"") 
    Key$=ext$+"_auto_file" 
    RegDeleteKeyWithAllSub("HKEY_CLASSES_ROOT\."+ext$,".") 
    RegDeleteKeyWithAllSub("HKEY_CLASSES_ROOT\"+Key$,".") 
    RegDeleteKeyWithAllSub("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\."+ext$,".") 
  Else ;Windows 9x 
    RegDeleteKeyWithAllSub("HKEY_LOCAL_MACHINE\Software\Classes\."+ext$,".") 
    RegDeleteKeyWithAllSub("HKEY_LOCAL_MACHINE\Software\Classes\"+prgkey$,"") 
  EndIf 
EndProcedure 

;/ Test 1 : AssociateFileEx
; AssociateFileEx("bbb","File type bbb","c:\windows\notepad.exe","c:\windows\divx.ico","notepad.exe","Open the File","open")

;/ Test 2 : AssociateFile
; AssociateFile("bbb","bbb file associated by PureBasic","c:\windows\notepad.exe","c:\windows\divx.ico") 


;/ And to remove association
; RemoveAssociateFile("bbb","notepad.exe")

;} AssociateFile (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                BlockInput                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ BlockInput (Start)                                            

; Inhibit keyboard & Mouse
; PureBasic 3.93
; 
; Windows 9x : 
; Caution : The keyboard And Mouse are disabled Until Next reboot
; State.l don't care / Return : Nothing
; 
; Other OS  :
; State.l = #True --> Locked / #False --> Unlocked
; Return 1 is sucess / 0 If error Or always Locked
  

ProcedureDLL BlockInput(State.l)
  
  If NTCore() ;/ NT Core
    
    If State.l=#True
      retour=BlockInput_(#True)
      
    EndIf
    
    If State.l=#False
      retour=BlockInput_(#False)
    EndIf
    
    If retour <>0 : retour =1 : EndIf
    
  Else ;/ Windows 9x
    
    RunProgram("RunDll32.exe","MOUSE,DISABLE","")
    RunProgram("RunDll32.exe","KEYBOARD,DISABLE","")
    
  EndIf
  
  ProcedureReturn retour
  
EndProcedure

 
;/ Test
; If NTCore()
  ; MessageRequester("Info","5 seconds with keyboard & Mouse locked")
  ; BlockInput(#True)
  ; Delay(5000)
  ; BlockInput(#False)
  ; MessageRequester("Keyboard & Mouse","Are Unlocked")
; Else
  ; BlockInput(#True)
  ; MessageRequester("Keyboard & Mouse disable","Sorry, you must Reset !")
; EndIf

  
  






;} BlockInput (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 BootState                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ BootState (Start)                                             
;/ Author : Gillou

; Return the system Boot state
; 0 Normal boot / 1 Fail-safe boot / 2 Fail-safe with network boot

ProcedureDLL BootState() 
  ProcedureReturn GetSystemMetrics_(#SM_CLEANBOOT) 
EndProcedure 

;/ Test
; Select BootState()
  ; Case 0
    ; MessageRequester("Boot","Normal boot")
  ; Case 1
    ; MessageRequester("Boot","Fail-safe boot")
  ; Case 2
    ; MessageRequester("Boot","Fail-safe with network boot")
; EndSelect

    

;} BootState (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  Capture                                  |
;  |                                  _______                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Capture (Start)                                               
;/ Author : Kale / Droopy

; CaptureScreenPart / CaptureFullScreen / CaptureWindow : Return pointer to BMP SnapShot

; SaveCapture : 
; ImagePlugin = #PB_ImagePlugin_BMP / #PB_ImagePlugin_JPEG / #PB_ImagePlugin_PNG
; JpegCompression = JpegCompression 0 (Bad) to 10 (Best) --> Only for Jpeg

ProcedureDLL CaptureScreenPart(Left.l, Top.l, width.l, height.l) 
  dm.DEVMODE 
  BMPHandle.l 
  srcDC = CreateDC_("DISPLAY", "", "", dm) 
  trgDC = CreateCompatibleDC_(srcDC) 
  BMPHandle = CreateCompatibleBitmap_(srcDC, Width, Height) 
  SelectObject_( trgDC, BMPHandle) 
  BitBlt_( trgDC, 0, 0, Width, Height, srcDC, Left, Top, #SRCCOPY) 
  DeleteDC_( trgDC) 
  ReleaseDC_( BMPHandle, srcDC)
  
  CaptureScreenHeight=Height
  CaptureScreenWidth=Width
  CaptureScreenBMPHandle=BMPHandle
  ProcedureReturn BMPHandle 
EndProcedure 

ProcedureDLL CaptureFullScreen()
  ProcedureReturn CaptureScreenPart(0,0,GetSystemMetrics_(#SM_CXSCREEN),GetSystemMetrics_(#SM_CYSCREEN))
EndProcedure

ProcedureDLL CaptureWindow(handle.l) ; ### The Window must be visible !
  
  If Handle 
    WindowSize.RECT 
    GetWindowRect_(Handle, @WindowSize) 
    ProcedureReturn CaptureScreenPart(WindowSize\Left, WindowSize\Top, WindowSize\Right - WindowSize\Left, WindowSize\Bottom - WindowSize\Top) 
  EndIf
  
EndProcedure 

ProcedureDLL SaveCapture(File.s, ImagePlugin , JpegCompression) 
  
  If CaptureScreenBMPHandle
    Id=CreateImage(#PB_Any, CaptureScreenWidth, CaptureScreenHeight) 
    StartDrawing(ImageOutput(id)) 
    DrawImage(CaptureScreenBMPHandle,0,0) 
    StopDrawing()
    
    Select ImagePlugin
      
      Case #PB_ImagePlugin_JPEG 
        UseJPEGImageEncoder()
        Retour=SaveImage(Id, File,#PB_ImagePlugin_JPEG,JpegCompression)
        
      Case #PB_ImagePlugin_PNG
        UsePNGImageEncoder()
        Retour=SaveImage(Id, File,#PB_ImagePlugin_PNG)
        
      Default
        Retour=SaveImage(Id, File)
        
    EndSelect
    
    FreeImage(Id)
    
  EndIf
  
  ProcedureReturn Retour
EndProcedure


;/ Test
; CaptureFullScreen()
; SaveCapture("c:\CaptureFullScreen.png",#PB_ImagePlugin_PNG,0)
; SaveCapture("c:\CaptureFullScreen.bmp",0,0)
; SaveCapture("c:\CaptureFullScreen.Jpg",#PB_ImagePlugin_JPEG,10)




;} Capture (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           ChangeDisplaySettings                           |
;  |                           _____________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ChangeDisplaySettings (Start)                                 
;/ Author : DarkDragon / Gillou

;  Constants Added to the Droopy.res
#DISP_CHANGE_SUCCESSFUL = 0   ; The settings change was successful.
#DISP_CHANGE_RESTART = 1      ; The computer must be restarted in order for the graphics mode to work.
#DISP_CHANGE_BADFLAGS = -4    ; An invalid set of flags was passed in.
#DISP_CHANGE_FAILED = -1      ; The display driver failed the specified graphics mode.
#DISP_CHANGE_BADMODE = -2     ; The graphics mode is not supported.
#DISP_CHANGE_NOTUPDATED = -3  ; Windows NT only: Unable to write settings to the registry.

ProcedureDLL ChangeDisplaySettings(width,height,Depth,Freq,Permanent)
  dmScreenSettings.DEVMODE 
  dmScreenSettings\dmSize = SizeOf(dmScreenSettings) 
  dmScreenSettings\dmPelsWidth = width
  dmScreenSettings\dmPelsHeight = height
  dmScreenSettings\dmBitsPerPel = Depth
  dmScreenSettings\dmDisplayFrequency=Freq
  dmScreenSettings\dmFields = 262144 | 524288 | 1048576 
  
  If Permanent
    retour=ChangeDisplaySettings_(@dmScreenSettings, 1) 
  Else
    retour=ChangeDisplaySettings_(@dmScreenSettings, 4) 
  EndIf
  
  ProcedureReturn retour
EndProcedure

;/ Test
; ChangeDisplaySettings(1024,768,16,70,0)
; MessageRequester("Change Display Settings","OK to Restore")

;} ChangeDisplaySettings (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          CheckInternetConnection                          |
;  |                          _______________________                          |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CheckInternetConnection (Start)                               
; Return : 
; 0x40 INTERNET_CONNECTION_CONFIGURED : Local system has a valid connection To the Internet, but it might Or might not be currently connected. 
; 0x02 INTERNET_CONNECTION_LAN : Local system uses a Local area network To connect To the Internet. 
; 0x01 INTERNET_CONNECTION_MODEM : Local system uses a modem To connect To the Internet. 
; 0x08 INTERNET_CONNECTION_MODEM_BUSY : No longer used. 
; 0x20 INTERNET_CONNECTION_OFFLINE : Local system is in offline mode. 
; 0x04 INTERNET_CONNECTION_PROXY : Local system uses a proxy server To connect To the Internet. 
; 0x10 INTERNET_RAS_INSTALLED : Local system has RAS installed
; Or 0 If  there is No Internet connection

;  A mettre dans Droopy.res

#INTERNET_CONNECTION_CONFIGURED =$40 
#INTERNET_CONNECTION_LAN = $02 
#INTERNET_CONNECTION_MODEM =$1
#INTERNET_CONNECTION_MODEM_BUSY =$8
#INTERNET_CONNECTION_OFFLINE =$20
#INTERNET_CONNECTION_PROXY =$4
#INTERNET_RAS_INSTALLED =$10

ProcedureDLL CheckInternetConnection()
  InternetGetConnectedState_(@retour, 0) 
  ProcedureReturn retour
EndProcedure

;/ Test
; 
; State=CheckInternetConnection()
; 
; If State=0 : Temp.s="No Internet Connection" : EndIf
; If State & #INTERNET_CONNECTION_CONFIGURED : Temp="INTERNET_CONNECTION_CONFIGURED"+#CRLF$ : EndIf
; If State & #INTERNET_CONNECTION_LAN : Temp+"INTERNET_CONNECTION_LAN"+#CRLF$ :EndIf
; If State & #INTERNET_CONNECTION_MODEM : Temp+"INTERNET_CONNECTION_MODEM"+#CRLF$ : EndIf
; If State & #INTERNET_CONNECTION_MODEM_BUSY : Temp+"INTERNET_CONNECTION_MODEM_BUSY"+#CRLF$ : EndIf
; If State & #INTERNET_CONNECTION_OFFLINE : Temp+"INTERNET_CONNECTION_OFFLINE"+#CRLF$ : EndIf
; If State & #INTERNET_CONNECTION_PROXY : Temp+"INTERNET_CONNECTION_PROXY"+#CRLF$ : EndIf
; If State & #INTERNET_RAS_INSTALLED : Temp+"INTERNET_RAS_INSTALLED"+#CRLF$ : EndIf
; 
; MessageRequester("Internet Connexion",Temp)  


;} CheckInternetConnection (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             CommandLineShell                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CommandLineShell (Start)                                      
;/ Gillou

ProcedureDLL.s CommandLineShell() ;  
  ;cmd$ = Space(255) : GetEnvironmentVariable_("comspec", @cmd$, 255) 
  ProcedureReturn GetEnvironmentVariable("comspec");cmd$ 
EndProcedure 

;/ Test
; MessageRequester("Command Line Shell",CommandLineShell())

;} CommandLineShell (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              CreateSizedFile                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CreateSizedFile (Start)                                       

; Each Block is 1MB
; If you want 100Mb File : Block = 100
; The limit is 4Gb file ( Block = 4000 )

ProcedureDLL CreateSizedFile(File.s,Block)
  *Tampon=AllocateMemory(1024*1024) ;/ Each Packet is 1Mb
  CreateFile(0,File)
  
  For n=1 To Block
    FileSeek(0, Lof(0))
    WriteData(0, *Tampon,1024*1024)
  Next
  
  CloseFile(0)
  FreeMemory(*Tampon)
EndProcedure


;/ Test ( Create a 100MB file )
; #File="C:\Big.bin"
; CreateSizedFile(#File,1000)
; MessageRequester(#File,Str(FileSize(#File)/1024/1024)+" MB")




;} CreateSizedFile (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               EnableWindow                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ EnableWindow (Start)                                          

; This function enables Or disables mouse And keyboard input To The specified window Or control. 


ProcedureDLL EnableWindow(handle,State)
  Retour=EnableWindow_(Handle,State)
  If Retour<>0 : Retour =1 : EndIf
  ProcedureReturn Retour
EndProcedure

; The IsWindowEnabled function determines whether The specified window is enabled For mouse And keyboard input
ProcedureDLL IsWindowEnabled(handle)
  Retour=IsWindowEnabled_(Handle)
  If Retour<>0 : Retour =1 : EndIf
  ProcedureReturn Retour
EndProcedure



;/ Test

; Procedure EnableWindowAfterTenSeconds(Handle)
  ; Delay(10000)
  ; Beep(1000,700)
  ; EnableWindow(Handle,#True)
; EndProcedure
; 
; x=OpenWindow(0,0,0,222,200,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"ButtonGadgets")
; EnableWindow(x,#False)
; CreateGadgetList(WindowID(0))
; ButtonGadget(0, 10, 10, 200, 20, "Standard Button")
; ButtonGadget(1, 10, 40, 200, 20, "Left Button", #PB_Button_Left)
; ButtonGadget(2, 10, 70, 200, 20, "Right Button", #PB_Button_Right)
; ButtonGadget(3, 10,100, 200, 60, "Multiline Button  (longer text gets automatically wrapped)", #PB_Button_MultiLine)
; ButtonGadget(4, 10,170, 200, 20, "Toggle Button", #PB_Button_Toggle)
; CreateThread(@EnableWindowAfterTenSeconds(),x)
; WaitUntilWindowIsClosed()







;} EnableWindow (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            EnumDisplaySettings                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ EnumDisplaySettings (Start)                                   
;/ Author : Gillou


ProcedureDLL.s EnumDisplay() 
  Static b
  If b > -1
    If EnumDisplaySettings_(0,b,dmEcran.DEVMODE)
      retour.s=Str (dmEcran\dmPelsWidth)+","+ Str (dmEcran\dmPelsHeight)+","+ Str (dmEcran\dmBitsPerPel) + ","+Str(dmEcran\dmDisplayFrequency)
    Else
      b=-2
    EndIf
  EndIf
  b=b+1
  ProcedureReturn retour
EndProcedure

;/ Test
; x.s=EnumDisplay()
; While x<>""
  ; Debug x
  ; x.s=EnumDisplay()
; Wend


;} EnumDisplaySettings (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                EnumProcess                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ EnumProcess (Start)                                           
;/ Author : Fred


Structure PROCESSENTRY32_droopy; - MAY be able to be deleted
  dwSize.l 
  cntUsage.l 
  th32ProcessID.l 
  th32DefaultHeapID.l 
  th32ModuleID.l 
  cntThreads.l 
  th32ParentProcessID.l 
  pcPriClassBase.l 
  dwFlags.l 
  szExeFile.b[#MAX_PATH] 
EndStructure 

#TH32CS_SNAPPROCESS = $2 

ProcedureDLL EnumProcessInit() 
  
  Static Initialised
  If Initialised=0
    Global NewList EnumProcessLList.s()
    Initialised=1
  Else
    ClearList(EnumProcessLList())
  EndIf
  
  kernel32 = OpenLibrary(#PB_Any, "Kernel32.dll") 
  If kernel32
    
    CreateToolhelpSnapshot = GetFunction(0, "CreateToolhelp32Snapshot") 
    ProcessFirst           = GetFunction(0, "Process32First") 
    ProcessNext            = GetFunction(0, "Process32Next") 
    
    If CreateToolhelpSnapshot And ProcessFirst And ProcessNext ; Ensure than all the functions are found 
      
      Process.PROCESSENTRY32\dwSize = SizeOf(PROCESSENTRY32) 
      
      Snapshot = CallFunctionFast(CreateToolhelpSnapshot, #TH32CS_SNAPPROCESS, 0) 
      If Snapshot 
        
        ProcessFound = CallFunctionFast(ProcessFirst, Snapshot, Process) 
        While ProcessFound 
          Temp.s=PeekS(@Process\szExeFile) 
          If Temp<>"[System Process]"
            AddElement(EnumProcessLList())
            EnumProcessLList()= Temp
          EndIf
          ProcessFound = CallFunctionFast(ProcessNext, Snapshot, Process) 
          
        Wend 
      EndIf 
      
      CloseHandle_(Snapshot) 
    EndIf 
    
    CloseLibrary(kernel32) 
  EndIf
  
  ResetList(EnumProcessLList())
  ProcedureReturn ListSize(EnumProcessLList())
  
EndProcedure 

ProcedureDLL.s EnumProcess()
  
  Static Pointeur
  
  If Pointeur >= ListSize(EnumProcessLList())
    Pointeur=0
  Else
    SelectElement(EnumProcessLList(),Pointeur)
    Retour.s=EnumProcessLList()
    Pointeur+1
  EndIf
  
  ProcedureReturn Retour.s
EndProcedure

;/ Test
; Title.s=Str(EnumProcessInit())+ " Process found"
; 
; Repeat
  ; Temp.s=EnumProcess()
  ; Message.s+Temp+#CRLF$
; Until Temp=""
; 
; MessageRequester(Title,Message)


;} EnumProcess (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetDesktopHandle                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetDesktopHandle (Start)                                      

;/ Get the Handle of the Desktop
; Useful for creating Systray Icon without opening a window or creating an invisible window

ProcedureDLL GetDesktopHandle()
  ProcedureReturn GetDesktopWindow_()
EndProcedure


;/ Test
; AddSysTrayIcon(0,GetDesktopHandle(),ExtractIcon_(0,"c:\windows\regedit.exe",0))
; Delay(2000)
; Beep(1400,250)
  


;} GetDesktopHandle (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetDirectorySize                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetDirectorySize (Start)                                      

;/ Return Size of a Directory ( in KB )

Procedure SearchDirectorySize(Path.s)
  
  ; Add \ to Path if missing
  If Right(Path,1)<>"\" : Path+"\":EndIf
  
  ; Apply Structure
  lpFindFileData.WIN32_FIND_DATA
  
  ; Add Filter *.*
  Recherche.s=Path+"*.*"
  
  ; Initiate the Search
  handle.i = FindFirstFile_(Recherche, @lpFindFileData)
  
  ; If search succeeds
  If handle <> #INVALID_HANDLE_VALUE
    
    Repeat
      
      ; Trouve = File or Directory Found
      Trouve.s=PeekS(@lpFindFileData\cFileName)
      
      ; This is a not a directory
      If lpFindFileData\dwFileAttributes & #FILE_ATTRIBUTE_DIRECTORY =#False
        
        Fichiers.s=Path+Trouve
        
        Size+( lpFindFileData\nFileSizeLow / 1024) ; Add Low DWord
        If lpFindFileData\nFileSizeHigh
          Size+lpFindFileData\nFileSizeHigh * $3FFFFF ; Add High DWord *$3FFFFF
        EndIf
        
      EndIf
      
      ; Exit when there is no more files
    Until FindNextFile_(handle, @lpFindFileData)= #False
    
    ; Close the Api search Function
    FindClose_(handle)
    
  EndIf
  
  ProcedureReturn Size
  
EndProcedure
  
Procedure SearchSubDirectorySize(Path.s)
  
  ; Add \ to Path if missing
  If Right(Path,1)<>"\" : Path+"\":EndIf
  
  ; Apply Structure
  lpFindFileData.WIN32_FIND_DATA
  
  ; Add Filter *.*
  Recherche.s=Path+"*.*"
  
  ; Initiate the Search
  handle.i = FindFirstFile_(Recherche, @lpFindFileData)
  
  ; If search succeeds
  If handle <> #INVALID_HANDLE_VALUE
    
    Repeat
      
      ; trouve = File Or Directory Found
      Trouve.s=PeekS(@lpFindFileData\cFileName)
      
      ; This is a directory
      If lpFindFileData\dwFileAttributes & #FILE_ATTRIBUTE_DIRECTORY
        
        ; And not the . or .. directory
        If Trouve <>"." And Trouve <>".."
          
          ; Call the function itself ( Recursive ) to search in another Directory
          Size+SearchSubDirectorySize(Path+Trouve)
          
          ; Directory found : Search file within this Directory
          Size+ SearchDirectorySize(Path+Trouve)
          
        EndIf
        
      EndIf
      
      ; Exit when there is no more files
    Until FindNextFile_(handle, @lpFindFileData)= #False
    
    ; Close the Api search Function
    FindClose_(handle)
    
  EndIf
  
  ProcedureReturn Size
  
EndProcedure

ProcedureDLL GetDirectorySize(Path.s) 
  
  Size=SearchDirectorySize(Path) ; Car le répertoire lui même n'est pas scanné sinon
  Size+SearchSubDirectorySize(Path)
  
  ProcedureReturn Size
  
EndProcedure

;/ Test
; #Directory="C:\Windows\"
; MessageRequester(#Directory,Str(GetDirectorySize(#Directory))+" KB")


;} GetDirectorySize (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetFileCRC32                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetFileCRC32 (Start)                                          
;/ Author : Armoured
; Return as Hex Value the CRC32 of a File
; This function load File in Memory so, use it with little files

ProcedureDLL.s GetFileCRC32(file$) 
  Protected crc32$,length.l,*MemoryBuffer
  If (ReadFile(0,file$)) 
    length = Lof(0) 
    If (length) 
      *MemoryBuffer = AllocateMemory(length) 
      If (*MemoryBuffer) 
        If (ReadData(0, *MemoryBuffer,length)) 
          crc32$ = Hex(CRC32Fingerprint(*MemoryBuffer,length)) 
        EndIf 
        FreeMemory(*MemoryBuffer) 
      EndIf 
    Else 
      crc32$ = "0" 
    EndIf 
    CloseFile(0) 
  EndIf 
  ProcedureReturn crc32$ 
EndProcedure 

;/ Test
; File.s= OpenFileRequester("Select a file", "","All files (*.*)|*.*", 0) 
; MessageRequester(File,"CRC32: "+GetFileCRC32(File) )

;} GetFileCRC32 (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                GetFileType                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetFileType (Start)                                           


ProcedureDLL.s GetFileType(File.s)
  If FileSize(File)<>-1
    SHGetFileInfo_(@File, 0, @info.SHFILEINFO, SizeOf(SHFILEINFO), #SHGFI_TYPENAME)
    retour.s=PeekS(@info\szTypeName[0], 80) 
  EndIf 
  ProcedureReturn retour
EndProcedure


;/ Test
; File.s="C:\Windows\Regedit.exe"
; MessageRequester(GetFilePart(File),GetFileType(File))

;} GetFileType (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              GetFileVersion                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetFileVersion (Start)                                        
;/ Author : Sverson 
;/ Get exe/dll file information [gfvi] 

; FieldName = #True : Add Field Name / #False : Without Field Name

; Wich = 
; #GFVI_FileVersion / #GFVI_FileDescription / #GFVI_LegalCopyright / #GFVI_InternalName / #GFVI_OriginalFilename 
; #GFVI_ProductName / #GFVI_ProductVersion / #GFVI_CompanyName / #GFVI_LegalTrademarks / #GFVI_SpecialBuild
; #GFVI_PrivateBuild / #GFVI_Comments / #GFVI_Language
; Or #GFVI_All if you want to retrieve all these fields


Enumeration 
  #GFVI_FileVersion      = $0001 
  #GFVI_FileDescription  = $0002 
  #GFVI_LegalCopyright   = $0004 
  #GFVI_InternalName     = $0008 
  #GFVI_OriginalFilename = $0010 
  #GFVI_ProductName      = $0020 
  #GFVI_ProductVersion   = $0040 
  #GFVI_CompanyName      = $0080 
  #GFVI_LegalTrademarks  = $0100 
  #GFVI_SpecialBuild     = $0200 
  #GFVI_PrivateBuild     = $0400 
  #GFVI_Comments         = $0800 
  #GFVI_Language         = $1000 
  #GFVI_All              = $1FFF 
EndEnumeration 

Procedure.s GetElementNameInternal(elementKey.l)
  If     elementKey = #GFVI_FileVersion      : ProcedureReturn "FileVersion" 
  ElseIf elementKey = #GFVI_FileDescription  : ProcedureReturn "FileDescription" 
  ElseIf elementKey = #GFVI_LegalCopyright   : ProcedureReturn "LegalCopyright" 
  ElseIf elementKey = #GFVI_InternalName     : ProcedureReturn "InternalName" 
  ElseIf elementKey = #GFVI_OriginalFilename : ProcedureReturn "OriginalFilename" 
  ElseIf elementKey = #GFVI_ProductName      : ProcedureReturn "ProductName" 
  ElseIf elementKey = #GFVI_ProductVersion   : ProcedureReturn "ProductVersion" 
  ElseIf elementKey = #GFVI_CompanyName      : ProcedureReturn "CompanyName" 
  ElseIf elementKey = #GFVI_LegalTrademarks  : ProcedureReturn "LegalTrademarks" 
  ElseIf elementKey = #GFVI_SpecialBuild     : ProcedureReturn "SpecialBuild" 
  ElseIf elementKey = #GFVI_PrivateBuild     : ProcedureReturn "PrivateBuild" 
  ElseIf elementKey = #GFVI_Comments         : ProcedureReturn "Comments" 
  ElseIf elementKey = #GFVI_Language         : ProcedureReturn "Language" 
  EndIf 
EndProcedure 

CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
  #frontdec = ""
CompilerElse
  #frontdec = "_"
CompilerEndIf



;/ Test
; File.s  = "c:\windows\regedit.exe"
; MessageRequester(GetFilePart(File)+" (with FieldName)",GetFileVersion(File,#GFVI_CompanyName,#True))
; MessageRequester(GetFilePart(File)+" (without FieldName)",GetFileVersion(File,#GFVI_CompanyName,#False))
; MessageRequester(GetFilePart(File)+" (without FieldName)",GetFileVersion(File,#GFVI_FileVersion | #GFVI_FileDescription,#False))
; MessageRequester(GetFilePart(File)+" (with FieldName)",GetFileVersion(File,#GFVI_All,#True))


;} GetFileVersion (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetLastError                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetLastError (Start)                                          
;/ Author : ?

; GetLastError() Use to get Last Win32 API Error
; If result <> 0 --> An error occur
; You can retrieve the error as String with GetLastErrorAsText

ProcedureDLL GetLastError() 
  ; Error 1309 or 0 = No error 
  
  LastError=GetLastError_()
  If LastError=1309 : LastError=0 : EndIf
  ProcedureReturn LastError
EndProcedure

ProcedureDLL.s GetLastErrorAsText(LastError.l)
  
  If LastError 
    *ErrorBuffer = AllocateMemory(1024) 
    FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, 0, LastError, 0, *ErrorBuffer, 1024, 0) 
    message.s=PeekS(*ErrorBuffer) 
    FreeMemory(*ErrorBuffer) 
  EndIf 
  
  ProcedureReturn message
EndProcedure

;/ Test
; DeleteFile("C:\DoesNotExist.txt")
; LastError=GetLastError()
; MessageRequester("GetLastError = "+Str(LastError),GetLastErrorAsText(LastError))


;} GetLastError (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            GetPureBasicVersion                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetPureBasicVersion (Start)                                   

;/ Author : Gillou

ProcedureDLL.s GetPureBasicVersion() 
  
  Temp.s=RegGetValue_int("HKEY_CLASSES_ROOT\Applications\PureBasic.exe\shell\open\command","",".")
  Temp=GetPathPart(RTrim(RemoveString(RemoveString(Temp, Chr(34), 1), "%1", 1))) 
  
  File = ReadFile(#PB_Any,Temp + "\compilers\PBcompiler.exe") 
  If File 
    Repeat 
      ligne$ = ReadString(file) 
      pos = FindString(ligne$, "PureBasic v", 0) 
      If pos <> 0 
        po = pos 
        CIPureBasic$ = ligne$ 
      EndIf 
    Until Eof(File) Or pos <> 0 
    CloseFile(File) 
    CIPureBasic$ = StringField(Right(CIPureBasic$, Len(CIPureBasic$) - (po + 10)), 1, "*") 
  EndIf 
  ProcedureReturn CIPureBasic$ 
EndProcedure 

;/ Test
; MessageRequester("PureBasic version",GetPureBasicVersion())


;} GetPureBasicVersion (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                           Handle&Pid toFileName                           |
;  |                           _____________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Handle&Pid toFileName (Start)                                 
;/ Author : dlolo
; Return the file Path and Name by specifying Windows Handle or Process Pid
;1.31.15: made wrapper function to not cause IMA
;             commented out End commands - userlib should not end a program.
;             unicode fix for HandleToFileName

#PROCESS_ALL_ACCESS=$01F0FFF 
#MAX_PATH=$0104 

ProcedureDLL.s HandleToFileName(hWnd.i) 
  PID.i=0 
  GetWindowThreadProcessId_( hWnd, @PID ) 
  hProcess.i = OpenProcess_( #PROCESS_ALL_ACCESS, 0, PID ); 
  Name.s=Space(256) 
  
  psapi = OpenLibrary(#PB_Any,"PSAPI.DLL") 
  If psapi
    CompilerIf #PB_Compiler_Unicode
      *F=GetFunction(psapi,"GetModuleFileNameExW")
    CompilerElse
      *F=GetFunction(psapi,"GetModuleFileNameExA")
    CompilerEndIf 
    If *F 
      CallFunctionFast(*F,hProcess,0,@Name,#MAX_PATH ) 
    Else 
      Debug "Fonction non trouvé" 
      CloseLibrary(psapi) 
      ;End 
    EndIf 
  Else 
    Debug "Library non ouverte" 
    ;End 
  EndIf 
  ProcedureReturn Name 
EndProcedure 

Procedure.s PidToFileName_Internal(PID.i) 
  PID.i=0 
  ;GetWindowThreadProcessId_( hWnd, @PID ) 
  hProcess.i = OpenProcess_( #PROCESS_ALL_ACCESS, 0, PID ); 
  Name.s=Space(256) 
  
  psapi = OpenLibrary(#PB_Any,"PSAPI.DLL") 
  If psapi
    CompilerIf #PB_Compiler_Unicode
      *F=GetFunction(psapi,"GetModuleFileNameExW")
    CompilerElse
      *F=GetFunction(psapi,"GetModuleFileNameExA")
    CompilerEndIf 
    If *F 
      CallFunctionFast(*F,hProcess,0,@Name,#MAX_PATH ) 
    Else 
      Debug "Fonction non trouvé" 
      CloseLibrary(psapi) 
      ;End 
    EndIf 
  Else 
    Debug "Library non ouverte" 
    ;End 
  EndIf 
  ProcedureReturn Name 
EndProcedure 

ProcedureDLL.s PidToFileName(PID.i) 
  ProcedureReturn PidToFileName_Internal(PID)
EndProcedure
;/ Test
; 
; Repeat
  ; Temp.s=WindowsEnum()
  ; If Temp="":Break:EndIf
  ; message.s+Temp+" --> "+HandleToFileName(GetHandle(Temp))+#CRLF$+#CRLF$
; ForEver
; MessageRequester("Windows Handle to Filename",message)
; 
; MessageRequester("PID Process to Filename","Explorer.exe"+" --> "+PidToFileName(GetPidProcess("Explorer.exe")))





;} Handle&Pid toFileName (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                IconExtract                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ IconExtract (Start)                                           
; Idea from Rikuk
; File specifies the File where Icon is extracted
; Icon = 0 To ? --> Return handle of Image
; Icon = -1 --> Return the count of Icon

ProcedureDLL IconExtract(File.s,Icon.i)
  ProcedureReturn ExtractIcon_(0,File,Icon) 
EndProcedure

;/ Test
; #file="C:\WINDOWS\explorer.exe"
; Count=IconExtract(#file,-1)
; OpenWindow(0,0,0,130,70,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,Str(Count)+" Icons") 
; CreateGadgetList(WindowID(0)) 
; ButtonImageGadget(0,10,10,48,48,IconExtract(#file,pointer)) 
; TextGadget(1,80,30,40,20,"n° 1")
; 
; 
; Repeat
  ; event=WaitWindowEvent()
  ; 
  ; If event= #PB_Event_Gadget And EventGadgetID()=0 And EventType()=#PB_EventType_LeftClick
    ; pointer+1
    ; If pointer=Count : pointer=0 : EndIf
    ; SetGadgetState(0,IconExtract(#file,pointer))
    ; SetGadgetText(1,"n° "+Str(pointer+1))
  ; EndIf
; Until event=#PB_Event_CloseWindow
   

  




;} IconExtract (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               IconExtractEx                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ IconExtractEx (Start)                                         
;/ Idea from Flype 
; Return ImageId of an Icon embedded in a file (Exe Or Dll )
; 0 Get Small Icon / 1 Get Big Icon
; If Selected = #True : Icon is Selected 

ProcedureDLL IconExtractEx(File.s,size.l,Selected.l)
  
  If Selected
    Type=#SHGFI_SELECTED
  EndIf
  
  If size
    SHGetFileInfo_(File, 0, @InfosFile.SHFILEINFO, SizeOf(SHFILEINFO), Type | #SHGFI_ICON | #SHGFI_LARGEICON)
    ProcedureReturn InfosFile\hIcon
  Else
    SHGetFileInfo_(File, 0, @InfosFile.SHFILEINFO, SizeOf(SHFILEINFO), Type | #SHGFI_ICON |#SHGFI_SMALLICON)
    ProcedureReturn InfosFile\hIcon
  EndIf
  
EndProcedure

;/ Test
; 
; #file="C:\Windows\Regedit.exe"
; #File2="C:\Windows\Notepad.exe"
; 
; OpenWindow(0,0,0,210,70,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"IconExtractEx")
; CreateGadgetList(WindowID()) 
; ButtonImageGadget(0,10,10,40,40,IconExtractEx(#file,0,0)) 
; ButtonImageGadget(1,60,10,40,40,IconExtractEx(#file,0,1)) 
; ButtonImageGadget(2,110,10,40,40,IconExtractEx(#File2,1,0)) 
; ButtonImageGadget(3,160,10,40,40,IconExtractEx(#File2,1,1)) 
; 
; WaitUntilWindowIsClosed()  


;} IconExtractEx (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                        LocaleDate with Sublanguage                        |
;  |                        ___________________________                        |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ LocaleDate with Sublanguage (Start)                           
;/ Author Flype
; 07/10/05
; LocaleDate(Mask.s,Date.l,lang.l,[sublang.l]) 
; Return Date as String with a Mask like :

;/ Mask Format
; d	    Day of month as digits with no leading zero For single-digit days.
; dd	  Day of month as digits with leading zero For single-digit days.
; ddd	  Day of week as a three-letter abbreviation. The function uses The LOCALE_SABBREVDAYNAME value associated with The specified locale.
; dddd	Day of week as its full name. The function uses The LOCALE_SDAYNAME value associated with The specified locale.
; M	    month as digits with no leading zero For single-digit months.
; MM	  month as digits with leading zero For single-digit months.
; MMM	  month as a three-letter abbreviation. The function uses The LOCALE_SABBREVMONTHNAME value associated with The specified locale.
; MMMM	month as its full name. The function uses The LOCALE_SMONTHNAME value associated with The specified locale.
; y	    Year as last two digits, but with no leading zero For years less than 10.
; yy	  Year as last two digits, but with leading zero For years less than 10.
; yyyy	Year represented by full four digits.

;/ Lang ( 0 specify locale )
; #LANG_GERMAN / #LANG_ENGLISH / #LANG_FRENCH  /#LANG_ITALIAN / #LANG_PORTUGUESE / #LANG_SPANISH / #LANG_TURKISH 


Procedure.l LocaleDate_LCID(lang.b,sublang.b) 
  
  ; Retourne une valeur LCID utilisable avec GetDateFormat() par ex. 
  
  ;Protected lang.b, sublang.b, lRes.l  - not sure the purpose of this line, causes errors
  
  lRes = (#SORT_DEFAULT<<16) | ( (sublang<<10) | lang ) 
  
  ProcedureReturn lRes 
  
EndProcedure 

ProcedureDLL.s LocaleDate(Mask.s,Date.l,lang.l) 
  
;   Protected Date.l, lang.l, lcid.l, 
  sRes.s
  st.SYSTEMTIME 
  
  st\wYear   = Year(Date) 
  st\wMonth  = Month(Date) 
  st\wDay    = Day(Date) 
  st\wHour   = Hour(Date) 
  st\wMinute = Minute(Date) 
  st\wSecond = Second(Date) 
  
  sRes = Space(255) 
  GetDateFormat_(lang,0,st,Mask,sRes,255) 
  
  ProcedureReturn sRes 
  
EndProcedure 

ProcedureDLL.s LocaleDate2(Mask.s,Date.l,lang.l,sublang.l) 
  
;   Protected Mask.s, Date.l, lang.l, sublang.l, 
  sRes.s 
  a.SYSTEMTIME 
  
  a\wYear  = Year(Date) 
  a\wMonth = Month(Date) 
  a\wDay   = Day(Date) 
  
  sRes = Space(255) 
  GetDateFormat_(LocaleDate_LCID(lang,sublang),0,a,Mask,sRes,255) 
  
  ProcedureReturn sRes 
  
EndProcedure


;/ Test
; Temp.s="Italian : "+LocaleDate("dddd d MMMM yyyy gg",Date(),#LANG_ITALIAN)+#CRLF$
; Temp.s+"Spanish : "+LocaleDate("dddd d MMMM yyyy gg",Date(),#LANG_SPANISH)+#CRLF$
; Temp.s+"Local : "+LocaleDate("dddd d MMMM yyyy gg",Date(),0)+#CRLF$+#CRLF$
; 
; Temp.s+"Uzbek (Latin) : "+LocaleDate("dddd d MMMM yyyy gg",Date(),$43,1)+#CRLF$
; Temp.s+"Uzbek (Cyrillic) : "+LocaleDate("dddd d MMMM yyyy gg",Date(),$43,2)
; 
; MessageRequester("Locale Date",Temp)

;} LocaleDate with Sublanguage (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              LockWorkStation                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ LockWorkStation (Start)                                       

;/ Author : PB
; Return 1 if success / 0 if fail

ProcedureDLL LockWorkStation()
  retour=LockWorkStation_()
  If retour<>0 : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure

;/ Test
; LockWorkStation()

;} LockWorkStation (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                MessageBeep                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MessageBeep (Start)                                           
;/ Just a Windows Sound 
; Sound = #MB_ICONASTERISK / #MB_ICONEXCLAMATION / #MB_ICONHAND / #MB_OK
; #MB_ICONQUESTION don't work !?

ProcedureDLL MessageBeep(Sound)
  MessageBeep_(Sound)
EndProcedure

;/ Test
; MessageBeep(#MB_ICONASTERISK)
; Delay(1000)
; MessageBeep(#MB_ICONEXCLAMATION	)
; Delay(1000)
; MessageBeep(#MB_ICONHAND)
; Delay(1000)
; MessageBeep(#MB_OK)


;} MessageBeep (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 MountVol                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ MountVol (Start)                                              
;/ Droopy 25/10/05 
; PureBasic 3.94 

; UnMountVolume : Return 1 if success / 0 if fail 
; MountVol : Return 1 if success / 0 if fail 
; if Fail : 0 Cannot Mount Destination / 2 Cannot Unmount Source / 3 Destination already Mounted / 4 Source not mounted 
; MountListInit / MountList renvoie la liste des VolumeName ( \\?\{xxxx )
; GetVolumeName ( Spécifier \?\\{xxx ) --> Renvoie D: + Fonctionne si conflit Mappage Réseau !

;  Deleted because return "" if a Network Map cover up a VolumeName
; MountVolName : Return VolumeName as String or "" if volume is not mounted 
; MountVolChange : Change Drive letter : Return if success : 1 

; ProcedureDLL.s MountVolName(Drive.s) ;  Return "" if a Network Map cover up a VolumeName
  ; If Right(Drive,1)<>"\" : Drive+"\":EndIf 
  ; VolumeName.s=Space(255) 
  ; VolumeMountPoint.s=Drive 
  ; OpenLibrary(0,"Kernel32.dll") 
  ; Retour=CallFunction(0,"GetVolumeNameForVolumeMountPointA",@VolumeMountPoint,@VolumeName,255) 
  ; CloseLibrary(0) 
  ; If Retour 
    ; ProcedureReturn VolumeName 
  ; EndIf 
; EndProcedure 

; ProcedureDLL MountVolChange(Source.s,Destination.s) ;  Peut Merdouiller car utilise MountVolName !
  ; If Right(Source,1)<>"\" : Source+"\":EndIf 
  ; If Right(Destination,1)<>"\" : Destination+"\":EndIf 
  ; 
  ; VolId.s=MountVolName(Source) 
  ; If VolId<>"" ;/ Source existe 
    ; If MountVolName(Destination)="" ;/ Destination non montée 
      ; If UnMountVolume(Source) ;/ Le suppression s'est bien passé 
        ; Retour=MountVol(Destination,VolId) ;/ Le montage s'est bien passé 
      ; Else 
        ; Retour=2 ;/ Suppression mal passée 
      ; EndIf 
    ; Else ;/ Destination déjà montée 
      ; Retour=3 
    ; EndIf 
  ; Else ;/ Pas de montage dans le lecteur Source 
    ; Retour=4 
  ; EndIf 
  ; 
  ; ProcedureReturn Retour 
; EndProcedure 

ProcedureDLL UnMountVolume(Drive.s) 
  If Right(Drive,1)<>"\" : Drive+"\":EndIf 
  VolumeMountPoint.s=Drive 
  kernel32 = OpenLibrary(#PB_Any,"Kernel32.dll") 
  CompilerIf #PB_Compiler_Unicode = 0
    func.s = "DeleteVolumeMountPointA"
  CompilerElse
    func.s = "DeleteVolumeMountPointW"
  CompilerEndIf
  retour=CallFunctionFast(GetFunction(kernel32,func),@VolumeMountPoint) 
  CloseLibrary(kernel32) 
  If retour<>0 : retour=1 : EndIf 
  ProcedureReturn retour 
EndProcedure 

ProcedureDLL MountVol(Drive.s,MountPoint.s) 
  If Right(Drive,1)<>"\" : Drive+"\":EndIf 
  VolumeMountPoint.s=Drive 
  kernel32 = OpenLibrary(#PB_Any,"Kernel32.dll") 
  CompilerIf #PB_Compiler_Unicode = 0
    func.s = "SetVolumeMountPointA"
  CompilerElse
    func.s = "SetVolumeMountPointW"
  CompilerEndIf
  Retour=CallFunctionFast(GetFunction(kernel32,func),@VolumeMountPoint,@MountPoint) 
  CloseLibrary(kernel32) 
  If Retour<>0 : Retour=1 : EndIf 
  ProcedureReturn Retour 
EndProcedure 

ProcedureDLL MountListInit()
  Static Flag
  
  If Flag=0
    Global NewList LLMPoint.s()
    Flag=1
  Else
    ClearList(LLMPoint())
  EndIf
  
  VolumeName.s=Space(255)
  kernel32 = OpenLibrary(#PB_Any,"Kernel32.dll")
  CompilerIf #PB_Compiler_Unicode = 0
    func.s = "FindFirstVolumeA"
  CompilerElse
    func.s = "FindFirstVolumeW"
  CompilerEndIf
  Handle=CallFunctionFast(GetFunction(kernel32,func),@VolumeName,255)
  
  If Handle<>-1 ;/ Trouvé
    AddElement(LLMPoint())
    LLMPoint()=VolumeName
    
    Repeat
      VolumeName=Space(255)
      CompilerIf #PB_Compiler_Unicode = 0
        func.s = "FindNextVolumeA"
      CompilerElse
        func.s = "FindNextVolumeW"
      CompilerEndIf
      Retour=CallFunctionFast(GetFunction(kernel32,func),Handle,@VolumeName,255)
      If Retour =0 : Break : EndIf ;/ Erreur ou Plus de volumes à lister
      AddElement(LLMPoint())
      LLMPoint()=VolumeName
      
    ForEver
    
    CompilerIf #PB_Compiler_Unicode = 0
      func.s = "FindVolumeCloseA"
    CompilerElse
      func.s = "FindVolumeCloseW"
    CompilerEndIf
    CallFunctionFast(GetFunction(kernel32,func)) ;/ Fermeture Propre
    CloseLibrary(kernel32)
  EndIf
  
  ResetList(LLMPoint())
  ProcedureReturn ListSize(LLMPoint())
  
EndProcedure

ProcedureDLL.s MountList()
  
  If NextElement(LLMPoint())
    ProcedureReturn LLMPoint()
  Else
    ResetList(LLMPoint())
  EndIf
EndProcedure

ProcedureDLL.s GetMountVolName(MountPoint.s) ;/ Works with VolumeName cover up with Network Map
  VolName.s=Space(1000)
  kernel32 = OpenLibrary(#PB_Any,"Kernel32.dll")
  CompilerIf #PB_Compiler_Unicode = 0
    func.s = "GetVolumePathNamesForVolumeNameA"
  CompilerElse
    func.s = "GetVolumePathNamesForVolumeNameW"
  CompilerEndIf
  Handle=CallFunctionFast(GetFunction(kernel32,func),@MountPoint,@VolName,1000,val2)
  CloseLibrary(kernel32)
  ProcedureReturn VolName
EndProcedure

;  Deleted because use MountVolName
; ;/ Test1 : List All Mounted Volumes 
; For n=65 To 90 
  ; Lecteur.s=Chr(n)+":\" 
  ; Temp.s=MountVolName(Lecteur) 
  ; If Temp<>"" 
    ; Message.s+Lecteur+"         "+Temp+#CRLF$ 
  ; EndIf 
; Next 
; MessageRequester("Volume Information",Message,#MB_ICONINFORMATION) 

;  Deleted because use MountVolName
; ;/ Test2 : Change Drive letter of my USB Key 
; If MessageRequester("Change Drive Letter ?","Do you want to change drive letter ?",#PB_MessageRequester_YesNo)=6 
  ; Select MountVolChange("Z:","U:") 
    ; Case 0 
      ; MessageRequester("Changing Drive Letter","Cannot Mount Destination",#MB_ICONERROR ) 
    ; Case 1 
      ; MessageRequester("Changing Drive Letter","Success",#MB_ICONINFORMATION ) 
    ; Case 2 
      ; MessageRequester("Changing Drive Letter","Cannot Unmount Source",#MB_ICONERROR ) 
    ; Case 3 
      ; MessageRequester("Changing Drive Letter","Destination already Mounted",#MB_ICONERROR ) 
    ; Case 4 
      ; MessageRequester("Changing Drive Letter","Source not mounted",#MB_ICONERROR ) 
  ; EndSelect 
; EndIf


;/ Test3 
; message.s=Str(MountListInit())+ " MountPoint Found"+#CRLF$+#CRLF$
; Repeat
  ; MountPoint.s=MountList()
  ; If MountPoint="": Break:EndIf
  ; message+ GetMountVolName(MountPoint)+" --> "+MountPoint+#CRLF$
; ForEver
  ; 
; MessageRequester("MountPoint Info",message)

;} MountVol (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 NewTimer                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ NewTimer (Start)                                              
;  This functions replace Timer() TimerKill() --> Deleted in Droopy Lib 1.28

;/ Author: BackupUser tweaked by Droopy/Kale 

ProcedureDLL Timer(TimerId,Delay,ProcedureAdress, windowid)
  SetTimer_(WindowID,TimerId,Delay,ProcedureAdress)
EndProcedure

ProcedureDLL TimerKill(TimerId, windowid)
  KillTimer_(WindowID,TimerId)
EndProcedure

;/ Test

; Procedure Timer1() ; First ProgressBarGadget
  ; SetGadgetState(0,GetGadgetState(0)+1) 
  ; beep_(400,10) 
; EndProcedure 
; 
; Procedure Timer2(); Second ProgressBarGadget 
  ; SetGadgetState(1,GetGadgetState(1)+1) 
  ; beep_(1000,10) 
; EndProcedure 
; 
; Procedure Timer3() 
  ; SetGadgetText(2,"Timer 3 Kill Timer 1 and 2") 
  ; TimerKill(1) ;/ Kill Timer #1 
  ; TimerKill(2) ;/ Kill Timer #2 
  ; beep_(1500,500) 
  ; TimerKill(3)
; EndProcedure 
; 
; OpenWindow(0,0,0,230,120,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"Timers with API") 
; CreateGadgetList(WindowID()) 
; ProgressBarGadget(0,10,10,210,30,0,65,#PB_ProgressBar_Smooth) 
; ProgressBarGadget(1,10,45,210,30,0,9,#PB_ProgressBar_Smooth) 
; SetGadgetState(0,0)
; SetGadgetState(1,0)
; TextGadget(2,10,80,210,30,"Timer 1/2/3 Started",#PB_Text_Center) 
; 
; ;/ Starting Timers 
; Timer(1, 150, @Timer1())   ; Timer #1 each 150 ms 
; Timer(2, 1000, @Timer2())  ; Timer #2 each second 
; Timer(3, 10000, @Timer3()) ; Timer #3 each 10 seconds 
  ; 
; Repeat 
; Until WaitWindowEvent()=#PB_EventCloseWindow 



;} NewTimer (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 Odd Even                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Odd Even (Start)                                              
;/ Odd (Pair) / Even (Impair)

ProcedureDLL Odd(Number.l)
  If Number & 1=1
    ProcedureReturn 1
  EndIf
EndProcedure

ProcedureDLL Even(Number.l)
  If Number & 1=0
    ProcedureReturn 1
  EndIf
EndProcedure


;/ Test
; x=2
; Debug Odd(x)
; Debug Even(x)
 

;} Odd Even (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 PokePeek                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ PokePeek (Start)                                              
;/ Author : DoubleDutch

;/ Set bit n° 'bitno' with 'bit' 
ProcedureDLL PokeBit(base,bitno,bit) 
  modulo=bitno%8 
  base+(bitno-modulo)>>3 
  If bit 
    PokeB(base,PeekB(base)|(1<<modulo)) 
  Else 
    PokeB(base,PeekB(base)&(~(1<<modulo))) 
  EndIf 
EndProcedure 

;/ Return bit n° 'bit' of the value stored @base
ProcedureDLL PeekBit(base,bitno) 
  modulo=bitno%8 
  ProcedureReturn (PeekB(base+(bitno-modulo)>>3)>>modulo)&1 
EndProcedure 

;/ Fill bits @base, starting @bitno, width specify the nb of byte, value specify the value ( ex : %1111)
ProcedureDLL PokeBits(base,bitno,width,Value) 
  For loop=0 To width-1 
    PokeBit(base,bitno,value&1) 
    bitno+1 
    value>>1 
  Next 
EndProcedure 

;/ Return bits, @base, width define the number of bits to return, bitno specify which bit is the first 
ProcedureDLL PeekBits(base,bitno,width) 
  result=0 
  For loop=0 To width-1 
    result|(PeekBit(base,bitno)<<loop) 
    bitno+1 
  Next 
  ProcedureReturn result 
EndProcedure 

;/ Test
; Value=%00000000000000000000000000000000
; PokeBit(@Value,31,1)
; Debug Bin(Value)
; Debug PeekBit(@Value,31)
; PokeBits(@Value,0,5,%11111)
; Debug Bin(Value)
; Debug Bin(PeekBits(@Value,0,3))



;} PokePeek (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              RecentDocuments                              |
;  |                              _______________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RecentDocuments (Start)                                       
;/ ??

ProcedureDLL AddRecentDocuments(File.s)
  SHAddToRecentDocs_(2,File) 
EndProcedure

ProcedureDLL ClearRecentDocuments()
  SHAddToRecentDocs_(2,0) 
EndProcedure

;/ Test
; ClearRecentDocuments()
; AddRecentDocuments("c:\Added2RecentDocumentsByPureBasic.txt")

;} RecentDocuments (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                RenameDrive                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RenameDrive (Start)                                           
;/ Author : MrVainSCL! aka Thorsten
; Return 1 if success / 0 if fail

ProcedureDLL RenameDrive(drive$,name$)
  result = SetVolumeLabel_(drive$, name$)
  ProcedureReturn result
EndProcedure


;/ Test
; If RenameDrive("c:\","Windows")
  ; MessageRequester("Result of renaming drive:","Drive succesfully renamed.",0)
; Else
  ; MessageRequester("Result of renaming drive:","Could'nt rename Drive",0)
; EndIf


;} RenameDrive (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 Resource                                  |
;  |                                 ________                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Resource (Start)                                              
;/ Droopy 
; PureBasic 3.94 25/11/05

; Create a File with RC Extension And include it as RC_DATA Resource Type 
; Path can be absolute Or relative
; Exemple :
            ; REG RCData "C:\WINDOWS\REGEDIT.EXE"
            ; SON RCData "son.wav"
            ; Image RCData "image.bmp"

;/ SaveResourceAs(Name.s,File.s) Save the resource as a file
;/ GetResourcePointer(Name.s) is usefull with PureBasic CatchXXX functions (CatchImage / CatchSound ... )

ProcedureDLL SaveResourceAs(Name.s,File.s)
  
  ; (Use GetModuleHandle_ if you want to specify another file)
  
  HandleResource= FindResource_(0,@Name,#RT_RCDATA)
  If HandleResource
    HandleGlobalMemoryBlock=LoadResource_(0,HandleResource) 
    PointerFirstByteOfTheResource=LockResource_(HandleGlobalMemoryBlock)
    
    ; Get size of the resource
    Size= SizeofResource_(Handle,HandleResource)
    
    ; Save the file
    FileId=OpenFile(#PB_Any,File)
    If FileId
      WriteData(fileid, HandleGlobalMemoryBlock,Size)
      CloseFile(FileId)
    EndIf
    
    ; Test if the file is written
    If FileSize(File)=Size 
      ProcedureReturn 1
    EndIf
  EndIf
  
EndProcedure

ProcedureDLL GetResourcePointer(Name.s)
  
  ; (Use GetModuleHandle_ if you want to specify another file)
  
  HandleResource= FindResource_(0,@Name,#RT_RCDATA)
  If HandleResource
    HandleGlobalMemoryBlock=LoadResource_(0,HandleResource) 
    PointerFirstByteOfTheResource=LockResource_(HandleGlobalMemoryBlock)
    
    ProcedureReturn HandleGlobalMemoryBlock
  EndIf
EndProcedure

ProcedureDLL GetResourceSize(Name.s)
  
  ; (Use GetModuleHandle_ if you want to specify another file)
  
  HandleResource= FindResource_(0,@Name,#RT_RCDATA)
  If HandleResource
    HandleGlobalMemoryBlock=LoadResource_(0,HandleResource) 
    PointerFirstByteOfTheResource=LockResource_(HandleGlobalMemoryBlock)
    
    ; Return the size of the resource
    Size= SizeofResource_(Handle,HandleResource)
    ProcedureReturn Size
  EndIf
  
EndProcedure

;/ Test
; CatchImage(0,GetResourcePointer("IMAGE"))
; OpenWindow(0,0,0,240,240,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"ImageGadget")
; CreateGadgetList(WindowID(0))
; ImageGadget(0,20,20,200,200,UseImage(0),#PB_Image_Border)  
; SaveResourceAs("REG","d:\Out.exe")
; InitSound()
; CatchSound(0,GetResourcePointer("SON"))
; PlaySound(0)
; Delay(2000)


;} Resource (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              SelfEncryption                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SelfEncryption (Start)                                        
;/ Author : Dare2
; en = #True  --> Encrypt 
; en = #False --> Decrypt

ProcedureDLL.s SelfEncryption(Text.s,en.l) 
  k1=Len(Text) 
  If k1>0 
    *p=@Text 
    k2=PeekB(*p) & $FF 
    r=k1 ! k2 
    If r<>0 : PokeB(*p,r) : EndIf 
    For i=2 To Len(Text) 
      *p+1 
      If en : k1=PeekB(*p-1) & $FF : Else : k1=k2 : EndIf 
      k2=PeekB(*p) 
      r=k1 ! k2 
      If r<>0 : PokeB(*p,r) : EndIf 
    Next 
  EndIf 
  ProcedureReturn Text 
EndProcedure 

;/ Test
; x.s="Wooo! Hooo! This is self encrypting" 
; y.s=SelfEncryption(x,#True) 
; z.s=SelfEncryption(y,#False) 
; MessageRequester("SelfEncryption",x+#CRLF$+y+#CRLF$+z)


;} SelfEncryption (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                          SetEnvironmentVariable                           |
;  |                          ______________________                           |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SetEnvironmentVariable (Start)                                

; ProcedureDLL SetEnvironmentVariable(Name.s,Value.s)
;   retour =SetEnvironmentVariable_(Name,Value)
;   If retour<>0 : retour=1 :EndIf
;   ProcedureReturn retour
; EndProcedure

;/ Test
; SetEnvironmentVariable("toto","aaa")
; RunProgram("cmd.exe","/k set toto","")

;} SetEnvironmentVariable (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               SetWindowIcon                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ SetWindowIcon (Start)                                         
;/ Idea from Erix14

ProcedureDLL SetWindowIcon(handle,IconHandle)
  SendMessage_(handle,#WM_SETICON,#False,IconHandle) 
EndProcedure

;/ Test
; OpenWindow(0, 0, 0, 195, 260, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, "SetWindowIcon")
; IconHandle=ExtractIcon_(0,"c:\windows\system32\shell32.dll",130)
; SetWindowIcon(WindowID(),IconHandle)
; WaitUntilWindowIsClosed()

;} SetWindowIcon (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                ShowTaskBar                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ShowTaskBar (Start)                                           
;/ Author: AWEAR

ProcedureDLL ShowTaskBar(State)
  OpenLibrary(1, "user32.dll") 
  ;Value = CallFunction(1, "FindWindowA", "Shell_TrayWnd", "") 
  Value = FindWindow_("Shell_TrayWnd", "") 
  ;CallFunction(1, "ShowWindow", Value, State)  
  ShowWindow_(Value, State)  
EndProcedure

;/ Test
; ShowTaskBar(#False)
; MessageRequester("TaskBar is hidden","Clik OK to show TaskBar")
; ShowTaskBar(#True)

;} ShowTaskBar (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                ShowWindow                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ShowWindow (Start)                                            
;/ Sets the specified window's show state
; SW_HIDE	Hides the Window And activates another Window.
; SW_MAXIMIZE	Maximizes the specified Window.
; SW_MINIMIZE	Minimizes the specified Window And activates the Next Top-level Window in the z order.
; SW_RESTORE	activates And displays the Window. If the Window is minimized Or maximized, Windows restores it To its original size And position. An application should specify this Flag when restoring a minimized Window.
; SW_SHOW	activates the Window And displays it in its current size And position. 
; SW_SHOWDEFAULT	Sets the show State based on the SW_ Flag specified in the STARTUPINFO Structure passed To the CreateProcess function by the program that started the application. 
; SW_SHOWMAXIMIZED	activates the Window And displays it as a maximized Window.
; SW_SHOWMINIMIZED	activates the Window And displays it as a minimized Window.
; SW_SHOWMINNOACTIVE	displays the Window as a minimized Window. the active Window remains active.
; SW_SHOWNA	displays the Window in its current State. the active Window remains active.
; SW_SHOWNOACTIVATE	displays a Window in its most recent size And position. the active Window remains active.
; SW_SHOWNORMAL	

ProcedureDLL ShowWindow(handle,State)
  ShowWindow_(handle,State)
EndProcedure

;/ Test
; Procedure WindowsTest()
; If OpenWindow(0,0,0,222,200,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"ButtonGadgets") And CreateGadgetList(WindowID(0))
  ; ButtonGadget(0, 10, 10, 200, 20, "Standard Button")
  ; ButtonGadget(1, 10, 40, 200, 20, "Left Button", #PB_Button_Left)
  ; ButtonGadget(2, 10, 70, 200, 20, "Right Button", #PB_Button_Right)
  ; ButtonGadget(3, 10,100, 200, 60, "Multiline Button  (longer text gets automatically wrapped)", #PB_Button_MultiLine)
  ; ButtonGadget(4, 10,170, 200, 20, "Toggle Button", #PB_Button_Toggle)
  ; Repeat : Until WaitWindowEvent()=#PB_Event_CloseWindow
; EndIf
; WaitUntilWindowIsClosed()
; EndProcedure
; 
; Procedure TestAgain(handle,State)
  ; Delay(2000) 
  ; Beep(800,250)
  ; ShowWindow(handle,State)
; EndProcedure
; 
; CreateThread(@WindowsTest(),0)
; Repeat
  ; a=GetHandle("ButtonGadgets")
; Until a<>0
; 
; TestAgain(a,#SW_MINIMIZE)
; TestAgain(a,#SW_RESTORE)
; TestAgain(a,#SW_MAXIMIZE)
; TestAgain(a,#SW_SHOWNORMAL)
; TestAgain(a,#SW_SHOWNORMAL)


;} ShowWindow (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            Uni2Ansi Ansi2Uni                              |
;  |                            __________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Uni2Ansi Ansi2Uni (Start)                                    
;/ BackupUser

ProcedureDLL Ansi2Uni(string.s) ; Converts normal (Ansi) string To Unicode 
  *out = AllocateMemory(Len(string)*2 * #SIZEOF_WORD) 
  MultiByteToWideChar_(#CP_ACP, 0, string, -1, *out, Len(string))  
  ProcedureReturn *out  
EndProcedure 

ProcedureDLL.s Uni2Ansi(Pointer) ; Converts Unicode to normal (Ansi) string 
  Buffer.s=Space(512)
  WideCharToMultiByte_(#CP_ACP,0,Pointer,-1,@Buffer,512,0,0)
  ProcedureReturn Buffer
EndProcedure

;} Uni2Ansi Ansi2Uni (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                WindowsExit                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WindowsExit (Start)                                           

;/ Author : Franco

ProcedureDLL WindowsExit(WindowID,State)
  SysMenu = GetSystemMenu_(WindowID,State)
  SysMenuItemCount = GetMenuItemCount_(SysMenu)
  RemoveMenu_(SysMenu,SysMenuItemCount -1,#MF_DISABLED|#MF_BYPOSITION)
  RemoveMenu_(SysMenu,SysMenuItemCount -2,#MF_DISABLED|#MF_BYPOSITION)
  DrawMenuBar_(WindowID)
EndProcedure


;/ Test
; #CheckBox=0
; Handle=OpenWindow(0,0,0,200,50,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"Close me ?") 
; CreateGadgetList(WindowID(0))
; CheckBoxGadget(#CheckBox,10, 10,250,20,"Checked = Close Enabled")
; SetGadgetState(#CheckBox,#True)
; 
; Repeat 
  ; Event=WaitWindowEvent()
  ; If Event= #PB_Event_Gadget And EventGadgetID()=#CheckBox
    ; WindowsExit(Handle,GetGadgetState(#CheckBox))
  ; EndIf
; Until Event=#PB_Event_CloseWindow


;} WindowsExit (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                WindowsMove                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WindowsMove (Start)                                           
;/ Author : Franco / Example by Droopy

ProcedureDLL WindowsMove(WindowID,State)
  RemoveMenu_(GetSystemMenu_(WindowID,State),1,#MF_DISABLED|#MF_BYPOSITION)
  DrawMenuBar_(WindowID)
EndProcedure


;/ Test
; #CheckBox=0
; Handle=OpenWindow(0,0,0,200,50,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,"Move me ?") 
; CreateGadgetList(WindowID(0))
; CheckBoxGadget(#CheckBox,10, 10,250,20,"Checked = Moving Enabled")
; SetGadgetState(#CheckBox,#True)
; 
; Repeat 
  ; Event=WaitWindowEvent()
  ; If Event= #PB_Event_Gadget And EventGadgetID()=#CheckBox
    ; WindowsMove(Handle,GetGadgetState(#CheckBox))
  ; EndIf
; Until Event=#PB_Event_CloseWindow

;} WindowsMove (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                   Word                                    |
;  |                                   ____                                    |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Word (Start)                                                  

;/ Author : Cederavic

ProcedureDLL.l MakeLong(HiWord.l,LoWord.l) 
  param & $FFFF + LoWord 
  param + HiWord << 16 
  ProcedureReturn param 
EndProcedure 

ProcedureDLL.w GetLoWord(Long.l) 
  ProcedureReturn Long & $FFFF 
EndProcedure 

ProcedureDLL.w GetHiWord(Long.l) 
  ProcedureReturn Long >> 16 & $0000FFFF
EndProcedure 

;/ Test
; Debug Hex(MakeLong($AAAA,$BBBB))
; Debug Hex(GetLoWord($FFFFAAAA))
; Debug Hex(GetHiWord($FFFFAAAA))

;} Word (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                XPFirewall                                 |
;  |                                __________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ XPFirewall (Start)                                            

;/ Author : Bingo

; XPFirewall #True : Enable XP Firewall / #False : Disable XP Firewall
; Return 1 if Firewall is enabled / 0 if disabled

Interface INetFwProfile Extends IDispatch 
  get_Type(a) 
  get_FirewallEnabled(a) 
  put_FirewallEnabled(a) 
  get_ExceptionsNotAllowed(a) 
  put_ExceptionsNotAllowed(a) 
  get_NotificationsDisabled(a) 
  put_NotificationsDisabled(a) 
  get_UnicastResponsesToMulticastBroadcastDisabled(a) 
  put_UnicastResponsesToMulticastBroadcastDisabled(a) 
  get_RemoteAdminSettings(a) 
  get_IcmpSettings(a) 
  get_GloballyOpenPorts(a) 
  get_Services(a) 
  get_AuthorizedApplications(a) 
EndInterface 

Interface INetFwPolicy Extends IDispatch 
  get_CurrentProfile(a) 
  GetProfileByType(a,b) 
EndInterface 

Interface INetFwMgr Extends IDispatch 
  get_LocalPolicy(a) 
  get_CurrentProfileType(a) 
  RestoreDefaults() 
  IsPortAllowed(a,b,c,d,e,f,g) 
  IsIcmpTypeAllowed(a,b,c,d,e) 
EndInterface 

ProcedureDLL XPFirewall(State.l)
  CoInitialize_(0) 
  If CoCreateInstance_(?CLSID_NetFwMgr,0,1,?IID_INetFwMgr,@object0.INetFwMgr) = 0 
    object0\get_LocalPolicy(@a.INetFwPolicy) 
    a\get_CurrentProfile(@objPolicy.INetFwProfile) 
    
    objPolicy\put_FirewallEnabled(State) 
    objPolicy\get_FirewallEnabled(@fwout.l) 
    retour=fwout 
    
  EndIf 
  CoUninitialize_() 
  If retour<>0 : retour=1 : EndIf
  ProcedureReturn retour
  
  DataSection 
  CLSID_NetFwMgr: 
  Data.l $304CE942 
  Data.w $6E39,$40D8 
  Data.b $94,$3A,$B9,$13,$C4,$0C,$9C,$D4 
  
  IID_INetFwMgr: 
  Data.l $F7898AF5 
  Data.w $CAC4,$4632 
  Data.b $A2,$EC,$DA,$06,$E5,$11,$1A,$F2 
  EndDataSection
EndProcedure


;/ Test 
; Select MessageRequester("XP FireWall","Enable it ?",#PB_MessageRequester_YesNo)
  ; Case 6
    ; XPFirewall(#True)
  ; Case 7
    ; XPFirewall(#False)
; EndSelect







;} XPFirewall (End)

;/
;/
;/
;/
;/
;/                        VERSION 1.29 FUNCTIONS ADDON ( 04/12/05 )
;/
;/
;/
;/
;/

;  _____________________________________________________________________________
;  |                                                                           |
;  |                               GetErrorLevel                               |
;  |                               _____________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetErrorLevel (Start)    
;/ Author : Flype                                     
; Return the termination status of the specified process (ErrorLevel Code)

ProcedureDLL GetErrorLevel(handle)
  GetExitCodeProcess_(handle,@ExitCode.l)
  ProcedureReturn ExitCode
EndProcedure

;/ Test
; Handle=RunProgram("END55.exe","","d:\",1)
; ErrorLevel=GetErrorLevel(Handle)
; If Handle
  ; MessageRequester("ErrorLevel",Str(ErrorLevel))
; Else
  ; MessageRequester("Program","Not Found")
; EndIf

;  ( Code of END55.EXE : End 55 )

;} GetErrorLevel (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                         WaitProgramInitialisation                         |
;  |                         _________________________                         |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ WaitProgramInitialisation (Start)                             
;/ Author : Bingo
; The WaitProgramInitialisation function waits Until The specified process is waiting For user input 
; with no input pending, Or Until The time-out interval has elapsed.
; If this process is a console application or does not have a message queue, 
; WaitProgramInitialisation returns immediately. 

ProcedureDLL WaitProgramInitialisation(handle)  
  While  WaitForInputIdle_(handle, 1) > 0 
    Delay(1) 
  Wend 
EndProcedure

;/ Test ( Launch it in Debug Mode )
; ret = RunProgram("Calc.exe") 
; If ret
  ; WaitProgramInitialisation(ret)
; EndIf
; Debug "Launched & Ready."



;} WaitProgramInitialisation (End)


;/
;/
;/
;/
;/
;/                        VERSION 1.31 FUNCTIONS ADDON ( 28/12/05 )
;/
;/
;/
;/
;/
;/ Test
; UseJPEGImageDecoder() ; Needed with a jpeg logo
; IconId=ExtractIcon_(0,"c:\windows\system32\shell32.dll",130)
; LogoId=LoadImage(0,"Logo.jpg")
; SubText.s="²This is an AboutBox created using²"
; SubText+"the Droopy Lib 1.31."
; SubText+"²²Visit PureBasic Homepage (www.PureBasic.com)"
; SubText+"²²Droopy : December 2005"
; AboutBox(IconId,0,"AboutBox","Example of AboutBox",SubText)



;} AboutBox (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  Between                                  |
;  |                                  _______                                  |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Between (Start)                                               
;/ Author : Dr. Dri

ProcedureDLL.s Between(string.s, LString.s, RString.s) 
  Protected Between.s, LIndex.l, RIndex.l 
  
  LIndex = FindString(string, LString, 0) 
  RIndex = FindString(string, RString, Lindex+1) 
  
  If LIndex And RIndex 
    LIndex  + Len(LString) 
    Between = Mid(string, LIndex, RIndex-LIndex) 
  EndIf 
  
  ProcedureReturn Between 
EndProcedure 

Procedure.s Between_int(string.s, LString.s, RString.s) ;for internal purposes
  Protected Between.s, LIndex.l, RIndex.l 
  
  LIndex = FindString(string, LString, 0) 
  RIndex = FindString(string, RString, Lindex+1) 
  
  If LIndex And RIndex 
    LIndex  + Len(LString) 
    Between = Mid(string, LIndex, RIndex-LIndex) 
  EndIf 
  
  ProcedureReturn Between 
EndProcedure 


;/ Test
; MessageRequester("Between",Between("Droopy", "Dr", "py"))


;} Between (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                            CountRemovableDrive                            |
;  |                            ___________________                            |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ CountRemovableDrive (Start)                                   
;/ Droopy 28/11/05
; Return the number of Removable Media with a media present
; This function can detect a usb key 
; or a memory card present in a memory card reader ( or in a printer with cardslots )

ProcedureDLL CountRemovableDrive()
  For n=2 To 26
    If RealDriveType_(n,0)=#DRIVE_REMOVABLE
      If CheckForMedium(Chr(65+n)+":")
        Count+1 ;/ Only if there is a media in the Removal Drive
      EndIf
    EndIf
  Next
  ProcedureReturn Count
EndProcedure

;/ Test
; MessageRequester("Removable Drive","With media present : "+Str(CountRemovableDrive()),#MB_ICONINFORMATION)




;} CountRemovableDrive (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  DDebug                                   |
;  |                                  ______                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ DDebug (Start)                                                
;/ Functions for debugging with debugger off
;/ I needed this functions for running PureBasic EXE as another user (RUNAS)

ProcedureDLL DDebug(Text.s)
  Global DDebugMessageGlobal.s
  DDebugMessageGlobal+Text+#CRLF$
EndProcedure

ProcedureDLL DDebugShow()
  Global DDebugMessageGlobal.s
  MessageRequester("",DDebugMessageGlobal)
EndProcedure

ProcedureDLL DDebugClear()
  Global DDebugMessageGlobal.s
  DDebugMessageGlobal.s=""
EndProcedure

ProcedureDLL.s DDebugGet()
  ProcedureReturn DDebugMessageGlobal
EndProcedure

ProcedureDLL DDebugLine()
  DDebug("----------------------------")
EndProcedure


;/ Test
; DDebug("This the first Line")
; DDebugLine()
; DDebug("This is another Line")
; DDebug("And another")
; DDebug("And another ...")
; DDebugLine()
; DDebug("This is the end ...")
; DDebugShow()
; DDebugClear()
; DDebug("There is only one line after a clear")
; DDebugShow()


;} DDebug (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 DropFiles                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ DropFiles (Start)                                             
; Original source code by James L.Boyd; 
; Cleaned and reposted by LarsG
; Tweaked by Droopy for Library Purpose

;/ Tested with Succes with a ListIcon & ListView and a Window

Procedure DropFilesInitInternal() ; Internal Procedure (Return the count of dropped files)
  Global DropFilesPointer
  DropFilesPointer=EventwParam() 
  ProcedureReturn DragQueryFile_(DropFilesPointer, $FFFFFFFF, temp$, 0)
EndProcedure 

Procedure.s DropFilesGet(index) ; Internal Procedure
  bufferNeeded = DragQueryFile_(DropFilesPointer, index, 0, 0) 
  For a = 1 To bufferNeeded: buffer$ + " ": Next ; Short by one character! 
  DragQueryFile_(DropFilesPointer, index, buffer$, bufferNeeded+1) 
  ProcedureReturn buffer$ 
EndProcedure 

ProcedureDLL DropFilesAccept(Id,State) ; id=WindowsId or GadgetId / State = #True or #False
  DragAcceptFiles_(Id, State) 
EndProcedure

ProcedureDLL DropFilesInit() ; Initialise and retrieve all files dropped
  Static Initialised
  
  If Initialised=0
    Initialised=1
    Global NewList DropFiles.s()
  Else
    ClearList(DropFiles())
  EndIf
  
  num.l = DropFilesInitInternal()
  For index = 0 To num - 1 
    AddElement(DropFiles())
    DropFiles()=DropFilesGet(index)
  Next 
  
  ;ResetList(dropfiles())
  
  DragFinish_(DropFilesPointer) 
  
  ProcedureReturn ListSize(dropfiles());num
EndProcedure

ProcedureDLL.s DropFilesEnum() ; Each time this function is called, a dropped files is returned until no more
  Static Pointeur  
  
   If Pointeur >= ListSize(DropFiles())
     Pointeur=0
     ClearList(DropFiles())
   Else
     SelectElement(DropFiles(),Pointeur)
     retour.s=DropFiles()
     Pointeur+1
   EndIf
  
  ProcedureReturn retour.s
  
EndProcedure


;/ Test
; #List=0
; OpenWindow(0, 0, 0, 400, 220,  #PB_Window_SystemMenu | #PB_Window_ScreenCentered  , "DropFiles Test") 
; CreateGadgetList(WindowID()) 
; ListIconGadget(#List, 10, 10, 380, 180,"DropFiles Names",375) 
; DropFilesAccept(GadgetID(#List),#True)
; CreateStatusBar(0,WindowID())
  ; 
; Repeat 
  ; Event=WaitWindowEvent() 
  ; 
  ; If Event=#WM_DROPFILES 
    ; NombreFichiers=DropFilesInit()
    ; ClearGadgetItemList(#List)
    ; StatusBarText(0,0,Str(NombreFichiers)+" Dropped Files",#PB_StatusBar_Center )
    ; Repeat
      ; File.s=DropFilesEnum()
      ; If File ="" :  Break : EndIf
      ; AddGadgetItem(#List, -1, File) 
    ; ForEver
  ; EndIf
  ; 
; Until Event=#PB_EventCloseWindow 


;} DropFiles (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                FlashWindow                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ FlashWindow (Start)                                           
;/ Author : Cpl.Bator


ProcedureDLL FlashWindow(hWnd,Delay,Time) 
  For i = 1 To Time 
    FlashWindow_(hWnd,1) 
    Delay(Delay) 
  Next 
  FlashWindow_(hWnd,0) 
EndProcedure

;/ Test
; hWnd=OpenWindow(0,0,0,640,480,#PB_Window_ScreenCentered,"FlashWindow")
; FlashWindow(hWnd,500,10)


;} FlashWindow (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetExtensionIcon                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetExtensionIcon (Start)                                      
;/ Author : Lars
;/ Size : 0 = Small / 1 Large

ProcedureDLL GetExtensionIcon(Extension.s, size.l) 
  Protected Info.SHFILEINFO, StandardIcon.l, flags.l 
  
  StandardIcon = 0 
  
  If Size = 0 
    flags = #SHGFI_USEFILEATTRIBUTES | #SHGFI_ICON | #SHGFI_SMALLICON 
  Else 
    flags = #SHGFI_USEFILEATTRIBUTES | #SHGFI_ICON | #SHGFI_LARGEICON 
  EndIf 
  
  If SHGetFileInfo_("." + extension, #FILE_ATTRIBUTE_NORMAL, @Info.SHFILEINFO, SizeOf(SHFILEINFO), flags) 
    StandardIcon = Info\hIcon 
  Else 
    If Size = 0 
      ExtractIconEx_("shell32.dll", 0, 0, @StandardIcon, 1) 
    Else 
      ExtractIconEx_("shell32.dll", 0, @StandardIcon, 0, 1) 
    EndIf 
  EndIf 
  
  ProcedureReturn StandardIcon 
EndProcedure 


;/ Test 
; extension.s="pb"
; OpenWindow(0, 0, 0, 130, 100, #PB_Window_ScreenCentered | #PB_Window_SystemMenu, "Default Icon") 
; CreateGadgetList(WindowID()) 
; TextGadget(0,10,10,100,25,"For '"+extension+"' extension")
; ImageGadget(1, 10, 40, 32, 32, GetExtensionIcon(extension, 1)) 
; WaitUntilWindowIsClosed()


;} GetExtensionIcon (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             GetTempDirectory                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ GetTempDirectory (Start)                                      
;/ Author : Gillou

ProcedureDLL.s GetTempDirectory() ; Return the temp directory 
  Protected WinTemp.s 
  WinTemp  = Space(255) 
  GetTempPath_(255, WinTemp) 
  If Right(WinTemp, 1) <> "\" : WinTemp = WinTemp + "\" : EndIf 
  ProcedureReturn WinTemp 
EndProcedure 

;/ Test
; MessageRequester("Temp Directory =",GetTempDirectory())

;} GetTempDirectory (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                 LocalText                                 |
;  |                                 _________                                 |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ LocalText (Start)                                             
;  En fait Local & English

; LocalText is for creating a MultiLanguage Software.
; Two language are supported 
; The first language is your language ( example : French )
; The second language is the International language ( English )
; If the user is french the software is in French
; If the user is not french, the software is in English.
; You can get your local language with : 
; MessageRequester("Default Primary Language Identifier","Your Language Identifier is : "+Str(GetLanguage(1)))

;/ Return the default primary language identifier ( 0 system / 1 User )
ProcedureDLL GetLanguage(wich)
  If wich
    ProcedureReturn GetUserDefaultLangID_() & 511
  Else
    ProcedureReturn GetSystemDefaultLangID_() & 511
  EndIf
EndProcedure

;/ Initialise the LocalText function with a Primary language identifier
;/ German = 7 / English 9 / French 12 / Spanish = 10 / Italian = 16 / Portuguese = 22 
ProcedureDLL LocalTextInit(LocalLanguageIdentifier)
  Shared LocaltextIsLocal
  LocaltextIsLocal=0
  If GetLanguage(1)=LocalLanguageIdentifier
    LocaltextIsLocal=1
  EndIf
EndProcedure

;/ Return the correct text regarding the user language 
ProcedureDLL.s LocalText(Local.s,International.s)
  Shared LocaltextIsLocal
  If LocaltextIsLocal
    ProcedureReturn Local
  Else
    ProcedureReturn International
  EndIf
EndProcedure




;/ Test
; LocalTextInit(12) ;/ French Language as local
; 
; WindowsTitle.s=LocalText("Version Française","English Version")
; OpenWindow(0,0,0,200,120,#PB_Window_SystemMenu|#PB_Window_ScreenCentered,WindowsTitle) 
; CreateGadgetList(WindowID())
; 
; CreateStatusBar(0,WindowID())
; StatusBarText(0,0,LocalText("C'est juste un test","It's just a test"),#PB_StatusBar_Center)
; 
; ButtonGadget(0, 10, 10, 180, 80, LocalText("Cliquez Moi","Clic Me"))
; GadgetToolTip(0,LocalText("Ce texte est en Français","This text is in English"))
; 
; WaitUntilWindowIsClosed()

;} LocalText (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                              Path Functions                               |
;  |                              ______________                               |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Path Functions (Start)                                        
;  Lecture et modification du Path pour les postes NT/2K/XP
; Pour Windows 98 / 95 la variable est définie dans l'Autoexec.bat
; Clé de registre de type REG_EXPAND_SZ : Necessite Droopy Lib 1.31 ?

ProcedureDLL.s PathGet()
  ProcedureReturn RegGetValue_int("HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment","Path",".")
EndProcedure

Procedure.s PathGet_int()
  ProcedureReturn RegGetValue_int("HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment","Path",".")
EndProcedure

ProcedureDLL PathSet(Path.s) ; Return 1 if success
  ProcedureReturn RegSetValue("HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment","Path",Path,#REG_EXPAND_SZ,".")  
EndProcedure

ProcedureDLL PathAdd(StringToAdd.s) ; Return 1 if success
  ProcedureReturn PathSet(PathGet_int()+";"+StringToAdd)
EndProcedure

ProcedureDLL PathRefresh() ; Force Windows to refresh Path value for new process
  SendMessage_(#HWND_BROADCAST,#WM_SETTINGCHANGE,0,"Environment")
EndProcedure

;/ Test
; PathSet("%systemroot%")
; PathAdd("c:\titi")
; PathRefresh()

;} Path Functions (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             Printer Functions                             |
;  |                             _________________                             |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Printer Functions (Start)                                     

ProcedureDLL PrinterDelete(PrinterName.s) ; Return 1 if success / 0 if fail (The printer is not deleted if job queue isn't empty)
  
  ;/ Applique la structure + tous les droits à ;/ Delete a LPPRINTER_DEFAULTS
  LPPRINTER_DEFAULTS.PRINTER_DEFAULTS
  LPPRINTER_DEFAULTS\DesiredAccess=#PRINTER_ALL_ACCESS
  
  ;/ Ouvre l'imprimante et récupère son handle
  If OpenPrinter_(PrinterName,@Handle,@LPPRINTER_DEFAULTS)=0
    ProcedureReturn
  EndIf
  
  If DeletePrinter_(Handle)=0
    ClosePrinter_(Handle)
    ProcedureReturn
  EndIf
  
  ClosePrinter_(Handle)
  
  ProcedureReturn 1
EndProcedure

ProcedureDLL PrinterClearJobQueue(PrinterName.s) ; Return 1 if success / 0 if fail
  
  ;/ Applique la structure + tous les droits à ;/ Delete a LPPRINTER_DEFAULTS
  LPPRINTER_DEFAULTS.PRINTER_DEFAULTS
  LPPRINTER_DEFAULTS\DesiredAccess=#PRINTER_ALL_ACCESS
  
  ;/ Ouvre l'imprimante et récupère son handle
  If OpenPrinter_(PrinterName,@Handle,@LPPRINTER_DEFAULTS)=0
    ProcedureReturn
  EndIf
  
  retour=SetPrinter_(Handle,0,0,#PRINTER_CONTROL_PURGE)
  
  ClosePrinter_(Handle)
  
  If retour<>0 : retour=1 : EndIf
  ProcedureReturn retour
EndProcedure

ProcedureDLL.s PrinterEnum() ; Each time this function is called, it return a name of a printer( "" = you are @ the end of the list )
  
  Static index,Cle.s
  
  
  ;/ Détermine quelle clé utiliser ( 98 ou XP )
  If Cle=""
    If NTCore()
      Cle="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\" ; XP
    Else
      Cle="HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print\Printers\" ; 9x
    EndIf
  EndIf
  
  ;/ Liste les clés
  Imprimante.s=RegListSubKey_int(Cle,index,".")
  If Imprimante="" 
    index=0
    PrinterPort=""
    ProcedureReturn ""
  EndIf
  
  nom.s= RegGetValue_int(Cle+Imprimante,"Name",".")
  PrinterPort=RegGetValue_int(Cle+Imprimante,"Port",".")
  
  index+1
  
  ProcedureReturn nom
EndProcedure

ProcedureDLL.s PrinterEnumGetPort() ; Retrieve the port of the printer listed with PrinterEnum
  ProcedureReturn PrinterPort.s
EndProcedure
  

;/ Test
; Repeat
  ; PrinterName.s=PrinterEnum()
  ; If PrinterName="" : Break : EndIf
  ; PrinterPort.s=PrinterEnumGetPort()
  ; DDebug("Printer : "+PrinterName)
  ; DDebug("Port : "+PrinterPort)
  ; DDebugLine()
; ForEver
; DDebugShow()


;} Printer Functions (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                               RunProgramEx                                |
;  |                               ____________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ RunProgramEx (Start)                                          

;/ Same as RunProgram but with optionnal parameters
;/ Returns the handle of the newly created process 
; 1: Wait the program ends
; 2: Run in invisible mode

Declare RunProgramEx2(ProgramNameAndParameters.s,flags)

ProcedureDLL RunProgramEx(ProgramNameAndParameters.s)
  ProcedureReturn RunProgramEx2(ProgramNameAndParameters,0)
EndProcedure

ProcedureDLL RunProgramEx2(ProgramNameAndParameters.s,flags)
  si.STARTUPINFO 
  pi.PROCESS_INFORMATION 
  si\cb = SizeOf(STARTUPINFO) 
  si\dwFlags=#STARTF_USESHOWWINDOW
  
  ;/ Si Hide
  If flags & 2
    si\wShowWindow=#SW_HIDE
  Else
    si\wShowWindow=#SW_NORMAL
  EndIf
  
  retour=CreateProcess_(#Null,ProgramNameAndParameters,#Null,#Null,#False,0,#Null,#Null,@si, @pi) 
  
  If retour ;/ Succès de l'exécution
    
    ;/ Si il faut attendre que l'appli soit terminée
    ;/ On attends que le thread soit terminé
    If flags & 1
      Thread = pi\hThread
      While IsThreadRunning(Thread)
        Delay(1)
      Wend
    EndIf
    
    ProcedureReturn pi\hProcess ;/ On renvoie le Handle du Process créé
  EndIf
  
  ;/ Erreur d'exécution --> On renvoie 0
  
EndProcedure




;/ Test
; RunProgramEx("WordPad yyyyy")
; RunProgramEx("Notepad.exe xxxxxx",1)
; Beep(800,500)

;} RunProgramEx (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                ScreenSaver                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ScreenSaver (Start)                                           
;/ Author : TerryHough

ProcedureDLL ScreenSaver()
  ; Execute the screen saver application specified in the [boot] section of the SYSTEM.INI file. 
  SendMessage_(GetForegroundWindow_(), #WM_SYSCOMMAND, #SC_SCREENSAVE, 0) 
EndProcedure

;/ Test
; ScreenSaver()

;} ScreenSaver (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                             ShellAboutWindow                              |
;  |                             ________________                              |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ ShellAboutWindow (Start)                                      
;/Author Hroudwolf

ProcedureDLL ShellAboutWindow(*ParentWindow,Title.s,FirstText.s,DialogText.s,Icon.l) 
  Text.s=Title.s+"#"+FirstText.s 
  If DialogText.s="":DialogText.s=Chr(32):EndIf  
  ShellAbout_(*ParentWindow,@Text,@DialogText.s,Icon.l) 
EndProcedure  


;/ Test
; ShellAboutWindow(GetDesktopHandle(),"Title","First line","Dialog Text",IconExtract("Shell32.dll",12)) 



;} ShellAboutWindow (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                StringToChr                                |
;  |                                ___________                                |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ StringToChr (Start)                                           
;/ Convert a String to a suite of Chr Code
;/ Usefull to crypt a string and put in your code

ProcedureDLL.s StringToChr(string.s)
  For n = 1 To Len(String)
    temp.s+"Chr("+Str(Asc(Mid(String,n,1)))+")+"
  Next
  temp=Left(temp,Len(temp)-1) ; Delete the last '+'
  ProcedureReturn temp
EndProcedure

;/ Test
; String.s="This is a String"
; StringCrypted.s=RC4Api(String,"Password")
; temp.s=StringToChr(StringCrypted)
; MessageRequester("Your text : "+String,temp)
; SetClipboardText(temp) ;  The password is paste to the ClipBoard as a suite of ascii code ( chr(x)+chr(y)+ ....



;} StringToChr (End)
;  _____________________________________________________________________________
;  |                                                                           |
;  |                                  Xander                                   |
;  |                                  ______                                   |
;  |                                                                           |
;  |___________________________________________________________________________|
;{ Xander (Start)                                                
;/ Demonio Ardente Contribution 28/12/05 ( 3° Time Revisited )

;{- HotKeys Functions

; Hotkeysinit() - initializes the hotkeys lib
; returns nothing
ProcedureDLL HotKeysInit() ; init hotkeys - must be called before all other hotkey functions
  Structure hotkeysinfo
    Id.i
    vk.i
    func.i
    name.s
    window.i
    ismenubased.l
  EndStructure
  Global Dim hotkeys.hotkeysinfo(1000)
  Global HotKeysInitDone
  HotKeysInitDone = 1
EndProcedure
 
; Hotkeyadd() - adds a global hotkey to the list
; returns 1 on success, $DEAD if there's no more space for hotkeys, $DEADBEEF if u havent done hotkeysinit()
ProcedureDLL HotKeyAdd(Window, vk, function.i, Name.s, shiftstate, altstate, controlstate); add a hotkey - see the help file
  Result = 0
  If vk And function And Name And Window And HotKeysInitDone
    idtouse = -1
    For x = 0 To 1000
      If hotkeys(x)\Name = ""
        hotkeys(x)\Name = Name
        hotkeys(x)\vk = vk
        hotkeys(x)\func = function
        hotkeys(x)\Id = x
        hotkeys(x)\Window = Window
        idtouse = x
        Break
      EndIf
    Next x
    
    mods = 0
    If shiftstate = 1
      mods = mods|#MOD_SHIFT
    EndIf
    If altstate = 1
      mods = mods|#MOD_ALT
    EndIf
    If controlstate = 1
      mods = mods|#MOD_CONTROL
    EndIf
    
    If idtouse > -1
      If RegisterHotKey_(Window, idtouse, mods, vk) = 0
      Else
        Result = 1
      EndIf
    Else
      Result = $DEAD
    EndIf
    
  Else
    Result = $DEADBEEF
  EndIf;check needed vars
  ProcedureReturn Result
EndProcedure  

ProcedureDLL HotKeyAdd2(Window, vk, function.i, Name.s, shiftstate, altstate, controlstate, ismenubased)
  Result = 0
  If vk And function And Name And Window And HotKeysInitDone
    idtouse = -1
    For x = 0 To 1000
      If hotkeys(x)\Name = ""
        hotkeys(x)\Name = Name
        hotkeys(x)\vk = vk
        hotkeys(x)\func = function
        hotkeys(x)\Id = x
        hotkeys(x)\Window = Window
        hotkeys(x)\ismenubased = ismenubased
        idtouse = x
        Break
      EndIf
    Next x
    
    mods = 0
    If shiftstate = 1
      mods = mods|#MOD_SHIFT
    EndIf
    If altstate = 1
      mods = mods|#MOD_ALT
    EndIf
    If controlstate = 1
      mods = mods|#MOD_CONTROL
    EndIf
    
    If idtouse > -1
      If RegisterHotKey_(Window, idtouse, mods, vk) = 0
      Else
        Result = 1
      EndIf
    Else
      Result = $DEAD
    EndIf
    
  Else
    Result = $DEADBEEF
  EndIf;check needed vars
  ProcedureReturn Result
EndProcedure

; hotkeycheck() - checks to see if a hotkey event has been fired, if so, runs the function attached to the hotkey
; its better to use hotkeywaitwindowevent() or hotkeywindowevent()
; this one returns 0 if there was a hotkey message and it has been processed, else it returns the messagethat was passed into it
;does nothing if hotkey is menu based
ProcedureDLL HotkeyCheck(message, wparam) ; checks if a hotkey message is waiting, and if it is, runs the function attached to the hotkey
  result = 0
  result = message
  If HotKeysInitDone
    If message = #WM_HOTKEY
      If hotkeys(wparam)\name > ""
        If hotkeys(wparam)\ismenubased = 0
          CallFunctionFast(hotkeys(wparam)\func)
        EndIf
        result = 0
      EndIf
    EndIf
  EndIf;HotKeysInitDone
EndProcedure

; hotkeywaitwindowevent() - uses the waitwindowevent() function to check if a hotkeymsg is there - if it is, runs the associated function
; use instead of waitwindowevent() when you are using the hotkeys lib
; returns an event - but not a #wm_hotkey event 
ProcedureDLL HotkeyWaitWindowEvent() ; uses the waitwindowevent() function to check a hotkey msg
  message = WaitWindowEvent()
  result = message
  If HotKeysInitDone
    If message = #WM_HOTKEY
      wparam = EventwParam()
      If hotkeys(wparam)\name > ""
        If hotkeys(wparam)\ismenubased = 0
          CallFunctionFast(hotkeys(wparam)\func)
        Else
          PostMessage_(WindowID(EventWindow()), #WM_COMMAND, hotkeys(wparam)\func, 0)
        EndIf
        result = HotkeyWaitWindowEvent()
      EndIf
    EndIf
  EndIf;initdone
  ProcedureReturn result
EndProcedure

; hotkeywindowevent() - uses the windowevent() function to check if a hotkeymsg is there - if it is, runs the associated function
; returns the message returned by windowevent() if it is not a hotkey one, if the message is a hotkey message, if will return 0
ProcedureDLL HotkeyWindowEvent() ; uses the windowevent() function to check a hotkey msg
  message = WindowEvent()
  result = message
  If HotKeysInitDone
    If message = #WM_HOTKEY
      wparam = EventwParam()
      If hotkeys(wparam)\name > ""
        If hotkeys(wparam)\ismenubased = 0
          CallFunctionFast(hotkeys(wparam)\func)
        Else
          PostMessage_(WindowID(EventWindow()), #WM_COMMAND, hotkeys(wparam)\func, 0)
        EndIf
        result = 0
      EndIf
    EndIf
  EndIf;initdone
  ProcedureReturn result
EndProcedure

; hotkeyremove() - this function removes the hotkey specified by name
; returns 1 if successful, 0 if unable to unregister hotkey, $DEAD if the hotkey isn't found, $DEADBEEF if name is null or Hotkeysinit() hasnt been called
ProcedureDLL HotKeyRemove(Name.s) ; removes the hotkey specified by name
  If HotKeysInitDone And name
    idtoremove = -1
    For x = 0 To 1000
      If hotkeys(x)\name = name
        idtoremove = x
        done = 1
        Break
      EndIf
    Next x
    If idtoremove > -1
      If UnregisterHotKey_(hotkeys(idtoremove)\window, idtoremove)
        hotkeys(idtoremove)\name = ""
        hotkeys(idtoremove)\vk = 0
        hotkeys(idtoremove)\func = 0
        hotkeys(idtoremove)\Id = 0
        hotkeys(idtoremove)\window = 0
        hotkeys(idtoremove)\ismenubased = 0
        result = 1
      Else
        result = 0
      EndIf
    Else
      result = $DEAD
    EndIf
  Else
    result = $DEADBEEF
  EndIf
EndProcedure

; hotkeychangefunction() - changes the function associated with the hotkey to the one specified by newfunc
ProcedureDLL HotKeyChangeFunction(Name.s, newfunc.i) ; change the function of the specified hotkey to newfunc
  result = 0
  If HotKeysInitDone And name And newfunc
    For x = 0 To 1000
      If hotkeys(x)\name = name
        idtochange = x
        done = 1
        If hotkeys(x)\ismenubased : ProcedureReturn $DEAD : EndIf
        Break
      EndIf
    Next x
    If done = 1
      hotkeys(idtochange)\func = newfunc
      result = 1
    Else
      result = $DEAD
    EndIf
  Else
    result = $DEADBEEF
  EndIf
EndProcedure

;/ Test #1
; Procedure hotkey2()
  ; MessageRequester("hello 2", "this is the seccond functions... that  is all.... please close the main window now..")
; EndProcedure
; 
; Procedure hotkey()
  ; MessageRequester("Hello!", "I got the hotkey message"+Chr(13)+"press again to see a different message")
  ; HotKeyChangeFunction("test", @hotkey2())
; EndProcedure
; 
; HotKeysInit()
; OpenWindow(0, 0,0,200, 100,#PB_Window_SystemMenu|#PB_Window_ScreenCentered, "hotkeys test")
; HotKeyAdd(WindowID(), #VK_A, @hotkey(), "test", 0,1,1)
; 
; Repeat
  ; event = HotkeyWaitWindowEvent()
  ; If event = #WM_CLOSE ; aka #PB_Event_CloseWindow
    ; quit = 1
  ; EndIf
; Until quit = 1
  
  
;/ Test #2
; Procedure hotkey2()
  ; MessageRequester("hello 2", "this is the seccond functions... that  is all.... please close the main window now..")
; EndProcedure
; 
; Procedure hotkey()
  ; MessageRequester("Hello!", "I got the hotkey message"+Chr(13)+"press again to see a different message")
  ; HotKeyChangeFunction("test", @hotkey2())
; EndProcedure
; 
; HotKeysInit()
; 
; OpenWindow(0, 0,0,200, 100,#PB_Window_SystemMenu|#PB_Window_ScreenCentered, "hotkeys test")
; HotKeyAdd(WindowID(), #VK_A, @hotkey(), "test", 0,1,1)
; 
; Repeat
  ; event = HotkeyWindowEvent()
  ; If event = #WM_CLOSE ; aka #PB_Event_CloseWindow
    ; quit = 1
  ; ElseIf event = 0
    ; Delay(20)
  ; EndIf
  ; 
; Until quit = 1

  
;/ Test #3
; Procedure hotkey2()
  ; MessageRequester("hello 2", "this is the seccond functions... that  is all.... please close the main window now..")
; EndProcedure
; 
; Procedure hotkey()
  ; MessageRequester("Hello!", "I got the hotkey message"+Chr(13)+"press again to see a different message")
  ; HotKeyChangeFunction("test", @hotkey2())
; EndProcedure
; 
; HotKeysInit()
; OpenWindow(0, 0,0,200, 100,#PB_Window_SystemMenu|#PB_Window_ScreenCentered, "hotkeys test")
; HotKeyAdd(WindowID(), #VK_A, @hotkey(), "test", 0,1,1)
; 
; 
; Repeat
  ; event = HotkeyCheck(WaitWindowEvent(), EventwParam())
  ; 
; 
  ; If event = #WM_CLOSE ; aka #PB_Event_CloseWindow
    ; quit = 1
  ; EndIf
; 
; Until quit = 1
;}

;{- Simple WinApi

; uses getwindowtext_() to get the title of the specified hwnd
; returns the title of the window
ProcedureDLL.s GetWindowTitleEx(hWnd) ; get the window title of the specified hwnd
  Title.s = Space(#MAX_PATH)
  GetWindowText_(hwnd, @Title, #MAX_PATH)
  ProcedureReturn Title
EndProcedure


; uses getclassname_() to get the class name associated with the specified window
; returns the class name
ProcedureDLL.s GetWindowClassName(hWnd) ; get the class name of the specified hwnd
  classname.s = Space(#MAX_PATH)
  GetClassName_(hwnd, @classname, #MAX_PATH)
  ProcedureReturn classname
EndProcedure
;/ Test
; OpenWindow(0,0,0,100,100,#PB_Window_SystemMenu, "test")
; MessageRequester("GetHwndClassName",GetWindowClassName(WindowID()))


; retrieves the FULL command line sent to the program
; returns the command line in the format of : ' "c:\full\path\to\app.exe" and all the parameters that are passed '
ProcedureDLL.s GetFullCMDLine(); get the full command line sent to the app - please see help file!
  ProcedureReturn PeekS(GetCommandLine_())
EndProcedure


; returns the parameters that were passed to your program - like calling programparameter() a few times and combining the results into one string 
ProcedureDLL.s GetFullCmdArgs() ; get all of the command line arguments passed to your program - see the help file
  cmdline.s = GetFullCMDLine()
  cmdline = Right(cmdline, Len(cmdline)-1)
  cmdline = Right(cmdline, Len(cmdline) - (FindString(cmdline, Chr(34), 0) +1))
  ProcedureReturn cmdline
EndProcedure


; The RegisterWindowMessage function defines a new Window message that is guaranteed To be unique throughout The system.
; Return a message identifier Or 0 If fail
; The RegisterWindowMessage function is typically used To register messages For communicating Between two cooperating applications. 
; If two different applications register The same message string, The applications Return The same message Value. 
; The message remains registered Until The Windows session ends. 
ProcedureDLL RegWinMsg(custommsg.s) ; the same as winapi function RegisterWindowMessage_()
  ProcedureReturn RegisterWindowMessage_(custommsg)
EndProcedure
;/ Test 
; RegWinMsg("my msg to broadcast")


; this function is the same as calling sendmessage_() - just a quicker way of typing it
ProcedureDLL SendMsg(windowhandle, msg, wparam, lparam) ; same as winapi fuction SendMessage_()
  ProcedureReturn SendMessage_(windowhandle, msg, wparam, lparam)
EndProcedure
;/Test 
; SendMsg(WindowID(), #WM_CLOSE, 0,0)


; this function is the same as calling postmessage_() - just a quicker way of typing it
ProcedureDLL PostMsg(windowhandle, msg, wparam, lparam) ; same as winapi fuction PostMessage_()
  ProcedureReturn PostMessage_(windowhandle, msg, wparam, lparam)
EndProcedure
;/ Test 
; PostMsg(WindowID(), #WM_CLOSE, 0,0)


; uses FindWindow_() To find the first instance of the specified class Name
; returns a hwnd (windowhandle) Or 0 If not found
ProcedureDLL FindClassWindow(classname.s) ; get the FIRST hwnd of the specified class. I repeat _FIRST_ hwnd
  Handle = FindWindow_(classname, #NUL)
  ProcedureReturn Handle
EndProcedure
;/ Test
; phandle=RunProgram("notepad.exe")
; WaitProgramInitialisation(phandle) ; to let notepad start...
; hwnd = FindClassWindow("Notepad")
; Delay(1000)
; PostMsg(hwnd, #WM_CLOSE, 0,0) ; close notepad



; this function is like calling CreateWindowEx_()
; Window is the #window parameter of the OpenWindow() function
; x,y,width,height,Title,parentwindowid are the same as their equivelent parameters in OpenWindow()
; normalflags is the same as flags in OpenWindow()
; exflags are the same as dwExStyle in CreateWindowEx_() (see CreateWindowEx_())
; isinvisible is set To 1 when you want the Window To stay invisible - DO NOT USE #PB_Window_Invisible in the flags parameter, IT WILL NOT WORK!!
; the reason that you have To USE this parameter, is because of the way the exflags get put on..... (For those who are curious, look at the source code)
ProcedureDLL OpenWindowEx(Window, x, y, width, height, normalflags, Title.s, exflags, isinvisible); kind of like using createwindowex_()...
  result = OpenWindow(window, x, y, width, height, Title, normalflags|#PB_Window_Invisible)
  If result
    newwinid = WindowID(window)
    SetWindowLongPtr_(newwinid, #GWL_EXSTYLE, GetWindowLongPtr_(newwinid, #GWL_EXSTYLE)|exflags)
    If isinvisible = 0
      HideWindow(window, 0)
    EndIf
  EndIf
  ProcedureReturn result
EndProcedure
 
ProcedureDLL OpenWindowEx2(Window, x, y, width, height, normalflags, Title.s, exflags, isinvisible, parentwindowid)
  Result = OpenWindow(Window, x, y, width, height, Title, normalflags|#PB_Window_Invisible, parentwindowid)
  If Result
    newwinid = WindowID(Window)
    SetWindowLongPtr_(newwinid, #GWL_EXSTYLE, GetWindowLongPtr_(newwinid, #GWL_EXSTYLE)|exflags)
    If isinvisible = 0
      HideWindow(Window, 0)
    EndIf
  EndIf
  ProcedureReturn Result
EndProcedure
;/ Test 
; OpenWindowEx(0, 0,0,200, 100, #PB_Window_SystemMenu|#PB_Window_ScreenCentered, "openwindowex test", #WS_EX_TOOLWINDOW, 0)
; Repeat
  ; Event = WaitWindowEvent()
  ; If Event = #WM_CLOSE;aka #PB_Event_CloseWindow
    ; quit = 1
  ; EndIf
; Until quit = 1

;}

;{- Misc Window Functions


;/ Function CloseHwndWindow Not added because this function is the same as CloseProgram 

; Activates the next window in the z order by emulating an alt-tab press
ProcedureDLL ActivateNextWindow() ; activates the next window in the z-order - simulates alt-tab
  keybd_event_(#VK_MENU, 0, 0, 0)
  keybd_event_(#VK_TAB, 0,0,0)
  keybd_event_(#VK_TAB, 0, #KEYEVENTF_KEYUP, 0)
  keybd_event_(#VK_MENU, 0, #KEYEVENTF_KEYUP, 0)
EndProcedure
 
; Activates the previous window in the z order by emulating an shift-alt-tab press
ProcedureDLL ActivatePrevWindow() ; activates the previous window in z-order - simulates alt-shift-tab
  keybd_event_(#VK_MENU, 0, 0, 0)
  keybd_event_(#VK_SHIFT, 0, 0, 0)
  keybd_event_(#VK_TAB, 0,0,0)
  keybd_event_(#VK_TAB, 0, #KEYEVENTF_KEYUP, 0)
  keybd_event_(#VK_SHIFT, 0, #KEYEVENTF_KEYUP, 0)
  keybd_event_(#VK_MENU, 0, #KEYEVENTF_KEYUP, 0)
EndProcedure
;}

;{- special message boxes

ProcedureDLL InfoBox(message.s) ; shows an infomation messagebox with an optional non default title
  MessageRequester("Info", message, #MB_ICONINFORMATION)
EndProcedure
 ; 
ProcedureDLL InfoBox2(message.s, Title.s)
  MessageRequester(Title, message, #MB_ICONINFORMATION)
  
EndProcedure
  
ProcedureDLL ErrorBox(errormsg.s) ; send an error messagebox to the user - also has an optional non default title
  MessageRequester("Error", errormsg, #MB_ICONERROR)
EndProcedure
  
ProcedureDLL ErrorBox2(errormsg.s, Title.s)
  MessageRequester(Title, errormsg, #MB_ICONERROR)
EndProcedure
;}

;/ Opens a file for appending using openfile() and then seeks to the bottom of the file
;/ returns 1 on success, 0 on failure
ProcedureDLL AppendFile(File, FileName.s) ; open a file for appending
  If OpenFile(file, filename)
    FileSeek(file, Lof(file))
    ProcedureReturn 1
  EndIf 
EndProcedure

; this function simulates a keypress with optional control, alt, and shift
ProcedureDLL SimulateKeyPress(vk, Delay, control, alt, shift)
  If control
    keybd_event_(#VK_CONTROL, 0, 0,0)
  EndIf
  If alt
    keybd_event_(#VK_MENU, 0,0,0)
  EndIf
  If shift
    keybd_event_(#VK_SHIFT, 0,0,0)
  EndIf
  keybd_event_(vk, 0,0,0)
  Delay(Delay)
  keybd_event_(vk, 0, #KEYEVENTF_KEYUP, 0)
  If control
    keybd_event_(#VK_CONTROL, 0, #KEYEVENTF_KEYUP,0)
  EndIf
  If alt
    keybd_event_(#VK_MENU, 0,#KEYEVENTF_KEYUP,0)
  EndIf
  If shift
    keybd_event_(#VK_SHIFT, 0,#KEYEVENTF_KEYUP,0)
  EndIf
EndProcedure

;/ Test
; SimulateKeyPress(#VK_ESCAPE, 0, 1, 0, 0)



;} Xander (End)


#HTTP_QUERY_CONTENT_TYPE=    1

Procedure.s ReadHttpFile(server.s,file.s,port.i=80, overwriteencoding.i=0)
  Protected verb.s="GET",app.s="",openhandle.i,hconnect.i, hreq.i, send_handle.i,headerindex.l,open_handle.i
  Protected result.s="",*buffer,bytes_read.l, encoding, *encoding, encodingsize.l
  
  open_handle.i=InternetOpen_(@app, 1, 0, 0, 0)
  hConnect.i=InternetConnect_(open_handle, @server, port, 0, 0, 3, 0, 0)
  hReq.i=HttpOpenRequest_(hConnect, @verb, @file, 0, 0, 0, 0, 0)
  send_handle.i=HttpSendRequest_(hReq, 0, 0, 0, 0)
  
  *buffer=AllocateMemory(1420)
  
  If overwriteencoding
    encoding = overwriteencoding
  Else
    encodingsize.l = 1024
    *encoding = AllocateMemory(encodingsize)
    headerindex.l = 0
    HttpQueryInfo_(hReq, #HTTP_QUERY_CONTENT_TYPE,*encoding,@encodingsize, @headerindex)
    If FindString(PeekS(*encoding), "UTF-8", 0)
      encoding = #PB_UTF8
    Else
      encoding = #PB_Ascii
    EndIf
  EndIf
  
  Repeat
    InternetReadFile_(hReq, *buffer, 1420, @bytes_read)
    result+Trim(PeekS(*buffer, bytes_read, encoding))
  Until bytes_read=0
  FreeMemory(*buffer)
  FreeMemory(*encoding)
  InternetCloseHandle_(hReq)
  InternetCloseHandle_(hConnect)
  InternetCloseHandle_(open_handle)
  ProcedureReturn result
EndProcedure


; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 6348
; FirstLine = 6341
; Folding = --------------------------------------------------------------------------------------------
; è·§î’¡ë’…ë—¦îŽ³ê‚´ë£¢î– êº°è§§îš¤ê¾½ê—§îž°ê†ë§¢îž­ê†î•­è‚”ê·«î’¼é¢‹ê¯‹
; é’‰ë—¤îšŸë–±ê—¦îš´è²¥î™¢è²…é‡§îž³è†è‡¢îŠ­ë¶€ë£¢îš®é²‘ë·¦îž²ê¾è—¦îš¹ëŽµ