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



CustomServiceConnection::usage="Builds a custom ServiceConnection paclet"


Begin["`Private`"];


CustomServiceConnection::ifkey="Import function `` missing keys ``";


Options[customServiceConnectionImportFunction]:=
	{
		"URL"->None,
		"Method"->"GET",
		"Body"->None,
		"Headers"->None,
		"Path"->None,
		"Parameters"->None,
		"Required"->None,
		"Function"->None,
		"Permissions"->None,
		"ReturnContentData"->None,
		"RequiredPermissions"->None,
		"IncludeAuth"->None,
		"MultipartData"->None,
		"BodyData"->None
		};
customServiceConnectionImportFunction[name_,ops:OptionsPattern[]]:=
	With[
		{
			basic=
				DeleteCases[None]@
					Association@{ops},
			required=
				{"URL","Path"}
			},
		With[{
			function=
				Join[
					DeleteCases[{}]@
						<|
							"BodyData"->
								Cases[Lookup[basic,"Body",{}],_String|_Rule],
							"MultipartData"->
								Cases[Lookup[basic,"Body",{}],_List]
							|>,
					KeyDrop[
						KeyMap[
							Replace[{
								"Method"->"HTTPSMethod",
								"Path"->"PathParameters",
								"Required"->"RequiredParameters",
								"Function"->"ResultsFunction",
								"Permissions"->"RequiredPermisssions"
								}],
							If[!(KeyMemberQ[basic,"Method"]&&KeyMemberQ[basic,"HTTPSMethod"]),
								Append["Method"->OptionValue["Method"]],
								Identity
								]@basic
							],
						"Body"
						]
					]
			},
			Replace[
				Select[MissingQ]@
					Lookup[function,AssociationThread[required,required]],{
					a_?(Length@#>0&):>
						(
							Message[CustomServiceConnection::ifkey,name,Keys@a];
							$Failed
							),
					_:>
						(name->Normal@function)
				}]
			]
		]


CustomServiceConnection::pfkey="Process function `` missing keys ``";


Options[customServiceConnectionProcessFunction]={
	"Call"->None,
	"Method"->None,
	"CleanArguments"->None,
	"Pre"->None,
	"Import"->None,
	"Post"->None,
	"Default"->None,
	"Parameters"->None,
	"Required"->None
	};
customServiceConnectionProcessFunction[name_,ops:OptionsPattern[]]:=
	With[
		{
			function=
				DeleteCases[None]@
					Association@{ops},
			required=
				{}
			},
		Replace[
			Select[MissingQ]@
				Lookup[function,AssociationThread[required,required]],{
				a_?(Length@#>0&):>
					(
						Message[CustomServiceConnection::pfkey,name,Keys@a];
						$Failed
						),
				_:>
					(name->function)
			}]
		];
	customServiceConnectionProcessFunction[name_,func_]:=
		customServiceConnectionProcessFunction[name,
			"Call"->"Raw"<>name,
			"Import"->func
			]


$customServiceExportContext=$Context;


customServiceTemplateExport[
	name_,
	dir_,
	template_,
	params_
	]:=
	With[{
		tf=
			PackageFilePath[
				"Resources",
				"Templates",
				"$ServiceConnection",
				"Kernel",
				template<>".m"
				],
		out=
			FileNameJoin@{
				dir,
				"ServiceConnection_"<>name,
				"Kernel",
				StringReplace[
					template,
					"$ServiceConnection"->
						name
					]<>".m"
				}
		},
		Block[{$Context=$customServiceExportContext},
			Export[out,
				StringReplace[
					Import[tf,"Text"],
					With[{obj=#2,key=#},
						#->
							Switch[obj,
								Verbatim[Verbatim][_String],
									First@obj,
								_Function,
									"("<>ToString[#2,InputForm]<>")",
								_,
									If[(ListQ@obj||AssociationQ@obj)&&Length@obj>0,
										Replace[
											NewlineateCodeRecursive[
												obj,
												_List|_Association|_Rule
												],{
											RawBoxes[r_]:>
											"\n"<>
												FrontEndExecute[
													ExportPacket[
														Cell[
															BoxData@r,
															"Input"
															],
														"InputText"
														]
													][[1]],
											e_:>(ToString[obj,InputForm])
										}],
										ToString[obj,InputForm]
										]
								]
						]&@@@params
					],
				"Text"
				]
			]
		];


$customServiceConnectionBaseFetchFunction=
	(
			With[ {params = Lookup[{##2},"Parameters",{}]},
				URLFetch[#1,
					Sequence@@FilterRules[{##2},Except["Parameters"]],
						"Parameters" -> 
							FilterRules[params, 
									Except[{"accountid", "authtoken"}]
									],
						"Username"->"accountid"/.params,
						"Password"->"authtoken"/.params
						]
				]&
			)


Options[customServiceConnectionPrep]={
	"Fetch"->
		Automatic,
	"Client"->
		Automatic,
	"ClientInfo"->
		Automatic,
	"ClientID"->None,
	"ClientSecret"->None,
	"AuthorizationResponseType"->None,
	"RedirectURI"->None,
	"AuthorizationState"->None,
	"AuthorizationScope"->None,
	"LoginURL"->
		None,
	"LogoutURL"->
		None,
	"UseOAuth"->
		Automatic,
	"AuthorizeEndpoint"->
		Automatic,
	"AccessEndpoint"->
		Automatic,
	"TokenRequestor"->
		None,
	"TokenExtractor"->
		None,
	"TermsOfServiceURL"->
		None,
	"Information"->
		None,
	"Icon"->
		None,
	"Functions"->
		None
	};
customServiceConnectionPrep[
	name_,
	dir_,
	functionData:_List?OptionQ,
	cookingData:_List?OptionQ,
	ops:OptionsPattern[]
	]:=
	With[{
		imps=
			Association[customServiceConnectionImportFunction@@@functionData],
		preps=
			Association[customServiceConnectionProcessFunction@@@cookingData]
		},
		With[{
			params=
			Flatten@{
				"$ServiceConnectionURLFetch"->
					OptionValue@"Fetch",
				"$ServiceConnectionClientInfo"->
					OptionValue@"ClientInfo",
				"$ServiceConnectionClientName"->
					StringReplace[
						Replace[
							HoldPattern[Capitalize[s_String]]:>
								(ToUpperCase@StringTake[s,1]<>StringDrop[s,1])
							]@Capitalize@ToLowerCase@
							StringTrim[
								Replace[OptionValue@"Client",{
									Automatic:>
										If[
											Replace[OptionValue@"UseOAuth",
												Except[True|False]:>
													!MatchQ[OptionValue["AuthorizeEndpoint"],Automatic|None]&&
														!MatchQ[OptionValue["AccessEndpoint"],Automatic|None]
												]//TrueQ,
											"OAuth",
											"Key"
											],
									Except[_String]->"Key"
									}],
								"client"
								]<>"Client",
						"Oauth"->"OAuth"
						],
				"$ServiceConnectionUseOAuth"->
					Replace[OptionValue@"UseOAuth",
						Except[True|False]:>
							StringQ@OptionValue@"Client"&&
								StringStartsQ[ToLowerCase@OptionValue@"Client","oauth"]||
							!MatchQ[OptionValue["AuthorizeEndpoint"],Automatic|None]&&
								!MatchQ[OptionValue["AccessEndpoint"],Automatic|None]
						],
				"$ServiceConnectionAuthEndpoint"->
					Replace[OptionValue@"AuthorizeEndpoint",
						Automatic:>
							If[
								TrueQ[
									TrueQ@OptionValue@"UseOAuth"||
										StringQ@OptionValue@"Client"&&
											StringStartsQ[ToLowerCase@OptionValue@"Client","oauth"]
									],
								"https://localhost:8080/oauth2authorize",
								None
								]
							],
				"$ServiceConnectionAccessEndpoint"->
					Replace[OptionValue@"AccessEndpoint",
						Automatic:>
							If[
								TrueQ[
									TrueQ@OptionValue@"UseOAuth"||
										StringQ@OptionValue@"Client"&&
											StringStartsQ[ToLowerCase@OptionValue@"Client","oauth"]
									],
								"https://localhost:8080/oauth2access",
								None
								]
							],
				"$ServiceConnectionAccessTokenRequestor"->
					OptionValue@"TokenRequestor",
				"$ServiceConnectionAccessTokenExtractor"->
					OptionValue@"TokenExtractor",
				"$ServiceConnectionTermsOfServiceURL"->
					OptionValue@"TermsOfServiceURL",
				"$ServiceConnectionClientID"->
					OptionValue@"ClientID",
				"$ServiceConnectionClientSecret"->
					OptionValue@"ClientSecret",
				"$ServiceConnectionAuthResponseType"->
					OptionValue@"AuthorizationResponseType",
				"$ServiceConnectionState"->
					OptionValue@"AuthorizationState",
				"$ServiceConnectionAuthScope"->
					OptionValue@"AuthorizationScope",
				"$ServiceConnectionRedirectURI"->
					Replace[OptionValue@"RedirectURI",
						Automatic:>
							If[OptionValue@"UseOAuth"||
								StringQ@OptionValue@"Client"&&
									StringStartsQ[ToLowerCase@OptionValue@"Client","oauth"],
								"https://localhost:7000/oauth2callback",
								None
								]
							],
				"$ServiceConnectionCalls"->
					imps,
				"$ServiceConnectionCookingFunctions"->
					preps,
					With[{r=#,b=ToUpperCase@StringTrim[#,"s"]},
						With[{
							impSpec=
								Cases[Normal@imps,
									(k_->{
										___,
										"HTTPSMethod"->_?(
											(ToUpperCase@#/.("PATCH"|"PUT"|"DELETE"->"POST"))===b&),
										___
										}):>k
									]
							},
						Sequence@@
							{
								"$ServiceConnectionRaw"<>r->
									impSpec,
								"$ServiceConnection"<>r->
									Join[
										Keys@
											Select[preps,
												If[KeyMemberQ[#,"Method"],
													ReplaceAll[
														ToUpperCase@#["Method"],
														"PATCH"|"PUT"|"DELETE"->"POST"
														]===ToUpperCase@StringTrim[r,"s"],
													MemberQ[impSpec,#["Call"]]
													]&
												],
										If[r==="Gets",
											Keys@
												Select[preps,
													AllTrue[
														Lookup[#,{"Call","Method"}],
														MissingQ
														]&
													],
											{}
											]
										]
								}
						]
					]&/@{"Gets","Posts"},
				"$ServiceConnectionInformation"->
					OptionValue@"Information",
				"$ServiceConnectionIcon"->
					OptionValue@"Icon",
				"$ServiceConnectionHelperNames"->
					Verbatim@
						StringRiffle[
							Replace[
								Flatten@DeleteCases[None]@{OptionValue@"Functions"},{
								(k_->f_):>
									ToString[k],
								e_:>
									ToString@e
								},
								1],
							"\n\n"
							],
				"$ServiceConnectionHelperFunctions"->
					Block[{$ContextPath={"System`",$Context}},
						Verbatim@
							StringRiffle[
								Replace[
									Flatten@DeleteCases[None]@{OptionValue@"Functions"},{
									(k_->f_):>
										(ToString[k]<>" = "<>ToString[f,InputForm]),
									e_:>
										ToString[Definition@e,InputForm]
									},
									1],
								"\n\n"
								]
						],
				"$ServiceConnection"->
					Verbatim@name,
				"$serviceconnection"->
					Verbatim@ToLowerCase@name
				}
			},
			customServiceTemplateExport[
				name,
				dir,
				#,
				params
				]&/@{
					"load",
					"$ServiceConnection",
					"$ServiceConnectionFunctions",
					"$ServiceConnectionLoad"
					};
			
			]
		]


Options[CustomServiceConnection]=
	Join[
		{
			"ImportFunctions"->{},
			"ProcessFunctions"->{},
			"Icon"->None
			},
		Options@customServiceConnectionPrep,
		Options@PacletInfoExpressionBundle
		];


CustomServiceConnection[
	name_String?(StringMatchQ[WordCharacter..]),
	directory:_String?DirectoryQ|Automatic:Automatic,
	pack:True|False:True,
	ops:OptionsPattern[]
	]:=
	With[{dir=Replace[directory,Automatic:>$TemporaryDirectory]},
		Quiet@CreateDirectory@
			FileNameJoin@{
				dir,
				"ServiceConnection_"<>name,
				"Kernel"
				};
		With[{res=
			customServiceConnectionPrep[
				name,
				dir,
				OptionValue@"ImportFunctions",
				OptionValue@"ProcessFunctions",
				FilterRules[{
					"Icon"->
						Replace[OptionValue@"Icon",{
							Graphics[e_,o___]:>
								Graphics[e,ImageSize->24,o],
							Except[None|_Graphics]->Automatic
							}],
						ops},
					Options@customServiceConnectionPrep]
				]
			},
			If[AllTrue[res,StringQ@#&&FileExistsQ@#&],
				With[{
					bmdir=
						FileNameJoin@{
								dir,
								"ServiceConnection_"<>name,
								"FrontEnd",
								"SystemResources",
								"Bitmaps"
							},
					things=
						Replace[OptionValue@"Icon",{
							g_Graphics:>
								{
									Insert[g,
										ImageSize->24,
										2
										],
									Insert[g,
										ImageSize->48,
										2
										]
									},
							i_?ImageQ:>
								{
									ImageResize[i,{24}],
									ImageResize[i,{48}]
									},
							e:Except[None|{_,_}]:>
								{
									Rasterize[e,"Image",
										RasterSize->{24,24}],
									Rasterize[e,"Image",
										RasterSize->{48,48}]
									}
							}]
					},
						If[ListQ@things&&Length@things==2,
							Quiet@CreateDirectory@bmdir;
							If[MatchQ[First@things,(_File|_String)?FileExistsQ],
								CopyFile[
									First@things,
									FileNameJoin@{
										bmdir,
										ToLowerCase@name<>".png"
										}
									],
								Export[
									FileNameJoin@{
										bmdir,
										ToLowerCase@name<>".png"
										},
									First@things
									];
							If[MatchQ[Last@things,(_File|_String)?FileExistsQ],
								CopyFile[
									Last@things,
									FileNameJoin@{
										bmdir,
										ToLowerCase@name<>"@2.png"
										}
									],
								Export[
									FileNameJoin@{
										bmdir,
										ToLowerCase@name<>"@2.png"
										},
									Last@things
									]
								]
							]
						]
					];
				If[pack,
					PacletInfoExpressionBundle[
						FileNameJoin@{dir,"ServiceConnection_"<>name},
						FilterRules[Flatten@{
							FilterRules[{ops}, Except["Icon"]],
							"Icon"->
								FileNameJoin@{
										"FrontEnd",
										"SystemResources",
										"Bitmaps",
										ToLowerCase@name<>"@2.png"
										}
								},
							Options@PacletInfoExpressionBundle
							]
						];
					PacletBundle@FileNameJoin@{dir,"ServiceConnection_"<>name},
					FileNameJoin@{dir,"ServiceConnection_"<>name}
					]
				]/;AllTrue[res,StringQ@#&&FileExistsQ@#&]
			]
		]


End[];



