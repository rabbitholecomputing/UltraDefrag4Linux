/*
 *  UltraDefrag - a powerful defragmentation tool for Windows NT.
 *  Copyright (c) 2007-2011 by Dmitri Arkhangelski (dmitriar@gmail.com).
 *  Copyright (c) 2010-2011 by Stefan Pendl (stefanpe@users.sourceforge.net).
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
* Universal code for both regular and micro edition installers.
*/

!ifndef _ULTRA_DEFRAG_NSH_
!define _ULTRA_DEFRAG_NSH_

/*
* 1. ${DisableX64FSRedirection} is required before
*    all macros except CheckWinVersion and UninstallTheProgram.
* 2. Most macros require the $INSTDIR variable
*    to be set and plugins directory to be initialized.
*    It is safe to do both initialization actions
*    in the .onInit function.
*/

Var AtLeastXP

!macro CheckMutex

    Push $R0

    ; check if UltraDefrag is running
    System::Call 'kernel32::OpenMutex(i 0x100000, b 0, t "ultradefrag_mutex") i .R0'
    ${If} $R0 == 0
        System::Call 'kernel32::OpenMutex(i 0x100000, b 0, t "\BaseNamedObjects\ultradefrag_mutex") i .R0'
    ${EndIf}
    ${If} $R0 == 0
        System::Call 'kernel32::OpenMutex(i 0x100000, b 0, t "\Sessions\1\BaseNamedObjects\ultradefrag_mutex") i .R0'
    ${EndIf}
    ${If} $R0 != 0
        System::Call 'kernel32::CloseHandle(i $R0)'
        MessageBox MB_OK|MB_ICONEXCLAMATION "Ultra Defragmenter is running. Please close it first!" /SD IDOK
        Abort
    ${EndIf}

    Pop $R0

!macroend

!define CheckMutex "!insertmacro CheckMutex"

;-----------------------------------------

