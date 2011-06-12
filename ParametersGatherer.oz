\ifndef OPI

functor

import
   System(show:Show)
   ETkMisc(typeDef:TypeDef
	   manager:Manager
	   nOOP:NOOP
	   fAIL:FAIL
	   tkStringTo:TkStringTo
	   colorToString:ColorToString
	   none:None)
   EBL(remoteType:RemoteType
       invalidType:InvalidType
       checkType:CheckType)
   
export
   synonyms:Synonyms
   tkDefaults:TkDefaults
   tkParameters:TkParameters
   tkTypeChecker:TkTypeChecker
   tkProxyMarshaller:TkProxyMarshaller
   tkRenderMarshaller:TkRenderMarshaller

require
   Tk
%   Browser(browse:Browse)
%    EBL(getType:GetType
%        checkType:CheckType
%        getTypeInfo:GetTypeInfo
%        remote:Remote
%        invalid:Invalid)

prepare
   Data
   Types

\endif

\ifdef OPI
Synonyms
TkDefaults
TkParameters
TkTypeChecker
TkProxyMarshaller
TkRenderMarshaller

local

\endif
   
%declare

   %% available at this stage :
   %%    Synonyms=synonym(bg:background ...)
   %%    Defaults=info(button:o(activebackground:'blabla' ...) ...)
   %%    TkTypeChecker
   %%    TkMarshaller
   

   Data
   Types
   
   local
      
      fun{ConfigureInfoToRecord A}
	 Synonyms={Dictionary.new}
	 fun{Split2 S N R}
	    case S
	    of &\\|X|Xs then &\\|X|{Split2 Xs N R}
	    [] &{|Xs then &{|{Split2 Xs N+1 R}
	    [] &}|Xs then
	       if N>0 then
		  &}|{Split2 Xs N-1 R}
	       else
		  R={List.dropWhile Xs fun{$ C} C==&   end}
		  nil
	       end
	    [] X|Xs then X|{Split2 Xs N R}
	    else R=nil nil end
	 end
	 fun{Split1 S}
	    R
	    T={Split2 S ~1 R}
	 in
	    if R==nil then
	       T.2|nil
	    else
	       T.2|{Split1 R}
	    end
	 end
	 fun{Split4 S N R}
	    case S
	    of &\\|X|Xs then &\\|X|{Split4 Xs N R}
	    [] &{|Xs then &{|{Split4 Xs N+1 R}
	    [] &}|Xs then
	       if N>0 then
		  &}|{Split4 Xs N-1 R}
	       else
		  R={List.dropWhile Xs fun{$ C} C==&   end}
		  nil
	       end
	    [] & |Xs then
	       if N>0 then
		  & |{Split4 Xs N R}
	       else
		  R={List.dropWhile Xs fun{$ C} C==&   end}
		  nil
	       end
	    [] X|Xs then X|{Split4 Xs N R}
	    else R=nil nil end
	 end
	 fun{Split3 S}
	    R
	    T={Split4 S 0 R}
	 in
	    if R==nil then
	       T|nil
	    else
	       T|{Split3 R}
	    end
	 end
	 fun{DropMinus S}
	    case S of &-|Xs then Xs else S end
	 end
	 fun{LowerCaseAtom S}
	    {String.toAtom {List.map {VirtualString.toString S} fun{$ C} {Char.toLower C} end}}
	 end
	 proc{AddSynonym Source Target1}
	    L={GetSynonyms Source}
	    Target={String.toAtom {DropMinus Target1}}
	 in
	    if Source\=Target then
	       proc{Loop L}
		  if {IsDet L} then
		     if L.1\=Target then
			{Loop L.2}
		     end
		  else
		     Target|_=L
		  end
	       end
	    in
	       {Loop L}
	    end
	 end
	 fun{GetSynonyms S1}
	    S={LowerCaseAtom S1}
	 in
	    if {Dictionary.member Synonyms S} then
	       {Dictionary.get Synonyms S}
	    else
	       N
	    in
	       {Dictionary.put Synonyms S N}
	       N
	    end
	 end
	 proc{CloseSynonyms}
	    {ForAll {Dictionary.items Synonyms}
	     proc{$ L}
		proc{Loop L}
		   if {IsDet L} then {Loop L.2} else L=nil end
		end
	     in
		{Loop L}
	     end}
	 end
	 fun{Filter L}
	    case L of X|Xs then
	       G={Length X}
	    in
	       if G==2 then
		  {AddSynonym {DropMinus {List.nth X 2}} {DropMinus {List.nth X 1}}}
		  {Filter Xs}
	       else
		  A={StringToAtom {DropMinus {List.nth X 1}}}
		  S={GetSynonyms A}
		  {ForAll {List.take X.2 G-4}
		   proc{$ E}
		      {AddSynonym A E}
		   end}
		  Type={String.toAtom {List.nth X G-2}}
		  Default={String.toAtom {List.nth X G-1}}
		  Current={String.toAtom {List.nth X G}}
	       in
		  A#r(synonym:S
		      type:Type
		      default:Default
		      current:Current)|{Filter Xs}


