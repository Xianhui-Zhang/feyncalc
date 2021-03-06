(* ::Package:: *)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: SimplifyPolyLog													*)

(*
	This software is covered by the GNU General Public License 3.
	Copyright (C) 1990-2018 Rolf Mertig
	Copyright (C) 1997-2018 Frederik Orellana
	Copyright (C) 2014-2018 Vladyslav Shtabovenko
*)

(* :Summary:  Simplifies expressions containing polylogarithms				*)

(* ------------------------------------------------------------------------ *)


SimplifyPolyLog::usage =
"SimplifyPolyLog[y] performs several simplifications assuming \
that the variables  occuring in the Log and PolyLog functions \
are between 0 and 1. The simplifications will in general not \
be valid if the arguments are complex or outside the range between 0 and 1.";

SPL::usage=
"SPL is an abbreviation for SimplifyPolyLog.";

SimplifyPolyLog::failmsg =
"Error! SimplifyPolyLog has encountered a fatal problem and must abort the computation. \
The problem reads: `1`"

(* ------------------------------------------------------------------------ *)

Begin["`Package`"]
End[]

Begin["`SimplifyPolyLog`Private`"]

SPL=SimplifyPolyLog;
optSqrt::usage="";

Options[SimplifyPolyLog] = {
	Nielsen -> True,
	Sqrt -> True
};

SimplifyPolyLog[expr_, OptionsPattern[]] :=
	Block[{loli, tmp, repRule={}, var},

		loli = {Log :> simplifyArgumentLog, PolyLog :> simplifyArgumentPolyLog};
		optSqrt = OptionValue[Sqrt];

		tmp = expr;

		tmp = tmp/.Zeta2->(Pi^2/6)/.loli/.simptab/.simptab/.simptab/.simptab/.simptab/.simptab/.loli/.Pi^2->6 Zeta2;

		If[	!OptionValue[Nielsen],
			tmp = tmp/. Nielsen[z__]:> Nielsen[z,PolyLog->True]
		];

		tmp = Expand2[tmp,{Log,Pi}];

		tmp = tmp /. {
			Pi^2 :> 6 Zeta2 , Pi^3 :> Pi 6 Zeta2, Pi^4 :> 90 Zeta4,
			Log[x_Integer?EvenQ] :> PowerExpand[Log[x]]
		};

		tmp

	];

(*The arguments of logs and polylogs might contain scalar products, so a naive memoization is not safe here! *)

simplifyArgument[su_, head_, {}] :=
	If[	FreeQ[su,Plus],
		head[su],
		head[Factor2[Cancel[Factor2[su]]]]
	];

simplifyArgument[su1_, su2_, head_, {}] :=
	If[	FreeQ[su2,Plus],
		head[su1,su2],
		head[su1,Factor2[Cancel[Factor2[su2]]]]
	];

simplifyArgumentLog[su_, OptionsPattern[]] :=
	FCUseCache[simplifyArgument,{su, Log}];

simplifyArgumentPolyLog[su1_,su2_] :=
	FCUseCache[simplifyArgument,{su1, su2, PolyLog}];

funex[PolyGamma[2,2]] :>
	2 - 2 Zeta[3];

funex[PolyGamma[a_,b_]] :=
	FCUseCache[polyGammaExpand,{PolyGamma[a,b]}];

polyGammaExpand[PolyGamma[a_,b_]]:=
	Expand[FunctionExpand[PolyGamma[a,b]] /. EulerGamma->0];

(*
	These relations follow from the basic properties of polylogs.
	Many of them can be found in L. Lewin's "Polylogarithms and Associated Functions"
	and "Table of Integrals and Formulae for Feynman Diagram Calculations" by Devoto and Duke.
	Furthermore, new relations can be easily derived by differentiating the given polylog
	w.r.t x and then integrating in x from 0 to t or from 1 to z (whatever converges better).
	For example

	Integrate[D[PolyLog[2, 1 - x], x], {x, 0, t},  Assumptions -> {t > 0, t < 1}]

	and so on. The correctness of the expression can be then checked via
	Plot[exp1-exp2,{x,0,1}]. This is the only way, as Mathematica will not recognize most
	of these transformations.
*)

