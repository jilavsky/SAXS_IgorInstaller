#pragma TextEncoding = "UTF-8"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma version = 0.3

//0.3 added lots of new functionality and was tested on Windows 10
//0.2 added functions to load IgorInstallerConfig.xml and parse the content into text waves in Igor
//0.1 Added and modified XML code. Code from ALways_First.ipf by Jon Tischler. Functions renamed to protect name space.  
//			added support for reading and extracting infomrmation from specific form ox xml configuration file.  

// this is support package for installer of Igor Pro software from Github 
//Function GHW_ReadConfigurationFile()					this function scans and generates lists of data. 



//Known keywords:
//VersionCheck/KnownPackages
//					/current_release, current_beta_release
//InstallerConfig/release
//							SourceFileAddress
//							Package/name, version, PackageList, VersionCheckFile

//<?xml version="1.0" encoding="UTF-8" ?>
// 
//<IgorInstaller>
//			<!--
//				The structure of this file "IgorInstallerConfig.xml" is used to define Installer functionality.
//				Its name is fixed in the code. Its location is something similar to this:
//				"http://raw.githubusercontent.com/jilavsky/SAXS_IgorCode/master/"		
//				VersionCheck defines what the known packages are and what the current releases are
//				InstallerConfig lists for each release for all packages : version, PackageList (contains list of paths and files to be copied
//				and version check file (file in which code will look for #pragma version =)
//				-->
//	<VersionCheck>
//		<KnownPackages>
//			<Package>Irena</Package>
//			<Package>Nika</Package>
//			<Package>Indra</Package>
//			<Package>xop</Package>
//		</KnownPackages>
//		<current_release>March2016</current_release>
//		<current_beta_release>March2016_2</current_beta_release>
//	</VersionCheck>
//
//	<InstallerConfig>
//		<release name="March2016">
//			<SourceFileAddress>https://github.com/jilavsky/SAXS_IgorCode/archive/TestVersion.zip</SourceFileAddress>
//			<Package>
//				<name>Irena</name>
//				<version>2.62</version>
//				<PackageList>IrenaPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Irena1 modeling.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>Nika</name>
//				<version>1.5</version>
//				<PackageList>NikaPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Nika.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>Indra</name>
//				<version>1.88</version>
//				<PackageList>IndraPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Indra2.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>xop</name>
//				<version></version>
//				<PackageList>xopPckg.xml</PackageList>
//				<VersionCheckFile></VersionCheckFile>
//			</Package>
//			<VersionComment>Added Panel Scaling</VersionComment>
//		</release>
//		<release name="March2016_2" beta="true">
//			<SourceFileAddress>https://github.com/jilavsky/SAXS_IgorCode/archive/TestVersion.zip</SourceFileAddress>
//			<Package>
//				<name>Irena</name>
//				<version>2.62</version>
//				<PackageList>IrenaPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Irena1 modeling.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>Nika</name>
//				<version>1.5</version>
//				<PackageList>NikaPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Nika.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>Indra</name>
//				<version>1.88</version>
//				<PackageList>IndraPckg.xml</PackageList>
//				<VersionCheckFile>/Igor Procedures/Boot Indra2.ipf</VersionCheckFile>
//			</Package>
//			<Package>
//				<name>xop</name>
//				<version></version>
//				<PackageList>xopPckg.xml</PackageList>
//				<VersionCheckFile></VersionCheckFile>
//			</Package>
//			<VersionComment>Added Panel Scaling</VersionComment>
//		</release>
//	</InstallerConfig>
//</IgorInstaller>

//  ======================================================================================  //
Function GHW_DwnldConfFileAndScanLocal()
//this function scans and provides list of available releases. 
	if(!DataFolderExists("root:Packages:GHInstaller"))
		GHW_InitializeInstaller()
	endif
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller
	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
	Wave/T ListOfPackages = root:Packages:GHInstaller:ListOfPackages
	NVAR UseLocalFolder = root:Packages:GHInstaller:UseLocalFolder
	Redimension/N=(0,3) ListOfReleases
	Redimension/N=0 ListOfPackages
	SVAR CurrentReleaseName = root:Packages:GHInstaller:CurrentReleaseName
	SVAR CurrentBetaReleaseName = root:Packages:GHInstaller:CurrentBetaReleaseName
	SVAR ListOfReleaseNames = root:Packages:GHInstaller:ListOfReleaseNames
	SVAR ListOfBetaReleaseNames = root:Packages:GHInstaller:ListOfBetaReleaseNames
	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
	SVAR LocalFolderPath = root:Packages:GHInstaller:LocalFolderPath
	variable fileID
	string FileContent=""
	GHW_DownloadWarning()
	
	if(UseLocalFolder)
		GUIReportActivityForUser = "Reading Configuration from local folder"
		//source is local folder
		String FileNameWithPath=LocalFolderPath+ksNameOfConfFile
		//check for the file to exists
		GetFileFolderInfo/Z/Q FileNameWithPath
		if(V_Flag!=0)	//error, not found
			GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+"Did not find necessary configuration file "+FileNameWithPath, abortProgress=1)
		endif
		FileContent = PadString(FileContent, V_logEOF, 0x20 )
		Open fileID  as FileNameWithPath
		FBinRead fileID, FileContent
		close fileID
	else		//web is the source	
		GUIReportActivityForUser = "Downloading Configuration from GitHub"
		DoUpdate /W=DownloadWarning
		string ConfigFileURL=ksWebAddressForConfFile+ksNameOfConfFile
		URLRequest url=ConfigFileURL
		Variable error = GetRTError(1)
		if (error != 0)
			DoWIndow/K DownloadWarning
			GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+"Error downloading data "+ConfigFileURL, abortProgress=1)
		endif
		FileContent =  S_serverResponse
	endif
	//print FileContent
	FileContent=GHI_XMLremoveComments(FileContent)		//get rid of comments, confuse rest of the code... 
	//FileContent now contains content of the file...
	string InstallerText=GHI_XMLtagContents("IgorInstaller",FileContent)	//if nothing, wrong format
	if(strlen(InstallerText)<10)	//no real content
		DoWIndow/K DownloadWarning
		SetDataFolder saveDFR					// Restore current data folder
		GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+" Installer text too short", abortProgress=1)
	endif
	//list all Installable files here so we have cache of them.
	GHW_MakeRecordOfProgress( "Recording local installed files, this may take a while")
	GHW_ListAllInstallableFiles()
	DoWIndow/K DownloadWarning
	//get what are the names of packages we should be able to find
	GHW_ListPackagesName(InstallerText, ListOfPackages)
	CurrentReleaseName = GHW_GetCurrentRelease(InstallerText)
	CurrentBetaReleaseName = GHW_GetCurrentBetaRelease(InstallerText)
	GHW_ListReleases(FileContent, ListOfReleases)
	//Parse these for further use by GUI
	ListOfReleaseNames=""
	ListOfBetaReleaseNames=""
	variable i
	For(i=0;i<dimsize(ListOfReleases,0);i+=1)
		if(StringMatch(ListOfReleases[i][1], "normal" ))
			ListOfReleaseNames+=ListOfReleases[i][0]+";"
		elseif(StringMatch(ListOfReleases[i][1], "beta" ))
			ListOfBetaReleaseNames+=ListOfReleases[i][0]+";"
		endif
	endfor
	//and now we have all data from XML file in Igor as Igor waves/strings.  
	SetDataFolder saveDFR					// Restore current data folder
end 
//  ======================================================================================  //
//**************************************************************** 
//**************************************************************** 
Function GHW_DownloadWarning() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/N=DownloadWarning /W=(153,101,502,259) as "The code is working"
	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,textrgb= (65535,0,0)
	DrawText 131,37,"Installer is :"
	SetDrawEnv fsize= 16,textrgb= (65535,0,0)
	DrawText 94,101,"This may take a while"
	SetDrawEnv fsize= 16,textrgb= (65535,0,0)
	DrawText 40,133,"This window will disapper when done"
	SetVariable UserMessage,pos={26.00,49.00},size={290.00,17.00},title="Info: "
	SetVariable UserMessage,fSize=11,fStyle=1,valueColor=(65535,0,0)
	SetVariable UserMessage,value= root:Packages:GHInstaller:GUIReportActivityForUser,noedit= 1
EndMacro

//  ======================================================================================  //
Function GHW_InitializeInstaller()
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:GHInstaller
	make/O/N=(0,3)/T ListOfReleases	//0 will be "release", 1 normal or beta, 2 content of all tags as kw=list;
	make/O/N=0/T ListOfPackages
	string/g CurrentReleaseName
	string/g SelectedReleaseName
	string/g PopListOfReleaseNames
	string/g ListOfReleaseNames
	string/g ListOfBetaReleaseNames
	string/g CurrentBetaReleaseName
	string/g GUIReportActivityForUser
	String/g ReleaseNotes
  	variable/g DisplayBetaReleases
  	variable/g UseLocalFolder
  	string/g LocalFolderPath
 	SetDataFolder saveDFR					// Restore current data folder
end
//  ======================================================================================  //
Function/T GHW_GetCurrentRelease(str)
	string str
	string VersionCheckStr
	VersionCheckStr = GHI_XMLtagContents("VersionCheck",str)
	return GHI_XMLtagContents("current_release",VersionCheckStr)
end
//  ======================================================================================  //
Function/T GHW_GetCurrentBetaRelease(str)
	string str
	string VersionCheckStr
	VersionCheckStr = GHI_XMLtagContents("VersionCheck",str)
	return GHI_XMLtagContents("current_beta_release",VersionCheckStr)
end
//  ======================================================================================  //
Function GHW_ListPackagesName(str, tw)
	string str
	wave/T tw
	Variable start=0
	string result = ""
	string VersionCheckStr, PackagesStr	
	VersionCheckStr = GHI_XMLtagContents("VersionCheck",str)
	PackagesStr = GHI_XMLtagContents("KnownPackages",VersionCheckStr)
	String feed
	do
		feed = GHI_XMLtagContents("Package",PackagesStr, start=start)
		if(strlen(feed)>0)
			Redimension/N=(dimsize(tw,0)+1) tw
			tw[dimsize(tw,0)-1] = feed
		endif
	while(strlen(feed))
	return 1
end
//  ======================================================================================  //
Function/T GHW_ListPlatformSpecificValues(str, Key, Platform)
	string str, Key, Platform
	
	string WholeContent, ListOfNodes, ListOfRequestedKeys
	WholeContent = GHI_XMLtagContents("PackageContent",str)
	ListOfNodes = GHI_XMLNodeList(WholeContent)		//all nodes on this level
	ListOfRequestedKeys = GrepList(ListOfNodes, Key )		//just the ones called what we want this time
	string KeyAttribs, KeyStr, ResultingList
	ResultingList=""
	variable i, j
	for(i=0;i<ItemsInList(ListOfRequestedKeys);i+=1)
		KeyAttribs = GHI_XMLattibutes2KeyList(Key,WholeContent,occurance=i)
		//choices: "", "os=Windows", "os=Macintosh", "os=all"
		//Platform: "Windows" or "Macintosh", both include "" or "all" 
		KeyStr = GHI_XMLtagContents(Key,WholeContent,occurance=i)
		if(strlen(KeyAttribs)<3 || stringmatch(StringByKey("os", KeyAttribs, "=", ";"),"all"))
			ResultingList += KeyStr+";"
		endif
		if(stringmatch(StringByKey("os", KeyAttribs, "=", ";"),Platform))
			ResultingList += KeyStr+";"
		endif

	endfor
	return ResultingList
end
//  ======================================================================================  //
Function/T GHW_ListReleases(str, Releasetw)
	string str
	wave/T Releasetw
	
	Redimension/N=(0,3) Releasetw
	variable rel_i, beta_i
	rel_i = 0
	string InstallerConfigStr, ListOfReleases
	InstallerConfigStr = GHI_XMLtagContents("InstallerConfig",str)
	ListOfReleases = GHI_XMLNodeList(InstallerConfigStr)		//all nodes on this level
	ListOfReleases = GrepList(ListOfReleases, "release")		//just the ones called release
	string ReleaseAttribs, ReleaseStr, ListOfTags, TagList, Curtag
	variable i, j
	for(i=0;i<ItemsInList(ListOfReleases);i+=1)
		ReleaseAttribs = GHI_XMLattibutes2KeyList("release",InstallerConfigStr,occurance=i)
		ReleaseStr = GHI_XMLtagContents("release",InstallerConfigStr,occurance=i)
		ListOfTags = GHI_XMLNodeList(ReleaseStr)
		TagList=GHW_ReadReleaseContent(ReleaseStr)
		rel_i+=1
		redimension/N=(rel_i,3) Releasetw
		Releasetw[rel_i-1][0]=StringByKey("name", ReleaseAttribs,"=")
		if(Stringmatch(StringByKey("beta", ReleaseAttribs,"="),"true"))
			Releasetw[rel_i-1][1]= "beta"
		else
			Releasetw[rel_i-1][1]= "normal"
		endif 
		Releasetw[rel_i-1][2]=TagList
	endfor
end
//  ======================================================================================  //
Function/T GHW_ReadReleaseContent(Str)
	string Str
		
	string Content=""
	variable i, j
	string tempStr, tmpList
	string ListOfTags=GHI_XMLNodeList(Str)
	string ListOfPackages, ListOfOtherStuff
	//ListOfOtherStuff = GrepList(ListOfTags, "^((?.release).)*$")
	ListOfOtherStuff = GrepList(ListOfTags, "Package",1)
	ListOfPackages = GrepList(ListOfTags,"Package")
	For(i=0;i<ItemsInList(ListOfPackages);i+=1)
		tempStr=GHI_XMLtagContents(stringFromList(i,ListOfPackages),Str, occurance=i)
		Content+=GHW_ReadPackageContent(tempStr)
	endfor	

	For(i=0;i<ItemsInList(ListOfOtherStuff);i+=1)
		tempStr=GHI_XMLtagContents(stringFromList(i,ListOfOtherStuff),Str)
		Content+=StringFromList(i,ListOfOtherStuff)+"="+tempStr+";"
	endfor	
	return Content
end
//  ======================================================================================  //
Function/T GHW_ReadPackageContent(Str)
	string Str
		
	string Content=""
	variable i, j
	string tempStr, tmpList, PackageName
	string ListOfTags=GHI_XMLNodeList(Str)
	string ListOfOtherStuff=RemoveFromList("name", ListOfTags)
	ListOfOtherStuff=RemoveFromList("version", ListOfOtherStuff)
	PackageName=GHI_XMLtagContents("name",Str)
	Content+=PackageName+"="+GHI_XMLtagContents("version",Str)+";"

	For(i=0;i<ItemsInList(ListOfOtherStuff);i+=1)
		tempStr=GHI_XMLtagContents(stringFromList(i,ListOfOtherStuff),Str)
		Content+=PackageName+"_"+StringFromList(i,ListOfOtherStuff)+"="+tempStr+";"
	endfor	
	return Content
end
//  ======================================================================================  //
Function/T GHW_ListFilesInPckgList(Str)
	string Str
		
	string Content=""
	variable i, j
	string tempStr, tmpList, PackageName, buf
	buf = GHI_XMLtagContents("PackageContent",Str)
	//print buf
	Variable start=0
	String feed
	do
		feed = GHI_XMLtagContents("File",buf, start=start)
		//print feed
		Content += feed+";"
	while(strlen(feed))
	return Content
end


//  ======================================================================================  //
//  ======================================================================================  //
//  ================================ Start of Generic XML ================================  //
//
//	XML support	 (occurance optionally allows selecting the the occuranceth instance of xmltag), note vectors usually delimited by a space
//
//	GHI_XMLNodeList(buf)											returns a list with all top level nodes in buf
//	GHI_XMLtagContents(xmltag,buf,[occurance])				returns the contents of xmltag
//	GHI_XMLtagContents2List(xmltag,buf,[occurance,delimiters])	returns the contents of xmltag as a list, useful for vectors in the contents
//	GHI_XMLattibutes2KeyList(xmltag,buf)						return a list with all of the attribute value pairs for xmltag
//	GHI_XMLremoveComments(str)									remove all xml comments from str
//
//	for GHI_XMLtagContents() and GHI_XMLattibutes2KeyList()
// when there are MANY occurances of xmltag, do not use occurance, but rather:
//	Variable start=0
//	String feed
//	do
//		feed = GHI_XMLtagContents("feed",buf, start=start)
//		other code goes here ...
//	while(strlen(feed))

