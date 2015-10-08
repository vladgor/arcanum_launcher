
;
; Processes Lib for Purebasic
;
;-----------------------------------------------------------------------------
;     (c) 2004-2005 Siegfried Rings
;
;     This library is free software; you can redistribute it and/or
;     modify it under the terms of the GNU Lesser General Public
;     License as published by the Free Software Foundation; either
;     version 2.1 of the License, Or (at your option) any later version.
;
;     This library is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY Or FITNESS For A PARTICULAR PURPOSE.  See the GNU
;     Lesser General Public License For more details.
;-----------------------------------------------------------------------------


;Structures for setting Privileges
; Structure LUID
;  LowPart.l
;  HighPart.l
; EndStructure

; Structure LUID_AND_ATTRIBUTES
;  pLuid.LUID
;  Attributes.l
; EndStructure

Structure myTOKEN_PRIVILEGES
  PrivilegeCount.l
  TheLuid.LUID
  Attributes.l
EndStructure

Structure PROCESS_MEMORY_COUNTERS
  cb.l
  PageFaultCount.l
  PeakWorkingSetSize.l
  WorkingSetSize.l
  QuotaPeakPagedPoolUsage.l
  QuotaPagedPoolUsage.l
  QuotaPeakNonPagedPoolUsage.l
  QuotaNonPagedPoolUsage.l
  PageFileUsage.l
  PeakPagefileUsage.l
EndStructure

#OWNER_SECURITY_INFORMATION = $00000001
#GROUP_SECURITY_INFORMATION = $00000002
#DACL_SECURITY_INFORMATION  = $00000004
#SACL_SECURITY_INFORMATION  = $00000008
#PROCESS_TERMINATE          = $0001
#PROCESS_CREATE_THREAD      = $0002
#PROCESS_SET_SESSIONID      = $0004
#PROCESS_VM_OPERATION       = $0008
#PROCESS_VM_READ            = $0010
#PROCESS_VM_WRITE           = $0020
#PROCESS_DUP_HANDLE         = $0040
#PROCESS_CREATE_PROCESS     = $0080
#PROCESS_SET_QUOTA          = $0100
#PROCESS_SET_INFORMATION    = $0200
#PROCESS_QUERY_INFORMATION  = $0400
#PROCESS_ALL_ACCESS         = #STANDARD_RIGHTS_REQUIRED | #SYNCHRONIZE | $FFF

