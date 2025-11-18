@echo off
REM ============================================================================
REM             	  Icon Wizard by ridwan47
REM ============================================================================
REM SETTINGS:
REM   - Set ExeMode to 0 for this script to install ITSELF. (Default Standalone)
REM   - Set ExeMode to 1 for this script to act as an installer for the
REM     'IconWizard.bat' located in the 'resources' sub-folder.
REM ============================================================================
set "ExeMode=0"
REM ============================================================================

setlocal enabledelayedexpansion

REM Enable UTF-8 support for special characters
chcp 65001 >nul 2>nul

REM ============================================================================
REM User Configuration
REM ============================================================================
REM Installation paths
set "INSTALL_DIR=%ProgramFiles%\Icon Wizard"
set "INSTALL_RESOURCES=%INSTALL_DIR%\Resources"
set "SCRIPT_VERSION=4.7.6"

REM Check if we're running from Program Files (installed mode)
set "isInstalled=0"
echo "%~dp0" | findstr /I /C:"Icon Wizard" >nul
if not errorlevel 1 (
    set "isInstalled=1"
)

REM Set resource path based on installation status
if "%isInstalled%"=="1" (
    REM Running from installed location - resources are in Resources subfolder
    set "resourcesPath=%~dp0Resources\"
) else (
    REM Running from portable location - resources are in resources subfolder
    set "resourcesPath=%~dp0resources\"
)

REM --- Icon Changer Dependencies ---
set "IconUpdaterPath=%resourcesPath%FolderIconUpdater.exe"

REM --- Context Menu Icon Configuration ---
set "ContextMenuIconPath=%resourcesPath%icon.ico"

REM --- Configuration File (optional) ---
set "configFile=%~dp0config.ini"
REM ============================================================================

REM --- DEBUG FILE SETUP in TEMP Directory ---
set "debugLogFile=%TEMP%\_folder_icon_debug.log"
del "%debugLogFile%" 2>nul
call :DebugLog "======== SCRIPT SESSION STARTED v%SCRIPT_VERSION% (ExeMode=%ExeMode%) ========"

REM --- Validate Critical Resources ---
call :ValidateResources

REM ----------------------------------------------------------------------------
REM Configuration: Files and Resources
REM ----------------------------------------------------------------------------
set "skipFiles=7z,CRC,SFV,dxweb,cheat,protect,launch,crash,patch,redist,language,QtWeb,mod,version,overlay,error,dump,node.exe,handler,lumaplay,createdump"

REM ----------------------------------------------------------------------------
REM [PRIMARY METHOD] Check for a folder/file being passed to the script
REM ----------------------------------------------------------------------------
call :DebugLog "Script started with parameter: '%~1'"

if not "%~1"=="" (
    REM Check for context menu installation parameters first
    if /i "%~1"=="--install-context" ( 
        call :DebugLog "Installation parameter detected: --install-context"
        goto :InstallContextMenu 
    )
    if /i "%~1"=="--uninstall-context" ( 
        call :DebugLog "Installation parameter detected: --uninstall-context"
        goto :UninstallContextMenu 
    )
    
    call :DebugLog "Checking if parameter is a folder or file..."
    
    REM Check if it's a folder
    if exist "%~1\" (
        call :DebugLog "Parameter is a FOLDER: %~1"
        call :OfferFolderActions "%~f1"
        call :FolderOperationCompleteMenu "%~f1"
        goto :ExitScript
    ) else if exist "%~1" (
        call :DebugLog "Parameter is a FILE: %~1"
        REM It's a file - check if it's a supported image/icon/exe file
        set "fileExt=%~x1"
        call :DebugLog "File extension detected: !fileExt!"
        
        if /i "!fileExt!"==".png" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".jpg" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".jpeg" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".bmp" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".gif" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".svg" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".ico" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".exe" ( goto :HandleFileConversion )
        if /i "!fileExt!"==".webp" ( goto :HandleFileConversion )
        
        call :DebugLog "File type NOT SUPPORTED: !fileExt!"
        echo The file you dropped is not a supported format.
        echo Supported formats: PNG, JPG, BMP, GIF, SVG, ICO, EXE, WebP
        pause
        goto :eof
    ) else (
        call :DebugLog "ERROR: Parameter is neither a valid folder nor file: %~1"
        echo The item you dropped onto the script is not valid.
        pause
        goto :eof
    )
) else (
    call :DebugLog "No parameter passed - showing main menu"
)

:MainMenu
call :DebugLog "Main Menu displayed."
cls
echo.
echo  ========================================================================
echo                       Icon Wizard v%SCRIPT_VERSION%
echo  ========================================================================
echo.
echo  TIP: Drag a folder onto the .bat file for quick single-folder operation
echo  DEBUG LOG: %temp%\_folder_icon_debug.log
echo.
echo  ========================================================================
echo                          OPERATION MODES
echo  ========================================================================
echo.
echo    --- FOLDER ICON CHANGER ---
echo    [1]  Browse for a folder
echo    [2]  Paste folder path manually
echo    [3]  Scan all subfolders in current directory
echo.
echo    --- IMAGE CONVERTER ---
echo    [4]  Icon Conversion Tools
echo.
echo  ------------------------------------------------------------------------
echo.
echo                    CONTEXT MENU INTEGRATION
echo.
echo    [I]  Install Context Menu     (Press I to Install)
echo    [U]  Uninstall Context Menu   (Press U to Uninstall)
echo.
echo  ------------------------------------------------------------------------
echo.
echo    [E]  Exit
echo.
echo  ========================================================================
echo.

choice /C:1234IUE /N /M "  Select your choice: "

if errorlevel 7 (
    call :DebugLog "Main Menu Choice: E (Exit)"
    call :Cleanup
    exit /b
)
if errorlevel 6 ( call :DebugLog "Main Menu Choice: U (Uninstall)" & goto :UninstallContextMenu )
if errorlevel 5 ( call :DebugLog "Main Menu Choice: I (Install)" & goto :InstallContextMenu )
if errorlevel 4 ( call :DebugLog "Main Menu Choice: 4" & goto :ImageConverterMainMenu )
if errorlevel 3 ( call :DebugLog "Main Menu Choice: 3" & goto :ProcessAllSubfolders )
if errorlevel 2 ( call :DebugLog "Main Menu Choice: 2" & goto :ManualFolderInput )
if errorlevel 1 ( call :DebugLog "Main Menu Choice: 1" & goto :BrowseForSingleFolder )
goto :MainMenu

:BrowseForSingleFolder
call :DebugLog "Option 1: Browse for single folder selected."
echo.
echo ...Opening folder browser...

REM Escape current directory for PowerShell
set "currentDir=%CD%"
call :EscapeForPowerShell "%currentDir%" escapedDir

set "psCommand=Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.OpenFileDialog; $f.Title='Select a folder by navigating into it and clicking Open'; $f.ValidateNames=$false; $f.CheckFileExists=$false; $f.CheckPathExists=$true; $f.InitialDirectory='!escapedDir!'; $f.FileName='Select This Folder'; if($f.ShowDialog() -eq 'OK'){ [System.IO.Path]::GetDirectoryName($f.FileName) }"

set "selectedFolder="
for /f "usebackq delims=" %%F in (`powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "!psCommand!"`) do (
    set "selectedFolder=%%F"
)

if defined selectedFolder (
    call :OfferFolderActions "!selectedFolder!"
    call :FolderOperationCompleteMenu "!selectedFolder!"
) else (
    call :DebugLog "Folder browse dialog cancelled."
    echo ...No folder selected.
    pause
)
goto :MainMenu

:ProcessAllSubfolders
    call :DebugLog "Option 3: Scan all subfolders selected."
    echo.
    set "returnToMenu="
    set "folderCount=0"
    
    REM Count folders first
    for /D %%I in (*) do set /a folderCount+=1
    
    if !folderCount! equ 0 (
        echo No subfolders found in current directory.
        pause
        goto :MainMenu
    )
    
    echo Found !folderCount! subfolder(s) to process.
    echo.
    
    set "processedCount=0"
    for /D %%I in (*) do (
        set /a processedCount+=1
        echo Processing [!processedCount!/!folderCount!]: %%~nxI
        call :DebugLog "Processing subfolder: %%~fI"
        call :OfferFolderActions "%%~fI"
        if defined returnToMenu goto :SubfolderLoopEnd
        echo.
    )
    :SubfolderLoopEnd
    cls
    echo.
    echo ======================================================
    echo  Subfolder scan complete. Returning to main menu.
    echo ======================================================
    echo.
    pause
    goto :MainMenu

:ManualFolderInput
call :DebugLog "Option 2: Manual path input selected."
cls
echo ======================================================
echo  Manual Folder Path Entry
echo ======================================================
echo.
echo IMPORTANT: Pasting a path works perfectly. Dragging
echo a path into this window may crash the script.
echo This is a bug in Windows, not the script.
echo.
setlocal enabledelayedexpansion
set /p "manualPath=Paste folder path and press Enter: "
call :DebugLog "Manual folder path input received"

if not defined manualPath (
    call :DebugLog "Manual path input was empty."
    echo ...No path entered.
    pause
    endlocal
    goto :MainMenu
)

REM Remove all quotes
set "cleanPath=!manualPath!"
set cleanPath=!cleanPath:"=!

REM Trim any leading/trailing spaces
for /f "tokens=* delims= " %%a in ("!cleanPath!") do set "cleanPath=%%a"

call :DebugLog "Manual path cleaned"

if exist "!cleanPath!\" (
    call :OfferFolderActions "!cleanPath!"
    call :FolderOperationCompleteMenu "!cleanPath!"
) else (
    call :DebugLog "Manual path was not a valid folder"
    echo.
    echo ...ERROR: The path "!cleanPath!" is not a valid folder.
    pause
)
endlocal
goto :MainMenu

:ExitScript
call :Cleanup
call :DebugLog "======== SCRIPT SESSION FINISHED (Normal Exit) ========"
echo ======================================================
echo Script finished.
echo ======================================================
pause
goto :eof

:HandleFileConversion
    call :DebugLog "File dropped/context menu used. Routing to image converter."
    set "argPath=%~f1"
    call :ImageConverterFileMenu
    goto :EndExecutionMenu
    
