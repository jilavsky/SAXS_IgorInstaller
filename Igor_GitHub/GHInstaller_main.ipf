#pragma TextEncoding = "UTF-8"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 1.11
#pragma IgorVersion = 8.03



Strconstant ksNameOfPackages ="Irena, Nika, and Indra"
Strconstant ksWebAddressForConfFile ="https://raw.githubusercontent.com/jilavsky/SAXS_IgorCode/master/"
Strconstant ksNameOfConfFile ="IgorInstallerConfig.xml"
strconstant strConstRecordwwwAddress="https://usaxs.xray.aps.anl.gov/staff/jan-ilavsky/IrenaNikaRecords/installrecord.php?"
Strconstant NameOfInstallMessageFile ="InstallMessage.ifn"

//1.11 critical upgrade, fix for bug in code which relies on bug in Igor behavior which will be fixed in Igor 8.05 and 9
//1.10 adds ability to delete folders on desktop
//1.09 adds better unzip for Windows 8 and 10. 
//1.08 added better messages for failed installations.
//1.05 fix location of new php file, increase Igor version need - rest of the code needs 7.05 or higher anyway. 
//1.05 adds Message from installer, promoted version requirement to 7.05  
//1.04 Addes recording of installation (method, packages, success etc) for statistical purposes.
//1.03 updated to handle better failed downloads of files from Github.
//1.02 Fixes to some paths which were causing issues unzipping files 
//1.0 promoted to 1.0, seems to work. 
//0.6 minor fix of support packages to handle two most common errors. 
//0.5 ready for beta release. 
//0.3 looks like first functioning version on Windows 10. 

//Universal installer using Github as source for installtions files. 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
Menu "Install Packages"
	"Open GitHub GUI", GHW_Start()
	help={"Open GUI to install packages from GitHub"}
end

//**************************************************************** 
//*********************************F******************************* 
//**************************************************************** 
//**************************************************************** 
Function GHW_Start()
	if (str2num(stringByKey("IGORVERS",IgorInfo(0)))<7.00)
			DoAlert /T="Important message :"  0, "This installer will work ONLY with Igor 7.00 or higher. Please, update your Igor before running this installer!"  
			BrowseURL "http://www.wavemetrics.com/support/versions.htm"
	else
		DoWIndow GH_MainPanel
		if(V_Flag)
			DoWIndow/K GH_MainPanel
		endif
		GHW_InitializeInstaller()
		GHW_DwnldConfFileAndScanLocal(0)
		GHW_PrepareGUIData()
		GHW_CreateMainpanel()
		GHW_GenerateHelp()
		GHW_GetAndDisplayUpdateMessage()
	endif

end
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
Function GHW_GetAndDisplayUpdateMessage()
		//checks for update message and if available, gets it and presents to user. 
		
	string FileContent
	string ConfigFileURL=ksWebAddressForConfFile+NameOfInstallMessageFile
	URLRequest/Z/TIME=2 url=ConfigFileURL
	if (V_Flag != 0)
		print "Could not get Install message file from server."
		return 0
	endif
	FileContent =  S_serverResponse
	variable refNum
	NewPath/O/C/Q TempUserUpdateMessage, SpecialDirPath("Temporary",0,0,0)
	Open/P=TempUserUpdateMessage  refNum as NameOfInstallMessageFile
	FBinWrite refNum, FileContent
	Close refNum
	OpenNotebook/k=1/N=MessageFromAuthor/P=TempUserUpdateMessage/Z NameOfInstallMessageFile
   return 1
end

//**************************************************************** 
//**************************************************************** 
//**************************************************************** 

