If FileSize("launcher.cfg") = - 1
  CreatePreferences("launcher.cfg", #PB_Preference_GroupSeparator)
Else
  OpenPreferences("launcher.cfg", #PB_Preference_GroupSeparator)
EndIf

PreferenceGroup("common")
Global cfgLanguage.s       = ReadPreferenceString ("language", "")
Global cfgInfoLink.s       = ReadPreferenceString ("infoLink", "http://www.x1a7.ru/arcanumLauncher/mods.txt")
Global cfgInfoTestFile.s   = ReadPreferenceString ("infoTestFile", "http://www.x1a7.ru/arcanumLauncher/test.txt")
Global cfgInfoTestHost.s   = ReadPreferenceString ("infoTestHost", "")
Global cfgInfoTestPort     = ReadPreferenceInteger ("infoTestPort", 0)
Global cfgLastUsedMod.s    = ReadPreferenceString ("lastUsedMod", "NoMod")
Global cfgCheckForUpdate.i = ReadPreferenceInteger ("checkForUpdate", 1)
Global cfgStoreLogs.i      = ReadPreferenceInteger ("storeLogs", 0)
PreferenceGroup(cfgLanguage)

;main window
Global localBtnLaunch.s             = ReadPreferenceString ("btnLaunch", "Launch")
Global localBtnGetMoreMods.s        = ReadPreferenceString ("btnGetMoreMods", "Get more mods")
Global localBtnCheckingConnection.s = ReadPreferenceString ("btnCheckingConnection", "Checking connection...")
Global localBtnCantConnect.s        = ReadPreferenceString ("btnCantConnect", "Can't connect")

Global localColModName.s            = ReadPreferenceString ("colModName", "name")
Global localColModVersion.s         = ReadPreferenceString ("colModVersion", "version")

Global localMenuOpenModFolder.s     = ReadPreferenceString ("menuOpenModFolder", "Open folder location")
Global localMenuOpenDescription.s   = ReadPreferenceString ("menuOpenDescription", "Show mod description")
Global localMenuCheckForUpdates.s   = ReadPreferenceString ("menuCheckForUpdates", "Check for updates")
Global localMenuCreateShortcut.s    = ReadPreferenceString ("menuCreateShortcut", "Create shortcut")
Global localMenuBackup.s            = ReadPreferenceString ("menuBackup", "Backup saves")
Global localMenuUnbackup.s          = ReadPreferenceString ("menuUnbackup", "Unbackup saves")
Global localMenuDelete.s            = ReadPreferenceString ("menuDelete", "Delete")
Global localMenuPropeties.s         = ReadPreferenceString ("menuPropeties", "Properties")
Global localMenuRename.s            = ReadPreferenceString ("menuRename", "Rename")

;windows titles
Global localWndGetModTitle.s        = ReadPreferenceString ("wndGetModTitle", "Mod Downloader")
Global localWndGetModDownloadingTitle.s = ReadPreferenceString ("wndGetModDownloadingTitle", "Downloading")
Global localWndShortcutTitle.s      = ReadPreferenceString ("wndShortcutTitle", "create shortcut")
Global localWndBackupTitle.s        = ReadPreferenceString ("wndBackupTitle", "backup mod")
Global localWndUnbackupTitle.s      = ReadPreferenceString ("wndUnbackupTitle", "unbackup mod")
Global localWndDescriptionTitle.s   = ReadPreferenceString ("wndDescriptionTitle", "description")
Global localWndPropertiesTitle.s    = ReadPreferenceString ("wndPropertiesTitle", "properties")
Global localWndChangeModNameTitle.s = ReadPreferenceString ("WndChangeModNameTitle", "rename mod")

;backup window
Global localLblBackupName.s         = ReadPreferenceString ("lblBackupName", "Name:")
Global localLblBackupDescription.s  = ReadPreferenceString ("lblBackupDescription", "Description:")
Global localBtnBackup.s             = ReadPreferenceString ("btnBackup", "Backup")

Global localLblBackupStatus.s       = ReadPreferenceString ("lblBackupStatus", "Backuping...")
Global localLblBackupStatusOk.s     = ReadPreferenceString ("lblBackupStatusOk", "Everything is okay. Closing window...")
Global localLblBackupStatusError.s  = ReadPreferenceString ("lblBackupStatusError", "Backup with this name already exists!")

;shortcut window
Global localBtnCreateShortcut.s     = ReadPreferenceString ("btnCreateShortcut", "Create shortcut")
Global localLblShortcutLine.s       = ReadPreferenceString ("lblShortcutLine","Enter command line arguments (e.g " + Chr(34) + "-fullscreen -no3d -fps" + Chr(34) + "):")
Global localLblShortcutList.s       = ReadPreferenceString ("lblShortcutList", "List of available command line arguments:")

Global localTtFullScreen.s          = ReadPreferenceString ("ttFullScreen", "Starts the game in fullscreen (compact UI) mode")
Global localTtFPS.s                 = ReadPreferenceString ("ttFPS", "Displays current FPS in the top left corner")
Global localTtNoSound.s             = ReadPreferenceString ("ttNoSound", "Starts the game without sound")
Global localTtNoRandomEnc.s         = ReadPreferenceString ("ttNoRandomEnc", "Turns off random encounters")
Global localTtScrollFps.s           = ReadPreferenceString ("ttScrollFps", "Scrolling speed. If not specified it will be the default value of 35.")
Global localTtScrolDist.s           = ReadPreferenceString ("ttScrollDist", "Scrolling distance. Set it to 0 to make it infinite. Default: 10")
Global localTtMod.s                 = ReadPreferenceString ("ttMod", "Runs a different module at startup")
Global localTtNo3d.s                = ReadPreferenceString ("ttNo3d", "Starts the game in safe mode (software renderer)")
Global localTtVidFreed.s            = ReadPreferenceString ("ttVidFreed", "Increases art cache by [number]")
Global localTtDoubleBuffer.s        = ReadPreferenceString ("ttDoubleBuffer", "Double buffer. May increase performance")
Global localTtMpAutoJoin.s          = ReadPreferenceString ("ttMpAutoJoin", "Turns on AutoJoin for multiplayer")
Global localTtMpNoBcast.s           = ReadPreferenceString ("ttMpNoBcast", "Turns on NoBroadcast for Multiplayer")
Global localTtDialogNumber.s        = ReadPreferenceString ("ttDialogNumber", "Shows PC dialogue line numbers in game")
Global localTtDialogCheck.s         = ReadPreferenceString ("ttDialogCheck", "Checks all dialogue files for missing lines, prints the results in the debug output")
Global localTtGenderCheck.s         = ReadPreferenceString ("ttGenderCheck", "Checks if characters have correct gender specific descriptions when loading a map. Prints all errors in the debug output")
Global localTtLogCheck.s            = ReadPreferenceString ("ttLogCheck", "Checks all log entries, prints the results in the debug output")
Global localTtLwindowed.s           = ReadPreferenceString ("ttLogWindowed", "[launcher-specific] Starts the game in windowed mode. Works only if " + Chr(34) + "-no3d"  + Chr(34) + " argument is written")

Global localMsgSaveShortcut.s       = ReadPreferenceString ("msgSaveShortcut", "Choose place where shortcut will be created")

;rename window

Global localTxtRenameMod.s          = ReadPreferenceString ("txtRenameMod", "Enter new mod name:")

;unbackup window 
Global localBtnUnbackup.s           = ReadPreferenceString ("btnUnbackup", "Unbackup")

Global localLblUnbackupStatus.s     = ReadPreferenceString ("lblUnbackupStatus", "Unbackuping...")
Global localLblUnbackupStatusOk.s   = ReadPreferenceString ("lblUnbackupStatusOk", "Everything is okay. Closing window...")
Global localLblUnbackupStatusCantUnzip.s  = ReadPreferenceString ("lblUnbackupStatusCantUnzip", "Can't unzip files")
Global localLblUnbackupStatusUnspec.s = ReadPreferenceString ("lblUnbackupStatusUnspec", "Can't unbackup. Unspecified error")

;mod properties window
Global localBtnSaveModProperties.s   = ReadPreferenceString ("btnSaveModProperties", "Apply")

;get mod window
Global localBtnAbortDownloading.s      = ReadPreferenceString ("btnAbortDownloading", "Abort")

;+ %mod
Global localLblGetModStatusPreparing.s = ReadPreferenceString ("lblGetModStatusPreparing", "Preparing to download %mod...")
;+ %progress
Global localLblGetModStatusDownloading.s = ReadPreferenceString ("lblGetModStatusDownloading", "Downloading %mod (%progress%)...")
Global localLblGetModStatusUnzipping.s = ReadPreferenceString ("lblGetModStatusUnzipping", "Unzipping %mod...")
Global localLblGetModStatusInstalled.s = ReadPreferenceString ("lblGetModStatusInstalled", "%mod was successfully installed")

Global localLblGetModStatusCantUnzip.s = ReadPreferenceString ("lblGetModStatusCantUnzip", "ERROR: Can't unzip")
Global localLblGetModStatusFileDamaged.s = ReadPreferenceString ("lblGetModStatusFileDamaged", "ERROR: Downloaded file is damaged")
Global localLblGetModStatusCantDownload.s = ReadPreferenceString ("lblGetModStatusCantDownload", "ERROR: Can't download")


;вернуть многоточия обратно в функции!!! wut?

;update mod window
;+ %mod
Global localLblUpdateStatusBackuping.s = ReadPreferenceString ("lblUpdateStatusBackuping", "Backuping %mod...")
Global localLblUpdateStatusPreparing.s = ReadPreferenceString ("lblUpdateStatusPreparing", "Preparing to download update...")
Global localLblUpdateStatusDeleting.s  = ReadPreferenceString ("lblUpdateStatusDeleting", "Deleting old files...")
Global localLblUpdateStatusUnzipping.s = ReadPreferenceString ("lblUpdateStatusUnzipping", "Unzipping new files...")
Global localLblUpdateStatusUnbackuping.s = ReadPreferenceString ("lblUpdateStatusUnbackuping", "Unbackuping old files...")
Global localLblUpdateStatusOk.s = ReadPreferenceString ("lblUpdateStatusOk", "%Mod has been successfully updated")

Global localLblUpdateStatusDeletingError.s  = ReadPreferenceString ("lblUpdateStatusDeletingError", "ERROR: Can't delete mod's directory")
Global localLblUpdateStatusUnzippingError.s = ReadPreferenceString ("lblUpdateStatusUnzippingError", "ERROR: Can't unzip mod")
Global localLblUpdateStatusUnbackupingError.s = ReadPreferenceString ("lblUpdateStatusUnbackupingError", "ERROR: Can't unbackup mod")
Global localLblUpdateStatusDownloadingError.s = ReadPreferenceString ("lblUpdateStatusDownloadingError", "ERROR: Can't download mod")
Global localLblUpdateStatusBackupingError.s = ReadPreferenceString ("lblUpdateStatusBackupingError", "ERROR: Can't backup")
Global localLblUpdateStatusClosingWindow.s = ReadPreferenceString ("lblUpdateStatusClosingWindow", "Closing window...")

;messages
Global localMsgBlankNameWasEntered.s    = ReadPreferenceString ("msgBlankNameEntered", "New name should contain at least one character")
Global localMsgCantRenameMod.s          = ReadPreferenceString ("msgCantRenameMod", "Can't rename this mod, because another mod with this name is installed")
Global localMsgNoMoreModsAreAvailable.s = ReadPreferenceString ("msgNoMoreModsAreAvailable", "There are no more mods available")
Global localMsgYouHaveNoBackup.s    = ReadPreferenceString ("msgYouHaveNoBackup", "You have no backups for this mod")
Global localMsgYouAlreadyHaveTheNewestVersion.s = ReadPreferenceString ("msgYouAlreadyHaveTheNewestVersion", "You already have the newest version")
Global localMsgCantRunSeveralCopies.s    = ReadPreferenceString ("msgCantRunSeveralCopies", "You can't run several launchers for one Arcanum")
;%version and %newversion
Global localMsgNewVersionAvailable.s     = ReadPreferenceString ("msgNewVersionAvailable", "There is new version available (your version: %version, new version: %newVersion)")
;
Global localMsgDoYouWantToUpdate.s       = ReadPreferenceString ("msgDoYouWantToUpdate", "Do you want to update this mod? Your game progress will be saved (I hope)")
Global localMsgCantFindSpecMod.s         = ReadPreferenceString ("msgCantFindSpecMod", "Can't find specified mod")
Global localMsgDoYouWantToDeleteMod.s    = ReadPreferenceString ("msgDoYouWantToDeleteMod", "Are you sure you want to delete this mod? Game progress for this mod will be deleted as well")

Global localMsgCantDeleteMod.s           = ReadPreferenceString ("msgCantDeleteMod", "Can't delete mod")

Global localMsgCantFindDownloadableMod.s = ReadPreferenceString ("msgCantFindDownloadableMod", "Can't find this mod in list of downloadable mods")

Global localMsgRecoveringWasDoneSuccesfully.s = ReadPreferenceString("MsgRecoveringWasDoneSuccesfully", "Recovering was successfully done")
Global localMsgDoYouWantToRecoverMod.s = ReadPreferenceString ("MsgDoYouWantToRecoverMod", "It looks like ArcanumLauncher has crashed. Do you want ArcanumLauncher to recover mod?")
;%errors
Global localMsgErrorsOccured.s           = ReadPreferenceString ("msgErrorsOccured", "")
Global localMsgErrorsOccuredWhileRecovering.s = ReadPreferenceString("MsgErrorsOccuredWhileRecovering", "%errors occured while recovering:")


;update launcher
;%version, %newversion and %cr
Global localMsgLauncherNewVersionFound.s = ReadPreferenceString ("msgLauncherNewVersionFound", "New version of arcanumLauncher is available:" + Chr(10) + Chr(13) + "current: %version"  + Chr(10) + Chr(13) + "new: %newversion"  + Chr(10) + Chr(13) + "Do you want your launcher to be updated?")
localMsgLauncherNewVersionFound = ReplaceString(localMsgLauncherNewVersionFound, "%cr", Chr(10) + Chr(13))
Global localMsgLauncherUpdateFailed.s    = ReadPreferenceString ("msgLauncherUpdateFailed", "ERROR: Couldn't update launcher")
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 75
; FirstLine = 57
; EnableXP
; Executable = C:\Documents and Settings\vladgor\Рабочий стол\temporary\launcher.exe