ThreadSafe Function/T GHI_XMLNodeList(buf)			// returns a list of node names at top most level in buf
	String buf
	String name,nodes=""
	Variable i0=0, i1,i2
	do
		i0 = strsearch(buf,"<",i0)					// find start of a tag
		if (i0<0)
			break
		endif
		i1 = strsearch(buf," ",i0)					// find end of tag name using i1 or i2, end will be in i1
		i1 = i1<0 ? Inf : i1
		i2 = strsearch(buf,">",i0)
		i2 = i2<0 ? Inf : i2
		i1 = min(i1,i2)
		if (numtype(i1) || (i1-i0-1)<1)
			break
		endif
		name = ReplaceString(";",buf[i0+1,i1-1],"_")// name cannot contain semi-colons
		nodes += name+";"

		i2 = strsearch(buf,"</"+name+">",i0)		// find the closer for this tag, check for '</name>'
		if (i2<0)
			i0 = strsearch(buf,">",i1+1)				// no '</name>', just a simple node
		else
			i0 = i2 + strlen(name) + 3				// first character after '</name>'
		endif
	while(i0>0)
	return nodes
End

//ThreadSafe
 Function/T GHI_XMLtagContents(xmltag,buf,[occurance,start])
	String xmltag
	String buf
	Variable occurance									// use 0 for first occurance, 1 for second, ...
	Variable &start										// offset in buf, start searching at buf[start], new start is returned
																// both occurance and start may be used together, but usually you only want to use one of them
	occurance = ParamIsDefault(occurance) ? 0 : occurance
	Variable startLocal = ParamIsDefault(start) ? 0 : start
	startLocal = numtype(startLocal) || startLocal<1 ? 0 : round(startLocal)

	Variable i0,i1
	if (startLocal>0)
		i0 = GHI_startOfxmltag(xmltag,buf[startLocal,Inf],occurance) + startLocal
	else
		i0 = GHI_startOfxmltag(xmltag,buf,occurance)
	endif
	if (i0<0)
		return ""
	endif
	i0 = strsearch(buf,">",i0)						// character after '>' in intro
	if (i0<0)												// this is an ERROR
		return ""
	endif
	i0 += 1													// start of contents

	i1 = strsearch(buf,"</"+xmltag+">",i0)-1	// character just before closing '<tag>'
	startLocal = strsearch(buf,">",i1)+1			// character just after closing '<tag>'

	if (i1<i0 || i1<0)
		if (!ParamIsDefault(start))
			start = -1
		endif
		return ""
	endif

	if (!ParamIsDefault(start))
		start = startLocal
	endif

	return buf[i0,i1]
End

//ThreadSafe
 Function/T GHI_XMLtagContents2List(xmltag,buf,[occurance,delimiters]) //reads a tag contensts and converts it to a list
	String xmltag
	String buf
	Variable occurance				// use 0 for first occurance, 1 for second, ...
	String delimiters					// characters that might be used for delimiters (NOT semi-colon), default is space, tab, cr, or nl = " \t\r\n"
	occurance = ParamIsDefault(occurance) ? 0 : occurance
	if (ParamIsDefault(delimiters) || strlen(delimiters)==0)
		delimiters = " \t\r\n"							// the usual white-space characters
	endif

	String str = GHI_XMLtagContents(xmltag,buf,occurance=occurance)
	str = ReplaceString(";",str,"_")				// cannot have any semi-colons in input string

	Variable i
	for (i=0;i<strlen(delimiters);i+=1)
		str = ReplaceString(delimiters[i],str,";")		// replace every occurance of a character in delimiters with a semi-colon
	endfor

	do
		str = ReplaceString(";;",str,";")			// replace all multiple semi-colons with a single semi-colon
	while(strsearch(str,";;",0)>=0)

	if (char2num(str[0])==char2num(";"))			// remove any leaing semi-colon
		str = str[1,Inf]
	endif
	return str
End

//ThreadSafe
 Function/T GHI_XMLattibutes2KeyList(xmltag,buf,[occurance,start])// return a list with all of the attribute value pairs for xmltag
	String xmltag											// name of tag to find
	String buf												// buf containing xml
	Variable occurance									// use 0 for first occurance, 1 for second, ...
	Variable &start										// offset in buf, start searching at buf[start], new start is returned
																// both occurance and start may be used together, but usually you only want to use one of them
	occurance = ParamIsDefault(occurance) ? 0 : occurance
	Variable startLocal = ParamIsDefault(start) ? 0 : start
	startLocal = numtype(startLocal) || startLocal<1 ? 0 : round(startLocal)

	Variable i0,i1
	if (startLocal>0)
		i0 = GHI_startOfxmltag(xmltag,buf[startLocal,Inf],occurance) + startLocal
	else
		i0 = GHI_startOfxmltag(xmltag,buf,occurance)
	endif
	if (i0<0)
		return ""
	endif
	i0 += strlen(xmltag)+2								// start of attributes
	i1 = strsearch(buf,">",i0)-1						// end of attributes
	String key, value, keyVals=""

	if (i1 < i0)											// this is an ERROR
		startLocal = -1
	else
		startLocal = i1 + 2								// character just after closing '>'
		// parse buf into key=value pairs
		buf = buf[i0,i1]
		buf = ReplaceString("\t",buf," ")
		buf = ReplaceString("\r",buf," ")
		buf = ReplaceString("\n",buf," ")
		buf = GHI_TrimFrontBackWhiteSpace(buf)
		i0 = 0
		do
			i1 = strsearch(buf,"=",i0,0)
			key = GHI_TrimFrontBackWhiteSpace(buf[i0,i1-1])
			i0 = strsearch(buf,"\"",i1,0)+1				// character after the first double quote around value
			i1 = strsearch(buf,"\"",i0,0)-1				// character before the second double quote around value
			value = buf[i0,i1]
			if (strlen(key)>0)
				keyVals = ReplaceStringByKey(key,keyVals,value,"=")
			endif
			i0 = strsearch(buf," ",i1,0)					// find space separator, set up for next key="val" pair
		while(i0>0 && strlen(key))
	endif

	if (!ParamIsDefault(start))							// set start if it was passed
		start = startLocal
	endif
	return keyVals
End
ThreadSafe Function/T GHI_TrimFrontBackWhiteSpace(str)
	String str
	str = GHI_TrimLeadingWhiteSpace(str)
	str = GHI_TrimTrailingWhiteSpace(str)
	return str
End
//
ThreadSafe Function/T GHI_TrimLeadingWhiteSpace(str)
	String str
	Variable i, N=strlen(str)
	for (i=0;char2num(str[i])<=32 && i<N;i+=1)	// find first non-white space
	endfor
	return str[i,Inf]
End
//
ThreadSafe Function/T GHI_TrimTrailingWhiteSpace(str)
	String str
	Variable i
	for (i=strlen(str)-1; char2num(str[i])<=32 && i>=0; i-=1)	// find last non-white space
	endfor
	return str[0,i]
End

//


ThreadSafe Function/T GHI_XMLremoveComments(str)	// remove all xml comments from str
	String str
	Variable i0,i1
	do
		i0 = strsearch(str,"<!--",0)					// start of a comment
		i1 = strsearch(str,"-->",0)					// end of a comment
		if (i0<0 || i1<=i0)
			break
		endif
		str[i0,i1+2] = ""									// snip out comment
	while(1)
	return str
End
//
ThreadSafe Static Function GHI_startOfxmltag(xmltag,buf,occurance)	// returns the index into buf pointing to the start of xmltag
	String xmltag, buf
	Variable occurance									// use 0 for first occurance, 1 for second, ...

	Variable i0,i1, i, start
	for (i=0,i0=0;i<=occurance;i+=1)
		start = i0
		i0 = strsearch(buf,"<"+xmltag+" ",start)	// find start of a tag with attributes
		i1 = strsearch(buf,"<"+xmltag+">",start)	// find start of a tag without attributes
		i0 = i0<0 ? Inf : i0
		i1 = i1<0 ? Inf : i1
		i0 = min(i0,i1)
		i0 += (i<occurance) ? strlen(xmltag)+2 : 0	// for more, move starting point forward
	endfor
	i0 = numtype(i0) || i0<0 ? -1 : i0
	return i0
End

//  ================================= End of Generic XML =================================  //
//  ======================================================================================  //
//  ============    Index Procedure files so we can find what we have... =================  //
//**************************************************************** 
//**************************************************************** 
static Function GHW_ListAllInstallableFiles()
	String path
	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
	//Igor Procedures
	GUIReportActivityForUser = "Scanning local Igor Procedures"
	DoUpdate  /W=DownloadWarning 
	GetFileFolderInfo/Q/Z/P=Igor "Igor Procedures"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path,1 )
	endif
	GetFileFolderInfo/Q/Z GHW_GetIgorUserFilesPath()+"Igor Procedures:"
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Procedures:",0)
	endif
	//user procedures 
	GUIReportActivityForUser = "Scanning local User Procedures"
	DoUpdate  /W=DownloadWarning 
	GetFileFolderInfo/Q/Z/P=Igor "User Procedures"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path,0)
	endif
	path = GHW_GetIgorUserFilesPath()				//HR This is needed because of a bug in SpecialDirPath prior to 6.20B03.
	path += "User Procedures:"					
	GetFileFolderInfo/Q/Z (path)	
	if(V_Flag==0)
		GHW_ListProcFiles(path,0)	//HR Reuse path variable
	endif
	//xops
	GUIReportActivityForUser = "Scanning local xop packages"
	DoUpdate  /W=DownloadWarning 
	GetFileFolderInfo/Q/Z/P=Igor "Igor Extensions (64-bit)"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path, 0)
	endif
	GetFileFolderInfo/Q/Z (GHW_GetIgorUserFilesPath()+"Igor Extensions (64-bit):")
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Extensions (64-bit):",0)
	endif
	GetFileFolderInfo/Q/Z/P=Igor "Igor Extensions"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path, 0)
	endif
	GetFileFolderInfo/Q/Z (GHW_GetIgorUserFilesPath()+"Igor Extensions:")
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Extensions:",0)
	endif
	KillPath/Z tempPath
end
//**************************************************************** 
static Function GHW_ListUserProcFiles()
	GetFileFolderInfo/Q/Z/P=Igor "User Procedures"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path,1)
	endif

	String path
															//HR Create path variable for easier debugging
	path = GHW_GetIgorUserFilesPath()				//HR This is needed because of a bug in SpecialDirPath prior to 6.20B03.
	path += "User Procedures:"						//HR Removed trailing colon though that is not necessary //JIL and HR was wrong, it fails afterwards
	GetFileFolderInfo/Q/Z (path)	
	if(V_Flag==0)
		GHW_ListProcFiles(path,0)	//HR Reuse path variable
	endif

	KillPath/Z tempPath
end
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
static Function GHW_ListIgorExtensionsFiles()
	GetFileFolderInfo/Q/Z/P=Igor "Igor Extensions (64-bit)"	
	if(V_Flag==0)
		GHW_ListProcFiles(S_Path, 1)
	endif
	GetFileFolderInfo/Q/Z (GHW_GetIgorUserFilesPath()+"Igor Extensions (64-bit):")
	if(V_Flag==0)
		GHW_ListProcFiles(GHW_GetIgorUserFilesPath()+"Igor Extensions (64-bit):",0)
	endif
	KillPath/Z tempPath
end
//**************************************************************** 
static Function/S GHW_GetIgorUserFilesPath()
	// This should be a Macintosh path but, because of a bug prior to Igor Pro 6.20B03
	// it may be a Windows path.
	String path = SpecialDirPath("Igor Pro User Files", 0, 0, 0)
	path = GHW_Windows2IgorPath(path)
	return path
End
//**************************************************************** 
static Function /S GHW_Windows2IgorPath(pathIn)
	String pathIn
	String pathOut = ParseFilePath(5, pathIn, ":", 0, 0)
	return pathOut
End

//**************************************************************** 
//**************************************************************** 
static  Function GHW_ListProcFiles(PathStr, resetWaves)
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
				//Inst_Append2Log(str,0)
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
				//Inst_Append2Log(str,0)
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
//	if(runningTopLevel)
//		//some output here...
//		print "Found   "+num2str(numpnts(FileNames))+"  files in   "+PathStr+" folder, its subfolders and linked folders and subfolders"
//		KillPath/Z tempPath
//	endif
 
	setDataFolder OldDf
end
//***********************************
//***********************************
//**************************************************************** 
//**************************************************************** 
//static 
Function GHW_FindFileVersion(FilenameStr)
	string FilenameStr
	
	Wave/T PathToFIles= root:Packages:UseProcedureFiles:PathToFIles
	Wave/T FileNames=root:Packages:UseProcedureFiles:FileNames
	Wave FileVersions =root:Packages:UseProcedureFiles:FileVersions
	variable i, imax=Numpnts(FileNames), versionFound
	string tempname
	versionFound=-1
	For(i=0;i<imax;i+=1)
		tempname = FileNames[i]
		if(stringmatch(tempname,FileNameStr))
			versionFound = FileVersions[i]
			return versionFound
		endif
	endfor
	return -1
end
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 
//**************************************************************** 

//static 
Function GHW_FindVersionOfSingleFile(tempFileName,PathStr)
	string tempFileName, PathStr
		
		string tempScraptext
		Grep/P=$(PathStr)/Z/E="(?i)^#pragma[ ]*version[ ]*=[ ]*" tempFileName as "Clipboard"
		sleep/s (0.02)
		tempScraptext = GetScrapText()
		if(strlen(tempScraptext)>10)		//found line with #pragma version"
			tempScraptext = replaceString("#pragma",tempScraptext,"")	//remove #pragma
			tempScraptext = replaceString("version",tempScraptext,"")		//remove version
			tempScraptext = replaceString("=",tempScraptext,"")			//remove =
			tempScraptext = replaceString("\t",tempScraptext,"  ")			//remove optional tabulators, some actually use them. 
			tempScraptext = RemoveEnding(tempScraptext,"\r")			//remove optional tabulators, some actually use them. 
			//forget about the comments behind the text. 
                    //str2num is actually quite clever in this and converts start of the string which makes sense. 
			return str2num(tempScraptext)
		else             //no version found, set to NaN
			return NaN
		endif

end


//**************************************************************** 
//**************************************************************** 
Function GHW_PrepareGUIData()
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller

	Wave/T ListOfPackages = root:Packages:GHInstaller:ListOfPackages
	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
	SVAR CurrentBetaReleaseName = root:Packages:GHInstaller:CurrentBetaReleaseName
	SVAR CurrentReleaseName = root:Packages:GHInstaller:CurrentReleaseName
	SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
	SVAR ListOfReleaseNames = root:Packages:GHInstaller:ListOfReleaseNames
	SVAR ListOfBetaReleaseNames = root:Packages:GHInstaller:ListOfBetaReleaseNames
	SVAR PopListOfReleaseNames = root:Packages:GHInstaller:PopListOfReleaseNames
	NVAR DisplayBetaReleases = root:Packages:GHInstaller:DisplayBetaReleases
	NVAR UseLocalFolder = root:Packages:GHInstaller:UseLocalFolder
 
	if(DisplayBetaReleases)
		PopListOfReleaseNames = CurrentReleaseName+";"+CurrentBetaReleaseName+";---;"+ListOfReleaseNames+";"+ListOfBetaReleaseNames+"master"+";"
		SelectedReleaseName = CurrentReleaseName
	else
		PopListOfReleaseNames = CurrentReleaseName+";---;"+ListOfReleaseNames+";"
		SelectedReleaseName = CurrentReleaseName
	endif
	if(UseLocalFolder)
		PopListOfReleaseNames = "Local Folder"+";"
		SelectedReleaseName = "Local Folder"
	endif
	DoWIndow GH_MainPanel
	if(V_Flag)
			PopupMenu SelectReleaseToInstall,win=GH_MainPanel ,mode=1,value= #"root:Packages:GHInstaller:PopListOfReleaseNames"
	endif
	GHW_PrepareListboxGUIData()
	SetDataFolder saveDFR					// Restore current data folder