Function GHW_CreateMainpanel()

	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(131,111,733,450) as "Install/Unistall Packages"
	DoWindow/C GH_MainPanel
	//ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 20,fstyle= 3,textrgb= (1,4,52428)
	DrawText 101,25,"Install/Uninstall Igor packages hosted on Github"
	DrawText 11,45,"This Igor experiment enables user to manage "+ksNameOfPackages+" packages" 
	Button CheckVersions,pos={10,50},size={200,20},proc=GHW_ButtonProc,title="Check packages versions"
	Checkbox DisplayBetaReleases, pos={5,77}, size={100,20}, variable = root:Packages:GHInstaller:DisplayBetaReleases, proc=GHW_CheckProc
	Checkbox DisplayBetaReleases, help={"Check to display beta releases?"}, title="  Include Beta releases in list?"
	Checkbox UseLocalFolder, pos={250,50}, size={100,20}, variable = root:Packages:GHInstaller:UseLocalFolder, proc=GHW_CheckProc
	Checkbox UseLocalFolder, help={"Check to use Local Folder?"}, title="  Use Local folder?"
	PopupMenu SelectReleaseToInstall,pos={233.00,75.00},size={231.00,23.00},bodyWidth=120,proc=GHW_PopMenuProc,title="Select Release to Install:"
	PopupMenu SelectReleaseToInstall,help={"Select release to install"}
	PopupMenu SelectReleaseToInstall,mode=1,value= #"root:Packages:GHInstaller:PopListOfReleaseNames"
	SetVariable ReleaseNotes variable = root:Packages:GHInstaller:ReleaseNotes
	SetVariable ReleaseNotes pos={10,98},size={570,18},disable=2
	ListBox InstallationSelection,pos={10.00,120.00},size={362.00,177.00}
	ListBox InstallationSelection,listWave=root:Packages:GHInstaller:VersionsAndInstall
	ListBox InstallationSelection,selWave=root:Packages:GHInstaller:SelVersionsAndInstall
	ListBox InstallationSelection,mode= 8,userColumnResize= 1

	Button GetHelp,pos={480,45},size={110,20},proc=GHW_ButtonProc,title="Get Help"
	Button InstallPackages,pos={390,126},size={200,20},proc=GHW_ButtonProc,title="Install/Update Selected", fColor=(16386,65535,16385)
	Button UninstallPackages,pos={390,155},size={200,20},proc=GHW_ButtonProc,title="Uninstall Selected", fColor=(16386,65535,16385)

	Button OpenWebSIte,pos={390,200},size={200,18},proc=GHW_ButtonProc,title="Ilavsky Web site"
	Button OpenGitHub,pos={390,230},size={200,18},proc=GHW_ButtonProc,title="Github depository"
	Button SignupIrena,pos={390,260},size={200,18},proc=GHW_ButtonProc,title="Sign up for Irena mailing list"
	Button SignUpNika,pos={390,290},size={200,18},proc=GHW_ButtonProc,title="Sign up for Nika mailing list"
//
	DrawText 5,320,"Version 1.08 of Github Installer, JIL."
	DrawText 5,335,"Please, check the web site for latest version before using." 
end
//**************************************************************** 
//**************************************************************** 
//**************************************************************** //**************************************************************** 
//**************************************************************** 
//**************************************************************** 

Function GHW_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	NVAR DisplayBetaReleases = root:Packages:GHInstaller:DisplayBetaReleases

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(stringmatch(cba.ctrlName,"DisplayBetaReleases"))
				GHW_PrepareGUIData()
				//Inst_CheckForLocalCopyPresence()
			endif
			if(stringmatch(cba.ctrlName,"UseLocalFolder"))
				SVAR LocalFolderPath	=	root:Packages:GHInstaller:LocalFolderPath
				NVAR UseLocalFolder	=	root:Packages:GHInstaller:UseLocalFolder
				NVAR DisplayBetaReleases = root:Packages:GHInstaller:DisplayBetaReleases
				if(checked)
					PathInfo/S userDesktop 
					NewPath /M="Select Location of Folder with data downloaded from GitHub"  /O/Q LocalInstallationFolder  
					PathInfo LocalInstallationFolder 
					LocalFolderPath = S_path
					DisplayBetaReleases = 0
				else
					KillPath/Z LocalInstallationFolder
				endif
				GHW_DwnldConfFileAndScanLocal(1)
				GHW_PrepareGUIData()
				//Inst_CheckForLocalCopyPresence()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 