:OfferFolderActions
    setlocal
    set "folderPath=%~f1"
    cls
    echo A folder has been selected.
    echo ======================================================
    echo FOLDER: %folderPath%
    echo ======================================================
    echo.
    echo What would you like to do?
    echo.
    echo   1. Browse for an external icon (Windows Browse GUI)
    echo   2. Drag ^& Drop Icon File / Paste icon path manually
    echo   3. Process this folder (find icons inside the folder)
    echo ===============================================
    echo   0. Skip Folder
    echo   M. Main Menu
    echo   E. Exit
    echo.
    choice /C:1230ME /N /M "Select an option: "

    if errorlevel 6 ( call :Cleanup & exit /b )
    if errorlevel 5 (
        call :DebugLog "Action Choice: M (Main Menu)"
        endlocal
        set "returnToMenu=true"
        goto :MainMenu
    )
    if errorlevel 4 (
        call :DebugLog "Action Choice: 0 (Skip folder)"
        echo ...Skipping folder.
        endlocal
        goto :eof
    )
    if errorlevel 3 (
        call :DebugLog "Action Choice: 3 (Process folder)"
        endlocal & call :ProcessFolder "%folderPath%"
        goto :eof
    )
    if errorlevel 2 (
        call :DebugLog "Action Choice: 2 (Manual icon path)"
        endlocal & call :ManualIconInput "%folderPath%"
        goto :eof
    )
    if errorlevel 1 (
        call :DebugLog "Action Choice: 1 (Browse for external icon)"
        endlocal & call :BrowseForExternalIcon "%folderPath%"
        goto :eof
    )
goto :eof

:ProcessFolder
    setlocal disabledelayedexpansion
    set "targetFolder=%~f1"
    call :DebugLog "--- Begin Processing Folder: %targetFolder% ---"
    
    set "tempFile=%TEMP%\foldericon_%RANDOM%.txt"
    set "icoTempFile=%TEMP%\foldericon_ico_%RANDOM%.txt"
    set "exeTempFile=%TEMP%\foldericon_exe_%RANDOM%.txt"
    if exist "%tempFile%" del "%tempFile%"
    if exist "%icoTempFile%" del "%icoTempFile%"
    if exist "%exeTempFile%" del "%exeTempFile%"

    echo ...Scanning for suitable files, please wait...
    
    for /f "delims=" %%J in ('dir /s /b /a-d "%targetFolder%\*.ico" 2^>nul') do (
        set "skipFlag="
        for %%S in (%skipFiles%) do (echo "%%~nxJ" | findstr /i /L "%%S" >nul 2>nul && set "skipFlag=1")
        if not defined skipFlag ((echo %%J^|%%~nxJ^|%%~dpJ)>>"%icoTempFile%")
    )
    for /f "delims=" %%J in ('dir /s /b /a-d "%targetFolder%\*.exe" 2^>nul') do (
        set "skipFlag="
        for %%S in (%skipFiles%) do (echo "%%~nxJ" | findstr /i /L "%%S" >nul 2>nul && set "skipFlag=1")
        if not defined skipFlag ((echo %%J^|%%~nxJ^|%%~dpJ)>>"%exeTempFile%")
    )

    if exist "%icoTempFile%" type "%icoTempFile%" >> "%tempFile%"
    if exist "%exeTempFile%" type "%exeTempFile%" >> "%tempFile%"

    set "icoCount=0"
    set "totalCount=0"
    if exist "%icoTempFile%" ( for /f "usebackq" %%L in ("%icoTempFile%") do set /a icoCount+=1 )
    if exist "%tempFile%" ( for /f "usebackq" %%L in ("%tempFile%") do set /a totalCount+=1 )
    call :DebugLog "Found %totalCount% suitable files (%icoCount% ICOs)."
    
    if %totalCount% equ 0 (
        echo ...No suitable .ico or .exe files found.
        call :PromptUserChoice "%targetFolder%" "%tempFile%" 0 0
    ) else if %totalCount% equ 1 (
        for /f "usebackq tokens=1,2 delims=|" %%A in ("%tempFile%") do (
            echo ...One suitable file found, auto-selecting: %%B
            call :DebugLog "Auto-selecting single file: %%B"
            call :SetFolderIcon "%targetFolder%" "%%A"
        )
    ) else (
        call :PromptUserChoice "%targetFolder%" "%tempFile%" %totalCount% %icoCount%
    )
    
    if exist "%tempFile%" del "%tempFile%"
    if exist "%icoTempFile%" del "%icoTempFile%"
    if exist "%exeTempFile%" del "%exeTempFile%"
    call :DebugLog "--- End Processing Folder: %targetFolder% ---"
    endlocal
goto :eof

:PromptUserChoice
    setlocal disabledelayedexpansion
    set "targetFolder=%~f1"
    set "tempFileArg=%~2"
    set "totalCountArg=%~3"
    set "icoCountArg=%~4"
    
    REM Store basePath before enabling delayed expansion
    set "basePath=%targetFolder%\"
    
    echo.
    if %totalCountArg% gtr 0 (
        echo Multiple suitable files found. Please choose one:
    ) else (
        echo No local files found. You can browse for an icon.
    )
    echo.
    echo   0. [Skip this folder]
    if %totalCountArg% gtr 0 (
        set "displayNum=0"
        set "headerPrinted="
        setlocal enabledelayedexpansion
        
        if %icoCountArg% gtr 0 echo. & echo   --- ICO Files ---
        
        for /f "usebackq tokens=2,3 delims=|" %%F in ("!tempFileArg!") do (
            set /a displayNum+=1
            if !displayNum! gtr %icoCountArg% if not defined headerPrinted (
                echo. & echo   --- EXE Files ---
                set "headerPrinted=1"
            )

            set "fileName=%%F"
            set "parentDir=%%G"
            
            REM Compare paths to determine location display
            if /i "!parentDir!"=="!basePath!" (
                set "location=root"
            ) else (
                REM Use temporary variable for substring replacement
                set "location=!parentDir!"
                for %%B in ("!basePath!") do set "location=!location:%%~B=!"
                
                REM Clean up leading backslash if present
                if "!location:~0,1!"=="\" set "location=!location:~1!"
                
                REM Add leading backslash for display
                if not "!location!"=="" set "location=\!location!"
            )

            set "paddedName=!fileName!                                        "
            set "paddedName=!paddedName:~0,35!"

            echo   !displayNum!. !paddedName! --- (!location!)
        )
        endlocal
    )
    echo. & echo   B. [Browse for another .ico file]
    echo   M. [Return to Main Menu]
    echo   E. [Exit]
    echo.
    
    if %totalCountArg% gtr 9 goto :PromptUserChoice_Legacy

    setlocal enabledelayedexpansion
    set "choiceChars=0BME"
    for /L %%N in (1,1,%totalCountArg%) do set "choiceChars=!choiceChars!%%N"
    
    echo Press a key to make your choice (no Enter needed)...
    choice /C:!choiceChars! /N

    set "choiceErrorLevel=%errorlevel%"
    endlocal & set choiceErrorLevel=%choiceErrorLevel%

    if %choiceErrorLevel% equ 1 (
        echo ...Skipping.
        call :DebugLog "User chose to skip."
        endlocal
        goto :eof
    )
    if %choiceErrorLevel% equ 2 (
        call :DebugLog "User chose to browse for external icon."
        endlocal & call :BrowseForExternalIcon "%targetFolder%"
        goto :eof
    )
    if %choiceErrorLevel% equ 3 (
        call :DebugLog "User chose M for Main Menu."
        endlocal
        set "returnToMenu=true"
        goto :MainMenu
    )
    if %choiceErrorLevel% equ 4 ( call :Cleanup & exit /b )
    
    set /a "selectedChoice = choiceErrorLevel - 4"
    call :FindSelectionByNumber "%targetFolder%" "%tempFileArg%" %selectedChoice%
    endlocal
goto :eof

:PromptUserChoice_Legacy
    set /p "userChoice=Type your choice (0-%totalCountArg%, B, M, or E) and press Enter: "
    call :DebugLog "Legacy prompt input received"

    if /i "%userChoice%"=="e" ( call :Cleanup & exit /b )
    if /i "%userChoice%"=="m" (
        call :DebugLog "User chose M for Main Menu."
        endlocal
        set "returnToMenu=true"
        goto :MainMenu
    )
    if /i "%userChoice%"=="b" (
        call :DebugLog "User chose to browse for external icon."
        call :BrowseForExternalIcon "%targetFolder%"
        endlocal
        goto :eof
    )
    set /a "selectedChoice=-1" & set /a "selectedChoice=%userChoice%" 2>nul
    
    if %selectedChoice% lss 1 (
        if %selectedChoice% equ 0 ( echo ...Skipping. & call :DebugLog "User chose to skip." ) else ( echo ...Invalid choice. )
        endlocal
        goto :eof
    )
    if %selectedChoice% gtr %totalCountArg% (
        echo ...Invalid choice.
        endlocal
        goto :eof
    )
    call :FindSelectionByNumber "%targetFolder%" "%tempFileArg%" %selectedChoice%
    endlocal
goto :eof

:FindSelectionByNumber
    setlocal
    set "targetFolder=%~1"
    set "tempFileArg=%~2"
    set "selectedChoice=%~3"
    call :DebugLog "User selected item #%selectedChoice% from the list."
    set "foundPath="

    REM --- OPTIMIZED: Use findstr to get the Nth line directly ---
    for /f "tokens=1* delims=:" %%A in ('findstr /N "^" "%tempFileArg%"') do (
        if %%A equ %selectedChoice% (
            for /f "tokens=1 delims=|" %%C in ("%%B") do (
                set "foundPath=%%C"
                goto :SelectionFound
            )
        )
    )

:SelectionFound
    if defined foundPath (
        call :DebugLog "Matched item #%selectedChoice% to path: %foundPath%"
        echo.
        for %%F in ("%foundPath%") do echo ...You selected: %%~nxF
        endlocal & call :SetFolderIcon "%targetFolder%" "%foundPath%"
    ) else (
        endlocal
    )
goto :eof

:BrowseForExternalIcon
    set "browseTarget=%~f1"
    echo.
    echo ...Opening file browser...
    
    REM Escape current directory for PowerShell
    set "currentDir=%CD%"
    call :EscapeForPowerShell "%currentDir%" escapedDir
    
    set "psCommand=Add-Type -AssemblyName System.windows.forms; $f=New-Object System.Windows.Forms.OpenFileDialog; $f.InitialDirectory='!escapedDir!'; $f.Filter='Icon Files (*.ico)|*.ico|All Files (*.*)|*.*'; $f.Title='Select an Icon File'; [void]$f.ShowDialog(); if ($f.FileName -ne '') { $f.FileName }"
    
    set "selectedFile="
    for /f "usebackq delims=" %%F in (`powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "!psCommand!"`) do (
        set "selectedFile=%%F"
    )

    if defined selectedFile (
        call :DebugLog "User browsed and selected external file: %selectedFile%"
        echo ...You selected: %selectedFile%
        call :SetFolderIcon "%browseTarget%" "%selectedFile%"
    ) else (
        call :DebugLog "User cancelled the browse dialog."
        echo ...No file selected.
    )
goto :eof

