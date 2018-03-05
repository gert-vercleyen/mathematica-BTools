(* ::Package:: *)

(* ::Subsection:: *)
(*Constants*)


(* ::Subsubsection::Closed:: *)
(*Naming*)


$PackageDirectory=
	DirectoryName@$InputFileName;
$PackageName=
	"$Name";


(* ::Subsubsection::Closed:: *)
(*Loading*)


$PackageListing=<||>;
$PackageContexts={
		"$Name`",
		"$Name`PackageScope`Private`",
		"$Name`PackageScope`Package`"
		};
$PackageDeclared=
	TrueQ[$PackageDeclared];


(* ::Subsubsection::Closed:: *)
(*Scoping*)


$PackageFEHiddenSymbols={};
$PackageScopedSymbols={};
$PackageLoadSpecs=
	Merge[
		{
			With[
				{
					f=
						Append[
							FileNames[
								"LoadInfo."~~"m"|"wl",
								FileNameJoin@{$PackageDirectory, "Config"}
								],
							None
							][[1]]
					},
				Replace[
						Quiet[
							Import@f,
							{
								Import::nffil,
								Import::chtype
								}
							],
					Except[KeyValuePattern[{}]]:>
						{}
					]
				],
			With[
				{
					f=
						Append[
							FileNames[
								"LoadInfo."~~"m"|"wl",
								FileNameJoin@{$PackageDirectory, "Private", "Config"}
								],
							None
							][[1]]},
				Replace[
					Quiet[
						Import@f,
						{
							Import::nffil,
							Import::chtype
							}
						],
					Except[KeyValuePattern[{}]]:>
						{}
					]
				]
			},
		Last
		];
$AllowPackageRescoping=
	Replace[
		Lookup[$PackageLoadSpecs, "AllowRescoping"],
		Except[True|False]->
			$TopLevelLoad
		];
$AllowPackageRecoloring=
	Replace[
		Lookup[$PackageLoadSpecs, "AllowRecoloring"],
		Except[True|False]->
			$TopLevelLoad
		];