end
//**************************************************************** 
//**************************************************************** 

Function GHW_PrepareListboxGUIData()
//this function prepares data for GUI so they can be easily used. 
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller
	//expect to find below listed strings and text waves
	Wave/T ListOfPackages = root:Packages:GHInstaller:ListOfPackages
	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
	SVAR CurrentBetaReleaseName = root:Packages:GHInstaller:CurrentBetaReleaseName
	SVAR CurrentReleaseName = root:Packages:GHInstaller:CurrentReleaseName
	SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
	SVAR ListOfReleaseNames = root:Packages:GHInstaller:ListOfReleaseNames
	SVAR ListOfBetaReleaseNames = root:Packages:GHInstaller:ListOfBetaReleaseNames
	SVAR PopListOfReleaseNames = root:Packages:GHInstaller:PopListOfReleaseNames
	NVAR DisplayBetaReleases = root:Packages:GHInstaller:DisplayBetaReleases
	SVAR ReleaseNotes = root:Packages:GHInstaller:ReleaseNotes
	SVAR LocalFolderPath = root:Packages:GHInstaller:LocalFolderPath
	//need to prepare new stuff...
	variable NumOfReleases=DimSize(ListOfReleases, 0 )
	variable NumOfPackages=DimSize(ListOfPackages, 0 )
	make/O/T/N=(NumOfPackages,4) VersionsAndInstall
	make/O/N=(NumOfPackages,4) SelVersionsAndInstall
	Wave/T VersionsAndInstall
	VersionsAndInstall = ""
	SetDimLabel 1,0,$"Package",VersionsAndInstall
	SetDimLabel 1,1,$"Local ver.",VersionsAndInstall
	SetDimLabel 1,2,$"Release ver.",VersionsAndInstall
	SetDimLabel 1,3,$"Select?",VersionsAndInstall
	SelVersionsAndInstall[][3] =32
	//find out versions... 
	//column 1 are Local versions, look inside local files
	//column 2 are remote versions in the release
	variable i
	variable TmpVer
	string TempStr, tempKey, tempVerName
	string LookHere
	variable WhichReleaseUserWants=NaN
	For(i=0;i<dimsize(ListOfReleases,0);i+=1)
		if(StringMatch(ListOfReleases[i][0], SelectedReleaseName ))
			WhichReleaseUserWants = i
			break	
		endif
	endfor
	ReleaseNotes = ""
	if(numtype(WhichReleaseUserWants)!=0)
		//something went wrong here, abort and set values to Nan's 
		if(StringMatch(SelectedReleaseName, "master" ))
			ReleaseNotes = "Master = development versions in GH at this moment!"
			tempVerName = "unknown"
		else
			ReleaseNotes = "LocalFolder = versions in : "+LocalFolderPath
			tempVerName = "unknown"
		endif
		LookHere = ListOfReleases[0][2]
		For(i=0;i<numpnts(ListOfPackages);i+=1)
			VersionsAndInstall[i][0]=ListOfPackages[i]
			TempStr = StringByKey(ListOfPackages[i]+"_VersionCheckFile", LookHere,"=",";")
			TmpVer = GHW_FindFileVersion(TempStr)
			VersionsAndInstall[i][1]=num2str(TmpVer)
			VersionsAndInstall[i][2]=tempVerName		//would be nice to use this: GHW_FindNonStandardPckgVersionNum but it is ugly process to figure it out. May be later. 
		endfor
	else
		LookHere = ListOfReleases[WhichReleaseUserWants][2]
		For(i=0;i<numpnts(ListOfPackages);i+=1)
			VersionsAndInstall[i][0]=ListOfPackages[i]
			TempStr = StringByKey(ListOfPackages[i]+"_VersionCheckFile", LookHere,"=",";")
			TmpVer = GHW_FindFileVersion(TempStr)
			VersionsAndInstall[i][1]=num2str(TmpVer)
			VersionsAndInstall[i][2]=StringByKey(ListOfPackages[i], LookHere,"=",";")
		endfor
		ReleaseNotes = StringByKey("VersionComment", LookHere,"=",";")
	endif
	
	SetDataFolder saveDFR					// Restore current data folder
end
//**************************************************************** 
//**************************************************************** 
//**************************************************************************************************************************************
//**************************************************************************************************************************************
Function GHW_Uninstall()
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller
 
	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
	Wave SelVersionsAndInstall = root:Packages:GHInstaller:SelVersionsAndInstall
	Wave/T VersionsAndInstall = root:Packages:GHInstaller:VersionsAndInstall
	SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
	string/g ToModifyPackagesList=""
	string/g PackageListsToDownload=""
	string/g ListOfProcFilesToClose=""
	variable i, j
	variable WhichReleaseUserWants=NaN
	For(i=0;i<dimsize(ListOfReleases,0);i+=1)
		if(StringMatch(ListOfReleases[i][0], SelectedReleaseName ))
			WhichReleaseUserWants = i
			break	
		endif
	endfor
	//if using local folder, this will fial. Pick the first one here.
	if(numtype(WhichReleaseUserWants)!=0)
		WhichReleaseUserWants = 0
	endif
	string LookHere = ListOfReleases[WhichReleaseUserWants][2]
	For(i=0;i<dimsize(SelVersionsAndInstall,0);i+=1)
		if(SelVersionsAndInstall[i][3]>32)
			ToModifyPackagesList+=VersionsAndInstall[i][0]+";"
			PackageListsToDownload+=StringByKey(VersionsAndInstall[i][0]+"_PackageList", LookHere  , "=", ";")+";"
		endif
	endfor
	//print ToModifyPackagesList
	//print PackageListsToDownload
	//download xml files with list of files 
	variable fileID
	string FileContent=""
	string ConfigFileURL, tempStr
	GUIReportActivityForUser = "Downloading Configuration from GitHub"
	GHW_DownloadWarning()
	GHW_MakeRecordOfProgress("Started Unistallation of the packages", header=1) 
	NewPath /Q/Z/O IgorUserPath, SpecialDirPath("Igor Pro User Files", 0, 0, 0 )
	DoUpdate /W=DownloadWarning
	string LinksList, LinkListFixed
	variable ij
	For(i=0;i<ItemsInList(ToModifyPackagesList);i+=1)
		GUIReportActivityForUser = "Downloading "+StringFromList(i,PackageListsToDownload)
		DoUpdate /W=DownloadWarning
		ConfigFileURL=ksWebAddressForConfFile+StringFromList(i,PackageListsToDownload)
		FileContent=FetchURL(ConfigFileURL)
		Variable error = GetRTError(1)
		if (error == 0)
			GHW_MakeRecordOfProgress("Downloaded file : "+ConfigFileURL) 
		else
			DoWIndow/K DownloadWarning
			GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+"Error downloading data, cannot proceed", abortProgress=1) 
		endif
		FileContent=GHI_XMLremoveComments(FileContent)		//get rid of comments, confuses the rest of the code... 
		//FileContent now contains content of the file...
		string InstallerText=GHI_XMLtagContents("PackageContent",FileContent)	//if nothing, wrong format
		if(strlen(InstallerText)<10)	//no real content
			DoWIndow/K DownloadWarning
			SetDataFolder saveDFR					// Restore current data folder
			GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+"No content came from server, cannot proceed  ", abortProgress=1) 
		endif
		GUIReportActivityForUser = "Deleting files for "+StringFromList(i,PackageListsToDownload)
		DoUpdate /W=DownloadWarning
		string igorCmd
		string/g $(StringFromList(i,PackageListsToDownload)+"Pkcg")
		SVAR PackgList=$(StringFromList(i,PackageListsToDownload)+"Pkcg") 
		//PackgList=GHW_ListFilesInPckgList(FileContent) 
 		PackgList= GHW_ListPlatformSpecificValues(FileContent, "File", IgorInfo(2))
// 		LinksList=GHW_ListPlatformSpecificValues(FileContent, "xopLinks", IgorInfo(2))
// 		if(stringMatch(IgorInfo(2),"Windows"))
// 			For(ij=0;ij<ItemsInList(LinksList);ij+=1)
// 				LinkListFixed=LinksList+".lnk"+";"
// 			endfor
// 		else
// 			LinkListFixed=LinksList
// 		endif
// 		PackgList+=LinkListFixed
		For(j=0;j<ItemsInList(PackgList);j+=1)
			tempStr = StringFromList(j,PackgList,";")
			string FoldStr
			if(strlen(tempStr)>2)		//clean up accidental empty lines
				if(!stringMatch(tempStr[0],":"))
					tempStr = ":"+tempStr
				endif
				tempStr = replaceString("/",tempStr,":")
				//tempStr = StringFromList(ItemsInList(tempStr, "/")-1, tempStr , "/")
				GetFileFolderInfo/Q/Z/P=IgorUserPath  tempStr+".deleteMe"
				if(V_Flag==0)		//file/xop found, get rid of it
					if(V_isFile)
						DeleteFile /P=IgorUserPath /Z tempStr+".deleteMe"
						if(V_flag!=0)
							GHW_MakeRecordOfProgress("Could not delete "+tempStr+".deleteMe")
						else
							GHW_MakeRecordOfProgress( "Deleted old file : "+tempStr+".deleteMe")	
						endif
					elseif(V_isFolder)
						//here is nasty overwrite using OS script...
						PathInfo IgorUserPath
						FoldStr = replaceString("::",S_Path+tempStr,":")
						FoldStr=RemoveFromList(StringFromList(0,FoldStr  , ":"), FoldStr  , ":")
						FoldStr = ParseFilePath(5, FoldStr, "\\", 0, 0)
						FoldStr = ReplaceString("\\", FoldStr, "/")
						FoldStr = "rm -Rdf  '/"+ReplaceString(".xop", FoldStr, ".xop.deleteMe")+"'"
						sprintf igorCmd, "do shell script \"%s\"", FoldStr
						//print igorCmd
						ExecuteScriptText igorCmd
						GetFileFolderInfo/Q/Z/P=IgorUserPath  tempStr+".deleteMe"
						if(V_flag==0)
							GHW_MakeRecordOfProgress( "Could not delete folder/xop"+tempStr+".deleteMe")
						else
							GHW_MakeRecordOfProgress( "Deleted old file : "+tempStr+".deleteMe")
						endif
					elseif(V_isAliasShortcut)
						DeleteFile /P=IgorUserPath /Z tempStr+".deleteMe"
						if(V_flag!=0)
							GHW_MakeRecordOfProgress( "Could not delete "+tempStr+".deleteMe")
						else
							GHW_MakeRecordOfProgress( "Deleted old file : "+tempStr+".deleteMe")	
						endif		
					endif
				endif
				//OK, now we can, if needed rename existing file AND keep the user folder cleaner
				//now check for existing target file and delete/rename if necessary
				GetFileFolderInfo/Q/Z/P=IgorUserPath  tempStr
				if(V_Flag==0)		//old file/xop found, get rid of it
					if(V_isFile)
						DeleteFile /P=IgorUserPath /Z tempStr
						if(V_flag!=0)
							MoveFile /O/P=IgorUserPath tempStr as tempStr+".deleteMe" 
							GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+tempStr)
						else
							GHW_MakeRecordOfProgress( "Deleted existing file : "+tempStr)
						endif
					elseif(V_isFolder)
						MoveFolder /O/P=IgorUserPath tempStr as tempStr+".deleteMe" 
						if(V_Flag==0)
							GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+tempStr)
						else
							GHW_MakeRecordOfProgress( "Could NOT move existing file : "+tempStr+" to .deleteMe")
						endif
					elseif(V_isAliasShortcut)
						DeleteFile /P=IgorUserPath /Z tempStr
						if(V_flag!=0)
							MoveFile /O/P=IgorUserPath tempStr as tempStr+".deleteMe" 
							GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+tempStr)
						else
							GHW_MakeRecordOfProgress( "Deleted existing file : "+tempStr)
						endif		
					endif
				endif
			endif
		endfor
	endfor	
	DoWIndow/K DownloadWarning
	SetDataFolder saveDFR					// Restore current data folder
end
//**************************************************************************************************************************************
//**************************************************************************************************************************************


//Function GHW_RemoveListOfFiles()
//	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
//	SetDataFOlder root:Packages:GHInstaller
// 
//	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
//	Wave SelVersionsAndInstall = root:Packages:GHInstaller:SelVersionsAndInstall
//	Wave/T VersionsAndInstall = root:Packages:GHInstaller:VersionsAndInstall
//	SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
//	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
//	SVAR ToModifyPackagesList=root:Packages:GHInstaller:ToModifyPackagesList
//	SVAR PackageListsToDownload=root:Packages:GHInstaller:PackageListsToDownload
//	SVAR ListOfProcFilesToClose=root:Packages:GHInstaller:ListOfProcFilesToClose
//	Wave/T FileNames = root:Packages:UseProcedureFiles:FileNames
//	Wave FileVersions = root:Packages:UseProcedureFiles:FileVersions
//	Wave/T PathToFiles = root:Packages:UseProcedureFiles:PathToFiles
//	variable i, j, FoundLoc
//	variable IamOnMac, isItMacXOP
//	if(stringmatch(IgorInfo(2),"Windows"))
//		IamOnMac=0
//	else
//		IamOnMac=1
//	endif
//	string tempStr, UserDataPath
//	//UserDataPath = SpecialDirPath("Igor Pro User Files", 0, 0, 0 )
//	For(i=0;i<ItemsInList(ToModifyPackagesList);i+=1)
//		SVAR PackgList=$(StringFromList(i,PackageListsToDownload)+"Pkcg")
//		For(j=0;j<ItemsInList(PackgList , ";");j+=1)
//			tempStr = StringFromList(j, PackgList , ";")
//			tempStr = StringFromList(ItemsInList(tempStr, "/")-1, tempStr , "/")
//			FindValue /TEXT=tempStr /TXOP=4 /Z FileNames
//			if(V_value>=0)
//				tempStr = PathToFiles[V_value]+ReplaceString("/", tempStr, ":")
//				GetFileFolderInfo/Z/Q tempStr
//				isItMacXOP = IamOnMac * stringmatch(tempStr, "*xop*" )
//				if(V_isFile)
//					print "Would delete file:"+tempStr
//					//	DeleteFile/Z tempStr
//					// if(V_Flag!=0)
//						//rename original file, but first delete any such version which may exist
//					//endif
//				elseif(V_isFolder)
//					print "Would delete folder/xop"
//					//	DeleteFolder/Z tempStr
//					// if(V_Flag!=0)
//						//rename original file, but first delete any such version which may exist
//					//endif
//				//elseif(isItMacXOP)
//					//print would deal with MacXOP (for installation purposes, here needs to be unzipped... 
//				endif	
//			endif
//		endfor
//		
//	endfor
//	
//	SetDataFolder saveDFR					// Restore current data folder
//end
//**************************************************************************************************************************************
//**************************************************************************************************************************************