:ManualIconInput
    setlocal enabledelayedexpansion
    set "targetFolder=%~f1"
    for %%F in ("%targetFolder%") do set "folderName=%%~nxF"
    cls
    echo ======================================================
    echo  Manual Icon Path Entry ^>^> !folderName!
    echo ======================================================
    echo.
    echo IMPORTANT: Pasting a path works perfectly. Dragging
    echo a path into this window may crash the script.
    echo This is a bug in Windows, not the script.
    echo.
    set /p "iconPath=Paste icon path (.ico or .exe) and press Enter: "
    
    if not defined iconPath (
        call :DebugLog "Manual icon path input was empty."
        echo ...No path entered.
        endlocal
        goto :eof
    )
    
    REM Remove surrounding quotes if present - use set with quotes
    set "cleanPath=!iconPath!"
    set cleanPath=!cleanPath:"=!
    
    REM Trim any leading/trailing spaces
    for /f "tokens=* delims= " %%a in ("!cleanPath!") do set "cleanPath=%%a"
    
    call :DebugLog "Manual icon path received"
    call :DebugLog "Cleaned path: !cleanPath!"

    if not exist "!cleanPath!" (
        call :DebugLog "Manual icon path does not exist"
        echo ...ERROR: The file path you entered does not exist.
        echo ...Path attempted: !cleanPath!
        pause
        endlocal
        goto :eof
    )

    for %%F in ("!cleanPath!") do set "ext=%%~xF"
    if /i not "!ext!"==".ico" if /i not "!ext!"==".exe" (
        call :DebugLog "Manual icon path is not a valid file type"
        echo ...ERROR: The file must be an .ico or .exe.
        echo ...Extension detected: !ext!
        pause
        endlocal
        goto :eof
    )
    
    set "finalCleanPath=!cleanPath!"
    endlocal & call :SetFolderIcon "%targetFolder%" "%finalCleanPath%"
goto :eof

:SetFolderIcon
    setlocal disabledelayedexpansion
    set "targetFolder=%~f1"
    set "fullPath=%~f2"
    
    setlocal enabledelayedexpansion
    
    for %%F in ("!fullPath!") do (
        set "fileName=%%~nxF"
        set "fileExt=%%~xF"
    )
    
    call :DebugLog "SetFolderIcon: Target Folder is '!targetFolder!'"
    call :DebugLog "SetFolderIcon: Full Icon Path is '!fullPath!'"
    
    echo ...Processing icon for "!fileName!"
    set "iconPath="
    
    pushd "!targetFolder!" || (call :DebugLog "FATAL ERROR: Could not pushd to target folder."& echo ...ERROR: Access denied.& endlocal & endlocal & goto :eof)

    REM --- Use GOTO for robust conditional logic ---
    if /i "!fileExt!"==".exe" goto :SetIcon_ProcessExe
    if /i "!fileExt!"==".ico" goto :SetIcon_ProcessIco
    goto :SetIcon_ProcessOther

:SetIcon_ProcessExe
    call :DebugLog "File is an EXE. Using full absolute path."
    set "iconPath=!fullPath!"
    goto :SetIcon_EndProcessing

:SetIcon_ProcessIco
    for %%N in ("!fileName!") do (
        set "baseName=%%~nN"
        set "ext=%%~xN"
    )
    set "finalName=icon_!baseName!!ext!"
    call :DebugLog "ICO selected. Base proposed name is '!finalName!'."
    
    if exist "!finalName!" (
        set "counter=2"
        :NameCheckLoop
        set "finalName=icon_!baseName!_!counter!!ext!"
        if exist "!finalName!" (
            set /a counter+=1
            goto :NameCheckLoop
        )
    )
    call :DebugLog "Conflict check passed. Final name will be '!finalName!'."
    
    REM --- Try to copy first without modifying attributes ---
    call :DebugLog "Attempting to copy '!fullPath!' to '!finalName!'."
    copy /Y "!fullPath!" "!finalName!" >nul 2>nul

    if not errorlevel 1 (
        echo ...Icon file copied to '!finalName!'.
        set "iconPath=!finalName!"
        call :DebugLog "Copy succeeded without attribute modification."
    ) else (
        call :DebugLog "Initial copy failed. Checking file attributes..."
        
        REM --- Save original attributes ---
        set "originalAttribs="
        for /f "tokens=*" %%A in ('attrib "!fullPath!"') do set "originalAttribs=%%A"
        call :DebugLog "Original attributes: !originalAttribs!"
        
        REM --- Remove restrictive attributes and try again ---
        call :DebugLog "Removing attributes to attempt copy..."
        attrib -s -h -a -r "!fullPath!" >nul 2>nul
        
        copy /Y "!fullPath!" "!finalName!" >nul 2>nul
        
        if not errorlevel 1 (
            echo ...Icon file copied to '!finalName!'.
            set "iconPath=!finalName!"
            call :DebugLog "Copy succeeded after removing attributes."
        ) else (
            call :DebugLog "Copy still failed. Using full absolute path as fallback."
            echo ...Warning: Could not copy icon into folder. Using original path.
            set "iconPath=!fullPath!"
        )
        
        REM --- Restore original attributes - System (S) must be last ---
        if defined originalAttribs (
            call :DebugLog "Preparing to restore original attributes..."
            set "attribFlags="
            
            REM Process R, A, H first, then S last (System attribute must be applied last)
            for %%A in (R A H) do (
                echo "!originalAttribs!" | findstr "%%A" >nul 2>nul
                if not errorlevel 1 set "attribFlags=!attribFlags! +%%A"
            )
            
            REM Check for System attribute separately to apply it last
            set "hasSystem="
            echo "!originalAttribs!" | findstr "S" >nul 2>nul
            if not errorlevel 1 set "hasSystem=1"

            if defined attribFlags (
                call :DebugLog "Applying attrib command with flags:!attribFlags!"
                REM The leading space in attribFlags is intentional and required
                attrib!attribFlags! "!fullPath!" >nul 2>nul
            )
            
            REM Apply System attribute last if it was present
            if defined hasSystem (
                call :DebugLog "Applying System attribute last..."
                attrib +s "!fullPath!" >nul 2>nul
            )
            
            REM --- Verification Step ---
            set "finalAttribs="
            for /f "tokens=*" %%Z in ('attrib "!fullPath!"') do set "finalAttribs=%%Z"
            call :DebugLog "Verification - Final attributes are: !finalAttribs!"
        )
    )
    goto :SetIcon_EndProcessing

:SetIcon_ProcessOther
    call :DebugLog "WARNING: Unexpected file extension '!fileExt!'. Using full path."
    set "iconPath=!fullPath!"
    goto :SetIcon_EndProcessing

:SetIcon_EndProcessing
    REM --- Use FolderIconUpdater.exe to set icon with instant refresh ---
    call :DebugLog "Using FolderIconUpdater.exe with icon path: '!iconPath!'"
    
    if exist "%IconUpdaterPath%" (
        "%IconUpdaterPath%" /f "!targetFolder!" /i "!iconPath!" /a +H+S >nul 2>nul
        
        if errorlevel 1 (
            call :DebugLog "FolderIconUpdater.exe reported an error. Falling back to manual method."
            echo ...Warning: Icon updater reported an issue. Using fallback method...
            call :ManualDesktopIniMethod "!targetFolder!" "!iconPath!"
        )
    ) else (
        call :DebugLog "FolderIconUpdater.exe not found. Using manual method."
        call :ManualDesktopIniMethod "!targetFolder!" "!iconPath!"
    )

    REM --- Hide the copied/renamed icon file so the folder stays clean ---
    if defined iconPath if /i not "!iconPath!"=="!fullPath!" (
        call :DebugLog "Setting attributes (+s +h -a) on local icon file (!iconPath!)."
        attrib +s +h -a "!iconPath!" >nul 2>nul
    )

    popd
    echo ...Folder icon set successfully.
    endlocal
    endlocal
goto :eof

:ManualDesktopIniMethod
    REM Helper function for manual desktop.ini creation
    setlocal
    set "folder=%~1"
    set "icon=%~2"
    
    pushd "%folder%"
    if exist "desktop.ini" (attrib -s -h -r "desktop.ini" 2>nul & del "desktop.ini" 2>nul)
    
    call :DebugLog "Writing to desktop.ini manually..."
    (
        echo [.ShellClassInfo]
        echo IconResource=%icon%,0
    ) > "desktop.ini"

    call :DebugLog "Setting desktop.ini attributes (+s +h -a)."
    attrib +s +h -a "desktop.ini" >nul 2>nul
    
    REM Set folder as system folder
    attrib +s "%folder%" >nul 2>nul
    
    popd
    endlocal
goto :eof

REM ============================================================================
REM ============================================================================
REM ==                START OF IMAGE CONVERTER PRO SECTION                    ==
REM ============================================================================
REM ============================================================================

:ImageConverterFileMenu
:: --- Direct file conversion menu when file is passed via context menu or drag-drop ---
call :DebugLog "ImageConverterFileMenu: Entry point reached"
call :DebugLog "ImageConverterFileMenu: argPath = '%argPath%'"

SET "MAGICK_EXE=%resourcesPath%magick.exe"
IF NOT EXIST "%MAGICK_EXE%" (
    call :DebugLog "FATAL ERROR: ImageMagick not found at: %MAGICK_EXE%"
    CLS
    ECHO.
    ECHO   -------------------------------------------------------------
    ECHO    [FATAL ERROR] ImageMagick Not Found!
    ECHO   -------------------------------------------------------------
    ECHO.
    ECHO   This function requires ImageMagick to function.
    ECHO   Please ensure 'magick.exe' is in the resources folder.
    ECHO.
    ECHO   Expected Location:
    ECHO   %MAGICK_EXE%
    ECHO.
    PAUSE
    GOTO :eof
)

call :DebugLog "ImageMagick found at: %MAGICK_EXE%"

REM Detect file type for smart menu display
set "fileExt="
FOR %%F IN ("%argPath%") DO set "fileExt=%%~xF"
call :DebugLog "Detected file extension: %fileExt%"

set "isImage=0"
set "isIcon=0"
set "isExe=0"

if /i "%fileExt%"==".png" set "isImage=1"
if /i "%fileExt%"==".jpg" set "isImage=1"
if /i "%fileExt%"==".jpeg" set "isImage=1"
if /i "%fileExt%"==".bmp" set "isImage=1"
if /i "%fileExt%"==".gif" set "isImage=1"
if /i "%fileExt%"==".svg" set "isImage=1"
if /i "%fileExt%"==".webp" set "isImage=1"
if /i "%fileExt%"==".ico" set "isIcon=1"
if /i "%fileExt%"==".exe" set "isExe=1"

call :DebugLog "File type flags: isImage=%isImage%, isIcon=%isIcon%, isExe=%isExe%"

