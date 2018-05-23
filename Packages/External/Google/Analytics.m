(* ::Package:: *)



$GoogleAnalyticsCalls::usage="";


GAAnalyticsReportsRequest::usage="";
GAAnalyticsReportsCall::usage="";


GAAGetReport::usage="";


Begin["`Private`"];


(* ::Subsection:: *)
(*API Basics*)



(* ::Subsubsection::Closed:: *)
(*Requests*)



GAAnalyticsRequest[
	mode:"AnalyticsReporting":"AnalyticsReporting",
	passoc_Association,
	assoc:_Association:<||>
	]:=
	Block[{$GAVersion=4},
		GARequest[
			"AnalyticsReporting",
			passoc,
			assoc
			]
		];
GAAnalyticsRequest[
	mode:"AnalyticsReporting":"AnalyticsReporting",
	path:_String|{__String}|Nothing:Nothing,
	query:_Rule|{___Rule}:{},
	assoc:_Association:<||>
	]:=
	Block[{$GAVersion=4},
		GARequest[
			"AnalyticsReporting",
			path,
			query,
			assoc
			]
		];


GoogleAnalytics::err="\n``";


(* ::Subsection:: *)
(*Calls*)



If[!AssociationQ@$GoogleAnalyticsCalls,
	$GoogleAnalyticsCalls=<||>
	];


(* ::Subsection:: *)
(*Report*)



(* ::Subsubsection::Closed:: *)
(*ReportDimensions*)



$GAAReportDimensions=
	<|
		"UserDimensions"->
			{
				"UserType","VisitorType","SessionCount",
				"VisitCount","DaysSinceLastSession","UserDefinedValue",
				"UserBucket"
				},
		"SessionDimensions"->
			{
				"SessionDurationBucket","VisitLength"
				},
		"TrafficSourceDimensions"->
			{
				"ReferralPath","FullReferrer","Campaign",
				"Source","Medium","SourceMedium",
				"Keyword","AdContent","SocialNetwork",
				"HasSocialSourceReferral","CampaignCode"
				},
		"PageDimensions"->
			{
				"Hostname","PagePath","PagePathLevel1",
				"PagePathLevel2","PagePathLevel3","PagePathLevel4",
				"PageTitle","LandingPagePath","SecondPagePath",
				"ExitPagePath","PreviousPagePath","PageDepth"
				},
		"LocationDimensions"->
			{
				"Continent","SubContinent","Country",
				"Region","Metro","City",
				"Latitude","Longitude","NetworkDomain",
				"NetworkLocation","CityId","ContinentId",
				"CountryIsoCode","MetroId","RegionId",
				"RegionIsoCode","SubContinentCode"
				},
		"TimeDimensions"->
			{
				"Date","Year","Month",
				"Week","Day","Hour",
				"Minute","NthMonth","NthWeek",
				"NthDay","NthMinute","DayOfWeek",
				"DayOfWeekName","DateHour","DateHourMinute",
				"YearMonth","YearWeek","IsoWeek",
				"IsoYear","IsoYearIsoWeek","NthHour"
				},
		"AudienceDimensions"->
			{
				"UserAgeBracket","VisitorAgeBracket","UserGender",
				"VisitorGender","InterestOtherCategory",
				"InterestAffinityCategory",
				"InterestInMarketCategory"
				},
		"EventDimensions"->
			{
				"EventCategory","EventAction","EventLabel"
				}
		|>;


$GoogleAnalyticsCalls["ReportDimensions"]=
	GAAReportDimensions;


GAAReportDimensions//Clear


GAAReportDimensions[]:=
	$GAAReportDimensions;
GAAReportDimensions[p_String, e___String, ___]:=
	$GAAReportDimensions[StringTrim[p, "s"|"Dimensions"]<>"Dimensions", e];


(* ::Subsubsection::Closed:: *)
(*ReportMetrics*)



$GAAReportMetrics=
	<|
		"UserMetrics"->
			{
				"Users","Visitors","NewUsers",
				"NewVisits","1DayUsers","7DayUsers",
				"14DayUsers","28DayUsers","30DayUsers",
				"SessionsPerUser",
				"PercentNewSessions","PercentNewVisits"
				},
		"SessionMetrics"->
			{
				"Sessions",
				"Visits","Bounces","SessionDuration",
				"UniqueDimensionCombinations","Hits",
				"BounceRate","VisitBounceRate","AvgSessionDuration"
				},
		"TrafficSourceMetrics"->
			{
				"OrganicSearches"
				},
		"PageMetrics"->
			{
				"PageValue","Entrances","Pageviews",
				"UniquePageviews","TimeOnPage","Exits",
				"EntranceRate","PageviewsPerSession","PageviewsPerVisit",
				"AvgTimeOnPage","ExitRate"
				},
		"EventMetrics"->
			{
				"TotalEvents","UniqueEvents","EventValue",
				"SessionsWithEvent","VisitsWithEvent","AvgEventValue",
				"EventsPerSessionWithEvent","EventsPerVisitWithEvent"
				}
		|>;