% 	       if {List.member Type ['Background' 'DisabledBackground' 'DisabledForeground' 'Foreground' 'HighlightBackground' 'HighlightColor' 'ReadonlyBackground']} then
% 		    r(synonym:S
% 		      type:Type
% 		      default:{CodeColor Default}
% 		      current:{CodeColor Current})
% 		 else
% 		    r(synonym:S
% 		      type:Type
% 		      default:Default
% 		      current:Current)
% 		 end|{Filter Xs}
	       end
% 	 L={List.last X}
%       in
% 	 if L.1==&- then
% 	    {String.toAtom X.1.2}#r(synonym:{String.toAtom X.2.1.2})|{Filter Xs} %% option alias => ignore
% 	 else
% 	    {String.toAtom X.1.2}#r(capitalized:{String.toAtom X.2.1}
% 				    type:{String.toAtom X.2.2.1}
% 				    default:X.2.2.2.1
% 				    current:L)|{Filter Xs}
% 	 end
	    else
	       {CloseSynonyms}
	       nil
	    end
	 end
      in
	 {List.toRecord o {Filter {List.map {Split1 A} Split3}}}
      end

      WidgetList=[button canvas checkbutton entry frame label listbox menubutton message radiobutton scale scrollbar text labelframe panedwindow spinbox menu]

% labelframe not defined by default by Tk
% panedwindow not defined by default by Tk
% spinbox  not defined by default by Tk

      fun{Process W}
	 C={Tk.newWidgetClass noCommand W}
	 H={New C tkInit(parent:Win)}
	 V={H tkReturn(configure $)}
	 {Wait V}
      in
	 W#{ConfigureInfoToRecord V}
      end

      Win={New Tk.toplevel tkInit(withdraw:true)}
      fun{GatherTypes Data}
	 D={Dictionary.new}
	 {Record.forAllInd Data
	  proc{$ E W}
	     {Record.forAllInd W
	      proc{$ K I}
		 {Dictionary.put D I.type E|{Dictionary.condGet D I.type nil}}
	      end}
	  end}
      in
	 {List.sort {Dictionary.entries D}
	  fun{$ A B} A.1<B.1 end}
      end
   in
      Data={List.toRecord info {List.map
				toplevel#{ConfigureInfoToRecord {Win tkReturn(configure $)}}|{List.map WidgetList Process}
				fun{$ K#V}
				   K#{Record.map V
				      fun{$ R}
					 fun{CodeColor C}
					    [R G B]={Tk.returnListInt winfo(rgb Win C)}
					 in
					    {Wait R} {Wait G} {Wait B}
					    c(R G B)
					 end
				      in
					 if {List.member R.type ['Background' 'DisabledBackground' 'DisabledForeground' 'Foreground' 'HighlightBackground' 'HighlightColor' 'ReadonlyBackground']} then
					    r(synonym:R.synonym
					      type:R.type
					      default:{CodeColor R.default}
					      current:{CodeColor R.current})
					 else
					    R
					 end
				      end}
				end}}

      {Win tkClose}



      Types={GatherTypes Data}
   end
      
