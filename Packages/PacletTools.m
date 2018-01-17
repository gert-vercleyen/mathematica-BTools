(* ::Package:: *)



(* ::Section:: *)
(*PacletTools*)



(* ::Subsubsection::Closed:: *)
(*Paclets*)



PackageScopeBlock[
	PacletInfo::usage=
		"Extracts the Paclet from a PacletInfo.m file";
	PacletInfoAssociation::usage=
		"Converts a Paclet into an Association";
	PacletExpression::usage=
		"Generates a Paclet expression for a directory";	
	PacletExpressionBundle::usage=
		"Bundles a PacletExpression into a PacletInfo.m file";
	PacletBundle::usage=
		"Bundles a paclet site from a directory in a standard build directory";
	PacletAutoPaclet::usage=
		"Autogenerates a paclet";
	PacletLookup::usage=
		"Applies Lookup to paclets";
	];


PacletInfoGenerate::usage=
	"Generates a PacletInfo.m file from a directory";


PacletOpen::usage=
	"Opens an installed paclet from its \"Location\"";


(* ::Subsubsection::Closed:: *)
(*Paclet Sites*)



PackageScopeBlock[
	PacletSiteURL::usage=
		"Provides the default URL for a paclet site";
	PacletSiteInfo::usage=
		"Extracts a PacletSite from a .paclet or PacletSite.mz file";
	PacletSiteInfoDataset::usage=
		"Formats a PacletSite into a Dataset";
	PacletSiteBundle::usage=
		"Bundles a PacletSite.mz from a collection of PacletInfo specs";
	];


(* ::Subsubsection::Closed:: *)
(*Installers*)



PacletInstallerURL::usage=
	"Provides the default URL for a paclet installer";
PacletUploadInstaller::usage=
	"Uploads the paclet installer script";
PacletUninstallerURL::usage=
	"Provides the default URL for a paclet installer";
PacletUploadUninstaller::usage=
	"Uploads the paclet installer script";


(* ::Subsubsection::Closed:: *)
(*Uploads*)



PackageScopeBlock[
	$PacletUploadPatterns::usage=
		"Possible forms for PacletUpload";
	$PacletRemovePatterns::usage=
		"Possible forms for PacletRemove";
	$PacletFilePatterns::usage=
		"Possible forms for a paclet file";
	$PacletUploadAccount::usage=
		"The account to which paclets get uploaded by default";
	PacletSiteUpload::usage=
		"Uploads a PacletSite.mz file";
	PacletAPIUpload::usage=
		"Creates a paclet link via an API based upload";
	];


PacletUpload::usage=
	"Uploads a paclet to a server";
PacletRemove::usage=
	"Removes a paclet from a server";


PackageScopeBlock[
	PacletSiteInstall::usage=
		"Installs from the Installer.m file if possible";
	PacletSiteUninstall::usage=
		"Uninstalls from the Uninstaller.m file if possible";
	];


(* ::Subsubsection::Closed:: *)
(*Downloads*)



(*PacletDownload::usage=
	"Downloads pieces of a paclet from a server";*)


(* ::Subsubsection::Closed:: *)
(*Install*)



PacletInstallPaclet::usage="Installs a paclet from a URL";


Begin["`Private`"];


(* ::Subsection:: *)
(*Config*)



