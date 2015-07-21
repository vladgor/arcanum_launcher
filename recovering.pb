text.s = getFileContent ("launcher\debug.txt")

;if can't find a record about mod deactivation in debug file
b = FindString(text,"activate" + Chr(13) + "---")

If (b) And (Not FindString(text,"deactivate" + Chr(13) + "---"))
  
  ;(13 = len("activate") + len("---") + 1)
  text = Mid(text, b + 13)
  
  If MessageRequester("",localMsgDoYouWantToRecoverMod, #MB_ICONQUESTION | #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
      i = CountString(text, Chr(13))
      str.s = ""
      action.s = ""
      args.s = ""
      oldPath.s = ""
      newPath.s = ""
      temp.s = ""
      
      errors = 0
      errorsLog.s
      
      For k = i + 1 To 1 Step -1
        str = StringField(text,k, Chr(13))
        
        If str <> ""
          action = StringField(str, 1, ":")
          args = Trim(StringField(str,2, ":"))
          Debug args
          If FindString(args, " -> ")
            temp = ReplaceString(args, " -> ", "|")
            oldPath = StringField(temp, 2, "|")
            newPath = StringField(temp, 1, "|")
          EndIf
          
          Select action
            ;folders
            Case "folder backuped"
              If Not(RenameFile(args, Left(args, Len(args) - Len("Backup"))))
                errors = errors + 1
                errorsLog = errorsLog + "Couldn't unbackup this directory: " + args + Chr(13)
              EndIf
              
            Case "folder replaced"
              If Not(RenameFile(oldPath, NewPath))
                errors = errors + 1  
                errorsLog = errorsLog + "Couldn't move " + Chr(34) + oldPath + Chr(34) + " to " + Chr(34) + newPath + Chr(34) + Chr(13)
              EndIf
              
            Case "created"
              If Not(DeleteDirectory(args, "*.*", #PB_FileSystem_Force))
                errors = errors + 1  
                errorsLog = errorsLog + "Couldn't delete this directory: " + args + Chr(13)
              EndIf
              
            ;files
            Case "backuped"
              If Not(RenameFile(args, Left(args, Len(args) - Len(".backup"))))
                errors = errors + 1 
                errorsLog = errorsLog + "Couldn't unbackup this file: " + args + Chr(13)
              EndIf
              
            Case "replaced"
              If Not(RenameFile(oldPath, NewPath))
                errors = errors + 1  
                errorsLog = errorsLog + "Couldn't move " + Chr(34) + oldPath + Chr(34) + " to " + Chr(34) + newPath + Chr(34) + Chr(13)
              EndIf
          EndSelect
          
        EndIf
      Next
      
      If errors
        MessageRequester("", ReplaceString(localMsgErrorsOccuredWhileRecovering, "%errors", Str(errors)) + Chr(13) + errorsLog, #MB_ICONERROR)
      Else
        MessageRequester("", localMsgRecoveringWasDoneSuccesfully, #MB_ICONINFORMATION)
      EndIf
   EndIf
    
EndIf
; IDE Options = PureBasic 5.11 (Windows - x86)
; EnableXP
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\launcher.exe