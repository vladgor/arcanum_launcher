Procedure.s Reverse(s.s)
  O.s=Mid(s,Len(s),1)
  P=Len(s)-1
  While P>0
    O.s=O+Mid(s,P,1)
    P=P-1
  Wend
  ProcedureReturn O
EndProcedure

Global fileNumber = Random(999,10)
Global hURL
Global hInet
Global *buf

Procedure DoEvents()
  msg.MSG
  If PeekMessage_(msg,0,0,0,1)
    TranslateMessage_(msg)
    DispatchMessage_(msg)
  Else
    Sleep_(1)
  EndIf
EndProcedure

Procedure.s GetQueryInfo(hHttpRequest.l, iInfoLevel.l)
  lBufferLength.l=0
  lBufferLength = 1024
  sBuffer.s=Space(lBufferLength)
  HttpQueryInfo_(hHttpRequest, iInfoLevel, sBuffer, @lBufferLength, 0)
  ProcedureReturn Left(sBuffer, lBufferLength)
EndProcedure

Procedure.l UrlToFileWithProgress(myFile.s, URL.s, size.q)
  isLoop.b=1
  Bytes.q=0
  fBytes.q=0
  Buffer.l=4096
  res.s=""
  tmp.s=""
 
  OpenType.b=1
  INTERNET_FLAG_RELOAD.l = $80000000
  INTERNET_FLAG_KEEP_CONNECTION.l = $00400000
  INTERNET_DEFAULT_HTTP_PORT.l = 80
  INTERNET_SERVICE_HTTP.l = 3
  HTTP_QUERY_STATUS_CODE.l = 19
  HTTP_QUERY_STATUS_TEXT.l = 20
  HTTP_QUERY_RAW_HEADERS.l = 21
  HTTP_QUERY_RAW_HEADERS_CRLF.l = 22


  *Buf = AllocateMemory(Buffer)
 
  
  myMax.q
  
  Result = CreateFile(fileNumber, myFile)
  hInet = InternetOpen_("", OpenType, #Null, #Null, 0)
  hURL = InternetOpenUrl_(hInet, URL, #Null, 0, INTERNET_FLAG_RELOAD | INTERNET_FLAG_KEEP_CONNECTION, 0)
 
  ;get Filesize
   domain.s = ReplaceString(Left(URL,(FindString(URL, "/",8) - 1)),"http://","")
   hInetCon = InternetConnect_(hInet,domain, INTERNET_DEFAULT_HTTP_PORT, #Null, #Null, INTERNET_SERVICE_HTTP, 0, 0)
   If hInetCon > 0
     hHttpOpenRequest = HttpOpenRequest_(hInetCon, "HEAD", ReplaceString(URL,"http://"+domain+"/",""), "http/1.1", #Null, 0, INTERNET_FLAG_RELOAD, 0)
     If hHttpOpenRequest > 0
       iretval = HttpSendRequest_(hHttpOpenRequest, #Null, 0, 0, 0)
       If iretval > 0
         tmp = GetQueryInfo(hHttpOpenRequest, HTTP_QUERY_STATUS_CODE)
         If Trim(tmp) = "200"
           tmp = GetQueryInfo(hHttpOpenRequest, HTTP_QUERY_RAW_HEADERS_CRLF)
           If FindString(tmp,"Content-Length:",1)>0
             ii.l=FindString(tmp, "Content-Length:",1) + Len("Content-Length:")
             tmp = Mid(tmp, ii, Len(tmp)-ii)
             myMax = Val(Trim(tmp))
           EndIf
         EndIf
       EndIf
     EndIf
   EndIf
 
  i = 0
  ;start downloading
  
  If myMax = 0 ;if it isn't possible to determine size 
    myMax = size
  EndIf
  
  
  Repeat
    InternetReadFile_(hURL, *Buf, Buffer, @Bytes)
    
    If bytes = 0
      Break
    Else
      fBytes=fBytes+Bytes
      If size >= fBytes 
        If i = 20
          progress.i = Int(fBytes/myMax * 100)
          SetGadgetState(#pbDownloading, progress)
          text.s = ReplaceString(localLblGetModStatusDownloading, "%mod", dMod, #PB_String_NoCase)
          text = ReplaceString(text, "%progress", Str(progress), #PB_String_NoCase)
          SetGadgetText(#lblDownloading, text)
          i = 0
        EndIf
      EndIf
      
      i = i + 1
      WriteData(fileNumber,*Buf, Bytes)
    EndIf  
    
    DoEvents()
  ForEver
    
  InternetCloseHandle_(hURL)
  InternetCloseHandle_(hInet)
  CloseFile(fileNumber)   
  FreeMemory(*Buf)
  
  If fBytes = myMax
    ProcedureReturn #True
  Else
    ProcedureReturn #False   
  EndIf
EndProcedure

Procedure abortDownloading()
  If IsThread(dThread)
   InternetCloseHandle_(hURL)
   InternetCloseHandle_(hInet)
   FreeMemory(*Buf)
   CloseFile(fileNumber)
   KillThread(dThread)
   
   d("Aborted!")
   If DeleteFile(dModTempFile)
     d("Temp file deleted")
   Else 
     d("!ERROR: can't delete temp file")
   EndIf
   HideGadget(#lstGetModList,0)
   HideGadget(#wbGetMod,0)
   HideGadget(#lblDownloading,1)
   HideGadget(#pbDownloading, 1)
   HideGadget(#btnAbortDownloading, 1)
   
   dIndent(3)
   FlushFileBuffers(0)
   SetWindowTitle(#wndGetMod,"ArcanumLauncher " + lVersion + ", Mod Downloader")
 EndIf
EndProcedure

; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 130
; FirstLine = 110
; Folding = 8
; EnableThread
; EnableXP
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\temporary\launcher.exe