(*$pacletConfigLoaded//ClearAll*)


If[$pacletConfigLoaded//TrueQ//Not,
	$PacletBuildRoot=$TemporaryDirectory;
	$PacletBuildExtension=
		"_paclets";
	$PacletBuildDirectory:=
		FileNameJoin@{$PacletBuildRoot,$PacletBuildExtension};
	$PacletExtension="paclets";
	$PacletServerBase=CloudObject;
	$PacletUseKeyChain=False;
	$FormatPaclets=False;
	Replace[
		SelectFirst[
			`Package`PackageFilePath["Private","PacletConfig."<>#]&/@{"m","wl"},
			FileExistsQ
			],
			f_String:>Get@f
		]
	];
$pacletConfigLoaded=True


(* ::Subsection:: *)
(*Error Handling*)



If[!ValueQ@$pacletToolsExceptionTag,
	$pacletToolsExceptionTag=Automatic
	];
If[!ValueQ@$pacletToolsCallBack,
	$pacletToolsCallBack=Automatic
	];
If[!ValueQ@$pacletToolsDefaultCallBack,
	$pacletToolsDefaultCallBack=#&
	];
pacletToolsCatchBlock//Clear;
pacletToolsCatchBlock[exc_, f_:Automatic]:=
	Function[Null,
		Block[{
			$pacletToolsExceptionTag=
				If[$pacletToolsExceptionTag===Automatic,
					exc,
					$pacletToolsExceptionTag
					]
			},
			Catch[#, 
				exc, 
				Replace[f, 
					Automatic:>
						Replace[$pacletToolsCallBack,
							Automatic:>
								Replace[$pacletToolsTmpCallBack,
									{
										Automatic:>
											$pacletToolsDefaultCallBack,
										e_:>
											($pacletToolsTmpCallBack=Automatic;e)
										}
									]
							]
					]
				]
			],
		HoldAllComplete
		];
pacletToolsThrow[v_:$Failed, tag_:Automatic]:=
	Throw[v, Replace[tag, Automatic:>$pacletToolsExceptionTag]]


(* ::Subsection:: *)
(*Paclets*)



(* ::Subsubsection::Closed:: *)
(*PacletInfo*)



PacletInfoAssociation[PacletManager`Paclet[k__]]:=
	With[{o=Keys@Options[PacletExpression]},
		KeySortBy[First@FirstPosition[o,#]&]
		]@
		With[{base=
			KeyMap[Replace[s_Symbol:>SymbolName[s]],<|k|>]
			},
			ReplacePart[base,
				"Extensions"->
					AssociationThread[
						First/@Lookup[base,"Extensions",{}],
						Association@*Rest/@Lookup[base,"Extensions",{}]
						]
				]
			];
PacletInfoAssociation[infoFile_]:=
	Replace[PacletInfo[infoFile],{
		p:PacletManager`Paclet[__]:>
			PacletInfoAssociation@p,
		_-><||>
		}];
PacletInfo[infoFile:(_String|_File)?FileExistsQ]:=
	With[{pacletInfo=
		Replace[infoFile,{
			d:(_String|_File)?DirectoryQ:>
				FileNameJoin@{d,"PacletInfo.m"},
			f:(_String|_File)?(FileExtension[#]=="paclet"&&FileExistsQ[#]&):>
				With[{rd=CreateDirectory[]},
					First@ExtractArchive[f,rd,"*PacletInfo.m"]
					]
			}]
		},
		(If[
			StringContainsQ[
				Nest[DirectoryName,pacletInfo,3],
				$TemporaryDirectory
				]&&
					(StringTrim[DirectoryName@pacletInfo,$PathnameSeparator~~EndOfString]!=
						StringTrim[
							If[DirectoryQ@infoFile,
								infoFile,
								DirectoryName@infoFile],
							$PathnameSeparator~~EndOfString
							]),
				DeleteDirectory[Nest[DirectoryName,pacletInfo,2],DeleteContents->True]
				];#)&@
		If[FileExistsQ@pacletInfo,
			PacletManager`CreatePaclet[pacletInfo],
			PacletManager`Paclet[]
			]
		];
PacletInfo[pac_PacletManager`Paclet]:=
	With[{pf=pac["Location"]},
		If[FileExistsQ@FileNameJoin@{pf,"PacletInfo.m"},
			PacletInfo@FileNameJoin@{pf,"PacletInfo.m"},
			pac
			]
		];
PacletInfo[p_String]:=
	Replace[PacletManager`PacletFind[p],
		{pac_}:>
			PacletInfo[pac]
		]


(* ::Subsubsection::Closed:: *)
(*PacletDocsInfo*)



Options[PacletDocsInfo]={
	"Language"->"English",
	"Root"->None,
	"LinkBase"->None,
	"MainPage"->None(*,
	"Resources"\[Rule]None*)
	};
PacletDocsInfo[ops:OptionsPattern[]]:=
	SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
		With[{o=Options@PacletDocsInfo},Position[o,First@#]&]];
PacletDocsInfo[dest_String?DirectoryQ,ops:OptionsPattern[]]:=
	With[{lang=
		FileBaseName@
			SelectFirst[
				FileNames["*",FileNameJoin@{dest,"Documentation"}],
				DirectoryQ]},
		If[MissingQ@lang,
			{},
			PacletDocsInfo[ops,
				"Language"->
					lang,
				"MainPage"->
					Replace[
						Map[
							FileNameTake[#,-2]&,
							Replace[
								FileNames["*.nb",
									FileNameJoin@{dest,"Documentation",lang,"Guides"}],{
									{}:>
										FileNames["*.nb",
											FileNameJoin@{dest,"Documentation",lang},
											2]
								}]
							],{
						{}->None,
						p:{__}:>
							First@
								SortBy[StringTrim[p,".nb"],
									EditDistance[FileBaseName@dest,FileBaseName@#]&]
						}]
				]
			]
		];


(* ::Subsubsection::Closed:: *)
(*PacletExtensionData*)



Options[PacletExtensionData]={
	"Documentation"->Automatic,
	"Kernel"->Automatic,
	"FrontEnd"->Automatic,
	"Resource"->Automatic,
	"AutoCompletionData"->Automatic
	};
PacletExtensionData[pacletInfo_Association,dest_,ops:OptionsPattern[]]:=
	Merge[Merge[Last]]@{
		Replace[Lookup[pacletInfo,"Extensions"],
			Except[_Association?AssociationQ]:>
				<||>
			],
		{
			Replace[OptionValue["Documentation"],{
				Automatic:>
					If[Length@
							FileNames["*.nb",
									FileNameJoin@{dest,"Documentation"},
									\[Infinity]]>0,
						"Documentation"->
							PacletDocsInfo[dest],
						Nothing
						],
				r:_Rule|{___Rule}:>
					"Documentation"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["Kernel"],{
				Automatic:>
					If[AnyTrue[
							FileNameJoin@Flatten@{dest,#}&/@
								{FileBaseName[dest]<>".wl",FileBaseName[dest]<>".m",
									{"Kernel","init.m"}},
							FileExistsQ
							],
						"Kernel"->
							<|
									Root -> ".", 
									Context -> FileBaseName@dest<>"`"
									|>,
						Nothing
						],
				r:_Rule|{___Rule}:>
					"Kernel"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["FrontEnd"],{
				Automatic:>
					If[Length@Select[Not@*DirectoryQ]@
							Flatten@Join[
								Map[
									FileNames["*.nb",
										FileNameJoin@{dest,"FrontEnd","Documentation",#},
										\[Infinity]]&,{
									"ReferencePages",
									"Guides",
									"Tutorials"
									}],
								Map[
									FileNames["*",
										FileNameJoin@{dest,"FrontEnd",#},
										\[Infinity]
										]&,{
									"TextResources",
									"SystemResources",
									"StyleSheets",
									"Palettes"
									}]
								]>0,
							"FrontEnd"->
								If[
									DirectoryQ@
										FileNameJoin@{dest,
											"FrontEnd",
											"TextResources"
											}||
									DirectoryQ@
										FileNameJoin@{dest,
											"FrontEnd",
											"SystemResources"
											},
									<|Prepend->True|>,
									<||>
									],
							Nothing
							],
				r:_Rule|{___Rule}:>
					"FrontEnd"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["Resource"],{
				Automatic:>
					Which[Length@
							Select[
								FileNames["*",
									FileNameJoin@{dest,"Data"},
									\[Infinity]],
								Not@DirectoryQ@#&&
									Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
								]>0,
							"Resource"->
								<|
									"Root" -> "Data",
									"Resources" -> 
										Map[
											FileNameDrop[#,
												FileNameDepth[dest]+1
												]&,
											Select[
												FileNames["*",
													FileNameJoin@{dest,"Data"},
													\[Infinity]],
												Not@DirectoryQ@#&&
													Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
												]
											]
									|>,
						Length@
							Select[
								FileNames["*",
									FileNameJoin@{dest,"Resources"},
									\[Infinity]],
								Not@DirectoryQ@#&&
									Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
								]>0,
							"Resource"->
								<|
									"Root" -> "Resources",
									"Resources" -> 
										Map[
											FileNameDrop[#,
												FileNameDepth[dest]+1
												]&,
											Select[
												FileNames["*",
													FileNameJoin@{dest,"Resources"}
													],
												Not@StringMatchQ[FileNameTake@#,".DS_Store"]&
												]
											]
									|>,
						True,
							Nothing
							],
				r:_Rule|{___Rule}:>
					"Resource"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}],
			Replace[OptionValue["AutoCompletionData"],{
				Automatic:>
					If[Length@
							FileNames["*.tr",
									FileNameJoin@{dest,"AutoCompletionData"},
									\[Infinity]]>0,
						"AutoCompletionData"->
							<|
								"Root" -> "AutoCompletionData"
								|>,
						Nothing
						],
				r:_Rule|{___Rule}:>
					"Documentation"->Association@Flatten@{r},
				Except[_Association]->Nothing
				}]
			}
		};


(* ::Subsubsection::Closed:: *)
(*PacletExpression*)



Options[PacletExpression]=
	Join[
		{
			"Name"->"MyPaclet",
			"Version"->Automatic,
			"Creator"->Automatic,
			"Description"->Automatic,
			"Root"->Automatic,
			"WolframVersion"->Automatic,
			"MathematicaVersion"->Automatic,
			"Internal"->Automatic,
			"Loading"->Automatic,
			"Qualifier"->Automatic,
			"SystemID"->Automatic,
			"BuildNumber"->Automatic,
			"Tags"->Automatic,
			"Icon"->Automatic,
			"Categories"->Automatic,
			"Authors"->Automatic,
			"Extensions"->Automatic
			},
		Options@PacletExtensionData
		];
PacletExpression[ops:OptionsPattern[]]:=
	PacletManager`Paclet@@
		SortBy[DeleteCases[DeleteDuplicatesBy[{ops},First],_->None],
			With[{o=Options@PacletExpression},Position[o,First@#]&]
			];


(*PacletExpression[dir]~~PackageAddUsage~~
	"generates a Paclet expression from dir";*)
Options[iPacletExpression]=
	Options[PacletExpression];
iPacletExpression[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]
	]:=
	With[{pacletInfo=KeyDrop[PacletInfoAssociation[dest], "Location"]},
		PacletExpression[
			Sequence@@FilterRules[{ops},
				Except["Kernel"|"Documentation"|"Extensions"|"FrontEnd"]],
			"Name"->FileBaseName@dest,
			"Extensions"->
				Replace[OptionValue["Extensions"],{
					Automatic:>
						KeyValueMap[Prepend[Normal@#2,#]&,
							PacletExtensionData[pacletInfo,
								dest,
								FilterRules[{ops},
									Options@PacletExtensionData
									]
								]
							],
					Except[_List]:>
						With[{baseData=
							PacletExtensionData[pacletInfo,
								dest,
								FilterRules[{ops},
									Options@PacletExtensionData
									]
								]},
							Map[
								Replace[OptionValue[#],{
									Automatic:>
										Replace[Lookup[baseData,#],{
											a_Association:>
												Flatten@{#,DeleteDuplicates@Normal@a},
											_->Nothing
											}],
									r:_Rule|{___Rule}|_Association:>
										Flatten@{
											#,
											DeleteDuplicates@Normal@r
											},
									_->Nothing
									}]&,
								Keys@Options[PacletExtensionData]
								]
						]
					}],
			"Version"->
				Replace[OptionValue@"Version",
					Automatic:>
						With[{pointVersions=
							StringSplit[
								ToString[Lookup[pacletInfo,"Version","1.0.-1"]],
								"."
								]
							},
							StringJoin@Riffle[
								If[Length@pointVersions>1,
									Append[Most@pointVersions,
										ToString[ToExpression[Last@pointVersions]+1]
										],
									{pointVersions,"1"}],
								"."]
							]
					],
				Sequence@@Normal@pacletInfo
			]
		];
PacletExpression[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]
	]:=
	iPacletExpression[
		dest,
		FilterRules[{ops}, Options@PacletExpression]
		]


(* ::Subsubsection::Closed:: *)
(*PacletExpressionBundle*)



Options[PacletExpressionBundle]=
	Options[PacletExpression];
PacletExpressionBundle[paclet,dest]~~`Package`PackageAddUsage~~
	"bundles paclet into a PacletInfo.m file in dest";
PacletExpressionBundle[
	paclet_PacletManager`Paclet,
	dest_String?DirectoryQ]:=
	With[{pacletFile=FileNameJoin@{dest,"PacletInfo.m"}},
		Begin["PacletManager`"];
		Block[{$ContextPath={"System`","PacletManager`"}},
			With[{pac=Map[ToExpression[#[[1]]]->#[[2]]&, Select[paclet,OptionQ]]},
				Export[pacletFile,pac]
				]
			];
		End[];
		pacletFile
		];
PacletExpressionBundle[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]
	]:=
	PacletExpressionBundle[
		PacletExpression[dest,ops],
		dest
		];


Options[PacletInfoGenerate]=
	Options[PacletExpressionBundle];
PacletInfoGenerate[
	dest_String?DirectoryQ,
	ops:OptionsPattern[]
	]:=
	PacletExpressionBundle[dest,ops]


(* ::Subsubsection::Closed:: *)
(*PacletLookup*)



PacletLookup[p:{__PacletManager`Paclet},props_]:=
	Lookup[PacletManager`PacletInformation/@p,props];
PacletLookup[p_PacletManager`Paclet,props_]:=
	Lookup[PacletManager`PacletInformation@p,props];
PacletLookup[p:_String|{_String,_String},props_]:=
	PacletLookup[PacletManager`PacletFind[p],props];


(* ::Subsubsection::Closed:: *)
(*PacletOpen*)



PacletOpen[p_,which:_:First]:=
	With[{locs=PacletLookup[p,"Location"]},
		With[{files=
			Flatten@{
				Replace[
					which@Flatten@{locs},
					HoldPattern[which[f_]]:>f
					]
				}
			},
			Map[SystemOpen,files];
			files
			]/;
			AllTrue[Flatten@{locs},StringQ]
		];


(* ::Subsubsection::Closed:: *)
(*PacletAutoPaclet*)



Options[PacletAutoPaclet]=
	Options[PacletExpressionBundle];
PacletAutoPaclet[
	dir:_String?DirectoryQ|Automatic:Automatic, 
	f_String?FileExistsQ,
	ops:OptionsPattern[]
	]:=
	With[{bn=FileBaseName[f]},
		With[{d=CreateDirectory[FileNameJoin@{Replace[dir, Automatic:>Directory[]], bn}]},
			Which[
				DirectoryQ@f,
					CopyDirectory[d, f];
					If[!FileExistsQ@FileNameJoin@{d, "PacletInfo.m"},
						PacletExpressionBundle[d, ops]
						],
				MatchQ[FileExtension[f],
					Alternatives@@CreateArchiveDump`$CONVERTERS
					],
					ExtractArchive[f, d];
					If[!FileExistsQ@FileNameJoin@{d, "PacletInfo.m"},
						PacletExpressionBundle[d, ops]
						],
				True,
					Switch[FileExtension[f],
						"m"|"wl",
							CopyFile[f, FileNameJoin@{d, FileNameTake@f}],
						"nb",
							CopyFile[f, FileNameJoin@{d, FileNameTake@f}];
							Export[
								FileNameJoin@{d, FileBaseName[f]<>".m"},
								"(*Open package notebook*)
CreateDocument[
	Import@
		StringReplace[$InputFileName,\".m\"->\".nb\"]
	]",
							"Text"
							];
						];
					PacletExpressionBundle[d, ops]
				];
			d
			]
		]


(* ::Subsubsection::Closed:: *)
(*PacletBundle*)



PacletBundle[dir]~`Package`PackageAddUsage~
	"creates a .paclet file from dir and places it in the default build directory";
Options[PacletBundle]=
	Join[
		{
			"RemovePaths"->{},
			"RemovePatterns"->{},
			"BuildRoot":>$PacletBuildRoot
			},
		Options[PacletExpressionBundle]
		];
PacletBundle[dir:(_String|_File)?DirectoryQ, ops:OptionsPattern[]]:=
	With[{
		rmpaths=
			Replace[
				Flatten@List@OptionValue["RemovePaths"],
				Except[{__?StringPattern`StringPatternQ}]:>{}
				],
		rmpatterns=
			Replace[
				Flatten@List@OptionValue["RemovePatterns"],
				Except[{__?StringPattern`StringPatternQ}]:>{}
				],
		pacletDir=
			FileNameJoin@{
				OptionValue["BuildRoot"],
				$PacletBuildExtension,
				FileBaseName@dir
				}
		},
		If[!FileExistsQ@DirectoryName[pacletDir],
			CreateDirectory@DirectoryName[pacletDir]
			];
		If[Length@Join[rmpaths,rmpatterns]===0,
			(* just do a simple PackPaclet and move the paclet *)
			With[{p=PacletManager`PackPaclet[dir]},
				RenameFile[
					p,
					FileNameJoin@{
						DirectoryName[pacletDir],
						FileNameTake[p]
						},
					OverwriteTarget->True
					];
				FileNameJoin@{
					DirectoryName[pacletDir],
					FileNameTake[p]
					}
				],
			(* copy the dir, remove the dangerous junk, etc. *)
			If[!FileExistsQ@DirectoryName[pacletDir],
				CreateDirectory@DirectoryName[pacletDir]
				];
			If[FileExistsQ@pacletDir,
				DeleteDirectory[pacletDir,DeleteContents->True]
				];
			CopyDirectory[dir,pacletDir];
			Do[
				With[{p=If[Not@FileExistsQ@path,FileNameJoin@{pacletDir,path},path]},
					If[DirectoryQ@p,
						DeleteDirectory[p,
							DeleteContents->True
							],
						If[FileExistsQ@p,DeleteFile[p]]
						]
					],
				{path,
					Join[
						Flatten[{OptionValue["RemovePaths"]},1],
						FileNameDrop[#,FileNameDepth@pacletDir]&/@
							FileNames[OptionValue["RemovePatterns"],pacletDir,\[Infinity]]
						]}
				];
			With[{pacletFile=PacletManager`PackPaclet[pacletDir]},
				pacletFile
				]
			]
		];


(*
	Prep the dir first when passed just a file
	*)


PacletBundle[f:(_String|_File)?FileExistsQ, ops:OptionsPattern[]]:=
	With[{d=CreateDirectory[]},
		(DeleteDirectory[d, DeleteContents->True];#)&@
			PacletBundle[
				PacletAutoPaclet[d, f,
					FilterRules[
						{
							ops,
							"Description"->
								TemplateApply[
									"Autogenerated paclet from ``",
									FileNameTake[f]
									]
							},
						Options[PacletExpressionBundle]
						]
					], 
				ops
				]
		]


(* ::Subsection:: *)
(*Sites*)



(* ::Subsubsection::Closed:: *)
(*pacletStandardServerName*)



pacletStandardServerName[serverName_]:=
	Replace[
		Replace[
			serverName,
			{
				Automatic:>
					"PacletServer",
				Default:>
					Lookup[$PacletServer,"ServerName"]
				}
			],{
		e:Except[_String]:>(Nothing)
		}]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerBase*)



pacletStandardServerBase[serverBase_,
	cc_:Automatic,
	kc_:Automatic
	]:=
	If[StringQ[#]&&DirectoryQ@#, ExpandFileName[#], #]&@
		Replace[
			Replace[
				serverBase,
				{
					Default:>
						Lookup[$PacletServer,"ServerBase"]
					}
				],{
			e:Except[
				_String|_CloudObject|_CloudDirectory|CloudObject|CloudDirectory|
				_File|_URL
				]:>
					Replace[CloudDirectory[],
						Except[_CloudObject]:>
							(
							pacletCloudConnect[serverBase, cc, kc];
							CloudDirectory[]
							)
						],
			f:(_String|_File)?DirectoryQ:>
				ExpandFileName[f]
			}]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerExtension*)



pacletStandardServerExtension[serverExtension_]:=
	Replace[
		Replace[
			serverExtension,
			{
				Automatic:>
					Nothing,
				Default:>
					Lookup[$PacletServer, "ServerExtension"]
				}
			],{
		e:Except[_String|{___String}]:>{},
		s_String:>DeleteCases[""]@URLParse[s,"Path"]
		}]


(* ::Subsubsection::Closed:: *)
(*pacletStandardServerPermissions*)



pacletStandardServerPermissions[perms_]:=
	Replace[
		Replace[
			perms,
			Automatic|Default:>
				Lookup[$PacletServer,Permissions]
			],{
		e:Except[_String]:>$Permissions
		}]


(* ::Subsubsection::Closed:: *)
(*PacletSiteURL*)



PacletSiteURL::nobby="Unkown site base ``";


$PacletUploadDomains=
	<|
		"www.github.com"->
			Function[PacletAPIUpload["GitHub", ##]],
		"drive.google.com"->
			Function[PacletAPIUpload["GoogleDrive", ##]],
		"www.dropbox.com"->
			Function[PacletAPIUpload["Dropbox", ##]]
		|>


pacletCloudConnect[base_, cc_, useKeyChain_]:=
	(
		With[
			{
				kc=
					Replace[useKeyChain,
						Automatic:>
							$PacletUseKeyChain
						],
				ccReal=
					Replace[
						cc,
						Automatic:>
							Replace[base,
								Verbatim[CloudObject][o_,___]:>
									DeleteCases[URLParse[o, "Path"], ""][[2]]
								]
						]
				},
			Replace[
				ccReal,
				{
					a:$KeyChainCloudAccounts?(kc&):>
						KeyChainConnect[a],
					k_Key:>
						KeyChainConnect[k],
					s_String:>
						If[$WolframID=!=s||
							(StringQ[$WolframID]&&StringSplit[$WolframID, "@"][[1]]=!=s),
							If[kc, 
								KeyChainConnect,
								CloudConnect
								][If[!StringContainsQ[s, "@"], s<>"@gmail.com", s]]
							],
					{s_String,p_String}:>
						If[$WolframID=!=s, 
							If[kc, 
								KeyChainConnect,
								CloudConnect
								][s,p]
							],
					{s_String,e___,CloudBase->b_,r___}:>
						If[$CloudBase=!=b||$WolframID=!=s,
							If[kc, 
								KeyChainConnect,
								CloudConnect
								][s,e,CloudBase->b,r]
							],
					_:>
						If[!StringQ[$WolframID], CloudConnect[]]
					}
				]
			];
		If[!StringQ[$WolframID],
			Message[PacletSiteURL::nowid];
			pacletToolsThrow[]
			]
		);


Options[PacletSiteURL]=
	{
		"ServerBase"->
			Automatic,
		"ServerName"->
			Automatic,
		"ServerExtension"->
			Automatic,
		"Username"->
			Automatic,
		CloudConnect->
			Automatic,
		"UseKeyChain"->
			Automatic
		};
PacletSiteURL::nowid="$WolframID isn't a string. Try cloud connecting";
PacletSiteURL[ops:OptionsPattern[]]:=
	pacletToolsCatchBlock["PacletSiteURL"]@
		With[
			{
				ext=
					pacletStandardServerExtension@OptionValue["ServerExtension"],
				base=
					pacletStandardServerBase[
						OptionValue["ServerBase"],
						OptionValue@CloudConnect, 
						OptionValue@"UseKeyChain"
						],
				name=
					pacletStandardServerName@OptionValue["ServerName"]
				},
			Switch[base,
				$CloudBase|"Cloud"|CloudObject|CloudDirectory|
					_CloudObject|_CloudDirectory,
					pacletCloudConnect[
						base, 
						OptionValue@CloudConnect, 
						OptionValue@"UseKeyChain"
						];
					URLBuild@
						<|
							"Scheme"->"http",
							"Domain"->
								Replace[base,
									{
										"Cloud"|CloudObject|CloudDirectory->
											URLParse[$CloudBase,"Domain"],
										d_String|CloudObject[d_,___]:>
											URLParse[d,"Domain"]
										}
									],
							"Path"->
								Flatten@{
									"objects",
									Replace[OptionValue["Username"],
										{
											Automatic:>
												URLParse[$CloudRootDirectory[[1]], "Path"][[-1]]
											}
										],
									ext,
									name
									}
							|>,
				_String?(KeyMemberQ[$PacletUploadDomains, URLParse[#, "Domain"]]&),
					pacletToolsThrow["Non-cloud paclet support not yet complete"],
				_String?(AllTrue[URLParse[#, {"Scheme", "Domain"}], #=!=None&]&),
					URLBuild@
						Flatten@{
							base,
							ext,
							name
							},
				_String?(StringMatchQ[FileNameJoin@{$RootDirectory,"*"}]),
					"file://"<>
						URLBuild@Key["Path"]@URLParse@
							URLBuild@Flatten@
								{
									base,
									ext,
									name
									}//StringReplace[URLDecode[#]," "->"%20"]&,
				_?SyncPathQ,
					"file://"<>
						URLBuild@Key["Path"]@URLParse@
							URLBuild@Join[{
								SyncPath[
									Replace[
										StringSplit[base,":",2],{
										{r_,p_}:>
											StringJoin@{r,":",
												URLBuild@Flatten@{
													ext,
													p}
												},
										{r_}:>
											StringJoin@{r,":",
												URLBuild@Flatten@{
													ext
													}
												}
										}]
									],
								name
								}]//StringReplace[URLDecode[#]," "->"%20"]&,
				_,
					Message[PacletSiteURL::nobby,base];
					pacletToolsThrow[]
				]
			];


(* ::Subsubsection::Closed:: *)
(*PacletSiteFiles*)



Options[PacletSiteFiles]=
	Join[{
		"MergePacletInfo"->Automatic
		},
		Options@PacletSiteURL
		];
$PacletFilePatterns=
	(_String|_URL|_File|_PacletManager`Paclet)|
		(
			(_String|_PacletManager`Paclet)->
				(_String|_URL|_File|_PacletManager`Paclet)
			);
PacletSiteFiles[infoFiles_,ops:OptionsPattern[]]:=
	DeleteCases[Except[$PacletFilePatterns]]@
		Replace[
			Replace[
				Flatten@{ infoFiles, OptionValue["MergePacletInfo"] },{
					(p_PacletManager`Paclet->_):>
						p,
					(_->f_):>f
					},
				1
				],{
			s_String?DirectoryQ:>
				Which[
					FileExistsQ@FileNameJoin@{s,"PacletSite.mz"},
						FileNameJoin@{s,"PacletSite.mz"},
					FileExistsQ@FileNameJoin@{s,"PacletInfo.m"},
						FileNameJoin@{s,"PacletInfo.m"},
					True,
						Replace[FileNames["*PacletSite.mz",s],{
							{}:>
								FileNames["*PacletInfo.m",s]
							}]
					],
			s_String?FileExistsQ:>s,
			s_String?(
				MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}],
					{_String,None,{__,_?(StringMatchQ[Except["."]..])}}
					]&
				):>
				StringReplace[URLBuild@{s,"PacletSite.mz"},
					StartOfString~~"file:"->
						"file://"
					],
			None:>
				Sequence@@{},
			All:>
				StringReplace[
					URLBuild@{
						PacletSiteURL[
							FilterRules[{ops},Options@PacletSiteURL]
							],
						"PacletSite.mz"
						},{
					StartOfString~~"file:"->"file://",
					"%20"->" "
					}],
			s_String?(
				MatchQ[Lookup[URLParse[#],{"Scheme","Domain","Path"}],
					{None,None,{_?(StringMatchQ[Except["."]..])}}
					]&):>
				StringReplace[
					URLBuild@{
						PacletSiteURL[
							"ServerName"->s,
							FilterRules[{ops},Options@PacletSiteURL]
							],
						"PacletSite.mz"
						},{
					StartOfString~~"file:"->"file://",
					"%20"->" "
					}]
			},
			1];


(* ::Subsubsection::Closed:: *)
(*PacletSiteInfo*)



pacletSiteMExtract[mzFile_,dirExt_:Automatic]:=
	If[FileExistsQ@mzFile,
		With[{dir=CreateDirectory[]},
			Replace[
				Quiet[ExtractArchive[mzFile,dir,"PacletSite.m"],ExtractArchive::infer],
				Except[{__}]:>
					Quiet[
						ExtractArchive[mzFile,dir,"*/PacletInfo.m"],
						ExtractArchive::infer
						]
				]
			],
		$Failed
		];


PacletSiteInfo//Clear


Options[PacletSiteInfo]=
	Options[PacletSiteFiles];
(*PacletSiteInfo[specs]~~`Package`PackageAddUsage~~
	"extracts the PacletSite info stored in specs";*)
PacletSiteInfo[infoFiles:Except[_?OptionQ]|All|{}:All,ops:OptionsPattern[]]:=
	With[{
		pacletInfos=
			Which[
				MatchQ[#,_PacletManager`Paclet],
					#,
				StringMatchQ[Replace[#,File[f_]|URL[f_]:>f],"file://*"],
					With[{f=FileNameJoin@URLParse[#]["Path"]},
						Which[
							FileExtension[f]=="mz",
								pacletSiteMExtract[f],
							True,
								f
							]
						],
				FileExistsQ@#,
					Which[
						MatchQ[FileExtension[#],"mz"|"paclet"|"tmp"],
							pacletSiteMExtract[#],
						True,
							#
						],
				URLParse[#,"Scheme"]=!=None,
					If[
						StringMatchQ[Last@URLParse[#,"Path"],
							"*.paclet"|"PacletSite.m"|
							"PacletInfo.m"|"PacletSite.mz"],
						With[{file=
							FileNameJoin@{
								$TemporaryDirectory,
								Last@URLParse[#,"Path"]
								}},
							If[Between[URLSave[#,file,"StatusCode"],{200,299}],
								Which[
									StringMatchQ[FileExtension[file],"m"|"wl"],
										file,
									StringMatchQ[FileExtension[file],"mz"|"paclet"|"tmp"],
										pacletSiteMExtract[file],
									True,
										Nothing
									],
								Nothing
								]
							],
						With[{ext=StringJoin@RandomSample[Alphabet[],5]},
							Quiet@CreateDirectory@
								FileNameJoin@{
									$TemporaryDirectory,
									ext
									};
							With[{
								file=
									FileNameJoin@{
										$TemporaryDirectory,
										ext,
										"PacletSite.mz"
										}
								},
								If[
									Between[
										URLSave[URLBuild@{#,"PacletSite.mz"},file,"StatusCode"],
										{200,299}
										],
									pacletSiteMExtract[file,ext],
									Nothing
									]
								]
							]
						],
					True,
						Nothing
				]&/@PacletSiteFiles[Flatten@{infoFiles},ops]//Flatten
		},
		Begin["PacletManager`"];
		With[{pacletsite=
			PacletManager`PacletSite@@
				Flatten@
					Map[
						With[{imp=
							Replace[If[MatchQ[#,(_String|_File)?FileExistsQ],Import[#],#],
								{
									PacletManager`PacletSite[p___]:>p,
									e:Except[_PacletManager`Paclet|{__PacletManager`Paclet}]:>
										(Nothing)
									}
								]
							},
							Replace[#,
								{
									(s_Symbol->v_):>
										(SymbolName[s](*s*)->v),
									(s_String->v_):>
										(*ToExpression[s]*)s->v,
									_:>
										Sequence@@{}
									},
								1]&/@Flatten@{imp}
							]&,
						pacletInfos
						]//DeleteDuplicatesBy[
							Lookup[Association@@#,{"Name","Version"}]&
							]
			},
			End[];
			DeleteCases[pacletsite,Except[_PacletManager`Paclet]]
			]
		];


(* ::Subsubsection::Closed:: *)
(*PacletSiteInfoDataset*)



(*PacletSiteInfoDataset::usages="";
PacletSiteInfoDataset[site]~`Package`PackageAddUsage~
	"formats a Dataset from the PacletInfo in site";
PacletSiteInfoDataset[files]~`Package`PackageAddUsage~
	"formats from the PacletSiteInfo in files";*)


PacletSiteInfoDataset//Clear


Options[PacletSiteInfoDataset]=
	Options[PacletSiteInfo];
PacletSiteInfoDataset[PacletManager`PacletSite[p___]]:=
	Dataset@Map[PacletInfoAssociation,{p}];
PacletSiteInfoDataset[files:Except[_?OptionQ]|All|{}:All,ops:OptionsPattern[]]:=
	PacletSiteInfoDataset[PacletSiteInfo[files,ops]];


(* ::Subsubsection::Closed:: *)
(*PacletSiteBundle*)



Options[PacletSiteBundle]=
	Join[
		{
			"BuildRoot":>$TemporaryDirectory,
			"FilePrefix"->None
			},
		Options@PacletSiteInfo
		];
(*PacletSiteBundle[infoFiles]~~`Package`PackageAddUsage~~
	"bundles the PacletInfo.m files found in infoFiles into a compressed PacletSite file";*)
PacletSiteBundle[dir_String?DirectoryQ, ops:OptionsPattern[]]:=
	PacletSiteBundle[
		FileNames["*.paclet",dir,2],
		ops
		];
PacletSiteBundle[
	infoFiles:$PacletFilePatterns|{$PacletFilePatterns...},
	ops:OptionsPattern[]
	]:=
	Export[
		FileNameJoin@{
			With[{d=
				FileNameJoin@{
					OptionValue["BuildRoot"],
					$PacletBuildExtension
					}
				},
				If[!FileExistsQ@d,
					CreateDirectory@d
					];
				d
				],
			Replace[OptionValue["FilePrefix"],{
				Automatic:>
					With[{f=First@{infoFiles}},
						If[StringMatchQ[FileNameTake[f],"*.*"],
							DirectoryName[f],
							FileBaseName[f]
							]
						]<>"-",
				s_String:>(s<>"-"),
				_->""
				}]<>"PacletSite.mz"
			},
		PacletSiteInfo[
			infoFiles,
			FilterRules[{ops},
				Options@PacletSiteInfo
				]
			],
		{"ZIP", "PacletSite.m"}
		];


(* ::Subsection:: *)
(*Installers*)



Options[PacletInstallerURL]=
	Options@PacletSiteURL;
PacletInstallerURL[ops:OptionsPattern[]]:=
	StringReplace[
		URLBuild@{PacletSiteURL[ops],"Installer.m"},
		StartOfString~~"file:"->"file://"
		];


Options[PacletInstallerScript]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletInstallerURL,{
			"InstallSite"->
				False,
			"PacletSite"->
				Automatic,
			"PacletNames"->
				Automatic,
			"PacletSiteFile"->
				Automatic
			}
			];
PacletInstallerScript[ops:OptionsPattern[]]:=
	Module[{
		ps=
			Replace[OptionValue["PacletSite"],
				Automatic:>
					With[{p=
						PacletSiteURL@
							FilterRules[{ops},Options@PacletSiteURL]
						},
						If[URLParse[p,"Scheme"]==="file",
							FileNameJoin@URLParse[p,"Path"],
							p
							]
						]
				],
		info=
			Normal@PacletSiteInfoDataset@
				Replace[OptionValue@"PacletSiteFile",
					Except[(_File|_String)?FileExistsQ]:>
						Replace[OptionValue["PacletSite"],
							Automatic:>
								StringReplace[
									URLBuild@{
										PacletSiteURL@
											FilterRules[{ops},
												Options@PacletSiteURL],
										"PacletSite.mz"
										},
									StartOfString~~"file:"->"file://"
									]
						]
					],
		names
		},
		names=
			DeleteMissing@
				Replace[OptionValue["PacletNames"],
					Automatic:>
						Lookup[info,{"Name","Version"}]
					];
			Which[StringMatchQ[ps,"http:*"|"https:*"|"file:*"],
				If[OptionValue@"InstallSite"//TrueQ,
					With[{
						desc=
							"Paclet Server for: "<>
								StringRiffle[First/@Replace[names,s_String:>{s},1],", "],
						site=ps,
						paclets=names
						},
						Hold[
							PacletManager`PacletSiteAdd[site,
								desc,
								Prepend->True
								];
							PacletManager`PacletInstall[#,
								"Site"->site
								]&/@paclets
							]
						],
					With[{
						pacletFiles=
							URLBuild@{
								ps,
								"Paclets",
								#[["Name"]]<>"-"<>#[["Version"]]<>".paclet"
								}&/@info
						},
						Hold[
							With[{file=
								FileNameJoin@{
									$TemporaryDirectory,
									URLParse[#,"Path"]//Last
									}
								},
								If[Between[URLSave[#,file,"StatusCode"],{200,299}],
									PacletManager`PacletInstall@file,
									PacletInstallerScript::savefail=
										"No paclet found at ``";
									Message[PacletInstallerScript::savefail,file];
									$Failed
									]
								]&/@pacletFiles
							]
						]
					],
				StringMatchQ[ps,
					($UserBaseDirectory|$HomeDirectory|
						$BaseDirectory|$InstallationDirectory|$RootDirectory)
						~~___],
					Replace[
						Replace[
							SelectFirst[
								Thread@Hold[{
									$UserBaseDirectory,$HomeDirectory,
										$BaseDirectory,$InstallationDirectory,
										$RootDirectory}],
								StringMatchQ[ps,ReleaseHold[#]~~__]&
								],
							Hold[p_]:>
								Replace[FileNameSplit[StringTrim[ps,p]],{
									{"",s__}:>
										Hold[{p,s}],
									{s__}:>
										Hold[p,s]
									}]
							],{
						Hold[fp_]:>
							If[OptionValue@"InstallSite",
								With[{desc=
									"Paclet Server for: "<>
										Riffle[names," "]
									},
									Hold[
										PacletManager`PacletSiteAdd[
											"file://"<>URLBuild@fp,
											desc,
											Prepend->True
											];
										If[$VersionNumber<11.2,
										   PacletManager`Services`Private`finishPacletSiteUpdate[
										   	{
										   		PacletManager`Private`siteURL_, 
										   		PacletManager`Private`file_, 
										   		PacletManager`Private`interactive_, 
										   		PacletManager`Private`async_, 
										   		0}
										   	] := 
										   	PacletManager`Services`Private`finishPacletSiteUpdate[
										   		{
															PacletManager`Private`siteURL, 
															PacletManager`Private`file, 
															PacletManager`Private`interactive, 
															PacletManager`Private`async, 
															200}
										   		];
										   PacletManager`Package`getTaskData[task_] := 
										   	Block[{PacletManager`Private`$inTaskDataPatch = True}, 
										   		Replace[PacletManager`Package`getTaskData[task], 
										   			{
										   				PacletManager`Private`a_, 
										   				PacletManager`Private`b_, 
										   				PacletManager`Private`c_, 
										   				PacletManager`Private`d_, 
										   				PacletManager`Private`e_, 0, 
										   				PacletManager`Private`rest__} :> 
										   				{
										   					PacletManager`Private`a, 
										   					PacletManager`Private`b, 
										   					PacletManager`Private`c, 
										   					PacletManager`Private`d, 
										   					PacletManager`Private`e, 200, 
										   					PacletManager`Private`rest}]
										   		] /; ! TrueQ[PacletManager`Private`$inTaskDataPatch]
										   	];
									   PacletManager`PacletInstall[
											#,
											"Site"->("file://"<>URLBuild@fp),
											"Asynchronous"->False
											]&/@names
										]
									],
								With[{paclets=
									StringReplace[
										URLBuild@{
											ps,
											"Paclets",
											#[["Name"]]<>"-"<>#[["Version"]]<>".paclet"
											}&/@info,
										"file:"->"file://"
										]
									},
									Hold[
										If[FileExistsQ@#,
											PacletManager`PacletInstall@#,
											PacletInstallerScript::savefail=
												"No paclet found at ``";
											Message[PacletInstallerScript::savefail,file];
											$Failed
											]&/@paclets
										]
									]
								]
						}],
				True,
					PacletInstallerScript::unclear="Unclear how to install paclet from site ``";
					Message[PacletInstallerScript::unclear,ps];
					$Failed
				]
		];
PacletInstallerScript[
	ps_,
	names:{__String}|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	PacletInstallerScript[
		"PacletSite"->ps,
		"PacletNames"->names,
		ops
		]


Options[PacletUploadInstaller]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletInstallerScript,
			Options@CloudExport
			];
PacletUploadInstaller[ops:OptionsPattern[]]:=
	With[{
		installerLoc=
			With[{p=
				PacletInstallerURL@
					FilterRules[{ops},Options@PacletInstallerURL]
				},
				If[URLParse[p,"Scheme"]==="file",
					FileNameJoin@URLParse[p,"Path"],
					p
					]
				],
		script=
			PacletInstallerScript@
				FilterRules[{ops},
					Options@PacletInstallerScript
					]
		},
			Which[
				StringMatchQ[installerLoc,"http:*"|"https:*"],
					(SetOptions[
						CopyFile[#,#,
							"MIMEType"->"application/vnd.wolfram.mathematica.package"
							],
						FilterRules[{ops},
							Options@CloudExport
							]
						];#)&@
						Replace[script,
							Hold[s_]:>
								CloudPut[Unevaluated[s],
									installerLoc
									]
							],
					True,
						If[Not@FileExistsQ@installerLoc,
							CreateFile[installerLoc,
								CreateIntermediateDirectories->True
								]
							];
							Replace[script,
								Hold[s_]:>
									Put[Unevaluated[s],
										installerLoc
										]
								];
						installerLoc
				]
		]


Options[PacletUninstallerURL]=
	Options@PacletSiteURL;
PacletUninstallerURL[ops:OptionsPattern[]]:=
	StringReplace[
		URLBuild@{PacletSiteURL[ops],"Uninstaller.m"},
		StartOfString~~"file:"->"file://"
		];


Options[PacletUninstallerScript]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletUninstallerURL,{
			"UninstallSite"->
				False,
			"PacletSite"->Automatic,
			"PacletNames"->Automatic,
			"PacletSiteFile"->Automatic
			}
			];
PacletUninstallerScript[ops:OptionsPattern[]]:=
	Module[{
		ps=
			Replace[OptionValue["PacletSite"],
				Automatic:>
					With[{p=
						PacletSiteURL@
							FilterRules[{ops},Options@PacletSiteURL]
						},
						If[URLParse[p,"Scheme"]==="file",
							FileNameJoin@URLParse[p,"Path"],
							p
							]
						]
				],
		info=
			Normal@PacletSiteInfoDataset@
				Replace[OptionValue@"PacletSiteFile",
					Except[(_File|_String)?FileExistsQ]:>
						Replace[OptionValue["PacletSite"],
							Automatic:>
								StringReplace[
									URLBuild@{
										PacletSiteURL@
											FilterRules[{ops},
												Options@PacletSiteURL],
										"PacletSite.mz"
										},
									StartOfString~~"file:"->"file://"
									]
						]
					],
		names
		},
		names=
			DeleteMissing@
				Replace[OptionValue["PacletNames"],
					Automatic:>
						Lookup[info,{"Name","Version"}]
					];
			Which[StringMatchQ[ps,"http:*"|"https:*"(*|"file:*"*)],
				With[{
						site=
							ps,
						paclets=
							names
						},
					If[OptionValue["UninstallSite"],
						Hold[
							PacletManager`PacletSiteRemove[site];
							PacletManager`PacletUninstall[#]&/@paclets
							],
						Hold[PacletManager`PacletUninstall[#]&/@paclets]
						]
					],
				StringMatchQ[ps,
					($UserBaseDirectory|$HomeDirectory|
						$BaseDirectory|$InstallationDirectory|$RootDirectory)
						~~___],
					Replace[
						Replace[
							SelectFirst[
								Thread@Hold[{
									$UserBaseDirectory,$HomeDirectory,
										$BaseDirectory,$InstallationDirectory,
										$RootDirectory}],
								StringMatchQ[ps,ReleaseHold[#]~~__]&
								],
							Hold[p_]:>
								Replace[FileNameSplit[StringTrim[ps,p]],{
									{"",s__}:>
										Hold[{p,s}],
									{s__}:>
										Hold[p,s]
									}]
							],{
						Hold[fp_]:>
							With[{
								site=ps,
								paclets=names
								},
								If[OptionValue@"UninstallSite",
									Hold[
										PacletManager`PacletSiteRemove@
											("file://"<>URLBuild@fp);
										PacletManager`PacletUninstall[#]&/@names;
										names
										],
									Hold[
										PacletManager`PacletUninstall[#]&/@paclets;
										names
										]
									]
								]
					}],
				True,
					PacletUninstallerScript::unclear="Unclear how to uninstall paclet from site ``";
					Message[PacletUninstallerScript::unclear,ps];
					$Failed
				]
		];
PacletUninstallerScript[
	ps_,
	names:{__String}|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	PacletUninstallerScript[
		"PacletSite"->ps,
		"PacletNames"->names,
		ops
		]


Options[PacletUploadUninstaller]:=
	DeleteDuplicatesBy[First]@
		Join[
			Options@PacletUninstallerScript,
			Options@CloudExport
			];
PacletUploadUninstaller[ops:OptionsPattern[]]:=
	With[{
		installerLoc=
			With[{p=
				PacletUninstallerURL@
					FilterRules[{ops},Options@PacletUninstallerURL]
				},
				If[URLParse[p,"Scheme"]==="file",
					FileNameJoin@URLParse[p,"Path"],
					p
					]
				],
		script=
			PacletUninstallerScript@
				FilterRules[{ops},
					Options@PacletUninstallerScript
					]
		},
			Which[
				StringMatchQ[installerLoc,"http:*"|"https:*"],
					(SetOptions[
						CopyFile[#,#,
							"MIMEType"->"application/vnd.wolfram.mathematica.package"
							],
						FilterRules[{ops},
							Options@CloudExport
							]
						];#)&@
						Replace[script,
							Hold[s_]:>
								CloudPut[Unevaluated[s],
									installerLoc
									]
							],
					True,
						If[Not@FileExistsQ@installerLoc,
							CreateFile[installerLoc,
								CreateIntermediateDirectories->True
								]
							];
							Replace[script,
								Hold[s_]:>
									Put[Unevaluated[s],
										installerLoc
										]
								];
						installerLoc
				]
		]


Options[PacletInstallerLink]=
	Options@CloudExport;
PacletInstallerLink[pacletURL:_String,uri_,ops:OptionsPattern[]]:=
	"wolfram+cloudobject:"<>
		First@
			CloudExport[
				Notebook[{
					Cell[
						BoxData@ToBoxes@Unevaluated[PacletManager`PacletInstall@pacletURL],
						"Input"
						]
					}],
				"NB",
				uri,
				Permissions->
					pacletStandardServerPermissions@OptionValue[Permissions],
				ops
				];
PacletInstallerLink[pacletURL:{__String},uri_,ops:OptionsPattern[]]:=
	"wolfram+cloudobject:"<>
		First@
			CloudExport[
				Notebook[{
					Cell[
						BoxData@ToBoxes@Unevaluated[PacletManager`PacletInstall/@pacletURL],
						"Input"
						]
					}],
				"NB",
				uri,
				Permissions->
					pacletStandardServerPermissions@OptionValue[Permissions],
				ops
				];
PacletInstallerLink[c_CloudObject,uri_,ops:OptionsPattern[]]:=
	PacletInstallerLink[First@c,uri,ops];
PacletInstallerLink[c:{__CloudObject},uri_,ops:OptionsPattern[]]:=
	PacletInstallerLink[First/@c,uri,ops];


Options[PacletSiteInstall]=
	Options@PacletSiteURL;
PacletSiteInstall[site_String]:=
	Which[
		DirectoryQ@site,
			If[FileExistsQ@FileNameJoin@{site,"Installer.m"},
				Get@FileNameJoin@{site,"Installer.m"},
				PacletInstallerScript[site]//ReleaseHold
				],
		StringMatchQ[site,"file:*"],
			With[{f=FileNameJoin@URLParse[site,"Path"]},
				If[DirectoryQ@f,
					If[FileExistsQ@FileNameJoin@{f,"Installer.m"},
						Get@FileNameJoin@{f,"Installer.m"},
						PacletInstallerScript[f]//ReleaseHold
						],
					$Failed
					]
				],
		StringMatchQ[site,"http:*"|"https:*"],
			With[{f=URLBuild@{site,"Installer.m"}},
				If[Between[URLRead[f,"StatusCode"],{200,299}],
					CloudGet@f,
					If[Quiet@Get[f]===$Failed,
						PacletInstallerScript[site]//ReleaseHold
						]
					]
				],
		True,
			$Failed
		];
PacletSiteInstall[ops:OptionsPattern[]]:=
	PacletSiteInstall[PacletSiteURL[ops]];


Options[PacletSiteUninstall]=
	Options@PacletSiteURL;
PacletSiteUninstall[site_String]:=
	Which[
		DirectoryQ@site,
			If[FileExistsQ@FileNameJoin@{site,"Uninstaller.m"},
				Get@FileNameJoin@{site,"Uninstaller.m"},
				PacletUninstallerScript[site]//ReleaseHold
				],
		StringMatchQ[site,"file:*"],
			With[{f=FileNameJoin@URLParse[site,"Path"]},
				If[DirectoryQ@f,
					If[FileExistsQ@FileNameJoin@{f,"Uninstaller.m"},
						Get@FileNameJoin@{f,"Uninstaller.m"},
						PacletUninstallerScript[f]//ReleaseHold
						],
					$Failed
					]
				],
		StringMatchQ[site,"http:*"|"https:*"],
			With[{f=URLBuild@{site,"Uninstaller.m"}},
				If[Quiet@Get[f]===$Failed,
					PacletUninstallerScript[site]//ReleaseHold
					]
				],
		True,
			$Failed
		];
PacletSiteUninstall[ops:OptionsPattern[]]:=
	PacletSiteUninstall@PacletSiteURL[ops];


(* ::Subsection:: *)
(*Upload*)



(* ::Subsubsection::Closed:: *)
(*PacletSiteUpload*)



Options[pacletSiteUpload]=
	Join[
		Options[PacletSiteURL],{
			Permissions->Automatic
		}];
pacletSiteUpload[
	CloudObject[site_],
	pacletMZ:(_String|_File)?FileExistsQ,
	ops:OptionsPattern[]
	]:=
	With[{res=
		CopyFile[
			pacletMZ,
			CloudObject[
				URLBuild@{site,"PacletSite.mz"},
				Permissions->
					pacletStandardServerPermissions@OptionValue[Permissions]
				]
			]
		},
		Most[res]/;MatchQ[res,_CloudObject]
		]
pacletSiteUpload[
	dir:(_String|_File)?DirectoryQ,
	pacletMZ:(_String|_File)?FileExistsQ,
	ops:OptionsPattern[]
	]:=
	CopyFile[pacletMZ,
		FileNameJoin@{dir,"PacletSite.mz"},
		OverwriteTarget->True
		];
pacletSiteUpload[
	site:(_String|_URL),
	pacletMZ:(_String|_File)?FileExistsQ,
	ops:OptionsPattern[]
	]:=
	If[URLParse[site,"Scheme"]==="file",
		pacletSiteUpload[
			URLParse[site,"Path"]//FileNameJoin,
			pacletMZ,
			ops],
		pacletSiteUpload[
			CloudObject@First@Flatten[URL@site,1,URL],
			pacletMZ,
			ops
			]
		];


Options[PacletSiteUpload]=
	DeleteDuplicatesBy[First]@
		Join[
			Options[pacletSiteUpload],
			Options[PacletSiteBundle]
			];
PacletSiteUpload[
	site_,
	pacletMZ:(_String|_File)?(FileExistsQ@#&&FileExtension@#=="mz"&),
	ops:OptionsPattern[]
	]:=
	With[{res=
		pacletSiteUpload[
			Replace[site,
				Automatic:>
					PacletSiteURL@
						FilterRules[{ops},
							Options@PacletSiteURL
							]
				],
			pacletMZ,
			FilterRules[{ops},Options@pacletSiteUpload]
			]
		},
		res/;!MatchQ[res,_pacletSiteUpload]
		];
PacletSiteUpload[
	pacletMZ:(_String|_File)?(FileExistsQ@#&&FileExtension@#=="mz"&),
	ops:OptionsPattern[]
	]:=
	With[{
		site=PacletSiteURL@FilterRules[{ops},Options@PacletSiteURL]
		},
		With[{res=
			pacletSiteUpload[site,pacletMZ,
				FilterRules[{ops},Options@pacletSiteUpload]
				]},
			res/;!MatchQ[res,_pacletSiteUpload]
			]
		];
PacletSiteUpload[
	site:Except[{}, _String|_?OptionQ],
	infoFiles:$PacletFilePatterns|{$PacletFilePatterns...},
	ops:OptionsPattern[]
	]:=
	With[{mz=
		PacletSiteBundle[
			infoFiles,
			FilterRules[{ops},Options@PacletSiteBundle]
			]
		},
		With[{res=
			PacletSiteUpload[
				Replace[site,Automatic:>(Sequence@@{})],
				mz,
				ops
				]
			},
			res/;!MatchQ[res,_PacletSiteUpload]
			]
		];
PacletSiteUpload[
	site:Except[{}, _String|_?OptionQ],
	PacletManager`PacletSite[infoFiles:$PacletFilePatterns...],
	ops:OptionsPattern[]
	]:=
	PacletSiteUpload[site,{infoFiles},ops];


(* ::Subsubsection::Closed:: *)
(*PacletAPIUpload*)



$PacletAPIUploadAPIs=
	{
		"GoogleDrive"|"Google Drive"|"googledrive"|"google drive"->
			"GoogleDrive"
		};
PacletAPIUploadAPIQ[s_String]:=
	MatchQ[PacletAPIUploadAPIQ,Alternatives@@Keys@$PacletAPIUploadAPIs]


PacletAPIUpload[
	pacletFile:(_String|_File)?(Not@DirectoryQ@#&&FileExtension[#]==="paclet"&),
	apiName_:"GoogleDrive"
	]:=
	With[{api=apiName/.$PacletAPIUploadAPIs},
		With[{pac=pacletAPIUpload[pacletFile,api]},
			Replace[pac,
				url_String:>
					(PacletInfo[pacletFile]->url)
				]/;!MatchQ[pac,_pacletAPIUpload]
			]
		];


pacletAPIUpload[pacletFile_,"GoogleDrive"]:=
	With[{fil=GoogleDrive["Upload",pacletFile]},
		GoogleDrive["Publish",fil];
		Replace[#["WebContentLink"],URL[u_]:>u]&@
			GoogleDrive["Info",fil,{"name","webContentLink"}]
		]


(* ::Subsubsection::Closed:: *)
(*PacletUpload*)



$PacletSpecPattern=
	(_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)|
		Rule[
			_String|_PacletManager`Paclet,
			(_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)
			];
$PacletUploadPatterns=
	$PacletSpecPattern|{$PacletSpecPattern..}


urlBasedPacletQ[url_String]:=
	With[{data=URLParse[url]},
		(
			data["Domain"]==="drive.google.com"
			&&
			MemberQ[data["Query"],"export"->"download"]
			)
			||
			(
				data["Scheme"]=!=None&&
					FileExtension@Last@data["Path"]==="paclet"
				)
		];


urlBasedPacletRedirect[site_]:=
	URLParse[site,"Path"][[-1]]->HTTPRedirect[site];


builtPacletFileFind//Clear


Options[builtPacletFileFind]=
	{
		"UseCachedPaclets"->True,
		"BuildPaclets"->True
		};
builtPacletFileFind[
	f:_PacletManager`Paclet|_String|_URL|_File,
	ops:OptionsPattern[]
	]:=
	With[
		{
			useCached=TrueQ@OptionValue["UseCachedPaclets"],
			build=TrueQ@OptionValue@"BuildPaclets"
			},
		Which[
			MatchQ[f,_PacletManager`Paclet],
				(* We're handed a Paclet expression so we confirm that a .paclet file exists for it or build it ourselves *)
				With[{
					info=
						Lookup[
							PacletManager`PacletInformation@f,
							{"Location","Name","Version"}
							]},
					If[useCached&&FileExistsQ@(info[[1]]<>".paclet"),
						info[[1]]<>".paclet",
						Replace[builtPacletFileFind[info[[2;;3]],ops],
							None:>
								If[DirectoryQ@info[[1]],
									If[build,
										PacletBundle[info[[1]]],
										True
										],
									None
									]
							]
						]
					],
			MatchQ[f, (_File|_String)?DirectoryQ]&&
				!FileExistsQ[FileNameJoin@{f,"PacletInfo.m"}],
				(* prep non-paclet directories for packing *)
				If[build,
					PacletExpressionBundle[Replace[f,File[s_]:>s]];
					builtPacletFileFind[f,ops],
					True
					],
			MatchQ[f,(_String|_URL)?urlBasedPacletQ],
				(* We're handed a URL so we just return that *)
				First@Flatten[URL[f],1,URL],
			MatchQ[f, _String?(Length@PacletManager`PacletFind[#]>0&)],
				(* found a paclet to pack by name *)
				builtPacletFileFind[
					First@PacletManager`PacletFind[f],
					ops
					],
			MatchQ[f, _File|_String|True|False],
				Replace[{
					File[fil_]:>fil
					}]@
					SelectFirst[
						{
							If[TrueQ@DirectoryQ@f,
								(* handed a directory *)
								If[TrueQ@FileExistsQ@FileNameJoin@{f,"PacletInfo.m"},
									(* if f is a paclet directory *)
									With[{a=PacletInfoAssociation[FileNameJoin@{f,"PacletInfo.m"}]},
										(* check again for the paclet file by version*)
										Replace[builtPacletFileFind[Lookup[a,{"Name","Version"}],ops],
											{
												None:>
													If[build,
														(* needs to be built *)
														PacletBundle[f],
														True
														],
												Except[_String|_File]:>
													Nothing
												}
											]
										],
									Nothing
									],
								(* Only thing left it could be is a file *)
								With[{fname=StringTrim[f, "."<>FileExtension[f]]<>".paclet"},
									(* If its paclet file exists *)
									If[FileExistsQ@fname,
										fname,
										If[build,
											If[FileExistsQ@f,
												PacletBundle[f],
												None
												],
											True
											]
										]
									]
								],
							If[TrueQ@useCached,
								(* Check for default cached paclet *)
								FileNameJoin@{
									$PacletBuildRoot,
									$PacletBuildExtension,
									StringTrim[f,"."<>FileExtension[f]]<>".paclet"
									},
								Nothing
								]
						},
						TrueQ[#]||
							(MatchQ[#, _File|_String]&&FileExistsQ[#])&,
						None
						],
		True,
			None
			]
		];
builtPacletFileFind[{f_String,v_String},ops:OptionsPattern[]]:=
	builtPacletFileFind[f<>"-"<>v<>".paclet",ops];
builtPacletFileFind[Rule[s_,p_],ops:OptionsPattern[]]:=
	Rule[s,builtPacletFileFind[p,ops]];
builtPacletFileFind[None,___]:=None;
builtPacletFileQ[spec_,
	ops:OptionsPattern[]
	]:=
	!MatchQ[builtPacletFileFind[spec,"BuildPaclets"->False,ops],None|(_->None)];


pacletUploadPostProcess[assoc_, uploadInstallLink_, site_, perms_]:=
	Replace[uploadInstallLink,{
		True:>
			Append[#,
				"PacletInstallLinks"->
					PacletInstallerLink[
						#["PacletFiles"],
						URLBuild@{site,"InstallerNotebook.nb"},
						Permissions->
							pacletStandardServerPermissions@perms
						]
				],
		s_String:>
			Append[#,
				"PacletInstallLinks"->
					PacletInstallerLink[
						#["PacletFiles"],
						URLBuild@{site,s},
						Permissions->
							pacletStandardServerPermissions@perms
						]
				],
		Automatic:>
			Append[#,
				"PacletInstallLinks"->
					Map[
						Function[
							PacletInstallerLink[
								#,
								URLBuild@{
									site,
									StringReplace[
										URLParse[#,"Path"][[-1]],
										".paclet"~~EndOfString->".nb"
										]},
								Permissions->
									pacletStandardServerPermissions@perms
								]
							],
						#["PacletFiles"]
						]
				],
		_:>#
		}]&@assoc;
pacletUploadPostProcess[uploadInstallLink_, site_, perms_][assoc_]:=
	pacletUploadPostProcess[assoc, uploadInstallLink, site, perms]


pacletUploadBuildPacletCloudObject[url_, perms_, v_]:=
	CloudObject[
		URLBuild@{
			url,
			"Paclets",
			Replace[v,
				{
					Rule[n_PacletManager`Paclet,_]:>
						StringJoin@
							Riffle[
								Lookup[List@@n,{"Name","Version"}],
								{"-",".paclet"}
								],
					Rule[n_String,_]:>
						n,
					URL[u_]:>
						URLParse[u,"Path"][[-1]],
					f:_String|_File:>
						If[FileExistsQ@f,
							FileNameTake@f,
							URLParse[f,"Path"][[-1]]
							],
					_:>$Failed
					}
				]															
			},
		Permissions->
			pacletStandardServerPermissions@perms
		];
pacletUploadBuildPacletCloudObject[url_, perms_][v_]:=
	pacletUploadBuildPacletCloudObject[url, perms, v]


pacletUploadCloudObjectRouteExport[url_, perms_, v_]:=
	With[{
		co=
			pacletUploadBuildPacletCloudObject[url,
				perms,
				v
				],
		fil=
			Replace[v,
				Rule[_,f_]:>f
				]
		},
		Take[#, 1]&@
			If[
				Switch[v,
					_File|_String,
						FileExistsQ@v,
					_URL,
						False,
					_Rule,
						FileExistsQ@Last@v
					],
				CopyFile[
					If[MatchQ[v,_Rule],Last@v,v],
					co],
				CloudDeploy[
					HTTPRedirect@
						If[MatchQ[v,_Rule],
							Last@v,
							v],
					co]
				]
		]


PacletUpload::nosite="Site `` isn't a string";
Options[pacletUpload]=
	DeleteDuplicatesBy[First]@
		Join[
			Options[PacletSiteURL],
			{
				"BuildRoot":>$PacletBuildRoot,
				"SiteFile"->Automatic,
				"OverwriteSiteFile"->False,
				"UploadSiteFile"->False,
				"UploadInstaller"->False,
				"UploadInstallLink"->False,
				"UploadUninstaller"->False,
				"UseCachedPaclets"->True,
				Permissions->Automatic
				}
			];
pacletUpload[
	pacletSpecs:$PacletUploadPatterns,
	ops:OptionsPattern[]
	]:=
	With[{
		bPFFOps=FilterRules[{ops},Options[builtPacletFileFind]]
		},
		pacletToolsCatchBlock["PacletUpload"]@
			DeleteCases[Nothing]@
			With[{
				base=
					If[StringQ[#]&&MatchQ[URLParse[#, "Scheme"], "http"|"https"],
						Quiet@
							Check[CloudObject@#, #],
						#
						]&@
						pacletStandardServerBase@OptionValue["ServerBase"],
				site=
					PacletSiteURL[
						FilterRules[{
							ops
							},
							Options@PacletSiteURL
							]
						],
				pacletFiles=builtPacletFileFind[#,bPFFOps]&/@Flatten@{pacletSpecs}
				},
				If[MatchQ[site,Except[_String]],
					Message[PacletUpload::nosite,site];
					pacletToolsThrow[]
					];
				With[{pacletMZ=
					If[OptionValue["UploadSiteFile"]//TrueQ,
						Replace[OptionValue["SiteFile"],
							Automatic:>
								PacletSiteBundle[
									Replace[pacletFiles,
										(k_->_):>k
										],
									FilterRules[
										{
											ops,
											"MergePacletInfo"->
												If[OptionValue["OverwriteSiteFile"]//TrueQ,
													None,
													site
													]
												},
										Options@PacletSiteBundle
										]
									]
							]
						]},
					Switch[base,
						(* ------------------- Wolfram Cloud Paclets ------------------- *)
						"Cloud"|CloudObject|CloudDirectory|Automatic|_CloudObject|_CloudDirectory,
							With[{url=site},
								pacletUploadPostProcess[
									OptionValue["UploadInstallLink"],
									site, 
									OptionValue["Permissions"]
									]@
								<|
									"PacletSiteFile"->
										If[OptionValue["UploadSiteFile"]//TrueQ,
											Replace[
												PacletSiteUpload[CloudObject@site,pacletMZ,
													FilterRules[{ops},Options@PacletSiteUpload]
													],
												_PacletSiteUpload->$Failed
												],
											Nothing
											],
									"PacletFiles"->
										Map[
											pacletUploadCloudObjectRouteExport[url, OptionValue[Permissions], #]&,
											pacletFiles
											],
									"PacletInstaller"->
										If[OptionValue["UploadInstaller"]//TrueQ,
											PacletUploadInstaller[ops,
												Permissions->
													pacletStandardServerPermissions@OptionValue[Permissions],
												"PacletSiteFile"->
													pacletMZ
												],
											Nothing
											],
									"PacletUninstaller"->
										If[OptionValue["UploadUninstaller"]//TrueQ,
											PacletUploadUninstaller[ops,
												Permissions->
													pacletStandardServerPermissions@OptionValue[Permissions],
												"PacletSiteFile"->
													pacletMZ
												],
											Nothing
											]
									|>	
								],
						(* ------------------- Local Paclets ------------------- *)
						_String?(StringMatchQ[FileNameJoin@{$RootDirectory,"*"}]),
							With[{dir=URLDecode@StringTrim[site,"file://"]},
								If[Not@DirectoryQ@dir,
									CreateDirectory[dir,
										CreateIntermediateDirectories->True
										]
									];
								<|
									"PacletSite"->
										If[MatchQ[pacletMZ,(_String|_File)?FileExistsQ],
											CopyFile[pacletMZ,
												FileNameJoin@{dir,"PacletSite.mz"},
												OverwriteTarget->True
												],
											Nothing
											],
									"PacletFiles"->
										Map[
											(
												Quiet@
													CreateFile[
														FileNameJoin@{dir,"Paclets",FileNameTake@#}
														];
												CopyFile[#,
													FileNameJoin@{dir,"Paclets",FileNameTake@#},
													OverwriteTarget->True
													]
												)&,
											pacletFiles
											],
									"PacletInstaller"->
										If[OptionValue["UploadInstaller"]//TrueQ,
											PacletUploadInstaller@
												FilterRules[{ops},
													Options@PacletUploadInstaller
													],
											Nothing
											],
									"PacletUninstaller"->
										If[OptionValue["UploadUninstaller"]//TrueQ,
											PacletUploadUninstaller@
												FilterRules[{ops},
													Options@PacletUploadUninstaller
													],
											Nothing
											]
									|>	
								],
						_?SyncPathQ,
							With[{p=SyncPath@base},
								Quiet@CreateDirectory[p,
									CreateIntermediateDirectories->True];
								PacletUpload[
									pacletFiles,
									"ServerBase"->p,
									ops
									]
								],
						_,
							Message[PacletUpload::nobby,base];
							pacletToolsThrow[]
							]
					]
				]
		];


PacletUpload//Clear


Options[PacletUpload]=
	Options[pacletUpload];
PacletUpload::nobby="Unkown site base ``"
PacletUpload::nopac="Unable to find paclet files ``";
PacletUpload[pacletFiles]~~`Package`PackageAddUsage~~
	"uploads pacletFiles to the specified server and configures installers";
PacletUpload[
	pacletSpecs:$PacletUploadPatterns,
	ops:OptionsPattern[]
	]:=
	Block[{
		$PacletBuildRoot=OptionValue["BuildRoot"],
		bPFFOps=FilterRules[{ops},Options[builtPacletFileFind]],
		files
		},
		files=builtPacletFileFind[#,bPFFOps]&/@Flatten[{pacletSpecs}, 1];
		If[!AllTrue[files,builtPacletFileQ],
			Message[PacletUpload::nopac,
				Pick[Flatten@{pacletSpecs},MatchQ[None|(_->None)]/@files]
				]
			];
		pacletUpload[pacletSpecs,ops]/;
			AllTrue[files,builtPacletFileQ]
		];


(* ::Subsection:: *)
(*Remove*)



(* ::Subsubsection::Closed:: *)
(*pacletRemove*)



pacletRemove[server_,siteExpr_,{name_,version_}]:=
	With[{
		file=
			StringReplace[
				URLBuild@{server,"Paclets",name<>"-"<>version<>".paclet"},{
				"file://"->"file://",
				"file:"->"file://"
				}]
		},
		If[URLParse[file,"Scheme"]==="file",
			Quiet[DeleteFile@FileNameJoin@URLParse[file,"Path"],DeleteFile::nffil],
			Quiet[DeleteFile@CloudObject[file],DeleteFile::nffil]
			];
		Select[siteExpr,
			!AllTrue[
				Transpose@{
					Lookup[List@@#,{"Name","Version"}],
					{name,version}
					},
				StringMatchQ[#[[1]],#[[2]]]&
				]&
			]
		];
pacletRemove[server_,siteExpr_,fileExt_String?(StringEndsQ[".paclet"])]:=
	pacletRemove[server,siteExpr,
		ReplacePart[#,-1->StringTrim[Last@#,".paclet"]]&@
			StringSplit[fileExt,"-"]
		];
pacletRemove[server_,siteExpr_,pacName_String]:=
	pacletRemove[server,siteExpr,
		Select[siteExpr,
			StringMatchQ[Lookup[List@@#,"Name"],pacName]&
			]
		];
pacletRemove[server_,siteExpr_,pac_PacletManager`Paclet]:=
	pacletRemove[server,siteExpr,
		Lookup[List@@pac,{"Name","Version"}]
		];
pacletRemove[server_,siteExpr_,pacSpecs_List]:=
	Fold[
		Replace[pacletRemove[server,#,#2],
			_pacletRemove->#
			]&,
		siteExpr,
		pacSpecs
		];
pacletRemove[server_,siteExpr_,PacletManager`PacletSite[pacSpecs___]]:=
	pacletRemove[server,siteExpr,{pacSpecs}]


(* ::Subsubsection::Closed:: *)
(*PacletRemove*)



$PacletRemoveSpec=
	{_String,_String}|PacletManager`Paclet|_String;
$PacletRemovePatterns=
	$PacletRemoveSpec|{$PacletRemoveSpec..}


Options[PacletRemove]=
	DeleteDuplicatesBy[First]@
	Join[
		Options[PacletSiteURL],
		Options[PacletSiteUpload],
		{
			"OverwriteSiteFile"->True
			}
		];
PacletRemove[pacSpecs:$PacletRemovePatterns,ops:OptionsPattern[]]:=
	With[{site=PacletSiteURL[FilterRules[{ops},Options@PacletSiteURL]]},
		With[{res=
			Replace[
				pacletRemove[
					site,
					PacletSiteInfo[site],
					pacSpecs
					],{
				p_PacletManager`PacletSite?(OptionValue["OverwriteSiteFile"]&):>
					PacletSiteUpload[site,
						p,
						FilterRules[
							{
								ops,
								"MergePacletInfo"->False
								},
							Options@PacletSiteUpload
							]
						]
				}]
			},
			res/;!MatchQ[res,_pacletRemove]
			]
		]


(* ::Subsection:: *)
(*Download*)



(* ::Subsubsection::Closed:: *)
(*PacletDownload*)



PacletDownload[
	paclet_CloudObject,
	components:_String|{__String}:"PacletInfo.m"
	]:=
	With[{info=CloudObjectInformation[paclet,{"OwnerWolframUUID","Path"}]},
CloudEvaluate[
With[{i=
Compress@
Map[Import,Flatten@{#}]},
Map[DeleteFile,Flatten@{#}];
i
]&@
ExtractArchive[
FileNameJoin@{
$RootDirectory,
"wolframcloud",
"userfiles",
StringTake[#OwnerWolframUUID,3],
#OwnerWolframUUID,
Sequence@@Rest@URLParse[#Path,"Path"]
}&@info,
FileNameJoin@{$HomeDirectory,"trash"},
Alternatives@@Map["*"<>#&,components]
]
]
]//Uncompress


(* ::Subsection:: *)
(*Install*)



$PackageDependenciesFile=
	"DependencyInfo.m";


PacletInstallPaclet::howdo="Unsure how to pack a paclet from file type ``";
PacletInstallPaclet::laywha="Couldn't detect package layout from directory ``";
PacletInstallPaclet::dumcode="Couldn't generate PacletInfo.m for directory ``";
PacletInstallPaclet::badbun="Not a real directory ``";


(* ::Subsubsection::Closed:: *)
(*installPacletGenerate*)



Options[installPacletGenerate]={
	"Verbose"->False
	};


(* ::Subsubsubsection::Closed:: *)
(*Directory*)



installPacletGenerate[dir:(_String|_File)?DirectoryQ,ops:OptionsPattern[]]:=
	Block[{bundleDir=dir},
		If[OptionValue@"Verbose",
			DisplayTemporary@
				Internal`LoadingPanel[
					TemplateApply["Bundling paclet for ``",dir]
					]
				];
		(* ------------ Extract Archive Files --------------- *)
		If[FileExistsQ@#,Quiet@ExtractArchive[#,dir]]&/@
			Map[
				FileNameJoin@{dir,FileBaseName@dir<>#}&,
				{".zip",".gz"}
				];
		(* ------------ Detect Paclet Layout --------------- *)
		Which[
			FileExistsQ@FileNameJoin@{dir,"PacletInfo.m"},
				bundleDir=dir,
			FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".m"}||
				FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".wl"}||
				FileExistsQ@FileNameJoin@{dir,"Kernel","init"<>".m"}||
				FileExistsQ@FileNameJoin@{dir,"Kernel","init"<>".wl"},
				bundleDir=dir;
				PacletExpressionBundle[bundleDir],
			FileExistsQ@FileNameJoin@{dir,FileBaseName@dir,"PacletInfo.m"},
				bundleDir=FileNameJoin@{dir,FileBaseName@dir},
			FileExistsQ@FileNameJoin@{dir,FileBaseName@dir,FileBaseName@dir<>".m"},
				bundleDir=FileNameJoin@{dir,FileBaseName@dir};
				PacletExpressionBundle[bundleDir],
			FileExistsQ@FileNameJoin@{dir,FileBaseName[dir]<>".nb"},
				Export[
					FileNameJoin@{dir,FileBaseName[dir]<>".m"};
					"(*Open package notebook*)
CreateDocument[
	Import@
		StringReplace[$InputFileName,\".m\"->\".nb\"]
	]",
					"Text"
					];
				bundleDir=dir;
				PacletExpressionBundle[bundleDir],
			_,
				Message[PacletInstallPaclet::laywha];
				pacletToolsThrow[]
			];
		Which[
			!DirectoryQ@bundleDir,
				Message[PacletInstallPaclet::badbun, bundleDir];
				pacletToolsThrow[],
			!FileExistsQ@FileNameJoin@{bundleDir, "PacletInfo.m"},
				Message[PacletInstallPaclet::dumcode, bundleDir];
				pacletToolsThrow[],
			True,
				PacletBundle[bundleDir]
			]
		];


(* ::Subsubsubsection::Closed:: *)
(*File*)



installPacletGenerate[file:(_String|_File)?FileExistsQ,ops:OptionsPattern[]]:=
	Switch[FileExtension[file],
		"m"|"wl",
			If[OptionValue@"Verbose",
				DisplayTemporary@
					Internal`LoadingPanel[
						TemplateApply["Bundling paclet for ``",file]
						]
					];
			With[{dir=
				FileNameJoin@{
					$TemporaryDirectory,
					FileBaseName@file
					}
				},
				If[!DirectoryQ@dir,
					CreateDirectory[dir]
					];
				If[FileExistsQ@
					FileNameJoin@{
						DirectoryName@file,
						$PackageDependenciesFile
						},
					CopyFile[
						FileNameJoin@{
							DirectoryName@file,
							$PackageDependenciesFile
							},
						FileNameJoin@{
							dir,
							$PackageDependenciesFile
							}	
						]
					];
				If[FileExistsQ@
					FileNameJoin@{
						DirectoryName@file,
						"PacletInfo.m"
						},
					CopyFile[
						FileNameJoin@{
							DirectoryName@file,
							"PacletInfo.m"
							},
						FileNameJoin@{
							dir,
							"PacletInfo.m"
							}	
						]
					];
				CopyFile[file,
					FileNameJoin@{
						dir,
						FileNameTake@file
						},
					OverwriteTarget->True
					];
				PacletExpressionBundle[dir,
					"Name"->
						StringReplace[FileBaseName[dir],
							Except[WordCharacter|"$"]->""]
							];
				PacletBundle[dir,
					"BuildRoot"->$TemporaryDirectory
					]
				],
		"nb",
			With[{dir=
				FileNameJoin@{
					$TemporaryDirectory,
					StringJoin@RandomSample[Alphabet[],10],
					FileBaseName@file
					}
					},
				Quiet[
					DeleteDirectory[dir,DeleteContents->True];
					CreateDirectory[dir,CreateIntermediateDirectories->True]
					];
				CopyFile[file,FileNameJoin@{dir,FileNameTake@file}];
				installPacletGenerate[dir]
				],
		"paclet",
			file,
		_,
			Message[PacletInstallPaclet::howdo,
				FileExtension@file
				]
		];


(* ::Subsubsection::Closed:: *)
(*gitPacletPull*)



gitPacletPull//Clear


gitPacletPull[loc:(_String|_File|_URL)?GitHubPathQ]:=
	Quiet[GitHub["Clone",loc],Git::err];
gitPacletPull[loc:(_String|_File|_URL)?(Not@*GitHubPathQ)]:=
	Quiet[Git["Clone",loc],Git::err];


(* ::Subsubsection::Closed:: *)
(*wolframLibraryPull*)



wolframLibraryPull[loc:_String|_URL]:=
	With[{fileURLs=
		URLBuild@
			Merge[{
					URLParse[loc],
					URLParse[#]
					},
				Replace[DeleteCases[#,None],{
						{s_}:>s,
						{___,l_}:>l,
						{}->None
						}]&
				]&/@
			Cases[
				Import[loc,{"HTML","XMLObject"}],
				XMLElement["a",
					{
						___,
						"href"->link_,
						___},
					{___,
						XMLElement["img",
							{___,"src"->"/images/database/download-icon.gif",___},
							_],
						___}
					]:>link,
				\[Infinity]
				]
		},
		With[{name=
			FileBaseName@
				First@
					SortBy[
						Switch[FileExtension[#],
							"paclet",
								0,
							"zip"|"gz",
								1,
							"wl"|"m",
								2,
							_,
								3
							]&
						][URLParse[#,"Path"][[-1]]&/@fileURLs]
				},
			Quiet@
				DeleteDirectory[
					FileNameJoin@{$TemporaryDirectory,name},
					DeleteContents->True
					];
			CreateDirectory@FileNameJoin@{$TemporaryDirectory,name};
			MapThread[
				RenameFile[
					#,
					FileNameJoin@{$TemporaryDirectory,name,URLParse[#2,"Path"][[-1]]}
					]&,{
				URLDownload[fileURLs,
					FileNameJoin@{$TemporaryDirectory,name}],
				fileURLs
				}];
			FileNameJoin@{$TemporaryDirectory,name}
			]
		]


(* ::Subsubsection::Closed:: *)
(*downloadURLIfExists*)



downloadURLIfExists[urlBase_,{files__},dir_]:=
	If[
		MatchQ[0|200]@
			URLSave[
				URLBuild@{urlBase,#},
				FileNameJoin@{
					dir,
					#
					},
				"StatusCode"
				],
		FileNameJoin@{
			dir,
			#
			},
		Quiet@
			DeleteFile@
				FileNameJoin@{
					dir,
					#
					};
		Nothing
		]&/@{files}


(* ::Subsubsection::Closed:: *)
(*PacletInstallPaclet*)



Options[PacletInstallPaclet]=
	{
		"Verbose"->True,
		"InstallSite"->True,
		"InstallDependencies"->
			Automatic,
		"Log"->True
		};
PacletInstallPaclet[
	loc:(_String|_File)?FileExistsQ,
	ops:OptionsPattern[]
	]:=
	pacletToolsCatchBlock["PacletInstallPaclet"]@
	Replace[
		installPacletGenerate[loc,ops],{
			File[f_]|(f_String?FileExistsQ):>
				Replace[PacletManager`PacletInstall@f,
					p_PacletManager`Paclet:>
						With[{deps=
							Replace[OptionValue["InstallDependencies"],{
								Automatic->{"Standard"},
								True->All
								}]
							},
						If[MatchQ[deps,_List|All],
							Flatten@{
								p,
								With[{l=PacletLookup[p,"Location"]},
									If[FileExistsQ@FileNameJoin@{l,$PackageDependenciesFile},
										Replace[Import[$PackageDependenciesFile],{
											a_Association:>
												Switch[deps,
													All,
														Flatten@
															Map[Map[PacletInstallPaclet,#]&,a],
													_,
														Flatten@
															Map[PacletInstallPaclet,
																Flatten@Lookup[a,deps,{}]
																]
													],
											l_List:>
												Map[PacletInstallPaclet,l]
											}],
										{}
										]
									]
								},
							p
							]
						]
					],
			_->$Failed
			}];
PacletInstallPaclet[
	loc:(_String?(URLParse[#,"Scheme"]=!=None&)|_URL),
	ops:OptionsPattern[]
	]:=
	Which[
		URLParse[loc,"Domain"]==="github.com",
			With[{dir=
				If[OptionValue@"Verbose"//TrueQ,
					Monitor[
						gitPacletPull[loc],
						Which[GitHubRepoQ@loc,
							Internal`LoadingPanel[
								TemplateApply["Cloning repository at ``",loc]
								],
							GitHubReleaseQ@loc,
								Internal`LoadingPanel[
									TemplateApply["Pulling release at ``",loc]
									],
							True,
								Internal`LoadingPanel[
									TemplateApply["Downloading from ``",loc]
									]
							]
						],
					gitPacletPull[loc]
					]
				},
				PacletInstallPaclet@dir
				],
			URLParse[loc,"Domain"]==="library.wolfram.com",
				With[{dir=
					If[OptionValue@"Verbose"//TrueQ,
						Monitor[
							wolframLibraryPull[loc],
							Internal`LoadingPanel[
								TemplateApply["Downloading from library.wolfram.com ``",loc]
								]
							],
						gitPacletPull[loc]
						]
					},
					PacletInstallPaclet@dir
					],
			True,
				If[
					And[
						OptionValue["InstallSite"]//TrueQ,
						MatchQ[
							Quiet@PacletSiteInfo[loc],
							PacletManager`PacletSite[__PacletManager`Paclet]
							]
						],
					PacletSiteInstall[loc],
					Switch[URLParse[loc,"Path"][[-1]],
						_?(FileExtension[#]=="paclet"&),
							PacletInstallPaclet@URLDownload[loc],
						_?(MatchQ[FileExtension[#],"m"|"wl"]&),
							PacletInstallPaclet@
								downloadURLIfExists[
									URLBuild[
										ReplacePart[#,
											"Path"->
												Drop[#Path,-1]
											]&@URLParse[loc]
										],{
									URLParse[loc,"Path"][[-1]],
									$PackageDependenciesFile,
									"PacletInfo.m"
									}],
						_,
							Replace[
								Quiet@Normal@PacletSiteInfoDataset[loc],{
									Except[{__Association}]:>
										(
											Message[PacletInstallPaclet::nopac,loc];
											$Failed
											),
									a:{__Association}:>
										PacletInstallPaclet[
											URLBuild@
												Flatten@{
													loc,
													StringJoin@{
														Lookup[Last@SortBy[a,#Version&],{
															"Name",
															"Version"
															}],
														".paclet"
														}
													},
											ops
											]
								}]
						]
					]
			];


(* ::Subsection:: *)
(*Format*)



If[!AssociationQ@$pacletIconCache, $pacletIconCache=<||>];
pacletGetIcon[a_]:=
	Replace[
		FileNames[
			Lookup[
				a,
				"Icon",
				"PacletIcon.png"
				],
			a["Location"]
			],
		{
			{f_, ___}:>
				Lookup[$pacletIconCache, f, $pacletIconCache[f] = Import[f]],
			{}:>
				With[{f=PackageFindFile["Resources", "Icons", "PacletIcon.png"]},
					Lookup[$pacletIconCache, f, $pacletIconCache[f] = Import[f]]
					]
				(*Pane[
					Style[Last@StringSplit[a["Name"],"_"],"Input"],
					{Automatic,28},
					Alignment\[Rule]Center
					]*)
			}
		];			


SetPacletFormatting[]:=
	(
		Format[p_PacletManager`Paclet/;
			($FormatPaclets&&AssociationQ@
				PacletInfoAssociation[p])]:=
			With[{a=PacletInfoAssociation[p]},
				RawBoxes@
				BoxForm`ArrangeSummaryBox[
					"Paclet",
					p,
					pacletGetIcon[a],
					KeyValueMap[
						BoxForm`MakeSummaryItem[
							{Row[{#, ": "}],#2},
							StandardForm
							]&,
						a[[{"Name","Version"}]]
						],
					Join[
						{
							If[KeyMemberQ[a,"Location"],
								BoxForm`MakeSummaryItem[
									{Row[{"Location", ": "}],
										With[{l=a["Location"]},
											Button[
												Hyperlink[l],
												SystemOpen[l],
												Appearance->None,
												BaseStyle->"Hyperlink"
												]
											]},
									StandardForm
									],
								Nothing
								]
							},
						KeyValueMap[
							BoxForm`MakeSummaryItem[
								{Row[{#, ": "}],#2},
								StandardForm
								]&,
							KeyDrop[a,{"Name","Version","Location"}]
							]
						],
					StandardForm
					]
				];
		FormatValues[PacletManager`Paclet]=
			SortBy[
				FormatValues[PacletManager`Paclet],
				FreeQ[HoldPattern[$FormatPaclets]]
				]
		);
If[$TopLevelLoad, SetPacletFormatting[]]


End[];



