Declare createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
Declare.s getSpecialFolder(id)

Procedure.s getSpecialFolder(id)
  Protected path.s, *ItemId.ITEMIDLIST
 
  *itemId = #Null
  If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
    path = Space(#MAX_PATH)
    If SHGetPathFromIDList_(*itemId, @path)
      If Right(path, 1) <> "\"
        path + "\"
      EndIf
      ProcedureReturn path
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
  ;obj - path to the exe that is linked to, lnk - link name, dir - working
  ;directory, icon - path to the icon file, index - icon index in iconfile
  Protected hRes.l, mem.s, ppf.IPersistFile
  CompilerIf #PB_Compiler_Unicode
    Protected psl.IShellLinkW
  CompilerElse
    Protected psl.IShellLinkA
  CompilerEndIf

  ;make shure COM is active
  CoInitialize_(0)
  hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)

  If hRes = 0
    psl\SetPath(Obj)
    psl\SetArguments(arg)
    psl\SetDescription(desc)
    psl\SetWorkingDirectory(dir)
    psl\SetIconLocation(icon, index)
    ;query IShellLink for the IPersistFile interface for saving the
    ;link in persistent storage
    hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)

    If hRes = 0
      ;CompilerIf #PB_Compiler_Unicode
        ;save the link
        hRes = ppf\Save(lnk, #True)
;       CompilerElse
;         ;ensure that the string is ansi unicode
;         mem = Space(#MAX_PATH)
;         MultiByteToWideChar_(#CP_ACP, 0, lnk, -1, mem, #MAX_PATH)
;         ;save the link
;         hRes = ppf\Save(mem, #True)
;       CompilerEndIf
      ppf\Release()
    EndIf
    psl\Release()
  EndIf

  ;shut down COM
  CoUninitialize_()

  DataSection
    CLSID_ShellLink:
    Data.l $00021401
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IShellLink:
    CompilerIf #PB_Compiler_Unicode
      Data.l $000214F9
    CompilerElse
      Data.l $000214EE
    CompilerEndIf
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IPersistFile:
    Data.l $0000010b
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
  EndDataSection
  ProcedureReturn hRes
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; Folding = -
; EnableXP