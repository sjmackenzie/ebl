class MenuRender from TkRender
   feat
      items
      vars
   attr lb
      tearoff
   meth init(M)
      TkRender,init(M)
      self.items={Dictionary.new}
      self.handle={New (self.tk).menu tkInit(parent:self.parent.handle)}
      {self initState}
      self.vars={Dictionary.new}
      lb<-nil
      tearoff<-1
      {self set(lb lb {M get(lb lb $)})}
   end
   meth set(I K V)=M
      case I#K
      of lb#lb then
	 NewItems={NewCell nil}
	 proc{Create Id H}
	    Tk=self.tk
	    S={self.manager getStore(Id $)}
	    Type={S get(type $)}
	    TkId={Tk.getId}
	    State1={Record.subtract {Record.subtract {List.toRecord o {S getState($)}} type} selected}
	    State2=if Type\=separator then
		      {Record.adjoinAt State1 command TkId}
		   else
		      State1
		   end
	    Var State
	    Unbind
	    if Type==radiobutton orelse Type==checkbutton then
	       C={S createEvent(args:nil
				action:proc{$}
					  N={Var tkReturn($)}=="1"
				       in
					  {S set(selected N)}
					  {S triggerVirtualEvent(default a(value:N))}
				       end
				code:$)}
	    in
	       {S registerVirtualEvent(Id C)}
	       Var={New (self.tk).variable tkInit({S get(selected $)})}
	       {Dictionary.put self.vars Id Var}
	       if Type==radiobutton then
		  State={Record.adjoin State2
			 o(value:true variable:Var)}
	       else
		  State={Record.adjoin State2
			 o(onvalue:true offvalue:true variable:Var)}
	       end
	       Unbind={Tk.defineUserCmd TkId
		       self.eventPort#v(store:S obj:self event:Id)
		       nil}
	    else
	       Var=unit
	       State=State2
	       Unbind={Tk.defineUserCmd TkId
		       self.eventPort#v(store:S obj:self event:default)
		       nil}
	    end
	 in
	    if State==o then
	       {TkExec self.tk [self.handle insert H
				{S get(type $)}]}
	    else
	       {TkExec self.tk [self.handle insert H
				{S get(type $)} State]}
	    end
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
	 {Loop @tearoff @lb V}
	 lb<-V
	 {List.forAllInd V
	  proc{$ I K}
	     {Dictionary.put self.items K I-1}
	  end}