CLS
ECHO.
ECHO   ========================================================================
ECHO                              File Detected
ECHO   ========================================================================
ECHO.
FOR %%F IN ("%argPath%") DO ECHO   File: "%%~nxF"
FOR %%F IN ("%argPath%") DO ECHO   Path: "%%~dpF"
ECHO.
ECHO   Choose an action to perform on this file:
ECHO.

REM ============================================================================
REM ==                *** UNIFIED MENU LOGIC (REPAIRED v3) ***                ==
REM ============================================================================
set "optionCount=0"

REM --- For regular images (PNG, JPG, etc.) ---
if "%isImage%"=="1" if "%isIcon%"=="0" (
    set /a optionCount+=1 & set "option!optionCount!=Convert_ICO" & ECHO     [!optionCount!] Convert to ICO (Standard^)
    set /a optionCount+=1 & set "option!optionCount!=Convert_ICO_Rounded" & ECHO     [!optionCount!] Convert to ICO (Rounded Corners^)
)
REM --- For ICO files ---
if "%isIcon%"=="1" (
    set /a optionCount+=1 & set "option!optionCount!=Convert_ICO_Standard_Reprocess" & ECHO     [!optionCount!] Re-process to Standard ICO
    set /a optionCount+=1 & set "option!optionCount!=Convert_ICO_Rounded" & ECHO     [!optionCount!] Re-process to Rounded ICO
    set /a optionCount+=1 & set "option!optionCount!=Convert_PNG_Single" & ECHO     [!optionCount!] Convert ICO to PNG (Highest Res^)
    set /a optionCount+=1 & set "option!optionCount!=Convert_PNG_AllSizes" & ECHO     [!optionCount!] Convert ICO to all PNGs
)
REM --- For EXE files ---
if "%isExe%"=="1" (
    set /a optionCount+=1 & set "option!optionCount!=Convert_EXE_to_ICO" & ECHO     [!optionCount!] Extract Icon from EXE
)

REM --- For ANY image file (including icons) ---
set "isAnyImage=0"
if "%isImage%"=="1" set "isAnyImage=1"
if "%isIcon%"=="1" set "isAnyImage=1"
if "%isAnyImage%"=="1" (
    ECHO.
    ECHO   ------------------------------------------------------------------------
    ECHO     [P] Convert Image to PNG
    ECHO     [J] Convert Image to JPG
    ECHO     [W] Convert Image to Webp
    ECHO   ------------------------------------------------------------------------
)
call :DebugLog "Final numeric option count: %optionCount%"

REM --- Auto-proceed if only one action is available ---
if "%optionCount%"=="1" if "%isAnyImage%"=="0" (
    ECHO. & ECHO   Only one action available, auto-proceeding... & timeout /t 1 /nobreak >nul
    call :DebugLog "Auto-executing single option: !option1!"
    CALL :!option1! "%argPath%"
    GOTO :EndExecution
)

ECHO.
ECHO   ========================================================================
ECHO     [M] Return to Main Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.

if "%optionCount%"=="0" if "%isAnyImage%"=="0" (
    call :DebugLog "ERROR: No menu options available for this file type!"
    ECHO   [ERROR] Unable to determine valid operations for this file.
    PAUSE
    GOTO :eof
)

REM Build choice string dynamically IN ORDER of appearance
set "choiceStr="
for /L %%N in (1,1,%optionCount%) do set "choiceStr=!choiceStr!%%N"
if "%isAnyImage%"=="1" set "choiceStr=!choiceStr!PJW"
set "choiceStr=!choiceStr!ME"
call :DebugLog "Choice string: !choiceStr!"

CHOICE /C !choiceStr! /N /M "Enter your choice: "
set "userChoiceLvl=%errorlevel%"
call :DebugLog "User selected choice errorlevel: %userChoiceLvl%"

REM --- This is the reliable way to handle CHOICE errorlevels ---
set /a "currentLvl=0"

REM --- Check numeric options ---
for /L %%N in (1,1,%optionCount%) do (
    set /a currentLvl+=1
    if %userChoiceLvl% equ !currentLvl! (
        set "actionToRun=!option%%N!"
        call :DebugLog "User chose option %%N. Executing: !actionToRun!"
        CALL :!actionToRun! "%argPath%"
        GOTO :EndExecution
    )
)

REM --- Check letter options ---
if "%isAnyImage%"=="1" (
    set /a currentLvl+=1
    if %userChoiceLvl% equ !currentLvl! (
        call :DebugLog "User chose P - Convert to PNG"
        CALL :Convert_to_PNG "%argPath%"
        GOTO :EndExecution
    )
    set /a currentLvl+=1
    if %userChoiceLvl% equ !currentLvl! (
        call :DebugLog "User chose J - Convert to JPG"
        CALL :Convert_to_JPG "%argPath%"
        GOTO :EndExecution
    )
    set /a currentLvl+=1
    if %userChoiceLvl% equ !currentLvl! (
        call :DebugLog "User chose W - Convert to WebP"
        CALL :Convert_to_WEBP "%argPath%"
        GOTO :EndExecution
    )
)

REM --- Check Menu options ---
set /a currentLvl+=1
if %userChoiceLvl% equ !currentLvl! (
    call :DebugLog "User chose M - Main Menu"
    goto :MainMenu
)
set /a currentLvl+=1
if %userChoiceLvl% equ !currentLvl! (
    call :DebugLog "User chose E - Exit"
    call :Cleanup
    exit /b
)

call :DebugLog "ERROR: Invalid choice mapping! Fell through all checks."
ECHO [ERROR] Invalid selection
PAUSE
GOTO :EndExecution

:ImageConverterMainMenu
:: --- Check for ImageMagick Dependency ---
SET "MAGICK_EXE=%resourcesPath%magick.exe"
IF NOT EXIST "%MAGICK_EXE%" (
    CLS
    ECHO.
    ECHO   -------------------------------------------------------------
    ECHO    [FATAL ERROR] ImageMagick Not Found!
    ECHO   -------------------------------------------------------------
    ECHO.
    ECHO   This function requires ImageMagick to function.
    ECHO   Please ensure 'magick.exe' is in the resources folder.
    ECHO.
    ECHO   Expected Location:
    ECHO   %MAGICK_EXE%
    ECHO.
    PAUSE
    GOTO :MainMenu
)

CLS
ECHO.
ECHO   ========================================================================
ECHO                           Icon Converter Pro
ECHO   ========================================================================
ECHO.
ECHO   Select a conversion task for a single file:
ECHO.
ECHO     [1] Convert Image to ICO (Standard)
ECHO     [2] Convert Image to ICO (Rounded Corners)
ECHO     [3] Re-process ICO to Standard ICO
ECHO     [4] Convert ICO to PNG (Highest Resolution)
ECHO     [5] Convert ICO to PNG (All sizes, new folder)
ECHO     [6] Extract Icon from EXE
ECHO.
ECHO   ------------------------------------------------------------------------
ECHO     [P] Convert Image to PNG
ECHO     [J] Convert Image to JPG
ECHO     [W] Convert Image to Webp
ECHO   ------------------------------------------------------------------------
ECHO.
ECHO   ========================================================================
ECHO     [7] Convert Entire Folder
ECHO   ========================================================================
ECHO.
ECHO   ------------------------------------------------------------------------
ECHO     [M] Return to Main Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.
CHOICE /C 1234567PJWME /N /M "Enter your choice: "

IF ERRORLEVEL 12 call :Cleanup & exit /b
IF ERRORLEVEL 11 GOTO :MainMenu
IF ERRORLEVEL 10 GOTO :HandleOptionW
IF ERRORLEVEL 9 GOTO :HandleOptionJ
IF ERRORLEVEL 8 GOTO :HandleOptionP
IF ERRORLEVEL 7 GOTO :HandleFolderConversionMenu
IF ERRORLEVEL 6 GOTO :HandleOption6
IF ERRORLEVEL 5 GOTO :HandleOption5
IF ERRORLEVEL 4 GOTO :HandleOption4
IF ERRORLEVEL 3 GOTO :HandleOption3
IF ERRORLEVEL 2 GOTO :HandleOption2
IF ERRORLEVEL 1 GOTO :HandleOption1
GOTO :eof

:HandleOption1
    CALL :GetUserInput "Convert Image to ICO" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_ICO "%argPath%" & GOTO :EndExecution
:HandleOption2
    CALL :GetUserInput "Convert Image to ICO (Rounded Corners)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_ICO_Rounded "%argPath%" & GOTO :EndExecution
:HandleOption3
    CALL :GetUserInput "Re-process ICO to Standard ICO" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_ICO_Standard_Reprocess "%argPath%" & GOTO :EndExecution
:HandleOption4
    CALL :GetUserInput "Convert ICO to PNG (Highest Resolution)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_PNG_Single "%argPath%" & GOTO :EndExecution
:HandleOption5
    CALL :GetUserInput "Convert ICO to PNG (All Sizes)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_PNG_AllSizes "%argPath%" & GOTO :EndExecution
:HandleOption6
    CALL :GetUserInput "Extract Icon from EXE" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_EXE_to_ICO "%argPath%" & GOTO :EndExecution
:HandleOptionP
    CALL :GetUserInput "Convert Image to PNG" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_PNG "%argPath%" & GOTO :EndExecution
:HandleOptionJ
    CALL :GetUserInput "Convert Image to JPG" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_JPG "%argPath%" & GOTO :EndExecution
:HandleOptionW
    CALL :GetUserInput "Convert Image to WebP" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_WEBP "%argPath%" & GOTO :EndExecution

:HandleFolderConversionMenu
CLS
ECHO.
ECHO   ========================================================================
ECHO                        Folder Conversion Tasks
ECHO   ========================================================================
ECHO.
ECHO   Select a batch conversion task for an entire folder:
ECHO.
ECHO     [1] Convert Entire Folder's Images to ICO (Standard)
ECHO     [2] Convert Entire Folder's Images to ICO (Rounded Corners)
ECHO     [3] Re-process Entire Folder's ICOs to Standard ICO
ECHO     [4] Convert Entire Folder's ICOs to PNG (Highest Resolution)
ECHO     [5] Convert Entire Folder's ICOs to PNG (All Sizes)
ECHO     [6] Extract All Icons from Folder's EXEs
ECHO.
ECHO   ------------------------------------------------------------------------
ECHO     [P] Convert Entire Folder's Images to PNG
ECHO     [J] Convert Entire Folder's Images to JPG
ECHO     [W] Convert Entire Folder's Images to Webp
ECHO   ------------------------------------------------------------------------
ECHO.
ECHO     [M] Return to Icon Converter Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.
CHOICE /C 123456PJWME /N /M "Enter your choice: "

