class ListboxRender from TkRender
   feat items
   attr lb
   meth init(M)
      TkRender,init(M)
      C
   in
      self.handle={New (self.tk).listbox tkInit(parent:self.parent.handle)}
      C={self.store createEvent(event:'<<ListboxSelect>>'
				args:nil
				action:proc{$}
					  {self.store triggerVirtualEvent(default a)}
				       end
				code:$)}
      {self bind(main C '<<ListboxSelect>>'#nil)}
      {self initState}
      self.items={Dictionary.new}
      lb<-nil
      {self set(lb lb {M get(lb lb $)})}
   end
   meth set(I K V)=M
      case I#K of lb#lb then
	 NewItems={NewCell nil}
	 proc{Create Id H}
	    S={self.manager getStore(Id $)}
	    {TkExec self.tk [self.handle insert H {S get(text $)}]}
	 in
	    {Assign NewItems Id#S|{Access NewItems}}
	 end
	 proc{Loop I O N}
	    if O==nil then
	       if N==nil then skip
	       else
		  %% new items to create
		  {List.forAllInd N
		   proc{$ J Id}
		      {Create Id I+J-1}
		   end}
	       end
	    else
	       if N==nil then
		  {TkExec self.tk [self.handle delete I 'end']}
		  {ForAll O
		   proc{$ Id}
		      {{self.manager getStore(Id $)} destroy}
		      {Dictionary.remove self.items Id}
		   end}
	       else
		  if O.1==N.1 then
		     {Loop I+1 O.2 N.2}
		  else
		     if {List.member O.1 N.2} then
			%% this O.1 is somewhere later in N
			%% => N.1 is new
			{Create N.1 I}
			{Loop I+1 O N.2}
		     else
			%% this O.1 is no more in N => delete it
			{TkExec self.tk [self.handle delete I]}
			{{self.manager getStore(O.1 $)} destroy}
			{Dictionary.remove self.items O.1}
			{Loop I O.2 N}
		     end
		  end
	       end
	    end
	 end
      in
	 {Loop 0 @lb V}
	 lb<-V
	 {List.forAllInd V
	  proc{$ I K}
	     {Dictionary.put self.items K I-1}
	  end}
	 {ForAll {Access NewItems}
	  proc{$ Id#S}
	     {ForAll {S getState($)}
	      proc{$ K#V}
		 if K\=text then
		    {self set(Id K V)}
		 end
	      end}
	  end}
      [] _#text then
	 skip
      elseif {Name.is I} then
	 H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    {TkExec self.tk [self.handle itemconfigure H "-"#K V]}
	 end
      else
	 TkRender,M
      end
   end
   meth get(I K V)=M
      case I of main then
	 TkRender,M
      else
	  H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    V={TkReturn self.tk [self.handle itemcget H "-"#K]}
	 end
      end
   end
   meth ask(Q R)=M
      case Q
      of bbox(I) then
	 R={TkStringTo.listFloat {TkReturn self.tk [self.handle bbox {Dictionary.get self.items I}]}}
      [] curselection then
	 R={TkStringTo.listInt {TkReturn self.tk [self.handle curselection]}}
      [] nearest(Y) then
	 R={TkStringTo.int {TkReturn self.tk [self.handle nearest Y]}}
      [] is(I) then
	 R={TkReturn self.tk [self.handle selection includes {Dictionary.get self.items I}]}=="1"
      else TkRender,M
      end
   end
   meth send(M)
      case M
      of set(I) then
	 {TkExec self.tk [self.handle selection {Label M} {Dictionary.get self.items I}]}
      [] clear(I) then
	 {TkExec self.tk [self.handle selection {Label M} {Dictionary.get self.items I}]}
      [] anchor(I) then
	 {TkExec self.tk [self.handle selection {Label M} {Dictionary.get self.items I}]}
      [] see(I) then
	 {TkExec self.tk [self.handle {Label M} {Dictionary.get self.items I}]}	    
      else
	 TkRender,send(M)
      end
   end
end

class ListboxItem from TkProxy
   feat Parent Id
   meth init(P I S D)
      self.Manager=P.Manager
      self.Parent=P
      self.Id=I
      self.Store=S
      {self.Store setParametersType(t(background:'Background'
				      foreground:'Foreground'
				      selectbackground:'Background'
				      selectforeground:'Foreground'
				      text:'Any'
				     ))}
      {self.Store setTypeChecker(TkTypeChecker)}
      {self.Store setProxyMarshaller(TkProxyMarshaller)}
      {self.Store set(text D)}
   end
   meth set(...)=M
      W={List.map
	 {Record.toListInd M}
	 fun{$ K#V}
	    if K==text then
	       {Exception.raiseError eblError(invalidParameter(K)
					      hint:"Invalid parameter "#K)}
	       unit
	    else
	       {self.Store remoteSet(K V $)}
	    end
	 end}
   in
      {ForAll W Wait}
   end
   meth get(...)=M
      {Record.forAllInd M
       proc{$ K V}
	  {self.Store remoteGet(K V)}
       end}
   end
   meth bbox($)
      {self.Manager ask(bbox(self.Id) $)}
   end
   meth setSelection
      {self.Manager send(set(self.Id))}
   end
   meth clearSelection
      {self.Manager send(clear(self.id))}
   end
   meth setAnchorSelection
      {self.Manager send(anchor(self.id))}
   end
   meth isSelected($)
      {self.Manager ask(is(self.id $))}
   end
end

class ListboxProxy from XYTkProxy
   feat widgetName:listbox
      Items
   attr
      Lb
   meth init(...)=M
      XYTkProxy,M
      Lb<-nil
      self.Items={Dictionary.new}
      {{self.Manager getStore(lb $)} setTypeChecker(t('...':TkTypeChecker.'Any'))}
      {self.Manager set(lb lb @Lb)}
   end
   meth curselection(L)
      L={self.Manager ask(curselection $)}
   end
   meth delete(F L<=unit)
      if L==unit then
	 A={self index(F $)}+1
      in
	 Lb<-{List.filterInd @Lb
	      fun{$ I _}
		 I\=A
	      end}
      else
	 A={self index(F $)}+1
	 B={self index(L $)}+1
      in
	 Lb<-{List.filterInd @Lb
	      fun{$ I _}
		 I<A orelse I>B
	      end}
      end
      {self.Manager set(lb lb @Lb)}
   end
   meth getItem(F $)
      {Dictionary.get self.Items {List.nth @Lb {self index(F $)}+1}}      
   end
   meth getItems(F L $)
      A={self index(F $)}
      B={self index(L $)}
   in
      {List.map {List.take {List.drop @Lb A} B-A+1}
       fun{$ I} {Dictionary.get self.Items I} end}      
   end
   meth index(I $)
      if {Int.is I} then {Min I {Length @Lb}}
      elseif I=='end' then {Length @Lb}
      else {self.Manager ask(index(I) $)} end
   end
   meth insert(I L)
      A={self index(I $)}
      It={List.map L
	  fun{$ D}
	     Id={NewName}
	     Store={self.Manager getStore(Id $)}
	     V={New ListboxItem init(self Id Store D)}
	  in
	     {Dictionary.put self.Items Id V}
	     Id
	  end}
      Bf Af
      O N
   in
      O=Lb<-N
      {List.takeDrop O A Bf Af}
      N={List.append {List.append Bf It} Af}
      {self.Manager set(lb lb @Lb)}
   end
   meth nearest(Y $)
      {self.Manager ask(nearest(Y) $)}
   end
   meth size($)
      {Length @Lb}
   end
   meth see(I)
      {self.Manager send(see(I))}
   end
%    meth scan(...)=M
%    end
%    meth selection(...)=M
%    end
end

ListboxWidget={CreateWidgetClass
	       listbox(proxy:ListboxProxy
		       synonyms:Synonyms
		       defaultRenderClass:ListboxRender
		       rendererClass:TCLTK
		      )}

{QTk.register ListboxWidget QTkBuild}
