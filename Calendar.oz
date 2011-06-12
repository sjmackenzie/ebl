%declare 
%[ETk EBL]={Module.link ["ETk.ozf" "EBL.ozf"]}

functor
import
   ETk at 'ETk.ozf'
   Pickle
   OS
   Application
   System
   Open
   
define
   QTk=ETk.etk


   Data={Dictionary.new}

   try
      L={Pickle.load "calendar.dat"}
   in
      {Record.forAllInd L
       proc{$ K V}
	  {Dictionary.put Data K V}
       end}
   catch _ then skip end

   proc{Save}
      try
	 {Pickle.save {Dictionary.toRecord l Data} "calendar.dat"}
      catch _ then skip end
   end

   proc{Store}
      K={DateToKey {Access Current}}
   in
      {Dictionary.put Data K
       {Record.filter
	{List.toTuple p
	 {List.map EntriesHandle
	  fun{$ H}
	     {H get(text:$)}
	  end}}
	fun{$ V} V\="" end}}
      {Save}
   end

   fun{DateToKey D}
      {VirtualString.toAtom D.mDay#"/"#D.mon#"/"#D.year}
   end

%{Dictionary.put Data {DateToKey {OS.localTime}} p(1:"Test")}

   fun{IsBis Year}
      if (Year mod 4)\=0 then false
      elseif (Year mod 100)\=0 then true
      else (Year mod 1000)\=0 end
   end

   fun{Diff R}
      Year=R.year+1900
      fun{Loop1 I Year}
	 if I<Year then
	    if {IsBis I} then 2 else 1 end+{Loop1 I+1 Year}
	 else 0 end
      end
      Bis={IsBis Year}
      fun{Loop2 I Month}
	 if I<Month then
	    if I==1 then
	       if Bis then 1+{Loop2 I+1 Month}
	       else {Loop2 I+1 Month} end
	    elseif I mod 2==0 then
	       3+{Loop2 I+1 Month}
	    else
	       2+{Loop2 I+1 Month}
	    end
	 else 0 end
      end
   in
      ({Loop2 0 R.mon}+{Loop1 1900 R.year+1900}) mod 7
   end

   Cells={Array.new 1 7*6 unit}

   proc{Select N}
      {Store}
      S={Diff {Access Current}}
   in
      {Assign Current {Record.adjoinAt {Access Current}
		       mDay N-S}}
      {Refresh}
   end

   fun{Loop I}
      if I==7*6 then nil
      else
	 H
      in
	 {Array.put Cells I+1 H}
	 if (I mod 7)==0 then
	    newline|button(relief:flat
			   action:proc{$} {Select I+1} end
			   glue:we handle:H)|{Loop I+1}
	 else
	    button(relief:flat
		   action:proc{$} {Select I+1} end
		   glue:we handle:H)|{Loop I+1}
	 end
      end
   end


   Desc={Record.adjoin
	 {List.toTuple lr
	  {List.append {List.map ["Mo" "Tu" "We" "Th" "Fr" "Sa" "Su"]
			fun{$ L} label(glue:nwe text:L) end}
	   {Loop 0}}}
	 lr(glue:nswe name:calendar relief:raised borderwidth:2)}

   Current={NewCell {OS.localTime}}

   proc{Refresh}
      C={Access Current}
   in
      {SetMonth C}
      {Calendar.current set(text:(C.mon+1)#"/"#(C.year+1900))}
      {List.forAllInd EntriesHandle
       proc{$ I H}
	  {H set(text:{CondSelect {Dictionary.condGet Data {DateToKey C} p} I ""})}
       end}
   end

   proc{Left}
      {Store}
      C={Access Current}
   in
      if C.mon==0 then
	 {Assign Current r(year:C.year-1
			   mDay:1
			   mon:11)}
      else
	 {Assign Current r(year:C.year
			   mDay:1
			   mon:C.mon-1)}
      end
      {Refresh}
   end

   proc{Right}
      {Store}
      C={Access Current}
   in
      if C.mon==11 then
	 {Assign Current r(year:C.year+1
			   mDay:1
			   mon:0)}
      else
	 {Assign Current r(year:C.year
			   mDay:1
			   mon:C.mon+1)}
      end
      {Refresh}
   end

   proc{Restore}
      {Calendar restoreInitialGeometry}
   end

   EntriesHandle
   Entries
   local
      fun{Loop I}
	 H
      in
	 H#[label(text:if I<10 then "0" else "" end#I#":00" glue:w)
	    entry(glue:we handle:H)
	    newline]|if I<18 then {Loop I+1} else nil end
      end
      A={Loop 7}
   in
      EntriesHandle={List.map A fun{$ H#_} H end}
      Entries={Record.adjoin {List.toTuple lr {List.flatten {List.map A fun{$ _#D} D end}}}
	       lr(glue:we name:entries relief:raised borderwidth:2)}
   end

% Entries=lr(glue:we name:entries relief:raised borderwidth:2
% 	   label(text:"07:00" glue:w) entry(glue:we) newline
% 	   label(text:"08:00" glue:w) entry(glue:we) newline
% 	   label(text:"09:00" glue:w) entry(glue:we) newline
% 	   label(text:"10:00" glue:w) entry(glue:we) newline
% 	   label(text:"11:00" glue:w) entry(glue:we) newline
% 	   label(text:"12:00" glue:w) entry(glue:we) newline
% 	   label(text:"13:00" glue:w) entry(glue:we) newline
% 	   label(text:"14:00" glue:w) entry(glue:we) newline
% 	   label(text:"15:00" glue:w) entry(glue:we) newline
% 	   label(text:"16:00" glue:w) entry(glue:we) newline
% 	   label(text:"17:00" glue:w) entry(glue:we) newline
% 	   label(text:"18:00" glue:w) entry(glue:we))
	   

   Calendar={QTk.build window(name:top
			      action:proc{$}
					{Store}
					{Thread.terminate ClockThId}
					{Pu.close}
					{Calendar destroyAll}
					{Application.exit 0}
				     end
			      td(glue:nswe
				 button(glue:n
					text:"Restore All Widgets"
					action:Restore)
				 lr(glue:nswe
				    td(glue:nswe
				       canvas(name:clock background:QTk.color.white width:100 height:100 relief:sunken borderwidth:1)
				       Desc
				       name:shareleft
				      )
				    Entries)
				 lr(glue:swe
				    button(name:left text:"<<" action:Left)
				    label(name:current)
				    button(name:right text:">>" action:Right))))}

   BackgroundColor

   proc{SetMonth D}
      S={Diff D}
      ML=if D.mon==1 then
	    if {IsBis D.year+1900} then 29 else 28 end
	 elseif D.mon mod 2==0 then
	    31 else 30 end
      proc{Loop I}
	 if I>7*6 then skip
	 else
	    H={Array.get Cells I}
	 in
	    if I=<S then
	       {H set(text:"" state:disabled background:BackgroundColor)}
	    elseif (I-S)=<ML then
	       {H set(text:I-S state:normal background:if (I-S)==D.mDay then
							  QTk.color.red
						       elseif {Dictionary.condGet Data {DateToKey {Record.adjoinAt D mDay I-S}} p}==p then
							  BackgroundColor
						       else
							  QTk.color.blue
						       end)}
	    else
	       {H set(text:"" state:disabled background:BackgroundColor)}
	    end
	    {Loop I+1}
	 end
      end
   in
      {Loop 1}
   end

   BackgroundColor={Calendar.calendar get(background:$)}
   {Refresh}


%{Calendar.clock create(oval [10.0 10.0 90.0 90.0])}
   PI2={Float.acos 0.0}

   local
      proc{Loop I}
	 T={Int.toFloat I}/12.0
      in
	 {Calendar.clock create(oval [50.0+39.0*{Float.cos T*4.0*PI2-PI2}
				      50.0+39.0*{Float.sin T*4.0*PI2-PI2}
				      50.0+41.0*{Float.cos T*4.0*PI2-PI2}
				      50.0+41.0*{Float.sin T*4.0*PI2-PI2}
				     ])}
	 if I<11 then {Loop I+1} end
      end
   in
      {Loop 0}
   end
   Minutes={Calendar.clock create(line [45.0 45.0 10.0 10.0] width:3 handle:$)}
   Hours={Calendar.clock create(line [45.0 45.0 10.0 10.0] width:3 handle:$)}
   Seconds={Calendar.clock create(line [45.0 45.0 10.0 10.0] width:1 handle:$)}
   Rect={Calendar.clock create(rectangle [20.0 60.0 80.0 70.0]
			       stipple:QTk.bitmap.gray75
			       outline:QTk.color.white fill:QTk.color.white handle:$)}
   TTime={Calendar.clock create(text [50.0 65.0]
				text:"00:00:00" handle:$)}
   {Rect setCoords({TTime bbox($)})}
   ClockThId
   thread
      fun{Two I}
	 if I>=10 then I else "0"#I end
      end
      proc{Loop}
	 T={OS.localTime}
	 CM={Int.toFloat T.min}/60.0
	 CH={Int.toFloat (T.hour mod 12)}/12.0+CM/12.0
	 CS={Int.toFloat T.sec}/60.0
      in
	 {Seconds setCoords([50.0 50.0 50.0+37.0*{Float.cos CS*4.0*PI2-PI2} 50.0+37.0*{Float.sin CS*4.0*PI2-PI2}])}
	 {Minutes setCoords([50.0 50.0 50.0+37.0*{Float.cos CM*4.0*PI2-PI2} 50.0+37.0*{Float.sin CM*4.0*PI2-PI2}])}
	 {Hours setCoords([50.0 50.0 50.0+20.0*{Float.cos CH*4.0*PI2-PI2} 50.0+20.0*{Float.sin CH*4.0*PI2-PI2}])}
	 {TTime set(text:{Two T.hour}#":"#{Two T.min}#":"#{Two T.sec})}
	 {Delay 1000}
	 {Loop}
      end
   in
      ClockThId={Thread.this}
      {Loop}
   end
   Pu={ETk.newPublisher 15632}
%{Show {OS.localTime}} {Show if 5<10 then 5 else "0"#5 end}
% {Calendar.top bind(event:lostWidget args:[ref placementInstructions]
% 		   action:proc{$ R P}
% 			     {Calendar.top destroy}
% 		       end)}
   {ForAll {Calendar getAllNames($)}
    proc{$ N}
       try
	  Ref={Calendar.N getRef($)}
       in
	  {Pu.subscribe N Ref N}
       catch _ then skip end
    end}
   {Calendar sync}
   {Calendar.top show}

%   {System.show {Calendar.shareleft getRef($)}}
   fun{BytesToString L}
      case L of X|Xs then
	 Low High
      in
	 Low=X div 16      % AAAABBBB => AAAA
	 High=(X-(Low*16)) % AAAABBBB => BBBB
	 (Low+64)|(High+64)|{BytesToString Xs}
      else nil end
   end

   fun{StringToBytes L}
      case L of Low|High|Xs then
	 (Low-64)*16+(High-64)|{StringToBytes Xs}
      else nil end
   end

   class TextFile from Open.text Open.file end

   {System.showInfo {OS.getCWD}}

   File={New TextFile init(name:"Calendar.cap"
			   flags:[create truncate write text])}
   {File putS("left="#{BytesToString {VirtualString.toString {Calendar.shareleft getRef($)}}})}
   {File putS("right="#{BytesToString {VirtualString.toString {Calendar.entries getRef($)}}})}
   {File close}
   
%{Browse {Calendar.calendar get(background:$)}}
end
