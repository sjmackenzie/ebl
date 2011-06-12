\ifndef OPI

functor

import
   Discovery
   Connection
   Tk
   ETkMisc(tkExec:TkExec
	   tkReturn:TkReturn
	   tkStringTo:TkStringTo
	   typeDef:TypeDef
	   init:Init
	   manager:Manager
	   bind:Bind
	   atomize:Atomize
	   toEventCode:ToEventCode
	   tCLTK:TCLTK
	   color:Color)
   EBL(newWidgetRepository:NewWidgetRepository
       newRadioListeners:NewRadioListeners
       newEBLProxyManager:NewEBLProxyManager
       newLook:NewLook
       createWidgetClass:CreateWidgetClass
       addMultiSetGetSupport:AddMultiSetGetSupport
       marshall:Marshall
       remoteType:RemoteType
       continueLength:ContinueLength
       toDescGlue:ToDescGlue
       calcLR:CalcLR
       toArray:ToArray
       newPublisher:NewPublisher
       getFromPublisher:GetFromPublisher)
   ParametersGatherer(synonyms:Synonyms
		      tkProxyMarshaller:TkProxyMarshaller
		      tkRenderMarshaller:TkRenderMarshaller
		      tkTypeChecker:TkTypeChecker
		      tkDefaults:TkDefaults
		      none:None
		      tkParameters:TkParameters)
   Open
   System
   OS

prepare
   GetDict={NewName}
   
export

   etk:QTk
   newPublisher:NewPublisher1
   getFromPublisher:GetFromPublisher1
   manager:Manager1
   newProxyManager:NewProxyManager1
   buildFun:QTkBuild
   setBuilder:SetBuilder
   
define

   NewPublisher1=NewPublisher
   GetFromPublisher1=GetFromPublisher
   Manager1=Manager
   NewProxyManager1=NewEBLProxyManager
   
\else
   GetDict=getdict % the OPI version doesn't protect GetDict
\endif

