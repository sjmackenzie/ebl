class PanedwindowRender from TkRender
   attr
      panes
   feat
      frames
   meth init(M)
      TkRender,init(M)
      C={(self.tk).newWidgetClass noCommand panedwindow}
   in
      self.handle={New C tkInit(parent:self.parent.handle)}
      panes<-nil
      self.frames={Dictionary.new}
      {self initState}
      {self set(panes panes {self.manager get(panes panes $)})}
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
	    {TkExec self.tk [self.handle paneconfigure Ob.handle "-"#K V]}
	 end
      end
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
		  {self.handle tk(add Ob.handle
				  before:F.handle
				  height:'' width:''
				  padx:0 pady:0 sticky:nswe)}
	       else
		  {Loop2 Lz}
	       end
	    else
	       {self.handle tk(add Ob.handle
			       height:'' width:''
			       padx:0 pady:0 sticky:nswe)}
	    end
	 end
	 proc{Loop1 L}
	    case L of Ls|Lz then
	       F={Dictionary.condGet self.frames Ls unit}
	    in
	       if F\=unit then
		  {self.handle tk(add Ob.handle
				  after:F.handle
				  height:'' width:''
				  padx:0 pady:0 sticky:nswe)}
	       else
		  {Loop1 Lz}
	       end
	    else {Loop2 {Reverse A}} end
	 end
      in
	 {Loop1 B.2} 
      end
   end
   meth remove(Ob)
      {ForAll {Dictionary.entries self.frames}
       proc{$ K#V} if V==Ob then {Dictionary.remove self.frames K} end end}
      {self.handle tk(forget Ob.handle)}
   end
   meth ask(Q R)
      case Q of gs(Id) then
	 TclId={(self.tk).getTclName {Dictionary.get self.frames Id}.handle}
	 fun{Loop I L}
	    if L==nil then
	       raise noSashForLastElement end
	       unit
	    elseif L.1==TclId andthen L.2\=nil then
	       R={self.handle tkReturnListInt(sash(coord I) $)}
	    in
	       if {self.handle tkReturn(cget("-orient") $)}=="horizontal" then
		  R.1 else R.2.1
	       end
	    else
	       {Loop I+1 L.2}
	    end
	 end
      in
	 R={Loop 0 {self.handle tkReturnList(panes $)}}	 
      else
	 TkRender,ask(Q R)
      end
   end
   meth send(M)
      case M
      of sh(Id H) then
	 {TkExec self.tk [self.handle paneconfigure {Dictionary.get self.frames Id}.handle "-height" H]}
      [] sw(Id W) then
	 {TkExec self.tk [self.handle paneconfigure {Dictionary.get self.frames Id}.handle "-width" W]}
      [] ss(Id W) then
	 TclId={(self.tk).getTclName {Dictionary.get self.frames Id}.handle}
	 proc{Loop I L}
	    if L==nil then skip
	    elseif L.1==TclId andthen L.2\=nil then
	       {self.handle tk(sash place I W W)}
	    else
	       {Loop I+1 L.2}
	    end
	 end
      in
	 {Loop 0 {self.handle tkReturnList(panes $)}}
      else
	 TkRender,send(M)
      end
   end
end

Destroy={NewName}

class SimplePanedwindowItem from TkProxy
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
   meth setHeight(H)
      {self.Manager send(sh(self.Id H))}
   end
   meth setWidth(W)
      {self.Manager send(sw(self.Id W))}
   end
   meth setSash(S)
      {self.Manager send(ss(self.Id S))}
   end
   meth getSash($)
      {self.Manager ask(gs(self.Id) $)}
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

PanedwindowItem={AddMultiSetGetSupport SimplePanedwindowItem}

class PanedwindowProxy from TkProxy
   feat widgetName:panedwindow
      PaneItems
   attr panes
   prop locking
   meth init(...)=M
      lock
	 panes<-nil
	 TkProxy,M
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

PanedwindowWidget={CreateWidgetClass
		   panedwindow(proxy:PanedwindowProxy
			       synonyms:Synonyms
			       defaultRenderClass:PanedwindowRender
			       rendererClass:TCLTK
			      )}

{QTk.register PanedwindowWidget
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