% 	 {ForAll {Access NewItems}
% 	  proc{$ Id#S}
% 	     {ForAll {S getState($)}
% 	      proc{$ K#V}
% 		 if K\=text then
% 		    {self set(Id K V)}
% 		 end
% 	      end}
% 	  end}
      [] main#tearoff then
	 if V then tearoff<-1 else tearoff<-0 end
	 TkRender,M
      [] main#_ then
	 TkRender,M
      [] _#type then
	 skip
      else
	 H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    case K of selected then
	       {{Dictionary.get self.vars I} tkSet(V)}
	    else
	       try
		  {TkExec self.tk [self.handle entryconfigure H+@tearoff "-"#K V]}
	       catch _ then skip end
	    end
	 end
      end
   end
   meth get(I K V)=M
      case I of main then
	 TkRender,M
      else
	  H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    V={TkReturn self.tk [self.handle entrycget H+@tearoff "-"#K]}
	 end
      end
   end
   meth ask(Q R)
      case Q
      of yposition(I) then
	 R={TkStringTo.int {TkReturn self.tk [self.handle nearest {Dictionary.get self.items I}+@tearoff]}}
      [] index(I) then
	 R1={TkReturn self.tk [self.handle index I]}
      in
	 R=if R1=="none" then
	      none
	   else
	      {TkStringTo.int R1}-@tearoff
	   end
      end
   end
   meth send(M)
      case M
      of post(X Y) then
	 {TkExec self.tk [self.handle post X Y]}
      [] unpost then
	 {TkExec self.tk [self.handle unpost]}
      else
	 {TkExec self.tk [self.handle v({Label M}) {Dictionary.get self.items M.1}+@tearoff]}
      end
   end
end

class MenuItem from TkProxy
   feat widgetName:menuitem
      Parent Id
   attr Group
   meth init(P I S D F)
      self.Manager=P.Manager
      self.Parent=P
      self.Id=I
      self.Store=S
      {self.Store setParametersType(p(menu:'Menu'
				      font:'Font'
				      bitmap:'Bitmap'
				      image:'Image'
				      selectimage:'Image'
				      type:'Any'
				      selected:'Boolean'
				      '...':'Remote'))}
      {self.Store setTypeChecker(t('Menu':TkTypeChecker.'Menu'
				   'Font':TkTypeChecker.'Font'
				   'Bitmap':TkTypeChecker.'Bitmap'
				   'Image:':TkTypeChecker.'Image'
				   'Boolean':TkTypeChecker.'TearOff'
				   'Any':fun{$ _} true end
				   'Remote':RemoteType))}
      {self.Store setProxyMarshaller(t('Menu':TkProxyMarshaller.'Menu'
				       'Font':TkProxyMarshaller.'Font'
				       'Bitmap':TkProxyMarshaller.'Bitmap'
				       'Image':TkProxyMarshaller.'Image'))}
      {self.Store setRenderMarshaller(t('Menu':TkRenderMarshaller.'Menu'
					'Font':TkRenderMarshaller.'Font'
					'Bitmap':TkRenderMarshaller.'Bitmap'
					'Image':TkRenderMarshaller.'Image'))}
      {self.Store set(type D)}
      {self.Store set(selected false)}
      Group<-default
      {RadioListeners.register @Group self
       proc{$} {self set(selected:false)} end}
      {Record.forAllInd F
       proc{$ K V}
	  case K
	  of group then
	     {self set(K:V)}
	  else
	     {self.Store set(K V)}
	   end
       end}
      if D==radiobutton orelse D==checkbutton then
	 {self bind(event:default
		    args:[value]
		    action:proc{$ V}
			      if V then
				 {RadioListeners.setActive @Group self}
			      end
			   end)}
      end
   end
   meth set(...)=M
      W={List.map
	 {Record.toListInd M}
	 fun{$ K#V}
	    case K
	    of selected then
	       {self.Store set(selected V)}
	       unit
	    [] group then
	       O N
	    in
	       O=Group<-N
	       {RadioListeners.unregister O self}
	       {RadioListeners.register V self
		proc{$} {self set(selected:false)} end}
	       N=V	       
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
	  case K
	  of group then V=@Group
	  [] selected then
	     {self.Store localGet(K V)}
	  else
	     {self.Store remoteGet(K V)}
	  end
       end}
   end
   meth activate
      {self.Manager send(activate(self.Id))}
   end
   meth invoke
      {self.Manager send(invoke(self.Id))}
   end
   meth postcascade
      {self.Manager send(postcascade(self.Id))}
   end
   meth type($)
      {self.Store get(type $)}
   end
   meth yposition($)
      {self.Manager ask(yposition(self.Id) $)}
   end
   meth bind(event:E action:A args:G<=nil unbind:U<=_)
      case E of default then
	 Event={self.Store createEvent(event:default args:G action:A unbind:U code:$)}
      in
	 {self.Store registerVirtualEvent(default Event)}
      end
   end
end

SetSync={NewName}

class MenuProxy from TkMultiProxy
   feat widgetName:menu
      Items
      Sync
   attr
      Lb
   meth init(...)=M
      TkMultiProxy,M
      Lb<-nil
      self.Items={Dictionary.new}
      {{self.Manager getStore(lb $)} setTypeChecker(t('...':fun{$ _} true end))}
      {self.Manager set(lb lb @Lb)}
   end
   meth !SetSync(S) self.Sync=S end
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
   meth insert(I Type ...)=M
      A={self index(I $)}
      Id={NewName}
      Store={self.Manager getStore(Id $)}
      V={New MenuItem init(self Id Store Type {Record.subtract {Record.subtract {Record.subtract M 1} 2} handle})}
      {CondSelect M handle _}=V
      {Dictionary.put self.Items Id V}
      Bf Af
      O N
   in
      O=Lb<-N
      {List.takeDrop O A Bf Af}
      N={List.append Bf Id|Af}
      {self.Manager set(lb lb @Lb)}
      % Tcl/Tk is a dumb lier, so the following doesn't work on most options :/
%      {V {Record.adjoin {Record.subtract {Record.subtract M 1} 2} set}}
   end
   meth size($)
      {Length @Lb}
   end
   meth post(X Y 'at':Ob<=auto)
      if Ob==auto then
	 {self.Manager send(post(X Y))}
      else
	 {RExec Ob
	  proc{$ Env Param}
	     M={Marshall TkRenderMarshaller 'Menu' s2u(Param {{Env get(parent $)} getStore(main $)})}
	  in
	     try
		{Wait self.Sync}
	     catch _ then skip end
	     {TkExec {Env get(tk $)} [M post X Y]}
	  end
	  {Marshall TkProxyMarshaller 'Menu' u2s(self)}}
      end
   end
   meth unpost
      {self.Manager send(unpost)}
   end
end

MenuWidget={CreateWidgetClass
	    menu(proxy:MenuProxy
		 synonyms:Synonyms
		 defaultRenderClass:MenuRender
		 rendererClass:TCLTK)}

class MenubuttonRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).menubutton tkInit(parent:self.parent.handle)}
      {self initState}
   end
end

class MenubuttonProxy from TkProxy
   feat widgetName:menubutton
end

% MenuMarshaller={NewTypeMarshaller}
% {MenuMarshaller.register 'Menu'
%  fun{$ O}
%     if {Object.is O} then
%        {O.Manager getRef($)}
%     else
%        O
%     end
%  end
%  NOOP}

MenubuttonWidget={CreateWidgetClass
		  menubutton(proxy:MenubuttonProxy
			     synonyms:Synonyms
			     defaultRenderClass:MenubuttonRender
			     rendererClass:TCLTK
			    )}

{QTk.register MenubuttonWidget QTkBuild}

fun{NewMenu Desc}
   case Desc of menu(...) then
      Menu={New MenuWidget init}
      Sync
      {Menu SetSync(Sync)}
      Items
      U
   in
      Items={List.map {Record.toList Desc}
	     fun{$ M}
		Type={Label M}
		M2=if {HasFeature M menu} then
		      case M.menu of menu(...) then
			 {Record.adjoinAt M menu {NewMenu M.menu}}
		      else
			 M
		      end
		   else
		      M
		   end
	     in
		{Menu insert('end' Type handle:$)}#M2
	     end}
      thread
	 {ForAll Items
	  proc{$ H#M}
	     {H {Record.adjoin {Record.subtract M action} set}}
	     if {HasFeature M action} then
		{H bind(event:default action:M.action)}
	     end
	  end}
	 Sync=unit
      end
%       {Menu bind(event:connect
% 		 action:proc{$}
% 			   {ForAll Items
% 			    proc{$ H#M}
% 			       {H {Record.adjoin M set}}
% 			    end}
% 			   {U}
% 			end
% 		 unbind:U)}
      Menu
   else
      {Exception.raiseError eblError(invalidMenuSpecification(Desc)
				     hint:"Invalid menu specification, should be a record menu(...)")}
      unit
   end
end