$GoogleAnalyticsCalls["ReportMetrics"]=
	GAAReportMetrics;


GAAReportMetrics//Clear


GAAReportMetrics[]:=
	$GAAReportMetrics;
GAAReportMetrics[p_, e___String, ___]:=
	$GAAReportMetrics[StringTrim[p, "s"|"Metrics"]<>"Metrics", e];


(* ::Subsubsection::Closed:: *)
(*GetReport*)



$GoogleAnalyticsCalls["GetReport"]=
	GAAGetReport;


$GAParamMap["GetReport"]=
	{
		"dateRanges"->Automatic,
		"samplingLevel"->Automatic,
		"dimensions"->Automatic,
		"dimensionFilterClauses"->Automatic,
		"metrics"->Automatic,
		"metricFilterClauses"->Automatic,
		"filtersExpression"->Automatic,
		"orderBys"->Automatic,
		"segments"->Automatic,
		"pivots"->Automatic,
		"cohortGroup"->Automatic,
		"pageToken"->Automatic,
		"pageSize"->Automatic,
		"includeEmptyRows"->Automatic,
		"hideTotals"->Automatic,
		"hideValueRanges"->Automatic
		};


gaaDecapsMet[s_]:=
	With[{bits=
		DeleteCases[""]@
			StringSplit[s, StartOfString~~n:NumberString:>n, 2]},
		"ga:"<>
			If[Length@bits==2,
				bits[[1]]<>
					ToLowerCase@StringTake[bits[[2]], 1]<>StringDrop[bits[[2]], 1],
				ToLowerCase@StringTake[bits[[1]], 1]<>StringDrop[bits[[1]], 1]
				]
		]


gaaPrepMetrics[s:{__String}]:=
	Map[
		{"expression"->gaaDecapsMet[#]}&,
		Take[
			s,
			UpTo[10]
			]
		]


gaaPrepDims[s:{__String}]:=
	Map[
		{"name"->gaaDecapsMet[#]}&,
		Take[
			s,
			UpTo[10]
			]
		]


gaaPrepReportReqs[s_String]:=
	{
		"metrics"->
			gaaPrepMetrics@
				Lookup[$GAAReportMetrics, 
					StringTrim[s, "s"]<>"Metrics",
					{}
					],
		"dimensions"->
			gaaPrepDims@
				Lookup[$GAAReportDimensions, 
					StringTrim[s, "s"]<>"Dimensions",
					{}
					]
		};
gaaPrepReportReqs[___]:={};


GAAGetReport//Clear


Options[GAAGetReport]=
	Join[
		{
			"StartDate":>DateObject[{2005, 1, 1}],
			"EndDate":>Tomorrow,
			"Reports"->None,
			"Metrics"->None,
			"Dimensions"->None
			},
		$GAParamMap["GetReport"]
		];
GAAGetReport[
	viewID:_String|_Integer,
	ops:OptionsPattern[]
	]:=
	GAAnalyticsRequest[
		<|
			"Path"->"reports",
			"Port"->"batchGet"
			|>,
		<|
			"Method"->"POST",
			"Body"->
				ExportString[
					{
						"reportRequests"->
							Flatten@
								{
									"viewId"->ToString@viewID,
									GAPrepParams[
										{
											ops,
											"dateRanges"->
												{
													"startDate"->OptionValue["StartDate"],
													"endDate"->OptionValue["EndDate"]
													},
											Replace[OptionValue["Metrics"],
												{
													s_String:>
														("metrics"->gaaPrepMetrics[{s}]),
													s:{__String}:>
														("metrics"->gaaPrepMetrics[s]),
													_->{}
													}
												],
											Replace[OptionValue["Dimensions"],
												{
													s_String:>
														("dimensions"->gaaPrepDims[{s}]),
													s:{__String}:>
														("dimensions"->gaaPrepDims[s]),
													_->{}
													}
												],
											Sequence@@
												Normal@
													Merge[
														Replace[Except[_List]->{}]@
														Map[gaaPrepReportReqs, OptionValue["Reports"]],
														Flatten[#, 1]&
														]
											},
										GAAGetReport,
										"GetReport"
										]
									}
						},
					"JSON"
					]
			|>
		]


(* ::Subsubsection::Closed:: *)
(*NamedReports*)



$GoogleAnalyticsCalls["NamedReports"]=
	GAANamedReport;


$GAANamedReports=
	<|
		"PageUserNumbers"->
			{
				"Dimensions"->
					{
						"PagePath"
						},
				"Metrics"->
					{
						"Users", 
						"Visitors",
						"NewUsers",
						"NewVisits"
						}
				},
		
		|>



				


End[];



