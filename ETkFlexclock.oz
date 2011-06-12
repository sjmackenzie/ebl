%% Formating functions for displaying the time and date in several
%% textual formats
   


class FlexClockRender from TkRender
   attr
      current
   feat
      views
      tkviews
   meth init(M)

      
      fun{TwoPos I}
	 if I<10 then "0"#I else I end
      end

      fun{FmtTime T}
	 {TwoPos T.hour}#":"#{TwoPos T.min}
      end

      fun{FmtTimeS T}
	 {FmtTime T}#":"#{TwoPos T.sec}
      end

      fun{FmtDate T}
	 {TwoPos T.mDay}#"/"#{TwoPos T.mon+1}
      end

      fun{FmtDateY T}
	 {FmtDate T}#"/"#(1900+T.year)
      end

      fun{FmtDay T}
	 {List.nth ["Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"] T.wDay+1}
      end

      fun{FmtMonth T}
	 {List.nth ["January" "February" "March" "April" "May" "June" "July" "August"
		    "September" "October" "November" "December"] T.mon+1}
      end

      fun{IsLeap Year}
	 %% returns true if Year is a leap year.
	 if (Year mod 4)\=0 then false
	 elseif (Year mod 100)\=0 then true
	 else (Year mod 1000)\=0 end
      end

      fun{Diff R}
	 Year=R.year+1900
	 fun{Loop1 I Year}
	    if I<Year then
	       if {IsLeap I} then 2 else 1 end+{Loop1 I+1 Year}
	    else 0 end
	 end
	 Bis={IsLeap Year}
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

      fun{Calendar Redraw}
	 Old={NewCell r(yDay:0 year:0 mon:0)}
	 Cells={Array.new 1 7*6 unit}
	 fun{Loop I}
	    if I==7*6 then nil
	    else
	       H
	    in
	       {Array.put Cells I+1 H}
	       if (I mod 7)==0 then
		  newline|label(relief:flat
				bg:Color.white
				text:I
				glue:we handle:H)|{Loop I+1}
	       else
		  label(relief:flat
			bg:Color.white
			text:I
			glue:we handle:H)|{Loop I+1}
	       end
	    end
	 end
   
      in
	 proc{Redraw T}
	    O={Access Old}
	 in
	    if T.yDay==O.yDay andthen T.year==O.year andthen T.mon==O.mon then skip
	    else
	       {Assign Old T}
	       S={Diff T}
	       ML=if T.mon==1 then
		     if {IsLeap T.year+1900} then 29 else 28 end
		  else {List.nth [31 29 31 30 31 30 31 31 30 31 30 31] T.mon} end
	       proc{Loop I}
		  if I>7*6 then skip
		  else
		     H={Array.get Cells I}
		  in
		     if I=<S then
			{H set(text:"" state:disabled background:Color.white)}
		     elseif (I-S)=<ML then
			{H set(text:I-S state:normal background:Color.white)}
		     else
			{H set(text:"" state:disabled background:Color.white)}
		     end
		     {Loop I+1}
		  end
	       end
	    in
	       {Loop 1}
	    end
	 end
   
	 {Record.adjoin
	  {List.toTuple lr
	   {List.append {List.map ["Mo" "Tu" "We" "Th" "Fr" "Sa" "Su"]
			 fun{$ L} label(glue:nwe bg:Color.white text:L) end}
	    {Loop 0}}}
	  lr(glue:nswe bg:Color.white relief:raised borderwidth:2)}
      end

      PI2={Float.acos 0.0}

      fun{InitCanvas Canvas}
	 Ring Hour Min Sec
	 {Canvas create(oval [0.0 0.0 0.0 0.0] handle:Ring)}
	 {Canvas create(line [0.0 0.0 0.0 0.0] width:3 handle:Hour)}
	 {Canvas create(line [0.0 0.0 0.0 0.0] width:1 handle:Min)}
	 {Canvas create(line [0.0 0.0 0.0 0.0] width:1 handle:Sec)}
      in
	 r(ring:Ring hour:Hour min:Min sec:Sec)
      end

      proc{SetTime AC Time Width Height}
	 CM={Int.toFloat Time.min}/60.0
	 CH={Int.toFloat (Time.hour mod 12)}+12.0+CM/12.0
	 CS={Int.toFloat Time.sec}/60.0
	 S={Max {Min Width Height} 40.0}
	 S2=S/2.0
	 S23=S2*2.0/3.0
	 S25=S2*2.0/5.0
      in
	 {AC.ring setCoords([10.0 10.0 S-10.0 S-10.0])}
	 {AC.sec setCoords([S2 S2 
			    S2+S23*{Float.cos CS*4.0*PI2-PI2}
			    S2+S23*{Float.sin CS*4.0*PI2-PI2}])}
	 {AC.min setCoords([S2 S2 
			    S2+S23*{Float.cos CM*4.0*PI2-PI2} 
			    S2+S23*{Float.sin CM*4.0*PI2-PI2}])}
	 {AC.hour setCoords([S2 S2 
			     S2+S25*{Float.cos CH*4.0*PI2-PI2} 
			     S2+S25*{Float.sin CH*4.0*PI2-PI2}])}
      end

   
      fun{Analog Redraw}
	 Items
	 C
	 thread
	    {Wait C}
	    Items={InitCanvas C}
	 end
      in
	 proc{Redraw T}
	    {SetTime Items T {Int.toFloat {C winfo(width:$)}} {Int.toFloat {C winfo(height:$)}}}
	 end
	 canvas(bg:Color.white highlightthickness:0 glue:nswe handle:C)
      end

      H1 H2 H3 H4 H5 H6 H7 H8 H9 H10 H11 H12 H13 H14 H15 H16
      L1 L2 L3 L4 L5 L6 L7 L8 L9
      A1 A2 A3 A4 A5 A6 A7 A8 A9 A10
      C1 C2
   
      ViewList=[r(refresh:proc{$ T} {H1 set(text:{FmtTime T})} end
		  desc:label(handle:H1 bg:Color.white)
		  area:40#10)
		r(refresh:proc{$ T} {H2 set(text:{FmtTimeS T})} end
		  desc:label(handle:H2 bg:Color.white)
		  area:80#10)
		r(refresh:proc{$ T} {H3 set(text:{FmtTime T}#'\n'#{FmtDate T})} end
		  desc:label(handle:H3 bg:Color.white)
		  area:40#30)
		r(refresh:proc{$ T} {H4 set(text:{FmtTimeS T}#'\n'#{FmtDateY T})} end
		  desc:label(handle:H4 bg:Color.white)
		  area:80#30)
		r(refresh:proc{$ T} {H5 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#{FmtDateY T})} end
		  desc:label(handle:H5 bg:Color.white)
		  area:130#30)
		r(refresh:proc{$ T} {H6 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#
					    T.mDay#" "#{FmtMonth T}#" "#(1900+T.year))} end
		  desc:label(handle:H6 bg:Color.white)
		  area:180#30)
		r(refresh:proc{$ T} {A1 T} end
		  desc:td(handle:H7 {Analog A1} bg:Color.white)
		  area:60#60)
		r(refresh:proc{$ T} {L1 set(text:{FmtTime T}#"\n"#{FmtDate T})} {A2 T} end
		  desc:lr(handle:H8 glue:nswe {Analog A2} label(handle:L1 bg:Color.white) bg:Color.white)
		  area:100#60)
		r(refresh:proc{$ T} {L2 set(text:{FmtTimeS T}#"\n"#{FmtDateY T})} {A3 T} end
		  desc:lr(handle:H9 {Analog A3} label(handle:L2 bg:Color.white) bg:Color.white)
		  area:120#60)
		r(refresh:proc{$ T} {L3 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#{FmtDateY T})} {A4 T} end
		  desc:lr(handle:H10 {Analog A4} label(handle:L3 bg:Color.white) bg:Color.white)
		  area:180#60)
		r(refresh:proc{$ T} {L4 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#
					    T.mDay#" "#{FmtMonth T}#" "#(1900+T.year))} {A5 T} end
		  desc:lr(handle:H11 {Analog A5} label(handle:L4 bg:Color.white) bg:Color.white)
		  area:250#60)
		r(refresh:proc{$ T} {L5 set(text:{FmtTimeS T}#'\n'#{FmtDateY T})} {A6 T} end
		  desc:td(handle:H12 {Analog A6} label(handle:L5 bg:Color.white) bg:Color.white)
		  area:100#100)
		r(refresh:proc{$ T} {L6 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#{FmtDateY T})} {A7 T} end
		  desc:td(handle:H13 {Analog A7} label(handle:L6 bg:Color.white) bg:Color.white)
		  area:130#100)
		r(refresh:proc{$ T} {L7 set(text:{FmtTimeS T}#'\n'#{FmtDay T}#", "#
					    T.mDay#" "#{FmtMonth T}#" "#(1900+T.year))} {A8 T} end
		  desc:td(handle:H14 {Analog A8} label(handle:L7 bg:Color.white) bg:Color.white)
		  area:180#100)
		r(refresh:proc{$ T} {L8 set(text:{FmtTimeS T}#"\n"#
					    {FmtDay T}#", "#T.mDay#" "#{FmtMonth T}#" "#(1900+T.year))}
			     {A9 T} {C1 T}
			  end
		  desc:lr(handle:H15 glue:nswe {Analog A9} td(label(handle:L8 bg:Color.white) {Calendar C1} bg:Color.white) bg:Color.white)
		  area:280#160)
		r(refresh:proc{$ T} {L9 set(text:{FmtTimeS T}#"\n"#
					    {FmtDay T}#", "#T.mDay#" "#{FmtMonth T}#" "#(1900+T.year))}
			     {A10 T} {C2 T}
			  end
		  desc:td(handle:H16 glue:nswe {Analog A10} label(handle:L9 bg:Color.white) {Calendar C2} bg:Color.white)
		  area:180#230)
	       ]
   in
      TkRender,init(M)
      self.handle={New (self.tk).frame tkInit(parent:self.parent.handle bg:white)}
      {(self.tk).send grid(rowconfigure self.handle 0 weight:1)}
      {(self.tk).send grid(columnconfigure self.handle 0 weight:1)}
      self.tkviews={Dictionary.new}
      current<-unit
      self.views={List.mapInd ViewList
		  fun{$ I R}
		     Width#Height=R.area
		     UI
		  in
		     UI={self.manager build({Record.adjoinAt R.desc name top} $)}
		     {self.manager displayHere({UI.top getRef($)} I)}
		     Width#Height#I#R.refresh
		  end}
      {self.handle tkBind(event:'<Configure>'
			  action:self#place)}
      {self initState}
   end
   meth place
      WW={(self.tk).returnInt winfo(width self.handle)}
      WH={(self.tk).returnInt winfo(height self.handle)}
      fun{Select Views Max#CH#CR}
	 case Views
	 of W#H#Handle#Refresh|R then
	    This=(W-WW)*(W-WW)+(H-WH)*(H-WH)
	 in
	    if W<WW andthen H<WH andthen
	       (Max==inf orelse This<Max) then
	       {Select R This#Handle#Refresh}
	    else
	       {Select R Max#CH#CR}
	    end
	 else CH#CR end	 
      end
      Top#Ref={Select self.views inf#self.views.1.3#self.views.1.4}
      Han={Dictionary.condGet self.tkviews Top unit}
   in
      if Han\=unit andthen @current\=unit andthen Han==@current.1 then
	 {self tickClock}
      elseif Han\=unit then
	 if @current\=unit then
	    {(self.tk).send grid(forget @current.1)}
	 end
	 current<-Han#Ref
	 {self tickClock}
	 {(self.tk).send grid(Han row:0 column:0 sticky:nswe)}
      end
   end
   meth importHere(Ob I)
      {Dictionary.put self.tkviews I Ob.handle}
   end
   meth tickClock
      if @current\=unit then
	 try
	    {@current.2 {self.manager get(time time $)}}
	 catch _ then skip end
      end
   end
   meth set(I K V)
      case I#K of time#time then
	 {self tickClock}
      end
   end
end

class FlexClockProxy from TkProxy
   feat ThId
      widgetName:flexclock
   meth init(...)=M
      TkProxy,M
      {{self.Manager getStore(time $)} setTypeChecker(r('...':fun{$ _} true end#""))}
      {self.Manager set(time time {OS.localTime})}
      thread
	 self.ThId={Thread.this}
	 proc{Loop}
	    {self.Manager set(time time {OS.localTime})}
	    {Delay 1000}
	    {Loop}
	 end
      in
	 {Loop}
      end
   end
   meth destroy
      try {Thread.terminate self.ThId} catch _ then skip end
      TkProxy,destroy
   end
end

FlexClockWidget={CreateWidgetClass
		 flexclock(proxy:FlexClockProxy
			   synonyms:Synonyms
			   defaultRenderClass:FlexClockRender
			   rendererClass:TCLTK)}

{QTk.register FlexClockWidget QTkBuild}