Function GHW_Install()
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller
 
	Wave/T ListOfReleases = root:Packages:GHInstaller:ListOfReleases
	Wave SelVersionsAndInstall = root:Packages:GHInstaller:SelVersionsAndInstall
	Wave/T VersionsAndInstall = root:Packages:GHInstaller:VersionsAndInstall
	SVAR SelectedReleaseName = root:Packages:GHInstaller:SelectedReleaseName
	SVAR GUIReportActivityForUser=root:Packages:GHInstaller:GUIReportActivityForUser
	NVAR UseLocalFolder=root:Packages:GHInstaller:UseLocalFolder
	SVAR LocalFolderPath=root:Packages:GHInstaller:LocalFolderPath
	string/g ToModifyPackagesList=""
	string/g PackageListsToDownload=""
	string/g ListOfProcFilesToClose=""
	variable i, j
	variable WhichReleaseUserWants=NaN
	string LookHere
	GHW_MakeRecordOfProgress("", header=1)
	//special cases SelectedReleaseName : "master" and "Local Folder"
	if(stringmatch(SelectedReleaseName,"Local Folder"))	//using local folder. 	
		GetFileFolderInfo/Q/Z  LocalFolderPath
		if(V_Flag!=0)
			GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+"Installation from local folder "+LocalFolderPath+" cannot proceed, folder not found", abortProgress=1) 
		else
			GHW_MakeRecordOfProgress("Installation from local folder "+LocalFolderPath+" started. Found the source folder. " )
		endif
		//at this moment we should have a folder called $(InternalDataName) on the desktop with the rigth ditribution files and can install them as user wants. 
		//install packages as user requested	
		LookHere = ListOfReleases[0][2]		
		For(i=0;i<dimsize(SelVersionsAndInstall,0);i+=1)
			if(SelVersionsAndInstall[i][3]>32)
				ToModifyPackagesList+=VersionsAndInstall[i][0]+";"
				PackageListsToDownload+=StringByKey(VersionsAndInstall[i][0]+"_PackageList", LookHere  , "=", ";")+";"
			endif
		endfor
		GHW_MakeRecordOfProgress("User picked following packages to install: "+PackageListsToDownload )
		For(i=0;i<ItemsInList(ToModifyPackagesList);i+=1)
			GHW_InstallPackage(LocalFolderPath,StringFromList(i,PackageListsToDownload))
		endfor
		GHW_MakeRecordOfProgress("Installation from local folder "+LocalFolderPath+" finished. All done. " )
		DoAlert /T="Installation succesfully finished" 0, "Requested Installation finished succesfully. Delete the distribution zip file, folder with unzipped data and InstallLog.txt, if you do not need them anymore." 
	else		//dowload folder from remote location...
		For(i=0;i<dimsize(ListOfReleases,0);i+=1)
			if(StringMatch(ListOfReleases[i][0], SelectedReleaseName ))
				WhichReleaseUserWants = i
				break	
			endif
		endfor
		if(stringmatch(SelectedReleaseName,"master"))
			WhichReleaseUserWants = 0				//let's get any one of the addresses and remove the name of the zip file
		endif												//then append repoName-master.zip and that is current version (SAXS_IgorCode-master.zip)
		LookHere = ListOfReleases[WhichReleaseUserWants][2]
		string URLtoGet=StringByKey("SourceFileAddress", LookHere  , "=",";")
		//need to build name of data inside the zip file... 
		variable ItemsInPath=ItemsInList(URLtoGet,"/")
		string InternalDataName = StringFromList(ItemsInPath-3, URLtoGet, "/")
		if(stringmatch(SelectedReleaseName,"master"))
			URLtoGet = RemoveListItem(ItemsInPath-1, URLtoGet, "/")+"master.zip"
			InternalDataName =InternalDataName+"-master"
		else
			InternalDataName +="-"+ RemoveEnding(StringFromList(ItemsInPath-1, URLtoGet, "/"),".zip")
		endif
		GHW_MakeRecordOfProgress("Installation from Github zip source "+URLtoGet+" started. " )
		string FileContent
		variable refNum
		NewPath/O/C/Q userDesktop, SpecialDirPath("Desktop",0,0,0)
		String destinationZip = SpecialDirPath("Desktop",0,0,0)+InternalDataName+".zip"
		String DesktopFldr = SpecialDirPath("Desktop",0,0,0)
		String destinationFldr = DesktopFldr+InternalDataName
		variable SkipDownload=0
		if (GHW_FileFolderExists(destinationZip,file=1))
			Doalert/T="Existing file found" 2, "The file '"+InternalDataName+".zip' already exists on the desktop. Do you want to use it [yes] or delete it and download new one? [no]"
			if(V_Flag==1)
				//use existing
				SkipDownload = 1
				GHW_MakeRecordOfProgress("Found existing "+InternalDataName+".zip file and user choose to use it. " )
			elseif(V_Flag==2)
				DeleteFile /P=userDesktop (InternalDataName+".zip")  
				GHW_MakeRecordOfProgress("Found existing "+InternalDataName+".zip file and user choose to delete it. " )
			else
				GHW_MakeRecordOfProgress("Found existing "+InternalDataName+".zip file and user choose to abort. ", abortprogress=1 )
			endif
		endif
		if(!SkipDownload)
			GHW_DownloadWarning()
			GUIReportActivityForUser = "Downloading Package zip file from GitHub"
			GHW_MakeRecordOfProgress("Downloading Package zip file "+URLtoGet+" from GitHub " )
			FileContent=FetchURL(URLtoGet)
			Variable error = GetRTError(1)
			if (error != 0)
				DoWIndow/K DownloadWarning
				GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+"Error Downloading Package zip file "+URLtoGet+" from GitHub.", abortprogress=1 )
			endif
			sleep/S 3		//just to flush the data to disk and avoid getting ahead of system with reading file in cache. 
			//			str= "Done downloading distribution zip file, got : "+num2str(1.0486*strlen(fileBytes)/(1024*1024))+" Mbytes"
			//			Inst_Append2Log(str,0)
			Open/P=userDesktop  refNum as (InternalDataName+".zip")
			FBinWrite refNum, FileContent
			Close refNum
			FileContent=""
			DoWIndow/K DownloadWarning
		endif
		//the distribution zip file should be on the desktop. 
		variable err
		GHW_DownloadWarning()
		if(stringmatch(IgorInfo(2),"Windows"))
			//WIndows, need to get user to unzip the file
			GUIReportActivityForUser = "Unzipping "+InternalDataName+".zip file." 
			GHW_MakeRecordOfProgress("Windows : Unzipping the file "+InternalDataName+".zip file. " )	
			GHW_UnzipFileOnDesktopWindows(InternalDataName+".zip", InternalDataName, 0)
			//DoAlert/T="User action needed! Zip file is on the Desktop. " 1, "Please, copy the folder "+InternalDataName+" from dowloaded zip file "+(InternalDataName+".zip")+" on your Desktop and push Yes. No will cancel the process and stop. Use Alt-Tab/Cmd-Tab to move between Explorer/Finder and Igor, as needed. " 
			//if(V_Flag==1)
				//should have the folder where needed
			//else
			//	GHW_MakeRecordOfProgress("User cancelled in unzipping of "+InternalDataName+" zip file. Aborting.", abortprogress=1 )
			//endif
		else
			//unzip on Mac using script. 
			GUIReportActivityForUser = "Unzipping "+InternalDataName+".zip file." 
			GHW_MakeRecordOfProgress("Macintosh : unzipping "+InternalDataName+".zip file." )
			err = GHW_UnZipOnMac(InternalDataName+".zip",DesktopFldr,deleteZip=0, overWrite=1, printIt=1)
			if(err)
				GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+"Error in unzipping of "+InternalDataName+".zip file on OSX.", abortprogress=1 )
			endif
		endif
		DoWIndow/K DownloadWarning
		//at this moment we should have a folder called $(InternalDataName) on the desktop with the rigth ditribution files and can install them as user wants. 
		//install packages as user requested	
		For(i=0;i<dimsize(SelVersionsAndInstall,0);i+=1)
			if(SelVersionsAndInstall[i][3]>32)
				ToModifyPackagesList+=VersionsAndInstall[i][0]+";"
				PackageListsToDownload+=StringByKey(VersionsAndInstall[i][0]+"_PackageList", LookHere  , "=", ";")+";"
			endif
		endfor
		GHW_MakeRecordOfProgress("User picked following packages to install: "+PackageListsToDownload )
		For(i=0;i<ItemsInList(ToModifyPackagesList);i+=1)
			GHW_InstallPackage(DesktopFldr+InternalDataName,StringFromList(i,PackageListsToDownload))
		endfor
		GHW_MakeRecordOfProgress("Installation from local folder "+LocalFolderPath+" finished. All done. " )
		DoAlert /T="Installation succesfully finished" 0, "Requested Installation finished succesfully. Delete the InstallLog.txt, if you do not need it anymore." 
	endif	
	SetDataFolder saveDFR					// Restore current data folder
end
//**************************************************************************************************************************************
//**************************************************************************************************************************************

Static Function GHW_UnZipOnMac(zipFile,DestFolder,[deleteZip,overWrite,printIt])
	String zipFile				// name of zip file to expand
	String DestFolder			// folder to put results (defaults to same folder as zip file"
	Variable deleteZip		// if True, delete the zip file when done (default is NO delete)
	Variable overWrite		// if True, over write existing files when un-zipping (default is NOT overwite)
	Variable printIt
	deleteZip = ParamIsDefault(deleteZip) || numtype(deleteZip) ? 0 : deleteZip
	overWrite = ParamIsDefault(overWrite) || numtype(overWrite) ? 0 : overWrite
	printIt = ParamIsDefault(printIt) || numtype(printIt) ? strlen(GetRTStackInfo(2))==0 : printIt
	String str=""
	if (!StringMatch(IgorInfo(2),"Macintosh"))
		GHW_MakeRecordOfProgress("Macintosh : ERROR -- UnZipOnMac() only works on Macintosh")
		return 1
	endif

	// check for valid input zip file
	GetFileFolderInfo/P=Desktop/Q/Z=1 zipFile
	if (V_Flag || !V_isFile)
		if (printIt)
			sprintf str, "Macintosh : Error - did not find valid \"%s\" file\r",zipFile
			GHW_MakeRecordOfProgress(str)
		endif
		return 1
	endif
	printIt = StringMatch(S_Path,zipFile) ? printIt : 1

	zipFile = S_Path
	if (!StringMatch(ParseFilePath(4,zipFile,":",0,0),"zip"))
		if (printIt)
			sprintf str, "Macintosh : ERROR -- \"%s\" is not a zip file\r",zipFile
			GHW_MakeRecordOfProgress(str)
		endif
		return 1
	endif

	// check for valid destination folder
	if (strlen(DestFolder)<1)
		DestFolder = ParseFilePath(1,zipFile,":",1,0)
	endif
	GetFileFolderInfo/P=Desktop/Q/Z=1 DestFolder
	if (V_Flag || !V_isFolder)
		if (printIt)
			GHW_MakeRecordOfProgress("Macintosh : ERROR -- destination folder not found, nothing done")
		endif
		return 1
	endif
	DestFolder = S_Path
	printIt = StringMatch(S_Path,DestFolder) ? printIt : 1

	// get POSIX versions of paths for the shell script
	String zipFilePOSIX = ParseFilePath(5,zipFile,"/",0,0)
	String DestFolderPOSIX = ParseFilePath(5,DestFolder,"/",0,0)

	// create the shell script and execute it
	String cmd, switches=SelectString(overWrite,""," -o")
	sprintf cmd, "do shell script \"unzip %s \\\"%s\\\" -d \\\"%s\\\"\"", switches, zipFilePOSIX,DestFolderPOSIX
	ExecuteScriptText/Z cmd						//returns something only on error
	if (V_flag)
		sprintf str, "\r  ERROR -unzipping,  V_flag =",V_flag
		GHW_MakeRecordOfProgress(str)
		sprintf str, "cmd = ",ReplaceString("\n",cmd,"\r")
		GHW_MakeRecordOfProgress(str)
		sprintf str, "\r  S_value =",ReplaceString("\n",S_value,"\r")
		GHW_MakeRecordOfProgress(str)
		return V_flag									// all done, to not consider deleting the zip file
	elseif (printIt)
		sprintf str, "unzipping \"%s\"  -->  \"%s\"\r", zipFilePOSIX, DestFolderPOSIX
		GHW_MakeRecordOfProgress(str)
	endif

	// optionally delete the zip file if requested
	if (deleteZip)
		DeleteFile/M="Delete the zip file"/Z zipFile
		if (V_flag==0 && printIt)
			sprintf str, "Macintosh : Deleted:  \"%s\"\r", zipFile
			GHW_MakeRecordOfProgress(str)
		endif
	endif
	return V_flag
End
//**************************************************************************************************************************************
//**************************************************************************************************************************************
Function GHW_UnzipFileOnDesktopWindows(ZipFileName, UnzippedFolderName, deleteSource)
	string ZipFileName			// name of zip file on Desktop
	string UnzippedFolderName 	//the folder name inside the zip file
	variable deleteSource		// also delete the source zip file if this is TRUE
	if (!StringMatch(IgorInfo(2),"Windows"))
		GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+" ERROR -- UnzipFileOnDesktopWindows() only works on Windows",abortprogress=1)
		return 1
	endif

	//create Path to Desktop
	NewPath/O Desktop, SpecialDirPath("Desktop", 0, 0, 0 )
	//NewPath/O TempFolder, SpecialDirPath("Temporary", 0, 0, 0 )
	//check that the file exists
	GetFileFolderInfo /P=Desktop /Q/Z=1 ZipFileName
	if(V_Flag!=0)
		Abort "Zip file not found on Desktop"
	endif	

	//create the command file on the desktop, this is Zipjs.bat per 
	//from <a href="https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/zipjs.bat" title="https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/zipjs.bat" rel="nofollow">https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/zi...</a>	
	DoWindow zipjsbat
	if(V_Flag==0)
		GHW_CreateZipjsbat()	
	endif
	SaveNotebook/O/P=Desktop zipjsbat as "zipjs.bat"
	DoWindow/K zipjsbat
	//created the zipjs.bat command file which will unzip the file for us, note must kill the internal Notebook
	//or Igor will held the file and Windows will throw errors
	//now create cmd in line with
	//             zipjs.bat unzip -source C:\myDir\myZip.zip -destination C:\MyDir -keep no -force no
	// the destination folder is created by the script. 
	// -keep yes will keep the content of the zip file, -force yes will overwrite the tempfolder for the data if exists
	// be careful, -force yes will wipe out the destination, if exists, so make sure the data are directed to non-existing folder.
	string strToDesktop = SpecialDirPath("Desktop", 0, 1, 0 )
	string strToTemp = SpecialDirPath("Temporary", 0, 1, 0 )
	string cmd = strToDesktop+"zipjs.bat unzip -source "
	cmd +=strToDesktop+stringFromList(ItemsInList(ZipFileName,":")-1, ZipFileName,":")+" -destination "
	cmd +=strToTemp+"IgorCode -keep yes -force yes"
	ExecuteScriptText cmd
	//delete the batch file to clean up...
	DeleteFile /P=Desktop /Z  "zipjs.bat"
	if(deleteSource)
		DeleteFile /P=Desktop /Z  ZipFileName		
	endif
	GHW_MakeRecordOfProgress("Windows : Unzipped file "+ZipFileName+" to temp folder")
	//now the folder IgorCode is in the Desktop/ZipFileTempFldr
	//and we need it in Desktop... 
	//NewPath /C /O/Q/Z tempForIgorCode, strToDesktop+"IgorCode"
	cmd ="Xcopy  "+strToTemp+"IgorCode\\"+UnzippedFolderName+"\\*    "+strToDesktop+UnzippedFolderName+"\\ /s /y"
	//cmd =strToDesktop+"moveData.bat "+strToDesktop+"IgorCode\\IgorCode\\    "+strToDesktop+"IgorCode"
	ExecuteScriptText cmd
	GHW_MakeRecordOfProgress("Windows : Copied unzipped file "+ZipFileName+" from temp folder to folder : "+strToDesktop+UnzippedFolderName)
	sleep/s 3		//wait for some time to get OS chance to sort things out...
	//check that a file exists so we know the zip worked, and if not, let user unzip manually...
//	String TestFilePath = strToDesktop+"IgorCode\ftp_IndraPckg"
//	if(!Inst_FileFolderExists(TestFilePath, file=1))
//		DoAlert 0, "Uzipping was NOT succesful. On your Desktop find now IgorCode.zip and manually unzip it on the desktop - this will create new folder called IgorCode -  THEN push \"OK\" button so the installation can continue"
//		if(!Inst_FileFolderExists(TestFilePath, file=1))
//			NVAR InstallUsingFileByFile = root:Packages:JIL_Installer:InstallUsingFileByFile
//			InstallUsingFileByFile=1
//			CheckBox InstallUsingFileByFile win=Inst_MainPanel,  value=1
//			Abort "Still unable to find the files in the zip file. I have selected file-by-file installation method for you now. Please, run installer again now with this other method. "
//			return 1
//		endif
//	endif
	return 0
