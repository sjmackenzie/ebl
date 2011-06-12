\ifndef OPI

functor

export

   init:Init1
   manager:Manager1
   typeDef:TypeDef1
   none:None1
   atomize:Atomize1
   tkExec:TkExec1
   tkReturn:TkReturn1
   tkStringTo:TkStringTo1
   bind:Bind1
   toEventCode:ToEventCode1
   nOOP:NOOP1
   fAIL:FAIL1
   color:Color1
   colorToString:ColorToString1
   tCLTK:TCLTK1
   
prepare

\endif

   Manager={NewName}
   Init={NewName}
   TCLTK={NewName}

   fun{NOOP V} V end
   fun{FAIL V} {Value.failed V} end

   TypeDef
   local
   
      fun{ElementOf L}
	 fun{ToString L}
	    {VirtualString.toString "One of these elements:"#
	     {List.foldL L fun{$ O N} O#" "#N end ""}}
	 end
      in
	 fun{$ V}
	    {List.member V L}
	 end#{ToString L}
      end

      Color=fun{$ L}
	       case L of c(A B C) then
		  {List.all [A B C]
		   fun{$ X} {Int.is X} andthen X>=0 andthen X=<65535 end}
	       else false end
	    end#"A record c(RR GG BB) where RR,GG and BB are integers between 0 and 255"

%    Undefined=fun{$ L}
% 		false
% 	     end#"Undefined"

      FloatPoint=fun{$ L}
		    {Float.is L}
		 end#"A float"

      Boolean=fun{$ L}
		 L==true orelse L==false
	      end#"true or false"

      Integer=fun{$ L}
		 {Int.is L}
	      end#"An integer"

      PosInteger=fun{$ L}
		    {Int.is L} andthen L>=0
		 end#"A positive integer"

      VString=fun{$ L} {VirtualString.is L} end#"A virtual string"

      Pixel=fun{$ L}
	       case L
	       of F#c then {Float.is F}
	       [] F#i then {Float.is F}
	       [] F#m then {Float.is F}
	       [] I#p then {Int.is I}
	       [] I then {Int.is I}
	       end
	    end#"A pixel value: <Integer>, <Float>#c, <Float>#i, <Float>#m, <Integer>#p"

      FontType=fun{$ L}
		  ({Object.is L} andthen {CondSelect L widgetName unit}==font) orelse
		  {VirtualString.is L}
	       end#"A font object or a virtual string"

      NoneListInt=fun{$ L}
		     case L of q(...) then
			{Record.all L Int.is}
		     [] !None then true
		     else false end
		  end#"A record q(I1 ... Ix) where In are integers"

      Image=fun{$ L}
	       L==None orelse
	       ({Object.is L} andthen {CondSelect L widgetName unit}==image)
	    end#"An image or None"
      Menu=fun{$ L}
	      L==None orelse
	      ({Object.is L} andthen {CondSelect L widgetName unit}==menu)
	   end#"A menu or None"
      Bitmap=fun{$ L} L==None orelse
		({Object.is L} andthen {CondSelect L widgetName unit}==bitmap)
	     end#"A bitmap or None"
      OzAtom=fun{$ L} {Atom.is L} end#"An atom"
   in

      TypeDef=t(elementOf:ElementOf
		color:Color
		floatPoint:FloatPoint
		boolean:Boolean
		integer:Integer
		posInteger:PosInteger
		vString:VString
		pixel:Pixel
		fontType:FontType
		noneListInt:NoneListInt
		image:Image
		menu:Menu
		bitmap:Bitmap
		ozAtom:OzAtom)

   end
   
   None=''

   fun{Atomize E}
      try
	 {VirtualString.toAtom E}
      catch _ then E end
   end

   proc{TkExec Tk Cmd}
      if {Tk.returnInt 'catch'(v("{") b(Cmd) v("}"))}==1 then
	 raise error(failed Cmd) end
      end
   end

   fun{TkReturn Tk Cmd}
      case {Tk.return set(v("e [set v \"\"; catch {set v [")
			  b(Cmd)
			  v(']}];set e "$e $v"'))}
      of 49|32|_ then
	 raise error(failed Cmd) end unit
      [] 48|32|R then R
      end
   end

   TkStringTo

   local

%   Stok  = String.token
      Stoks = String.tokens
      S2F   = String.toFloat
      S2I   = String.toInt
      SIF   = String.isFloat
      SII   = String.isInt

%   V2S   = VirtualString.toString
   
      %%
      %% Some Character/String stuff
      %%
      fun {TkNum Is BI ?BO}
	 case Is of nil then BO=BI nil
	 [] I|Ir then
	    case I
	    of &- then &~|{TkNum Ir BI BO}
	    [] &. then &.|{TkNum Ir true BO}
	    [] &e then &e|{TkNum Ir true BO}
	    [] &E then &E|{TkNum Ir true BO}
	    else I|{TkNum Ir BI BO}
	    end
	 end
      end

      fun {TkStringToString S}
	 S
      end

      TkStringToAtom = StringToAtom

      fun {TkStringToInt S}
	 %% Read a number and convert it to an integer
	 OS IsAFloat in OS={TkNum S false ?IsAFloat}
	 if IsAFloat andthen {SIF OS} then
	    {FloatToInt {S2F OS}}
	 elseif {Not IsAFloat} andthen {SII OS} then
	    {S2I OS}
	 else false
	 end
      end

      fun {TkStringToFloat S}
	 %% Read a number and convert it to a float
	 OS IsAFloat in OS={TkNum S false ?IsAFloat}
	 if IsAFloat andthen {SIF OS} then
	    {S2F OS}
	 elseif {Not IsAFloat} andthen {SII OS} then
	    {IntToFloat {S2I OS}}
	 else false
	 end
      end

      fun {TkStringToListString S}
	 {Stoks S & }
      end

      fun {TkStringToListAtom S}
	 {Map {Stoks S & } TkStringToAtom}
      end

      fun {TkStringToListInt S}
	 {Map {Stoks S & } TkStringToInt}
      end

      fun {TkStringToListFloat S}
	 {Map {Stoks S & } TkStringToFloat}
      end

      fun{Str2Color Str}
	 if Str.1==&# then
	    L=({Length Str.2} div 3)
	    R G B C1
	    {List.takeDrop Str.2 L R C1}
	    {List.takeDrop C1 L G B}
	    fun{Loop V I}
	       if V>0 then
		  {Loop V-1 I*256}
	       else I end
	    end
	    Mult={Loop (L-4) 1}
	    fun{HConv O CC}
	       fun{ToDec C}
		  if C>=&a andthen C=<&f then
		     C-&a+10
		  elseif C>=&A andthen C=<&F then
		     C-&A+10
		  else
		     C-&0
		  end
	       end
	    in
	       case CC of X|Xs then
		  {HConv O*16+{ToDec X} Xs}
	       else O end
	    end
	    fun{Conv CC}
	       {HConv 0 CC}*Mult
	    end
	 in
	    c({Conv R} {Conv G} {Conv B})
	 else {String.toAtom Str}
	 end
      end

      fun{String2Geometry S}
	 fun {SplitGeometry Str}
      %
      % This function splits a string of integers separated by control characters
      % into an Oz list of the integers. ( e.g "100x200+10+40" into [100 200 10 40])
      %
	    R
	    fun{Loop Str}
	       case Str of X|Xs then
		  if X>=48 andthen X=<57 then
		     X|{Loop Xs}
		  else
		     R=Xs
		     nil
		  end
	       else
		  R=nil
		  nil
	       end
	    end
	 in
	    if Str==nil then nil else
	       {String.toInt {Loop Str}}|{SplitGeometry R}
	    end
	 end
	 L
      in
	 L={SplitGeometry S}
	 geometry(width:L.1
		  height:L.2.1
		  x:L.2.2.1
		  y:L.2.2.2.1)
      
      end
      fun{Guess A}
	 if {String.isInt A} then {String.toInt A}
	 elseif {String.isFloat A} then {String.toFloat A}
	 elseif A=="true" then true
	 elseif A=="false" then false
	 else
	    A
	 end
      end

      fun{GuessParams R A}
	 fun{Split R}
	    fun{Grab2 L R}
	       case L
	       of &}|Ls then
		  R={List.dropWhile Ls fun{$ C} C==&  end}
		  nil
	       [] X|Xs then
		  X|{Grab2 Xs R}
	       [] nil then
		  R=nil nil
	       end
	    end
	    fun{Grab L R}
	       case L
	       of & |Ls then
		  R=Ls nil
	       [] &{|Ls then
		  {Grab2 Ls R}
	       [] X|Xs then
		  X|{Grab Xs R}
	       [] nil then
		  R=nil nil
	       end
	    end
	 in
	    if R==nil then nil else
	       B
	    in
	       {Grab R B}|{Split B}
	    end
	 end
	 fun{Loop L I}
	    case L
	    of A|B|Ls then
	       case A of &-|As then
		  {String.toAtom As}#{Guess B}|{Loop Ls I}
	       else
		  I#{Guess A}|{Loop B|Ls I+1}
	       end
	    [] A|nil then
	       I#{Guess A}|nil
	    [] nil then nil
	    end
	 end
	 L={Split A}
      in
	 {List.toRecord R {Loop L 1}}
      end

   in
      TkStringTo=t(string:TkStringToString
		   atom:TkStringToAtom
		   int:TkStringToInt
		   float:TkStringToFloat
		   listString:TkStringToListString
		   listAtom:TkStringToListAtom
		   listFloat:TkStringToListFloat
		   listInt:TkStringToListInt
		   color:Str2Color
		   geometry:String2Geometry
		   guess:Guess
		   guessParams:GuessParams)
   end


   fun{Bind Tk What Sub Event Args Proc}
      Id={Tk.getId}
      Unbind={Tk.defineUserCmd Id Proc Args}
      BindCmd=if Sub==unit then
		 o(v("{bind") What)
	      else
		 o(v("{") What "bind" Sub)
	      end
   in
      if {Tk.returnInt 'catch'(BindCmd Event v("{"#Id#" "#{GetFields Args}#";}}"))}==1 then
	 raise errorBind(What Event Args Proc) end
      end
      proc{$}
	 {Tk.send 'catch'(BindCmd Event v("\"\"}"))}
	 {Unbind}
      end
   end

   fun{ToEventCode E M1 M2 D}
      M3 M4
   in
      M3#M4=if M1==unit then M2#M1
	    elseif M2==unit then M1#M2
	    elseif {VirtualString.toAtom M1}<{VirtualString.toAtom M2} then M1#M2 else M2#M1 end
      {VirtualString.toAtom "<"#if M3\=unit then M3#"-" else "" end#if M4\=unit then M4#"-" else "" end#E#if D\=unit then "-"#D else "" end#">"}
   end

   fun {GetFields Ts}
      case Ts of nil then ''
      [] T|Tr then
	 ' %' # case T
		of list(T) then
		   case T
		   of atom(A)   then A
		   [] int(I)    then I
		   [] float(F)  then F
		   [] string(S) then S
		   else T
		   end
		[] string(S) then S
		[] atom(A)   then A
		[] int(I)    then I
		[] float(F)  then F
		else T
		end # {GetFields Tr}
      end
   end

   Color=c('alice blue':c(61680 63736 65535) % 240 248 255
	   'AliceBlue':c(61680 63736 65535) % 240 248 255
	   'antique white':c(64250 60395 55255) % 250 235 215
	   'AntiqueWhite':c(64250 60395 55255) % 250 235 215
	   'AntiqueWhite1':c(65535 61423 56283) % 255 239 219
	   'AntiqueWhite2':c(61166 57311 52428) % 238 223 204
	   'AntiqueWhite3':c(52685 49344 45232) % 205 192 176
	   'AntiqueWhite4':c(35723 33667 30840) % 139 131 120
	   aquamarine:c(32639 65535 54484) % 127 255 212
	   aquamarine1:c(32639 65535 54484) % 127 255 212
	   aquamarine2:c(30326 61166 50886) % 118 238 198
	   aquamarine3:c(26214 52685 43690) % 102 205 170
	   aquamarine4:c(17733 35723 29812) % 69 139 116
	   azure:c(61680 65535 65535) % 240 255 255
	   azure1:c(61680 65535 65535) % 240 255 255
	   azure2:c(57568 61166 61166) % 224 238 238
	   azure3:c(49601 52685 52685) % 193 205 205
	   azure4:c(33667 35723 35723) % 131 139 139
	   beige:c(62965 62965 56540) % 245 245 220
	   bisque:c(65535 58596 50372) % 255 228 196
	   bisque1:c(65535 58596 50372) % 255 228 196
	   bisque2:c(61166 54741 47031) % 238 213 183
	   bisque3:c(52685 47031 40606) % 205 183 158
	   bisque4:c(35723 32125 27499) % 139 125 107
	   black:c(0 0 0) % 0 0 0
	   'blanched almond':c(65535 60395 52685) % 255 235 205
	   'BlanchedAlmond':c(65535 60395 52685) % 255 235 205
	   blue:c(0 0 65535) % 0 0 255
	   'blue violet':c(35466 11051 58082) % 138 43 226
	   blue1:c(0 0 65535) % 0 0 255
	   blue2:c(0 0 61166) % 0 0 238
	   blue3:c(0 0 52685) % 0 0 205
	   blue4:c(0 0 35723) % 0 0 139
	   'BlueViolet':c(35466 11051 58082) % 138 43 226
	   brown:c(42405 10794 10794) % 165 42 42
	   brown1:c(65535 16448 16448) % 255 64 64
	   brown2:c(61166 15163 15163) % 238 59 59
	   brown3:c(52685 13107 13107) % 205 51 51
	   brown4:c(35723 8995 8995) % 139 35 35
	   burlywood:c(57054 47288 34695) % 222 184 135
	   burlywood1:c(65535 54227 39835) % 255 211 155
	   burlywood2:c(61166 50629 37265) % 238 197 145
	   burlywood3:c(52685 43690 32125) % 205 170 125
	   burlywood4:c(35723 29555 21845) % 139 115 85
	   'cadet blue':c(24415 40606 41120) % 95 158 160
	   'CadetBlue':c(24415 40606 41120) % 95 158 160
	   'CadetBlue1':c(39064 62965 65535) % 152 245 255
	   'CadetBlue2':c(36494 58853 61166) % 142 229 238
	   'CadetBlue3':c(31354 50629 52685) % 122 197 205
	   'CadetBlue4':c(21331 34438 35723) % 83 134 139
	   chartreuse:c(32639 65535 0) % 127 255 0
	   chartreuse1:c(32639 65535 0) % 127 255 0
	   chartreuse2:c(30326 61166 0) % 118 238 0
	   chartreuse3:c(26214 52685 0) % 102 205 0
	   chartreuse4:c(17733 35723 0) % 69 139 0
	   chocolate:c(53970 26985 7710) % 210 105 30
	   chocolate1:c(65535 32639 9252) % 255 127 36
	   chocolate2:c(61166 30326 8481) % 238 118 33
	   chocolate3:c(52685 26214 7453) % 205 102 29
	   chocolate4:c(35723 17733 4883) % 139 69 19
	   coral:c(65535 32639 20560) % 255 127 80
	   coral1:c(65535 29298 22102) % 255 114 86
	   coral2:c(61166 27242 20560) % 238 106 80
	   coral3:c(52685 23387 17733) % 205 91 69
	   coral4:c(35723 15934 12079) % 139 62 47
	   'cornflower blue':c(25700 38293 60909) % 100 149 237
	   'CornflowerBlue':c(25700 38293 60909) % 100 149 237
	   cornsilk:c(65535 63736 56540) % 255 248 220
	   cornsilk1:c(65535 63736 56540) % 255 248 220
	   cornsilk2:c(61166 59624 52685) % 238 232 205
	   cornsilk3:c(52685 51400 45489) % 205 200 177
	   cornsilk4:c(35723 34952 30840) % 139 136 120
	   cyan:c(0 65535 65535) % 0 255 255
	   cyan1:c(0 65535 65535) % 0 255 255
	   cyan2:c(0 61166 61166) % 0 238 238
	   cyan3:c(0 52685 52685) % 0 205 205
	   cyan4:c(0 35723 35723) % 0 139 139
	   'dark blue':c(0 0 35723) % 0 0 139
	   'dark cyan':c(0 35723 35723) % 0 139 139
	   'dark goldenrod':c(47288 34438 2827) % 184 134 11
	   'dark gray':c(43433 43433 43433) % 169 169 169
	   'dark green':c(0 25700 0) % 0 100 0
	   'dark grey':c(43433 43433 43433) % 169 169 169
	   'dark khaki':c(48573 47031 27499) % 189 183 107
	   'dark magenta':c(35723 0 35723) % 139 0 139
	   'dark olive green':c(21845 27499 12079) % 85 107 47
	   'dark orange':c(65535 35980 0) % 255 140 0
	   'dark orchid':c(39321 12850 52428) % 153 50 204
	   'dark red':c(35723 0 0) % 139 0 0
	   'dark salmon':c(59881 38550 31354) % 233 150 122
	   'dark sea green':c(36751 48316 36751) % 143 188 143
	   'dark slate blue':c(18504 15677 35723) % 72 61 139
	   'dark slate gray':c(12079 20303 20303) % 47 79 79
	   'dark slate grey':c(12079 20303 20303) % 47 79 79
	   'dark turquoise':c(0 52942 53713) % 0 206 209
	   'dark violet':c(38036 0 54227) % 148 0 211
	   'DarkBlue':c(0 0 35723) % 0 0 139
	   'DarkCyan':c(0 35723 35723) % 0 139 139
	   'DarkGoldenrod':c(47288 34438 2827) % 184 134 11
	   'DarkGoldenrod1':c(65535 47545 3855) % 255 185 15
	   'DarkGoldenrod2':c(61166 44461 3598) % 238 173 14
	   'DarkGoldenrod3':c(52685 38293 3084) % 205 149 12
	   'DarkGoldenrod4':c(35723 25957 2056) % 139 101 8
	   'DarkGray':c(43433 43433 43433) % 169 169 169
	   'DarkGreen':c(0 25700 0) % 0 100 0
	   'DarkGrey':c(43433 43433 43433) % 169 169 169
	   'DarkKhaki':c(48573 47031 27499) % 189 183 107
	   'DarkMagenta':c(35723 0 35723) % 139 0 139
	   'DarkOliveGreen':c(21845 27499 12079) % 85 107 47
	   'DarkOliveGreen1':c(51914 65535 28784) % 202 255 112
	   'DarkOliveGreen2':c(48316 61166 26728) % 188 238 104
	   'DarkOliveGreen3':c(41634 52685 23130) % 162 205 90
	   'DarkOliveGreen4':c(28270 35723 15677) % 110 139 61
	   'DarkOrange':c(65535 35980 0) % 255 140 0
	   'DarkOrange1':c(65535 32639 0) % 255 127 0
	   'DarkOrange2':c(61166 30326 0) % 238 118 0
	   'DarkOrange3':c(52685 26214 0) % 205 102 0
	   'DarkOrange4':c(35723 17733 0) % 139 69 0
	   'DarkOrchid':c(39321 12850 52428) % 153 50 204
	   'DarkOrchid1':c(49087 15934 65535) % 191 62 255
	   'DarkOrchid2':c(45746 14906 61166) % 178 58 238
	   'DarkOrchid3':c(39578 12850 52685) % 154 50 205
	   'DarkOrchid4':c(26728 8738 35723) % 104 34 139
	   'DarkRed':c(35723 0 0) % 139 0 0
	   'DarkSalmon':c(59881 38550 31354) % 233 150 122
	   'DarkSeaGreen':c(36751 48316 36751) % 143 188 143
	   'DarkSeaGreen1':c(49601 65535 49601) % 193 255 193
	   'DarkSeaGreen2':c(46260 61166 46260) % 180 238 180
	   'DarkSeaGreen3':c(39835 52685 39835) % 155 205 155
	   'DarkSeaGreen4':c(26985 35723 26985) % 105 139 105
	   'DarkSlateBlue':c(18504 15677 35723) % 72 61 139
	   'DarkSlateGray':c(12079 20303 20303) % 47 79 79
	   'DarkSlateGray1':c(38807 65535 65535) % 151 255 255
	   'DarkSlateGray2':c(36237 61166 61166) % 141 238 238
	   'DarkSlateGray3':c(31097 52685 52685) % 121 205 205
	   'DarkSlateGray4':c(21074 35723 35723) % 82 139 139
	   'DarkSlateGrey':c(12079 20303 20303) % 47 79 79
	   'DarkTurquoise':c(0 52942 53713) % 0 206 209
	   'DarkViolet':c(38036 0 54227) % 148 0 211
	   'deep pink':c(65535 5140 37779) % 255 20 147
	   'deep sky blue':c(0 49087 65535) % 0 191 255
	   'DeepPink':c(65535 5140 37779) % 255 20 147
	   'DeepPink1':c(65535 5140 37779) % 255 20 147
	   'DeepPink2':c(61166 4626 35209) % 238 18 137
	   'DeepPink3':c(52685 4112 30326) % 205 16 118
	   'DeepPink4':c(35723 2570 20560) % 139 10 80
	   'DeepSkyBlue':c(0 49087 65535) % 0 191 255
	   'DeepSkyBlue1':c(0 49087 65535) % 0 191 255
	   'DeepSkyBlue2':c(0 45746 61166) % 0 178 238
	   'DeepSkyBlue3':c(0 39578 52685) % 0 154 205
	   'DeepSkyBlue4':c(0 26728 35723) % 0 104 139
	   'dim gray':c(26985 26985 26985) % 105 105 105
	   'dim grey':c(26985 26985 26985) % 105 105 105
	   'DimGray':c(26985 26985 26985) % 105 105 105
	   'DimGrey':c(26985 26985 26985) % 105 105 105
	   'dodger blue':c(7710 37008 65535) % 30 144 255
	   'DodgerBlue':c(7710 37008 65535) % 30 144 255
	   'DodgerBlue1':c(7710 37008 65535) % 30 144 255
	   'DodgerBlue2':c(7196 34438 61166) % 28 134 238
	   'DodgerBlue3':c(6168 29812 52685) % 24 116 205
	   'DodgerBlue4':c(4112 20046 35723) % 16 78 139
	   firebrick:c(45746 8738 8738) % 178 34 34
	   firebrick1:c(65535 12336 12336) % 255 48 48
	   firebrick2:c(61166 11308 11308) % 238 44 44
	   firebrick3:c(52685 9766 9766) % 205 38 38
	   firebrick4:c(35723 6682 6682) % 139 26 26
	   'floral white':c(65535 64250 61680) % 255 250 240
	   'FloralWhite':c(65535 64250 61680) % 255 250 240
	   'forest green':c(8738 35723 8738) % 34 139 34
	   'ForestGreen':c(8738 35723 8738) % 34 139 34
	   gainsboro:c(56540 56540 56540) % 220 220 220
	   'ghost white':c(63736 63736 65535) % 248 248 255
	   'GhostWhite':c(63736 63736 65535) % 248 248 255
	   gold:c(65535 55255 0) % 255 215 0
	   gold1:c(65535 55255 0) % 255 215 0
	   gold2:c(61166 51657 0) % 238 201 0
	   gold3:c(52685 44461 0) % 205 173 0
	   gold4:c(35723 30069 0) % 139 117 0
	   goldenrod:c(56026 42405 8224) % 218 165 32
	   goldenrod1:c(65535 49601 9509) % 255 193 37
	   goldenrod2:c(61166 46260 8738) % 238 180 34
	   goldenrod3:c(52685 39835 7453) % 205 155 29
	   goldenrod4:c(35723 26985 5140) % 139 105 20
	   gray:c(48830 48830 48830) % 190 190 190
	   gray0:c(0 0 0) % 0 0 0
	   gray1:c(771 771 771) % 3 3 3
	   gray2:c(1285 1285 1285) % 5 5 5
	   gray3:c(2056 2056 2056) % 8 8 8
	   gray4:c(2570 2570 2570) % 10 10 10
	   gray5:c(3341 3341 3341) % 13 13 13
	   gray6:c(3855 3855 3855) % 15 15 15
	   gray7:c(4626 4626 4626) % 18 18 18
	   gray8:c(5140 5140 5140) % 20 20 20
	   gray9:c(5911 5911 5911) % 23 23 23
	   gray10:c(6682 6682 6682) % 26 26 26
	   gray11:c(7196 7196 7196) % 28 28 28
	   gray12:c(7967 7967 7967) % 31 31 31
	   gray13:c(8481 8481 8481) % 33 33 33
	   gray14:c(9252 9252 9252) % 36 36 36
	   gray15:c(9766 9766 9766) % 38 38 38
	   gray16:c(10537 10537 10537) % 41 41 41
	   gray17:c(11051 11051 11051) % 43 43 43
	   gray18:c(11822 11822 11822) % 46 46 46
	   gray19:c(12336 12336 12336) % 48 48 48
	   gray20:c(13107 13107 13107) % 51 51 51
	   gray21:c(13878 13878 13878) % 54 54 54
	   gray22:c(14392 14392 14392) % 56 56 56
	   gray23:c(15163 15163 15163) % 59 59 59
	   gray24:c(15677 15677 15677) % 61 61 61
	   gray25:c(16448 16448 16448) % 64 64 64
	   gray26:c(16962 16962 16962) % 66 66 66
	   gray27:c(17733 17733 17733) % 69 69 69
	   gray28:c(18247 18247 18247) % 71 71 71
	   gray29:c(19018 19018 19018) % 74 74 74
	   gray30:c(19789 19789 19789) % 77 77 77
	   gray31:c(20303 20303 20303) % 79 79 79
	   gray32:c(21074 21074 21074) % 82 82 82
	   gray33:c(21588 21588 21588) % 84 84 84
	   gray34:c(22359 22359 22359) % 87 87 87
	   gray35:c(22873 22873 22873) % 89 89 89
	   gray36:c(23644 23644 23644) % 92 92 92
	   gray37:c(24158 24158 24158) % 94 94 94
	   gray38:c(24929 24929 24929) % 97 97 97
	   gray39:c(25443 25443 25443) % 99 99 99
	   gray40:c(26214 26214 26214) % 102 102 102
	   gray41:c(26985 26985 26985) % 105 105 105
	   gray42:c(27499 27499 27499) % 107 107 107
	   gray43:c(28270 28270 28270) % 110 110 110
	   gray44:c(28784 28784 28784) % 112 112 112
	   gray45:c(29555 29555 29555) % 115 115 115
	   gray46:c(30069 30069 30069) % 117 117 117
	   gray47:c(30840 30840 30840) % 120 120 120
	   gray48:c(31354 31354 31354) % 122 122 122
	   gray49:c(32125 32125 32125) % 125 125 125
	   gray50:c(32639 32639 32639) % 127 127 127
	   gray51:c(33410 33410 33410) % 130 130 130
	   gray52:c(34181 34181 34181) % 133 133 133
	   gray53:c(34695 34695 34695) % 135 135 135
	   gray54:c(35466 35466 35466) % 138 138 138
	   gray55:c(35980 35980 35980) % 140 140 140
	   gray56:c(36751 36751 36751) % 143 143 143
	   gray57:c(37265 37265 37265) % 145 145 145
	   gray58:c(38036 38036 38036) % 148 148 148
	   gray59:c(38550 38550 38550) % 150 150 150
	   gray60:c(39321 39321 39321) % 153 153 153
	   gray61:c(40092 40092 40092) % 156 156 156
	   gray62:c(40606 40606 40606) % 158 158 158
	   gray63:c(41377 41377 41377) % 161 161 161
	   gray64:c(41891 41891 41891) % 163 163 163
	   gray65:c(42662 42662 42662) % 166 166 166
	   gray66:c(43176 43176 43176) % 168 168 168
	   gray67:c(43947 43947 43947) % 171 171 171
	   gray68:c(44461 44461 44461) % 173 173 173
	   gray69:c(45232 45232 45232) % 176 176 176
	   gray70:c(46003 46003 46003) % 179 179 179
	   gray71:c(46517 46517 46517) % 181 181 181
	   gray72:c(47288 47288 47288) % 184 184 184
	   gray73:c(47802 47802 47802) % 186 186 186
	   gray74:c(48573 48573 48573) % 189 189 189
	   gray75:c(49087 49087 49087) % 191 191 191
	   gray76:c(49858 49858 49858) % 194 194 194
	   gray77:c(50372 50372 50372) % 196 196 196
	   gray78:c(51143 51143 51143) % 199 199 199
	   gray79:c(51657 51657 51657) % 201 201 201
	   gray80:c(52428 52428 52428) % 204 204 204
	   gray81:c(53199 53199 53199) % 207 207 207
	   gray82:c(53713 53713 53713) % 209 209 209
	   gray83:c(54484 54484 54484) % 212 212 212
	   gray84:c(54998 54998 54998) % 214 214 214
	   gray85:c(55769 55769 55769) % 217 217 217
	   gray86:c(56283 56283 56283) % 219 219 219
	   gray87:c(57054 57054 57054) % 222 222 222
	   gray88:c(57568 57568 57568) % 224 224 224
	   gray89:c(58339 58339 58339) % 227 227 227
	   gray90:c(58853 58853 58853) % 229 229 229
	   gray91:c(59624 59624 59624) % 232 232 232
	   gray92:c(60395 60395 60395) % 235 235 235
	   gray93:c(60909 60909 60909) % 237 237 237
	   gray94:c(61680 61680 61680) % 240 240 240
	   gray95:c(62194 62194 62194) % 242 242 242
	   gray96:c(62965 62965 62965) % 245 245 245
	   gray97:c(63479 63479 63479) % 247 247 247
	   gray98:c(64250 64250 64250) % 250 250 250
	   gray99:c(64764 64764 64764) % 252 252 252
	   gray100:c(65535 65535 65535) % 255 255 255
	   green:c(0 65535 0) % 0 255 0
	   'green yellow':c(44461 65535 12079) % 173 255 47
	   green1:c(0 65535 0) % 0 255 0
	   green2:c(0 61166 0) % 0 238 0
	   green3:c(0 52685 0) % 0 205 0
	   green4:c(0 35723 0) % 0 139 0
	   'GreenYellow':c(44461 65535 12079) % 173 255 47
	   grey:c(48830 48830 48830) % 190 190 190
	   grey0:c(0 0 0) % 0 0 0
	   grey1:c(771 771 771) % 3 3 3
	   grey2:c(1285 1285 1285) % 5 5 5
	   grey3:c(2056 2056 2056) % 8 8 8
	   grey4:c(2570 2570 2570) % 10 10 10
	   grey5:c(3341 3341 3341) % 13 13 13
	   grey6:c(3855 3855 3855) % 15 15 15
	   grey7:c(4626 4626 4626) % 18 18 18
	   grey8:c(5140 5140 5140) % 20 20 20
	   grey9:c(5911 5911 5911) % 23 23 23
	   grey10:c(6682 6682 6682) % 26 26 26
	   grey11:c(7196 7196 7196) % 28 28 28
	   grey12:c(7967 7967 7967) % 31 31 31
	   grey13:c(8481 8481 8481) % 33 33 33
	   grey14:c(9252 9252 9252) % 36 36 36
	   grey15:c(9766 9766 9766) % 38 38 38
	   grey16:c(10537 10537 10537) % 41 41 41
	   grey17:c(11051 11051 11051) % 43 43 43
	   grey18:c(11822 11822 11822) % 46 46 46
	   grey19:c(12336 12336 12336) % 48 48 48
	   grey20:c(13107 13107 13107) % 51 51 51
	   grey21:c(13878 13878 13878) % 54 54 54
	   grey22:c(14392 14392 14392) % 56 56 56
	   grey23:c(15163 15163 15163) % 59 59 59
	   grey24:c(15677 15677 15677) % 61 61 61
	   grey25:c(16448 16448 16448) % 64 64 64
	   grey26:c(16962 16962 16962) % 66 66 66
	   grey27:c(17733 17733 17733) % 69 69 69
	   grey28:c(18247 18247 18247) % 71 71 71
	   grey29:c(19018 19018 19018) % 74 74 74
	   grey30:c(19789 19789 19789) % 77 77 77
	   grey31:c(20303 20303 20303) % 79 79 79
	   grey32:c(21074 21074 21074) % 82 82 82
	   grey33:c(21588 21588 21588) % 84 84 84
	   grey34:c(22359 22359 22359) % 87 87 87
	   grey35:c(22873 22873 22873) % 89 89 89
	   grey36:c(23644 23644 23644) % 92 92 92
	   grey37:c(24158 24158 24158) % 94 94 94
	   grey38:c(24929 24929 24929) % 97 97 97
	   grey39:c(25443 25443 25443) % 99 99 99
	   grey40:c(26214 26214 26214) % 102 102 102
	   grey41:c(26985 26985 26985) % 105 105 105
	   grey42:c(27499 27499 27499) % 107 107 107
	   grey43:c(28270 28270 28270) % 110 110 110
	   grey44:c(28784 28784 28784) % 112 112 112
	   grey45:c(29555 29555 29555) % 115 115 115
	   grey46:c(30069 30069 30069) % 117 117 117
	   grey47:c(30840 30840 30840) % 120 120 120
	   grey48:c(31354 31354 31354) % 122 122 122
	   grey49:c(32125 32125 32125) % 125 125 125
	   grey50:c(32639 32639 32639) % 127 127 127
	   grey51:c(33410 33410 33410) % 130 130 130
	   grey52:c(34181 34181 34181) % 133 133 133
	   grey53:c(34695 34695 34695) % 135 135 135
	   grey54:c(35466 35466 35466) % 138 138 138
	   grey55:c(35980 35980 35980) % 140 140 140
	   grey56:c(36751 36751 36751) % 143 143 143
	   grey57:c(37265 37265 37265) % 145 145 145
	   grey58:c(38036 38036 38036) % 148 148 148
	   grey59:c(38550 38550 38550) % 150 150 150
	   grey60:c(39321 39321 39321) % 153 153 153
	   grey61:c(40092 40092 40092) % 156 156 156
	   grey62:c(40606 40606 40606) % 158 158 158
	   grey63:c(41377 41377 41377) % 161 161 161
	   grey64:c(41891 41891 41891) % 163 163 163
	   grey65:c(42662 42662 42662) % 166 166 166
	   grey66:c(43176 43176 43176) % 168 168 168
	   grey67:c(43947 43947 43947) % 171 171 171
	   grey68:c(44461 44461 44461) % 173 173 173
	   grey69:c(45232 45232 45232) % 176 176 176
	   grey70:c(46003 46003 46003) % 179 179 179
	   grey71:c(46517 46517 46517) % 181 181 181
	   grey72:c(47288 47288 47288) % 184 184 184
	   grey73:c(47802 47802 47802) % 186 186 186
	   grey74:c(48573 48573 48573) % 189 189 189
	   grey75:c(49087 49087 49087) % 191 191 191
	   grey76:c(49858 49858 49858) % 194 194 194
	   grey77:c(50372 50372 50372) % 196 196 196
	   grey78:c(51143 51143 51143) % 199 199 199
	   grey79:c(51657 51657 51657) % 201 201 201
	   grey80:c(52428 52428 52428) % 204 204 204
	   grey81:c(53199 53199 53199) % 207 207 207
	   grey82:c(53713 53713 53713) % 209 209 209
	   grey83:c(54484 54484 54484) % 212 212 212
	   grey84:c(54998 54998 54998) % 214 214 214
	   grey85:c(55769 55769 55769) % 217 217 217
	   grey86:c(56283 56283 56283) % 219 219 219
	   grey87:c(57054 57054 57054) % 222 222 222
	   grey88:c(57568 57568 57568) % 224 224 224
	   grey89:c(58339 58339 58339) % 227 227 227
	   grey90:c(58853 58853 58853) % 229 229 229
	   grey91:c(59624 59624 59624) % 232 232 232
	   grey92:c(60395 60395 60395) % 235 235 235
	   grey93:c(60909 60909 60909) % 237 237 237
	   grey94:c(61680 61680 61680) % 240 240 240
	   grey95:c(62194 62194 62194) % 242 242 242
	   grey96:c(62965 62965 62965) % 245 245 245
	   grey97:c(63479 63479 63479) % 247 247 247
	   grey98:c(64250 64250 64250) % 250 250 250
	   grey99:c(64764 64764 64764) % 252 252 252
	   grey100:c(65535 65535 65535) % 255 255 255
	   honeydew:c(61680 65535 61680) % 240 255 240
	   honeydew1:c(61680 65535 61680) % 240 255 240
	   honeydew2:c(57568 61166 57568) % 224 238 224
	   honeydew3:c(49601 52685 49601) % 193 205 193
	   honeydew4:c(33667 35723 33667) % 131 139 131
	   'hot pink':c(65535 26985 46260) % 255 105 180
	   'HotPink':c(65535 26985 46260) % 255 105 180
	   'HotPink1':c(65535 28270 46260) % 255 110 180
	   'HotPink2':c(61166 27242 42919) % 238 106 167
	   'HotPink3':c(52685 24672 37008) % 205 96 144
	   'HotPink4':c(35723 14906 25186) % 139 58 98
	   'indian red':c(52685 23644 23644) % 205 92 92
	   'IndianRed':c(52685 23644 23644) % 205 92 92
	   'IndianRed1':c(65535 27242 27242) % 255 106 106
	   'IndianRed2':c(61166 25443 25443) % 238 99 99
	   'IndianRed3':c(52685 21845 21845) % 205 85 85
	   'IndianRed4':c(35723 14906 14906) % 139 58 58
	   ivory:c(65535 65535 61680) % 255 255 240
	   ivory1:c(65535 65535 61680) % 255 255 240
	   ivory2:c(61166 61166 57568) % 238 238 224
	   ivory3:c(52685 52685 49601) % 205 205 193
	   ivory4:c(35723 35723 33667) % 139 139 131
	   khaki:c(61680 59110 35980) % 240 230 140
	   khaki1:c(65535 63222 36751) % 255 246 143
	   khaki2:c(61166 59110 34181) % 238 230 133
	   khaki3:c(52685 50886 29555) % 205 198 115
	   khaki4:c(35723 34438 20046) % 139 134 78
	   lavender:c(59110 59110 64250) % 230 230 250
	   'lavender blush':c(65535 61680 62965) % 255 240 245
	   'LavenderBlush':c(65535 61680 62965) % 255 240 245
	   'LavenderBlush1':c(65535 61680 62965) % 255 240 245
	   'LavenderBlush2':c(61166 57568 58853) % 238 224 229
	   'LavenderBlush3':c(52685 49601 50629) % 205 193 197
	   'LavenderBlush4':c(35723 33667 34438) % 139 131 134
	   'lawn green':c(31868 64764 0) % 124 252 0
	   'LawnGreen':c(31868 64764 0) % 124 252 0
	   'lemon chiffon':c(65535 64250 52685) % 255 250 205
	   'LemonChiffon':c(65535 64250 52685) % 255 250 205
	   'LemonChiffon1':c(65535 64250 52685) % 255 250 205
	   'LemonChiffon2':c(61166 59881 49087) % 238 233 191
	   'LemonChiffon3':c(52685 51657 42405) % 205 201 165
	   'LemonChiffon4':c(35723 35209 28784) % 139 137 112
	   'light blue':c(44461 55512 59110) % 173 216 230
	   'light coral':c(61680 32896 32896) % 240 128 128
	   'light cyan':c(57568 65535 65535) % 224 255 255
	   'light goldenrod':c(61166 56797 33410) % 238 221 130
	   'light goldenrod yellow':c(64250 64250 53970) % 250 250 210
	   'light gray':c(54227 54227 54227) % 211 211 211
	   'light green':c(37008 61166 37008) % 144 238 144
	   'light grey':c(54227 54227 54227) % 211 211 211
	   'light pink':c(65535 46774 49601) % 255 182 193
	   'light salmon':c(65535 41120 31354) % 255 160 122
	   'light sea green':c(8224 45746 43690) % 32 178 170
	   'light sky blue':c(34695 52942 64250) % 135 206 250
	   'light slate blue':c(33924 28784 65535) % 132 112 255
	   'light slate gray':c(30583 34952 39321) % 119 136 153
	   'light slate grey':c(30583 34952 39321) % 119 136 153
	   'light steel blue':c(45232 50372 57054) % 176 196 222
	   'light yellow':c(65535 65535 57568) % 255 255 224
	   'LightBlue':c(44461 55512 59110) % 173 216 230
	   'LightBlue1':c(49087 61423 65535) % 191 239 255
	   'LightBlue2':c(45746 57311 61166) % 178 223 238
	   'LightBlue3':c(39578 49344 52685) % 154 192 205
	   'LightBlue4':c(26728 33667 35723) % 104 131 139
	   'LightCoral':c(61680 32896 32896) % 240 128 128
	   'LightCyan':c(57568 65535 65535) % 224 255 255
	   'LightCyan1':c(57568 65535 65535) % 224 255 255
	   'LightCyan2':c(53713 61166 61166) % 209 238 238
	   'LightCyan3':c(46260 52685 52685) % 180 205 205
	   'LightCyan4':c(31354 35723 35723) % 122 139 139
	   'LightGoldenrod':c(61166 56797 33410) % 238 221 130
	   'LightGoldenrod1':c(65535 60652 35723) % 255 236 139
	   'LightGoldenrod2':c(61166 56540 33410) % 238 220 130
	   'LightGoldenrod3':c(52685 48830 28784) % 205 190 112
	   'LightGoldenrod4':c(35723 33153 19532) % 139 129 76
	   'LightGoldenrodYellow':c(64250 64250 53970) % 250 250 210
	   'LightGray':c(54227 54227 54227) % 211 211 211
	   'LightGreen':c(37008 61166 37008) % 144 238 144
	   'LightGrey':c(54227 54227 54227) % 211 211 211
	   'LightPink':c(65535 46774 49601) % 255 182 193
	   'LightPink1':c(65535 44718 47545) % 255 174 185
	   'LightPink2':c(61166 41634 44461) % 238 162 173
	   'LightPink3':c(52685 35980 38293) % 205 140 149
	   'LightPink4':c(35723 24415 25957) % 139 95 101
	   'LightSalmon':c(65535 41120 31354) % 255 160 122
	   'LightSalmon1':c(65535 41120 31354) % 255 160 122
	   'LightSalmon2':c(61166 38293 29298) % 238 149 114
	   'LightSalmon3':c(52685 33153 25186) % 205 129 98
	   'LightSalmon4':c(35723 22359 16962) % 139 87 66
	   'LightSeaGreen':c(8224 45746 43690) % 32 178 170
	   'LightSkyBlue':c(34695 52942 64250) % 135 206 250
	   'LightSkyBlue1':c(45232 58082 65535) % 176 226 255
	   'LightSkyBlue2':c(42148 54227 61166) % 164 211 238
	   'LightSkyBlue3':c(36237 46774 52685) % 141 182 205
	   'LightSkyBlue4':c(24672 31611 35723) % 96 123 139
	   'LightSlateBlue':c(33924 28784 65535) % 132 112 255
	   'LightSlateGray':c(30583 34952 39321) % 119 136 153
	   'LightSlateGrey':c(30583 34952 39321) % 119 136 153
	   'LightSteelBlue':c(45232 50372 57054) % 176 196 222
	   'LightSteelBlue1':c(51914 57825 65535) % 202 225 255
	   'LightSteelBlue2':c(48316 53970 61166) % 188 210 238
	   'LightSteelBlue3':c(41634 46517 52685) % 162 181 205
	   'LightSteelBlue4':c(28270 31611 35723) % 110 123 139
	   'LightYellow':c(65535 65535 57568) % 255 255 224
	   'LightYellow1':c(65535 65535 57568) % 255 255 224
	   'LightYellow2':c(61166 61166 53713) % 238 238 209
	   'LightYellow3':c(52685 52685 46260) % 205 205 180
	   'LightYellow4':c(35723 35723 31354) % 139 139 122
	   'lime green':c(12850 52685 12850) % 50 205 50
	   'LimeGreen':c(12850 52685 12850) % 50 205 50
	   linen:c(64250 61680 59110) % 250 240 230
	   magenta:c(65535 0 65535) % 255 0 255
	   magenta1:c(65535 0 65535) % 255 0 255
	   magenta2:c(61166 0 61166) % 238 0 238
	   magenta3:c(52685 0 52685) % 205 0 205
	   magenta4:c(35723 0 35723) % 139 0 139
	   maroon:c(45232 12336 24672) % 176 48 96
	   maroon1:c(65535 13364 46003) % 255 52 179
	   maroon2:c(61166 12336 42919) % 238 48 167
	   maroon3:c(52685 10537 37008) % 205 41 144
	   maroon4:c(35723 7196 25186) % 139 28 98
	   'medium aquamarine':c(26214 52685 43690) % 102 205 170
	   'medium blue':c(0 0 52685) % 0 0 205
	   'medium orchid':c(47802 21845 54227) % 186 85 211
	   'medium purple':c(37779 28784 56283) % 147 112 219
	   'medium sea green':c(15420 46003 29041) % 60 179 113
	   'medium slate blue':c(31611 26728 61166) % 123 104 238
	   'medium spring green':c(0 64250 39578) % 0 250 154
	   'medium turquoise':c(18504 53713 52428) % 72 209 204
	   'medium violet red':c(51143 5397 34181) % 199 21 133
	   'MediumAquamarine':c(26214 52685 43690) % 102 205 170
	   'MediumBlue':c(0 0 52685) % 0 0 205
	   'MediumOrchid':c(47802 21845 54227) % 186 85 211
	   'MediumOrchid1':c(57568 26214 65535) % 224 102 255
	   'MediumOrchid2':c(53713 24415 61166) % 209 95 238
	   'MediumOrchid3':c(46260 21074 52685) % 180 82 205
	   'MediumOrchid4':c(31354 14135 35723) % 122 55 139
	   'MediumPurple':c(37779 28784 56283) % 147 112 219
	   'MediumPurple1':c(43947 33410 65535) % 171 130 255
	   'MediumPurple2':c(40863 31097 61166) % 159 121 238
	   'MediumPurple3':c(35209 26728 52685) % 137 104 205
	   'MediumPurple4':c(23901 18247 35723) % 93 71 139
	   'MediumSeaGreen':c(15420 46003 29041) % 60 179 113
	   'MediumSlateBlue':c(31611 26728 61166) % 123 104 238
	   'MediumSpringGreen':c(0 64250 39578) % 0 250 154
	   'MediumTurquoise':c(18504 53713 52428) % 72 209 204
	   'MediumVioletRed':c(51143 5397 34181) % 199 21 133
	   'midnight blue':c(6425 6425 28784) % 25 25 112
	   'MidnightBlue':c(6425 6425 28784) % 25 25 112
	   'mint cream':c(62965 65535 64250) % 245 255 250
	   'MintCream':c(62965 65535 64250) % 245 255 250
	   'misty rose':c(65535 58596 57825) % 255 228 225
	   'MistyRose':c(65535 58596 57825) % 255 228 225
	   'MistyRose1':c(65535 58596 57825) % 255 228 225
	   'MistyRose2':c(61166 54741 53970) % 238 213 210
	   'MistyRose3':c(52685 47031 46517) % 205 183 181
	   'MistyRose4':c(35723 32125 31611) % 139 125 123
	   moccasin:c(65535 58596 46517) % 255 228 181
	   'navajo white':c(65535 57054 44461) % 255 222 173
	   'NavajoWhite':c(65535 57054 44461) % 255 222 173
	   'NavajoWhite1':c(65535 57054 44461) % 255 222 173
	   'NavajoWhite2':c(61166 53199 41377) % 238 207 161
	   'NavajoWhite3':c(52685 46003 35723) % 205 179 139
	   'NavajoWhite4':c(35723 31097 24158) % 139 121 94
	   navy:c(0 0 32896) % 0 0 128
	   'navy blue':c(0 0 32896) % 0 0 128
	   'NavyBlue':c(0 0 32896) % 0 0 128
	   'old lace':c(65021 62965 59110) % 253 245 230
	   'OldLace':c(65021 62965 59110) % 253 245 230
	   'olive drab':c(27499 36494 8995) % 107 142 35
	   'OliveDrab':c(27499 36494 8995) % 107 142 35
	   'OliveDrab1':c(49344 65535 15934) % 192 255 62
	   'OliveDrab2':c(46003 61166 14906) % 179 238 58
	   'OliveDrab3':c(39578 52685 12850) % 154 205 50
	   'OliveDrab4':c(26985 35723 8738) % 105 139 34
	   orange:c(65535 42405 0) % 255 165 0
	   'orange red':c(65535 17733 0) % 255 69 0
	   orange1:c(65535 42405 0) % 255 165 0
	   orange2:c(61166 39578 0) % 238 154 0
	   orange3:c(52685 34181 0) % 205 133 0
	   orange4:c(35723 23130 0) % 139 90 0
	   'OrangeRed':c(65535 17733 0) % 255 69 0
	   'OrangeRed1':c(65535 17733 0) % 255 69 0
	   'OrangeRed2':c(61166 16448 0) % 238 64 0
	   'OrangeRed3':c(52685 14135 0) % 205 55 0
	   'OrangeRed4':c(35723 9509 0) % 139 37 0
	   orchid:c(56026 28784 54998) % 218 112 214
	   orchid1:c(65535 33667 64250) % 255 131 250
	   orchid2:c(61166 31354 59881) % 238 122 233
	   orchid3:c(52685 26985 51657) % 205 105 201
	   orchid4:c(35723 18247 35209) % 139 71 137
	   'pale goldenrod':c(61166 59624 43690) % 238 232 170
	   'pale green':c(39064 64507 39064) % 152 251 152
	   'pale turquoise':c(44975 61166 61166) % 175 238 238
	   'pale violet red':c(56283 28784 37779) % 219 112 147
	   'PaleGoldenrod':c(61166 59624 43690) % 238 232 170
	   'PaleGreen':c(39064 64507 39064) % 152 251 152
	   'PaleGreen1':c(39578 65535 39578) % 154 255 154
	   'PaleGreen2':c(37008 61166 37008) % 144 238 144
	   'PaleGreen3':c(31868 52685 31868) % 124 205 124
	   'PaleGreen4':c(21588 35723 21588) % 84 139 84
	   'PaleTurquoise':c(44975 61166 61166) % 175 238 238
	   'PaleTurquoise1':c(48059 65535 65535) % 187 255 255
	   'PaleTurquoise2':c(44718 61166 61166) % 174 238 238
	   'PaleTurquoise3':c(38550 52685 52685) % 150 205 205
	   'PaleTurquoise4':c(26214 35723 35723) % 102 139 139
	   'PaleVioletRed':c(56283 28784 37779) % 219 112 147
	   'PaleVioletRed1':c(65535 33410 43947) % 255 130 171
	   'PaleVioletRed2':c(61166 31097 40863) % 238 121 159
	   'PaleVioletRed3':c(52685 26728 35209) % 205 104 127
	   'PaleVioletRed4':c(35723 18247 23901) % 139 71 93
	   'papaya whip':c(65535 61423 54741) % 255 239 213
	   'PapayaWhip':c(65535 61423 54741) % 255 239 213
	   'peach puff':c(65535 56026 47545) % 255 218 185
	   'PeachPuff':c(65535 56026 47545) % 255 218 185
	   'PeachPuff1':c(65535 56026 47545) % 255 218 185
	   'PeachPuff2':c(61166 52171 44461) % 238 203 173
	   'PeachPuff3':c(52685 44975 38293) % 205 175 149
	   'PeachPuff4':c(35723 30583 25957) % 139 119 101
	   peru:c(52685 34181 16191) % 205 133 63
	   pink:c(65535 49344 52171) % 255 192 203
	   pink1:c(65535 46517 50629) % 255 181 197
	   pink2:c(61166 43433 47288) % 238 169 184
	   pink3:c(52685 37265 40606) % 205 145 158
	   pink4:c(35723 25443 27756) % 139 99 108
	   plum:c(56797 41120 56797) % 221 160 221
	   plum1:c(65535 48059 65535) % 255 187 255
	   plum2:c(61166 44718 61166) % 238 174 238
	   plum3:c(52685 38550 52685) % 205 150 205
	   plum4:c(35723 26214 35723) % 139 102 139
	   'powder blue':c(45232 57568 59110) % 176 224 230
	   'PowderBlue':c(45232 57568 59110) % 176 224 230
	   purple:c(41120 8224 61680) % 160 32 240
	   purple1:c(39835 12336 65535) % 155 48 255
	   purple2:c(37265 11308 61166) % 145 44 238
	   purple3:c(32125 9766 52685) % 125 38 205
	   purple4:c(21845 6682 35723) % 85 26 139
	   red:c(65535 0 0) % 255 0 0
	   red1:c(65535 0 0) % 255 0 0
	   red2:c(61166 0 0) % 238 0 0
	   red3:c(52685 0 0) % 205 0 0
	   red4:c(35723 0 0) % 139 0 0
	   'rosy brown':c(48316 36751 36751) % 188 143 143
	   'RosyBrown':c(48316 36751 36751) % 188 143 143
	   'RosyBrown1':c(65535 49601 49601) % 255 193 193
	   'RosyBrown2':c(61166 46260 46260) % 238 180 180
	   'RosyBrown3':c(52685 39835 39835) % 205 155 155
	   'RosyBrown4':c(35723 26985 26985) % 139 105 105
	   'royal blue':c(16705 26985 57825) % 65 105 225
	   'RoyalBlue':c(16705 26985 57825) % 65 105 225
	   'RoyalBlue1':c(18504 30326 65535) % 72 118 255
	   'RoyalBlue2':c(17219 28270 61166) % 67 110 238
	   'RoyalBlue3':c(14906 24415 52685) % 58 95 205
	   'RoyalBlue4':c(10023 16448 35723) % 39 64 139
	   'saddle brown':c(35723 17733 4883) % 139 69 19
	   'SaddleBrown':c(35723 17733 4883) % 139 69 19
	   salmon:c(64250 32896 29298) % 250 128 114
	   salmon1:c(65535 35980 26985) % 255 140 105
	   salmon2:c(61166 33410 25186) % 238 130 98
	   salmon3:c(52685 28784 21588) % 205 112 84
	   salmon4:c(35723 19532 14649) % 139 76 57
	   'sandy brown':c(62708 42148 24672) % 244 164 96
	   'SandyBrown':c(62708 42148 24672) % 244 164 96
	   'sea green':c(11822 35723 22359) % 46 139 87
	   'SeaGreen':c(11822 35723 22359) % 46 139 87
	   'SeaGreen1':c(21588 65535 40863) % 84 255 159
	   'SeaGreen2':c(20046 61166 38036) % 78 238 148
	   'SeaGreen3':c(17219 52685 32896) % 67 205 128
	   'SeaGreen4':c(11822 35723 22359) % 46 139 87
	   seashell:c(65535 62965 61166) % 255 245 238
	   seashell1:c(65535 62965 61166) % 255 245 238
	   seashell2:c(61166 58853 57054) % 238 229 222
	   seashell3:c(52685 50629 49087) % 205 197 191
	   seashell4:c(35723 34438 33410) % 139 134 130
	   sienna:c(41120 21074 11565) % 160 82 45
	   sienna1:c(65535 33410 18247) % 255 130 71
	   sienna2:c(61166 31097 16962) % 238 121 66
	   sienna3:c(52685 26728 14649) % 205 104 57
	   sienna4:c(35723 18247 9766) % 139 71 38
	   'sky blue':c(34695 52942 60395) % 135 206 235
	   'SkyBlue':c(34695 52942 60395) % 135 206 235
	   'SkyBlue1':c(34695 52942 65535) % 135 206 255
	   'SkyBlue2':c(32382 49344 61166) % 126 192 238
	   'SkyBlue3':c(27756 42662 52685) % 108 166 205
	   'SkyBlue4':c(19018 28784 35723) % 74 112 139
	   'slate blue':c(27242 23130 52685) % 106 90 205
	   'slate gray':c(28784 32896 37008) % 112 128 144
	   'slate grey':c(28784 32896 37008) % 112 128 144
	   'SlateBlue':c(27242 23130 52685) % 106 90 205
	   'SlateBlue1':c(33667 28527 65535) % 131 111 255
	   'SlateBlue2':c(31354 26471 61166) % 122 103 238
	   'SlateBlue3':c(26985 22873 52685) % 105 89 205
	   'SlateBlue4':c(18247 15420 35723) % 71 60 139
	   'SlateGray':c(28784 32896 37008) % 112 128 144
	   'SlateGray1':c(50886 58082 65535) % 198 226 255
	   'SlateGray2':c(47545 54227 61166) % 185 211 238
	   'SlateGray3':c(40863 46774 52685) % 159 182 205
	   'SlateGray4':c(27756 31611 35723) % 108 123 139
	   'SlateGrey':c(28784 32896 37008) % 112 128 144
	   snow:c(65535 64250 64250) % 255 250 250
	   snow1:c(65535 64250 64250) % 255 250 250
	   snow2:c(61166 59881 59881) % 238 233 233
	   snow3:c(52685 51657 51657) % 205 201 201
	   snow4:c(35723 35209 35209) % 139 137 137
	   'spring green':c(0 65535 32639) % 0 255 127
	   'SpringGreen':c(0 65535 32639) % 0 255 127
	   'SpringGreen1':c(0 65535 32639) % 0 255 127
	   'SpringGreen2':c(0 61166 30326) % 0 238 118
	   'SpringGreen3':c(0 52685 26214) % 0 205 102
	   'SpringGreen4':c(0 35723 17733) % 0 139 69
	   'steel blue':c(17990 33410 46260) % 70 130 180
	   'SteelBlue':c(17990 33410 46260) % 70 130 180
	   'SteelBlue1':c(25443 47288 65535) % 99 184 255
	   'SteelBlue2':c(23644 44204 61166) % 92 172 238
	   'SteelBlue3':c(20303 38036 52685) % 79 148 205
	   'SteelBlue4':c(13878 25700 35723) % 54 100 139
	   tan:c(53970 46260 35980) % 210 180 140
	   tan1:c(65535 42405 20303) % 255 165 79
	   tan2:c(61166 39578 18761) % 238 154 73
	   tan3:c(52685 34181 16191) % 205 133 63
	   tan4:c(35723 23130 11051) % 139 90 43
	   thistle:c(55512 49087 55512) % 216 191 216
	   thistle1:c(65535 57825 65535) % 255 225 255
	   thistle2:c(61166 53970 61166) % 238 210 238
	   thistle3:c(52685 46517 52685) % 205 181 205
	   thistle4:c(35723 31611 35723) % 139 123 139
	   tomato:c(65535 25443 18247) % 255 99 71
	   tomato1:c(65535 25443 18247) % 255 99 71
	   tomato2:c(61166 23644 16962) % 238 92 66
	   tomato3:c(52685 20303 14649) % 205 79 57
	   tomato4:c(35723 13878 9766) % 139 54 38
	   turquoise:c(16448 57568 53456) % 64 224 208
	   turquoise1:c(0 62965 65535) % 0 245 255
	   turquoise2:c(0 58853 61166) % 0 229 238
	   turquoise3:c(0 50629 52685) % 0 197 205
	   turquoise4:c(0 34438 35723) % 0 134 139
	   violet:c(61166 33410 61166) % 238 130 238
	   'violet red':c(53456 8224 37008) % 208 32 144
	   'VioletRed':c(53456 8224 37008) % 208 32 144
	   'VioletRed1':c(65535 15934 38550) % 255 62 150
	   'VioletRed2':c(61166 14906 35980) % 238 58 140
	   'VioletRed3':c(52685 12850 30840) % 205 50 120
	   'VioletRed4':c(35723 8738 21074) % 139 34 82
	   wheat:c(62965 57054 46003) % 245 222 179
	   wheat1:c(65535 59367 47802) % 255 231 186
	   wheat2:c(61166 55512 44718) % 238 216 174
	   wheat3:c(52685 47802 38550) % 205 186 150
	   wheat4:c(35723 32382 26214) % 139 126 102
	   white:c(65535 65535 65535) % 255 255 255
	   'white smoke':c(62965 62965 62965) % 245 245 245
	   'WhiteSmoke':c(62965 62965 62965) % 245 245 245
	   yellow:c(65535 65535 0) % 255 255 0
	   'yellow green':c(39578 52685 12850) % 154 205 50
	   yellow1:c(65535 65535 0) % 255 255 0
	   yellow2:c(61166 61166 0) % 238 238 0
	   yellow3:c(52685 52685 0) % 205 205 0
	   yellow4:c(35723 35723 0) % 139 139 0
	   'YellowGreen':c(39578 52685 12850) % 154 205 50
	  )

   fun{ColorToString C}
      fun{RToHex V I}
	 C=V mod 16
	 R=V div 16
	 fun{ToStr C}
	    if C<10 then &0+C
	    else &a+C-10
	    end
	 end
      in
	 if I<4 then
	    {ToStr C}|{RToHex R I+1}
	 else
	    nil
	 end
      end
      fun{ToHex X}
	 {Reverse {RToHex X 0}}
      end
      c(R G B)=C
   in
      {List.flatten "#"|{ToHex R}|{ToHex G}|{ToHex B}}
   end


\ifndef OPI

define
   Manager1=Manager
   Init1=Init

   TypeDef1=TypeDef
   
   NOOP1=NOOP
   FAIL1=FAIL

   None1=None
   Atomize1=Atomize
   TkExec1=TkExec
   TkReturn1=TkReturn

   TkStringTo1=TkStringTo

   Bind1=Bind
   ToEventCode1=ToEventCode

   Color1=Color
   ColorToString1=ColorToString
   TCLTK1=TCLTK
   
end
\endif