%      {Browse Data}
%      {Browse Types}
%      {Wait _}
%{Browse Types}
%{Show {Length Types}}

\ifndef OPI

define
   TkTypeChecker
   TkProxyMarshaller
   TkRenderMarshaller
   TkDefaults
   Synonyms
   TkParameters
   
\endif

   OzAtom=TypeDef.ozAtom
   Boolean=TypeDef.boolean
   Integer=TypeDef.integer
   ElementOf=TypeDef.elementOf
   Color=TypeDef.color
   FloatPoint=TypeDef.floatPoint
   Bitmap=TypeDef.bitmap
   Pixel=TypeDef.pixel
   FontType=TypeDef.fontType
   Image=TypeDef.image
   VString=TypeDef.vString
   Menu=TypeDef.menu
   PosInteger=TypeDef.posInteger
   NoneListInt=TypeDef.noneListInt
   
   !TkTypeChecker=tktypechecker('Any':fun{$ _} true end
				'Atom':OzAtom
				'Int':Int.is
				'ListString':fun{$ V} {List.is V} andthen {List.all V VirtualString.is} end
				'ActiveStyle':{ElementOf [dotbox none underline]} %[listbox]
				'Anchor':{ElementOf [n ne e se s sw w nw center]} %[radiobutton message menubutton label checkbutton button]
				'Aspect':fun{$ V} {Int.is V} andthen V>0 end#"A strictly positive integer"  %[message]
				'AutoSeparators':Boolean %[text]
				'Background':Color %[toplevel text text spinbox spinbox spinbox spinbox scrollbar scrollbar scale scale radiobutton radiobutton radiobutton panedwindow message menubutton menubutton listbox listbox labelframe label label frame entry entry checkbutton checkbutton checkbutton canvas canvas button button]
				'BigIncrement':FloatPoint %[scale]
				'Bitmap':Bitmap %[radiobutton menubutton label checkbutton button]
				'BorderWidth':Pixel %[toplevel text text text spinbox spinbox spinbox scrollbar scrollbar scale radiobutton panedwindow message menubutton listbox listbox labelframe label frame entry entry entry checkbutton canvas canvas canvas button]
				'Boolean':Boolean
				'Class':RemoteType %[toplevel labelframe frame]
				'CloseEnough':FloatPoint %[canvas]
				'Colormap':RemoteType %[toplevel labelframe frame]
				'Command':InvalidType %[spinbox scrollbar scale radiobutton checkbutton button]
				'Compound':{ElementOf [none bottom top left right center]} %[radiobutton menubutton label checkbutton button]
				'Confine':Boolean %[canvas]
				'Container':Boolean %[toplevel labelframe frame]
				'Cursor':{ElementOf [None 'X_cursor' arrow based_arrow_down based_arrow_up boat bogosity bottom_left_corner bottom_right_corner bottom_side bottom_tee box_spiral center_ptr circle clock coffee_mug cross cross_reverse crosshair diamond_cross dot dotbox double_arrow draft_large draft_small draped_box exchange fleur gobbler gumby hand1 hand2 heart icon iron_cross left_ptr left_side left_tee leftbutton ll_angle lr_angle man middlebutton mouse pencil pirate plus question_arrow right_ptr right_side right_tee rightbutton rtl_logo sailboat sb_down_arrow sb_h_double_arrow sb_left_arrow sb_right_arrow sb_up_arrow sb_v_double_arrow shuttle sizing spider spraycan star target tcross top_left_arrow top_left_corner top_right_corner top_side top_tee trek ul_angle umbrella ur_angle watch xterm]} %[toplevel text spinbox spinbox scrollbar scale radiobutton panedwindow panedwindow message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'Default':{ElementOf [normal active disabled]} %[button]
				'Digits':Integer %[scale]
				'Direction':{ElementOf [above below left right]} %[menubutton]
				'DisabledBackground':fun{$ L} {Color.1 L} orelse L==None end#{VirtualString.toString "None or "#Color.2} %[spinbox entry]
				'DisabledForeground':fun{$ L} {Color.1 L} orelse L==None end#{VirtualString.toString "'' or "#Color.2} %[spinbox radiobutton menubutton listbox label entry checkbutton button]
				'ExportSelection':Boolean %[text spinbox listbox entry]
				'Font':FontType %[text spinbox scale radiobutton message menubutton listbox labelframe label entry checkbutton button]
				'Foreground':Color %[text text text spinbox spinbox spinbox scrollbar scale scale radiobutton radiobutton message menubutton menubutton listbox listbox labelframe label label entry entry entry checkbutton checkbutton canvas canvas button button]
				'Format':RemoteType %[spinbox]
				'From':FloatPoint %[spinbox scale]
				'HandlePad':Pixel %[panedwindow]
				'HandleSize':Pixel %[panedwindow]
				'Height':RemoteType %[toplevel text radiobutton panedwindow menubutton listbox labelframe label frame checkbutton canvas button]
				'HighlightBackground':Color %[toplevel text spinbox scrollbar scale radiobutton message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'HighlightColor':Color %[toplevel text spinbox scrollbar scale radiobutton message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'HighlightThickness':Pixel %[toplevel text spinbox scrollbar scale radiobutton message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'Image':Image %[radiobutton menubutton label checkbutton button]
				'Increment':FloatPoint %[spinbox]
				'IndicatorOn':Boolean %[radiobutton menubutton checkbutton]
				'InsertWidth':Pixel %[text spinbox entry canvas]
				'InvalidCommand':{ElementOf [None bell]} %[spinbox entry]
				'Jump':Boolean %[scrollbar]
				'Justify':{ElementOf [left center right]} %[spinbox radiobutton message menubutton label entry checkbutton button]
				'Label':VString %[scale]
				'LabelAnchor':{ElementOf [nw n ne en e es se e sw ws w wn]} %[labelframe]
				'LabelWidget':InvalidType %[labelframe]
				'Length':Pixel %[scale]
				'MaxUndo':Integer %[text]
				'Menu':Menu %[toplevel menubutton]
				'OffRelief':{ElementOf [raised sunken flat ridge solid groove]} %[radiobutton checkbutton]
				'OffTime':PosInteger %[text spinbox entry canvas]
				'Offset':RemoteType %[canvas]
				'OnTime':PosInteger %[text spinbox entry canvas]
				'OpaqueResize':InvalidType %[panedwindow]
				'Orient':{ElementOf [horizontal vertical]} %[scrollbar scale panedwindow]
				'OverRelief':{ElementOf [None raised sunken flat ridge solid groove]} %[radiobutton checkbutton button]
				'Pad':Pixel %[toplevel toplevel text text radiobutton radiobutton message message menubutton menubutton labelframe labelframe label label frame frame checkbutton checkbutton button button]
				'Pixel':Pixel
				'ReadonlyBackground':Color %[spinbox entry]
				'Relief':{ElementOf [raised sunken flat ridge solid groove]} %[toplevel text spinbox spinbox spinbox scrollbar scrollbar scale radiobutton panedwindow panedwindow message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'RepeatDelay':PosInteger %[spinbox scrollbar scale button]
				'RepeatInterval':PosInteger %[spinbox scrollbar scale button]
				'Resolution':Integer %[scale]
				'SashPad':Pixel %[panedwindow]
				'Screen':RemoteType %[toplevel]
				'ScrollCommand':InvalidType %[text text spinbox listbox listbox entry canvas canvas]
%  Undefined}
				'ScrollIncrement':Pixel %[canvas canvas]
				'ScrollRegion':fun{$ L} case L of q(I1 I2 I3 I4) then {Float.is I1} andthen {Float.is I2} andthen {Float.is I3} andthen {Float.is I4}
							[] !None then true
							else false end end#"None or a record q(I1 I2 I3 I4) where In are floats" %[canvas]
				'SelectImage':Image %[radiobutton checkbutton]
				'SelectMode':{ElementOf [single browse multiple extended]} %[listbox]
				'SetGrid':Boolean %[text listbox]
				'Show':VString %[entry]
				'ShowHandle':Boolean %[panedwindow]
				'SliderLength':Pixel %[scale]
				'SliderRelief':{ElementOf [raised sunken flat ridge solid groove]} %[scale]
				'Spacing':Pixel %[text text text]
				'State':{ElementOf [normal disabled]} %[text spinbox scale radiobutton menubutton listbox label entry checkbutton canvas button]
				'Tabs':RemoteType %[text]
				'TakeFocus':RemoteType %[toplevel text spinbox scrollbar scale radiobutton message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'Text':VString %[radiobutton message menubutton labelframe label checkbutton button]
				'TearOff':Boolean
				'TickInterval':FloatPoint %[scale]
				'To':FloatPoint %[spinbox scale]
				'Underline':Integer %[radiobutton menubutton label checkbutton button]
				'Undo':Boolean %[text]
				'Use':RemoteType %[toplevel]
				'Validate':{ElementOf [none focus focusin focusout key all]} %[spinbox entry]
				'ValidateCommand':RemoteType %[spinbox entry]
				'Value':InvalidType %[radiobutton checkbutton checkbutton]
				'Values':NoneListInt %[spinbox]
				'Variable':InvalidType %[spinbox scale radiobutton radiobutton message menubutton listbox label entry checkbutton checkbutton button]
				'Visual':RemoteType %[toplevel labelframe frame]
				'Width':RemoteType %[toplevel text spinbox scrollbar scale radiobutton panedwindow panedwindow message menubutton listbox labelframe label frame entry checkbutton canvas button]
				'Wrap':RemoteType %[text spinbox]
				'WrapLength':Pixel %[radiobutton menubutton label checkbutton button])
			       )

   fun{ObjectToRef O}
      if {Object.is O} then
	 {O.Manager getRef($)}
      else
	 O
      end
   end

   fun{RefToHandle O M}
      E={{M getManager($)} getEnv($)}
   in
      {{E get(global $)} E O}.handle
   end

   ISO8859toUTF8=NOOP
   fun{UTF8toISO8859 L}
      case L
      of F|Ls then
	 if F>=252 then
	    case Ls
	    of _|_|_|_|_|Lss then
	       &?|{UTF8toISO8859 Lss}
	    else &?|{UTF8toISO8859 Ls}
	    end
	 elseif F>=248 then
	    case Ls
	    of _|_|_|_|Lss then
	       &?|{UTF8toISO8859 Lss}
	    else &?|{UTF8toISO8859 Ls}
	    end
	 elseif F>=240 then
	    case Ls
	    of _|_|_|Lss then
	       &?|{UTF8toISO8859 Lss}
	    else &?|{UTF8toISO8859 Ls}
	    end
	 elseif F>=224 then
	    case Ls
	    of _|_|Lss then
	       &?|{UTF8toISO8859 Lss}
	    else &?|{UTF8toISO8859 Ls}
	    end
	 elseif F>=194 then
	    case Ls
	    of Z|Ls then
	       C=case F
		 of 195 then
		    (Z+64)
		 [] 194 then
		    Z
		 [] 197 then
		    {CondSelect
		     t(160:&ä
		       161:&ö
		       147:156
		       146:140
		       184:159) Z &?}
		 [] 203 then
		    {CondSelect
		     t(134:136
		       156:152
		      ) Z &?}
		 else &? end
	    in
	       if C>=32 andthen C=<255 then
		  C|{UTF8toISO8859 Ls}
	       else &?|{UTF8toISO8859 Ls} end
	    else
	       &?|nil
	    end
	 else
	    F|{UTF8toISO8859 Ls}
	 end
      else L end
   end

   !TkProxyMarshaller=tkproxymarshaller('Font':m(u2s:ObjectToRef) % u2s => user to store
					'Menu':m(u2s:ObjectToRef)
					'Bitmap':m(u2s:ObjectToRef)
					'Image':m(u2s:ObjectToRef)
					'SelectImage':m(u2s:ObjectToRef)
					'Show':m(u2s:ISO8859toUTF8
						 s2u:UTF8toISO8859)
					'Color':m(u2s:ColorToString
						  s2u:TkStringTo.color)
					'Background':m(u2s:ColorToString
						       s2u:TkStringTo.color)
					'DisabledBackground':m(u2s:ColorToString
							       s2u:TkStringTo.color)
					'DisabledForeground':m(u2s:ColorToString
							       s2u:TkStringTo.color)
					'Foreground':m(u2s:ColorToString
						       s2u:TkStringTo.color)
					'HighlightBackground':m(u2s:ColorToString
								s2u:TkStringTo.color)
					'HighlightColor':m(u2s:ColorToString
							   s2u:TkStringTo.color)
					'ReadonlyBackground':m(u2s:ColorToString
							       s2u:TkStringTo.color)
					'Text':m
					'Pixel':m
				       )

   !TkRenderMarshaller=tkrendermarshaller('Font':m(s2u:RefToHandle) % s2u => store to user
					  'Menu':m(s2u:fun{$ O M}
							  %% menus have to preserve widget hierarchy =>
							  %% each menu has to be defined uniquely each time its met
							  Manager={M getManager($)}
							  E={Manager createRemoteEnvironment($)}
							  {{Manager getWidget($)} setChildEnvironment(E unit)}
							  {E put(proxy O)}
						       in
							  {{Manager createRemoteHere(E render:$)} getWidget($)}.handle
						       end)
					  'Bitmap':m(s2u:RefToHandle)
					  'Image':m(s2u:RefToHandle)
					  'SelectImage':m(s2u:RefToHandle)
					  'Text':m(u2s:UTF8toISO8859
						   s2u:ISO8859toUTF8)
					  'Label':m(u2s:UTF8toISO8859
						    s2u:ISO8859toUTF8)
					  'Pixel':m(u2s:fun{$ S}
							   A B
							in
							   {List.takeDropWhile S
							    fun{$ C} C>=&0 andthen C=<&9 end A B}
							   if A==S then
							      {TkStringTo.float A}
							   else
							      {TkStringTo.float A}#B
							   end
							end)
					 )



   {Record.mapInd Data
    fun{$ T W}
       {Record.mapInd W
	fun{$ I E}
	   D=E.default
	   V=case T#I
	     of menubutton#padx then 4#p
	     [] menubutton#pady then 3#p
	     else try {String.toInt {VirtualString.toString D}} catch _ then
		     if D=='true' then true
		     elseif D=='false' then false
		     elseif D=='{}' then '' else D
		     end
		  end
	     end
	in
	   case {CheckType TkTypeChecker E.type V}
	   of remote then
	      V %#remote
	   [] invalid then
	      V %#unknownType
	   [] true then
	      V %#ok
	   [] false then
	      if {Int.is V} then
		 R
	      in
		 case V
		 of 0 then
		    if {CheckType TkTypeChecker E.type false}==true then
		       R=false %#ok
		    end
		 [] 1 then
		    if {CheckType TkTypeChecker E.type true}==true then
		       R=true %#ok
		    end
		 else skip end
		 if {IsFree R} then
		    V2=try {String.toFloat {VirtualString.toString D}} catch _ then
			  try {Int.toFloat V} catch _ then
			     unit
			  end
		       end
		 in
		    if V2\=unit then
		       if {CheckType TkTypeChecker E.type V2}==true then
			  R=V2 %#ok
		       end
		    end
		 end
		 if {IsFree R} then
%		    {Show T#I#V#{VirtualString.toAtom {TkTypeChecker.getTypeComment E.type}}}
		    V %#{VirtualString.toAtom {TkTypeChecker.getTypeComment E.type}}
		 else R end
	      else
%		 {Show T#I#V#{VirtualString.toAtom {TkTypeChecker.getTypeComment E.type}}}
		 V %#{VirtualString.toAtom {TkTypeChecker.getTypeComment E.type}}		       
	      end
	   end
	end}
    end}=TkDefaults

   SynonymD={Dictionary.new}
   {Record.forAllInd Data
    proc{$ T W}
       {Record.forAllInd W
	proc{$ I E}
	   {Dictionary.put SynonymD I I}
	   {ForAll E.synonym proc{$ V} {Dictionary.put SynonymD V I} end}
	end}
    end}
   {Dictionary.toRecord synonyms SynonymD}=Synonyms

   {Record.map Data
    fun{$ D}
       {Record.map D
	fun{$ E} E.type end}
    end}=TkParameters

\ifdef OPI
   
in skip end

\else

end

\endif

%{Browse {Dictionary.toRecord synonym Synonyms}}



%{Property.put 'print.width' 1000 Undefined}
%{Show {List.map Types fun{$ E Undefined} E.1 end Undefined} Undefined}

% {ForAll Types proc{$ E}
% 		 {System.showInfo "{TkTypeChecker.setLocalCheck '"#E.1#"' %"#{Value.toVirtualString E.2 1000 1000}}
% 		 {System.showInfo " Undefined}"}
% 	      end}

% {ForAll Types proc{$ E}
% 		 {System.showInfo "{TkMarshaller.register '"#E.1#"' %"#{TkTypeChecker.getTypeComment E.1}}
% 		 {System.showInfo " NOOP"}
% 		 {System.showInfo " NOOP}"}
% 	      end}

%['ActiveStyle' 'Anchor' 'Aspect' 'AutoSeparators' 'Background' 'BigIncrement' 'Bitmap' 'BorderWidth' 'Class' 'CloseEnough' 'Colormap' 'Command' 'Compound' 'Confine' 'Container' 'Cursor' 'Default' 'Digits' 'Direction' 'DisabledBackground' 'DisabledForeground' 'ExportSelection' 'Font' 'Foreground' 'Format' 'From' 'HandlePad' 'HandleSize' 'Height' 'HighlightBackground' 'HighlightColor' 'HighlightThickness' 'Image' 'Increment' 'IndicatorOn' 'InsertWidth' 'InvalidCommand' 'Jump' 'Justify' 'Label' 'LabelAnchor' 'LabelWidget' 'Length' 'MaxUndo' 'Menu' 'OffRelief' 'OffTime' 'Offset' 'OnTime' 'OpaqueResize' 'Orient' 'OverRelief' 'Pad' 'ReadonlyBackground' 'Relief' 'RepeatDelay' 'RepeatInterval' 'Resolution' 'SashPad' 'Screen' 'ScrollCommand' 'ScrollIncrement' 'ScrollRegion' 'SelectImage' 'SelectMode' 'SetGrid' 'Show' 'ShowHandle' 'ShowValue' 'SliderLength' 'SliderRelief' 'Spacing' 'State' 'Tabs' 'TakeFocus' 'Text' 'TickInterval' 'To' 'Underline' 'Undo' 'Use' 'Validate' 'ValidateCommand' 'Value' 'Values' 'Variable' 'Visual' 'Width' 'Wrap' 'WrapLength']