IF ERRORLEVEL 11 call :Cleanup & exit /b
IF ERRORLEVEL 10 GOTO :ImageConverterMainMenu
IF ERRORLEVEL 9 GOTO :HandleFolderOptionW
IF ERRORLEVEL 8 GOTO :HandleFolderOptionJ
IF ERRORLEVEL 7 GOTO :HandleFolderOptionP
IF ERRORLEVEL 6 GOTO :HandleFolderOption6
IF ERRORLEVEL 5 GOTO :HandleFolderOption5
IF ERRORLEVEL 4 GOTO :HandleFolderOption4
IF ERRORLEVEL 3 GOTO :HandleFolderOption3
IF ERRORLEVEL 2 GOTO :HandleFolderOption2
IF ERRORLEVEL 1 GOTO :HandleFolderOption1
GOTO :eof

:HandleFolderOption1
    CALL :GetFolderInput "Convert Folder: Images to ICO (Standard)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_ICO "%argPath%" & GOTO :EndExecution
:HandleFolderOption2
    CALL :GetFolderInput "Convert Folder: Images to ICO (Rounded)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_ICO_Rounded "%argPath%" & GOTO :EndExecution
:HandleFolderOption3
    CALL :GetFolderInput "Convert Folder: Re-process ICOs to Standard" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_Folder_ICO_Standard_Reprocess "%argPath%" & GOTO :EndExecution
:HandleFolderOption4
    CALL :GetFolderInput "Convert Folder: ICOs to PNG (Single)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_PNG_Single "%argPath%" & GOTO :EndExecution
:HandleFolderOption5
    CALL :GetFolderInput "Convert Folder: ICOs to PNG (All Sizes)" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_PNG_AllSizes "%argPath%" & GOTO :EndExecution
:HandleFolderOption6
    CALL :GetFolderInput "Convert Folder: Extract from EXEs" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_EXE_to_ICO "%argPath%" & GOTO :EndExecution
:HandleFolderOptionP
    CALL :GetFolderInput "Convert Folder: Images to PNG" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_PNG "%argPath%" & GOTO :EndExecution
:HandleFolderOptionJ
    CALL :GetFolderInput "Convert Folder: Images to JPG" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_JPG "%argPath%" & GOTO :EndExecution
:HandleFolderOptionW
    CALL :GetFolderInput "Convert Folder: Images to WebP" & IF NOT DEFINED argPath GOTO :ImageConverterMainMenu & CALL :Convert_to_WEBP "%argPath%" & GOTO :EndExecution

:: =================================================================
:: ==                  MAIN CONVERSION SCRIPTS                     ==
:: =================================================================

::-------------------------------------------------
::-- SCRIPT 1: Convert Image to ICO
::-------------------------------------------------
:Convert_ICO
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO                   [1] Convert Image to ICO
ECHO   -------------------------------------------------------------
ECHO.
SET "lastOutputFile="

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertIcoEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.png" "*.bmp" "*.gif" "*.jpg" "*.jpeg" "*.svg" "*.webp" 2^>nul`) DO (
        ECHO.
        ECHO - Processing "%%f"...
        SET "outputBase=%%~nf"
        SET "outputFile=!outputBase!.ico"
        IF EXIST "!outputFile!" (
            CALL :FindNextAvailableFilename "!outputBase!" ".ico"
            SET "outputFile=!foundFile!"
        )
        ECHO   Output file: "!outputFile!"
        CALL "%MAGICK_EXE%" -quiet "%%f" -alpha on -trim +repage -background transparent -resize 256x256 -gravity center -extent 256x256 -filter Lanczos -strip -define icon:auto-resize=256,128,96,64,48,32,24,16 "!outputFile!"
        SET "lastOutputFile=!outputFile!"
    )
    popd
) ELSE (
    ECHO Processing file: "%processPath%"
    ECHO.
    set "localProcessPath=%processPath%"
    for %%A in ("!localProcessPath!") do (
        ECHO - Processing "%%~nxA"...
        SET "outputBase=%%~dpnA"
    )
    SET "outputFile=!outputBase!.ico"
    IF EXIST "!outputFile!" (
        CALL :FindNextAvailableFilename "!outputBase!" ".ico"
        SET "outputFile=!foundFile!"
    )
    ECHO   Output file: "!outputFile!"
    CALL "%MAGICK_EXE%" -quiet "!localProcessPath!" -alpha on -trim +repage -background transparent -resize 256x256 -gravity center -extent 256x256 -filter Lanczos -strip -define icon:auto-resize=256,128,96,64,48,32,24,16 "!outputFile!"
    SET "lastOutputFile=!outputFile!"
)
:ConvertIcoEnd
ECHO.
ECHO   -------------------------------------------------------------
ECHO   Conversion complete.
ECHO   -------------------------------------------------------------
GOTO :EOF


::-------------------------------------------------
::-- SCRIPT 1B: Re-process ICO to Standard ICO
::-------------------------------------------------
:Convert_ICO_Standard_Reprocess
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO             [1B] Convert ICO to ICO (Standard)
ECHO   -------------------------------------------------------------
ECHO.
ECHO Processing single file...
ECHO.
ECHO - Reprocessing "%~nx1"...
CALL :GetLargestFrame "%~f1" "%TEMP%\%~n1"
CALL :FindNextAvailableFilename "%~dpn1" ".ico"
SET "finalName=!foundFile!"
ECHO   Output file: "!finalName!"
IF DEFINED largestFile (
    IF EXIST "!largestFile!" (
        CALL "%MAGICK_EXE%" -quiet "!largestFile!" -alpha on -background transparent -resize 256x256 -gravity center -extent 256x256 -filter Lanczos -strip -define icon:auto-resize=256,128,96,64,48,32,24,16 "!finalName!"
    )
)
DEL /Q "%TEMP%\%~n1_temp*.png" 2>nul
ECHO.
ECHO   -------------------------------------------------------------
ECHO   Conversion complete.
ECHO   -------------------------------------------------------------
GOTO :EOF

::-------------------------------------------------
::-- NEW SCRIPT: Re-process FOLDER of ICOs to Standard ICOs
::-------------------------------------------------
:Convert_Folder_ICO_Standard_Reprocess
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO        [3] Re-process Entire Folder's ICOs to Standard
ECHO   -------------------------------------------------------------
ECHO.

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertFolderReprocessEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.ico" 2^>nul`) DO (
        ECHO.
        ECHO - Reprocessing "%%f"...
        
        REM Re-use the logic from the single-file version for each file
        CALL :GetLargestFrame "%%~f" "%TEMP%\%%~nf"
        CALL :FindNextAvailableFilename "%%~dpnf" ".ico"
        
        ECHO   Output file: "!foundFile!"
        IF DEFINED largestFile (
            IF EXIST "!largestFile!" (
                CALL "%MAGICK_EXE%" -quiet "!largestFile!" -alpha on -background transparent -resize 256x256 -gravity center -extent 256x256 -filter Lanczos -strip -define icon:auto-resize=256,128,96,64,48,32,24,16 "!foundFile!"
            )
        )
        DEL /Q "%TEMP%\%%~nf_temp*.png" 2>nul
    )
    popd
) ELSE (
    ECHO [ERROR] A valid folder was not provided.
)
:ConvertFolderReprocessEnd
ECHO.
ECHO   -------------------------------------------------------------
ECHO   Re-processing complete.
ECHO   -------------------------------------------------------------
GOTO :EOF


::-------------------------------------------------
::-- SCRIPT 2: Convert to ICO (ROUNDED CORNERS)
::-------------------------------------------------
:Convert_ICO_Rounded
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO              [2] Convert to ICO (Rounded Corners)
ECHO   -------------------------------------------------------------
ECHO.
SET "lastOutputFile="

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertRoundedEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.ico" 2^>nul`) DO (
        CALL :ProcessIcoRounded "%%~f"
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.png" "*.bmp" "*.gif" "*.jpg" "*.jpeg" "*.svg" "*.webp" 2^>nul`) DO (
        CALL :ProcessImageRounded "%%~f"
    )
    popd
) ELSE (
    ECHO Processing single file...
    for %%f in ("%processPath%") do set "fileExt=%%~xf"
    IF /I "!fileExt!"==".ico" (
        CALL :ProcessIcoRounded "%processPath%"
    ) ELSE (
        CALL :ProcessImageRounded "%processPath%"
    )
)
:ConvertRoundedEnd
ECHO.
ECHO   -------------------------------------------------------------
ECHO   Conversion complete.
ECHO   -------------------------------------------------------------
GOTO :EOF

:ProcessImageRounded
    SETLOCAL
    SET "inputFile=%~f1"
    ECHO.
    ECHO - Processing "%~nx1"...
    SET "outputBase=%~dpn1"
    SET "outputFile=!outputBase!.ico"
    IF EXIST "!outputFile!" (
        CALL :FindNextAvailableFilename "!outputBase!" ".ico"
        SET "outputFile=!foundFile!"
    )
    ECHO   Output file: "!outputFile!"
    CALL :ExecuteRoundedConversion "!inputFile!" "!outputFile!"
    ENDLOCAL & SET "lastOutputFile=%outputFile%"
GOTO :EOF

:ProcessIcoRounded
    SETLOCAL
    SET "inputFile=%~f1"
    ECHO.
    ECHO - Reprocessing "%~nx1"...
    CALL :GetLargestFrame "%~f1" "%TEMP%\%~n1"
    CALL :FindNextAvailableFilename "%~dpn1" ".ico"
    SET "finalName=!foundFile!"
    ECHO   Output file: "!finalName!"
    IF DEFINED largestFile (
        IF EXIST "!largestFile!" (
            CALL :ExecuteRoundedConversion "!largestFile!" "!finalName!"
        )
    )
    DEL /Q "%TEMP%\%~n1_temp*.png" 2>nul
    ENDLOCAL & SET "lastOutputFile=%finalName%"
GOTO :EOF

:ExecuteRoundedConversion
    SETLOCAL
    SET "radius=25"
    SET "localInput=%~1"
    SET "localOutput=%~2"
    SET "tempBat=%TEMP%\_magick_cmd_%RANDOM%.bat"
    (
        ECHO @"%MAGICK_EXE%" -quiet "!localInput!" -alpha on -trim +repage -background transparent -resize 256x256 -gravity center -extent 256x256 ^( +clone -alpha extract -draw "fill black polygon 0,0 0,%radius% %radius%,0 fill white circle %radius%,%radius% %radius%,0" ^( +clone -flip ^) -compose Multiply -composite ^( +clone -flop ^) -compose Multiply -composite ^) -alpha off -compose CopyOpacity -composite -filter Lanczos -strip -define icon:auto-resize=256,128,96,64,48,32,24,16 "!localOutput!"
    ) > "!tempBat!"
    
    CALL "!tempBat!"
    DEL "!tempBat!"
    ENDLOCAL
GOTO :EOF


