(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



PackageScopeBlock[
	PacletServerPage::usage=
		"Generates a page laying out the available paclets on that server";
	PacletMarkdownNotebook::usage=
		"Generates a markdown notebook for the paclet";
	PacletMarkdownNotebookUpdate::usage=
		"Updates a markdown notebook for a paclet";
	LoadPacletServers::usage="";
	$PacletServers::usage=
		"The listing of possible servers";
	$DefaultPacletServer::usage=
		"The key of the default paclet server";
	$PacletServer::usage=
		"The configuration for the default paclet server";
	PacletServerURL::usage=
		"";
	PacletServerDeployURL::usage=
		"";
	PacletServerFile::usage=
		"Finds a file on a paclet server";
	PacletServerDirectory::usage=
		"";
	PacletServerDataset::usage=
		"";
	PacletServerDelete::usage=
		"Deletes a paclet server";
	]


PacletServerAdd::usage=
	"Adds a paclet to the default server";
PacletServerRemove::usage=
	"Removes a paclet from the default server";


PacletServerBuild::usage="Builds a paclet server and site";
PacletServerDeploy::usage="Deploys a paclet server";


PacletServerInterface::usage=
	"Generates an interface listing what's on a paclet server with install buttons"


Begin["`Private`"];


(* ::Subsection:: *)
(*Server Basics*)



(* ::Subsubsection::Closed:: *)
(*File*)



$PacletServersFile=
	FileNameJoin@{
		$UserBaseDirectory, 
		"ApplicationData",
		"PacletServers",
		"PacletServers.m"
		};


(* ::Subsubsection::Closed:: *)
(*Load*)



LoadPacletServers[]:=
	(
		If[FileExistsQ@$PacletServersFile,
			$PacletServers=
				Import[$PacletServersFile]
			];
		If[!AssociationQ@$PacletServers||Length@$PacletServers==0,
			$PacletServers=
				<|
					"Default"->
						<|
							"ServerBase"->
								$WebSiteDirectory,
							"ServerExtension"->
								Nothing,
							"ServerName"->
								"PacletServer",
							Permissions->
								"Public",
							CloudConnect->
								"PacletsAccount"
							|>
					|>
			]
		)


(* ::Subsubsection::Closed:: *)
(*Merge*)



ImportPacletServers[d_Association]:=
	Merge[
		{
			Select[$PacletServers],
			d,
			Select[$PacletServers,
				DirectoryQ@*Key["ServerBase"]
				]
			},
		Merge[Last]
		];
ImportPacletServers[f_String]/;FileExistsQ[f]&&!DirectoryQ[f]:=
	ImportPacletServers@Import[f];
ImportPacletServers[f_String]:=
	Replace[Quiet@CloudObject[f],
		{
			co_CloudObject:>ImportPacletServers@co,
			_:>ImportPacletServers@Import[f]
			}
		];
ImportPacletServers[c_CloudObject]:=
	ImportPacletServers@CloudImport[c];
ImportPacletServers[_]:=
	$Failed


(* ::Subsubsection::Closed:: *)
(*Index*)



$PacletServersIndexes=
	<|
		"b3m2a1"->CloudObject["user:b3m2a1.paclets/PacletIndex.m"]
		|>;


(* ::Subsubsection::Closed:: *)
(*Setup*)



If[!AssociationQ@$PacletServers,
	LoadPacletServers[]
	]


$DefaultPacletServer=
	"Default";


PacletServer[s_]:=
	Normal@$PacletServers[s]


$PacletServer:=
	PacletServer[$DefaultPacletServer]


localPacletServerPat=
	KeyValuePattern[{
		"ServerBase"->
			(
				_String?DirectoryQ|
				_String?(MatchQ[URLParse[#, "Scheme"], "file"|"http"]&)
				),
		"ServerName"->_
		}];
localPacletServer=
	MatchQ[localPacletServerPat]


(* ::Subsubsection::Closed:: *)
(*PacletServerURL*)



PacletServerURL[serv:localPacletServerPat]:=
	PacletSiteURL@
		FilterRules[serv,
			Options[PacletSiteURL]
			];


$PacletServerURL:=
	PacletServerURL@$PacletServer


(* ::Subsubsection::Closed:: *)
(*PacletServerDeployURL*)



PacletServerDeployURL[server_]:=
	PacletSiteURL@
		FilterRules[
			Flatten@{
				"ServerBase"->
					If[DirectoryQ@PacletServerDirectory[server], 
						CloudObject, 
						Lookup[server, "ServerBase"]
						],
				Normal@server
				},
			Options[PacletSiteURL]
			]


(* ::Subsubsection::Closed:: *)
(*PacletServerFile*)



PacletServerFile[
	server:localPacletServerPat,
	fileName:_String|{__String}|Nothing
	]:=
	With[{u=URLBuild@Flatten@{PacletServerURL[server],fileName}},
		If[URLParse[u,"Scheme"]==="file",
			FileNameJoin@URLParse[u,"Path"],
			u
			]
		];
PacletServerDirectory[
	server:localPacletServerPat
	]:=
	PacletServerFile[server, Nothing]


$PacletServerDirectory:=
	PacletServerDirectory@$PacletServer;


(* ::Subsubsection::Closed:: *)
(*PacletServerDataset*)



Options[PacletServerDataset]=
	{
		"DeployedServer"->
			True
		};
PacletServerDataset[
	server:localPacletServerPat,
	ops:OptionsPattern[]
	]:=
	PacletSiteInfoDataset@
		FilterRules[
			If[TrueQ@OptionValue["DeployedServer"],
				Prepend["ServerBase"->Automatic],
				Identity
				]@
				Normal@server,
			Options[PacletSiteInfoDataset]
			];


(* ::Subsection:: *)
(*PacletServerInterface*)



(* ::Subsubsection::Closed:: *)
(*pacletServerInterfacePage*)



pacletServerInterfacePage[
	var_,
	site_,
	coreAssoc_,
	pacletFindData_
	]:=
	With[{
		name=coreAssoc["Name"],
		version=coreAssoc["Version"],
		creator=Lookup[coreAssoc, "Creator", ""],
		description=Lookup[coreAssoc,"Description",""],
		extensions=
			Replace[
				Lookup[coreAssoc,"Extensions",Nothing],
				ds_Association:>Dataset[ds]
				]
		},
		Grid[{
			{
				Item[
					Row@{Style[name, Bold],Style[" v"<>version,Gray]},
					Background->GrayLevel[.8],
					Alignment->Center,
					ItemSize->{Automatic, 2},
					FrameStyle->Black
					],
					SpanFromLeft
				},
			{
				Item[#, Alignment->Left]&@
				Row@{Style["Creator: ",Gray], 
					Replace[Interpreter["EmailAddress"][creator],{
						s_String?(StringLength[#]>0&):>
							Hyperlink[creator, "mailto:"<>creator],
						_->creator
						}]},
				SpanFromLeft
				},
			{
				TextCell[description,
					CellSize->{500,Automatic},
					ParagraphIndent->None,
					Editable->False,
					Selectable->True
					],
				SpanFromLeft
				},
			{
				Item[
					"Extensions",
					Alignment->Center,
					Background->GrayLevel[.98]
					],
				SpanFromLeft
				},
			{
				Item[#, Alignment->Left]&@
				Grid[
					KeyValueMap[
						{
							Style[Row[{#, ": "}], Gray],
							Which[
								MatchQ[#2, <||>|<|Prepend->True|>],
									Grid[{{},{"Enabled"}}, Alignment->{Left, Top}],
								AssociationQ@#2,
									Grid[
										Prepend[{}]@
										KeyValueMap[
											{
												Style[Row[{#, ": "}], Gray],
												#2
												}&,
											DeleteDuplicates@#2
											],
										Alignment->{Left, Top}
										],
								True,
									#2
								]
							}&,
						Normal@extensions
						],
					Alignment->{Left, Top}
					],
				SpanFromLeft
				},
			{
				Item[
					Button[Hyperlink@"\[ReturnIndicator]",
						var=Automatic,
						Appearance->None,
						BaseStyle->"Hyperlink"
						],
					Alignment->Left,
					Background->GrayLevel[.95]
					],
				Item[
					If[Length[pacletFindData]===0,
						Button["Install",
							PacletInstall[name,
								"Site"->site,
								Enabled->StringQ[site]
								],
							ImageSize->Automatic
							],
						Button["Update",
							PacletUpdate[name,
								"Site"->site,
								"UpdateSites"->False
								],
							Enabled->
								StringQ[site]&&
								AllTrue[
									ToExpression/@
										StringSplit[Lookup[pacletFindData,"Version"],"."],
									!OrderedQ[
										ToExpression@StringSplit[coreAssoc["Version"],"."],
										#
										]&
									],
							ImageSize->Automatic
							]
						],
					Alignment->Right
					]
				}
			},
			BaseStyle->"Text",
			Frame->True,
			FrameStyle->GrayLevel[.8],
			Dividers->{
				Automatic, 
				{
					1->Black,
					2->GrayLevel[.4],
					3->GrayLevel[.8],
					4->GrayLevel[.8],
					5->GrayLevel[.8],
					6->GrayLevel[.4]
					}
				},
			Background->{{-1->GrayLevel[.98]}}
			]
		];
pacletServerInterfacePage~SetAttributes~HoldFirst


(* ::Subsubsection::Closed:: *)
(*pacletServerInterfaceEntry*)



pacletServerInterfaceEntry[
	var_,
	site_,
	coreAssoc_,
	pacletFindData_
	]:=
	With[{
		name=coreAssoc["Name"],
		version=coreAssoc["Version"],
		creator=Lookup[coreAssoc, "Creator", ""],
		description=Lookup[coreAssoc,"Description",""],
		page=
			pacletServerInterfacePage[var,site,coreAssoc,pacletFindData]
		},
		{
			(* Name *)
			Button[
				Hyperlink@name,
				var=page,
				Appearance->None,
				BaseStyle->"Hyperlink"
				],
			(* Version *)
			Row@{"v",version},
			(* Creator *)
			creator,
			(* Update / Install *)
			If[Length[pacletFindData]===0,
				Button["Install",
					PacletInstall[name,"Site"->site]
					],
				Button["Update",
					PacletUpdate[name,
						"Site"->site,
						"UpdateSites"->False
						],
					Enabled->
						StringQ[site]&&
							AllTrue[
								ToExpression/@
									StringSplit[Lookup[pacletFindData,"Version"],"."],
								!OrderedQ[
									ToExpression@StringSplit[coreAssoc["Version"],"."],
									#
									]&
								]
					]
				]
			}
		];
pacletServerInterfaceEntry~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*PacletServerInterface*)



PacletServerInterface//Clear


Options[PacletServerInterface]=
	Join[
		Options[Pane],
		Options[Grid]
		];
PacletServerInterface[
	siteBase:_String|_?OptionQ|None:None,
	siteDS_Dataset,
	displayStart_:Automatic,
	ops:OptionsPattern[]
	]:=	
	With[{
		ds=
			DeleteDuplicatesBy[#["Name"]&]@
			SortBy[
				{
					Lookup[#,"Name"],
					100000+-ToExpression@StringSplit[Lookup[#,"Version"],"."]
					}&
				]@Normal@siteDS,
		site=
			Replace[siteBase,
				o_?OptionQ:>
					PacletServerURL[o]
				]
		},
		DynamicModule[{
			main,
			display
			},
			display=
				If[StringQ@displayStart,
					With[{pf=PacletManager`PacletFind[displayStart]},
						If[Length@pf>0,
							pacletServerInterfacePage[
								display,
								siteDS,
								PacletInfoAssociation@
									pf[[1]],
								PacletInfoAssociation/@
									pf
								],
							Automatic
							]
						],
					Automatic
					];
			main=
				Pane[
					Grid[
						Prepend[
							Map[
								Item[
									Style[#, Bold],
									FrameStyle->Black,
									Alignment->{Left, Center},
									ItemSize->{Automatic, 2}
									]&,
								{"Name", "Version", "Creator", "Install"}
								]
							]@
						Map[
							pacletServerInterfaceEntry[
								display,
								site,
								#,
								PacletInfoAssociation/@
									PacletManager`PacletFind[#["Name"]]
								]&,
							ds
							],
						FilterRules[
							{
								ops,
								Background->
									{
										Automatic,
										Prepend[GrayLevel[.8]]@
											Flatten@ConstantArray[{White,GrayLevel[.95]},Length[ds]]
										},
								Frame->True,
								FrameStyle->GrayLevel[.8],
								Dividers->{
									Flatten@
										{
											Table[n+1->GrayLevel[.9],{n,3}]
											},
									Flatten@{
										Table[1+n->GrayLevel[.8],{n,Length[ds]-1}]
										}
									},
								BaseStyle->"Text",
								Alignment->Left
								},
							Options[Grid]
							]
						],
				FilterRules[{ops},
					Alternatives@@
						Complement[Keys[Options[Pane]],
							Keys@Options[Grid]
							]
					]
				];
			Dynamic[
				Replace[display,Automatic:>main],
				None
				]
			]
		];
PacletServerInterface[
	site:_String|_?OptionQ|Automatic:Automatic, 
	display_:Automatic,
	ops:OptionsPattern[]
	]:=
	With[
		{s=
			Replace[site,
				{
					Automatic:>
						PacletServerURL[
							With[{
								f=
									FilterRules[
										{ops},
										Except[Alternatives@@Join[Keys@Options[Grid], Keys@Options[Pane]]]
										]
								},
								If[Length@f>0,
									f,
									$PacletServer
									]
								]
							],
					o_?OptionQ:>
						PacletServerURL[o]
					}
				]
			},
		PacletServerInterface[
			s,
			PacletSiteInfoDataset[s],
			display,
			ops
			]
		]


(* ::Subsubsection::Closed:: *)
(*PacletServerExposedPaclets*)



PacletServerExposedPaclets//Clear


PacletServerExposedPaclets[
	pacletSpecs:{___Association}
	]:=
	Map[Normal,
		Select[
			SortBy[
				DeleteDuplicatesBy[
					Reverse@SortBy[ToExpression@StringSplit[#Version,"."]&]@
						Flatten@{pacletSpecs},
					#Name&
					],
				#Name&
				],
			!StringEndsQ[#Name,("_Part"~~NumberString)|"_Index"]&
			]
		];
PacletServerExposedPaclets[d_Dataset]:=
	PacletServerExposedPaclets@Normal@d;
PacletServerExposedPaclets[server:localPacletServerPat]:=
	PacletServerExposedPaclets@
		PacletSiteInfoDataset[
			PacletServerFile[server, "PacletSite.mz"]
			]


$PacletServerExposedPaclets:=
	PacletServerExposedPaclets@$PacletServer


(* ::Subsection:: *)
(*Sites Layout*)



(*

The server structure looks like this:
	
	PacletServer
	
	   + Paclets
	   - PacletSite.mz
	   + content
	      + posts
	        - paclet1.nb
	        - paclet1.md
	        - paclet2.nb
	        - paclet2.md
	        ...
	      + pages
	        - about.md (??)
	        
	   - SiteConfig.m

When the server is built the Paclets and PacletSite.mz are copied to output for deployment

*)


(* ::Subsection:: *)
(*Single Page*)



$PacletServerTitle="Paclet Server";
$PacletServerDescription="";


pacletDownloadLine[
	pacletDownloadNB_,
	pacletDownloadURL_
	]:=
	XMLElement["div",
		{
			"class"->"paclet-download-line"
			},
		{
			XMLElement["a",
				{
					"href"->"wolfram+cloudobject:"<>pacletDownloadNB
					},
				{
					"Notebook"
					}
				],
			" | ",
			XMLElement["a",
				{
					"href"->pacletDownloadURL
					},
				{
					"Paclet"	
					}
				]
			}
		];


Options[pacletSectionXML]=
	Options[PacletExpression];
pacletSectionXML[site_,ops:OptionsPattern[]]:=
	XMLElement["div",
		{
			"class"->"paclet-section",
			"id"->OptionValue["Name"]
			},
		{
			XMLElement["h3",
				{
					"class"->"paclet-name"
					},
				{
					OptionValue["Name"],
					XMLElement["span",
						{
							"class"->"paclet-version-text"
							},
						{
							" v"<>OptionValue["Version"],
							Replace[
								Replace[OptionValue["WolframVersion"],
									Except[_String]:>OptionValue["MathematicaVersion"]
									],{
								s_String:>
									" | Mathematica "<>s,
								_->Nothing
								}]
							}
						]
				}],
			XMLElement["div",
				{
					"class"->"paclet-section-box"
					},
				{
					pacletDownloadLine[
						URLBuild[{
							site,
							OptionValue["Name"]<>"-"<>
								OptionValue["Version"]<>".nb"
							}],
						URLBuild[{
							site,
							"Paclets",
							OptionValue["Name"]<>"-"<>
								OptionValue["Version"]<>".paclet"
							}]
						],
					XMLElement[
						"p",
						{
							"class"->"paclet-download-description"	
							},
						{
							Replace[
								OptionValue["Description"],
								Automatic->""
								]
							}
						]
					}
				]
			}
		];


$pacletServerCSS=
"
body { 
	background: #fafafa ;
	margin: 0;
	}
.paclet-server-title {
	width: 100%;
	margin: 0;
	padding: 10;
	left: 0;
	top: 0;
	border-bottom: 1px solid #b01919 ;
	background: #8f3939; 
	color: #fafafa;
	box-shadow: 0px 2px 2px #901919 ;
 }
.paclet-server-description { 
	color: #505050;
	margin-left: 20px;
 }
.paclet-section {
	margin-top: 25;
	margin-left: 20px;
	width: 95%;
	margin-bottom: 15px;
	box-shadow: 1px 1px 1px gray ;
	border-radius: 5px;
	}
.paclet-name {
	min-height: 25px;
	margin: 0;
	padding: 10;
	color: #fafafa;
	background: #3f3f3f;
	border: solid 1px #3f3f3f;
	box-shadow: 1px 2px 2px #5f5f5f;
	border-top-left-radius: 5px;
	border-top-right-radius: 5px;
	}
.paclet-section-box { 
	border-left: solid 1px gray;
	border-right: solid 1px gray;
	border-bottom: solid 1px gray;
	border-bottom-left-radius: 5px;
	border-bottom-right-radius: 5px; 
	background: #f6f6f6;
	margin: 0;
	margin-top: 2;
	padding: 10;
	min-height: 125px;
 }
.paclet-version-text { 
	color: gray; 
	}
a:link {
	color: gray;
	}
a:hover {
	color: #cf3939;
	}
a:visited {
	color: #8f3939;
	}
";


Options[pacletServerXML]={
	"Title"->Automatic,
	"Description"->Automatic
	};
pacletServerXML[
	site_,
	pacletSpecs:_Association|{___Association},
	ops:OptionsPattern[]
	]:=
	XMLElement["html",{},{
		XMLElement["head",{},
			{
				XMLElement["title",{},{
					Replace[
						Replace[OptionValue["Title"],
							Automatic|Default->$PacletServerTitle
							],
						Except[_String]->""
						]
					}],
				XMLElement["style",
					{},
					{
						$pacletServerCSS
						}
					]
		}],
		XMLElement["body",
			{},
			Flatten@{
				XMLElement["div",
					{
						"class"->"paclet-server-title"
						},
					{
						XMLElement["h2",{},{
							Replace[
								Replace[OptionValue["Title"],
									Automatic|Default->$PacletServerTitle
									],
								Except[_String]->""
								]
							}]
						}
					],
				XMLElement[
					"div",
					{
						"class"->"paclet-server-description"
						},
					{
						XMLElement["p",{},{
							Replace[
								Replace[OptionValue["Description"],
									Automatic|Default->$PacletServerDescription
									],
								Except[_String]->""
								]
							}]
						}
					],
				pacletSectionXML[site,#]&/@
					PacletServerExposedPaclets[pacletSpecs]
				}
			]
		}];


(* ::Subsubsection::Closed:: *)
(*PacletServerPage*)



Options[PacletServerPage]=
	Join[{
		Permissions->Automatic
		},
		Options[CloudExport],
		Options[PacletSiteURL],
		Options[pacletServerXML],{
		"Extension"->"main.html"
		}];
PacletServerPage[
	ops:OptionsPattern[]
	]:=
	Block[{
		pacletServer=
			PacletSiteURL[FilterRules[{ops},Options@PacletSiteURL]],
		pacletServerPageXML:=
			htmlExportString@
				pacletServerXML[
					pacletServer,
					Normal@PacletSiteInfoDataset[pacletServer],
					FilterRules[{ops},Options@pacletServerXML]
					]
		},
		If[StringStartsQ[pacletServer,"file:"],
			Export[
				FileNameJoin@
					Append[
						URLParse[pacletServer,"Path"],
						OptionValue@"Extension"
						],
				pacletServerPageXML,
				"Text"
				],
			CloudExport[
				HTMLTemplateNotebook;
				pacletServerPageXML,
				"HTML",
				URLBuild@{
					pacletServer,
					OptionValue@"Extension"
					},
				FilterRules[{
					ops,
					Permissions->pacletStandardServerPermissions@OptionValue[Permissions]
					},
					Options@CloudExport]
				]
			]
	]


(* ::Subsection:: *)
(*Add / Remove*)



(* ::Subsubsection::Closed:: *)
(*PacletServerAdd*)



PacletServerAdd//Clear


Options[PacletServerAdd]=
	Options@PacletUpload;
PacletServerAdd[
	server:localPacletServerPat,
	pacletSpecs:$PacletUploadPatterns,
	ops:OptionsPattern[]
	]:=
	PacletUpload[
		pacletSpecs,
		ops,
		Sequence@@
			FilterRules[
				Normal@server,
				Options@PacletUpload
				],
		"UseCachedPaclets"->False,
		"UploadSiteFile"->True
		];
PacletServerAdd[
	pacletSpecs:$PacletUploadPatterns,
	ops:OptionsPattern[]
	]:=
	With[{s=
		PacletServerAdd[
			$PacletServer,
			pacletSpecs,
			ops
			]
		},
		s/;Head[s]=!=PacletServerAdd
		]


(* ::Subsubsection::Closed:: *)
(*PacletServerRemove*)



PacletServerRemove//Clear


Options[PacletServerRemove]=
	Options@PacletRemove;
PacletServerRemove[
	server:localPacletServerPat,
	pacletSpecs:$PacletRemovePatterns,
	ops:OptionsPattern[]
	]:=
	PacletRemove[
		pacletSpecs,
		Sequence@@
			FilterRules[
				Flatten@{
					ops,
					"MergePacletInfo"->False,
					Normal@server
					},
				Options@PacletRemove
				]
		];
PacletServerRemove[
	pacletSpecs:$PacletRemovePatterns,
	ops:OptionsPattern[]
	]:=
	With[{
		s=
		PacletServerRemove[
			$PacletServer,
			pacletSpecs,
			ops
			]
		},
		s/;Head[s]=!=PacletServerRemove
		]


(* ::Subsubsection::Closed:: *)
(*PacletServerDelete*)



Options[PacletServerDelete]=
	{
		"DeleteLocal"->True,
		"DeleteCloud"->False
		};
PacletServerDelete[
	server:localPacletServerPat,
	ops:OptionsPattern[]
	]:=
	(
		If[OptionValue["DeleteLocal"],
			With[{d=Echo@PacletServerDirectory[server]},
				If[DirectoryQ[d],
					DeleteDirectory[PacletServerDirectory[server],
						DeleteContents->True
						]
					]
				]
			];
		If[OptionValue["DeleteCloud"],	
			With[{d=Quiet@Check[CloudObject@PacletServerURL[server], $Failed]},
				If[MatchQ[d, CloudObject],
					DeleteFile/@
						CloudObjects[d]
					]
				]
			];
		)


(* ::Subsection:: *)
(*Site*)



(* ::Subsubsection::Closed:: *)
(*PacletMarkdownNotebook Bits*)



pacletMarkdownNotebookDownloadLink[a_]:=
	Cell[
		TextData[
			ButtonBox["Download",
				BaseStyle->"Hyperlink",
					ButtonData->
					{
						URLBuild@{
							"Paclets",
							Lookup[a,"Name"]<>"-"<>
								Lookup[a,"Version"]<>".paclet"
							},
						None
						}
				]
			],
		"Text",
		CellTags->"DownloadLink"
		]


pacletMarkdownNotebookDescriptionText[a_]:=
	Cell[Lookup[a,"Description",""],"Text",
		CellTags->"DescriptionText"
		]


pacletMarkdownNotebookBasicInfoSection[a_,thing_]:=
	With[{d=Lookup[a,thing]},
		If[StringQ@d,
			Cell[
				CellGroupData[{
					Cell[thing,"Subsubsection",CellTags->thing],
					Cell[d,"Text"]
					}]
				],
			Nothing
			]
		]


pacletMarkdownNotebookExtensionSection[extensionData_]:=
	Cell[
		CellGroupData@
			Flatten@{
				Cell["Extensions","Subsection"],
				KeyValueMap[
					Cell@
						CellGroupData[Flatten@{
							Cell[#,"Subsubsection"],
							Replace[Normal@#2,{
								((Prepend|Append)->_):>Nothing,
								(k_->v_):>
									Cell[ToString[k]<>": "<>ToString[v],"Item"]
								},
								1]
							}]&,
					extensionData
					]
				},
		CellTags->"Extensions"
		]


(* ::Subsubsection::Closed:: *)
(*PacletMarkdownNotebook*)



PacletMarkdownNotebook[
	a_Association
	]:=
	Notebook[
		{
			Cell[
				BoxData@ToBoxes@
					a,
				"Metadata"
				],
			Cell@CellGroupData@
				Flatten@{
					Cell[Lookup[a,"Name","Unnamed Paclet"],"Section"],
					pacletMarkdownNotebookDownloadLink[a],
					pacletMarkdownNotebookDescriptionText[a],
					Prepend[Cell["","PageBreak"]]@
					Riffle[
						{
							Cell[
								CellGroupData[{
									Cell["Basic Information","Subsection"],
									pacletMarkdownNotebookBasicInfoSection[a,"Name"],
									pacletMarkdownNotebookBasicInfoSection[a,"Version"],
									pacletMarkdownNotebookBasicInfoSection[a,"Description"],
									pacletMarkdownNotebookBasicInfoSection[a,"Creator"]
									}],
								CellTags->"BasicInformation"
								],
							If[KeyMemberQ[a,"Extensions"],
								pacletMarkdownNotebookExtensionSection[a["Extensions"]],
								Nothing
								]
							},
					Cell["","PageBreak"]
					]
				}
			},
		StyleDefinitions->FrontEnd`FileName[Evaluate@{$PackageName,"MarkdownNotebook.nb"}]
		];
PacletMarkdownNotebook[p_PacletManager`Paclet]:=
	PacletMarkdownNotebook[
		PacletInfoAssociation@p
		];
PacletMarkdownNotebook[f_String?FileExistsQ,a_]:=
	PacletMarkdownNotebookUpdate[f,a];
PacletMarkdownNotebook[f_String,a_]:=
	With[{nb=PacletMarkdownNotebook[a]},
		Switch[nb,
			_Notebook,
				If[!DirectoryQ@DirectoryName@f,
					CreateDirectory[DirectoryName@f,
						CreateIntermediateDirectories->True
						]
					];
				Export[f,nb],
			_,
				$Failed
			]
		]


(* ::Subsubsection::Closed:: *)
(*PacletMarkdownNotebookUpdate*)



PacletMarkdownNotebookUpdate[notebook_Notebook,a_]:=
	Module[{nb=notebook},
		nb=
			ReplaceAll[nb,
				Cell[BoxData[e_],"Metadata",___]:>
					Cell[
						BoxData@ToBoxes@
							Merge[{ToExpression[e],a},Last],
						"Metadata"
						]
				];
		nb=
			ReplaceAll[nb,
				Cell[___,CellTags->"DownloadLink",___]:>
					pacletMarkdownNotebookDownloadLink[a]
				];
		nb=
			ReplaceAll[nb,
				Cell[___,CellTags->"DescriptionText",___]:>
					pacletMarkdownNotebookDescriptionText[a]
				];
		Map[
			Function[
				nb=	
					ReplaceAll[nb,
						Cell[
							CellGroupData[{
								Cell[___,
									CellTags->#,
									___
									],
								___
								},
								___],
							___
							]:>
								pacletMarkdownNotebookBasicInfoSection[a,#]
						]
				],
			DeleteCases[Keys[a],
				"Extensions"|"Tags"|"Categories"|"Authors"
				]
			];
		nb=
			DeleteCases[nb,
				Cell[
					CellGroupData[{
						Cell[___,
							CellTags->
								Except[
									Alternatives@@
										Join[{
											"DescriptionText",
											"DownloadLink",
											"BasicInformation"
											},
											Keys[a]
											]
									],
							___
							],
						___
						},___],
					___
					],
				\[Infinity]
				];
		nb=
			ReplaceAll[nb,
				Cell[
					CellGroupData[{
						Cell[___,
							CellTags->"Extensions",
							___]
						},___
						],
					___
					]:>
					pacletMarkdownNotebookExtensionSection[a["Extensions"]]
				];
		nb
		];
PacletMarkdownNotebookUpdate[f_String?FileExistsQ,a_]:=
	With[{nb=Import[f]},
		Switch[nb,
			_Notebook,
				Export[
					f,
					PacletMarkdownNotebookUpdate[nb,a]
					],
			_,
				$Failed
			]
		]


(* ::Subsubsection::Closed:: *)
(*PacletServerInitialize*)



PacletServerInitialized[server_]:=
	With[{d=PacletServerDirectory[server]},
		AllTrue[{d,
			FileNameJoin@{d,"content"},
			FileNameJoin@{d,"SiteConfig.wl"}
			},
			FileExistsQ
			]
		];
$PacletServerInitialized:=
	PacletServerInitialized@$PacletServer


PacletServerInitialize[server:localPacletServer]:=
	If[!PacletServerInitialized@server,
		With[{d=PacletServerDirectory@server},
			If[!DirectoryQ@DirectoryName[d],	
				CreateDirectory@DirectoryName[d]
				];
			With[{tempDir=PackageFilePath["Resources","Templates","PacletServer"]},
				Map[
					With[
						{
							tf=FileNameJoin@{d,FileNameDrop[#,FileNameDepth[tempDir]]}
							},
						If[!FileExistsQ@tf,
							If[DirectoryQ@#,
								CopyDirectory[#, tf],
								CopyFile[#, tf]
								]
							]
						]&,
					FileNames["*",tempDir]
					];
				]
			]
		]


(* ::Subsubsection::Closed:: *)
(*PacletServerBuild*)



PacletServerBuild//Clear


Options[PacletServerBuild]=
	Join[
		Options[WebSiteBuild],
		{
			"RegenerateContent"->True,
			"BuildSite"->True
			}
		];
PacletServerBuild[
	server:localPacletServerPat,
	ops:OptionsPattern[]
	]:=
	With[{siteData=PacletServerExposedPaclets[server]},
		PacletServerInitialize[server];
		If[OptionValue["RegenerateContent"],
			With[{nbout=PacletServerFile[server, {"content","posts",#Name<>".nb"}]},
				PacletMarkdownNotebook[
					nbout,
					Join[
						<|
							"Title"->Lookup[#,"Name","Unnamed Paclet"],
							"Categories"->"misc",
							"Slug"->Automatic,
							"Authors"->
								StringTrim@
									Map[
										StringSplit[#,"@"][[1]]&,
										StringSplit[Lookup[#,"Creator",""],","]
										],
							"Tags"->StringSplit[Lookup[#,"Keywords",""],","]
							|>,
						#
						]
					];
				Function[NotebookMarkdownSave[#];NotebookClose[#]]@
					NotebookOpen[nbout,Visible->False];
				]&/@Association/@siteData
			];
		With[{s=
			If[TrueQ@OptionValue["BuildSite"],
				WebSiteBuild[
					PacletServerDirectory[server],
					"AutoDeploy"->False,
					"Configuration"->
						With[
							{
								conf=
									Replace[
										Quiet@Import@
											If[FileExistsQ@PacletServeFile[server, "SiteConfig.m"],
												PacletServeFile[server, "SiteConfig.m"],
												PacletServeFile[server, "SiteConfig.wl"]
												],
										{
											o_?OptionQ:>
												Association[o],
											_-><||>
											}
										]
								},
							Join[
								<|
									"SiteName"->
										Lookup[server, "ServerName"],
									"SiteURL"->
										With[
											{
												cc=
													PacletServerDeployURL[server]
												},
											conf
											],
									CloudConnect->
										server[CloudConnect],
									Permissions->
										server[Permissions]	
									|>,
								conf
								]
							],
					Sequence@@
						FilterRules[
							FilterRules[{ops},
								Options@WebSiteBuild
								],
							Except["AutoDeploy"]
							]
					],
				Quiet@CreateDirectory@PacletServerFile[server, "output"];
				PacletServerFile[server, "output"]
				]
			},
			If[TrueQ[OptionValue["AutoDeploy"]]||
				TrueQ@
					OptionValue["AutoDeploy"]===Automatic&&
						Lookup[
							Replace[Quiet@Import[PacletServerFile[server, "SiteConfig.wl"]],
								Except[_Association]:>{}
								],
							"AutoDeploy"
							],
				PacletServerDeploy[
					server,
					Replace[
						OptionValue["DeployOptions"],
						Except[_?OptionQ]->{}
						]
					],
				s
				]
			]
		];


(* ::Subsubsection::Closed:: *)
(*PacletServerDeploy*)



PacletServerDeploy//Clear


PacletServerDeploy::nobld=
	"PacletServerBuild needs to be called before PacletServerDeploy can work";


Options[PacletServerDeploy]=
	Join[
		Options[WebSiteDeploy],
		{
			"DeployPages"->True
			}
		];
PacletServerDeploy[
	server:localPacletServerPat,
	ops:OptionsPattern[]
	]:=
	If[
		DirectoryQ@PacletServerFile[server, "output"]||
			DirectoryQ@PacletServerFile[server, "Paclets"],
		With[
			{
				baseConfig=
					Lookup[
						Replace[Quiet@Import[PacletServerFile[server, "SiteConfig.wl"]],
							Except[_?OptionQ]:>{}
							],
						"DeployOptions",
						{}
						]
				},
				If[!DirectoryQ@PacletServerFile[server, "output"],
					CreateDirectory@PacletServerFile[server, "output"]
					];
				WebSiteDeploy[
					PacletServerFile[server, "output"],
					Lookup[server, "ServerName"],
					FilterRules[
						Normal@
							Merge[
								{
									ops,
									CloudConnect->
										Lookup[server, CloudConnect],
									Permissions->
										Lookup[server, Permissions],
									baseConfig,
									"ExtraFileNameForms"->
										{
											"PacletSite.mz",
											"*.paclet"
											},
									"IncludeFiles"->
										{
											PacletServerFile[server, "PacletSite.mz"],
											PacletServerFile[server, "Paclets"]
											}
										},
								Replace[
									{
										{s:_String|_?OptionQ,___}:>s,
										e_:>Flatten@e
										}
									]
								],
						Options@WebSiteDeploy
						]
					]
			],
		Message[PacletServerDeploy::nobld];
		$Failed
		];


End[];