simptab =
{
	PolyGamma[a_Integer, b_?NumberQ] :>
		funex[PolyGamma[a,b]],

	(*The duplication formula *)
	PolyLog[s_, -Sqrt[x_Symbol]]/; optSqrt :>
		2^(1-s) PolyLog[s, x] - PolyLog[s, Sqrt[x]],(*,

	PolyLog[s_, -x_Symbol] :>
		2^(1-s) PolyLog[s, x^2] - PolyLog[s, x],
	*)

	PolyLog[2, -((1 - 2*t_Symbol)/t_Symbol)] :>
		(
		-Zeta2 +
		2*Log[2]*Log[1 - 2*t] +
		2*Log[1 - 2*t]*Log[t] +
		2*Log[1 - t]*Log[t] -
		Log[t]^2 -
		2*Log[2]*Log[-1 + 2*t] -
		2*Log[1 - t]*Log[-1 + 2*t] +
		2*PolyLog[2, 1 - t] -
		2*PolyLog[2, 2*(1 - t)] +
		2*PolyLog[2, 2*t]
		)/2,

	PolyLog[2, (2*(1 - t_Symbol))/(1 - 2*t_Symbol)] :>
		(
		6*Zeta2 -
		2*Log[2]*Log[-(1 - 2*t)^(-1)] +
		2*I*Pi*Log[1 - 2*t] -
		Log[1 - 2*t]^2 -
		2*I*Pi*Log[1 - t] +
		2*Log[1 - 2*t]*Log[1 - t] -
		2*Log[-(1 - 2*t)^(-1)]*Log[(1 - t)/(1 - 2*t)]  -
		2*Log[(1 - t)/(1 - 2*t)]*Log[t] +
		2*Log[(1 - t)/(1 - 2*t)]*Log[-(t/(1 - 2*t))] -
		2*Log[2]*Log[-1 + 2*t] -
		2*Log[1 - t]*Log[-1 + 2*t] -
		2*PolyLog[2, 2*(1 - t)]
		)/ 2,

	PolyLog[2, (1 - t_Symbol)^2/(1 - 2*t_Symbol)] :>
		(
		2*I*Pi*Log[1 - 2*t] +
		4*Log[2]*Log[1 - 2*t] -
		Log[1 - 2*t]^2 -
		4*I*Pi*Log[1 - t] +
		4*Log[1 - 2*t]*Log[1 - t] +
		4*Log[1 - 2*t]*Log[t] -
		4*Log[2]*Log[-1 + 2*t] -
		4*Log[1 - t]*Log[-1 + 2*t] +
		8*PolyLog[2, 1 - t] -
		4*PolyLog[2,2*(1 - t)] +
		4*PolyLog[2, 2*t]
		)/2,

	PolyLog[2, (1 - t_Symbol)/(1 - 2*t_Symbol)] :>
		(
		3*Zeta2 +
		2*I*Pi*Log[1 - 2*t] +
		2*Log[2]*Log[1 - 2*t] -
		Log[1 - 2*t]^2 -
		2*I*Pi*Log[1 - t] +
		2*Log[1 - 2*t]*Log[1 - t] +
		2*Log[1 - 2*t]*Log[t] -
		2*Log[2]*Log[-1 + 2*t] -
		2*Log[1 - t]*Log[-1 + 2*t] +
		2*PolyLog[2, 1 - t] -
		2*PolyLog[2, 2*(1 - t)] +
		2*PolyLog[2, 2*t]
		)/2,

	Log[-(t_Symbol^2/(1 - 2*t_Symbol))] :>
		Log[t] + Log[-(t/(1 - 2*t))],

	PolyLog[2, -(t_Symbol/(1 - 2*t_Symbol))] :>
		(
		Zeta2 -
		Log[(1 - t)/(1 - 2*t)]*Log[-(t/(1 - 2*t))] -
		PolyLog[2, (1 - t)/(1 - 2*t)]
		),

	PolyLog[2, -(t_Symbol^2/(1 - 2*t_Symbol))] :>
		(
		Zeta2 -
		Log[(1 - t)^2/(1 - 2*t)]*Log[-(t^2/(1 - 2*t))] -
		PolyLog[2, (1 - t)^2/(1 - 2*t)]
		),

	PolyLog[3, (1 - t_Symbol)^2/t_Symbol^2] :>
		(
		2*Pi^2*Log[1 - t]/3 -
		4*Log[1 - t]^2*Log[-((1 - 2*t)/t)] +
		8*Log[1 - t]*Log[-((1 - 2*t)/t)]*Log[t] -
		2*Log[1 - t]*Log[t]^2 -
		4*Log[-((1 - 2*t)/t)]*Log[t]^2 +
		(2*Log[t]^3)/3 -
		4*Log[1 - t]*PolyLog[2, -((1 - 2*t)/t)] +
		4*Log[t]*PolyLog[2, -((1 - 2*t)/t)] -
		4*Log[1 - t]*PolyLog[2, (1 - t)/t] + 4*Log[t]*PolyLog[2, (1 - t)/t] -
		4*PolyLog[3, 1 - t] + 4*PolyLog[3, (1 - t)/t] - 4*PolyLog[3, t] +
		4*Zeta[3]
		),

	PolyLog[2, 2 - x_Symbol] :>
		(
		Zeta2 -
		I*Pi*Log[2 - x] -
		Log[1 - x]*Log[2 - x] -
		PolyLog[2, -1 + x]
		),

	PolyLog[2, (1 + x_Symbol)/x_Symbol] :>
		(
		2*Zeta2 +
		I*Pi*Log[x] -
		Log[x]^2/2 -
		I*Pi*Log[1 + x] +
		Log[x]*Log[1 + x] +
		PolyLog[2, -x]
		),

	PolyLog[2, (1 - x_Symbol)/2] :>
		(
		Zeta2 -
		Log[2]^2 + 2*Log[2]*Log[1 + x] + 2*Log[x]*Log[1 + x] -
		Log[1 + x]^2 + 2*PolyLog[2, 1 - x] + 2*PolyLog[2, -x] -
		2*PolyLog[2, (1 - x)/(1 + x)]
		)/2,

		PolyLog[2, (1 - Sqrt[x_Symbol])/2]/; optSqrt :>
		(
		-Log[2]^2/2 + Log[2]*Log[1 + Sqrt[x]] - Log[1 + Sqrt[x]]^2/2 +
		2*PolyLog[2, 1 - Sqrt[x]] - PolyLog[2, (1 - Sqrt[x])/(1 + Sqrt[x])] -
		PolyLog[2, 1 - x]/2
		),

	PolyLog[2, (1 - Sqrt[x_Symbol])/2]/; optSqrt :>
		(
		- PolyLog[2, (1 + Sqrt[x])/2] +
		Zeta2 -
		Log[2]^2 + Log[1 + Sqrt[x]]^2 + Log[2] Log[1 - x] -
		Log[1 + Sqrt[x]] Log[1 - x]
		),

	PolyLog[2, -(1 - x_Symbol)/(2*x_Symbol)] :>
		(
		4*Zeta2 +
		4*I*Pi*Log[2] -
		3*Log[2]^2 +
		4*Log[2]*Log[1 - x] +
		4*I*Pi*Log[x] -
		6*Log[2]*Log[x] +
		4*Log[1 - x]*Log[x] -
		3*Log[x]^2 -
		4*I*Pi*Log[1 + x] +
		2*Log[2]*Log[1 + x] -
		4*Log[1 - x]*Log[1 + x] +
		2*Log[x]*Log[1 + x] +
		Log[1 + x]^2 +
		2*PolyLog[2, (1 - x)/(1 + x)] -
		4*PolyLog[2, (1 + x)/(2*x)]
		)/2,

	PolyLog[3, -(x_^2/(1 - x_^2))] :>
		(
		7*Zeta2*Log[1 - x] +
		I*Pi*Log[1 - x]^2 +
		Log[1 - x]^3/6 -
		Log[1 - x]^2*Log[x] +
		Zeta2*Log[1 + x] -
		2*I*Pi*Log[1 - x]*Log[1 + x] +
		(Log[1 - x]^2*Log[1 + x])/2 -
		2*Log[1 - x]*Log[x]*Log[1 + x] -
		I*Pi*Log[1 + x]^2 +
		(Log[1 - x]*Log[1 + x]^2)/2 -
		Log[x]*Log[1 + x]^2 +
		Log[1 + x]^3/6 -
		4*PolyLog[3, 1 - x] -
		4*PolyLog[3, -x] -
		4*PolyLog[3, x] -
		4*PolyLog[3, 1 + x] -
		2*PolyLog[3, -((1 + x)/(1 - x))] +
		2*PolyLog[3, (1 + x)/(1 - x)] +
		(9*Zeta[3])/2
		),

	PolyLog[2, -(x_^2/(1 - x_^2))] :>
		(
		-2*Zeta2 -
		Log[1 - x]^2/2 +
		2*Log[1 - x]*Log[x] -
		Log[1 - x]*Log[1 + x] -
		Log[1 + x]^2/2 +
		2*PolyLog[2, 1 - x] -
		2*PolyLog[2, -x]
		),

	PolyLog[3, -(1 - x_Symbol)^(-1)] :>
		Log[1 - x]^3/6 + Zeta2*Log[1 - x] + PolyLog[3, -1 + x],

	PolyLog[3, (1 - x_Symbol)^2] :>
		4*PolyLog[3, 1 - x] + 4*PolyLog[3, -1 + x],

	PolyLog[2, -1 + 2*x_Symbol] :>
		Zeta2 - Log[2]*Log[-1 + 2*x] - Log[1 - x]*Log[-1 + 2*x] - PolyLog[2, 2*(1 - x)],

	PolyLog[2, (1 - 2*x_Symbol)/(1 - x_Symbol)] :>
		-Log[1 - x]^2/2 + Log[1 - x]*Log[x] - Log[x]^2/2 - PolyLog[2, -((1 - 2*x)/x)],

	PolyLog[2, (1 - 2*x_Symbol)/(2*(1 - x_Symbol))] :>
		-Log[2]^2/2 - Log[2]*Log[1 - x] - Log[1 - x]^2/2 - PolyLog[2, -1 + 2*x],

	PolyLog[2, (1 - x_Symbol)/x_Symbol] :>
		(
		Zeta2 -
		I*Pi*Log[1 - x] -
		Log[1 - 2*x]*Log[1 - x] +
		I*Pi*Log[x] +
		Log[1 - 2*x]*Log[x] +
		Log[1 - x]*Log[x] -
		Log[x]^2 -
		PolyLog[2, -((1 - 2*x)/x)]
		),

	PolyLog[2, 1/(2*(1 - x_Symbol))] :>
		(
		Zeta2 -
		Log[2]^2/2 +
		Log[2]*Log[1 - 2*x] -
		Log[2]*Log[1 - x] +
		Log[1 - 2*x]*Log[1 - x] -
		Log[1 - x]^2/2 +
		PolyLog[2, -1 + 2*x]
		),

	PolyLog[2, x_Symbol/(1 + x_Symbol)] :>
			-Pi^2/6 + I*Pi*Log[1 + x] + Log[x]*Log[1 + x] - Log[1 + x]^2/2 + PolyLog[2, 1 + x],

	PolyLog[3, x_^(-2)] :>
		(
		2*Pi^2*Log[x] -
		12*Zeta2*Log[x] -
		2*I*Pi*Log[x]^2 -
		4*Log[1 - x]*Log[x]^2 +
		(4*Log[x]^3)/3 -
		4*Log[x]*PolyLog[2, 1 - x] -
		4*Log[x]*PolyLog[2, x] +
		4*PolyLog[3, -x] +
		4*PolyLog[3, x]
		),

	PolyLog[3, (1 - x_Symbol^2)^(-1)] :>
		(
		-8*Zeta2*Log[1 - x] -
		(3*I)/2*Pi*Log[1 - x]^2 +
		Log[1 - x]^3/6 -
		2*Zeta2*Log[1 + x] +
		I*Pi*Log[1 - x]*Log[1 + x] +
		(Log[1 - x]^2*Log[1 + x])/2 +
		I/2*Pi*Log[1 + x]^2 +
		(Log[1 - x]*Log[1 + x]^2)/2 +
		Log[1 + x]^3/6 +
		4*PolyLog[3, 1 - x] +
		4*PolyLog[3, 1 + x] +
		2*PolyLog[3, -((1 + x)/(1 - x))] -
		2*PolyLog[3, (1 + x)/(1 - x)] -
		(7*Zeta[3])/2
		),

	PolyLog[3, 1 - x_Symbol^2] :>
		(
		-6*Zeta2*Log[1 - x] -
		I*Pi*Log[1 - x]^2 +
		2*I*Pi*Log[1 - x]*Log[1 + x] +
		I*Pi*Log[1 + x]^2 +
		4*PolyLog[3, 1 - x] +
		4*PolyLog[3, 1 + x] +
		2*PolyLog[3, -((1 + x)/(1 - x))] -
		2*PolyLog[3, (1 + x)/(1 - x)] -
		(7*Zeta[3])/2
		),

	PolyLog[2, 2/(1 - x_Symbol)] :>
		(
		7*Zeta2 -
		2*I*Pi*Log[2] +
		4*I*Pi*Log[1 - x] +
		2*Log[2]*Log[1 - x] -
		2*Log[1 - x]^2 -
		2*I*Pi*Log[1 + x] -
		2*Log[2]*Log[1 + x] +
		2*Log[1 - x]*Log[1 + x] -
		2*Log[x]*Log[1 + x] -
		2*PolyLog[2, 1 - x] -
		2*PolyLog[2, -x] -
		2*PolyLog[2, (1 + x)/(1 - x)]
		)/2,

	PolyLog[2, -((1 + x_Symbol)/(1 - x_Symbol))] :>
		(
		-5*Pi^2 -
		12*I*Pi*Log[1 - x] +
		12*I*Pi*Log[1 + x] +
		12*Log[x]*Log[1 + x] +
		12*PolyLog[2, 1 - x] +
		12*PolyLog[2, -x] +
		12*PolyLog[2, (1 + x)/(1 - x)]
		)/12,

	PolyLog[2, (1 + x_Symbol)/(-1 + x_Symbol)] :>
		(
		-5*Pi^2 -
		12*I*Pi*Log[1 - x] +
		12*I*Pi*Log[1 + x] +
		12*Log[x]*Log[1 + x] +
		12*PolyLog[2, 1 - x] +
		12*PolyLog[2, -x] +
		12*PolyLog[2, (1 + x)/(1 - x)]
		)/12,

	PolyLog[2, 1 + x_Symbol] :>
		Zeta2 - I*Pi*Log[1 + x] - Log[x]*Log[1 + x] - PolyLog[2, -x],

	PolyLog[2, 1 + Sqrt[x_Symbol]] /; optSqrt :>
		(
		- PolyLog[2, -Sqrt[x]] +
		Zeta2 - I Pi Log[1 + Sqrt[x]] - 1/2 Log[1 + Sqrt[x]] Log[x]
		),


	PolyLog[2,1/x_] :>
		Log[(x-1)/x] Log[x] + Pi^2/3 - PolyLog[2,x] - Log[x] Log[1-x] + 1/2 Log[x]^2,

	PolyLog[2,-1/x_] :>
		Log[(+x+1)/x] Log[-x] + Pi^2/3 - PolyLog[2,-x] - Log[-x] Log[1+x] + 1/2 Log[-x]^2,

	(* a matter of taste
	PolyLog[2, 1 - x_] -> Zeta2 - Log[1 - x] Log[x] - PolyLog[2, x], *)

	PolyLog[2, x_ /; FreeQ2[x,{Plus,Times,Power}]] :>
		Zeta2 - Log[1 - x] Log[x] - PolyLog[2, 1 - x],

	PolyLog[2, Sqrt[x_Symbol]]/; optSqrt :>
		(
		- PolyLog[2, 1 - Sqrt[x]] +
		Zeta2 + 1/2 Log[1 + Sqrt[x]] Log[x] - 1/2 Log[1 - x] Log[x]
		),

	PolyLog[2, x_^(-2)] :>
		2*Zeta2 + 2*I*Pi*Log[x] + 2*Log[1 - x]*Log[x] - Log[x]^2 + 2*PolyLog[2, 1 - x] + 2*PolyLog[2, -x^(-1)],

	PolyLog[2, (1 + x_Symbol)/(1 - x_Symbol^2)] :>
		2*Zeta2 + I*Pi*Log[1 - x] - Log[1 - x]^2/2 - PolyLog[2, 1 - x],

	PolyLog[2,1-x_^2] :>
		PolyLog[2,1-x] - PolyLog[2,x]-2 PolyLog[2,-x]- Log[x] Log[1-x] - 2 Log[x] Log[1+x],

	PolyLog[2, -((1 - x_Symbol)/(1 + x_Symbol))] :>
		(-3*Zeta2)/2 - Log[x]*(-Log[1 - x] + Log[1 + x]) - PolyLog[2, -x] + PolyLog[2, x] + PolyLog[2, (1 - x)/(1 + x)],

	PolyLog[2, ((x_Symbol -1)/(1 + x_Symbol))] :>
		(-3*Zeta2)/2 - Log[x]*(-Log[1 - x] + Log[1 + x]) - PolyLog[2, -x] + PolyLog[2, x] + PolyLog[2, (1 - x)/(1 + x)],

	PolyLog[2, (1 + x_Symbol)/2] :>
		(
		Zeta2/2 -
		Log[2]^2/2 +
		Log[2]*Log[1 - x] -
		Log[1 - x]*Log[1 + x] -
		Log[x]*Log[1 + x] +
		Log[1 + x]^2/2 -
		PolyLog[2, 1 - x] -
		PolyLog[2, -x] +
		PolyLog[2, (1 - x)/(1 + x)]
		),

	PolyLog[2, (1 + Sqrt[x_Symbol])/2]/; optSqrt :>
		(
		Zeta2 - Log[2]^2/2 - Log[2] Log[1 + Sqrt[x]] +
		3/2 Log[1 + Sqrt[x]]^2 + Log[2] Log[1 - x] -
		Log[1 + Sqrt[x]] Log[1 - x] - 2 PolyLog[2, 1 - Sqrt[x]] +
		PolyLog[2, (1 - Sqrt[x])/(1 + Sqrt[x])] + 1/2 PolyLog[2, 1 - x]
		),

	PolyLog[2, (1 + x_Symbol)/(1 - x_Symbol)] :>
		(
		2*Zeta2 +
		I*Pi*Log[1 - x] -
		Log[1 - x]^2/2 -
		I*Pi*Log[1 + x] +
		Log[1 - x]*Log[1 + x] -
		Log[1 + x]^2/2 -
		PolyLog[2, (1 - x)/(1 + x)]
		),

	PolyLog[2, (-2*x_Symbol)/(1 - x_Symbol)] :>
		(
		Zeta2 +
		I*Pi*Log[1 - x] +
		Log[2]*Log[1 - x] -
		Log[1 - x]^2 +
		Log[1 - x]*Log[x] -
		I*Pi*Log[1 + x] -
		Log[2]*Log[1 + x] +
		Log[1 - x]*Log[1 + x] -
		Log[x]*Log[1 + x] -
		PolyLog[2, (1 + x)/(1 - x)]
		),

	PolyLog[2, x_^2] :>
		Zeta2 - Log[1 - x]*Log[x] - PolyLog[2, 1 - x] + 2*PolyLog[2, -x] + PolyLog[2, x],

	PolyLog[2, (1 + x_Symbol)/(2*x_Symbol)] :>
		(
		2*Zeta2 +
		2*I*Pi*Log[2] -
		Log[2]^2 +
		2*Log[2]*Log[1 - x] +
		2*I*Pi*Log[x] -
		2*Log[2]*Log[x] +
		2*Log[1 - x]*Log[x] -
		Log[x]^2 -
		2*I*Pi*Log[1 + x] -
		2*Log[1 - x]*Log[1 + x] +
		Log[1 + x]^2 +
		2*PolyLog[2, (1 - x)/(1 + x)]
		)/2,


	PolyLog[2, x_Symbol/(1 + x_Symbol)] :>
		(-Log[1 + x]^2 - 2*PolyLog[2, -x])/2,

	PolyLog[2, 2 x_Symbol/(1 + x_Symbol)] :>
		(
		-Pi^2/12 + Log[2]^2/2 - Log[1 - x]*Log[2/(1 + x)] - Log[1 + x]^2/2 + PolyLog[2, (1 - x)/2] - PolyLog[2, -x] + PolyLog[2, x]
		),

	PolyLog[2, -x_Symbol/(1-x_Symbol)] :>
		-1/2 Log[1-x]^2 - PolyLog[2, x],

	PolyLog[2, 1 - 1/x_Symbol] :>
		-Log[x]^2/2 - PolyLog[2, 1 - x],

	PolyLog[2, (x_Symbol - 1)/x_Symbol] :>
		-Log[x]^2/2 - PolyLog[2, 1 - x],

	PolyLog[2, -(1 - x_Symbol)/x_Symbol]:>
		-Log[x]^2/2 - PolyLog[2, 1 - x],

	PolyLog[2,  x_Symbol/(x_Symbol -1)] :>
		-1/2 Log[1-x]^2 - PolyLog[2, x],

	PolyLog[3, x_Symbol] :>
		(2*Zeta2*Log[x] - Log[1 - x]*Log[x]^2 - 2*Nielsen[1, 2, 1 - x] - 2*Log[x]*PolyLog[2, 1 - x] + 2*Zeta[3])/2,

	(*
	Nielsen[1, 2, x_Symbol] :> (Log[1 - x]^2*Log[x])/2 +
		Log[1 - x]*PolyLog[2, 1 - x] - PolyLog[3, 1 - x] + Zeta[3], *)
	Nielsen[1,2, -x_/(1-x_)] :>
		-1/6 Log[1-x]^3 + Nielsen[1,2,x],

	PolyLog[2, -(x_^2/(1 - x_^2))] :>
		-2*Zeta2 - Log[1 - x]^2/2 + 2*Log[1 - x]*Log[x] - Log[1 - x]*Log[1 + x] - Log[1 + x]^2/2 + 2*PolyLog[2, 1 - x] - 2*PolyLog[2, -x],

	PolyLog[2, 1 - 2*x_Symbol] :>
		-Zeta2/2 + Log[1 - x]*Log[x] - Log[x]^2/2 + PolyLog[2, 1 - x] + PolyLog[2, -1 + 2*x] - PolyLog[2, (-1 + 2*x)/x],

	PolyLog[3, x_Symbol^(-1)] :>
		(-2*Pi^2*Log[x] - 3*I*Pi*Log[x]^2 + Log[x]^3 + 6*PolyLog[3, x])/6,

	PolyLog[3, (1 - x_Symbol)^(-1)] :>
		-2*Zeta2*Log[1 - x] - I/2*Pi*Log[1 - x]^2 + Log[1 - x]^3/6 + PolyLog[3, 1 - x],

	PolyLog[3, (1 + x_Symbol)/x_Symbol] :>
		(
		-12*Zeta2*Log[x] -
		3*I*Pi*Log[x]^2 +
		Log[x]^3 +
		18*Zeta2*Log[1 + x] +
		6*I*Pi*Log[x]*Log[1 + x] -
		3*Log[x]^2*Log[1 + x] -
		6*I*Pi*Log[1 + x]^2 -
		6*PolyLog[3, -x] -
		6*PolyLog[3, 1 + x] +
		6*Zeta[3]
		)/6,

		(* do it the other way round
		PolyLog[3, (1 + x_Symbol)^(-1)] :>
			(-9*I*Pi*Log[1 + x]^2 - 12*Log[x]*Log[1 + x]^2 + Log[1 + x]^3 -
		12*Log[1 + x]*PolyLog[2, -x] - 12*Log[1 + x]*PolyLog[2, 1 + x] +
					6*PolyLog[3, 1 + x])/6
		,*)
	PolyLog[3, 1 + x_Symbol] :>
		(
		12*Zeta2*Log[1 + x] -
		3*I*Pi*Log[1 + x]^2 -
		Log[1 + x]^3 +
		6*PolyLog[3, (1 + x)^(-1)]
		)/6,

	PolyLog[3, 1 + Sqrt[x_Symbol]]/; optSqrt :>
		(
		2*Zeta2*Log[1 + Sqrt[x]] -
		(I/2)*Pi*Log[1 + Sqrt[x]]^2 -
		Log[1 + Sqrt[x]]^3/6 +
		PolyLog[3, (1 + Sqrt[x])^(-1)]
		),

	PolyLog[3, - (x_/;FreeQ[x,Plus])^(-1)] :>
		Zeta2*Log[x] + Log[x]^3/6 + PolyLog[3, -x],
	(*
	,
	PolyLog[3,1-x_Symbol] :>
		(Log[1 - x]^2*Log[x] - 2*Nielsen[1, 2, x] +
				2*Log[1 - x]*PolyLog[2, 1 - x] + 2*Zeta[3])/2
	*)


	PolyLog[3, z_Symbol^2] :>
		(
		-4*((Log[1 - z]*Log[z]^2)/8 +
		(Log[z]^2*Log[1 + z])/8 -
		(Log[z]^2*Log[1 - z^2])/8 -
		PolyLog[3, -z] - PolyLog[3, z])
		),

	PolyLog[3, -x_Symbol/(1-x_Symbol)] :>
		-PolyLog[3, x] - PolyLog[3,1-x] + 1/6 Log[1-x]^3 - 1/2 Log[x] Log[1-x]^2 + Zeta2 Log[1-x] + Zeta[3],
(*
,
	PolyLog[3, x_/(1+x_)] :>
Nielsen[1,2,-x] + PolyLog[2,-x] Log[1-x] - PolyLog[3,-x] + 1/6 Log[1+x]^3
Li3(x/(1+x)) = S12(-x) + Li2(-x) ln(1-x) - Li3(-x) + 1/6 ln(1+x)^3
*)

	PolyLog[3,1 - 1/(x_/;FreeQ[x,Plus])] :>
		(
		Nielsen[1,2,x] -
		PolyLog[3,x] +
		Log[1-x] PolyLog[2,x] +
		1/6 Log[x]^3 +
		Zeta2 (Log[x]-Log[1-x])+
		1/2Log[x] Log[1-x] (Log[1-x] - Log[x])
		),

	PolyLog[3,-(1 - x_Symbol)/x_Symbol] :>
		(
		Nielsen[1,2,x] -
		PolyLog[3,x] +
		Log[1-x] PolyLog[2,x] +
		1/6 Log[x]^3 +
		Zeta2 (Log[x]-Log[1-x])+
		1/2Log[x] Log[1-x] (Log[1-x] - Log[x])
		),

	PolyLog[3,(x_Symbol-1)/x_Symbol] :>
		(
		Nielsen[1,2,x] -
		PolyLog[3,x] +
		Log[1-x] PolyLog[2,x] +
		1/6 Log[x]^3 +
		Zeta2 (Log[x]-Log[1-x])+
		1/2Log[x] Log[1-x] (Log[1-x] - Log[x])
		),

	PolyLog[3, (1 + x_Symbol)/(2*x_Symbol)] :>
		(
		3*I*Pi*Log[2]^2 -
		4*Log[2]^3 +
		3*Log[2]^2*Log[1 - x] +
		6*I*Pi*Log[2]*Log[x] -
		12*Log[2]^2*Log[x] +
		6*Log[2]*Log[1 - x]*Log[x] +
		3*I*Pi*Log[x]^2 -
		12*Log[2]*Log[x]^2 +
		3*Log[1 - x]*Log[x]^2 -
		4*Log[x]^3 -
		6*I*Pi*Log[2]*Log[1 + x] +
		9*Log[2]^2*Log[1 + x] -
		6*Log[2]*Log[1 - x]*Log[1 + x] -
		6*I*Pi*Log[x]*Log[1 + x] +
		18*Log[2]*Log[x]*Log[1 + x] -
		6*Log[1 - x]*Log[x]*Log[1 + x] +
		9*Log[x]^2*Log[1 + x] +
		3*I*Pi*Log[1 + x]^2 -
		6*Log[2]*Log[1 + x]^2 +
		3*Log[1 - x]*Log[1 + x]^2 -
		6*Log[x]*Log[1 + x]^2 + Log[1 + x]^3 -
		6*Log[2]*PolyLog[2, -(1 - x)/(2*x)] -
		6*Log[x]*PolyLog[2, -(1 - x)/(2*x)] +
		6*Log[1 + x]*PolyLog[2, -(1 - x)/(2*x)] -
		6*Log[2]*PolyLog[2, (1 + x)/(2*x)] -
		6*Log[x]*PolyLog[2, (1 + x)/(2*x)] +
		6*Log[1 + x]*PolyLog[2, (1 + x)/(2*x)] -
		6*PolyLog[3, -(1 - x)/(2*x)] -
		6*PolyLog[3, (1 - x)/(1 + x)] +
		6*Zeta[3]
		)/6,

	PolyLog[3, (-2*x_Symbol)/(1 - x_Symbol)] :>
		(
		-6*Zeta2*Log[2] -
		Log[2]^3 +
		6*Zeta2*Log[1 - x] +
		3*Log[2]^2*Log[1 - x] -
		3*Log[2]*Log[1 - x]^2 +
		Log[1 - x]^3 -
		6*Zeta2*Log[x] -
		3*Log[2]^2*Log[x] +
		6*Log[2]*Log[1 - x]*Log[x] -
		3*Log[1 - x]^2*Log[x] -
		3*Log[2]*Log[x]^2 + 3*Log[1 - x]*Log[x]^2 -
		Log[x]^3 +
		6*PolyLog[3, -(1 - x)/(2*x)]
		)/6,


	PolyLog[3, (-2*Sqrt[x_Symbol])/(1 - Sqrt[x_Symbol])]/; optSqrt :>
		(
		-(Zeta2*Log[2]) - Log[2]^3/6 + Zeta2*Log[1 - Sqrt[x]] + (Log[2]^2*Log[1 - Sqrt[x]])/2 - (Log[2]*Log[1 - Sqrt[x]]^2)/2 + Log[1 - Sqrt[x]]^3/6 -
		Zeta2*Log[Sqrt[x]] - (Log[2]^2*Log[Sqrt[x]])/2 + Log[2]*Log[1 - Sqrt[x]]*Log[Sqrt[x]] - (Log[1 - Sqrt[x]]^2*Log[Sqrt[x]])/2 - (Log[2]*Log[Sqrt[x]]^2)/2 +
		(Log[1 - Sqrt[x]]*Log[Sqrt[x]]^2)/2 - Log[Sqrt[x]]^3/6 + PolyLog[3, -(1 - Sqrt[x])/(2*Sqrt[x])]
		),


	PolyLog[3, -((1 + x_Symbol)/ (1 - x_Symbol))] :>
		(
		Zeta2*Log[1 - x] +
		Log[1 - x]^3/6 -
		Zeta2*Log[1 + x] -
		(Log[1 - x]^2*Log[1 + x])/2 +
		(Log[1 - x]*Log[1 + x]^ 2)/2 -
		Log[1 + x]^3/6 +
		PolyLog[3, -((1 - x)/ (1 + x))]
		),

	PolyLog[3, (1 + x_Symbol)/(1 - x_Symbol)] :>
		+I/6*(
		12*I*Zeta2*Log[1 - x] -
		3*Pi*Log[1 - x]^2 - I*Log[1 - x]^3 -
		12*I*Zeta2*Log[1 + x] +
		6*Pi*Log[1 - x]*Log[1 + x] +
		3*I*Log[1 - x]^2*Log[1 + x] -
		3*Pi*Log[1 + x]^2 -
		3*I*Log[1 - x]*Log[1 + x]^2 +
		I*Log[1 + x]^3 -
		6*I*PolyLog[3, (1 - x)/(1 + x)]
		),


	PolyLog[3, -(1 - x_Symbol)/(1 + x_Symbol)] :>
		(
		-(Zeta2*Log[2]) + Log[2]^3/3 - (Log[2]^2*Log[1 - x])/2 + Zeta2*Log[1 + x] - (Log[2]^2*Log[1 + x])/2 + Log[2]*Log[1 - x]*Log[1 + x] -
		(Log[1 - x]*Log[1 + x]^2)/2 + Log[1 + x]^3/6 - PolyLog[3, (1 - x)/2] - PolyLog[3, (1 + x)/2] + Zeta[3]
		),

	PolyLog[3, -(1 - Sqrt[x_Symbol])/(1 + Sqrt[x_Symbol])]/; optSqrt :>
		(
		-(Zeta2*Log[2]) + Log[2]^3/3 - (Log[2]^2*Log[1 - Sqrt[x]])/2 + Zeta2*Log[1 + Sqrt[x]] - (Log[2]^2*Log[1 + Sqrt[x]])/2 +
		Log[2]*Log[1 - Sqrt[x]]*Log[1 + Sqrt[x]] - (Log[1 - Sqrt[x]]*Log[1 + Sqrt[x]]^2)/2 + Log[1 + Sqrt[x]]^3/6 - PolyLog[3, (1 - Sqrt[x])/2] -
		PolyLog[3, (1 + Sqrt[x])/2] + Zeta[3]
		),

		(*XY*)
		(*
		PolyLog[3, (1 - x_Symbol)/(1 + x_Symbol)] :>
		-I/6*(12*I*Zeta2*Log[1 - x] - 3*Pi*Log[1 - x]^2 - I*Log[1 - x]^3 -
				12*I*Zeta2*Log[1 + x] + 6*Pi*Log[1 - x]*Log[1 + x] +
				3*I*Log[1 - x]^2*Log[1 + x] - 3*Pi*Log[1 + x]^2 -
				3*I*Log[1 - x]*Log[1 + x]^2 + I*Log[1 + x]^3 +
				6*I*PolyLog[3, (1 + x)/(1 - x)])
		*)

	PolyLog[2, (1 + x_Symbol)/(2*x_Symbol)] ->
		(
		Pi^2/6 +
		I*Pi*Log[2] -
		Log[2]^2/2 +
		Log[2]*Log[1 - x] +
		I*Pi*Log[x] -
		Log[2]*Log[x] +
		Log[1 - x]*Log[x] -
		Log[x]^2/2 -
		I*Pi*Log[1 + x] -
		Log[1 - x]*Log[1 + x] +
		Log[1 + x]^2/2 +
		PolyLog[2, (1 - x)/(1 + x)]
		),

	PolyLog[3, 2/(1 - x_Symbol)] :>
		(
		Pi^2*Log[2] -
		3*I*Pi*Log[2]^2 +
		Log[2]^3 -
		Pi^2*Log[1 - x] +
		6*I*Pi*Log[2]*Log[1 - x] -
		3*I*Pi*Log[1 - x]^2 -
		3*Log[2]*Log[1 - x]^2 +
		2*Log[1 - x]^3 -
		3*Log[2]^2*Log[1 + x] +
		6*Log[2]*Log[1 - x]*Log[1 + x] -
		3*Log[1 - x]^2*Log[1 + x] -
		6*PolyLog[3, (1 + x)/2] -
		6*PolyLog[3, -((1 + x)/(1 - x))] +
		6*Zeta[3]
		)/6,

	(* some weird formula ... *)

	PolyLog[3, x_Symbol/(1 + x_Symbol)] :>
		(
		3*Zeta2*Log[1 + x] -
		Log[-x]*Log[1 + x]^2 +
		Log[x]*Log[1 + x]^2 +
		Log[x]*PolyLog[2, -x] +
		Log[x]*PolyLog[2, x/(1 + x)] -
		PolyLog[3, -x] +
		PolyLog[3, (1 + x)^(-1)] -
		2*PolyLog[3, 1 + x] +
		Zeta[3]
		),

	PolyLog[3, Sqrt[x_Symbol]/(1 + Sqrt[x_Symbol])]/; optSqrt :>
		(
		-(Zeta2*Log[1 + Sqrt[x]]) +
		Log[1 + Sqrt[x]]^3/3 -
		(Log[1 + Sqrt[x]]^2*Log[Sqrt[x]])/2 -
		PolyLog[3, (1 + Sqrt[x])^(-1)] -
		PolyLog[3, -Sqrt[x]] + Zeta[3]
		),


	PolyLog[3, 2 x_Symbol/(1 + x_Symbol)] :>
		(
		2*Zeta2*Log[2] - Log[2]^3/6 + (Log[2]^2*Log[x])/2 + (Log[2]*Log[x]^2)/2 + (Log[1 - x]*Log[x]^2)/2 + Log[x]^3/6 - Zeta2*Log[1 + x] + (Log[2]^2*Log[1 + x])/2 -
		Log[2]*Log[1 - x]*Log[1 + x] - Log[2]*Log[x]*Log[1 + x] - Log[1 - x]*Log[x]*Log[1 + x] - Log[x]^2*Log[1 + x] + (Log[2]*Log[1 + x]^2)/2 +
		Log[1 - x]*Log[1 + x]^2 + (3*Log[x]*Log[1 + x]^2)/2 - (5*Log[1 + x]^3)/6 + Log[x]*PolyLog[2, (1 - x)/(1 + x)] - Log[1 + x]*PolyLog[2, (1 - x)/(1 + x)] +
		Log[x]*PolyLog[2, (2*x)/(1 + x)] - Log[1 + x]*PolyLog[2, (2*x)/(1 + x)] + PolyLog[3, (1 - x)/2] - PolyLog[3, -(1 - x)/(2*x)] + PolyLog[3, -((1 - x)/(1 + x))] -
		PolyLog[3, (1 - x)/(1 + x)] + PolyLog[3, (1 + x)/2]
		),


	PolyLog[3, 2 Sqrt[x_Symbol]/(1 + Sqrt[x_Symbol])]/; optSqrt :>
		(
		2*Zeta2*Log[2] - Log[2]^3/6 - 2*Zeta2*Log[1 + Sqrt[x]] + (Log[2]^2*Log[1 + Sqrt[x]])/2 - (Log[2]*Log[1 + Sqrt[x]]^2)/2 + Log[1 + Sqrt[x]]^3/6 +
		Zeta2*Log[Sqrt[x]] + (Log[2]^2*Log[Sqrt[x]])/2 - Log[2]*Log[1 - Sqrt[x]]*Log[Sqrt[x]] + Log[1 - Sqrt[x]]*Log[1 + Sqrt[x]]*Log[Sqrt[x]] -
		(Log[1 + Sqrt[x]]^2*Log[Sqrt[x]])/2 + (Log[2]*Log[Sqrt[x]]^2)/2 - (Log[1 - Sqrt[x]]*Log[Sqrt[x]]^2)/2 + Log[Sqrt[x]]^3/6 + PolyLog[3, (1 - Sqrt[x])/2] +
		PolyLog[3, -((1 - Sqrt[x])/(1 + Sqrt[x]))] - PolyLog[3, (1 - Sqrt[x])/(1 + Sqrt[x])] + PolyLog[3, (1 + Sqrt[x])/2] - PolyLog[3, -(1 - Sqrt[x])/(2*Sqrt[x])]
		),


	PolyLog[3, (1-Sqrt[z_Symbol])/(1 + Sqrt[z_Symbol])]/; optSqrt :>
		(
		-(Zeta2*Log[2]) + Log[2]^3/3 + 2*Zeta2*Log[1 + Sqrt[z]] - Log[2]*Log[1 + Sqrt[z]]^2 + Log[1 + Sqrt[z]]^3/3 - (Log[2]^2*Log[1 - z])/2 +
		Log[2]*Log[1 + Sqrt[z]]*Log[1 - z] - (Log[1 + Sqrt[z]]^2*Log[1 - z])/2 - PolyLog[3, (1 - Sqrt[z])/2] + 2*PolyLog[3, 1 - Sqrt[z]] +
		2*PolyLog[3, (1 + Sqrt[z])^(-1)] - PolyLog[3, (1 + Sqrt[z])/2] - PolyLog[3, 1 - z]/2 - (3*Zeta[3])/4
		),

	PolyLog[3, x_Symbol/(1 + x_Symbol)] :>
		(
		-Zeta2 Log[1 + x] - 1/2 Log[x] Log[1 + x]^2 + 1/3 Log[1 + x]^3 -
		PolyLog[3, -x] - PolyLog[3, 1/(1 + x)] + Zeta[3]
		),

	PolyLog[4, -x_/(1-x_)] :>
		(
		-Log[1 - x]^4/24 -
		Nielsen[1, 3, x] +
		Nielsen[2, 2, x] -
		(Log[1 - x]^2*PolyLog[2, x])/2 +
		Log[1 - x]*(-Nielsen[1, 2, x] + PolyLog[3, x]) -
		PolyLog[4, x]
		),

	Log[1/x_Symbol] :>
		-Log[x],

	Log[1/x_Symbol^2] :>
		- 2 Log[x],

	Log[1/(x_Symbol+1)] :>
		-Log[x+1],

	Log[Power[(x_Symbol+1),n_Integer]]/; n<0 :>
		- n Log[x+1],

	Log[Power[(x_Symbol^2+1),n_Integer]]/; n<0 :>
		- n Log[x^2+1],

	Log[x_Symbol/(x_Symbol+1)] :>
		Log[x]-Log[x+1],

	Log[1/(1-x_Symbol)] :>
		-Log[1-x],

	Log[Power[(1-x_Symbol),n_Integer]]/; n<0 :>
		- n Log[1-x],

	Log[Power[(1-x_Symbol^2),n_Integer]]/; n<0 :>
		- n Log[1-x^2],

	Log[-1/x_Symbol] :>
		-Log[x] + I Pi,

	Log[-1/(1-x_Symbol)] :>
		-Log[1-x] + I Pi,

	Log[-x_Symbol] :>
		Log[x] + I Pi,

	Log[-Sqrt[x_Symbol]]/; optSqrt :>
		1/2 Log[x] + I Pi,

	Log[(x_Symbol)^2] :>
		2 Log[x],

	Log[-x_Symbol^2] :>
		2 Log[x] + I Pi,

	Log[x_Symbol-1] :>
		Log[1-x] + I Pi,

	Log[(x_Symbol-1)/x_Symbol] :>
		Log[1-x]-Log[x]+I Pi,

	Log[-(1-x_Symbol)/x_Symbol] :>
		Log[1-x]-Log[x]+I Pi,

	Log[-1-x_Symbol] :>
		Log[1 + x] + I Pi,

	Log[1-x_Symbol^2] :>
		Log[1-x] + Log[1+x],

	Log[(1-x_Symbol) x_Symbol] :>
		Log[1-x] + Log[x],

	Log[(1-x_Symbol)/x_Symbol] :>
		Log[1-x] - Log[x],

	Log[(1-x_Symbol)/(1+x_Symbol)] :>
		Log[1-x] - Log[1+x],

	Log[(1+x_Symbol)/(1-x_Symbol)] :>
		Log[1+x] - Log[1-x],

	Log[(x_Symbol + 1)/x_Symbol] :>
		Log[x+1] - Log[x],

	Log[x_Symbol/(1-x_Symbol)] :>
		Log[x] -Log[1-x],

	Log[x_Symbol/(x_Symbol-1)] :>
		Log[x] -Log[1-x] + I Pi,

	Log[x_Symbol/(x_Symbol+1)] :>
		Log[x] -Log[1+x],

	Log[-x_Symbol/(1-x_Symbol)] :>
		Log[x] -Log[1-x] + I Pi,

	Log[r_?NumberQ x_]:>
		Log[r] + Log[x] /;r>0,

	Log[1-Sqrt[x_Symbol]]/; optSqrt :>
		Log[1-x] - Log[1+Sqrt[x]],

	Log[Sqrt[x_Symbol]]/; optSqrt :>
		1/2 Log[x],

	Pi^2 :>
		6 Zeta2,

	Pi^3 :>
		Pi 6 Zeta2,

	ArcSinh[z_] :>
		Log[z + Sqrt[z^2 + 1]],

	ArcCosh[z_] :>
		Log[z + Sqrt[z^2 - 1]],

	ArcTanh[z_] :>
		1/2 Log[(z+1)/(z-1)]
};

FCPrint[1,"SimplifyPolyLog.m loaded."];
End[]
