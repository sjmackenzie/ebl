proc{RExec Place Proc Param}
   if Place==unit then
      O={New class $
		meth init skip end
		meth get(K $)
		   case K of tk then Tk
		   [] global then Globalizer
		   end
		end
	     end init}
   in
      {Proc O Param}
   else
      {Place Exec(Proc Param)}
   end
end

fun{RReturn Place Proc Param}
   if Place==unit then
      O={New class $
		meth init skip end
		meth get(K $)
		   case K of tk then Tk
		   [] global then Globalizer
		   end
		end
	     end init}
   in
      {Proc O Param}
   else
      {Place Return(Proc Param $)}
   end
end

class ClipboardClass
   meth !Init skip end
   meth clear('at':Ob<=unit)=M
      {RExec Ob
       proc{$ E _}
	  {{E get(tk $)}.send clipboard(clear)}
       end unit}
   end
   meth append(format:F<=unit type:T<=unit Data 'at':Ob<=unit)=M
      {RExec Ob
       proc{$ E F#T#Data}
	  {{E get(tk $)}.send clipboard(append
					if F==unit then v("") else v("-format "#F) end
					if T==unit then v("") else v("-type "#T) end
					v("--") Data)}
       end F#T#Data}
   end
   meth get('at':Ob<=unit type:T<=unit Data)=M
      Data={RReturn Ob
	    fun{$ E T}
	       {TkReturn {E get(tk $)} [clipboard get if T==unit then v("") else v("-type "#T) end]}
	    end T}
   end
end

class BellClass
   meth !Init skip end
   meth ring('at':Ob<=unit)
      {RExec Ob
       proc{$ E _}
	  {{E get(tk $)}.send bell}
       end unit}
   end
end

%% fonts are a globally defined resource, but intrinsically linked to the platform specific widgets are placed on
%%    specifically, methods like names, families, measure, metrics etc are depending on a widget

% Font={NewName}

% fun{TkFont2ETkFont F}
%    {Record.adjoin
%     r(family:F.family
%       overstrike:F.overstrike==1
%       size:F.size
%       italic:F.slant=="italic"
%       bold:F.weight=="bold"
%       underline:F.underline==1) {Label F}}
% end

% class FontClass
%    meth !Init skip end
%    meth actual('at':Ob<=unit F $)
%       {TkFont2ETkFont {GuessParams actual {RReturn Ob
% 					   fun{$ GetSite F}
% 					      {TkReturn {GetSite tk} [font actual F]}
% 					   end
% 					   try {F Font($)} catch _ then F end}}}
%    end
%    meth families('at':Ob<=unit $)
%       {GuessParams families {RReturn Ob
% 			     fun{$ GetSite _}
% 				{TkReturn {GetSite tk} [font families]}
% 			     end _}}
%    end
%    meth measure('at':Ob<=unit F T $)
%       {Guess {RReturn Ob
% 	      fun{$ GetSite F#T}
% 		 {TkReturn {GetSite tk} [font measure F T]}
% 	      end try {F Font($)} catch _ then F end#T}}
%    end
%    meth metrics('at':Ob<=unit F $)
%       {GuessParams metrics {RReturn Ob
% 			    fun{$ GetSite F}
% 			       {TkReturn {GetSite tk} [font metrics F]}
% 			    end try {F Font($)} catch _ then F end}}
%    end
% end

% FontSpec=f(family:VirtualString.is
% 	   size:Int.is
% 	   bold:Bool.is
% 	   italic:Bool.is
% 	   underline:Bool.is
% 	   overstrike:Bool.is)


% class UserFontClass
%    feat
%       !Font
%    attr
%       family
%       size
%       bold
%       italic
%       underline
%       overstrike
%    meth !Init
%       family<-"Times"
%       size<-10
%       bold<-false italic<-false underline<-false overstrike<-false
%    end
%    meth set(...)=M
%       {Record.forAllInd M
%        proc{$ K V}
% 	  if {{CondSelect FontSpec K fun{$ _} false end} V} then
% 	     K<-V
% 	  else
% 	     raise error(invalidFontSet K V) end
% 	  end
%        end}
%    end
%    meth get(...)=M
%       {Record.forAllInd M
%        proc{$ K V}
% 	  V=@K
%        end}
%    end
%    meth !Font($)
%       {VirtualString.toString
%        "{"#@family#"} "#@size#
%        if @bold then " bold" else " normal" end#
%        if @italic then " italic" else " roman" end#
%        if @underline then " underline" else "" end#
%        if @overstrike then " overstrike" else "" end}
%    end
% end
   
% fun{NewFont}
%    {New UserFontClass Init}
% end

fun{RunDialog Tk Which}
   try
      fun{ToCmd M}
%	    M|{List.map {Record.toListInd Which}
%	       fun{$ K#V} v("-"#K#" "#V) end}
	 if {Atom.is Which} then
	    [M]
	 else
	    [M d(Which)]
	 end
      end
      Cmd=case {Label Which}
	  of chooseColor then {ToCmd tk_chooseColor}
	  [] chooseDirectory then {ToCmd tk_chooseDirectory}
%	     [] chooseButton then {ToCmd tk_chooseButton}
	  [] getOpenFile then {ToCmd tk_getOpenFile}
	  [] getSaveFile then {ToCmd tk_getSaveFile}
	  [] message then {ToCmd tk_messageBox}
	  end
      V={TkReturn Tk Cmd}
   in
      if V==nil then ok(unit) else
	 ok(case {Label Which}
	    of chooseColor then
	       {TkStringTo.color V}
	    [] chooseButton then
	       {TkStringTo.int V}
	    [] message then
	       {TkStringTo.atom V}
	    else V end)
      end
   catch X then
      X
   end
end
   
fun{DialogBoxes R}
   {RReturn {CondSelect R 'at' unit}
    fun{$ E R1}
       R
    in
       try
	  R={Record.adjoinAt R1 parent {E get(parent $)}}
       catch _ then R=R1 end
       case {RunDialog {E get(tk $)} R}
       of ok(X) then X
       [] L then raise L end
       end
    end {Record.subtract R 'at'}}
end