Function GHW_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//check Igor Pro version and bail out if not higher than 7.00
			string IgorInfoStr=IgorInfo(0)
			if(IgorVersion()<7.00)
				Abort "This code requires Igor 7.00 or higher, please update your Igor Pro."
			endif
			
			if(stringMatch(ba.ctrlName,"CheckVersions"))
				GHW_DwnldConfFileAndScanLocal(1)
				GHW_PrepareGUIData()
			endif

			if(stringMatch(ba.ctrlName,"InstallPackages"))	
				if(GHW_IsThereWhatToDo())
					GHW_Install()	
					GHW_DwnldConfFileAndScanLocal(1)
					GHW_PrepareGUIData()
				else
					DoALert 0, "Nothing to do, select some packages to install"
				endif
			endif
			
			if(stringMatch(ba.ctrlName,"OpenWebSite"))			
				BrowseURL "http://usaxs.xray.aps.anl.gov/staff/ilavsky/index.html"
			endif
			if(stringMatch(ba.ctrlName,"OpenGitHub"))			
				BrowseURL "https://github.com/jilavsky/SAXS_IgorCode"
			endif
			if(stringMatch(ba.ctrlName,"SignupIrena"))			
				BrowseURL "http://www.aps.anl.gov/mailman/listinfo/irena_users"
			endif
			if(stringMatch(ba.ctrlName,"SignUpNika"))			
				BrowseURL "http://www.aps.anl.gov/mailman/listinfo/nika_users"
			endif


			if(stringMatch(ba.ctrlName,"UninstallPackages"))
				if(GHW_IsThereWhatToDo())
					GHW_Uninstall()
					GHW_DwnldConfFileAndScanLocal(1)
					GHW_PrepareGUIData()
				else
					DoALert 0, "Nothing to do, select some packages to uninstall"
				endif
			endif
						
			if(stringMatch(ba.ctrlName,"GetHelp"))
				GHW_GenerateHelp()
			endif
			
			break
	endswitch

	return 0
End
//**************************************************************** 
Function GHW_IsThereWhatToDo()
	Wave SelVersionsAndInstall = root:Packages:GHInstaller:SelVersionsAndInstall	
	variable NumPckgs = DimSize(SelVersionsAndInstall, 0 )
	variable i, result
	result = 0
	for(i=0;i<NumPckgs;i+=1)
		result += SelVersionsAndInstall[i][3] > 32 ? 1 : 0
	endfor
	
	return result 

end//**************************************************************** 
//**************************************************************** 
Function GHW_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			if(StringMatch(pa.ctrlName, "SelectReleaseToInstall"))
				//fix something here... 
				SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
				SelectedReleaseName = popStr
				GHW_PrepareListboxGUIData()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
static Function GHW_ListIgorProcFiles()
	GetFileFolderInfo/Q/Z/P=Igor "Igor Procedures"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path,1 )
	endif
	GetFileFolderInfo/Q/Z GHW_GetIgorUserFilesPath()+"Igor Procedures:"
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Procedures:",0)
	endif
	KillPath/Z tempPath
end
 //**************************************************************** 
//**************************************************************** 
 //**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
static Function GHW_ListIgorExtensionsFiles()
	GetFileFolderInfo/Q/Z/P=Igor "Igor Extensions"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path, 1)
	endif
	GetFileFolderInfo/Q/Z (GHW_GetIgorUserFilesPath()+"Igor Extensions:")
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Extensions:",0)
	endif
	KillPath/Z tempPath
end

//**************************************************************** 
//**************************************************************** 
static Function /S GHW_Windows2IgorPath(pathIn)
	String pathIn
	String pathOut = ParseFilePath(5, pathIn, ":", 0, 0)
	return pathOut
End

static Function/S GHW_GetIgorUserFilesPath()
	// This should be a Macintosh path but, because of a bug prior to Igor Pro 6.20B03
	// it may be a Windows path.
	String path = SpecialDirPath("Igor Pro User Files", 0, 0, 0)
	path = GHW_Windows2IgorPath(path)
	return path