% declare

   %% unless we force an encoding, Tk is dumb enough to use different encoding wrt different widgets
   %% (entry => iso8859-1, text => utf-8), even on platforms that do not know these encodings
   %% (eg under Windows, iso8859-1 is normally not supported)
   
   {Tk.send encoding(system "utf-8")}

   Globalizer
   local
      GlobalDict
      thread
	 {ForAll
	  {WeakDictionary.new $ GlobalDict}
	  proc{$ _#V}
	     if V==unit then skip else
		{V destroy}
	     end
	  end}
      end
   in
      fun{Globalizer Env Ref}
	 Id={VirtualString.toAtom Ref}
	 % the whole ref serves as the id, {Com.ref2Id  Ref} is not enough because it always returns m
	 O N
	 H={Env get(render $)}
      in
	 {WeakDictionary.condExchange GlobalDict Id unit O N}
	 if O==unit then
	    %% create it
	    E={H.manager createRemoteEnvironment($)}
	    {H setChildEnvironment(E unit)}
	    {E put(proxy Ref)}
	 in
	    {H.manager createRemoteHere(E render:N)}
	 else
	    N=O
	 end
	 {N getWidget($)}
      end
   end

   RadioListeners={NewRadioListeners}
   
   class TkNoEventRender
      feat
	 handle
	 manager
	 store
	 tk
	 parent
      meth init(M)
	 self.manager=M
	 self.store={M getStore(main $)}
	 self.tk={{M getEnv($)} get(tk $)}
	 {{M getEnv($)} put(render self)}
	 {{M getEnv($)} put(handle self.handle)}
	 local
	    Parent={{M getEnv($)} get(parent $)}
	 in
	    self.parent=if Parent==unit then unit else {Parent getWidget($)} end
	 end
	 	 if self.parent==unit then
	    thread
	       {ForAll {NewPort $ self.eventPort}
		proc{$ M}
		   case M of e(...) then
		      O=M.obj
		      EventDict IEventDict
		      {O GetDict({M.store getName($)} EventDict IEventDict)}
		      _#ON={Dictionary.get IEventDict M.event}
		      Args={Record.toList
			    {Record.filterInd M
			     fun{$ K _}
				K\=store andthen K\=obj andthen K\=event
			     end}
			   }
		      proc{Loop ON Args}
			 case ON of Event|Os then
			    _#G={Dictionary.get EventDict Event}
			    L R
			    {List.takeDrop Args {Length G} L R}
			 in
			    {M.store triggerEvent(Event L)}
			    {Loop Os R}
			 else skip end
		      end
		   in
		      {Loop ON Args}
		   [] v(...) then
		      {M.store triggerVirtualEvent(M.event
						   {Record.filterInd M
						    fun{$ K _}
						       K\=store andthen K\=obj andthen K\=event
						    end})}
		   else
		      {Exception.raiseError M}
		   end
		end}
	    end
	    {Wait self.eventPort}
	 else
	    self.eventPort=(self.parent).eventPort
	 end
      end
      meth initState
	 local
	    S={self.store getState($)}
	 in
	    if S\=nil then
	       try
		  {TkExec self.tk [self.handle configure {List.toRecord o S}]}
	       catch _ then
		  {ForAll S
		   proc{$ K#V}
		      try
			 {self set(main K V)}
		      catch _ then skip end
		   end}
	       end
	    end
	 end
	 try
	    X={self.manager get(scrollview xview $)}
	 in
	    {self set(scrollview xview X)}
	 catch _ then skip end
	 try
	    Y={self.manager get(scrollview yview $)}
	 in
	    {self set(scrollview yview Y)}
	 catch _ then skip end
      end
      meth set(I K V)
	 case I
	 of main then
	    if {Atom.is K} then
	       {TkExec self.tk [self.handle configure "-"#K V]}
	    end
	 [] scrollview then
	    case K of xview then
	       case V of none then skip
	       [] true then
		  Id={self.tk.getId}
		  _={self.tk.defineUserCmd Id
		     self.eventPort#v(store:{self.manager getStore(scrollview $)}
				      obj:self
				      event:xview) nil}
	       in
		  {TkExec self.tk [self.handle configure "-xscrollcommand" Id]}
	       else
		  {TkExec self.tk [self.handle configure "-xscrollcommand" ""]}
	       end
	    [] yview then
	       case V of none then skip
	       [] true then
		  Id={self.tk.getId}
		  _={self.tk.defineUserCmd Id
		     self.eventPort#v(store:{self.manager getStore(scrollview $)}
				      obj:self
				      event:yview) nil}
	       in
		  {TkExec self.tk [self.handle configure "-yscrollcommand" Id]}	       
	       else
		  {TkExec self.tk [self.handle configure "-yscrollcommand" ""]}
	       end
	    [] xpos then
	       skip
	    [] ypos then
	       skip
	    end
	 else skip end
      end
      meth remoteGet(_ K R)=M
	 if {Atom.is K} then
	    R={TkReturn self.tk [self.handle cget "-"#K]}
	 end
      end
      meth ask(Q R)
	 case Q
	 of wi(W) then
	    P
	 in
	    P=if {HasFeature W 1} then
		 {TkReturn self.tk [winfo {Label W} self.handle W.1]}
	      else
		 {TkReturn self.tk [winfo W self.handle]}
	      end
	    {Wait P}
	    R=case {Label W}
	      of colormapfull then
		 P=="1"
	      [] geometry then
		 {TkStringTo.geometry P}
	      [] pointerxy then
		 L={String.tokens P & } in
		 {String.toInt L.1}#{String.toInt L.2.1}
	      [] rgb then
		 L={String.tokens P & } in
		 {String.toInt L.1}#{String.toInt L.2.1}#{String.toInt L.2.2.1}			     
	      [] visualsavailable then
		 {List.map {String.tokens P &}} fun{$ L}
						   F={String.tokens L & }
						in
						   F.1.2#{TkStringTo.guess F.2.1}
						end}
	      else
		 {TkStringTo.guess P}
	      end
	 [] xview then
	    R={TkStringTo.listFloat {TkReturn self.tk [self.handle xview]}}
	 [] yview then
	    R={TkStringTo.listFloat {TkReturn self.tk [self.handle yview]}}	 
	 else R=false end
      end
      meth send(M)
	 case M
	 of xview(...) then
	    {TkExec self.tk [self.handle M]}
%	 {self.manager set(scrollview xpos {TkStringTo.listFloat {TkReturn self.tk [self.handle xview]}}.1)}
	 [] yview(...) then
	    {TkExec self.tk [self.handle M]}
%	 {self.manager set(scrollview ypos {TkStringTo.listFloat {TkReturn self.tk [self.handle xview]}}.1)}
	 [] focus then
	    {TkExec self.tk [focus self.handle]}
	 end
      end
      meth remoteSet(Id K V R)=M
	 {self set(Id K V)}
	 R=true
      end
      meth destroy
	 try
	    {self.parent remove(self)}
	 catch error(object(lookup(...) ...) ...) then skip end
	 try
	    {self.handle tkClose}
	 catch _ then skip end
      end
      meth setChildEnvironment(E _)
	 {E put(tk self.tk)}
	 {E put(system {{self.manager getEnv($)} get(system $)})}
	 {E put(global {{self.manager getEnv($)} get(global $)})}
      end
      meth importHere(Ob PlacementInstructions)
	 raise cannotImportHere end
      end
   end

   class TkRender from TkNoEventRender
      feat
	 eventDict
	 iEventDict
	 eventPort
      meth init(M)
	 TkNoEventRender,init(M)
	 self.eventDict={Dictionary.new}
	 self.iEventDict={Dictionary.new}
      end
      meth initState
	 TkNoEventRender,initState
	 {ForAll {self.store getBinding($)}
	  proc{$ K#V} {self bind(main K V)} end}
      end
      meth !GetDict(_ E I)
	 E=self.eventDict
	 I=self.iEventDict
      end
      meth bind(_ Event P)=M
	 E#_=P
	 OP#ON={Dictionary.condGet self.iEventDict E proc{$} skip end#nil}
      in
	 {Dictionary.put self.eventDict Event P}
	 {Dictionary.put self.iEventDict E OP#{List.append ON [Event]}}
	 {self Rebind(E)}
      end
      meth askBind(_ Event P R)=M
	 %% tests a binding
	 E#_=P
	 fun{CheckBind B E}
	    {(self.tk).returnInt set(v("o [bind ") B E
				     v(";]; set e [catch {bind ") B E v("{a}}]; bind")
				     B E v("\"$o\"; set e \"$e\""))}==0
	 end
      in
	 if {CheckBind self.handle E} then R=true
	 else
	    raise cannotBind(P) end
	 end
      end
      meth removeBind(_ Event)=M
	 E#_={Dictionary.get self.eventDict Event}
	 OP#ON={Dictionary.get self.iEventDict E}
      in
	 {Dictionary.remove self.eventDict Event}
	 {Dictionary.put self.iEventDict E OP#{List.subtract ON Event}}
	 {self Rebind(E)}
      end
      meth Rebind(E)
	 OP#ON={Dictionary.get self.iEventDict E}
	 {OP}
      in
	 if ON==nil then {Dictionary.remove self.iEventDict E}
	 else
	    Proc=self.eventPort#e(store:self.store obj:self event:E)
	    Args={List.flatten {List.map ON fun{$ Event} {Dictionary.get self.eventDict Event}.2 end}}
	    Unbind={Bind self.tk self.handle unit E Args Proc}
	 in
	    {Dictionary.put self.iEventDict E Unbind#ON}
	 end
      end
   end

   class TkItemsRender from TkNoEventRender
      feat
	 items
	 itemsED
	 itemsID
	 eventPort
      meth init(...)=M
	 TkNoEventRender,M
	 self.items={Dictionary.new}
	 self.itemsED={Dictionary.new}
	 self.itemsID={Dictionary.new}
      end
      meth initState
	 TkNoEventRender,initState
	 {ForAll {self.manager getStores($)}
	  proc{$ Store}
	     {ForAll {Store getBinding($)}
	      proc{$ K#V} {self bind({Store getName($)} K V)} end}
	  end}
      end
      meth askBind(I Event P R)=M
	 if I==main then
	    E#_=P
	    fun{CheckBind B E}
	       {(self.tk).returnInt set(v("o [bind ") B E
					v(";]; set e [catch {bind ") B E v("{a}}]; bind")
					B E v("\"$o\"; set e \"$e\""))}==0
	    end
	 in
	    if {CheckBind self.handle E} then R=true
	    else
	       raise cannotBind(P) end
	    end
	 else
	    H={Dictionary.condGet self.items I unit}
	 in
	    if H\=unit then
	       E#_=P
	       fun{CheckBind E}
		  {(self.tk).returnInt set(v("o [") self.handle v("bind") H E
					   v(";]; set e [catch {") self.handle v("bind") H E v("{a}}];") self.handle v("bind")
					   H E v("\"$o\"; set e \"$e\""))}==0
	       end
	    in
	       if {CheckBind E} then R=true
	       else
		  raise cannotBind(P) end
	       end
	    else
	       R=false
	    end
	 end
      end
      meth !GetDict(I EventDict IEventDict)
	 EventDict={Dictionary.condGet self.itemsED I {ByNeed fun{$}
								 D={Dictionary.new}
							      in
								 {Dictionary.put self.itemsED I D}
								 D
							      end}}
	 IEventDict={Dictionary.condGet self.itemsID I {ByNeed fun{$}
								  D={Dictionary.new}
							       in
								  {Dictionary.put self.itemsID I D}
								  D
							       end}}

      end
      meth bind(I Event P)=M
	 EventDict IEventDict
	 {self GetDict(I EventDict IEventDict)}
	 E#_=P
	 OP#ON={Dictionary.condGet IEventDict E proc{$} skip end#nil}
      in
	 {Dictionary.put EventDict Event P}
	 {Dictionary.put IEventDict E OP#{List.append ON [Event]}}
	 {self Rebind(I E)}
      end
      meth removeBind(I Event)=M
	 EventDict IEventDict
	 {self GetDict(I EventDict IEventDict)}
	 E#_={Dictionary.get EventDict Event}
	 OP#ON={Dictionary.get IEventDict E}
      in
	 {Dictionary.remove EventDict Event}
	 {Dictionary.put IEventDict E OP#{List.subtract ON Event}}
	 {self Rebind(I E)}
      end
      meth Rebind(I E)
	 H=if I==main then main else {Dictionary.condGet self.items I unit} end
      in
	 if H\=unit then
	    EventDict IEventDict
	    {self GetDict(I EventDict IEventDict)}
	    OP#ON={Dictionary.get IEventDict E}
	    {OP}
	 in
	    if ON==nil then {Dictionary.remove IEventDict E}
	    else
	       Proc=self.eventPort#e(store:{self.manager getStore(I $)} obj:self event:E)
	       Args={List.flatten {List.map ON fun{$ Event} {Dictionary.get EventDict Event}.2 end}}
	       Unbind=if I==main then
			 {Bind self.tk self.handle unit E Args Proc}
		      else
			 {Bind self.tk self.handle H E Args Proc}
		      end
	    in
	       {Dictionary.put IEventDict E Unbind#ON}
	    end
	 end
      end
   end

   Store={NewName}
   SetBuilder={NewName}
   Exec={NewName}
   Return={NewName}

   class TkBasicProxy
      feat
	 widgetName:undefined
	 !Manager
	 !Store
      meth init
	 self.Manager={NewEBLProxyManager self.widgetName}
	 self.Store={self.Manager getStore(main $)}
	 if {HasFeature TkParameters self.widgetName} then
	    {self.Store setProxyMarshaller(TkProxyMarshaller)}
	    {self.Store setRenderMarshaller(TkRenderMarshaller)}
	    {self.Store setTypeChecker(TkTypeChecker)}
	    {self.Store setParametersType(TkParameters.(self.widgetName))}
	    {self.Store setDefaults(TkDefaults.(self.widgetName))}
	 end
	 local
	    SC={self.Manager getStore(scrollview $)}
	    {SC setParametersType(p('...':'...'))}
	    {SC setTypeChecker(p('...':fun{$ _} true end))}
	 in
	    {SC set(xscroll none)}
	    {SC set(yscroll none)}
	 end
      end
      meth !SetBuilder(B)
	 {self.Manager setBuilder(B)}
      end
      meth set(K V)
	 {self.Store set(K V)}
      end
      meth get(K V)
	 {self.Store get(K V)}
      end
      meth bind('attr':Attr<=unit
		event:E1<=unit action:A args:G<=nil mod1:M1<=unit mod2:M2<=unit detail:D<=unit unbind:U<=_)=M
	 E={Atomize E1}
      in
	 if Attr\=unit then
	    Event={self.Store createEvent(args:G action:A unbind:U code:$)}
	 in
	    {self.Store registerVirtualEvent(Attr Event)}
	 elseif {List.member E [connect disconnect default lostWidget]} then
	    Event={self.Store createEvent(args:G action:A unbind:U code:$)}
	 in
	    {self.Store registerVirtualEvent(E Event)}
	 elseif E1\=unit then
	    U1 R
	    Event={self.Store createEvent(event:{ToEventCode E M1 M2 D} args:G action:A unbind:U1 code:$)}
	    {self.Store askBind(Event R)}
	 in
	    if R==true then
	       %% event binding was accepted
	       proc{U}
		  {self.Store removeBind(Event)}
		  {U1}
	       end
	    else
	       %% event bind was rejected, uninstall event and raise exception
	       {U1}
	       raise R end
	    end
	 else
	    {Exception.raiseError ebl(missingBindEvent(M) hint:"Missing bind event")}
	 end
      end
      meth getRef($)
	 {self.Manager getRef($)}
      end
      meth setContext(C)
	 {self.Manager setContext(C)}
      end
      meth destroy
	 {self.Manager destroy}
      end
      meth winfo(...)=M
	 {Record.forAllInd M
	  proc{$ K V}
	     V={self.Manager ask(wi(K) $)}
	  end}
      end
      meth !Exec(Proc Params)
	 {self.Manager exec(Proc Params)}
      end
      meth !Return(Proc Params R)
	 {self.Manager return(Proc Params R)}
      end
   end

   class TkMultiProxy from TkBasicProxy
      meth init
	 TkBasicProxy,init
	 {self.Manager setConnectionPolicy(proc{$ M}
					      case M of incoming(Id) then
						 {self.Manager connect(Id)}
					      else skip end
					   end)}
      end
   end

   class TkProxy from TkBasicProxy
      meth allowMultipleRenderers(B)
	 if B then
	    {self.Manager setConnectionPolicy(proc{$ M}
						 case M of incoming(Id) then
						    {self.Manager connect(Id)}
						 else skip end
					      end)}
	 else
	    {self.Manager setConnectionPolicy(proc{$ M}
						 case M of incoming(Id) then
						    {ForAll {self.Manager getRenderIds($)}
						     proc{$ I}
							{self.Manager disconnect(I)}
						     end}
						    {self.Manager connect(Id)}
						 else skip end
					      end)}
	 end
      end
      meth getFocus
	 {self.Manager send(focus)}
      end
   end
   

%[button canvas checkbutton entry label listbox menubutton message radiobutton scale scrollbar text labelframe panedwindow spinbox]

%NewMenu

   \insert 'ETkDialogbox.oz'
   \insert 'ETkFont.oz'

   QTkWidgetRepository={NewWidgetRepository}

   AddSyncVar={NewName}
   
   {QTkWidgetRepository.setGathererClass
    class $
       feat
	  Constraints
       attr
	  Count
	  SyncVars
       meth init
	  self.Constraints={Dictionary.new}
	  Count<-0
	  SyncVars<-nil
       end
       meth !AddSyncVar(S)
	  O N
       in
	  O=SyncVars<-N
	  N=S|O
       end
       meth sync
	  {ForAll @SyncVars Wait}
	  SyncVars<-unit
       end
       meth destroyAll
	  {ForAll {self getAllItems($)}
	   proc{$ I} {I destroy} end}
       end
       meth setContext(C)
	  {ForAll {self getAllItems($)}
	   proc{$ I} try {I setContext(C)} catch _ then skip end end}	  
       end
       meth addConstraint(C R<=_)
	  proc{Err}
	     {Exception.raiseError eblError(invalidConstraint(C)
					    hint:"Invalid constraint")}
	  end
	  if {Not {Record.is C} andthen {HasFeature C trigger}} then
	     {Err}
	  end
	  fun{GetItem Id}
	     {self getItem(Id $)}
	  end
	  %% parses C and creates the binding accordingly
	  PList=case {Label C.trigger} of '#' then
		   {List.toRecord p {List.map {Arity C.trigger}.2 fun{$ K} (C.trigger.K)#(K-1) end}}
		else nil end
	  Trigger=case {Label C.trigger} of '#' then
		     C.trigger.1
		  else C.trigger end
	  class Action
	     meth init skip end
	     meth doit(Action M)
		proc{Exec A}
		   case A
		   of Widget#set(...) then
		      {GetItem Widget A.2}
		   [] Widget#unset(...) then
		      {GetItem Widget A.2}
		   elseif {Procedure.is A} then
		      {A}
		   elseif {Record.is A} andthen {Label A}=='#' andthen {Procedure.is A.1} then
		      {Procedure.apply A.1 {List.map {Record.toList A}.2
					    fun{$ K} M.(PList.K) end}}
		   elseif {List.is A} then
		      {ForAll A proc{$ K} {Exec K} end}
		   else
		      {Err}
		   end
		end
	     in
		{Exec if Action then {CondSelect C action unit} else {CondSelect C inverseaction unit} end}
	     end
	     meth action(...)=M
		fun{Eval W}
		   if {String.is W} then W
		   elseif {Procedure.is W} then
		      {W}
		   elseif {Int.is W} then W
		   elseif {Float.is W} then W
		   elsecase W
		   of Widget#get(K) then
		      {{GetItem Widget} get(K:$)}
		   elseif {Record.is W} andthen {Label W}=='#' andthen {Procedure.is W.1} then
		      R
		   in
		      {Procedure.apply W.1 {List.append
					    {List.map {Record.toList W}.2
					     fun{$ K} M.(PList.K) end}
					    [R]}}
		      R
		   elseif {Atom.is W} then
		      try
			 M.(PList.W)
		      catch _ then {Err} false end
		   else W end
		end
		%% check cond
		fun{Check What}
		   case What
		   of true then true
		   [] false then false
		   [] '=='(L R) then
		      {Eval L}=={Eval R}
		   [] '!='(L R) then
		      {Eval L}\={Eval R}
		   [] '>'(L R) then
		      {Eval L}>{Eval R}
		   [] '>='(L R) then
		      {Eval L}>={Eval R}
		   [] '<'(L R) then
		      {Eval L}<{Eval R}
		   [] '=<'(L R) then
		      {Eval L}=<{Eval R}
		   [] 'or'(L R) then
		      {Check L} orelse {Check R}
		   [] and(L R) then
		      {Check L} andthen {Check R}
		   [] 'not'(L) then
		      {Not {Check L}}
		   end
		end
	     in
		{self doit({Check {CondSelect C 'cond' true}} M)}
	     end
	  end
	  Ob={New Action init}
	  {{GetItem {Label Trigger}} {Record.adjoin {Record.adjoin Trigger r(action:Ob#action
									     unbind:U)}
				      bind}}
	  O N U
       in
	  O=Count<-N
	  N=O+1
	  {Dictionary.put self.Constraints N U#C}
	  R=N
       end
    end}
   
   QTk={Record.adjoin QTkWidgetRepository
	qtk(bell:{New BellClass Init}
	    newMenu:NewMenu
	    clipboard:{New ClipboardClass Init}
	    newFont:NewFont
	    newLook:NewLook
	    font:{New FontClass Init}
	    dialogbox:DialogBoxes
	    newImage:NewImage
	    newBitmap:NewBitmap
	    bitmap:Bitmap
	    color:Color
	    none:None
	   )}

   proc{QTkBuild Env}
      C Sync
   in
      {Env.handle.Manager setEventPort(Env.eventPort)}
      {Env.handle SetBuilder(Env.builder)}
      if {HasFeature Env.desc action} then
	 {Env.handle bind(event:default
			  action:Env.desc.action)}
      end
      try
	 {Env.gatherer AddSyncVar(Sync)}
      catch _ then skip end
      %% sets parameters at first connection, to avoid blocking
      %% another solution is to do that in a thread and rely on the set blocking behavior
      %% the connect approach is a bit better: we have the garantee that it will be executed
      %% before any other user configured event is processed
      %% note that the connect approach may block in case of fast connect/disconnected
      %% it then will use the set blocking behavior to proceed correctly
      {Env.handle bind(event:'connect' unbind:C
		       action:proc{$}
				 {Env.handle {Record.adjoin {Record.subtract Env.desc action} set}}
				 Sync=unit
				 {C}
			      end)}
   end

   \insert 'ETkScrollbar.oz'
   \insert 'ETkButton.oz'
   \insert 'ETkTable.oz'
   \insert 'ETkWindow.oz'
   \insert 'ETkLabel.oz'
   \insert 'ETkCanvas.oz'
   \insert 'ETkCheckbutton.oz'
   \insert 'ETkEntry.oz'
   \insert 'ETkListbox.oz'
   \insert 'ETkMessage.oz'
   \insert 'ETkMenubutton.oz'
   \insert 'ETkRadiobutton.oz'
   \insert 'ETkScale.oz'
   \insert 'ETkLabelframe.oz'
   \insert 'ETkSpinbox.oz'
   \insert 'ETkPanedwindow.oz'
   \insert 'ETkImage.oz'
   \insert 'ETkText.oz'
   \insert 'ETkNavigator.oz'
   \insert 'ETkSelector.oz'
   \insert 'ETkFlexclock.oz'
   
%[button canvas checkbutton entry frame label listbox menubutton message radiobutton scale scrollbar text labelframe panedwindow spinbox]
\ifndef OPI
end
\endif