End	
//
Static Function GHW_CreateZipjsbat()
	//from https://github.com/npocmaka/batch.scripts/blob/master/hybrids/jscript/zipjs.bat
	//how to use see
	//http://stackoverflow.com/questions/28043589/how-can-i-compress-zip-and-uncompress-unzip-files-and-folders-with-bat
	// this is short summary of the description there. Can unzpi, zip and do much more... 
	//
	//// unzip content of a zip to given folder.content of the zip will be not preserved (-keep no).Destination will be not overwritten (-force no)
	//call zipjs.bat unzip -source C:\myDir\myZip.zip -destination C:\MyDir -keep no -force no
	//
	//// lists content of a zip file and full paths will be printed (-flat yes)
	//call zipjs.bat list -source C:\myZip.zip\inZipDir -flat yes
	//
	//// lists content of a zip file and the content will be list as a tree (-flat no)
	//call zipjs.bat list -source C:\myZip.zip -flat no
	//
	//// prints uncompressed size in bytes
	//zipjs.bat getSize -source C:\myZip.zip
	//
	//// zips content of folder without the folder itself
	//call zipjs.bat zipDirItems -source C:\myDir\ -destination C:\MyZip.zip -keep yes -force no
	//
	//// zips file or a folder (with the folder itslelf)
	//call zipjs.bat zipItem -source C:\myDir\myFile.txt -destination C:\MyZip.zip -keep yes -force no
	//
	//// unzips only part of the zip with given path inside
	//call zipjs.bat unZipItem -source C:\myDir\myZip.zip\InzipDir\InzipFile -destination C:\OtherDir -keep no -force yes
	//call zipjs.bat unZipItem -source C:\myDir\myZip.zip\InzipDir -destination C:\OtherDir 
	//
	//// adds content to a zip file
	//call zipjs.bat addToZip -source C:\some_file -destination C:\myDir\myZip.zip\InzipDir -keep no
	//call zipjs.bat addToZip -source  C:\some_file -destination C:\myDir\myZip.zip


	String nb = "zipjsbat"
	NewNotebook/N=$nb/F=0/V=0/K=1/W=(321,81.5,820.5,376.25)
	Notebook $nb defaultTab=20, statusWidth=252
	Notebook $nb font="Arial", fSize=10, fStyle=0, textRGB=(0,0,0)
	Notebook $nb text="@if (@X)==(@Y) @end /* JScript comment\r"
	Notebook $nb text="\t@echo off\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\trem :: the first argument is the script name as it will be used for proper help message\r"
	Notebook $nb text="\tcscript //E:JScript //nologo \"%~f0\" \"%~nx0\" %*\r"
	Notebook $nb text="\r"
	Notebook $nb text="\texit /b %errorlevel%\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="@if (@X)==(@Y) @end JScript comment */\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="/*\r"
	Notebook $nb text="Compression/uncompression command-line tool that uses Shell.Application and WSH/Jscript -\r"
	Notebook $nb text="http://msdn.microsoft.com/en-us/library/windows/desktop/bb774085(v=vs.85).aspx\r"
	Notebook $nb text="\r"
	Notebook $nb text="Some resources That I've used:\r"
	Notebook $nb text="http://www.robvanderwoude.com/vbstech_files_zip.php\r"
	Notebook $nb text="https://code.google.com/p/jsxt/source/browse/trunk/js/win32/ZipFile.js?r=161\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="UPDATE *17-03-15*\r"
	Notebook $nb text="\r"
	Notebook $nb text="Devnullius Plussed noticed a bug in ZipDirItems  and ZipItem functions (now fixed)\r"
	Notebook $nb text="And also following issues (at the moment not handled by the script):\r"
	Notebook $nb text="- if there's not enough space on the system drive (usually C:\\) the script could produce various errors "
	Notebook $nb text=", most often the script halts.\r"
	Notebook $nb text="- Folders and files that contain unicode symbols cannot be handled by Shell.Application object.\r"
	Notebook $nb text="\r"
	Notebook $nb text="UPDATE *24-03-15*\r"
	Notebook $nb text="\r"
	Notebook $nb text="Error messages are caught in waitforcount method and if shuch pops-up the script is stopped.\r"
	Notebook $nb text="As I don't know hoe to check the content of the pop-up the exact reason for the failure is not given\r"
	Notebook $nb text="but only the possible reasons.\r"
	Notebook $nb text="\r"
	Notebook $nb text="------\r"
	Notebook $nb text="It's possible to be ported for C#,Powershell and JScript.net so I'm planning to do it at some time.\r"
	Notebook $nb text="\r"
	Notebook $nb text="For sure there's a lot of room for improvements and optimization and I'm absolutely sure there are some "
	Notebook $nb text="bugs\r"
	Notebook $nb text="as the script is big enough to not have.\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="!!!\r"
	Notebook $nb text="For suggestions contact me at - npocmaka@gmail.com\r"
	Notebook $nb text="!!!\r"
	Notebook $nb text="\r"
	Notebook $nb text="*/\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//   CONSTANTS\r"
	Notebook $nb text="\r"
	Notebook $nb text="// TODO - Shell.Application and Scripting.FileSystemObject objects could be set as global variables to a"
	Notebook $nb text="void theit creation\r"
	Notebook $nb text="// in every method.\r"
	Notebook $nb text="\r"
	Notebook $nb text="//empty zip character sequense\r"
	Notebook $nb text="var ZIP_DATA= \"PK\" + String.fromCharCode(5) + String.fromCharCode(6) + \"\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0\\0"
	Notebook $nb text="\\0\\0\";\r"
	Notebook $nb text="\r"
	Notebook $nb text="var SLEEP_INTERVAL=200;\r"
	Notebook $nb text="\r"
	Notebook $nb text="//copy option(s) used by Shell.Application.CopyHere/MoveHere\r"
	Notebook $nb text="var NO_PROGRESS_BAR=4;\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="//oprions used for zip/unzip\r"
	Notebook $nb text="var force=true;\r"
	Notebook $nb text="var move=false;\r"
	Notebook $nb text="\r"
	Notebook $nb text="//option used for listing content of archive\r"
	Notebook $nb text="var flat=false;\r"
	Notebook $nb text="\r"
	Notebook $nb text="var source=\"\";\r"
	Notebook $nb text="var destination=\"\";\r"
	Notebook $nb text="\r"
	Notebook $nb text="var ARGS = WScript.Arguments;\r"
	Notebook $nb text="var scriptName=ARGS.Item(0);\r"
	Notebook $nb text="\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//   ADODB.Stream extensions\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ADODB ) {\r"
	Notebook $nb text="\tvar ADODB = {};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! ADODB.Stream ) {\r"
	Notebook $nb text="\tADODB.Stream = {};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="// writes a binary data to a file\r"
	Notebook $nb text="if ( ! ADODB.Stream.writeFile ) {\r"
	Notebook $nb text="\tADODB.Stream.writeFile = function(filename, bindata)\r"
	Notebook $nb text="\t{\r"
	Notebook $nb text="        var stream = new ActiveXObject(\"ADODB.Stream\");\r"
	Notebook $nb text="        stream.Type = 2;\r"
	Notebook $nb text="        stream.Mode = 3;\r"
	Notebook $nb text="        stream.Charset =\"ASCII\";\r"
	Notebook $nb text="        stream.Open();\r"
	Notebook $nb text="        stream.Position = 0;\r"
	Notebook $nb text="        stream.WriteText(bindata);\r"
	Notebook $nb text="        stream.SaveToFile(filename, 2);\r"
	Notebook $nb text="        stream.Close();\r"
	Notebook $nb text="\t\treturn true;\r"
	Notebook $nb text="\t};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//   common\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.Common ) {\r"
	Notebook $nb text="\tvar Common = {};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Common.WaitForCount ) {\r"
	Notebook $nb text="\tCommon.WaitForCount = function(folderObject,targetCount,countFunction){\r"
	Notebook $nb text="\t\tvar shell = new ActiveXObject(\"Wscript.Shell\");\r"
	Notebook $nb text="\t\twhile (countFunction(folderObject) < targetCount ){\r"
	Notebook $nb text="\t\t\tWScript.Sleep(SLEEP_INTERVAL);\r"
	Notebook $nb text="\t\t\t//checks if a pop-up with error message appears while zipping\r"
	Notebook $nb text="\t\t\t//at the moment I have no idea how to read the pop-up content\r"
	Notebook $nb text="\t\t\t// to give the exact reason for failing\r"
	Notebook $nb text="\t\t\tif (shell.AppActivate(\"Compressed (zipped) Folders Error\")) {\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\"Error While zipping\");\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\"\");\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\"Possible reasons:\");\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\" -source contains filename(s) with unicode characters\");\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\" -produces zip exceeds 8gb size (or 2,5 gb for XP and 2003)\");\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(\" -not enough space on system drive (usually C:\\\\)\");\r"
	Notebook $nb text="\t\t\t\tWScript.Quit(432);\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t\t\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Common.getParent ) {\r"
	Notebook $nb text="\tCommon.getParent = function(path){\r"
	Notebook $nb text="\t\tvar splitted=path.split(\"\\\\\");\r"
	Notebook $nb text="\t\tvar result=\"\";\r"
	Notebook $nb text="\t\tfor (var s=0;s<splitted.length-1;s++){\r"
	Notebook $nb text="\t\t\tif (s==0) {\r"
	Notebook $nb text="\t\t\t\tresult=splitted[s];\r"
	Notebook $nb text="\t\t\t} else {\r"
	Notebook $nb text="\t\t\t\tresult=result+\"\\\\\"+splitted[s];\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn result;\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Common.getName ) {\r"
	Notebook $nb text="\tCommon.getName = function(path){\r"
	Notebook $nb text="\t\tvar splitted=path.split(\"\\\\\");\r"
	Notebook $nb text="\t\treturn splitted[splitted.length-1];\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="//file system object has a problem to create a folder with slashes at the end\r"
	Notebook $nb text="if ( ! Common.stripTrailingSlash ) {\r"
	Notebook $nb text="\tCommon.stripTrailingSlash = function(path){\r"
	Notebook $nb text="\t\twhile (path.substr(path.length - 1,path.length) == '\\\\') {\r"
	Notebook $nb text="\t\t\tpath=path.substr(0, path.length - 1);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn path;\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//   Scripting.FileSystemObject extensions\r"
	Notebook $nb text="\r"
	Notebook $nb text="if (! this.Scripting) {\r"
	Notebook $nb text="\tvar Scripting={};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if (! Scripting.FileSystemObject) {\r"
	Notebook $nb text="\tScripting.FileSystemObject={};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.DeleteItem ) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.DeleteItem = function (item) \r"
	Notebook $nb text="\t{\r"
	Notebook $nb text="\t\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\tif (FSOObj.FileExists(item)){\r"
	Notebook $nb text="\t\t\tFSOObj.DeleteFile(item);\r"
	Notebook $nb text="\t\t\treturn true;\r"
	Notebook $nb text="\t\t} else if (FSOObj.FolderExists(item) ) {\r"
	Notebook $nb text="\t\t\tFSOObj.DeleteFolder(Common.stripTrailingSlash(item));\r"
	Notebook $nb text="\t\t\treturn true;\r"
	Notebook $nb text="\t\t} else {\r"
	Notebook $nb text="\t\t\treturn false;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.ExistsFile ) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.ExistsFile = function (path)\r"
	Notebook $nb text="\t{\r"
	Notebook $nb text="\t\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\treturn FSOObj.FileExists(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="if ( !Scripting.FileSystemObject.ExistsFolder ) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.ExistsFolder = function (path){\r"
	Notebook $nb text="\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\treturn FSOObj.FolderExists(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.isFolder ) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.isFolder = function (path){\r"
	Notebook $nb text="\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\treturn FSOObj.FolderExists(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.isEmptyFolder ) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.isEmptyFolder = function (path){\r"
	Notebook $nb text="\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\tif(FSOObj.FileExists(path)){\r"
	Notebook $nb text="\t\t\treturn false;\r"
	Notebook $nb text="\t\t}else if (FSOObj.FolderExists(path)){\t\r"
	Notebook $nb text="\t\t\tvar folderObj=FSOObj.GetFolder(path);\r"
	Notebook $nb text="\t\t\tif ((folderObj.Files.Count+folderObj.SubFolders.Count)==0){\r"
	Notebook $nb text="\t\t\t\treturn true;\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn false;\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.CreateFolder) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.CreateFolder = function (path){\r"
	Notebook $nb text="\t\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\tFSOObj.CreateFolder(path);\r"
	Notebook $nb text="\t\treturn FSOObj.FolderExists(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.ExistsItem) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.ExistsItem = function (path){\r"
	Notebook $nb text="\t\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="\t\treturn FSOObj.FolderExists(path)||FSOObj.FileExists(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Scripting.FileSystemObject.getFullPath) {\r"
	Notebook $nb text="\tScripting.FileSystemObject.getFullPath = function (path){\r"
	Notebook $nb text="\t\tvar FSOObj= new ActiveXObject(\"Scripting.FileSystemObject\");\r"
	Notebook $nb text="        return FSOObj.GetAbsolutePathName(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//   Shell.Application extensions\r"
	Notebook $nb text="if ( ! this.Shell ) {\r"
	Notebook $nb text="\tvar Shell = {};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if (! Shell.Application ) {\r"
	Notebook $nb text="\tShell.Application={};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ExistsFolder ) {\r"
	Notebook $nb text="\tShell.Application.ExistsFolder = function(path){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar targetObject = new Object;\r"
	Notebook $nb text="\t\tvar targetObject=ShellObj.NameSpace(path);\r"
	Notebook $nb text="\t\tif (typeof targetObject === 'undefined' || targetObject == null ){\r"
	Notebook $nb text="\t\t\treturn false;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn true;\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ExistsSubItem ) {\r"
	Notebook $nb text="\tShell.Application.ExistsSubItem = function(path){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar targetObject = new Object;\r"
	Notebook $nb text="\t\tvar targetObject=ShellObj.NameSpace(Common.getParent(path));\r"
	Notebook $nb text="\t\tif (typeof targetObject === 'undefined' || targetObject == null ){\r"
	Notebook $nb text="\t\t\treturn false;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tvar subItem=targetObject.ParseName(Common.getName(path));\r"
	Notebook $nb text="\t\tif(subItem === 'undefined' || subItem == null ){\r"
	Notebook $nb text="\t\t\treturn false;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn true;\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ItemCounterL1 ) {\r"
	Notebook $nb text="\tShell.Application.ItemCounterL1 = function(path){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar targetObject = new Object;\r"
	Notebook $nb text="\t\tvar targetObject=ShellObj.NameSpace(path);\r"
	Notebook $nb text="\t\tif (targetObject != null ){\r"
	Notebook $nb text="\t\t\treturn targetObject.Items().Count;\t\r"
	Notebook $nb text="\t\t} else {\r"
	Notebook $nb text="\t\t\treturn 0;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="// shell application item.size returns the size of uncompressed state of the file.\r"
	Notebook $nb text="if ( ! Shell.Application.getSize ) {\r"
	Notebook $nb text="\tShell.Application.getSize = function(path){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar targetObject = new Object;\r"
	Notebook $nb text="\t\tvar targetObject=ShellObj.NameSpace(path);\r"
	Notebook $nb text="\t\tif (! Shell.Application.ExistsFolder (path)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(path + \"does not exists or the file is incorrect type.Be sure you are using full path to"
	Notebook $nb text=" the file\");\r"
	Notebook $nb text="\t\t\treturn 0;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (typeof size === 'undefined'){\r"
	Notebook $nb text="\t\t\tvar size=0;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (targetObject != null ){\r"
	Notebook $nb text="\t\t\t\r"
	Notebook $nb text="\t\t\tfor (var i=0; i<targetObject.Items().Count;i++){\r"
	Notebook $nb text="\t\t\t\tif(!targetObject.Items().Item(i).IsFolder){\r"
	Notebook $nb text="\t\t\t\t\tsize=size+targetObject.Items().Item(i).Size;\r"
	Notebook $nb text="\t\t\t\t} else if (targetObject.Items().Item(i).Count!=0){\r"
	Notebook $nb text="\t\t\t\t\tsize=size+Shell.Application.getSize(targetObject.Items().Item(i).Path);\r"
	Notebook $nb text="\t\t\t\t}\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t} else {\r"
	Notebook $nb text="\t\t\treturn 0;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\treturn size;\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="if ( ! Shell.Application.TakeAction ) {\r"
	Notebook $nb text="\tShell.Application.TakeAction = function(destination,item, move ,option){\r"
	Notebook $nb text="\t\tif(typeof destination != 'undefined' && move){\r"
	Notebook $nb text="\t\t\tdestination.MoveHere(item,option);\r"
	Notebook $nb text="\t\t} else if(typeof destination != 'undefined') {\r"
	Notebook $nb text="\t\t\tdestination.CopyHere(item,option);\r"
	Notebook $nb text="\t\t} \r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="//ProcessItem and  ProcessSubItems can be used both for zipping and unzipping\r"
	Notebook $nb text="// When an item is zipped another process is ran and the control is released\r"
	Notebook $nb text="// but when the script stops also the copying to the zipped file stops.\r"
	Notebook $nb text="// Though the zipping is transactional so a zipped files will be visible only after the zipping is done\r"
	Notebook $nb text="// and we can rely on items count when zip operation is performed. \r"
	Notebook $nb text="// Also is impossible to compress an empty folders.\r"
	Notebook $nb text="// So when it comes to zipping two additional checks are added - for empty folders and for count of item"
	Notebook $nb text="s at the \r"
	Notebook $nb text="// destination.\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ProcessItem ) {\r"
	Notebook $nb text="\tShell.Application.ProcessItem = function(toProcess, destination  , move ,isZipping,option){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tdestinationObj=ShellObj.NameSpace(destination);\r"
	Notebook $nb text="\t\t\t\r"
	Notebook $nb text="\t\tif (destinationObj!= null ){\r"
	Notebook $nb text="\t\t\tif (isZipping && Scripting.FileSystemObject.isEmptyFolder(toProcess)) {\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(toProcess +\" is an empty folder and will be not processed\");\r"
	Notebook $nb text="\t\t\t\treturn;\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t\tShell.Application.TakeAction(destinationObj,toProcess, move ,option);\r"
	Notebook $nb text="\t\t\tvar destinationCount=Shell.Application.ItemCounterL1(destination);\r"
	Notebook $nb text="\t\t\tvar final_destination=destination + \"\\\\\" + Common.getName(toProcess);\r"
	Notebook $nb text="\t\t\t\r"
	Notebook $nb text="\t\t\tif (isZipping && !Shell.Application.ExistsSubItem(final_destination)) {\r"
	Notebook $nb text="\t\t\t\tCommon.WaitForCount(destination\r"
	Notebook $nb text="\t\t\t\t\t,destinationCount+1,Shell.Application.ItemCounterL1);\r"
	Notebook $nb text="\t\t\t} else if (isZipping && Shell.Application.ExistsSubItem(final_destination)){\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(final_destination + \" already exists and task cannot be completed\");\r"
	Notebook $nb text="\t\t\t\treturn;\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t}\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ProcessSubItems ) {\r"
	Notebook $nb text="\tShell.Application.ProcessSubItems = function(toProcess, destination  , move ,isZipping ,option){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar destinationObj=ShellObj.NameSpace(destination);\r"
	Notebook $nb text="\t\tvar toItemsToProcess=new Object;\r"
	Notebook $nb text="\t\ttoItemsToProcess=ShellObj.NameSpace(toProcess).Items();\r"
	Notebook $nb text="\t\t\t\r"
	Notebook $nb text="\t\tif (destinationObj!= null ){\r"
	Notebook $nb text="\t\t\t\t\t\t\r"
	Notebook $nb text="\t\t\tfor (var i=0;i<toItemsToProcess.Count;i++) {\r"
	Notebook $nb text="\t\t\t\t\r"
	Notebook $nb text="\t\t\t\tif (isZipping && Scripting.FileSystemObject.isEmptyFolder(toItemsToProcess.Item(i).Path)){\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\t\t\t\tWScript.Echo(\"\");\r"
	Notebook $nb text="\t\t\t\t\tWScript.Echo(toItemsToProcess.Item(i).Path + \" is empty and will be not processed\");\r"
	Notebook $nb text="\t\t\t\t\tWScript.Echo(\"\");\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\t\t\t} else {\r"
	Notebook $nb text="\t\t\t\t\tShell.Application.TakeAction(destinationObj,toItemsToProcess.Item(i),move,option);\r"
	Notebook $nb text="\t\t\t\t\tvar destinationCount=Shell.Application.ItemCounterL1(destination);\r"
	Notebook $nb text="\t\t\t\t\tif (isZipping) {\r"
	Notebook $nb text="\t\t\t\t\t\tCommon.WaitForCount(destination,destinationCount+1,Shell.Application.ItemCounterL1);\r"
	Notebook $nb text="\t\t\t\t\t}\r"
	Notebook $nb text="\t\t\t\t}\r"
	Notebook $nb text="\t\t\t}\t\r"
	Notebook $nb text="\t\t}\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! Shell.Application.ListItems ) {\r"
	Notebook $nb text="\tShell.Application.ListItems = function(parrentObject){\r"
	Notebook $nb text="\t\tvar ShellObj=new ActiveXObject(\"Shell.Application\");\r"
	Notebook $nb text="\t\tvar targetObject = new Object;\r"
	Notebook $nb text="\t\tvar targetObject=ShellObj.NameSpace(parrentObject);\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\tif (! Shell.Application.ExistsFolder (parrentObject)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(parrentObject + \"does not exists or the file is incorrect type.Be sure the full path the"
	Notebook $nb text=" path is used\");\r"
	Notebook $nb text="\t\t\treturn;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (typeof initialSCount == 'undefined') {\r"
	Notebook $nb text="\t\t\tinitialSCount=(parrentObject.split(\"\\\\\").length-1);\r"
	Notebook $nb text="\t\t\tWScript.Echo(parrentObject);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tvar spaces=function(path){\r"
	Notebook $nb text="\t\t\tvar SCount=(path.split(\"\\\\\").length-1)-initialSCount;\r"
	Notebook $nb text="\t\t\tvar s=\"\";\r"
	Notebook $nb text="\t\t\tfor (var i=0;i<=SCount;i++) {\r"
	Notebook $nb text="\t\t\t\ts=\" \"+s;\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t\treturn s;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tvar printP = function (item,end){\r"
	Notebook $nb text="\t\t\tif (flat) {\r"
	Notebook $nb text="\t\t\t\tWScript.Echo(targetObject.Items().Item(i).Path+end);\r"
	Notebook $nb text="\t\t\t}else{\r"
	Notebook $nb text="\t\t\t\tWScript.Echo( spaces(targetObject.Items().Item(i).Path)+targetObject.Items().Item(i).Name+end);\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\tif (targetObject != null ){\r"
	Notebook $nb text="\t\t\tvar folderPath=\"\";\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\t\t\tfor (var i=0; i<targetObject.Items().Count;i++) {\r"
	Notebook $nb text="\t\t\t\t\tif(targetObject.Items().Item(i).IsFolder && targetObject.Items().Item(i).Count==0 ){\r"
	Notebook $nb text="\t\t\t\t\t\tprintP(targetObject.Items().Item(i),\"\\\\\");\r"
	Notebook $nb text="\t\t\t\t\t} else if (targetObject.Items().Item(i).IsFolder){\r"
	Notebook $nb text="\t\t\t\t\t\tfolderPath=parrentObject+\"\\\\\"+targetObject.Items().Item(i).Name;\r"
	Notebook $nb text="\t\t\t\t\t\tprintP(targetObject.Items().Item(i),\"\\\\\")\r"
	Notebook $nb text="\t\t\t\t\t\tShell.Application.ListItems(folderPath);\t\t\t\t\t\t\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\t\t\t\t} else {\r"
	Notebook $nb text="\t\t\t\t\t\tprintP(targetObject.Items().Item(i),\"\")\r"
	Notebook $nb text="\t\t\t\t\t\t\r"
	Notebook $nb text="\t\t\t\t\t}\r"
	Notebook $nb text="\t\t\t\t}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="//     ZIP Utils\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils ) {\r"
	Notebook $nb text="\tvar ZIPUtils = {};\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.ZipItem) {\t\r"
	Notebook $nb text="\tZIPUtils.ZipItem = function(source, destination ) {\r"
	Notebook $nb text="\t\tif (!Scripting.FileSystemObject.ExistsFolder(source)) {\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"\");\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"file \" + source +\" does not exist\");\r"
	Notebook $nb text="\t\t\tWScript.Quit(2);\t\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsFile(destination) && force ) {\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(destination);\r"
	Notebook $nb text="\t\t\tADODB.Stream.writeFile(destination,ZIP_DATA);\r"
	Notebook $nb text="\t\t} else if (!Scripting.FileSystemObject.ExistsFile(destination)) {\r"
	Notebook $nb text="\t\t\tADODB.Stream.writeFile(destination,ZIP_DATA);\r"
	Notebook $nb text="\t\t} else {\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"Destination \"+destination+\" already exists.Operation will be aborted\");\r"
	Notebook $nb text="\t\t\tWScript.Quit(15);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tsource=Scripting.FileSystemObject.getFullPath(source);\r"
	Notebook $nb text="\t\tdestination=Scripting.FileSystemObject.getFullPath(destination);\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tShell.Application.ProcessItem(source,destination,move,true ,NO_PROGRESS_BAR);\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.ZipDirItems) {\t\r"
	Notebook $nb text="\tZIPUtils.ZipDirItems = function(source, destination ) {\r"
	Notebook $nb text="\t\tif (!Scripting.FileSystemObject.ExistsFolder(source)) {\r"
	Notebook $nb text="\t\t\tWScript.Echo();\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"file \" + source +\" does not exist\");\r"
	Notebook $nb text="\t\t\tWScript.Quit(2);\t\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsFile(destination) && force ) {\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(destination);\r"
	Notebook $nb text="\t\t\tADODB.Stream.writeFile(destination,ZIP_DATA);\r"
	Notebook $nb text="\t\t} else if (!Scripting.FileSystemObject.ExistsFile(destination)) {\r"
	Notebook $nb text="\t\t\tADODB.Stream.writeFile(destination,ZIP_DATA);\r"
	Notebook $nb text="\t\t} else {\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"Destination \"+destination+\" already exists.Operation will be aborted\");\r"
	Notebook $nb text="\t\t\tWScript.Quit(15);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tsource=Scripting.FileSystemObject.getFullPath(source);\r"
	Notebook $nb text="\t\tdestination=Scripting.FileSystemObject.getFullPath(destination);\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tShell.Application.ProcessSubItems(source, destination, move ,true,NO_PROGRESS_BAR);\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (move){\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(source);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.Unzip) {\t\r"
	Notebook $nb text="\tZIPUtils.Unzip = function(source, destination ) {\r"
	Notebook $nb text="\t\tif(!Shell.Application.ExistsFolder(source) ){\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"Either the target does not exist or is not a correct type\");\r"
	Notebook $nb text="\t\t\treturn;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsItem(destination) && force ) {\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(destination);\r"
	Notebook $nb text="\t\t} else if (Scripting.FileSystemObject.ExistsItem(destination)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(\"Destination \" + destination + \" already exists\");\r"
	Notebook $nb text="\t\t\treturn;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tScripting.FileSystemObject.CreateFolder(destination);\r"
	Notebook $nb text="\t\tsource=Scripting.FileSystemObject.getFullPath(source);\r"
	Notebook $nb text="\t\tdestination=Scripting.FileSystemObject.getFullPath(destination);\r"
	Notebook $nb text="\t\tShell.Application.ProcessSubItems(source, destination, move ,false,NO_PROGRESS_BAR);\t\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (move){\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(source);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="    }\t\t\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.AddToZip) {\r"
	Notebook $nb text="\tZIPUtils.AddToZip = function(source, destination ) {\r"
	Notebook $nb text="\t\tif(!Shell.Application.ExistsFolder(destination)) {\r"
	Notebook $nb text="\t\t\tWScript.Echo(destination +\" is not valid path to/within zip.Be sure you are not using relative paths\""
	Notebook $nb text=");\r"
	Notebook $nb text="\t\t\tWscript.Exit(\"101\");\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif(!Scripting.FileSystemObject.ExistsItem(source)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(source +\" does not exist\");\r"
	Notebook $nb text="\t\t\tWscript.Exit(\"102\");\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tsource=Scripting.FileSystemObject.getFullPath(source);\r"
	Notebook $nb text="\t\tShell.Application.ProcessItem(source,destination,move,true ,NO_PROGRESS_BAR); \r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.UnzipItem) {\t\r"
	Notebook $nb text="\tZIPUtils.UnzipItem = function(source, destination ) {\r"
	Notebook $nb text="\r"
	Notebook $nb text="\t\tif(!Shell.Application.ExistsSubItem(source)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(source + \":Either the target does not exist or is not a correct type\");\r"
	Notebook $nb text="\t\t\treturn;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsItem(destination) && force ) {\r"
	Notebook $nb text="\t\t\tScripting.FileSystemObject.DeleteItem(destination);\r"
	Notebook $nb text="\t\t} else if (Scripting.FileSystemObject.ExistsItem(destination)){\r"
	Notebook $nb text="\t\t\tWScript.Echo(destination+\" - Destination already exists\");\r"
	Notebook $nb text="\t\t\treturn;\r"
	Notebook $nb text="\t\t} \r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tScripting.FileSystemObject.CreateFolder(destination);\r"
	Notebook $nb text="\t\tdestination=Scripting.FileSystemObject.getFullPath(destination);\r"
	Notebook $nb text="\t\tShell.Application.ProcessItem(source, destination, move ,false,NO_PROGRESS_BAR);\r"
	Notebook $nb text="\t\t                            \r"
	Notebook $nb text="    }\t\t\r"
	Notebook $nb text="}\r"
	Notebook $nb text="if ( ! this.ZIPUtils.getSize) {\t\r"
	Notebook $nb text="\tZIPUtils.getSize = function(path) {\r"
	Notebook $nb text="\t\t// first getting a full path to the file is attempted\r"
	Notebook $nb text="\t\t// as it's required by shell.application\r"
	Notebook $nb text="\t\t// otherwise is assumed that a file within a zip \r"
	Notebook $nb text="\t\t// is aimed\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\t//TODO - find full path even if the path points to internal for the \r"
	Notebook $nb text="\t\t// zip directory\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsFile(path)){\r"
	Notebook $nb text="\t\t\tpath=Scripting.FileSystemObject.getFullPath(path);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tWScript.Echo(Shell.Application.getSize(path));\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="if ( ! this.ZIPUtils.list) {\t\r"
	Notebook $nb text="\tZIPUtils.list = function(path) {\r"
	Notebook $nb text="\t\t// first getting a full path to the file is attempted\r"
	Notebook $nb text="\t\t// as it's required by shell.application\r"
	Notebook $nb text="\t\t// otherwise is assumed that a file within a zip \r"
	Notebook $nb text="\t\t// is aimed\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\t//TODO - find full path even if the path points to internal for the \r"
	Notebook $nb text="\t\t// zip directory\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\t// TODO - optional printing of each file uncompressed size\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t\tif (Scripting.FileSystemObject.ExistsFile(path)){\r"
	Notebook $nb text="\t\t\tpath=Scripting.FileSystemObject.getFullPath(path);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tShell.Application.ListItems(path);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////\r"
	Notebook $nb text="\r"
	Notebook $nb text="/////////////////////////////////////\r"
	Notebook $nb text="//   parsing'n'running\r"
	Notebook $nb text="function printHelp(){\r"
	Notebook $nb text="\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" list -source zipFile [-flat yes|no]\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tlist the content of a zip file\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tzipFile - absolute path to the zip file\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\t\tcould be also a directory or a directory inside a zip file or\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\t\tor a .cab file or an .iso file\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-flat - indicates if the structure of the zip will be printed as tree\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\t\tor with absolute paths (-flat yes).Default is yes.\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" list -source C:\\\\myZip.zip -flat no\" );\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" list -source C:\\\\myZip.zip\\\\inZipDir -flat yes\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" getSize -source zipFile\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tprints uncompressed size of the zipped file in bytes\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tzipFile - absolute path to the zip file\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\t\tcould be also a directory or a directory inside a zip file or\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\t\tor a .cab file or an .iso file\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" getSize -source C:\\\\myZip.zip\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" zipDirItems -source source_dir -destination destination.zip [-force yes|no"
	Notebook $nb text="] [-keep yes|no]\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tzips the content of given folder without the folder itself \");\r"
	Notebook $nb text="\tWScript.Echo( \"\tsource_dir - path to directory which content will be compressed\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tEmpty folders in the source directory will be ignored\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tdestination.zip - path/name  of the zip file that will be created\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-force - indicates if the destination will be overwritten if already exists.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-keep - indicates if the source content will be moved or just copied/kept.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" zipDirItems -source C:\\\\myDir\\\\ -destination C:\\\\MyZip.zip -keep yes"
	Notebook $nb text=" -force no\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" zipItem -source item -destination destination.zip [-force yes|no] [-keep y"
	Notebook $nb text="es|no]\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tzips file or directory to a destination.zip file \");\r"
	Notebook $nb text="\tWScript.Echo( \"\titem - path to file or directory which content will be compressed\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tIf points to an empty folder it will be ignored\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tIf points to a folder it also will be included in the zip file alike zipdiritems comma"
	Notebook $nb text="nd\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tEventually zipping a folder in this way will be faster as it does not process every el"
	Notebook $nb text="ement one by one\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tdestination.zip - path/name  of the zip file that will be created\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-force - indicates if the destination will be overwritten if already exists.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-keep - indicates if the source content will be moved or just copied/kept.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" zipItem -source C:\\\\myDir\\\\myFile.txt -destination C:\\\\MyZip.zip -ke"
	Notebook $nb text="ep yes -force no\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" unzip -source source.zip -destination destination_dir [-force yes|no] [-ke"
	Notebook $nb text="ep yes|no]\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tunzips the content of a zip file to a given directory \");\r"
	Notebook $nb text="\tWScript.Echo( \"\tsource - path to the zip file that will be expanded\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tEventually .iso , .cab or even an ordinary directory can be used as a source\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tdestination_dir - path to directory where unzipped items will be stored\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-force - indicates if the destination will be overwritten if already exists.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-keep - indicates if the source content will be moved or just copied/kept.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" unzip -source C:\\\\myDir\\\\myZip.zip -destination C:\\\\MyDir -keep no -"
	Notebook $nb text="force no\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" unZipItem -source source.zip -destination destination_dir [-force yes|no] "
	Notebook $nb text="[-keep yes|no]\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tunzips  a single within a given zip file to a destination directory\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tsource - path to the file/folcer within a zip  that will be expanded\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tEventually .iso , .cab or even an ordinary directory can be used as a source\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tdestination_dir - path to directory where unzipped item will be stored\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-force - indicates if the destination directory will be overwritten if already exists.\""
	Notebook $nb text=");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-keep - indicates if the source content will be moved or just copied/kept.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" unZipItem -source C:\\\\myDir\\\\myZip.zip\\\\InzipDir\\\\InzipFile -destina"
	Notebook $nb text="tion C:\\\\OtherDir -keep no -force yes\" );\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" unZipItem -source C:\\\\myDir\\\\myZip.zip\\\\InzipDir -destination C:\\\\Ot"
	Notebook $nb text="herDir \" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( scriptName + \" addToZip -source sourceItem -destination destination.zip  [-keep yes|no]\")"
	Notebook $nb text=";\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tadds file or folder to already exist zip file\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tsource - path to the item that will be processed\");\r"
	Notebook $nb text="\tWScript.Echo( \"\tdestination_zip - path to the zip where the item will be added\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t-keep - indicates if the source content will be moved or just copied/kept.\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\tdefault is yes\");\r"
	Notebook $nb text="\tWScript.Echo( \"Example:\");\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" addToZip -source C:\\\\some_file -destination C:\\\\myDir\\\\myZip.zip\\\\In"
	Notebook $nb text="zipDir -keep no \" );\r"
	Notebook $nb text="\tWScript.Echo( \"\t\" + scriptName + \" addToZip -source  C:\\\\some_file -destination C:\\\\myDir\\\\myZip.zip \" "
	Notebook $nb text=");\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tWScript.Echo( \"\tby Vasil \\\"npocmaka\\\" Arnaudov - npocmaka@gmail.com\" );\r"
	Notebook $nb text="\tWScript.Echo( \"\tver 0.1 \" );\r"
	Notebook $nb text="\tWScript.Echo( \"\tlatest version could be found here https://github.com/npocmaka/batch.scripts/blob/maste"
	Notebook $nb text="r/hybrids/jscript/zipjs.bat\" );\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="function parseArguments(){\r"
	Notebook $nb text="\tif (WScript.Arguments.Length==1 || WScript.Arguments.Length==2 || ARGS.Item(1).toLowerCase() == \"-help\""
	Notebook $nb text=" ||  ARGS.Item(1).toLowerCase() == \"-h\" ) {\r"
	Notebook $nb text="\t\tprintHelp();\r"
	Notebook $nb text="\t\tWScript.Quit(0);\r"
	Notebook $nb text="   }\r"
	Notebook $nb text="   \r"
	Notebook $nb text="   //all arguments are key-value pairs plus one for script name and action taken - need to be even numbe"
	Notebook $nb text="r\r"
	Notebook $nb text="\tif (WScript.Arguments.Length % 2 == 1 ) {\r"
	Notebook $nb text="\t\tWScript.Echo(\"Illegal arguments \");\r"
	Notebook $nb text="\t\tprintHelp();\r"
	Notebook $nb text="\t\tWScript.Quit(1);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\t//ARGS\r"
	Notebook $nb text="\tfor(var arg = 2 ; arg<ARGS.Length-1;arg=arg+2) {\r"
	Notebook $nb text="\t\tif (ARGS.Item(arg) == \"-source\") {\r"
	Notebook $nb text="\t\t\tsource = ARGS.Item(arg +1);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (ARGS.Item(arg) == \"-destination\") {\r"
	Notebook $nb text="\t\t\tdestination = ARGS.Item(arg +1);\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (ARGS.Item(arg).toLowerCase() == \"-keep\" && ARGS.Item(arg +1).toLowerCase() == \"no\") {\r"
	Notebook $nb text="\t\t\tmove=true;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (ARGS.Item(arg).toLowerCase() == \"-force\" && ARGS.Item(arg +1).toLowerCase() == \"no\") {\r"
	Notebook $nb text="\t\t\tforce=false;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t\tif (ARGS.Item(arg).toLowerCase() == \"-flat\" && ARGS.Item(arg +1).toLowerCase() == \"yes\") {\r"
	Notebook $nb text="\t\t\tflat=true;\r"
	Notebook $nb text="\t\t}\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="\tif (source == \"\"){\r"
	Notebook $nb text="\t\tWScript.Echo(\"Source not given\");\r"
	Notebook $nb text="\t\tprintHelp();\r"
	Notebook $nb text="\t\tWScript.Quit(59);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="var checkDestination=function(){\r"
	Notebook $nb text="\tif (destination == \"\"){\r"
	Notebook $nb text="\t\tWScript.Echo(\"Destination not given\");\r"
	Notebook $nb text="\t\tprintHelp();\r"
	Notebook $nb text="\t\tWScript.Quit(65);\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="}\r"
	Notebook $nb text="\r"
	Notebook $nb text="var main=function(){\r"
	Notebook $nb text="\tparseArguments();\r"
	Notebook $nb text="\tswitch (ARGS.Item(1).toLowerCase()) {\r"
	Notebook $nb text="\tcase \"list\":\r"
	Notebook $nb text="\t\tZIPUtils.list(source);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"getsize\":\r"
	Notebook $nb text="\t\tZIPUtils.getSize(source);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"zipdiritems\":\r"
	Notebook $nb text="\t\tcheckDestination();\r"
	Notebook $nb text="\t\tZIPUtils.ZipDirItems(source,destination);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"zipitem\":\r"
	Notebook $nb text="\t\tcheckDestination();\r"
	Notebook $nb text="\t\tZIPUtils.ZipDirItems(source,destination);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"unzip\":\r"
	Notebook $nb text="\t\tcheckDestination();\r"
	Notebook $nb text="\t\tZIPUtils.Unzip(source,destination);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"unzipitem\":\r"
	Notebook $nb text="\t\tcheckDestination();\r"
	Notebook $nb text="\t\tZIPUtils.UnzipItem(source,destination);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tcase \"addtozip\":\r"
	Notebook $nb text="\t\tcheckDestination();\r"
	Notebook $nb text="\t\tZIPUtils.AddToZip(source,destination);\r"
	Notebook $nb text="\t\tbreak;\r"
	Notebook $nb text="\tdefault:\r"
	Notebook $nb text="\t\tWScript.Echo(\"No valid switch has been passed\");\r"
	Notebook $nb text="\t\tprintHelp();\r"
	Notebook $nb text="\t\t\r"
	Notebook $nb text="\t}\r"
	Notebook $nb text="\t\r"
	Notebook $nb text="}\r"
	Notebook $nb text="main();\r"
	Notebook $nb text="//\r"
	Notebook $nb text="//////////////////////////////////////"
end

// ===================================== End of Un-Zipping ===================================== //
// ============================================================================================= //


//**************************************************************************************************************************************
//**************************************************************************************************************************************
Function GHW_MakeRecordOfProgress(MessageToRecord, [header, abortProgress])
	string MessageToRecord
	variable header, abortProgress
	
	if(ParamIsDefault(header))
		header=0
	endif
	if(ParamIsDefault(abortProgress))
		abortProgress=0
	endif
	print MessageToRecord
	variable FileNum
	string LogFileName="InstallRecord.log"
	PathInfo InstallerRecordPath
	if(V_Flag==0)
		NewPath /O/Q InstallerRecordPath  , SpecialDirPath("Desktop", 0, 0, 0 )
	endif
	GetFileFolderInfo/Q/Z/P=InstallerRecordPath  LogFileName
	if(V_Flag!=0)
		Open  /P=InstallerRecordPath /T=".txt"  FileNum  as LogFileName 
		Close FIleNum	
	endif
	Open /P=InstallerRecordPath  FileNum  as LogFileName
	if (strlen(S_fileName)<1)
		return 1
	endif
	FStatus FileNum
	FSetPos FileNum, V_logEOF
	if (V_logEOF<2 || header)			
		String str, head=SelectString(V_logEOF>2,"","\r\r\r\r")
		head += "********************************************************************************\r"
		head += "********************************************************************************\r"
		sprintf str,"       Starting Installion using  %s\r", IgorInfo(1)
		head += str
		sprintf str,"       on %s, %s\r", Secs2Date(DateTime,1), Secs2Time(DateTime,1)
		head += str
		sprintf str,"       Logging everything in history window to:\r\t\t\"%s\"\r\r\r",LogFileName
		head += str
		fprintf FileNum,head
		print head
	endif
	fprintf FileNum, MessageToRecord+"\r"
	Close FileNum
	if(abortProgress)
		Abort "Installation aborted due to error.\rPlease send the InstallRecord.log file from your Desktop to ilavsky@aps.anl.gov for analysis of the failure reason and debugging. "
	endif
	return 0
End
//**************************************************************************************************************************************
//**************************************************************************************************************************************

Function GHW_InstallPackage(PathToLocalData,PackageListxml)
	string PathToLocalData,PackageListxml
	DFREF saveDFR=GetDataFolderDFR()		// Get reference to current data folder
	SetDataFOlder root:Packages:GHInstaller
	
	//print PathToLocalData, PackageListxml
	variable fileID
	string FileContent="", tempStr
	string PackgListFiles, PackgListFilePaths, PackgListxopLinks, PackgListFileLinks
	PathToLocalData = RemoveEnding(PathToLocalData, ":")+":"		//make sure we have correct path ending to use
	//Open/R/Z fileID as PathToLocalData+PackageListxml
	GetFileFolderInfo/Z/Q PathToLocalData+PackageListxml
	if(V_flag!=0)
		GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+" - xml configuration file was not found",abortProgress=1 ) 
	endif
	FileContent = PadString(FileContent, V_logEOF, 0x20 )
	Open fileID  as PathToLocalData+PackageListxml
	FBinRead fileID, FileContent
	close fileID
	FileContent=GHI_XMLremoveComments(FileContent)		//get rid of comments, confuses the rest of the code...
	//FileContent now contains content of the xml configuration file...
	string InstallerText=GHI_XMLtagContents("PackageContent",FileContent)	//if nothing, wrong format
	if(strlen(InstallerText)<10)	//no real content
		SetDataFolder saveDFR					// Restore current data folder
		GHW_MakeRecordOfProgress("Abort in : "+GetRTStackInfo(3)+" - Nothing found in a file "+PathToLocalData+PackageListxml,abortProgress=1 ) 
	endif
	//known keywords: xopLinks for xop from Wavemetrics -> link to Igor Extensions (64-bit)
	//FileLinks for ipf files from Wavemetrics  -> link to User Procedures
	//and for ipf/ihf FolderFileLocation & File - copy from source to same place in User Procedures
	PackgListFiles			= GHW_ListPlatformSpecificValues(FileContent, "File", IgorInfo(2))
	PackgListFilePaths		= stringFromList(0,GHW_ListPlatformSpecificValues(FileContent, "FolderFileLocation", IgorInfo(2)),";")	
	PackgListxopLinks		= GHW_ListPlatformSpecificValues(FileContent, "xopLinks", IgorInfo(2))
	PackgListFileLinks 	= GHW_ListPlatformSpecificValues(FileContent, "FileLinks", IgorInfo(2))
	//these are list of files to copy and link as necessary
	variable j
	//process file and folders
	For(j=0;j<ItemsInList(PackgListFiles);j+=1)
		GHW_CopyOneFileFromDistribution(PathToLocalData, PackgListFilePaths, StringFromList(j,PackgListFiles,";"))
	endfor
	//process links. 
	For(j=0;j<ItemsInList(PackgListxopLinks);j+=1)
		GHW_CreateLinks( StringFromList(j,PackgListxopLinks,";"))
	endfor
	For(j=0;j<ItemsInList(PackgListFileLinks);j+=1)
		GHW_CreateLinks(StringFromList(j,PackgListFileLinks,";"))
	endfor
	
	
end
//**************************************************************************************************************************************
//**************************************************************************************************************************************


Function GHW_CreateLinks(FileToLink)
	string  FileToLink
	//the FileToLink is either Wavemetrics xop
	//of Wavemetrics ipf file. Nothing else supportede at this time. 
	FileToLink = ReplaceString("/", FileToLink, ":")
	string ExtOrProcPath
	string FileToLinkLoc
	if(StringMatch(FileToLink, "*.xop"))		//xop
		if(stringMatch(FileToLink,"* (64-bit)*"))
			ExtOrProcPath = "Igor Extensions (64-bit)"
		else	//old 32 bits
			ExtOrProcPath = "Igor Extensions"
		endif
	else
		ExtOrProcPath = "Igor Procedures"
	endif
	if(stringMatch(IgorInfo(2),"Macintosh"))
		FileToLinkLoc	=	FileToLink
	else		//windows, add .lnk to the name
		FileToLinkLoc	=	FileToLink+".lnk"
	endif
	string FileToLinkName=StringFromList(ItemsInList(FileToLinkLoc, ":")-1, FileToLinkLoc, ":")
	NewPath /O/Q targetFileFolderPath, SpecialDirPath("Igor Pro User Files", 0, 0, 0 )+ExtOrProcPath
	string IgorUserFilePathStr=SpecialDirPath("Igor Pro User Files", 0, 0, 0 )+ExtOrProcPath+":"
	NewPath /O/Q sourceFileFolderPath, SpecialDirPath("Igor Application", 0, 0, 0 )
	string SourceFileFolderPathStr = SpecialDirPath("Igor Application", 0, 0, 0 )
	//same process as with files, get rid of the old ones, if it can be done
	GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToLinkName+".deleteMe"
	if(V_Flag==0)		//file/xop found, get rid of it
		if(V_isFile)
			DeleteFile /P=targetFileFolderPath /Z FileToLinkName+".deleteMe"
			if(V_flag!=0)
				GHW_MakeRecordOfProgress("Could not delete "+FileToLinkName+".deleteMe")
			endif
		elseif(V_isFolder)
			DeleteFolder /P=targetFileFolderPath /Z FileToLinkName+".deleteMe"
			if(V_flag!=0)
				GHW_MakeRecordOfProgress("Could not delete "+FileToLinkName+".deleteMe")
			endif
		elseif(V_isAliasShortcut)
			DeleteFile /P=targetFileFolderPath /Z FileToLinkName+".deleteMe"
			if(V_flag!=0)
				GHW_MakeRecordOfProgress("Could not delete "+FileToLinkName+".deleteMe")
			endif		
		endif
		GHW_MakeRecordOfProgress("Deleted old file : "+FileToLinkName+".deleteMe")
	endif
	//OK, now we can, if needed rename existing file AND keep the user folder cleaner
	//now check for existing target file and delete/rename if necessary
	GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToLinkName
	if(V_Flag==0)		//old file/xop found, get rid of it
		if(V_isFile)
			DeleteFile /P=targetFileFolderPath /Z FileToLinkName
			if(V_flag!=0)
				MoveFile /O/P=targetFileFolderPath FileToLinkName as FileToLinkName+".deleteMe" 
				GHW_MakeRecordOfProgress("Moved to .deleteMe existing file : "+FileToLinkName)
			else
				GHW_MakeRecordOfProgress("Deleted existing file : "+FileToLinkName)
			endif
		elseif(V_isFolder)
			DeleteFolder /P=targetFileFolderPath /Z FileToLinkName
			if(V_flag!=0)
				MoveFolder /O/P=targetFileFolderPath FileToLinkName as FileToLinkName+".deleteMe" 
				GHW_MakeRecordOfProgress("Moved to .deleteMe existing file : "+FileToLinkName)
			else
				GHW_MakeRecordOfProgress("Deleted existing file : "+FileToLinkName)
			endif
		elseif(V_isAliasShortcut)
			DeleteFile /P=targetFileFolderPath /Z FileToLinkName
			if(V_flag!=0)
				MoveFile /O/P=targetFileFolderPath FileToLinkName as FileToLinkName+".deleteMe" 
				GHW_MakeRecordOfProgress("Moved to .deleteMe existing file : "+FileToLinkName)
			else
				GHW_MakeRecordOfProgress("Deleted existing file : "+FileToLinkName)
			endif		
		endif
		//print "Deleted/moved to .deleteMe existing file : "+FileToLinkName
	endif
	//now we should be able to make the alias
	//depends on platform and xop/not-xop...
	if(stringmatch(FileToLinkName,"*.xop*")&&stringMatch(IgorInfo(2),"Macintosh"))		//it is xop (folder) on Mac
		CreateAliasShortcut /D/I=0 /O /Z  (SourceFileFolderPathStr+FileToLink)   as    (IgorUserFilePathStr+FileToLinkName)  
		if(V_Flag==0)
			GHW_MakeRecordOfProgress("Created shortcut : "+S_path+ "  linking to : "+SourceFileFolderPathStr+FileToLink)
		else
			GHW_MakeRecordOfProgress("Could not create shortcut for "+IgorUserFilePathStr+FileToLinkName)
		endif
	else
		CreateAliasShortcut /I=0 /O /Z  (SourceFileFolderPathStr+FileToLink)   as    (IgorUserFilePathStr+removeEnding(FileToLinkName,".lnk"))  
		if(V_Flag==0)
			GHW_MakeRecordOfProgress("Created shortcut : "+S_path+ "  linking to : "+SourceFileFolderPathStr+FileToLink ) 
		else
			GHW_MakeRecordOfProgress("Could not create shortcut for "+IgorUserFilePathStr+FileToLinkName )
		endif
	endif
end
//**************************************************************************************************************************************
//**************************************************************************************************************************************


Function GHW_CopyOneFileFromDistribution(PathToLocalData, PackgListFilePaths, FileToCopy)
	string PathToLocalData, PackgListFilePaths, FileToCopy

	if(strlen(FileToCopy)<2)
		return 0
	endif
	FileToCopy =  ReplaceString("/", FileToCopy, ":")
	if(!StringMatch(FileToCopy[0],":" ))		//make this in relative path for 
		FileToCopy = ":"+FileToCopy
	endif
	//we get path to file/folder(xop) and will copy from source (PathToLocalData) to location
	//PackgListFilePaths is specific path where to look for the souce, not reproduced in target
	//FileToCopy is source and target path.
	//distribution is in PathToLocalData
	//target is in Igor User home area - Documents/Wavemetrics/Igor Pro 7 user Files
	//existing files needs to be deleted or if not possible, renamed into ....DeleteMe
	//any existing file with ....DeleteMe will be deleted first. 
	//Path where to put the files
	NewPath /O/Q targetFileFolderPath, SpecialDirPath("Igor Pro User Files", 0, 0, 0 ) 
	string IgorUserFilePathStr=SpecialDirPath("Igor Pro User Files", 0, 0, 0 )
	NewPath /O/Q sourceFileFolderPath, PathToLocalData+PackgListFilePaths
	//PathInfo sourceFileFolderPath
	//print S_Path+FileToCopy
	//variable fileNum
	string tempStr, igorCmd
	GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToCopy+".deleteMe"
	if(V_Flag==0)		//file/xop found, get rid of it
		if(V_isFile)
			DeleteFile /P=targetFileFolderPath /Z FileToCopy+".deleteMe"
			if(V_flag!=0)
				GHW_MakeRecordOfProgress("Could not delete "+FileToCopy+".deleteMe")
			endif
		elseif(V_isFolder)
				//			DeleteFolder /P=targetFileFolderPath /Z FileToCopy+".deleteMe"
				//here is nasty overwrite using OS script...
				PathInfo targetFileFolderPath
				tempStr = replaceString("::",S_Path+FileToCopy,":")
				tempStr=RemoveFromList(StringFromList(0,tempStr  , ":"), tempStr  , ":")
				tempStr = ParseFilePath(5, tempStr, "\\", 0, 0)
				tempStr = ReplaceString("\\", tempStr, "/")
				tempStr = "rm -Rdf  '/"+ReplaceString(".xop", tempStr, ".xop.deleteMe")+"'"
				sprintf igorCmd, "do shell script \"%s\"", tempStr
				//print igorCmd
				ExecuteScriptText igorCmd
				GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToCopy+".deleteMe"
				if(V_flag==0)
					GHW_MakeRecordOfProgress( "Could not delete folder/xop"+FileToCopy+".deleteMe")
				else
					GHW_MakeRecordOfProgress( "Deleted old file : "+FileToCopy+".deleteMe")
				endif
		elseif(V_isAliasShortcut)
			DeleteFile /P=targetFileFolderPath /Z FileToCopy+".deleteMe"
			if(V_flag!=0)
				GHW_MakeRecordOfProgress( "Could not delete "+FileToCopy+".deleteMe")
			endif		
		endif
		GHW_MakeRecordOfProgress( "Deleted old file : "+FileToCopy+".deleteMe")
	endif
	//OK, now we can, if needed rename existing file AND keep the user folder cleaner
	//now check for existing target file and delete/rename if necessary
	GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToCopy
	if(V_Flag==0)		//old file/xop found, get rid of it
		if(V_isFile)
			DeleteFile /P=targetFileFolderPath /Z FileToCopy
			if(V_flag!=0)
				MoveFile /O/P=targetFileFolderPath FileToCopy as FileToCopy+".deleteMe" 
				GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+FileToCopy)
			else
				GHW_MakeRecordOfProgress( "Deleted existing file : "+FileToCopy)		
			endif
		elseif(V_isFolder)
				GetFileFolderInfo/Q/Z/P=targetFileFolderPath  FileToCopy+".deleteMe"
				if(V_flag!=0)
					MoveFolder /O/P=targetFileFolderPath FileToCopy as FileToCopy+".deleteMe" 
					GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+FileToCopy)
				else
					GHW_MakeRecordOfProgress( "Cannot delete existing file : "+FileToCopy +" the old .deleteMe file is still present")		
				endif
		elseif(V_isAliasShortcut)
			DeleteFile /P=targetFileFolderPath /Z FileToCopy
			if(V_flag!=0)
				MoveFile /O/P=targetFileFolderPath FileToCopy as FileToCopy+".deleteMe" 
				GHW_MakeRecordOfProgress( "Moved to .deleteMe existing file : "+FileToCopy)
			else
				GHW_MakeRecordOfProgress( "Deleted existing file : "+FileToCopy)		
			endif
		endif
		//GHW_MakeRecordOfProgress( "Deleted/moved to .deleteMe existing file : "+FileToCopy)
	endif
	//and now we can copy the file/folder in the right place
	//first need to check the target folder exists...
	string tempFldrName
	string tmpIgorUserFilePathStr=IgorUserFilePathStr
	variable i
	for(i=0;i<(ItemsInList(FileToCopy,":")-1);i+=1)
		tempFldrName=StringFromList(i,FileToCopy,":")
		GetFileFolderInfo/Q/Z replaceString("::",IgorUserFilePathStr+tempFldrName,":") 
		if(V_Flag!=0)	//deas not exist, make it
			NewPath /C/O/Q tmpCreatePath  replaceString("::",IgorUserFilePathStr+tempFldrName,":")
			GHW_MakeRecordOfProgress( "Created new folder " + replaceString("::",IgorUserFilePathStr+tempFldrName,":"))
		endif
		tmpIgorUserFilePathStr = replaceString("::",IgorUserFilePathStr+tempFldrName,":")+":"
	endfor
	GetFileFolderInfo/Q/Z/P=sourceFileFolderPath  FileToCopy		//this is source file
	//GetFileFolderInfo/P=sourceFileFolderPath  FileToCopy		//this is source file
	//print S_Path
	if(V_Flag==0)				//exists...
		if(V_isFile)				//ipf, ihf, dll,... simply a file
			CopyFile /O/P=sourceFileFolderPath /Z  FileToCopy as replaceString("::",IgorUserFilePathStr+FileToCopy,":")
			if(V_flag)
				GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+"Failed to copy "+FileToCopy, abortProgress=1)
			endif
		elseif(V_isFolder)	//xops on Mac are folders
			CopyFolder /O /P=sourceFileFolderPath/Z  FileToCopy as replaceString("::",IgorUserFilePathStr+FileToCopy,":")
			if(V_flag)
				GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+"Failed to copy "+FileToCopy, abortProgress=1)
			endif	
		endif
		//note, this cannot handle links, separate code needed for making links. 
		GHW_MakeRecordOfProgress( "Copied " + FileToCopy + " from "+PathToLocalData+PackgListFilePaths)
	else
		GHW_MakeRecordOfProgress( "Abort in : "+GetRTStackInfo(3)+"ERROR: Source File not found : " +FileToCopy, abortprogress=1)
	endif
	return 1
end
//**************************************************************************************************************************************
//**************************************************************************************************************************************

Function/T GHW_FindNonStandardPckgVerNum(PathToLocalFile)
	string  PathToLocalFile
	
	return ""
end
//**************************************************************** 
//**************************************************************** 

Function GHW_GenerateHelp()
	doWindow Inst_Help
	if(V_Flag)
		DoWindow/F Inst_Help
	else

		String nb = "Inst_Help"
		NewNotebook/N=$nb/F=1/V=1/K=1/ENCG={3,1}/W=(525,40.25,1172.25,797)
		Notebook $nb defaultTab=36
		Notebook $nb showRuler=1, rulerUnits=1, updating={1, 60}
		Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
		Notebook $nb newRuler=Header, justification=1, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
		Notebook $nb ruler=Header, fSize=12, fStyle=1, text="Installer for Irena, Nika, and Indra packages\r"
		Notebook $nb text="using Github depository.\r"
		Notebook $nb text="https://github.com/jilavsky/SAXS_IgorCode\r"
		Notebook $nb ruler=Normal, fSize=-1, fStyle=-1, text="\r"
		Notebook $nb fStyle=2, text="Jan Ilavsky, November 2016\r"
		Notebook $nb fStyle=-1, text="\r"
		Notebook $nb fStyle=1, text="NOTE: ", fStyle=-1, text="Install ONLY packages you really need. Here are hints...\r"
		Notebook $nb text="Irena ... package for modeling of small-angle scattering data (and reflectivity)\r"
		Notebook $nb text="Nika ... package for reduction of data from area detectors (pinhole cameras)\r"
		Notebook $nb text="Indra ... package for data reduction of USAXS data (NOTE: unless you measuered on my instrument or own R"
		Notebook $nb text="igaku USAXS, this is _NOT_ for you) \r"
		Notebook $nb text="\r"
		Notebook $nb fStyle=1, text="Requirements", fStyle=-1, text=": \r"
		Notebook $nb text="1.   Igor 7 and higher.  \r"
		Notebook $nb text="2.   Access to the depository or downloaded zip file of a release from this depository\r"
		Notebook $nb text="3.  This Igor experiment\r"
		Notebook $nb text="\r"
		Notebook $nb fStyle=1, text="Use", fStyle=-1, text=": \r"
		Notebook $nb text="Get the \"Install/Uninstall Package\" Panel of this Igor experiment - if not up, select from \"Instal Packa"
		Notebook $nb text="ges\" menu the option \"Open GitHub GUI\". \r"
		Notebook $nb text="Using Igor to download everything : \r"
		Notebook $nb text="\tUncheck (if checked) \"Use local Folder\"\r"
		Notebook $nb text="\tPush \"Check packages versions\", Installer will check what is available in depository\r"
		Notebook $nb text="\tIn Select release release to install in \"Select release to install\". \r"
		Notebook $nb text="\t\tPick packages to install (or unistall) using checkboxes\r"
		Notebook $nb text="\t\tPush \"Install/Update\" or \"Unistall\" buttons as needed\r"
		Notebook $nb text="Manual download :\r"
		Notebook $nb text="\tDownload release zip file you from Github and unzip on your desktop\r"
		Notebook $nb text="\tSelect \"Use Local Folder\" in the main GUI\r"
		Notebook $nb text="\t\tPick packages to install (or unistall) using checkboxes\r"
		Notebook $nb text="\t\tPush \"Install/Update\" or \"Unistall\" buttons as needed\r"
		Notebook $nb text="\r"
		Notebook $nb text="when succesfully finished, you will see \"All done.\" in the history area. Or you will get error message w"
		Notebook $nb text="ith instructions. \r"
		Notebook $nb text="\r"
		Notebook $nb text="After you are done delete the distribution zip file, unzipped folder and the logfile (InstallRecord.txt)"
		Notebook $nb text=" file from desktop. ", textRGB=(0,1,2), text="If bad things happen, please, send me the log file \""
		Notebook $nb textRGB=(0,0,0), text="InstallRecord.txt", textRGB=(0,1,2), text="\" from your desktop.\r"
		Notebook $nb textRGB=(0,0,0), text="\r"
		Notebook $nb text="note: \tdownload of distribution zip file may take a long time (they are around 50-80Mb). You may want to"
		Notebook $nb text=" keep it in case you want to reinstall in short future. If proper file is found on desktop, it will be u"
		Notebook $nb text="sed even in subsequent installations. \r"
		Notebook $nb text="\tInstall xop files based on bit-version you instend to use (or simply install both). The xop packages ar"
		Notebook $nb text="e needed for any package.\r"
		Notebook $nb text="\tAfter any unistallation, you should reinstall packages you intend to use. Another words, since packages"
		Notebook $nb text=" share libraries, after any uninstallation the other packages are likely unusable. \r"
		Notebook $nb text="\r"
		Notebook $nb fStyle=1, text="Beta versions", fStyle=-1
		Notebook $nb text=": If you need/want latest beta version, check checkbox \"Include Beta releases\" and list in \"Select relea"
		Notebook $nb text="se to install\" will include Beta versions and \"master\".  Beta versions are designated by depository main"
		Notebook $nb text="tainer, \"master\" is latest versions now (when installing)  available in the depository. Note, there are "
		Notebook $nb text="no guarrantees the master will even work!\r"
		Notebook $nb text="\r"
		Notebook $nb text="*** ", fSize=11, fStyle=1, textRGB=(52428,1,1)
		Notebook $nb text="You can always update to the latest version of the packages using this experiment. When I update the on "
		Notebook $nb text="line depository, this experiment will pick the listing and re-download ALL packages again. To check whic"
		Notebook $nb text="h version is the last one available on the web, use button \"Check packages versions"
		Notebook $nb fSize=-1, fStyle=-1, textRGB=(0,1,2), text="\".\r"
		Notebook $nb text="\r"
		Notebook $nb text="ilavsky@aps.anl.gov\r"
	endif
end