::-------------------------------------------------
::-- SCRIPT 3: Convert ICO to PNG (Single, Best Quality)
::-------------------------------------------------
:Convert_PNG_Single
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO          [4] Convert ICO to PNG (Highest Resolution)
ECHO   -------------------------------------------------------------
ECHO.
SET successCount=0
SET failCount=0
SET "lastOutputFile="

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertPngSingleEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.ico" 2^>nul`) DO (
        CALL :ProcessIcoToPngSingleFile "%%~f"
    )
    popd
) ELSE IF EXIST "%processPath%" (
    ECHO Processing single file...
    CALL :ProcessIcoToPngSingleFile "%processPath%"
) ELSE (
    ECHO [ERROR] File or path not found: %processPath%
)

:ConvertPngSingleEnd
ECHO.
ECHO ============================================================
ECHO Summary: !successCount! succeeded, !failCount! failed
ECHO ============================================================
GOTO :EOF


::-------------------------------------------------
::-- SCRIPT 4: Convert ICO to PNG (All Sizes, New Folder)
::-------------------------------------------------
:Convert_PNG_AllSizes
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO             [5] Convert ICO to PNG (All Sizes)
ECHO   -------------------------------------------------------------
ECHO.
SET successCount=0
SET failCount=0
SET "lastOutputFolder="

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertPngAllEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.ico" 2^>nul`) DO (
        CALL :ProcessIcoToPngAllSizes "%%~f"
    )
    popd
) ELSE IF EXIST "%processPath%" (
    ECHO Processing single file...
    CALL :ProcessIcoToPngAllSizes "%processPath%"
) ELSE (
    ECHO [ERROR] File or path not found: %processPath%
)

:ConvertPngAllEnd
ECHO.
ECHO ============================================================
ECHO Summary: !successCount! succeeded, !failCount! failed
ECHO ============================================================
GOTO :EOF


::-------------------------------------------------
::-- SCRIPT 5: Extract Icon from EXE
::-------------------------------------------------
:Convert_EXE_to_ICO
SET "processPath=%~f1"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO                  [6] Extract Icon from EXE
ECHO   -------------------------------------------------------------
ECHO.

CALL :CheckForExtractionTools
IF !ERRORLEVEL! NEQ 0 (
    PAUSE
    GOTO :EOF
)

SET successCount=0
SET failCount=0
SET "lastOutputFile="

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 (
        echo ERROR: Could not access directory.
        goto ConvertExeEnd
    )
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.exe" 2^>nul`) DO (
        CALL :ProcessSingleExe "%%~f"
    )
    popd
) ELSE IF EXIST "%processPath%" (
    ECHO Processing single file...
    CALL :ProcessSingleExe "%processPath%"
) ELSE (
    ECHO [ERROR] File or path not found: %processPath%
)

:ConvertExeEnd
ECHO.
ECHO ============================================================
ECHO Summary: !successCount! succeeded, !failCount! failed
ECHO ============================================================
GOTO :EOF

::-------------------------------------------------
::-- NEW: Generic Image Converters
::-------------------------------------------------
:Convert_to_PNG
    CALL :Convert_Generic "%~1" "png"
GOTO :EOF

:Convert_to_JPG
    CALL :Convert_Generic "%~1" "jpg"
GOTO :EOF

:Convert_to_WEBP
    CALL :Convert_Generic "%~1" "webp"
GOTO :EOF

:Convert_Generic
SET "processPath=%~f1"
SET "targetExt=%~2"
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO            Converting file(s) to %targetExt%
ECHO   -------------------------------------------------------------
ECHO.

IF EXIST "%processPath%\*" (
    ECHO Processing directory: "%processPath%"
    pushd "%processPath%"
    if errorlevel 1 ( echo ERROR: Could not access directory. & goto GenericConvertEnd )
    
    FOR /F "usebackq delims=" %%f IN (`dir /b /a-d "*.png" "*.bmp" "*.gif" "*.jpg" "*.jpeg" "*.svg" "*.ico" "*.webp" 2^>nul`) DO (
        if /I "%%~xf" NEQ ".%targetExt%" (
            ECHO.
            ECHO - Processing "%%f"...
            SET "outputBase=%%~nf"
            CALL :FindNextAvailableFilename "!outputBase!" ".%targetExt%"
            ECHO   Output file: "!foundFile!"
            CALL "%MAGICK_EXE%" -quiet "%%f" "!foundFile!"
        )
    )
    popd
) ELSE (
    ECHO Processing file: "%processPath%"
    ECHO.
    set "localProcessPath=%processPath%"
    for %%A in ("!localProcessPath!") do (
        ECHO - Processing "%%~nxA"...
        SET "outputBase=%%~dpnA"
    )
    CALL :FindNextAvailableFilename "!outputBase!" ".%targetExt%"
    ECHO   Output file: "!foundFile!"
    CALL "%MAGICK_EXE%" -quiet "!localProcessPath!" "!foundFile!"
)
:GenericConvertEnd
ECHO.
ECHO   -------------------------------------------------------------
ECHO   Conversion complete.
ECHO   -------------------------------------------------------------
GOTO :EOF

:: =================================================================
:: ==                      HELPER SUBROUTINES                      ==
:: =================================================================

:GetUserInput
SET "argPath="
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO   %~1
ECHO   -------------------------------------------------------------
ECHO.
ECHO   Select an input method:
ECHO.
ECHO     [1] Browse for a file
ECHO     [2] Paste file path manually
ECHO.
ECHO   ------------------------------------------------------------------------
ECHO     [M] Return to Previous Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.
CHOICE /C 12ME /N /M "Enter your choice: "

IF ERRORLEVEL 4 call :Cleanup & exit /b
IF ERRORLEVEL 3 GOTO :EOF
IF ERRORLEVEL 2 GOTO :paste_path_manual
IF ERRORLEVEL 1 GOTO :browse_for_file
GOTO :EOF

:browse_for_file
ECHO.
ECHO Opening file browser...

REM Escape current directory for PowerShell
set "currentDir=%CD%"
call :EscapeForPowerShell "%currentDir%" escapedDir

for /f "delims=" %%i in ('powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.OpenFileDialog; $f.Filter='All Supported Files|*.exe;*.png;*.bmp;*.gif;*.jpg;*.jpeg;*.svg;*.ico;*.webp|All Files|*.*'; $f.InitialDirectory='!escapedDir!'; $f.Title='Select File'; if($f.ShowDialog() -eq 'OK'){$f.FileName}"') do set "argPath=%%i"
GOTO :EOF

:paste_path_manual
ECHO.
setlocal enabledelayedexpansion
set /p "inputPath=Enter the full path to your file and press Enter: "

REM Remove all quotes
set "cleanPath=!inputPath!"
set cleanPath=!cleanPath:"=!

REM Trim any leading/trailing spaces
for /f "tokens=* delims= " %%a in ("!cleanPath!") do set "cleanPath=%%a"

endlocal & set "argPath=%cleanPath%"
GOTO :EOF

:GetFolderInput
SET "argPath="
CLS
ECHO.
ECHO   -------------------------------------------------------------
ECHO   %~1
ECHO   -------------------------------------------------------------
ECHO.
ECHO   Select an input method:
ECHO.
ECHO     [1] Browse for a folder
ECHO     [2] Paste folder path manually
ECHO.
ECHO   ------------------------------------------------------------------------
ECHO     [M] Return to Previous Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.
CHOICE /C 12ME /N /M "Enter your choice: "

IF ERRORLEVEL 4 call :Cleanup & exit /b
IF ERRORLEVEL 3 GOTO :EOF
IF ERRORLEVEL 2 GOTO :paste_folder_path
IF ERRORLEVEL 1 GOTO :browse_for_folder
GOTO :EOF

:browse_for_folder
ECHO.
ECHO Opening folder browser...

REM Escape current directory for PowerShell
set "currentDir=%CD%"
call :EscapeForPowerShell "%currentDir%" escapedDir

set "psCommand=Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.OpenFileDialog; $f.Title='Select a folder by navigating into it and clicking Open'; $f.ValidateNames=$false; $f.CheckFileExists=$false; $f.CheckPathExists=$true; $f.InitialDirectory='!escapedDir!'; $f.FileName='Select This Folder'; if($f.ShowDialog() -eq 'OK'){ [System.IO.Path]::GetDirectoryName($f.FileName) }"

for /f "usebackq delims=" %%F in (`powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "!psCommand!"`) do (
    set "argPath=%%F"
)
GOTO :EOF

:paste_folder_path
ECHO.
setlocal enabledelayedexpansion
set /p "inputPath=Enter the full path to your folder and press Enter: "

REM Remove all quotes
set "cleanPath=!inputPath!"
set cleanPath=!cleanPath:"=!

REM Trim any leading/trailing spaces
for /f "tokens=* delims= " %%a in ("!cleanPath!") do set "cleanPath=%%a"

endlocal & set "argPath=%cleanPath%"
GOTO :EOF


:ProcessIcoToPngSingleFile
SETLOCAL
SET "inputFile=%~f1"
SET "outputBase=%~dpn1"
SET "outputFile=%outputBase%.png"

ECHO -----------------------------------------------------------
ECHO Processing: %~nx1

IF EXIST "!outputFile!" (
    CALL :FindNextAvailableFilename "!outputBase!" ".png"
    SET "outputFile=!foundFile!"
)
ECHO Output file: !outputFile!

CALL "%MAGICK_EXE%" "!inputFile![0]" -alpha on "!outputFile!" >nul 2>&1
IF EXIST "!outputFile!" (
    ECHO [SUCCESS] Conversion successful
    SET /A successCount+=1
) ELSE (
    ECHO [FAILED] Conversion failed for: %~n1%~x1
    SET /A failCount+=1
)
ENDLOCAL & SET successCount=%successCount%& SET failCount=%failCount%
GOTO :EOF


:ProcessIcoToPngAllSizes
SETLOCAL
SET "inputFile=%~f1"
SET "fileName=%~n1"
SET "outputFolderBase=%~dpn1"
SET "outputFolder=%outputFolderBase%"

ECHO -----------------------------------------------------------
ECHO Processing: %fileName%%~x1

IF EXIST "%outputFolder%\" (
    CALL :FindNextAvailableFolderName "%outputFolderBase%"
    SET "outputFolder=!foundFolder!"
)

ECHO Creating folder: !outputFolder!
MKDIR "!outputFolder!" 2>nul
IF !ERRORLEVEL! NEQ 0 (
    ECHO [ERROR] Failed to create folder
    SET /A failCount+=1
    GOTO :ProcessAllEnd
)

SET "outputFile=!outputFolder!\%fileName%.png"
ECHO Output: %outputFile% (and others)

