class NavigatorRenderFlatVersion from TkRender
   attr
      panes
   feat
      frames
   meth createHandle
      self.handle={New (self.tk).frame tkInit(parent:self.parent.handle)}
   end
   meth init(M)
      TkRender,init(M)
      {self createHandle}
      panes<-nil
      self.frames={Dictionary.new}
      {self initState}
      {self set(panes panes {self.manager get(panes panes $)})}
   end
   meth configureItem(Ob K V)
      {TkExec self.tk [Ob.handle configure "-"#K V]}
   end
   meth set(I K V)
      case I#K
      of panes#panes then
	 panes<-V
      else
	 Ob={Dictionary.condGet self.frames I unit}
      in
	 if Ob==unit then
	    TkRender,set(I K V)
	 else
	    {self configureItem(Ob K V)}
	    {TkExec self.tk [self.handle paneconfigure Ob.handle "-"#K V]}
	 end
      end
   end
   meth importHereBefore(Ob F)
      {TkExec self.tk [pack(Ob.handle before:F.handle fill:both padx:0 pady:0 ipadx:1 ipady:1 expand:true side:left)]}
   end
   meth importHereAtEnd(Ob)
      {TkExec self.tk [pack(Ob.handle fill:both padx:0 pady:0 ipadx:1 ipady:1 expand:true side:left)]}
   end
   meth importHereAfter(Ob F)
      {TkExec self.tk [pack(Ob.handle after:F.handle fill:both padx:0 pady:0 ipadx:1 ipady:1 expand:true side:left)]}
   end

   meth importHere(Ob I)
      {Dictionary.put self.frames I Ob}
      %% search @panes to find the correct command to insert Ob
      A B
   in
      {List.takeDropWhile @panes fun{$ L} L\=I end A B}
      if B==nil then
	 raise unknownChild end
      else
	 proc{Loop2 L}
	    case L of Ls|Lz then
	       F={Dictionary.condGet self.frames Ls unit}
	    in
	       if F\=unit then
		  {self importHereBefore(Ob F)}
	       else
		  {Loop2 Lz}
	       end
	    else
	       {self importHereAtEnd(Ob)}
	    end
	 end
	 proc{Loop1 L}
	    case L of Ls|Lz then
	       F={Dictionary.condGet self.frames Ls unit}
	    in
	       if F\=unit then
		  {self importHereAfter(Ob F)}
	       else
		  {Loop1 Lz}
	       end
	    else {Loop2 {Reverse A}} end
	 end
      in
	 {Loop1 B.2} 
      end
   end
   meth forgetItem(Ob)
      {TkExec self.tk [pack forget Ob.handle]}
   end
   meth remove(Ob)
      {ForAll {Dictionary.entries self.frames}
       proc{$ K#V} if V==Ob then {Dictionary.remove self.frames K} end end}
      {self forgetItem(Ob)}
   end
   
end

class NavigatorRenderDefaultVersion from NavigatorRenderFlatVersion
   feat
      left right tostart toend ihandle iframe
   attr
      current
   meth createHandle
      current<-unit
      self.ihandle={New (self.tk).frame tkInit(parent:self.parent.handle)}
      self.handle={New (self.tk).frame tkInit(parent:self.ihandle relief:raised)}
      self.iframe={New (self.tk).frame tkInit(parent:self.ihandle relief:sunken)}
      self.left={New (self.tk).button tkInit(parent:self.iframe
				      state:disabled
				      text:"  <  "
				      action:self#left)}
      self.right={New (self.tk).button tkInit(parent:self.iframe
				       state:disabled
				       text:"  >  "
				       action:self#right)}
      self.tostart={New (self.tk).button tkInit(parent:self.iframe
					 state:disabled
					 text:"  |<  "
					 action:self#tostart)}
      self.toend={New (self.tk).button tkInit(parent:self.iframe
				       state:disabled
				       text:"  >|  "
				       action:self#toend)}
      {TkExec self.tk [grid(configure self.ihandle column:0 row:0 sticky:nswe padx:0 pady:0)]}
      {TkExec self.tk [grid(configure self.iframe column:0 row:1 sticky:swe padx:0 pady:0)]}
      {TkExec self.tk [grid(rowconfigure self.ihandle 0 weight:1)]}
      {TkExec self.tk [grid(columnconfigure self.ihandle 0 weight:1)]}
      {TkExec self.tk [grid(rowconfigure self.handle 0 weight:1)]}
      {TkExec self.tk [grid(columnconfigure self.handle 0 weight:1)]}
%      {TkExec self.tk [pack(self.left self.right side:left)]}
      {TkExec self.tk [grid(configure self.tostart column:0 row:0)]}
      {TkExec self.tk [grid(configure self.left column:1 row:0)]}
      {TkExec self.tk [grid(configure self.right column:2 row:0)]}
      {TkExec self.tk [grid(configure self.toend column:3 row:0)]}
   end
   meth setCurrent(C)
      if @current\=unit then
	 {TkExec self.tk [grid remove @current.handle]}
      end
      current<-C
      {TkExec self.tk [grid(configure C.handle row:0 column:0 sticky:nswe padx:0 pady:0)]}
      {self checkArrows}
   end
   meth importHereAtEnd(Ob)
      if @current==unit then
	 {self setCurrent(Ob)}
      end
   end
   meth importHereBefore(Ob F)
      if @current==F then
	 {self setCurrent(Ob)}
      end
      {self checkArrows}
   end
   meth importHereAfter(Ob F)
      {self checkArrows}
   end
   meth getChildren($)
      fun{Loop L}
	 case L of nil then nil else
	    Ob={Dictionary.condGet self.frames L.1 unit}
	 in
	    if Ob==unit then {Loop L.2}
	    else Ob|{Loop L.2}
	    end
	 end
      end
   in
      {Loop {Reverse @panes}}
   end
   meth checkArrows
      Children={self getChildren($)}
   in
      if Children==nil then
	 {self.left tk(configure state:disabled)}
	 {self.right tk(configure state:disabled)}
      else
	 if {List.nth Children 1}==@current then
	    {self.left tk(configure state:disabled)}
	    {self.tostart tk(configure state:disabled)}
	 else
	    {self.left tk(configure state:normal)}
	    {self.tostart tk(configure state:normal)}
	 end
	 if {List.last Children}==@current then
	    {self.right tk(configure state:disabled)}
	    {self.toend tk(configure state:disabled)}
	 else
	    {self.right tk(configure state:normal)}
	    {self.toend tk(configure state:normal)}
	 end	    
      end
   end
   meth left
      C=@current
      proc{Loop L}
	 case L of N|!C|Ls then
	    {self setCurrent(N)}
	 [] nil then skip
	 else {Loop L.2} end
      end
   in
      {Loop {self getChildren($)}}
      {self checkArrows}
   end
   meth right
      C=@current
      proc{Loop L}
	 case L of !C|N|Ls then
	    {self setCurrent(N)}
	 [] nil then skip
	 else {Loop L.2} end
      end
   in
      {Loop {self getChildren($)}}
      {self checkArrows}
   end
   meth tostart
      C={self getChildren($)}
   in
      if C\=nil andthen C.1\=@current then
	 {self setCurrent(C.1)}
      end
      {self checkArrows}
   end
   meth toend
      C={self getChildren($)}
   in
      if C\=nil andthen {List.last C}\=@current then
	 {self setCurrent({List.last C})}
      end
      {self checkArrows}      
   end
   meth remove(Ob)
      {self forgetItem(Ob)}
      NavigatorRenderFlatVersion,remove(Ob)
   end
   meth forgetItem(Ob)
      if Ob==@current then
	 {self left}
	 if Ob==@current then
	    {self right}
	    if Ob==@current then
	       {TkExec self.tk [grid remove @current.handle]}
	       current<-unit
	    end
	 end
      end
      {self checkArrows}
   end
   meth destroy
      NavigatorRenderFlatVersion,destroy
      try
	 {self.ihandle tkClose}
      catch _ then skip end
   end
end


class NavigatorRenderPanedVersion from NavigatorRenderFlatVersion
   meth createHandle
      C={(self.tk).newWidgetClass noCommand panedwindow}
   in
      self.handle={New C tkInit(parent:self.parent.handle)}
   end
   meth configureItem(Ob K V)
      {TkExec self.tk [self.handle paneconfigure Ob.handle "-"#K V]}
   end
   meth importHereBefore(Ob F)
      {self.handle tk(add Ob.handle
		      before:F.handle
		      height:'' width:''
		      padx:0 pady:0 sticky:nswe)}
   end
   meth importHereAtEnd(Ob)
      {self.handle tk(add Ob.handle
		      height:'' width:''
		      padx:0 pady:0 sticky:nswe)}
   end
   meth importHereAfter(Ob F)
      {self.handle tk(add Ob.handle
		      after:F.handle
		      height:'' width:''
		      padx:0 pady:0 sticky:nswe)}
   end
   meth forgetItem(Ob)
      {self.handle tk(forget Ob.handle)}
   end
end

class SimpleNavigatorItem from TkProxy
   feat
      Parent Id
   attr
      Child
   meth init(P I)
      self.Parent=P
      self.Manager=P.Manager
      self.Id=I
      Child<-unit
      self.Store={self.Manager getStore(self.Id $)}
      {self.Store setParametersType(t(minsize:'Pixel'
				      padx:'Pixel'
				      pady:'Pixel'
				      sticky:'Sticky'))}
      {self.Store setTypeChecker(t('Pixel':TkTypeChecker.'Pixel'
				   'Sticky':fun{$ C} {Atom.is C} andthen
					       (C=='' orelse
						{List.all {VirtualString.toString C}
						 fun{$ A} {List.member A [&n &s &w &e]} end})
					    end))}
      {self.Store setDefaults(t(minsize:0.0
				padx:0.0
				pady:0.0
				sticky:''))}
   end
   meth display(Widget)
      Ref WId
   in
      Ref=if {Object.is Widget} then {Widget.Manager getRef($)}
	  else Widget end
      if @Child\=unit then
	 {self.Manager dropClient(@Child)}
      end
      {self.Manager importHere(Ref self.Id id:WId)}
      Child<-WId
   end
   meth destroy
      if @Child\=unit then
	 {self.Manager dropClient(@Child)}
      end      
      {self.Parent Destroy(self.Id)}
   end
end

NavigatorPanedwindowItem={AddMultiSetGetSupport SimplePanedwindowItem}

class NavigatorProxy from TkProxy
   feat widgetName:navigator
      PaneItems
   attr panes
   prop locking
   meth init(...)=M
      lock
	 panes<-nil
	 TkProxy,M
	 {self.Store setProxyMarshaller(TkProxyMarshaller)}
	 {self.Store setRenderMarshaller(TkRenderMarshaller)}
	 {self.Store setTypeChecker(TkTypeChecker)}
	 {self.Store setParametersType(TkParameters.frame)}
	 {self.Store setDefaults(TkDefaults.frame)}
	 {{self.Manager getStore(panes $)} setTypeChecker(t('...':TkTypeChecker.'Any'))}
	 {self.Manager set(panes panes nil)}
	 self.PaneItems={Dictionary.new}
      end
   end
   meth addPane(R)
      lock
	 Id={NewName}
	 O N
      in
	 O=panes<-N
	 N=Id|O
	 {self.Manager set(panes panes N)}
	 R={New PanedwindowItem init(self Id)}
	 {Dictionary.put self.PaneItems Id R}
      end
   end
   meth getPanes($)
      lock
	 O=@panes
      in
	 {List.map O fun{$ I}
			{Dictionary.get self.PaneItems I}
		     end}
      end
   end
   meth !Destroy(Id)
      lock
	 O N
      in
	 O=panes<-N
	 N={List.subtract O Id}
	 {Dictionary.remove self.PaneItems Id}
	 {self.Manager set(panes panes N)}
      end
   end
end

NavigatorWidget={CreateWidgetClass
		 navigator(proxy:NavigatorProxy
			   synonyms:Synonyms
			   defaultRenderClass:NavigatorRenderDefaultVersion
			   renderers:r(flat:NavigatorRenderFlatVersion
				       paned:NavigatorRenderPanedVersion)
			   rendererClass:TCLTK
			  )}

{QTk.register NavigatorWidget
 proc{$ Env}
    A B
    {Record.partitionInd Env.desc fun{$ I _} {Int.is I} end A B}
 in
    {Record.forAll A
     proc{$ I}
	R
	SH={Env.build I}
     in
	{Env.handle addPane(R)}
	{R display(SH)}
     end}
    {QTkBuild {Record.adjoinAt Env desc B}}
 end}