End
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
static Function GHW_ListProcFiles(PathStr, resetWaves)
	string PathStr
	variable resetWaves
	
	String abortMessage	//HR Used if we have to abort because of an unexpected error
	
	string OldDf=GetDataFolder(1)
	//create location for the results waves...
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:UseProcedureFiles
	//if this is top call to the routine we need to wipe out the waves so we remove old junk
	string CurFncName=GetRTStackInfo(1)
	string CallingFncName=GetRTStackInfo(2)
	variable runningTopLevel=0
	if(!stringmatch(CurFncName,CallingFncName))
		runningTopLevel=1
	endif
	if(resetWaves)
			Make/O/N=0/T FileNames		
			Make/O/N=0/T PathToFiles
			Make/O/N=0 FileVersions
	endif
	
	
	//if this was first call, now the waves are gone.
	//and now we need to create the output waves
	Wave/Z/T FileNames
	Wave/Z/T PathToFiles
	Wave/Z FIleVersions
	If(!WaveExists(FileNames) || !WaveExists(PathToFiles) || !WaveExists(FIleVersions))
		Make/O/T/N=0 FileNames, PathToFIles
		Make/O/N=0 FileVersions
		Wave/T FileNames
		Wave/T PathToFiles
		Wave FileVersions
		//I am not sure if we really need all of those declarations, but, well, it should not hurt...
	endif 
	string str
	//this is temporary path to the place we are looking into now...  
	NewPath/Q/O tempPath, PathStr
	if (V_flag != 0)		//HR Add error checking to prevent infinite loop
		sprintf abortMessage, "Unexpected error creating a symbolic path pointing to \"%s\"", PathStr
		str= abortMessage	// To make debugging easier
		//Inst_Append2Log(str,0)
		Abort abortMessage
	endif

	//list al items in this path
	string ItemsInTheFolder= IndexedFile(tempPath,-1,"????")+IndexedDir(tempPath, -1, 0 )	
	//HR If there is a shortcut in "Igor Procedures", ItemsInTheFolder will include something like "HDF5 Browser.ipf.lnk". Windows shortcuts are .lnk files.	
	//remove all . files. 
	ItemsInTheFolder = GrepList(ItemsInTheFolder, "^\." ,1)
	//Now we removed all junk files on Macs (starting with .)
	//now lets check what each of these files are and add to the right lists or follow...
	variable i, imax=ItemsInList(ItemsInTheFolder)
	string tempFileName, tempScraptext, tempPathStr
	variable IamOnMac, isItXOP
	if(stringmatch(IgorInfo(2),"Windows"))
		IamOnMac=0
	else
		IamOnMac=1
	endif
	For(i=0;i<imax;i+=1)
		tempFileName = stringfromlist(i,ItemsInTheFolder)
		GetFileFolderInfo/Z/Q/P=tempPath tempFileName
		isItXOP = IamOnMac * stringmatch(tempFileName, "*xop*" )
		
		if(V_isAliasShortcut)
			//HR If tempFileName is "HDF5 Browser.ipf.lnk", or any other shortcut to a file, S_aliasPath is a path to a file, not a folder.
			//HR Thus the "NewPath tempPath" command will fail.
			//HR Thus tempPath will retain its old value, causing you to recurse the same folder as before, resulting in an infinite loop.
			
			//is alias, need to follow and look further. Use recursion...
			if(strlen(S_aliasPath)>3)		//in case user has stale alias, S_aliasPath has 0 length. Need to skip this pathological case. 
				//HR Recurse only if S_aliasPath points to a folder. I don't really know what I'm doing here but this seems like it will prevent the infinite loop.
				GetFileFolderInfo/Z/Q/P=tempPath S_aliasPath	
				isItXOP = IamOnMac * stringmatch(S_aliasPath, "*xop*" )
				if (V_flag==0 && V_isFolder&&!isItXOP)		//this is folder, so all items in the folder are included... Except XOP is folder too... 
					GHW_ListProcFiles(S_aliasPath, 0)
				elseif(V_flag==0 && (!V_isFolder || isItXOP))	//this is link to file. Need to include the info on the file...
					//*************
					Redimension/N=(numpnts(FileNames)+1) FileNames, PathToFiles,FileVersions
					tempFileName =stringFromList(ItemsInList(S_aliasPath,":")-1, S_aliasPath,":")
					tempPathStr = RemoveFromList(tempFileName, S_aliasPath,":")
					FileNames[numpnts(FileNames)-1] = tempFileName
					PathToFiles[numpnts(FileNames)-1] = tempPathStr
					//try to get version from #pragma version = ... This seems to be the most robust way I found...
					NewPath/Q/O tempPath, tempPathStr
					if(stringmatch(tempFileName, "*.ipf"))
						Grep/P=tempPath/E="(?i)^#pragma[ ]*version[ ]*=[ ]*" tempFileName as "Clipboard"
						sleep/s (0.02)
						tempScraptext = GetScrapText()
						if(strlen(tempScraptext)>10)		//found line with #pragma version"
							tempScraptext = replaceString("#pragma",tempScraptext,"")	//remove #pragma
							tempScraptext = replaceString("version",tempScraptext,"")		//remove version
							tempScraptext = replaceString("=",tempScraptext,"")			//remove =
							tempScraptext = replaceString("\t",tempScraptext,"  ")			//remove optional tabulators, some actually use them. 
							tempScraptext = removeending(tempScraptext," \r")			//remove optional tabulators, some actually use them. 
							//forget about the comments behind the text. 
		                                       //str2num is actually quite clever in this and converts start of the string which makes sense. 
							FileVersions[numpnts(FileNames)-1]=str2num(tempScraptext)
						else             //no version found, set to NaN
							FileVersions[numpnts(FileNames)-1]=NaN
						endif
					else                    //no version for non-ipf files
						FileVersions[numpnts(FileNames)-1]=NaN
					endif
					//************
				endif
			endif
			//and now when we got back, fix the path definition to previous or all will crash...
			NewPath/Q/O tempPath, PathStr
			if (V_flag != 0)		//HR Add error checking to prevent infinite loop
				sprintf abortMessage, "Unexpected error creating a symbolic path pointing to \"%s\"", PathStr
				str= abortMessage	// To make debugging easier
			//	Inst_Append2Log(str,0)
				Abort abortMessage
			endif
		elseif(V_isFolder&&!isItXOP)	
			//is folder, need to follow into it. Use recursion.
			GHW_ListProcFiles(PathStr+tempFileName+":", 0)
			//and fix the path back or all will fail...
			NewPath/Q/O tempPath, PathStr
			if (V_flag != 0)		//HR Add error checking to prevent infinite loop
				sprintf abortMessage, "Unexpected error creating a symbolic path pointing to \"%s\"", PathStr
				str= abortMessage	// To make debugging easier
			//	Inst_Append2Log(str,0)
				Abort abortMessage
			endif
		elseif(V_isFile||isItXOP)
			//this is real file. Store information as needed. 
			Redimension/N=(numpnts(FileNames)+1) FileNames, PathToFiles,FileVersions
			FileNames[numpnts(FileNames)-1] = tempFileName
			PathToFiles[numpnts(FileNames)-1] = PathStr
			//try to get version from #pragma version = ... This seems to be the most robust way I found...
			if(stringmatch(tempFileName, "*.ipf"))
				Grep/P=tempPath/E="(?i)^#pragma[ ]*version[ ]*=[ ]*" tempFileName as "Clipboard"
				sleep/s(0.02)
				tempScraptext = GetScrapText()
				if(strlen(tempScraptext)>10)		//found line with #pragma version"
					tempScraptext = replaceString("#pragma",tempScraptext,"")	//remove #pragma
					tempScraptext = replaceString("version",tempScraptext,"")		//remove version
					tempScraptext = replaceString("=",tempScraptext,"")			//remove =
					tempScraptext = replaceString("\t",tempScraptext,"  ")			//remove optional tabulators, some actually use them. 
					//forget about the comments behind the text. 
                                       //str2num is actually quite clever in this and converts start of the string which makes sense. 
					FileVersions[numpnts(FileNames)-1]=str2num(tempScraptext)
				else             //no version found, set to NaN
					FileVersions[numpnts(FileNames)-1]=NaN
				endif
			else                    //no version for non-ipf files
				FileVersions[numpnts(FileNames)-1]=NaN
			endif
		endif
	endfor 
	setDataFolder OldDf
end


//***********************************
//***********************************
//***********************************
//***********************************

//static 
Function GHW_FileFolderExists(name,[path,file,folder])	// returns 1=exists, 0=does not exist
	String name					// partial or full file name or folder name
	String path					// optional path name, e.g. "home"
	Variable file,folder	// flags, if both set or both unset, it checks for either
	path = SelectString(ParamIsDefault(path),path,"")
	file = ParamIsDefault(file) ? 0 : file
	file = numtype(file) ? 0 : !(!file)
	folder = ParamIsDefault(folder) ? 0 : folder
	folder = numtype(folder) ? 0 : !(!folder)

	if (!file && !folder)	// check for either
		file = 1
		folder = 1
	endif

	if (strlen(path))
		PathInfo $path
		if (V_flag==0)
			return 0
		endif
		name = S_path+name	// add the path to name
	endif

	GetFileFolderInfo/Q/Z=1 name
	Variable found=0
	found = found || (file ? V_isFile : 0)
	found = found || (folder ? V_isFolder : 0)
	return found
End