CALL "%MAGICK_EXE%" "!inputFile!" -alpha on "!outputFile!" >nul 2>&1
IF !ERRORLEVEL! EQU 0 (
    ECHO [SUCCESS] Conversion successful
    SET /A successCount+=1
) ELSE (
    ECHO Trying fallback methods...
    CALL "%MAGICK_EXE%" "!inputFile!" -flatten -alpha on "!outputFile!" >nul 2>&1
    IF !ERRORLEVEL! EQU 0 (
         ECHO [SUCCESS] Conversion successful with method 2
         SET /A successCount+=1
    ) ELSE (
        ECHO [FAILED] All conversion methods failed for: %fileName%%~x1
        SET /A failCount+=1
    )
)

:ProcessAllEnd
ENDLOCAL & SET successCount=%successCount%& SET failCount=%failCount%
GOTO :EOF


:ProcessSingleExe
SETLOCAL
SET "target=%~f1"
SET "outputBase=%~dpn1"
SET "success=0"

ECHO -----------------------------------------------------------
ECHO Processing: %~nx1

:: --- Setup output and temp files ---
SET "outfile=!outputBase!.ico"
IF EXIST "!outfile!" (
    CALL :FindNextAvailableFilename "!outputBase!" ".ico"
    SET "outfile=!foundFile!"
)
SET "tempdir=%TEMP%\ico_extract_%RANDOM%%RANDOM%"
mkdir "!tempdir!" 2>nul
ECHO   Output: !outfile!

:: --- METHOD 1: IconsExtract (Best for preserving original quality) ---
if !success! equ 0 if defined IE_EXE (
    ECHO [Method 1] IconsExtract - Extracting...
    "!IE_EXE!" /save "!target!" "!tempdir!" -icons >nul 2>nul
    
    set "besticon="
    set "bestsize=0"
    
    for %%F in ("!tempdir!\*.ico") do (
        set "fname=%%~nxF"
        echo !fname! | findstr /r "_[0-9][0-9]*x[0-9][0-9]*_" >nul
        if errorlevel 1 (
            set "besticon=%%F"
            goto :copy_best_icon
        )
    )
    
    for %%F in ("!tempdir!\*.ico") do (
        set "besticon=%%F"
        goto :copy_best_icon
    )
    
    :copy_best_icon
    if defined besticon (
        copy /y "!besticon!" "!outfile!" >nul 2>&1
        if exist "!outfile!" (
            ECHO   [SUCCESS] Copied to output
            set "success=1"
        )
    ) else (
        ECHO   ...No icons extracted by IconsExtract
    )
)

:: --- METHOD 2: ResourceHacker - Try common indices ---
if !success! equ 0 if defined RH_EXE (
    ECHO [Method 2] ResourceHacker - Trying common indices...
    for %%I in (1 32512 32513 MAINICON 101 102 103 104 105) do (
        if !success! equ 0 (
            ECHO   Trying: %%I
            "!RH_EXE!" -open "!target!" -save "!outfile!" -action extract -mask ICONGROUP,%%I, -log NUL
            if exist "!outfile!" (
                ECHO   [SUCCESS] Found at index %%I
                set "success=1"
            )
        )
    )
)

:: --- METHOD 3: ImageMagick - Direct extraction ---
if !success! equ 0 if defined MAGICK_EXE (
    ECHO [Method 3] ImageMagick - Extracting...
    "!MAGICK_EXE%" "!target!" "!tempdir!\extracted.ico" 2>nul
    if exist "!tempdir!\extracted.ico" (
        copy /y "!tempdir!\extracted.ico" "!outfile!" >nul 2>&1
        if exist "!outfile!" (
            ECHO   [SUCCESS] Extracted with ImageMagick
            set "success=1"
        )
    )
    if !success! equ 0 (
        for /l %%I in (0,1,5) do (
             if !success! equ 0 (
                "!MAGICK_EXE%" "!target![%%I]" "!outfile!" 2>nul
                if exist "!outfile!" (
                    ECHO   [SUCCESS] Found at index %%I
                    set "success=1"
                )
            )
        )
    )
)

:: --- METHOD 4: ResourceHacker - Deep scan ---
if !success! equ 0 if defined RH_EXE (
    ECHO [Method 4] ResourceHacker - Deep scan...
    for /l %%I in (1,1,50000) do (
        if !success! equ 0 (
            "!RH_EXE!" -open "!target!" -save "!outfile!" -action extract -mask ICONGROUP,%%I, -log NUL 2>nul
            if exist "!outfile!" (
                ECHO   [SUCCESS] Found at index %%I
                set "success=1"
            )
        )
    )
)

:: --- Cleanup and Results ---
if exist "!tempdir!" (
    rd /s /q "!tempdir!" 2>nul
)

IF !success! equ 1 (
    SET /A successCount+=1
) ELSE (
    ECHO   [FAILED] Could not extract an icon from this file.
    SET /A failCount+=1
)
ENDLOCAL & SET successCount=%successCount%& SET failCount=%failCount%
GOTO :EOF


:GetLargestFrame
SET "inputFile=%~f1"
SET "baseName=%~2"
CALL "%MAGICK_EXE%" "%inputFile%" -alpha on "%baseName%_temp.png" >nul 2>&1
SET "largestFile="
SET "largestSize=0"
IF EXIST "%baseName%_temp.png" (
    FOR %%p IN ("%baseName%_temp.png") DO (
        SET "currentSize=%%~zp"
        IF !currentSize! GTR !largestSize! (
            SET "largestSize=!currentSize!"
            SET "largestFile=%%~fp"
        )
    )
)
FOR %%p IN ("%baseName%_temp-*.png") DO (
    SET "currentSize=%%~zp"
    IF !currentSize! GTR !largestSize! (
        SET "largestSize=!currentSize!"
        SET "largestFile=%%~fp"
    )
)
GOTO :EOF


:CheckForExtractionTools
ECHO Searching for required tools...
SET "RH_EXE="
SET "IE_EXE="

if exist "%resourcesPath%ResourceHacker.exe" SET "RH_EXE=%resourcesPath%ResourceHacker.exe"
if exist "%resourcesPath%IconsExtract.exe"   SET "IE_EXE=%resourcesPath%IconsExtract.exe"

if "!RH_EXE!"=="" (where ResourceHacker.exe >nul 2>&1 && SET "RH_EXE=ResourceHacker.exe")
if "!IE_EXE!"=="" (where IconsExtract.exe >nul 2>&1 && SET "IE_EXE=IconsExtract.exe")

IF NOT "!RH_EXE!"=="" (ECHO   [+] Found ResourceHacker: !RH_EXE!) ELSE (ECHO   [!] ResourceHacker not found)
IF NOT "!IE_EXE!"=="" (ECHO   [+] Found IconsExtract: !IE_EXE!) ELSE (ECHO   [!] IconsExtract not found)
IF NOT "!MAGICK_EXE!"=="" (ECHO   [+] Found ImageMagick: !MAGICK_EXE!) ELSE (ECHO   [!] ImageMagick not found)
ECHO.

SET "toolsFound=0"
IF NOT "!RH_EXE!"=="" SET "toolsFound=1"
IF NOT "!IE_EXE!"=="" SET "toolsFound=1"
IF NOT "!MAGICK_EXE!"=="" SET "toolsFound=1"

IF "!toolsFound!"=="0" (
    ECHO -----------------------------------------------------------
    ECHO [FATAL ERROR] No extraction tools found!
    ECHO -----------------------------------------------------------
    ECHO.
    ECHO This function requires at least one of the following:
    ECHO   - ResourceHacker.exe, IconsExtract.exe, magick.exe
    ECHO.
    ECHO Place the required tools in the 'resources' subfolder.
    ECHO.
    EXIT /B 1
)
EXIT /B 0


:FindNextAvailableFilename
SET "baseName=%~1"
SET "extension=%~2"
SET "counter=2"
:checkFileLoop
SET "checkFile=%baseName%_%counter%%extension%"
IF EXIST "%checkFile%" (
    SET /A counter+=1
    GOTO :checkFileLoop
)
SET "foundFile=%checkFile%"
GOTO :EOF


:FindNextAvailableFolderName
SET "baseName=%~1"
SET "counter=2"
:checkFolderLoop
SET "checkFolder=%baseName%_%counter%"
IF EXIST "%checkFolder%\" (
    SET /A counter+=1
    GOTO :checkFolderLoop
)
SET "foundFolder=%checkFolder%"
GOTO :EOF


:: =================================================================
:: ==             END OF IMAGE CONVERTER PRO SECTION               ==
:: =================================================================
:EndExecution
ECHO.
ECHO   ========================================================================
ECHO     [M] Return to Main Menu
ECHO     [E] Exit
ECHO   ========================================================================
ECHO.
CHOICE /C ME /N /M "Select your choice: "
IF ERRORLEVEL 2 call :Cleanup & exit /b
IF ERRORLEVEL 1 GOTO :MainMenu
GOTO :MainMenu

:: ### NEW SUBROUTINE for handling end-of-operation choices ###
:EndExecutionMenu
ECHO.
ECHO   ========================================================================
ECHO                          Operation Complete
ECHO   ========================================================================
ECHO.
ECHO     [M] Return to Main Menu
ECHO     [E] Exit
ECHO.
CHOICE /C ME /N /M "  Select your choice: "
IF ERRORLEVEL 2 ( call :Cleanup & call :DebugLog "User chose to exit." & exit /b )
IF ERRORLEVEL 1 GOTO :MainMenu
GOTO :MainMenu

:FolderOperationCompleteMenu
setlocal
set "processedFolder=%~1"
:MenuLoop
ECHO.
ECHO   ========================================================================
ECHO                          Operation Complete
ECHO   ========================================================================
ECHO.
ECHO     [I] Choose a Different Icon for this Folder
ECHO     [M] Return to Main Menu
ECHO     [E] Exit
ECHO.
CHOICE /C IME /N /M "  Select your choice: "
if errorlevel 3 ( call :Cleanup & call :DebugLog "User chose to exit from complete menu." & endlocal & exit /b )
if errorlevel 2 ( endlocal & goto :MainMenu )
if errorlevel 1 (
    call :OfferFolderActions "%processedFolder%"
    goto :MenuLoop
)
endlocal
goto :eof

REM ============================================================================
REM ============================================================================
REM ==                   UTILITY FUNCTIONS SECTION                            ==
REM ============================================================================
REM ============================================================================

:ValidateResources
    REM Check and report on critical dependencies
    set "missingTools="
    set "warningIssued=0"
    
    if not exist "%IconUpdaterPath%" (
        set "missingTools=!missingTools! FolderIconUpdater.exe"
        set "warningIssued=1"
    )
    
    if not exist "%resourcesPath%magick.exe" (
        set "missingTools=!missingTools! magick.exe"
        set "warningIssued=1"
    )
    
    if "%warningIssued%"=="1" (
        call :DebugLog "WARNING: Missing tools:%missingTools%"
        call :DebugLog "Some features will be unavailable."
    ) else (
        call :DebugLog "All critical resources validated successfully."
    )