!macro CheckWinVersion

    ${If} ${AtLeastWinXP}
        StrCpy $AtLeastXP 1
    ${Else}
        StrCpy $AtLeastXP 0
    ${EndIf}

    ${Unless} ${IsNT}
    ${OrUnless} ${AtLeastWinNT4}
        MessageBox MB_OK|MB_ICONEXCLAMATION \
        "On Windows 9x and NT 3.x this program is absolutely useless!$\nIf you are running another system then something is corrupt inside it.$\nTherefore we will try to continue." \
        /SD IDOK
        ;Abort
        /*
        * Sometimes on modern versions of Windows it fails.
        * This problem has been encountered on XP SP3 and Vista.
        * Therefore let's assume that we have at least XP system.
        * A dirty hack, but should work.
        */
        StrCpy $AtLeastXP 1
    ${EndUnless}

    /* this idea was suggested by bender647 at users.sourceforge.net */
    Push $R0
    ClearErrors
    ;ReadEnvStr $R0 "PROCESSOR_ARCHITECTURE"
    ; On 64-bit systems it always returns 'x86' because the installer
    ; is a 32-bit application and runs on a virtual machine :(((

    ; read the PROCESSOR_ARCHITECTURE variable from registry
    ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
    "PROCESSOR_ARCHITECTURE"

    ${Unless} ${Errors}
        ${If} $R0 == "x86"
        ${AndIf} ${ULTRADFGARCH} != "i386"
            MessageBox MB_OK|MB_ICONEXCLAMATION \
            "This installer cannot be used on 32-bit Windows!$\n \
            Download the i386 version from http://ultradefrag.sourceforge.net/" \
            /SD IDOK
            Pop $R0
            Abort
        ${EndIf}
        ${If} $R0 == "amd64"
        ${AndIf} ${ULTRADFGARCH} != "amd64"
            MessageBox MB_OK|MB_ICONEXCLAMATION \
            "This installer cannot be used on x64 version of Windows!$\n \
            Download the amd64 version from http://ultradefrag.sourceforge.net/" \
            /SD IDOK
            Pop $R0
            Abort
        ${EndIf}
        ${If} $R0 == "ia64"
        ${AndIf} ${ULTRADFGARCH} != "ia64"
            MessageBox MB_OK|MB_ICONEXCLAMATION \
            "This installer cannot be used on IA-64 version of Windows!$\n \
            Download the ia64 version from http://ultradefrag.sourceforge.net/" \
            /SD IDOK
            Pop $R0
            Abort
        ${EndIf}
    ${EndUnless}
    Pop $R0

!macroend

!define CheckWinVersion "!insertmacro CheckWinVersion"

;-----------------------------------------

/**
 * This procedure installs all mandatory files and
 * upgrades already existing configuration files
 * if they are in obsolete format.
 */
!macro InstallCoreFiles

    ${DisableX64FSRedirection}

    DetailPrint "Installing core files..."
    SetOutPath "$INSTDIR"
        File "${ROOTDIR}\src\LICENSE.TXT"
        File "${ROOTDIR}\src\CREDITS.TXT"
        File "${ROOTDIR}\src\HISTORY.TXT"
        File "${ROOTDIR}\src\README.TXT"

        File "lua5.1a.exe"
        File "lua5.1a_gui.exe"

    SetOutPath "$INSTDIR\scripts"
        File "${ROOTDIR}\src\scripts\udreportcnv.lua"
        File "${ROOTDIR}\src\scripts\udsorting.js"

    ; A. install default CSS for file fragmentation reports
        ${If} ${FileExists} "$INSTDIR\scripts\udreport.css"
            ${Unless} ${FileExists} "$INSTDIR\scripts\udreport.css.old"
                ; ensure that user's choice will not be lost
                Rename "$INSTDIR\scripts\udreport.css" "$INSTDIR\scripts\udreport.css.old"
            ${EndUnless}
        ${EndIf}
        File "${ROOTDIR}\src\scripts\udreport.css"
        
    ; B. install default report options
    SetOutPath "$INSTDIR\options"
        ${If} ${FileExists} "$INSTDIR\options\udreportopts.lua"
            ${Unless} ${FileExists} "$INSTDIR\options\udreportopts.lua.old"
                ; ensure that user's choice will not be lost
                Rename "$INSTDIR\options\udreportopts.lua" "$INSTDIR\options\udreportopts.lua.old"
            ${EndUnless}
        ${EndIf}
        File "${ROOTDIR}\src\scripts\udreportopts.lua"

    SetOutPath "$SYSDIR"
        File "zenwinx.dll"
        File "udefrag.dll"
        File "wgx.dll"
        File "lua5.1a.dll"
        File /oname=hibernate4win.exe "hibernate.exe"
        File "${ROOTDIR}\src\installer\ud-help.cmd"

    DetailPrint "Register .luar file extension..."
    WriteRegStr HKCR ".luar" "" "LuaReport"
    WriteRegStr HKCR "LuaReport" "" "Lua Report"
    WriteRegStr HKCR "LuaReport\DefaultIcon" "" "$INSTDIR\lua5.1a_gui.exe,1"
    WriteRegStr HKCR "LuaReport\shell\view" "" "View report"
    WriteRegStr HKCR "LuaReport\shell\view\command" "" \
        "$\"$INSTDIR\lua5.1a_gui.exe$\" $\"$INSTDIR\scripts\udreportcnv.lua$\" $\"%1$\" $\"$INSTDIR$\" -v"

    ${EnableX64FSRedirection}

!macroend

!define InstallCoreFiles "!insertmacro InstallCoreFiles"

;-----------------------------------------

!macro RemoveCoreFiles

    ${DisableX64FSRedirection}

    DetailPrint "Removing core files..."
    Delete "$INSTDIR\LICENSE.TXT"
    Delete "$INSTDIR\CREDITS.TXT"
    Delete "$INSTDIR\HISTORY.TXT"
    Delete "$INSTDIR\README.TXT"
    Delete "$INSTDIR\lua5.1a.exe"
    Delete "$INSTDIR\lua5.1a_gui.exe"
    RMDir /r "$INSTDIR\scripts"
    RMDir /r "$INSTDIR\options"

    Delete "$SYSDIR\zenwinx.dll"
    Delete "$SYSDIR\udefrag.dll"
    Delete "$SYSDIR\wgx.dll"
    Delete "$SYSDIR\lua5.1a.dll"
    Delete "$SYSDIR\hibernate4win.exe"
    Delete "$SYSDIR\ud-help.cmd"

    DetailPrint "Deregister .luar file extension..."
    DeleteRegKey HKCR "LuaReport"
    DeleteRegKey HKCR ".luar"

    ${EnableX64FSRedirection}

!macroend

!define RemoveCoreFiles "!insertmacro RemoveCoreFiles"

;-----------------------------------------

!macro InstallBootFiles

    ${DisableX64FSRedirection}

    ${If} ${FileExists} "$SYSDIR\defrag_native.exe"
        DetailPrint "Removing current boot interface..."
        ClearErrors
        Delete "$SYSDIR\defrag_native.exe"
        ${If} ${Errors}
            /*
            * If the native app depends on native DLL's
            * it may cause BSOD in case of inconsistency
            * between their versions. Therefore, we must
            * force upgrade to the latest monolithic native
            * defragmenter.
            */
            MessageBox MB_OK|MB_ICONSTOP \
            "Cannot update $SYSDIR\defrag_native.exe file!" \
            /SD IDOK
            ; try to recover the problem
            ExecWait '"$SYSDIR\bootexctrl.exe" /u /s defrag_native'
            ; the second attempt, just for safety
            ${EnableX64FSRedirection}
            SetOutPath $PLUGINSDIR
            File "bootexctrl.exe"
            ExecWait '"$PLUGINSDIR\bootexctrl.exe" /u /s defrag_native'
            ; abort the installation
            Abort
        ${EndIf}
    ${EndIf}

    DetailPrint "Installing boot interface..."
    SetOutPath "$INSTDIR\man"
    File "${ROOTDIR}\src\man\*.*"

    SetOutPath "$SYSDIR"
    File "${ROOTDIR}\src\installer\boot-config.cmd"
    File "${ROOTDIR}\src\installer\boot-off.cmd"
    File "${ROOTDIR}\src\installer\boot-on.cmd"
    File "bootexctrl.exe"
    File "defrag_native.exe"

    ${Unless} ${FileExists} "$SYSDIR\ud-boot-time.cmd"
        File "${ROOTDIR}\src\installer\ud-boot-time.cmd"
        File "${ROOTDIR}\src\installer\ud-boot-time.ini"
    ${Else}
        ; the script of v5.0 is not compatible with previous
        ; versions because of the filter syntax changes
        ${Unless} ${FileExists} "$SYSDIR\ud-boot-time.ini"
            Rename "$SYSDIR\ud-boot-time.cmd" "$SYSDIR\ud-boot-time.cmd.old"
            File "${ROOTDIR}\src\installer\ud-boot-time.cmd"
            File "${ROOTDIR}\src\installer\ud-boot-time.ini"
        ${EndUnless}
    ${EndUnless}
  
    ${EnableX64FSRedirection}

!macroend

!define InstallBootFiles "!insertmacro InstallBootFiles"

;-----------------------------------------

!macro RemoveBootFiles

    ${DisableX64FSRedirection}

    DetailPrint "Removing boot interface..."
    RMDir /r "$INSTDIR\man"

    ExecWait '"$SYSDIR\bootexctrl.exe" /u /s defrag_native'

    Delete "$SYSDIR\boot-config.cmd"
    Delete "$SYSDIR\boot-off.cmd"
    Delete "$SYSDIR\boot-on.cmd"
    Delete "$SYSDIR\bootexctrl.exe"
    Delete "$SYSDIR\defrag_native.exe"
    Delete "$SYSDIR\ud-boot-time.cmd"
    Delete "$SYSDIR\ud-boot-time.cmd.old"
    Delete "$SYSDIR\ud-boot-time.ini"

    ${EnableX64FSRedirection}

!macroend

!define RemoveBootFiles "!insertmacro RemoveBootFiles"

;-----------------------------------------

!macro InstallConsoleFiles

    ${DisableX64FSRedirection}

    DetailPrint "Installing console interface..."
    SetOutPath "$SYSDIR"
        File "udefrag.exe"

    ${EnableX64FSRedirection}

!macroend

!define InstallConsoleFiles "!insertmacro InstallConsoleFiles"

;-----------------------------------------

!macro RemoveConsoleFiles

    ${DisableX64FSRedirection}

    DetailPrint "Removing console interface..."
    Delete "$SYSDIR\udefrag.exe"

    ${EnableX64FSRedirection}

!macroend

!define RemoveConsoleFiles "!insertmacro RemoveConsoleFiles"

;-----------------------------------------

!macro InstallGUIFiles

    ${DisableX64FSRedirection}

    DetailPrint "Installing GUI interface..."
    SetOutPath "$INSTDIR\i18n"
        File /nonfatal "${ROOTDIR}\src\gui\i18n\*.lng"
        File /nonfatal "${ROOTDIR}\src\gui\i18n\*.template"

    SetOutPath "$INSTDIR"
        Delete "$INSTDIR\ultradefrag.exe"
        File "ultradefrag.exe"
        
    SetOutPath "$INSTDIR\scripts"
        File "${ROOTDIR}\src\scripts\upgrade-guiopts.lua"
        
    DetailPrint "Upgrade GUI preferences..."
    ${If} ${Silent}
        ExecWait '"$INSTDIR\lua5.1a_gui.exe" -s "$INSTDIR\scripts\upgrade-guiopts.lua" "$INSTDIR"'
    ${Else}
        ExecWait '"$INSTDIR\lua5.1a_gui.exe" "$INSTDIR\scripts\upgrade-guiopts.lua" "$INSTDIR"'
    ${EndIf}

    Push $R0
    Push $0

    DetailPrint "Register file extensions..."
    ; Without $SYSDIR because x64 system applies registry redirection for HKCR before writing.
    ; When we are using $SYSDIR Windows always converts them to C:\WINDOWS\SysWow64.

    ClearErrors
    ReadRegStr $R0 HKCR ".lua" ""
    ${If} ${Errors}
        WriteRegStr HKCR ".lua" "" "Lua.Script"
        WriteRegStr HKCR "Lua.Script" "" "Lua Script File"
        WriteRegStr HKCR "Lua.Script\shell\Edit" "" "Edit Script"
        WriteRegStr HKCR "Lua.Script\shell\Edit\command" "" "notepad.exe %1"

        WriteRegStr HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua" "1"
    ${Else}
        StrCpy $0 $R0
        ClearErrors
        ReadRegStr $R0 HKCR "$0\shell\Edit" ""
        ${If} ${Errors}
            WriteRegStr HKCR "$0\shell\Edit" "" "Edit Script"
            WriteRegStr HKCR "$0\shell\Edit\command" "" "notepad.exe %1"

            WriteRegStr HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua.edit" "1"
        ${EndIf}
    ${EndIf}

    ClearErrors
    ReadRegStr $R0 HKCR ".lng" ""
    ${If} ${Errors}
        WriteRegStr HKCR ".lng" "" "LanguagePack"
        WriteRegStr HKCR "LanguagePack" "" "Language Pack"
        WriteRegStr HKCR "LanguagePack\shell\open" "" "Open"
        WriteRegStr HKCR "LanguagePack\DefaultIcon" "" "shell32.dll,0"
        WriteRegStr HKCR "LanguagePack\shell\open\command" "" "notepad.exe %1"

        WriteRegStr HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lng" "1"
    ${EndIf}

    Pop $0
    Pop $R0

    ${EnableX64FSRedirection}

!macroend

!define InstallGUIFiles "!insertmacro InstallGUIFiles"

;-----------------------------------------

!macro RemoveGUIFiles

    ${DisableX64FSRedirection}

    DetailPrint "Removing GUI interface..."
    RMDir /r "$INSTDIR\i18n"

    Delete "$INSTDIR\ultradefrag.exe"
    Delete "$INSTDIR\scripts\upgrade-guiopts.lua"
    
    Push $R0

    DetailPrint "Unregister file extensions..."
    ClearErrors
    ReadRegStr $R0 HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua"
    ${Unless} ${Errors}
        ${If} $R0 == "1"
            DeleteRegKey HKCR "Lua.Script"
            DeleteRegKey HKCR ".lua"
            DeleteRegValue HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua"
        ${EndIf}
    ${EndUnless}

    ClearErrors
    ReadRegStr $R0 HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua.edit"
    ${Unless} ${Errors}
        ${If} $R0 == "1"
            ClearErrors
            ReadRegStr $R0 HKCR ".lua" ""
            ${Unless} ${Errors}
                DeleteRegKey HKCR "$R0\shell\Edit"
                DeleteRegValue HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lua.edit"
            ${EndUnless}
        ${EndIf}
    ${EndUnless}

    ClearErrors
    ReadRegStr $R0 HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lng"
    ${Unless} ${Errors}
        ${If} $R0 == "1"
            DeleteRegKey HKCR "LanguagePack"
            DeleteRegKey HKCR ".lng"
            DeleteRegValue HKLM ${UD_UNINSTALL_REG_KEY} "Registered.lng"
        ${EndIf}
    ${EndUnless}

    Pop $R0

    ${EnableX64FSRedirection}

!macroend

!define RemoveGUIFiles "!insertmacro RemoveGUIFiles"

;-----------------------------------------

!macro InstallHelpFiles

    ${DisableX64FSRedirection}

    DetailPrint "Installing documentation..."
    RMDir /r "$INSTDIR\handbook"

    SetOutPath "$INSTDIR\handbook"
        File "${ROOTDIR}\doc\html\handbook\doxy-doc\html\*.*"

    ${EnableX64FSRedirection}

!macroend

!define InstallHelpFiles "!insertmacro InstallHelpFiles"

;-----------------------------------------

!macro RemoveHelpFiles

    ${DisableX64FSRedirection}

    DetailPrint "Removing documentation..."
    RMDir /r "$INSTDIR\handbook"

    ${EnableX64FSRedirection}

!macroend

!define RemoveHelpFiles "!insertmacro RemoveHelpFiles"

;-----------------------------------------

!macro InstallShellHandlerFiles

    ${DisableX64FSRedirection}

    DetailPrint "Installing the context menu handler..."
    SetOutPath "$INSTDIR"
        File "${ROOTDIR}\src\installer\shellex.ico"
        File "${ROOTDIR}\src\installer\shellex-folder.ico"

    Push $0
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5
    Push $6
    Push $7

    StrCpy $0 "$\"$SYSDIR\udefrag.exe$\" --shellex $\"%1$\""
    StrCpy $1 "$INSTDIR\shellex.ico"
    StrCpy $2 "[--- &Ultra Defragmenter ---]"
    StrCpy $3 "$\"$SYSDIR\udefrag.exe$\" --shellex --folder $\"%1$\""
    StrCpy $4 "$\"$SYSDIR\udefrag.exe$\" --shellex --folder-itself $\"%1$\""
    StrCpy $5 "$INSTDIR\shellex-folder.ico"
    StrCpy $6 "[--- &Defragment folder itself ---]"
    StrCpy $7 "[--- &Defragment root folder itself ---]"

    ${If} $AtLeastXP == "1"
        WriteRegStr HKCR "Drive\shell\udefrag"                ""     $2
        WriteRegStr HKCR "Drive\shell\udefrag"                "Icon" $1
        WriteRegStr HKCR "Drive\shell\udefrag\command"        ""     $3
        WriteRegStr HKCR "Drive\shell\udefrag-folder"         ""     $7
        WriteRegStr HKCR "Drive\shell\udefrag-folder"         "Icon" $5
        WriteRegStr HKCR "Drive\shell\udefrag-folder\command" ""     $4
    ${Else}
        DeleteRegKey HKCR "Drive\shell\udefrag"
    ${EndIf}

    WriteRegStr HKCR "Folder\shell\udefrag"                ""     $2
    WriteRegStr HKCR "Folder\shell\udefrag"                "Icon" $1
    WriteRegStr HKCR "Folder\shell\udefrag\command"        ""     $3
    WriteRegStr HKCR "Folder\shell\udefrag-folder"         ""     $6
    WriteRegStr HKCR "Folder\shell\udefrag-folder"         "Icon" $5
    WriteRegStr HKCR "Folder\shell\udefrag-folder\command" ""     $4

    WriteRegStr HKCR "*\shell\udefrag"         ""     $2
    WriteRegStr HKCR "*\shell\udefrag"         "Icon" $1
    WriteRegStr HKCR "*\shell\udefrag\command" ""     $0

    Pop $7
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0

    ${EnableX64FSRedirection}

!macroend

!define InstallShellHandlerFiles "!insertmacro InstallShellHandlerFiles"

;-----------------------------------------

!macro RemoveShellHandlerFiles

    ${DisableX64FSRedirection}

    Delete "$INSTDIR\shellex.ico"

    DetailPrint "Removing the context menu handler..."
    DeleteRegKey HKCR "Drive\shell\udefrag"
    DeleteRegKey HKCR "Drive\shell\udefrag-folder"
    DeleteRegKey HKCR "Folder\shell\udefrag"
    DeleteRegKey HKCR "Folder\shell\udefrag-folder"
    DeleteRegKey HKCR "*\shell\udefrag"

    ${EnableX64FSRedirection}

!macroend

!define RemoveShellHandlerFiles "!insertmacro RemoveShellHandlerFiles"

;-----------------------------------------

!macro InstallUsageTracking

    Push $0

    DetailPrint "Disabling usage tracking..."
    StrCpy $0 "UD_DISABLE_USAGE_TRACKING"
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" $0 "1"
    WriteRegStr HKCU "Environment" $0 "1"

    ; "Export" our change
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
    
    Pop $0

!macroend

!define InstallUsageTracking "!insertmacro InstallUsageTracking"

;-----------------------------------------

!macro RemoveUsageTracking

    Push $0

    StrCpy $0 "UD_DISABLE_USAGE_TRACKING"
    DeleteRegValue HKCU "Environment" $0
    DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" $0
    DeleteRegValue HKLM "SYSTEM\ControlSet001\Control\Session Manager\Environment" $0
    DeleteRegValue HKLM "SYSTEM\ControlSet002\Control\Session Manager\Environment" $0

    ; "Export" our change
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000
    
    Pop $0

!macroend

!define RemoveUsageTracking "!insertmacro RemoveUsageTracking"

;-----------------------------------------

!macro InstallStartMenuIcon

    ${DisableX64FSRedirection}

    DetailPrint "Installing start menu icon..."
    SetShellVarContext all
    SetOutPath $INSTDIR

    ; install a single shortcut to the Start menu,
    ; because all important information can be easily
    ; accessed from the GUI
    CreateShortCut "$SMPROGRAMS\UltraDefrag.lnk" \
        "$INSTDIR\ultradefrag.exe"

    ${EnableX64FSRedirection}

!macroend

!define InstallStartMenuIcon "!insertmacro InstallStartMenuIcon"

;-----------------------------------------

!macro RemoveStartMenuIcon

    ${DisableX64FSRedirection}

    DetailPrint "Removing start menu icon..."
    SetShellVarContext all
    Delete "$SMPROGRAMS\UltraDefrag.lnk"

    ${EnableX64FSRedirection}

!macroend

!define RemoveStartMenuIcon "!insertmacro RemoveStartMenuIcon"

;-----------------------------------------

!macro InstallDesktopIcon

    ${DisableX64FSRedirection}

    DetailPrint "Installing desktop icon..."
    SetShellVarContext all
    SetOutPath $INSTDIR
    CreateShortCut "$DESKTOP\UltraDefrag.lnk" \
        "$INSTDIR\ultradefrag.exe"

    ${EnableX64FSRedirection}

!macroend

!define InstallDesktopIcon "!insertmacro InstallDesktopIcon"

;-----------------------------------------

!macro RemoveDesktopIcon

    ${DisableX64FSRedirection}

    DetailPrint "Removing desktop icon..."
    SetShellVarContext all
    Delete "$DESKTOP\UltraDefrag.lnk"

    ${EnableX64FSRedirection}

!macroend

!define RemoveDesktopIcon "!insertmacro RemoveDesktopIcon"

;-----------------------------------------

!macro InstallQuickLaunchIcon

    ${DisableX64FSRedirection}

    DetailPrint "Installing quick launch icon..."
    SetShellVarContext all
    SetOutPath $INSTDIR
    CreateShortCut "$QUICKLAUNCH\UltraDefrag.lnk" \
        "$INSTDIR\ultradefrag.exe"

    ${EnableX64FSRedirection}

!macroend

!define InstallQuickLaunchIcon "!insertmacro InstallQuickLaunchIcon"

;-----------------------------------------

!macro RemoveQuickLaunchIcon

    ${DisableX64FSRedirection}

    DetailPrint "Removing quick launch icon..."
    SetShellVarContext all
    Delete "$QUICKLAUNCH\UltraDefrag.lnk"

    ${EnableX64FSRedirection}

!macroend

!define RemoveQuickLaunchIcon "!insertmacro RemoveQuickLaunchIcon"

;-----------------------------------------

!macro RemoveObsoleteFiles

    ; remove files of previous installations
    DeleteRegKey HKLM "SYSTEM\UltraDefrag"
    DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Control\UltraDefrag"
    DeleteRegKey HKLM "SYSTEM\ControlSet001\Control\UltraDefrag"
    DeleteRegKey HKLM "SYSTEM\ControlSet002\Control\UltraDefrag"
    DeleteRegKey HKLM "SYSTEM\ControlSet003\Control\UltraDefrag"
    SetRegView 64
    DeleteRegKey HKLM "Software\UltraDefrag"
    SetRegView 32
    DeleteRegKey HKLM "Software\UltraDefrag"

    RMDir /r "$SYSDIR\UltraDefrag"
    Delete "$SYSDIR\udefrag-gui-dbg.cmd"
    Delete "$SYSDIR\udefrag-gui.exe"
    Delete "$SYSDIR\udefrag-gui.cmd"
    Delete "$SYSDIR\ultradefrag.exe"
    Delete "$SYSDIR\udefrag-gui-config.exe"
    Delete "$SYSDIR\udefrag-scheduler.exe"
    Delete "$SYSDIR\ud-config.cmd"
    Delete "$SYSDIR\udefrag-kernel.dll"
    Delete "$SYSDIR\lua5.1a.exe"
    Delete "$SYSDIR\lua5.1a_gui.exe"
    Delete "$SYSDIR\udctxhandler.cmd"
    Delete "$SYSDIR\udctxhandler.vbs"

    RMDir /r "$INSTDIR\doc"
    RMDir /r "$INSTDIR\presets"
    RMDir /r "$INSTDIR\logs"
    RMDir /r "$INSTDIR\portable_${ULTRADFGARCH}_package"
    RMDir /r "$INSTDIR\i18n\gui"
    RMDir /r "$INSTDIR\i18n\gui-config"

    Delete "$INSTDIR\scripts\udctxhandler.lua"
    Delete "$INSTDIR\dfrg.exe"
    Delete "$INSTDIR\INSTALL.TXT"
    Delete "$INSTDIR\FAQ.TXT"
    Delete "$INSTDIR\UltraDefragScheduler.NET.exe"
    Delete "$INSTDIR\boot_on.cmd"
    Delete "$INSTDIR\boot_off.cmd"
    Delete "$INSTDIR\ud_i18n.dll"
    Delete "$INSTDIR\wgx.dll"
    Delete "$INSTDIR\lua5.1a.dll"

    Delete "$INSTDIR\udefrag-scheduler.exe"
    Delete "$INSTDIR\*.lng"
    Delete "$INSTDIR\udefrag-gui-config.exe"
    Delete "$INSTDIR\LanguageSelector.exe"

    ; remove shortcuts of any previous version of the program
    SetShellVarContext all
    RMDir /r "$SMPROGRAMS\DASoft"
    RMDir /r "$SMPROGRAMS\UltraDefrag"

    Delete "$SYSDIR\Drivers\ultradfg.sys"
    DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Services\ultradfg"
    DeleteRegKey HKLM "SYSTEM\ControlSet001\Services\ultradfg"
    DeleteRegKey HKLM "SYSTEM\ControlSet002\Services\ultradfg"
    DeleteRegKey HKLM "SYSTEM\ControlSet003\Services\ultradfg"
    DeleteRegKey HKLM "SYSTEM\CurrentControlSet\Enum\Root\LEGACY_ULTRADFG"
    DeleteRegKey HKLM "SYSTEM\ControlSet001\Enum\Root\LEGACY_ULTRADFG"
    DeleteRegKey HKLM "SYSTEM\ControlSet002\Enum\Root\LEGACY_ULTRADFG"
    DeleteRegKey HKLM "SYSTEM\ControlSet003\Enum\Root\LEGACY_ULTRADFG"

!macroend

!define RemoveObsoleteFiles "!insertmacro RemoveObsoleteFiles"

;-----------------------------------------

!macro WriteTheUninstaller

    ${DisableX64FSRedirection}

    DetailPrint "Creating the uninstall information..."
    SetOutPath "$INSTDIR"

    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "DisplayName"     "Ultra Defragmenter"
    !ifdef RELEASE_STAGE
        WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "DisplayVersion"  "${ULTRADFGVER} ${RELEASE_STAGE}"
    !else
        WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "DisplayVersion"  "${ULTRADFGVER}"
    !endif
    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "Publisher"       "UltraDefrag Development Team"
    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "URLInfoAbout"    "http://ultradefrag.sourceforge.net/"
    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "DisplayIcon"     "$INSTDIR\uninstall.exe"
    WriteRegStr   HKLM ${UD_UNINSTALL_REG_KEY} "InstallLocation" "$INSTDIR"
    WriteRegDWORD HKLM ${UD_UNINSTALL_REG_KEY} "NoModify" 1
    WriteRegDWORD HKLM ${UD_UNINSTALL_REG_KEY} "NoRepair" 1

    WriteUninstaller "uninstall.exe"

    ${EnableX64FSRedirection}

!macroend

!define WriteTheUninstaller "!insertmacro WriteTheUninstaller"

;-----------------------------------------

!macro UpdateUninstallSizeValue

    push $R0
    push $0
    push $1
    push $2

    ${DisableX64FSRedirection}

    ; update the uninstall size value
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM ${UD_UNINSTALL_REG_KEY} "EstimatedSize" "$0"

    ${EnableX64FSRedirection}

    pop $2
    pop $1
    pop $0
    pop $R0

!macroend

!define UpdateUninstallSizeValue "!insertmacro UpdateUninstallSizeValue"

;-----------------------------------------

!endif /* _ULTRA_DEFRAG_NSH_ */