#NbProcessesMax = 1024 ;10000
;Dim ProcessesArray(#NbProcessesMax)



;Thread priority consts
#THREAD_BASE_PRIORITY_IDLE = -15
#THREAD_BASE_PRIORITY_LOWRT = 15
#THREAD_BASE_PRIORITY_MAX = 2
#THREAD_BASE_PRIORITY_MIN = -2
#THREAD_PRIORITY_HIGHEST = #THREAD_BASE_PRIORITY_MAX
#THREAD_PRIORITY_LOWEST = #THREAD_BASE_PRIORITY_MIN
#THREAD_PRIORITY_ABOVE_NORMAL = (#THREAD_PRIORITY_HIGHEST - 1)
#THREAD_PRIORITY_BELOW_NORMAL = (#THREAD_PRIORITY_LOWEST + 1)
;#THREAD_PRIORITY_ERROR_RETURN = (#MAXLONG)
#THREAD_PRIORITY_IDLE = #THREAD_BASE_PRIORITY_IDLE
#THREAD_PRIORITY_NORMAL = 0
#THREAD_PRIORITY_TIME_CRITICAL = #THREAD_BASE_PRIORITY_LOWRT

Structure thread32
  size.l
  use.l
  idth.l
  parentid.l
  base.l
  delta.l
  flags.l
EndStructure

Global PSAPI
Global Kernel

;drivers
Global DriverZeiger
Global MaxDriver
Global DriverMem

;examine DLL's
Global ProcessDLL
Global MaxProcessDLL
Global DLLMemModule

Global ProcessesArrayMem;memory wo die Daten liegen
Global nProcesses ;Anzahl aller Proxess
Global nProcessesZeiger;Aktueller Zeiger

Prototype.l EnumProcesses(a,b,c)
Prototype.l EnumProcessModules(a,b,c,d)
Prototype.l GetModuleBaseName(a,b,c.p-ascii,d)
Prototype.l GetModuleFileName(a,b,c.p-ascii,d)
Prototype.l EnumDeviceDrivers(a,b,c)
Prototype.l GetDeviceDriversBaseName(a,b.p-ascii,c)
Prototype.l GetDeviceDriversFileName(a,b.p-ascii,c)
Prototype.l GetProcessMemoryInfo(a,b,c)
Prototype.l EmptyWorkingSet(a)

Prototype.l CreateToolhelp32Snapshot(a,b)
Prototype.l Thread32First(a,b)
Prototype.l Thread32Next(a,b)
Prototype.l OpenThread(a,b,c)

Procedure SetRights(rightsname.s)
  tLuid.LUID
  tTokenPriv.myTOKEN_PRIVILEGES
  tTokenPrivNew.myTOKEN_PRIVILEGES
  lBufferNeeded.l

  ;#PROCESS_ALL_ACCESS = $1F0FFF
  #PROCESS_TERMINAT = $1
  #ANYSIZE_ARRAY = 1
  #TOKEN_ADJUST_PRIVILEGES = $20
  #TOKEN_QUERY = $8
  SE_DEBUG_NAME.s = rightsname.s
  #SE_PRIVILEGE_ENABLED = $2
  lhThisProc = GetCurrentProcess_()

  res=OpenProcessToken_(lhThisProc, #TOKEN_ADJUST_PRIVILEGES | #TOKEN_QUERY, @lhTokenHandle)
  res=LookupPrivilegeValue_("", SE_DEBUG_NAME.s, tLuid)

  ;Set the number of privileges to be change
  tTokenPriv\PrivilegeCount = 1
  tTokenPriv\TheLuid\LowPart = tLuid\LowPart
  tTokenPriv\TheLuid\HighPart = tLuid\HighPart

  tTokenPriv\Attributes = #SE_PRIVILEGE_ENABLED

  ;Enable the kill privilege in the access token of this process
  res=AdjustTokenPrivileges_(lhTokenHandle, 0, tTokenPriv, SizeOf(tTokenPrivNew), tTokenPrivNew, @lBufferNeeded)
EndProcedure

ProcedureDLL PBOSL_Process_Init()
  PSAPI=OpenLibrary(#PB_Any,"psapi.dll")
  If PSAPI
    Global EnumProcesses.EnumProcesses = GetFunction(PSAPI, "EnumProcesses")
    Global EnumProcessModules.EnumProcessModules = GetFunction(PSAPI, "EnumProcessModules")
    Global GetModuleBaseName.GetModuleBaseName  = GetFunction(PSAPI, "GetModuleBaseNameA")
    Global GetModuleFileName.GetModuleFileName  = GetFunction(PSAPI, "GetModuleFileNameExA")
    Global EnumDeviceDrivers.EnumDeviceDrivers = GetFunction(PSAPI, "EnumDeviceDrivers")
    Global GetDeviceDriversBaseName.GetDeviceDriversBaseName = GetFunction(PSAPI, "GetDeviceDriverBaseNameA")
    Global GetDeviceDriversFileName.GetDeviceDriversFileName = GetFunction(PSAPI, "GetDeviceDriverFileNameA")
    Global GetProcessMemoryInfo.GetProcessMemoryInfo = GetFunction(PSAPI, "GetProcessMemoryInfo")
    Global EmptyWorkingSet.EmptyWorkingSet = GetFunction(PSAPI, "EmptyWorkingSet")
    ;GetProcessMemoryInfo Lib "PSAPI.DLL"(ByVal hProcess As Long,ppsmemCounters As PROCESS_MEMORY_COUNTERS,ByVal cb As Long )
    ;GetDeviceDriverBaseName Lib "psapi.dll" Alias "GetDeviceDriverBaseName" (ImageBase As Any, ByVal lpBaseName As String, ByVal nSize As Long )
    ;EnumDeviceDrivers Lib "PSAPI.DLL" (lpImageBase() As Long,ByVal cb As Long , lpcbNeeded As Long

    ProcessesArrayMem=GlobalAlloc_(#GMEM_FIXED ,#NbProcessesMax*4)
    DriverMem=GlobalAlloc_(#GMEM_FIXED ,1024*4)
    DLLMemModule=GlobalAlloc_(#GMEM_FIXED ,1024*4)
    ;ProcedureReturn PSAPI
  EndIf

  ;note , under NT there are not these functions available, so i do a late binding
  ; Falsche Variable verwendet, angepaßt ts-soft 11.07.2005
  Kernel=OpenLibrary(#PB_Any, "kernel32.dll")
  If Kernel
    Global CreateToolhelp32Snapshot.CreateToolhelp32Snapshot=GetFunction(Kernel, "CreateToolhelp32Snapshot")
    Global Thread32First.Thread32First=GetFunction(Kernel, "Thread32First")
    Global Thread32Next.Thread32Next=GetFunction(Kernel, "Thread32Next")
    Global OpenThread.OpenThread=GetFunction(Kernel, "OpenThread")
  EndIf
EndProcedure

ProcedureDLL PBOSL_Process_End()
  If ProcessesArrayMem
    GlobalFree_(ProcessesArrayMem)
  EndIf
  If DriverMem
    GlobalFree_(DriverMem)
  EndIf
  If DLLMemModule
    GlobalFree_(DLLMemModule)
  EndIf
  If PSAPI
    CloseLibrary(PSAPI)
  EndIf
EndProcedure

ProcedureDLL ExamineDrivers();Reset the Driverlist
  Result=EnumDeviceDrivers(DriverMem,1024*4,@needed)
  MaxDriver=needed/4
  DriverZeiger=0
  ProcedureReturn MaxDriver
EndProcedure

ProcedureDLL NextDriver();examine next driver
  DriverZeiger+1
  If DriverZeiger>MaxDriver
    DriverZeiger=MaxDriver
    ProcedureReturn 0
  Else
    ProcedureReturn DriverZeiger
  EndIf
EndProcedure

ProcedureDLL GetDriverBase();gets the adress in Memory where the driver is loaded
  *L1.LONG
  *L1=DriverMem+((DriverZeiger-1)*4)
  ProcedureReturn *L1\l
EndProcedure

ProcedureDLL.s GetDriverName();Gets the name of the driver
  Name.s=Space(1024)
  Result=GetDeviceDriversBaseName(GetDriverBase(),Name.s,Len(Name.s))
  Name.s = PeekS(@Name, #PB_Any, #PB_Ascii)
  ProcedureReturn Name.s
EndProcedure

ProcedureDLL.s GetDriverFileName();gets the full filename of the driver
  Name.s=Space(1024)
  Result=GetDeviceDriversFileName(GetDriverBase(),Name.s,Len(Name.s))
  Name.s = PeekS(@Name, #PB_Any, #PB_Ascii)
  ProcedureReturn Name.s
EndProcedure

ProcedureDLL ReArrangeMem(PID)
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS  , 0, PID)
  If hProcess
    Result=EmptyWorkingSet(hProcess)
    SetProcessWorkingSetSize_(hProcess, -1, -1)
    CloseHandle_(hProcess)
  EndIf
EndProcedure

ProcedureDLL RemovePagefaults(PID);remove unneded memory from Process
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS  , 0, PID)
  If hProcess
    Result=EmptyWorkingSet(hProcess)
    CloseHandle_(hProcess)
    If Result=0
      el=GetLastError_()
      Nop.s=Space(1024)
      FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM,0, el,0,@Nop.s,1024,0)
      MessageRequester("Error RemovePageFaults","Error "+Str(el)+Chr(13)+Chr(10)+Nop.s ,0)
    EndIf
    ProcedureReturn Result
  Else
    ProcedureReturn -2
  EndIf
EndProcedure

ProcedureDLL ExamineProcesses() ;take a snapshot and examine processes
  EnumProcesses(ProcessesArrayMem, #NbProcessesMax, @nProcesses)
  nProcessesZeiger=0
  ProcedureReturn nProcesses/4
EndProcedure

ProcedureDLL NextProcess();examine next Process
  nProcessesZeiger+1
  If nProcessesZeiger>(nProcesses/4)
    nProcessesZeiger=(nProcesses/4)
    ProcedureReturn 0
  Else
    ProcedureReturn nProcessesZeiger
  EndIf
EndProcedure

ProcedureDLL ExamineProcessDLLS(PID);Examine all DLL's of a process
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=EnumProcessModules(hProcess, DLLMemModule, 1024*4, @cbNeeded)
    MaxProcessDLL=cbNeeded/4
    CloseHandle_(hProcess)
    ProcessDLL=0
    ProcedureReturn MaxProcessDLL
  EndIf
EndProcedure

ProcedureDLL NextProcessDLL();examine next dll of a process
  ProcessDLL+1
  If ProcessDLL>MaxProcessDLL
    ProcessDLL=MaxProcessDLL
    ProcedureReturn 0
  Else
    ProcedureReturn ProcessDLL
  EndIf
EndProcedure

ProcedureDLL.s GetProcessDLLName(PID);get back the Dll-Name out of the process
  *L1.LONG
  *L1=DLLMemModule+(ProcessDLL-1)*4
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=EnumProcessModules(hProcess, DLLMemModule, 1024*4, @cbNeeded)
    Name.s=Space(1024)
    Result=GetModuleBaseName(hProcess, *L1\l, Name.s, Len(Name.s))
    CloseHandle_(hProcess)
    ProcedureReturn Name.s
  EndIf
EndProcedure

ProcedureDLL.s GetProcessDLLFileName(PID);get back the full Filename of the loaded DLL
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=EnumProcessModules(hProcess, DLLMemModule, 1024*4, @cbNeeded)
    Name.s=Space(1024)
    Result=GetModuleFileName(hProcess, DLLMemModule, Name.s, Len(Name.s))
    CloseHandle_(hProcess)
    ProcedureReturn Name.s
  EndIf
EndProcedure

ProcedureDLL.l GetProcessDLLBase(PID);get the loaded adress of the dll
  *L1.LONG
  *L1=DLLMemModule+(ProcessDLL-1)*4
  ProcedureReturn *L1\l
EndProcedure

ProcedureDLL.s GetProcessName();get the name of the process
  *L1.LONG
  *L1=ProcessesArrayMem+(nProcessesZeiger-1)*4
  If *L1\l=0
    ProcedureReturn "IDLE"
  EndIf
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, *L1\l)
  If hProcess
    Result=EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
    Name$ = Space(255)
    Result=GetModuleBaseName(hProcess, BaseModule, Name$, Len(Name$))
    CloseHandle_(hProcess)
    If Name$="?"
      ProcedureReturn "System"
    Else
      ProcedureReturn Name$
    EndIf
  EndIf
EndProcedure

ProcedureDLL.s GetProcessName2(PID);get the name of the process
  ;MessageRequester("Info",Str(PID),0)
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
    LName3$ = Space(255)
    Result=GetModuleBaseName(hProcess, BaseModule, LName3$, Len(LName3$))
    CloseHandle_(hProcess)
    ; MessageRequester("Info " +Str(Result),LNAme3$,0)
    ProcedureReturn LName3$
  Else
    ProcedureReturn "Unknow process"
  EndIf
EndProcedure

ProcedureDLL.s GetProcessFileName();get the full Filename of the process
  *L1.LONG
  *L1=ProcessesArrayMem+(nProcessesZeiger-1)*4
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, *L1\l)
  ;Debug hprocess
  If hProcess
    Result=EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
    Name$ = Space(255)
    Result=GetModuleFileName(hProcess, BaseModule, name$, Len(name$))
    CloseHandle_(hProcess)
    ProcedureReturn Name$
  EndIf
EndProcedure

ProcedureDLL.s GetProcessFileName2(PID);get the full Filename of the process
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
    Name$ = Space(255)
    Result=GetModuleFileName(hProcess, BaseModule, name$, Len(name$))
    CloseHandle_(hProcess)
    ProcedureReturn Name$
  EndIf
EndProcedure

ProcedureDLL GetProcessRights(handle); can we acess this process (0 = Not, 1=yes)
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, handle)
  If hProcess
    CloseHandle_(hProcess)
    ProcedureReturn 1
  EndIf
EndProcedure

ProcedureDLL GetProcessMem();get the memory is use of the process
  *L1.LONG
  *L1=ProcessesArrayMem+(nProcessesZeiger-1)*4
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, *L1\l)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\WorkingSetSize
  EndIf
EndProcedure

ProcedureDLL GetProcessMem2(PID);get the memory is use of the process
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\WorkingSetSize
  EndIf
EndProcedure

ProcedureDLL GetProcessPageFaultCount(PID) ;Get Number of page faults.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\PageFaultCount
  EndIf
EndProcedure

ProcedureDLL GetProcessPeakWorkingSetSize (PID) ;Get Peak working set size.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\PeakWorkingSetSize

  EndIf
EndProcedure

ProcedureDLL GetProcessWorkingSetSize(PID);Get Current working set size.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\WorkingSetSize
  EndIf
EndProcedure

ProcedureDLL GetProcessQuotaPeakPagedPoolUsage(PID);Get Peak paged pool usage.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\QuotaPeakPagedPoolUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessQuotaPagedPoolUsage (PID);Get Current paged pool usage.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\QuotaPagedPoolUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessQuotaPeakNonPagedPoolUsage (PID);Get Peak nonpaged pool usage.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\QuotaPeakNonPagedPoolUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessQuotaNonPagedPoolUsage (PID);Get Current nonpaged pool usage.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\QuotaNonPagedPoolUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessPagefileUsage(PID);Get Current space allocated For the pagefile. Those pages may Or may not be in memory.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\PageFileUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessPeakPagefileUsage (PID);Get Peak space allocated For the pagefile.
  tPMC.PROCESS_MEMORY_COUNTERS
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    Result=GetProcessMemoryInfo(hProcess, tPMC, SizeOf(tPMC))
    CloseHandle_(hProcess)
    ProcedureReturn tPMC\PeakPagefileUsage
  EndIf
EndProcedure

ProcedureDLL GetProcessPIDfromHWND(hwnd);Get a PID from the window handle (hwnd)
  Result=GetWindowThreadProcessId_ (hwnd, @PID)
  ProcedureReturn PID
EndProcedure

ProcedureDLL GetProcessPID();get actual PID
  *L1.LONG
  *L1=ProcessesArrayMem+(nProcessesZeiger-1)*4
  ProcedureReturn *L1\l
EndProcedure

ProcedureDLL GetProcessPID2(LName.s);get PID from the Processname
  ;Dim ProcessesArray(#NbProcessesMax)
  Mem1=GlobalAlloc_(#GMEM_FIXED ,#NbProcessesMax*4)
  *L1.LONG
  EnumProcesses(Mem1, #NbProcessesMax, @nProcesses0)
  ;MessageRequester("Info",LName.s + ":" +Str(nProcesses0/4),0)
  For k=1 To nProcesses0/4
    *L1=Mem1+(k-1)*4
    hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, *L1\l)
    If hProcess
      EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
      LName2$ = Space(255)
      GetModuleBaseName(hProcess, BaseModule, LName2$, Len(LName2$))
      ;Debug Name$
      CloseHandle_(hProcess)
      If LCase(LName2$)=LCase(LName.s)
        handle=*L1\l
        Break
      EndIf
    EndIf
  Next
  GlobalFree_(Mem1)
  ProcedureReturn handle
EndProcedure

Procedure GetOwnPID()
  ProcedureReturn GetCurrentProcess_()
EndProcedure

ProcedureDLL GetProcessPrio(PID);get the priority of the process
  hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
  If hProcess
    prio=GetPriorityClass_(hProcess)
    CloseHandle_(hProcess)
    ProcedureReturn prio
  EndIf
EndProcedure

ProcedureDLL SetProcessPrio(PID,Priority);sets the priority of the process
  SetRights("SeIncreaseBasePriorityPrivilege")

  hProcess = OpenProcess_(#PROCESS_SET_INFORMATION , 1, PID)
  If hProcess
    prio=SetPriorityClass_(hProcess,Priority)
    CloseHandle_(hProcess)
    ProcedureReturn prio
  EndIf
EndProcedure

ProcedureDLL KillPID(PID,ExitCode);exit the process with Exitcode
  SetRights("SeDebugPrivilege")
  ;Open the process to kill

  hProcess = OpenProcess_(#PROCESS_TERMINAT, 0, PID)
  ; hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, PID)
  If hProcess
    Result=TerminateProcess_(hProcess,ExitCode)
    CloseHandle_(hProcess)
    ProcedureReturn Result
  EndIf
EndProcedure

ProcedureDLL KillAllProcess(LName.s,ExitCode);exit all processes with Name with Exitcode
  SetRights("SeDebugPrivilege")


  Mem1=GlobalAlloc_(#GMEM_FIXED ,#NbProcessesMax*4)
  *L1.LONG
  EnumProcesses(Mem1, #NbProcessesMax, @nProcesses0)

  For k=1 To nProcesses0/4
    *L1=Mem1+(k-1)*4
    PID=*L1\l
    hProcess = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, PID)
    If hProcess
      EnumProcessModules(hProcess, @BaseModule, 4, @cbNeeded)
      LName2$ = Space(255)
      GetModuleBaseName(hProcess, BaseModule, LName2$, Len(LName2$))
      CloseHandle_(hProcess)

      If LCase(LName2$)=LCase(LName.s)
        hProcess = OpenProcess_(#PROCESS_TERMINAT , 0, PID)

        If hProcess
          Result=TerminateProcess_(hProcess,ExitCode)
          CloseHandle_(hProcess)
        EndIf
      EndIf
    EndIf
  Next
  GlobalFree_(Mem1)
  ProcedureReturn handle
EndProcedure

ProcedureDLL pPeekL(handle,addr);get a Long from the process with Offset
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_VM_READ, 0, handle)
  If hProcess
    ReadProcessMemory_(hProcess,addr,@res,4,0)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL.w pPeekW(handle,addr);get a word from the process with Offset
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_VM_READ, 0, handle)
  If hProcess
    ReadProcessMemory_(hProcess,addr,@res.w,2,0)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL.b pPeekB(handle,addr);get a Byte from the process with Offset
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_VM_READ  , 0, handle)
  If hProcess
    ReadProcessMemory_(hProcess,addr,@res.b,1,0)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL.s pPeekS(handle,addr);get a String from the process with Offset
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_VM_READ , 0, handle)
  If hProcess
    res.s=""
    Repeat
      ReadProcessMemory_(hProcess,addr,@res2.b,1,0)
      res+Chr(res2.b & $FF)
      addr+1
    Until byte=0
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL pReadMemory(handle,addr, DestinationMemoryID, Length);copys Data from the process with Offset to own Process Destinationmemory
  SetRights("SeDebugPrivilege")
  hProcess = OpenProcess_(#PROCESS_VM_READ, 0, handle)
  If hProcess
    ReadProcessMemory_(hProcess,addr,DestinationMemoryID,Length,0)
    CloseHandle_(hProcess)
  EndIf
EndProcedure

ProcedureDLL pPokeL(handle,addr,value);Writes a Long to the process with Offset
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, handle)
  If hProcess
    OrigMode=1
    Mode=#PAGE_EXECUTE_READWRITE
    VirtualProtectEx_(hProcess,addr,4,Mode,@OrigMode)
    res=WriteProcessMemory_(hProcess,addr,@value,4,0)
    VirtualProtectEx_(hProcess,addr,4,OrigMode,@Mode)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL pPokeW(handle,addr,value.w);Writes a word to the process with Offset
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, handle)
  If hProcess
    OrigMode=1
    Mode=#PAGE_EXECUTE_READWRITE
    VirtualProtectEx_(hProcess,addr,2,Mode,@OrigMode)
    res=WriteProcessMemory_(hProcess,addr,@value,2,0)
    VirtualProtectEx_(hProcess,addr,2,OrigMode,@Mode)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL pPokeB(handle,addr,value.b);Writes a Byte to the process with Offset
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, handle)
  If hProcess
    OrigMode=1
    Mode=#PAGE_EXECUTE_READWRITE
    VirtualProtectEx_(hProcess,addr,1,Mode,@OrigMode)
    WriteProcessMemory_(hProcess,addr,@value,1,0)
    VirtualProtectEx_(hProcess,addr,1,OrigMode,@Mode)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure

ProcedureDLL pWriteMemory(handle,addr, SourceMemoryID, Laenge) ;copys Data from Sourcememory(own process) to the process with Offset
  hProcess = OpenProcess_(#PROCESS_ALL_ACCESS , 0, handle)
  If hProcess
    OrigMode=1
    Mode=#PAGE_EXECUTE_READWRITE
    VirtualProtectEx_(hProcess,addr,Laenge,Mode,@OrigMode)
    res=WriteProcessMemory_(hProcess,addr,SourceMemoryID,Laenge,0)
    VirtualProtectEx_(hProcess,addr,Laenge,OrigMode,@Mode)
    CloseHandle_(hProcess)
    ProcedureReturn res
  EndIf
EndProcedure


; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 270
; FirstLine = 251
; Folding = ---------
; EnableUser