goto :eof

:SanitizePath
    REM Remove quotes and trim spaces from path
    setlocal enabledelayedexpansion
    set "inputPath=%~1"
    set "inputPath=!inputPath:"=!"
    
    REM Trim leading spaces
    for /f "tokens=* delims= " %%a in ("!inputPath!") do set "inputPath=%%a"
    
    REM Trim trailing spaces
    :trimTrailing
    if "!inputPath:~-1!"==" " (
        set "inputPath=!inputPath:~0,-1!"
        goto :trimTrailing
    )
    
    endlocal & set "%~2=%inputPath%"
goto :eof

:EscapeForPowerShell
    REM Escape path for safe use in PowerShell commands
    setlocal enabledelayedexpansion
    set "inputPath=%~1"
    
    REM Replace backslashes with double backslashes
    set "inputPath=!inputPath:\=\\!"
    
    REM Escape single quotes
    set "inputPath=!inputPath:'=''!"
    
    REM Escape dollar signs
    set "inputPath=!inputPath:$=`$!"
    
    endlocal & set "%~2=%inputPath%"
goto :eof

:Cleanup
    REM Clean up temporary files
    call :DebugLog "Cleaning up temporary files..."
    
    if exist "%TEMP%\foldericon_*.txt" del /q "%TEMP%\foldericon_*.txt" 2>nul
    if exist "%TEMP%\ico_extract_*" rd /s /q "%TEMP%\ico_extract_*" 2>nul
    
    REM Clean up any orphaned temp PNG files
    if exist "%TEMP%\*_temp*.png" del /q "%TEMP%\*_temp*.png" 2>nul

    REM Clean up any orphaned temp bat files
    if exist "%TEMP%\_magick_cmd_*.bat" del /q "%TEMP%\_magick_cmd_*.bat" 2>nul
    
    call :DebugLog "Cleanup completed."
goto :eof

:DebugLog
    REM Safely log to file, handling special characters
    setlocal enabledelayedexpansion
    set "logMessage=%~1"
    set "logMessage=!logMessage:<=^<!"
    set "logMessage=!logMessage:>=^>!"
    set "logMessage=!logMessage:&=^&!"
    set "logMessage=!logMessage:|=^|!"
    echo %date% @ %time% - !logMessage! >> "%debugLogFile%"
    endlocal
goto :eof


REM ============================================================================
REM ============================================================================
REM ==                   CONTEXT MENU INSTALLATION SECTION                    ==
REM ============================================================================
REM ============================================================================

:InstallContextMenu
    cls
    echo.
    echo ======================================================
    echo  Install Context Menu Integration
    echo ======================================================
    echo.
    
    REM Check if running as administrator
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Administrator privileges required!
        echo.
        echo Please right-click this script and select
        echo "Run as administrator" to install the context menu.
        echo.
        timeout /t 3 >nul
        goto :MainMenu
    )
    
    call :DebugLog "Installing to Program Files with context menu integration..."
    echo Installing to: %INSTALL_DIR%
    echo.
    
    REM Create installation directory
    echo Creating installation directory...
    if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" 2>nul
    if not exist "%INSTALL_RESOURCES%" mkdir "%INSTALL_RESOURCES%" 2>nul
    
    if not exist "%INSTALL_DIR%" (
        echo ERROR: Failed to create installation directory.
        echo.
        pause
        goto :MainMenu
    )
    
    REM ### MODIFIED SECTION START ###
    echo Copying script files...
    if "%ExeMode%"=="1" (
        REM Installer mode: copy the main tool from the 'resources' subfolder
        call :DebugLog "ExeMode=1: Looking for resources\IconWizard.bat to copy."
        set "sourceBat=%~dp0resources\IconWizard.bat"
        
        if not exist "!sourceBat!" (
            cls
            echo.
            echo   [FATAL ERROR]
            echo   'IconWizard.bat' not found in the 'resources' folder.
            echo.
            echo   When ExeMode is set to 1, this script acts as an installer
            echo   and requires 'IconWizard.bat' to be present in the
            echo   'resources' sub-folder.
            echo.
            pause
            goto :MainMenu
        )
        
        echo   Copying 'IconWizard.bat' from resources to Program Files...
        copy /Y "!sourceBat!" "%INSTALL_DIR%\IconWizard.bat" >nul 2>nul
    ) else (
        REM Standalone mode: copy the running script itself
        call :DebugLog "ExeMode=0: Copying self to Program Files."
        echo   Copying current script to Program Files...
        copy /Y "%~f0" "%INSTALL_DIR%\IconWizard.bat" >nul 2>nul
    )

    if errorlevel 1 (
        echo ERROR: Failed to copy the main script file.
        echo.
        pause
        goto :MainMenu
    )
    REM ### MODIFIED SECTION END ###

    REM Copy all resources
    echo Copying resource files...
    set "copyErrors=0"
    
    if exist "%resourcesPath%." (
        REM Copy all files AND folders from the local resources to the install resources
        xcopy "%resourcesPath%." "%INSTALL_RESOURCES%\" /E /Y /I /Q >nul 2>nul
        if errorlevel 1 set "copyErrors=1"
    )

    if "%copyErrors%"=="1" (
        echo.
        echo WARNING: Some files may not have copied correctly.
        echo The installation will continue, but some features may not work.
        echo.
    )
    
    set "scriptPath=%INSTALL_DIR%\IconWizard.bat"
    set "sourceIconPath=%INSTALL_RESOURCES%\icon.ico"
    
    REM Check if icon file exists for context menu
    if exist "%sourceIconPath%" (
        set "iconForMenu=%sourceIconPath%"
        call :DebugLog "Icon found for context menu: %sourceIconPath%"
    ) else (
        echo WARNING: Icon file not found. Context menu will be installed without an icon.
        set "iconForMenu="
        call :DebugLog "Icon file not found, installing without icon."
    )
    
    echo.
    echo Creating registry entries for context menu...
    
    REM --- Create registry entries for FOLDER context menu ---
    reg add "HKEY_CLASSES_ROOT\Directory\shell\SetFolderIcon" /ve /d "Change Folder &Icon" /f >nul 2>nul
    if defined iconForMenu (
        reg add "HKEY_CLASSES_ROOT\Directory\shell\SetFolderIcon" /v "Icon" /d "%iconForMenu%" /f >nul 2>nul
    )
    reg add "HKEY_CLASSES_ROOT\Directory\shell\SetFolderIcon\command" /ve /d "\"%scriptPath%\" \"%%1\"" /f >nul 2>nul
    
    REM Also add to directory background (when right-clicking inside a folder)
    reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\SetFolderIcon" /ve /d "Change Folder &Icon" /f >nul 2>nul
    if defined iconForMenu (
        reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\SetFolderIcon" /v "Icon" /d "%iconForMenu%" /f >nul 2>nul
    )
    reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\SetFolderIcon\command" /ve /d "\"%scriptPath%\" \"%%V\"" /f >nul 2>nul
    
    REM --- Create registry entries for FILE context menus (Image Converter) ---
    for %%E in (png jpg jpeg bmp gif svg ico exe webp) do (
        set "regKey=SystemFileAssociations\.%%E"
        if /i "%%E"=="exe" set "regKey=exefile"

        reg add "HKEY_CLASSES_ROOT\!regKey!\shell\ConvertImageConverter" /ve /d "&Icon File Converter" /f >nul 2>nul
        if defined iconForMenu ( reg add "HKEY_CLASSES_ROOT\!regKey!\shell\ConvertImageConverter" /v "Icon" /d "%iconForMenu%" /f >nul 2>nul )
        reg add "HKEY_CLASSES_ROOT\!regKey!\shell\ConvertImageConverter\command" /ve /d "\"%scriptPath%\" \"%%1\"" /f >nul 2>nul
    )
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to install context menu.
        echo Please ensure you have administrator privileges.
        call :DebugLog "Context menu installation FAILED."
    ) else (
        echo.
        echo ======================================================
        echo  SUCCESS! Installation completed.
        echo ======================================================
        echo.
        echo Installation location:
        echo %INSTALL_DIR%
        echo.
        echo You can now right-click any folder or supported
        echo file to access the Icon Wizard functions.
        echo.
        echo The original files can be safely deleted.
        echo.
        call :DebugLog "Installation and context menu setup completed successfully."
    )
    
    echo.
    pause
    goto :MainMenu

:UninstallContextMenu
    cls
    echo.
    echo ======================================================
    echo  Uninstall Context Menu Integration
    echo ======================================================
    echo.
    echo This will remove ALL context menu entries and delete
    echo the installation from Program Files.
    echo.
    echo NOTE: This requires Administrator privileges.
    echo.
    CHOICE /M "Are you sure you want to continue?"
    IF ERRORLEVEL 2 GOTO :MainMenu
    echo.
    
    REM Check if running as administrator
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Administrator privileges required!
        echo.
        echo Please right-click this script and select
        echo "Run as administrator" to uninstall the context menu.
        echo.
        pause
        goto :MainMenu
    )
    
    call :DebugLog "Uninstalling context menu integration and removing installation..."
    echo Uninstalling...
    echo.
    
    echo Removing registry entries...
    
    REM --- Remove registry entries for FOLDERS ---
    reg delete "HKEY_CLASSES_ROOT\Directory\shell\SetFolderIcon" /f >nul 2>nul
    reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\SetFolderIcon" /f >nul 2>nul
    
    REM --- Remove registry entries for FILES ---
    for %%E in (png jpg jpeg bmp gif svg ico exe webp) do (
        set "regKey=SystemFileAssociations\.%%E"
        if /i "%%E"=="exe" set "regKey=exefile"
        reg delete "HKEY_CLASSES_ROOT\!regKey!\shell\ConvertImageConverter" /f >nul 2>nul
    )
    reg delete "HKEY_CLASSES_ROOT\dllfile\shell\ConvertImageConverter" /f >nul 2>nul
    
    REM Remove installation directory if it exists
    if exist "%INSTALL_DIR%" (
        echo Removing installation directory...
        rd /s /q "%INSTALL_DIR%" 2>nul
        
        if exist "%INSTALL_DIR%" (
            echo WARNING: Could not completely remove installation directory.
            echo You may need to delete it manually: %INSTALL_DIR%
            call :DebugLog "Failed to delete installation directory."
        ) else (
            echo Installation directory removed successfully.
            call :DebugLog "Installation directory deleted successfully."
        )
    )
    
    echo.
    echo ======================================================
    echo  SUCCESS! Uninstallation completed.
    echo ======================================================
    echo.
    echo All context menu entries have been removed.
    echo.
    call :DebugLog "Context menu uninstallation completed successfully."
    
    echo.
    pause
    goto :MainMenu

:eof