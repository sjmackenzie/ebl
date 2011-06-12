\ifdef OPI

[Com SC BootName]={Module.link ["Com.ozf" "SocketConnection.ozf" "x-oz://boot/Name"]}

\else

functor

import
   Error
   Com at 'Com.ozf'
   SC at 'SocketConnection.ozf'
   BootName at 'x-oz://boot/Name'
   System

prepare
   WidgetRepository={NewName}

export

   %% type management
   getType:GetType
   checkType:CheckType
   getTypeInfo:GetTypeInfo
   marshall:Marshall
   remoteType:RemoteType
   invalidType:InvalidType
   
   %% data structures provided

   newEBLProxyManager:NewEBLProxyManager % core proxy widget manager
   newWidgetLook:NewWidgetLook % look for a single widget
   newLook:NewLook % look for multiple widgets
   newWidgetRepository:NewWidgetRepository % repository for declarative/imperative mixed approach
   newRadioListeners:NewRadioListeners % support for radiobutton-like widgets

   %% render class support
   
   setRenderContextClass:SetRenderContextClass

   %% misc support for creating proxy widgets
   
   addLookSupport:AddLookSupport
   addSynonymSupport:AddSynonymSupport
   addMultiSetGetSupport:AddMultiSetGetSupport
   createWidgetClass:CreateWidgetClass

   %% misc support for td/lr widgets based on tables
   
   noGlue:NoGlue
   getGlue:GetGlue
   toDescGlue:ToDescGlue
   toArray:ToArray
   calcLR:CalcLR
   continueLength:ContinueLength

   %% publisher

   newPublisher:NewPublisher
   getFromPublisher:GetFromPublisher
   
define

\endif

   NewUniqueName=BootName.newUnique
   
%   `ooMeth`={NewUniqueName 'ooMeth'}
   `ooFeat`={NewUniqueName 'ooFeat'}
   `ooAttr`={NewUniqueName 'ooAttr'}
   
   {Error.registerFormatter eblError
    fun {$ E}
       T = 'Error: EBL module'
    in
       case E
       of eblError(C hint:S info:X) then
	  error(kind:T
		msg:S
		items:[hint(l:'Type'
			    m:oz(C))
		       hint(l:'Information'
			    m:oz(X))])
       [] eblError(C hint:S expecting:X got:V) then
	  error(kind:T
		msg:S
		items:[hint(l:'Type'
			    m:oz(C))
		       hint(l:'Expecting'
			    m:X)
		       hint(l:'Got'
			    m:oz(V))])
       []  eblError(C hint:S) then
	  error(kind:T
		msg:S
		items:[hint(l:'Type'
			    m:oz(C))])
       end
    end}

   fun{InvalidType _} invalid end
   fun{RemoteType _} remote end

   fun{Marshall M K Code}
      %% {Marshall TkRenderMarshaller 'Font' s2u(self Ref)}
      Fun={Label Code}
      Params={Record.toList Code}
      Marshaller={CondSelect M K unit}
   in
      if Marshaller==unit then Params.1
      else
	 F={CondSelect Marshaller Fun unit}
      in
	 if F==unit then Params.1
	 else
	    try
	       R
	    in
	       {Procedure.apply F {List.append Params [R]}}
	       R
	    catch error(kernel(arity !F !Params) ...) then
	       {Exception.raiseError eblError(unableToMarshallInvalidArity(K Code)
					      hint:"Unable to marshall")}
	       Params.1
	    end
	 end
      end
   end

   RenderClassRepository={Dictionary.new}
   proc{SetRenderContextClass RendererClass WidgetName Context Class}
      O N
   in
      {Dictionary.condExchange RenderClassRepository WidgetName r O N}
      N={Record.adjoinAt O Context Class}
   end

   FNewWidgetRepository
   
   local
      Init={NewName}

      class RemoteEnv
	 feat
	    D
	 meth !Init(M<=unit)
	    if M==unit then
	       self.D={Dictionary.new}
	    else
	       self.D={Dictionary.clone M}
	    end
	 end
	 meth put(K V)
	    {Dictionary.put self.D K V}
	 end
	 meth get(K $)
	    {Dictionary.get self.D K}
	 end
	 meth condGet(K F $)
	    {Dictionary.condGet self.D K F}
	 end
	 meth destroy
	    {Dictionary.removeAll self.D}
	 end
	 meth entries($)
	    {Dictionary.entries self.D}
	 end
	 meth clone($)
	    {New RemoteEnv Init(self.D)}
	 end
      
      end

      Answer={NewName}
      Conn={NewName}
      ForceSet={NewName}
      RSet={NewName}
      
      class ProxyStore
	 prop locking
	 feat
	    Parent
	    Question
	    !Answer
	    State
	    LocalState
	    !Conn
	    EventDict
	    VirtualEventDict
	    IVirtualEventDict
	    Id
	 attr
	    BoundEvent
	    ProxyMarshaller
	    RenderMarshaller
	    TypeChecker
	    ParametersType
	    Defaults
	 meth !Init(P I)
	    self.Parent=P
	    self.Question={WeakDictionary.new _}
	    self.Answer=P.Answer
	    self.Conn=P.Conn
	    self.State={Dictionary.new}
	    self.LocalState={Dictionary.new}
	    self.EventDict={Dictionary.new}
	    self.VirtualEventDict={Dictionary.new}
	    self.IVirtualEventDict={Dictionary.new}
	    self.Id=I
	    BoundEvent<-nil
	    ProxyMarshaller<-p
	    RenderMarshaller<-p
	    TypeChecker<-p('...':RemoteType) %% '...' type is checked remotely
	    ParametersType<-p('...':'...') %% all parameters map to '...' type
	    Defaults<-p
	 end
	 meth setProxyMarshaller(P)
	    ProxyMarshaller<-P
	 end
	 meth setRenderMarshaller(P)
	    RenderMarshaller<-P
	    {self.Conn broadcast(sr(self.Id P))}
	 end
	 meth setTypeChecker(P)
	    TypeChecker<-P
	 end
	 meth setParametersType(P)
	    ParametersType<-P
	    {self.Conn broadcast(sp(self.Id P))}
	 end
	 meth setDefaults(P)
	    Defaults<-P
	 end
	 meth Lock(K M)
	    O N
	    Type={CondSelect @ParametersType K
		  {ByNeed fun{$} {CondSelect @ParametersType '...'
				  {ByNeed fun{$}
					     {Value.failed error}
					  end}}
			  end}}
	    try
	       {Wait Type}
	    catch _ then
	       {Exception.raiseError eblError(unknownParameter(K M)
					      hint:"Unknown parameter "#K)}
	    end
	    if {Not {HasFeature @TypeChecker Type}} then
	       {Exception.raiseError eblError(unknownParameter(K Type)
					      hint:"Internal error: missing type information for parameter "#K)}
	    end
	 in
	    lock
	       {WeakDictionary.condExchange self.Question K unit O N}
	       thread
		  {Wait O}
		  try
		     {self {Record.adjoinAt M 1 Type}}
		     N=ok
		  catch Z then
		     N=error(Z)
		  end
	       end
	    end
	    case N of error(Z) then raise Z end
	    else skip end
	 end
	 meth GLock(K M)
	    O N
	    Type={CondSelect @ParametersType K
		  {ByNeed fun{$} {CondSelect @ParametersType '...'
				  {ByNeed fun{$}
					     {Value.failed error}
					  end}}
			  end}}
	    try
	       {Wait Type}
	    catch _ then
	       {Exception.raiseError eblError(unknownParameter(K)
					      hint:"Unknown parameter "#K)}
	    end
	 in
	    lock
	       {WeakDictionary.condExchange self.Question K unit O N}
	       thread
		  {Wait O}
		  try
		     {self M}
		     N=ok
		  catch Z then N=error(Z) end
	       end
	    end
	    case N of error(Z) then raise Z end
	    else skip end
	 end
	 meth Check(Type K V $)
	    Z=case @TypeChecker.Type of A#_ then A [] B then B end
	 in
	    case {Procedure.arity Z}
	    of 2 then
	       {Z V}
	    [] 3 then
	       {Z V self}
	    else
	       {Exception.raiseError eblError(unknownParameter(K)
					      hint:"Internal error: invalid arity for the type check procedure of the parameter "#K)}
	       unit
	    end
	 end
	 meth Set(Type K V)
	    case {self Check(Type K V $)}
	    of remote then
	       {Wait {self RemoteSet(Type K V $)}}
	    [] true then
	       {self LocalSet(Type K V)}
	    else
	       {Exception.raiseError eblError(typeError(K)
					      hint:"Invalid type for parameter "#K
					      expecting:case @TypeChecker.Type of _#M then M else "No type information" end
					      got:V)}
	    end
	 end
	 meth !ForceSet(K MV V)
	    O N
	 in
	    lock
	       {WeakDictionary.condExchange self.Question K unit O N}
	       thread
		  {Wait O}
		  {Dictionary.put self.State K MV}
		  if MV\=V andthen {Not {HasFeature {CondSelect @ProxyMarshaller K p} s2u}} then
		     %% there is no way for us to get back the value provided for this parameter => store it
		     {Dictionary.put self.LocalState K V}
		  end
		  {self triggerVirtualEvent(K a(value:V))}
		  {self.Conn broadcast(s(self.Id K MV))}
		  N=unit
	       end
	    end
	 end
	 meth LocalSet(Type K V)
	    M={CondSelect @ProxyMarshaller Type p}
	    MV=if {HasFeature M u2s} then
		  case {Procedure.arity M.u2s}
		  of 2 then
		     {M.u2s V}
		  [] 3 then
		     {M.u2s V self}
		  else
		     {Exception.raiseError eblError(marshallError(K)
						    hint:"Internal error: invalid arity for the marshall procedure of the parameter "#K)}
		     V
		  end
	       else
		  V
	       end
	 in
	    {Dictionary.put self.State K MV}
	    if MV\=V andthen {Not {HasFeature M s2u}} then
	       %% there is no way for us to get back the value provided for this parameter => store it
	       {Dictionary.put self.LocalState K V}
	    end
	    {self triggerVirtualEvent(K a(value:V))}
	    {self.Conn broadcast(s(self.Id K MV))}
	 end
	 meth Unset(Type K)
	    if {HasFeature @Defaults K} then
	       {self LocalSet(Type K @Defaults.K)}
	       {Dictionary.remove self.LocalState K}
	    else
	       {Exception.raiseError eblError(cannotUnset(K)
					      hint:"No default value for parameter "#K#": cannot be unset")}
	    end
	 end
	 meth RemoteSet(Type K V R1)
	    M={CondSelect @ProxyMarshaller Type p}
	    MV=if {HasFeature M u2s} then
		  case {Procedure.arity M.u2s}
		  of 2 then
		     {M.u2s V}
		  [] 3 then
		     {M.u2s V self}
		  else
		     {Exception.raiseError eblError(marshallError(K)
						    hint:"Internal error: invalid arity for the marshall procedure of the parameter "#K)}
		     V
		  end
	       else
		  V
	       end
	    I={NewName}
	    R
	 in
	    R1=!!R
	    {Dictionary.put self.Answer I r(R self.Id K MV V)}
	    {self.Conn broadcast(r(I self.Id K MV))}
	    try {Wait R} catch _ then skip end
	 end
	 meth set(K V)
	    {self Lock(K Set(unit K V))}
	 end
	 meth localSet(K V)
	    {self Lock(K LocalSet(unit K V))}
	 end
	 meth remoteSet(K V R1)
	    {self Lock(K RemoteSet(unit K V R1))}
	 end
	 meth unset(K)
	    {self Lock(K Unset(unit K))}
	 end
	 meth getManager($)
	    self.Parent
	 end
	 meth get(K $)
	    {self GLock(K Get(K $))}
	 end
	 meth localGet(K $)
	    {self GLock(K LocalGet(K $))}
	 end
	 meth remoteGet(K $)
	    {self GLock(K RemoteGet(K $))}
	 end
	 meth Get(K $)
	    if {HasFeature @Defaults K} then
	       {self LocalGet(K $)}
	    else
	       {self RemoteGet(K $)}
	    end
	 end
	 meth !RSet(K V)
	    M={CondSelect @ProxyMarshaller K p}
	    MV=if {HasFeature M s2u} then
		  case {Procedure.arity M.s2u}
		  of 2 then
		     {M.s2u V}
		  [] 3 then
		     {M.s2u V self}
		  else
		     {Exception.raiseError eblError(marshallError(K)
						    hint:"Internal error: invalid arity for the marshall procedure of the parameter "#K)}
		     V
		  end
	       else
		  V
	       end
	 in
	    {self set(K MV)}
	 end
	 meth LocalGet(K $)
	    if {Dictionary.member self.LocalState K} then
	       {Dictionary.get self.LocalState K}
	    elseif {Dictionary.member self.State K} then
	       V={Dictionary.get self.State K}
	       Type={CondSelect @ParametersType K
		     {ByNeed fun{$} {CondSelect @ParametersType '...'
				     {ByNeed fun{$}
						{Value.failed error}
					     end}}
			     end}}
	       M={CondSelect @ProxyMarshaller Type p}
	       MV=if {HasFeature M s2u} then
		     case {Procedure.arity M.s2u}
		     of 2 then
			{M.s2u V}
		     [] 3 then
			{M.s2u V self}
		     else
			{Exception.raiseError eblError(marshallError(K)
						       hint:"Internal error: invalid arity for the marshall procedure of the parameter "#K)}
			V
		     end
		  else
		     V
		  end
	    in
	       MV
	    elseif {HasFeature @Defaults K} then
	       @Defaults.K
	    else
	       {Exception.raiseError eblError(unableToGet(K)
					      hint:"Unable to get the value of the parameter "#K)}
	       unit
	    end
	 end
	 meth RemoteGet(K R1) %% similar to remoteSet except that it doesn't propose a value
	    M={NewName}
	    R R2
	 in
	    R1=!!R2
	    {Dictionary.put self.Answer M g(R self.Id K)}
	    {self.Conn broadcast(g(M self.Id K))}
	    try
	       {Wait R}
	       Type={CondSelect @ParametersType K
		     {ByNeed fun{$} {CondSelect @ParametersType '...'
				     {ByNeed fun{$}
						{Value.failed error}
					     end}}
			     end}}
	       M={CondSelect @ProxyMarshaller Type p}
	    in
	       R2=if {HasFeature M s2u} then
		     case {Procedure.arity M.s2u}
		     of 2 then
			{M.s2u R}
		     [] 3 then
			{M.s2u R self}
		     else
			{Exception.raiseError eblError(marshallError(K)
						       hint:"Internal error: invalid arity for the marshall procedure of the parameter "#K)}
			R
		     end
		  else
		     R
		  end
	    catch X then
	       R2={Value.failed X}
	    end
	 end
	 meth createEvent(event:E<=unit action:A args:G<=nil unbind:U<=_ code:C)
	    %% registers event E to run action A, with parameters G M1 M2 and D, U is a zeroprocedure that unbinds the event, returns the code C to trigger the event
	    C={NewName}
	    {Dictionary.put self.EventDict C E#A#G} % {List.toRecord a {List.map G fun{$ I} I#unit end}}}
	    proc{U}
	       O N
	    in
	       O=BoundEvent<-N
	       N={List.subtract O C}
	       {Dictionary.remove self.EventDict C}
	       if {Dictionary.member self.IVirtualEventDict C} then
		  Virtual={Dictionary.get self.IVirtualEventDict C}
		  {Dictionary.remove self.IVirtualEventDict C}
		  Old={Dictionary.condGet self.VirtualEventDict Virtual nil}
		  New={List.filter Old fun{$ I} I\=C end}
	       in
		  if New==nil then {Dictionary.remove self.VirtualEventDict Virtual}
		  else
		     {Dictionary.put self.VirtualEventDict Virtual New}
		  end
	       end
	    end
	 end
	 meth registerVirtualEvent(Virtual Code)
	    %% registers a code to execute upon a virtual event
	    {Dictionary.put self.VirtualEventDict Virtual Code|{Dictionary.condGet self.VirtualEventDict Virtual nil}}
	    {Dictionary.put self.IVirtualEventDict Code Virtual}
	 end
	 meth triggerVirtualEvent(Virtual FullArgs)
	    %% triggers all events associated to a virtual event
	    {ForAll {Dictionary.condGet self.VirtualEventDict Virtual nil}
	     proc{$ Code}
		_#_#G={Dictionary.condGet self.EventDict Code unit#unit#nil}
		fun{Loop L}
		   case L of K|Ls then
		      if {HasFeature FullArgs K} then FullArgs.K|{Loop Ls}
		      else
			 nil
		      end
		   else nil end
		end
		Args={Loop G} %{List.map G fun{$ K} FullArgs.K end}
	     in
		{self triggerEvent(Code Args)}
	     end}
	 end
	 meth triggerEvent(Code Args<=nil)
	    %% triggers an event with args Args
	    _#A#_={Dictionary.condGet self.EventDict Code unit#unit#unit}
	 in
	    if A==unit then skip
	    else
	       {self.Parent execEvent(A Args)}
	    end
	 end
	 meth askBind(Event R1)
	    R
	    E#_#G={Dictionary.get self.EventDict Event}
	 in
	    R1=!!R
	    {Dictionary.put self.Answer Event ab(R self.Id E#G)}
	    {self.Conn broadcast(ab(Event self.Id E#G))}
	 end
	 meth bind(Event)
	    E#_#G={Dictionary.get self.EventDict Event}
	    O N
	 in
	    O=BoundEvent<-N
	    N=Event|O
	    {self.Conn asend(m b(Event self.Id E#G))}
	 end
	 meth removeBind(Event)
	    if {Dictionary.member self.EventDict Event} then
	       {Dictionary.remove self.EventDict Event}
	       {self.Conn asend(m u(Event self.Id))}
	    end
	 end
	 meth getState($)
	    lock
	       {Dictionary.entries self.State}#
	       {List.map @BoundEvent
		fun{$ K}
		   E#_#G={Dictionary.get self.EventDict K}
		in
		   K#(E#G)
		end}#(@RenderMarshaller)#(@ParametersType)
	    end
	 end
	 meth destroy
	    BoundEvent<-nil
	    ProxyMarshaller<-p
	    RenderMarshaller<-p
	    TypeChecker<-p
	    ParametersType<-p
	    Defaults<-p
	    {WeakDictionary.removeAll self.Question}
	    {Dictionary.removeAll self.State}
	    {Dictionary.removeAll self.LocalState}
	    {Dictionary.removeAll self.EventDict}
	    {Dictionary.removeAll self.VirtualEventDict}
	    {Dictionary.removeAll self.IVirtualEventDict}
	 end
      end

      class EBLManager
	 meth set(I K V)
	    {{self getStore(I $)} set(K V)}
	 end
	 meth localSet(I K R)
	    {{self getStore(I $)} localSet(K R)}
	 end
	 meth remoteSet(I K V R)
	    {{self getStore(I $)} remoteSet(K V R)}      
	 end
	 meth get(I K V)
	    {{self getStore(I $)} get(K V)}      
	 end
	 meth localGet(I K R)
	    {{self getStore(I $)} localGet(K R)}
	 end
	 meth remoteGet(I K R)
	    {{self getStore(I $)} remoteGet(K R)}
	 end
      end

      class EBLProxyManager from EBLManager
	 feat
	    !Conn
	    Clients
	    StateLock
	    State
	    Question !Answer
	    Children
	    Contexts
	    WidgetName
	    Stores
	 attr
	    ConnPolicy
	    EventPort
	    RenderContext
	    Builder
	 prop locking
	 meth !Init(Name Com)
	    Builder<-unit
	    self.Conn={New Com.com init(m master proc{$ M}
						    {self Recv(M)}
						 end)}
	    ConnPolicy<-proc{$ M}
			   case M of incoming(Id) then
			      {ForAll {self getRenderIds($)}
			       proc{$ I}
				  {self disconnect(I)}
			       end}
			      {self connect(Id)}
			   else skip end
			end
	    thread
	       {ForAll {NewPort $ @EventPort}
		proc{$ P} {P} end}
	    end
	    {Wait @EventPort}
	    self.Clients={Dictionary.new}
	    self.State={Dictionary.new}
	    self.Answer={Dictionary.new}
	    self.StateLock={NewLock}
	    self.Children={Dictionary.new}
	    self.Contexts={Dictionary.new}
	    self.Stores={Dictionary.new}
	    self.WidgetName=Name
	    RenderContext<-default
	 end
	 meth setBuilder(S)
	    Builder<-S
	    {self.Conn broadcast(b(@Builder.ref))}
	 end
	 meth getStore(Name $)
	    O N
	    {Dictionary.condExchange self.Stores Name unit O N}
	 in
	    if O==unit then
	       N={New ProxyStore Init(self Name)}
	    else
	       N=O
	    end
	    N
	 end
	 meth refToId(R $)
	    {self.Conn getIdFromRef(R $)}
	 end
 	 meth setRenderContextClass(C R)
 	    {Dictionary.put self.Contexts C R}
 	 end
	 meth setContext(C)
	    Ok=if {Dictionary.member self.Contexts C} then
		  true
	       elseif {HasFeature {Dictionary.condGet RenderClassRepository self.WidgetName r} C} then
		  true
	       else false
	       end
	 in
	    if {Not Ok} then
	       raise eblError(undefinedContext(C) hint:"The context "#C#" is not defined for the widget "#self.WidgetName) end
	    else
	       RenderContext<-C
	       {self.Conn broadcast(cc)}
	    end
	 end
	 meth getContext($)
	    @RenderContext
	 end
	 meth getRenderClass($)
	    O
	    O1={Dictionary.condGet self.Contexts @RenderContext unit}
	    if O1==unit then
	       if @Builder==unit then
		  %% not builder associated to this proxy => use the global repository
		  O={CondSelect {Dictionary.condGet RenderClassRepository self.WidgetName r} @RenderContext unit}
	       else
		  O={@Builder.getRenderClass self.WidgetName @RenderContext}
	       end
	    else
	       O=O1
	    end
	 in
	    if O==unit then
	       raise eblError(undefinedContext(@RenderContext) hint:"The context "#@RenderContext#" is not defined for the widget "#self.WidgetName) end
	       unit
	    else
	       O
	    end
	 end
	 meth destroy
	    {self.Conn close}
	    EventPort<-unit
	    {Dictionary.removeAll self.Clients}
	    {Dictionary.removeAll self.Answer}
	    {ForAll {Dictionary.items self.Stores}
	     proc{$ V} {V destroy} end}
	    {Dictionary.removeAll self.Stores}
	 end
	 meth Recv(M)
	    case M
	    of add(Id) then
	       skip
	    [] message(Id connect) then
	       %% a remote site connects to this site
	       %%   what should we do to other already connected sites ?
	       %% => disconnect/readonly/readwrite
	       {@ConnPolicy incoming(Id)}
	       %% checks if the connection was accepted
	       if {Not {Dictionary.member self.Clients Id}} then
		  %% eject this client
		  {self.Conn eject(Id)}
	       end
	    [] message(_ err(S E O)) then
	       {System.showInfo "------------------------------------------------------"}
	       {System.showInfo "| Unexpected (invisible to application) error"}
	       if S\="" then
		  {System.showInfo "------------------------------------------------------"}
		  {System.showInfo S}
	       end
	       if O\=unit then
		  {System.showInfo "------------------------------------------------------"}
		  {System.show O}
	       end
	       {Error.printException E}
	    [] message(Id z(A B)) then
	       {self.Conn asend(Id z(A B))}
	    [] message(Id r(M B)) then
	       lock self.StateLock then
		  if {Dictionary.condGet self.Clients Id unit}==rw then
		     r(R Id K MV V)={Dictionary.condGet self.Answer M r(_ _ unit _ _)}
		  in
		     if K\=unit then
			case B
			of ok(true) then
			   R=true
			   {{self getStore(Id $)} ForceSet(K MV V)}
			[] ok(X) then
			   R=X
			[] error(X) then
			   R={Value.failed X}
			end
			{Dictionary.remove self.Answer M}
		     end
		  end
	       end
	    [] message(_ rih(R P)) then
	       {self importHere(R P)}
	    [] message(_ rs(I K V)) then
	       {{self getStore(I $)} RSet(K V)}
	    [] message(Id g(M V)) then
	       lock self.StateLock then
		  if {Dictionary.condGet self.Clients Id unit}==rw then
		     g(R Id K)={Dictionary.condGet self.Answer M g(_ _ unit)}
		  in
		     if K\=unit then
			case V
			of ok(X) then
			   R=X
			   {{self getStore(Id $)} set(K X)}
			[] error(X) then
			   R={Value.failed X}
			end
			{Dictionary.remove self.Answer M}
		     end
		  end
	       end
	    [] message(Id a(M Q)) then
	       if {Dictionary.condGet self.Clients Id unit}==rw then
		  O={Dictionary.condGet self.Answer M unit}
	       in
		  case O of a(R _) then
		     {Dictionary.remove self.Answer M}
		     case Q
		     of ok(X) then
			R=X
		     [] error(X) then
			R={Value.failed X}
		     end
		  else skip end
	       end
	    [] message(Id t(M Q)) then
	       if {Dictionary.condGet self.Clients Id unit}==rw then
		  O={Dictionary.condGet self.Answer M unit}
	       in
		  case O of t(R _) then
		     {Dictionary.remove self.Answer M}
		     case Q
		     of ok(X) then
			R=X
		     [] error(X) then
			R={Value.failed X}
		     end
		  else skip end
	       end
	    [] message(Id ab(Event B)) then
	       if {Dictionary.condGet self.Clients Id unit}==rw then
		  O={Dictionary.condGet self.Answer Event unit}
	       in
		  case O of ab(R Id _) then
		     {Dictionary.remove self.Answer Event}
		     case B
		     of ok(true) then
			{{self getStore(Id $)} bind(Event)}
			R=true
		     [] ok(X) then
			R=X
		     [] error(X) then
			R={Value.failed X}
		     end
		  else skip end
	       end
	    [] message(_ v(Id A B)) then
	       {{self getStore(Id $)}
		triggerVirtualEvent(A B)}
	    [] message(_ e(Id A B)) then
	       {{self getStore(Id $)} triggerEvent(A B)}
	    [] message(_ d(M)) then
	       {self dropClient(M)}
	    [] message(_ l(Ref)) then
	       {ForAll {Dictionary.entries self.Children}
		proc{$ K#(R#P)}
		   if R==Ref then
		      {Dictionary.remove self.Children K}
		      {{self getStore(main $)}
		       triggerVirtualEvent(lostWidget a(ref:R placementInstructions:P))}
		   end
		end}
%       [] message(_ cc(M)) then
% 	 O={Dictionary.condGet self.Children M unit}
%       in
% 	 if O\=unit then
% 	    {self.Conn broadcast(uc(M ProxyRef PlacementInstructions))}
% 	 end
	    [] message(m M) then
	       {self.Conn broadcast(M)}
	    else skip %{Show m#ignoring#M}
	    end
	 end
	 meth setConnectionPolicy(P)
	    ConnPolicy<-P
	 end
	 meth setEventPort(P)
	    EventPort<-P
	 end
	 meth createRemoteEnvironment($)
	    {New RemoteEnv Init}
	 end
	 meth getRef($)
	    {self.Conn getRef($)}
	 end
	 meth getRenderIds($)
	    {Dictionary.keys self.Clients}
	 end
	 meth getChildrenIds($)
	    {Dictionary.keys self.Children}
	 end
	 meth getChildInfo(K $)
	    {Dictionary.condGet self.Children K unit}
	 end
	 meth disconnect(Id)
	    if {Dictionary.member self.Clients Id} then
	       {self.Conn eject(Id)}
	       {Dictionary.remove self.Clients Id}
	       {{self getStore(main $)}
		triggerVirtualEvent(disconnect a(id:Id))}
	    end
	 end
	 meth connect(Id)
	    if {List.member Id {self.Conn getPeers($)}} andthen {Not {Dictionary.member self.Clients Id}} then
	       {Dictionary.put self.Clients Id rw}
	       {{self getStore(main $)}
		triggerVirtualEvent(connect a(id:Id))}
	       {self.Conn asend(Id c({self getState($)}))}
	       {ForAll {Dictionary.entries self.Answer}
		proc{$ K#V}
		   case V
		   of r(_ I KK MV _) then
		      {self.Conn asend(Id r(K I KK MV))}
		   else
		      {self.Conn asend(Id {Record.adjoinAt V 1 K})}
		   end
		end}
% 	 {ForAll {Dictionary.entries self.Answer}
% 	  proc{$ K#V}
% 	     case V
% 	     of ab(P _) then {self.Conn asend(Id ab(K P))}
% 	     [] r(A B _) then {self.Conn asend(Id r(K A B))}
% 	     [] g(A _) then {self.Conn asend(Id g(K A))}
% 	     [] a(Q _) then {self.Conn asend(Id a(K Q))}
% 	     end
% 	  end}
	    end
	 end
	 meth createRemoteHere(Env parent:Parent<=unit)
	    {Env put(proxy {self getRef($)})}
	    EventPort Ob
	    {Env put(eventPort EventPort)}
	    thread
	       {ForAll {NewPort $ EventPort} proc{$ P} {P} end}
	    end
	    fun{P Parent}
	       fun{$ E Proxy}
		  Ob
	       in
		  {E put(eventPort EventPort)}
		  {E put(proxy Proxy)}
		  {E put(parent Parent)}
		  {E put(createRemoteHere {P Ob})}
		  Ob={New EBLRemoteManager Init(E FNewWidgetRepository)}
		  Ob
	       end
	    end
	 in
	    {Env put(createRemoteHere {P Ob})}
	    {Env put(parent Parent)}
	    try
	       Ob={New EBLRemoteManager Init(Env FNewWidgetRepository)}
	    catch X then raise eblError(rendererCreationError hint:"Could not create renderer" info:X) end
	    end
	 end
	 meth importHere(ProxyRef PlacementInstructions id:M<=_)
	    B=@Builder
	 in
	    M={NewName}
	    {Dictionary.put self.Children M ProxyRef#PlacementInstructions}
	    {self.Conn broadcast(ih(M ProxyRef PlacementInstructions))}
	    if B\=unit then
	       {B.notifyImportHere self ProxyRef PlacementInstructions}
	    end
	 end
	 meth restoreHere(ProxyRef PlacementInstructions)
	    if {List.some {Dictionary.items self.Children}
		fun{$ R#P} R#P==ProxyRef#PlacementInstructions end} then skip
	    else
	       {self importHere(ProxyRef PlacementInstructions)}
	    end
	 end
	 meth dropClient(M)
	    if {Dictionary.member self.Children M} then
	       {Dictionary.remove self.Children M}
	       {self.Conn broadcast(d(M))}
	    end
	 end
	 meth execEvent(A Args)
	    P=if {Procedure.is A} then proc{$} {Procedure.apply A Args} end
	      elsecase A of L#R then
		 if {Port.is L} then
		    proc{$} {Port.send L {List.toTuple R Args}} end
		 elseif {Object.is L} then
		    proc{$} {L {List.toTuple R Args}} end
		 else unit end
	      else unit end
	 in
	    if P\=unit then
	       {Port.send @EventPort P}
	    end
	 end

	 meth ask(Q R1)
	    M={NewName}
	    R
	 in
	    R1=!!R
	    {Dictionary.put self.Answer M a(R Q)}
	    {self.Conn broadcast(a(M Q))}
	 end
	 meth send(V)
	    {self.Conn broadcast(s(V))}
	 end
	 meth exec(P V)
	    {self.Conn broadcast(e(P V))}
	 end
	 meth return(P V R1)
	    M={NewName}
	    R
	 in
	    R1=!!R
	    {Dictionary.put self.Answer M t(R P V)}
	    {self.Conn broadcast(t(M P V))}
	 end
	 meth getState($)
	    %% obtains the current state
	    %% state is characterized by
	    %%   State dictionary and Event dictionary
	    lock self.StateLock then
	       if @Builder==unit then unit else @Builder.ref end#{self getRenderClass($)}#
	       {Dictionary.entries self.Children}#
	       {List.map {Dictionary.entries self.Stores}
		fun{$ K#V} K#{V getState($)} end}
	    end
	 end
      end


      %% ---------------------------------------------

      EBLRemoteManager

      local

	 ExecEvent={NewName}
	 Set={NewName}
	 Bind={NewName}
	 Marshall={NewName}
	 UnMarshall={NewName}
	 Inc={NewName}
	 Dec={NewName}

      in
	 class RemoteStore
	    feat
	       State
	       Parent
	       Env
	       RemoteEventDict
	       EventDict
	       VirtualEventDict
	       IVirtualEventDict
	       Bounces
	       Name
	       Answers
	       !Conn
	    attr
	       RenderMarshaller
	       ParametersType
	    prop
	       locking
	    meth !Init(P N)
	       self.Name=N
	       self.Parent=P
	       self.Conn=P.Conn
	       self.Env={P getEnv($)}
	       self.EventDict={Dictionary.new}
	       self.VirtualEventDict={Dictionary.new}
	       self.IVirtualEventDict={Dictionary.new}
	       self.Answers={WeakDictionary.new _}
	       {WeakDictionary.close self.Answers}
	       self.State={Dictionary.new}
	       self.RemoteEventDict={Dictionary.new}
	       self.Bounces={Dictionary.new}
	       RenderMarshaller<-p
	       ParametersType<-p
	    end
	    meth setRenderMarshaller(P)
	       RenderMarshaller<-P
	    end
	    meth setParametersType(P)
	       ParametersType<-P
	    end
	    meth !UnMarshall(K V $)
	       if {Not {HasFeature @ParametersType K}} then
		  V
	       else
		  T={CondSelect @RenderMarshaller @ParametersType.K p}
	       in
		  if {HasFeature T s2u} then
		     case {Procedure.arity T.s2u}
		     of 2 then
			{T.s2u V}
		     [] 3 then
			{T.s2u V self}
		     else
			{Exception.raiseError eblError(unknownParameter(K)
						       hint:"Internal error: invalid arity for the s2u render procedure of the parameter "#K)}
			V
		     end
		  else
		     V
		  end
	       end
	    end
	    meth !Marshall(K V $)
	       if {Not {HasFeature @ParametersType K}} then
		  V
	       else
		  T={CondSelect @RenderMarshaller @ParametersType.K p}
	       in
		  if {HasFeature T u2s} then
		     case {Procedure.arity T.u2s}
		     of 2 then
			{T.u2s V}
		     [] 3 then
			{T.u2s V self}
		     else
			{Exception.raiseError eblError(unknownParameter(K)
						       hint:"Internal error: invalid arity for the u2s render procedure of the parameter "#K)}
			V
		     end
		  else
		     V
		  end
	       end
	    end
	    meth !Inc(K)
	       lock
		  O N
	       in
		  {Dictionary.condExchange self.Bounces K 0 O N}
		  N=O+1
	       end
	    end
	    meth !Dec(K)
	       lock
		  O N
		  A={WeakDictionary.condGet self.Answers K unit}
	       in
		  if A==unit then skip else A.2=unit end
		  {Dictionary.condExchange self.Bounces K 0 O N}
		  if O==1 then
		     {Dictionary.remove self.Bounces K}
		     N=0
		  else
		     N=O-1
		  end
	       end
	    end
	    meth set(K V)
	       %% render asks for a value K to be set to V
	       %% we will achieve that by bouncing through the proxy
	       %% : we ask the proxy to set K to V and block until
	       %%   we receive the instruction to do it back
	       O N
	    in
	       {WeakDictionary.condExchange self.Answers K unit#unit O N}
	       {Wait O.2}
	       N=V#_
	       {self TriggerVirtualEvent(K a(value:V))}
	       {self Inc(K)}
	       {self.Conn asend(m rs(self.Name K {self Marshall(K V $)}))}
	       {self.Conn asend(m z(self.Name K))}
	    end
	    meth !Set(K V silent:Silent<=false)
	       if {Dictionary.condGet self.Bounces K 0}==0 then
		  {Dictionary.put self.State K V}
		  if Silent==false then
		     MV={self UnMarshall(K V $)}
		  in
		     {{self.Parent getWidget($)} set(self.Name K MV)}
		  end
	       end
	    end
	    meth get(K V1)
	       O={WeakDictionary.condGet self.Answers K unit}
	       V
	    in
	       if O==unit then
		  {Dictionary.get self.State K V}
	       else
		  V=O.1
	       end
	       V={self UnMarshall(K V1 $)}
	    end
	    meth !Bind(Event P)
	       {Dictionary.put self.RemoteEventDict Event P}
	    end
	    meth removeBind(Event)
	       {Dictionary.remove self.RemoteEventDict Event}
	    end
	    meth getState($)
%	       {ForAll {WeakDictionary.items self.Answers} proc{$ V} {Wait V.2} end}
	       {List.map {Dictionary.entries self.State}
		fun{$ K#V}
		   K#{self UnMarshall(K V $)}
		end}
	    end
	    meth getBinding($) {Dictionary.entries self.RemoteEventDict} end
	    meth getName($) self.Name end
	    meth getManager($)
	       self.Parent
	    end
	    meth triggerEvent(Code Args)
	       {Port.send {self.Env get(eventPort $)}
		proc{$}
		   {self TriggerEvent(Code Args)}
		end}
	    end
	    meth triggerVirtualEvent(Virtual FullArgs)
	       {Port.send {self.Env get(eventPort $)}
		proc{$}
		   LV={Dictionary.condGet self.VirtualEventDict Virtual nil}
		in
		   if LV==nil then
		      {self.Conn asend(m v(self.Name Virtual FullArgs))}
		   else
		      {ForAll LV
		       proc{$ Code}
			  _#_#G={Dictionary.condGet self.EventDict Code unit#unit#nil}
			  fun{Loop L}
			     case L of K|Ls then
				if {HasFeature FullArgs K} then FullArgs.K|{Loop Ls}
				else
				   nil
				end
			     else nil end
			  end
			  Args={Loop G} %{List.map G fun{$ K} FullArgs.K end}
		       in
			  {self TriggerEvent(Code Args)}
		       end}
		   end
		end}
	    end
	    meth TriggerVirtualEvent(Virtual FullArgs)
	       {Port.send {self.Env get(eventPort $)}
		proc{$}
		   LV={Dictionary.condGet self.VirtualEventDict Virtual nil}
		in
		   {ForAll LV
		    proc{$ Code}
		       _#A#G={Dictionary.condGet self.EventDict Code unit#unit#nil}
		       Args={List.map G fun{$ K} FullArgs.K end}
		    in
		       {self.Parent ExecEvent(A Args)}
		    end}
		end}	 
	    end
	    meth TriggerEvent(Code Args)
	       _#A#_={Dictionary.condGet self.EventDict Code unit#unit#unit}
	    in
	       if A==unit then
		  %% this is a remote event
		  {self.Conn asend(m e(self.Name Code Args))}
	       else
		  %% this is a local event
		  {self.Parent ExecEvent(A Args)}
	       end
	    end	 
	    meth createEvent(event:E<=unit action:A args:G<=nil unbind:U<=_ code:C)
	       %% registers event E to run action A, with parameters G M1 M2 and D, U is a zeroprocedure that unbinds the event, returns the code C to trigger the event
	       C={NewName}
	       {Dictionary.put self.EventDict C E#A#G} % {List.toRecord a {List.map G fun{$ I} I#unit end}}}
	       proc{U}
		  {Dictionary.remove self.EventDict C}
		  if {Dictionary.member self.IVirtualEventDict C} then
		     Virtual={Dictionary.get self.IVirtualEventDict C}
		     {Dictionary.remove self.IVirtualEventDict C}
		     Old={Dictionary.condGet self.VirtualEventDict Virtual nil}
		     New={List.filter Old fun{$ I} I\=C end}
		  in
		     if New==nil then {Dictionary.remove self.VirtualEventDict Virtual}
		     else
			{Dictionary.put self.VirtualEventDict Virtual New}
		     end
		  end
	       end
	    end
	    meth registerVirtualEvent(Virtual Code)
	       %% registers a code to execute upon a virtual event
	       {Dictionary.put self.VirtualEventDict Virtual Code|{Dictionary.condGet self.VirtualEventDict Virtual nil}}
	       {Dictionary.put self.IVirtualEventDict Code Virtual}
	    end
	    meth destroy
	       {Dictionary.removeAll self.State}
	       {Dictionary.removeAll self.RemoteEventDict}
	       {Dictionary.removeAll self.EventDict} %% Simply relying on the toolkit's garbage collection
	       {Dictionary.removeAll self.VirtualEventDict}
	       {Dictionary.removeAll self.IVirtualEventDict}
	       {Dictionary.removeAll self.Bounces}
	    end
	 end

	 {SiteProperty.put com Com}

	 class EBLRemoteManager
	    feat
	       !Conn
	       Id
	       Env
	       Handle
	       Children
	       Opened
	       Closed
	       Stores
	       Build
	       !WidgetRepository
	    attr
	       Builder
	       OnDestroy
	    prop locking
	    meth !Init(E FNewWidgetRepository)
	       lock
		  self.WidgetRepository=FNewWidgetRepository
		  Ref={E get(proxy $)}
%	    EventPort={E get(eventPort $)}
	       in
		  Builder<-unit
		  self.Build={ByNeed fun{$} {self.WidgetRepository @Builder} end}
		  OnDestroy<-proc{$} skip end
		  self.Env=E
		  self.Id={NewName}
		  self.Conn={New Com.com init(self.Id slave proc{$ M}
							       lock
%								  {Show rem#M#self.Handle#self.Opened}
								  if {IsFree self.Opened} then
								     case M
								     of add(m) then
									{self.Conn asend(m connect)} %% should also provide capability and rendererclass information
								     [] message(m c(...)) then
									{self Recv(M)}
								     [] disconnected then
									{self Recv(M)}
								     else skip
								     end
								  elseif {IsFree self.Closed} then
								     {self Recv(M)}
								  end
							       end
							    end)}
		  {self.Conn open(Ref)}
		  self.Children={Dictionary.new}
		  self.Stores={Dictionary.new}
	       end
	    end
	    meth destroy
	       %% this method should destroy this widget
	       %% pre : can be one of different states
	       %%       already logically connected, not already logically connected
	       %%       already logically disconnected, not already dislogically connected
	       %%       already disconnected
	       %%       widget created, widget not yet created
	       %%       also children widgets may exist, and should be destroyed correctly
	       %%       and last but not least: this method can be called out of the self.Conn event processor
	       %%           or from a separated thread
	       %%       also it might turn out this function is called several times

	       %%
	       %%  self.Children => contains children EBLRemoteManager of this widget
	       %%  self.Opened => bound when self.Handle has been created
	       %%  self.Closed => bound when {self.Handle destroy} has been executed
%      lock
	       try {self.Conn close} catch error(notYetOpened) then skip end
	       if {IsDet self.Opened} then
		  if {IsFree self.Closed} then
		     C={Dictionary.items self.Children}
		     L={List.map C
			fun{$ H}
			   S
			in
			   thread
			      {H destroy}
			      S=unit
			   end
			end}
		  in
		     {ForAll L Wait}
		     try
			{self.Handle destroy}
		     catch _ then skip end
		     {ForAll {Dictionary.items self.Stores}
		      proc{$ V}
			 {V destroy}
		      end}
		     {Dictionary.removeAll self.Children}
		     local
			Parent={self.Env condGet(parent unit $)}
		     in
			if Parent\=unit then
			   {Parent LostCon(self)}
			end
		     end
		     {self.Env destroy}
		     {@OnDestroy}
		  end
	       end
	       self.Closed=unit
%      end
	    end
	    meth getEnv($) self.Env end
	    meth getStore(Name $)
	       O N
	       {Dictionary.condExchange self.Stores Name unit O N}
	    in
	       if O==unit then
		  N={New RemoteStore Init(self Name)}
	       else
		  N=O
	       end
	       N
	    end
	    meth getStores($)
	       {Dictionary.items self.Stores}
	    end
	    meth get(I K V)
	       {{self getStore(I $)} get(K V)}      
	    end
	    meth getState(I V)
	       {{self getStore(I $)} getState(V)}      
	    end
	    meth set(I K V)
	       {{self getStore(I $)} set(K V)}      
	    end
	    meth getChildren($) {Dictionary.items self.Children} end
	    meth getWidget($) self.Handle end
	    meth refToId(R $)
	       {self.Conn getIdFromRef(R $)}
	    end
	    meth LostCon(Child)
	       {ForAll {Dictionary.entries self.Children}
		proc{$ K#O}
		   if O==Child then
		      {Dictionary.remove self.Children K}
		      try
			 {self.Conn asend(m l({Child.Env get(proxy $)}))}
		      catch _ then skip end % ignore send errors
		   end
		end}
	    end
	    meth Recv(M)
	       lock
		  case M
		  of opening then skip
		  [] connected then skip
		  [] add(m) then skip
		  [] add(_) then skip
		  [] disconnected then
		     {self destroy}
		  [] error(m) then
		     thread
			%% the Com class is not reentrant with the message processing, so we need to destroy
			%% in a separate thread
			{self destroy}
		     end
% 		     local
% 			Parent={self.Env get(parent $)}
% 		     in
% 			if Parent\=unit then
% 			   {Parent LostCon(self)}
% 			end
% 		     end
		  [] remove(m) then
		     thread
			try {self.Conn close} catch _ then skip end
		     end
		  elseif M.1==m then
		     case M.2
		     of c(B#Class#Children#Stores) then
			self.Opened=unit
			Builder<-B
			{ForAll Stores
			 proc{$ K#V}
			    S={self getStore(K $)}
			 in
			    {ForAll V.1
			     proc{$ A#B} {S Set(A B silent:true)} end}
			    {ForAll V.2
			     proc{$ A#B} {S Bind(A B)} end}
			    {S setRenderMarshaller(V.3)}
			    {S setParametersType(V.4)}
			 end}
			local
			   class RenderClass from Class meth !Init skip end
			   end
			in
			   self.Handle={New RenderClass Init}
			   try
			      {self.Handle init(self)}
			      {ForAll Children
			       proc{$ K#V}
				  ProxyRef#PlacementInstructions=V
			       in
				  {self ImportHere(K ProxyRef PlacementInstructions)}
			       end}
			   catch X then
			      {self reportError(oz:init
						error:X)}
			   end
			end
		     [] sr(I P) then
			{{self getStore(I $)} setRenderMarshaller(P)}
		     [] sp(I P) then
			{{self getStore(I $)} setParametersType(P)}			
		     [] b(B) then
			if @Builder==unit then Builder<-B end
		     [] z(Id K) then
			{{self getStore(Id $)} Dec(K)}
		     [] r(M Id K V) then %%%%%%%%%%%%%%%%
			R X
		     in
			try
			   MV={{self getStore(Id $)} UnMarshall(K V $)}
			in
			   {self.Handle remoteSet(Id K MV R)}
			   X=true
			catch Z then X=Z end
			thread
			   {Wait X}
			   try
			      if X==true then
				 {{self getStore(Id $)} Inc(K)}
				 {self.Conn asend(m r(M ok(R)))}
			      else
				 {self.Conn asend(m r(M error(X)))}
			      end
			   catch error(comError(notConnected ...) ...) then skip
			   [] X then
			      {self reportError(oz:remoteSet(Id K V)
						error:X)}
			   end
			end
		     [] a(M Q) then
			R X
		     in
			try
			   {self.Handle ask(Q R)}
			   X=true
			catch Z then X=Z end
			thread
			   {Wait X}
			   try
			      if X==true then
				 {self.Conn asend(m a(M ok(R)))}
			      else
				 {self.Conn asend(m a(M error(X)))}
			      end
			   catch error(comError(notConnected ...) ...) then skip end
			end
		     [] s(Q) then
			try
			   {self.Handle send(Q)}
			catch X then
			   {self reportError(oz:send(Q)
					     error:X)}
			end
		     [] g(M Id K) then %%%%%%%%%%%%%%%%%%%%%%%%%
			R X
		     in
			try
			   {self.Handle remoteGet(Id K R)}
			   X=true
			catch Z then X=Z end
			thread
			   {Wait X}
			   try
			      if X==true then
				 {self.Conn asend(m g(M ok(R)))}
			      else
				 {self.Conn asend(m g(M error(X)))}
			      end
			   catch error(comError(notConnected ...) ...) then skip end
			end
		     [] s(Id K V) then %%%%%%%%%%%%%%%%%%%%%
			try
			   Store={self getStore(Id $)}
			in
			   {Store Set(K V)}
			catch X then
			   {self reportError(oz:set(Id K V)
					     error:X)}
			end
		     [] ab(Event Id P) then %%%%%%%%%%%%%%%%%%%%%%%%%
			R X
		     in
			try
			   {self.Handle askBind(Id Event P R)}
			   X=true
			catch Z then X=Z end
			thread
			   {Wait X}
			   try
			      if X==true then
				 {self.Conn asend(m ab(Event ok(R)))}
			      else
				 {self.Conn asend(m ab(Event error(X)))}
			      end
			   catch error(comError(notConnected ...) ...) then skip end
			end
		     [] b(Event Id P) then %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			try
			   {{self getStore(Id $)} Bind(Event P)}
			   {self.Handle bind(Id Event P)}
			catch X then
			   {self reportError(oz:bind(Event Id P)
					     error:X)}
			end
		     [] u(Event Id) then %%%%%%%%%%%%%%%%%%%%%%%%
			try
			   {{self getStore(Id $)} removeBind(Event)}
			   {self.Handle removeBind(Id Event)}
			catch X then
			   {self reportError(oz:unbind(Event Id)
					     error:X)}
			end
		     [] ih(M ProxyRef PlacementInstructions) then
			{self ImportHere(M ProxyRef PlacementInstructions)}    
		     [] d(M) then
			Ob={Dictionary.condGet self.Children M unit}
		     in
			if Ob\=unit then
			   {Dictionary.remove self.Children M}
			   try
			      {self.Handle remove({Ob getWidget($)})}
			   catch X then
			      {self reportError(oz:remote(M)
						error:X)}
			   end
			   thread
			      {Ob.Conn close}
			   end
			   {Wait Ob.Closed}
			end
		     [] cc then
			%% this renderer should be replaced by another one
			Parent={self.Env get(parent $)}
		     in
			if Parent==unit then
			   EV={self.Env clone($)}
			   EventPort={self.Env get(eventPort $)}
			   Ob
			   fun{P Parent}
			      fun{$ E Proxy}
				 Ob
			      in
				 {E put(eventPort EventPort)}
				 {E put(proxy Proxy)}
				 {E put(parent Parent)}
				 {E put(createRemoteHere {P Ob})}
				 Ob={New EBLRemoteManager Init(E self.WidgetRepository)}
				 Ob
			      end
			   end
			in
			   {EV put(createRemoteHere {P Ob})}
			   OnDestroy<-proc{$}
					 try
					    Ob={New EBLRemoteManager Init(EV self.WidgetRepository)}
					 catch X then raise eblError(rendererCreationError hint:"Could not create renderer" info:X) end
					 end
				      end
			   thread
			      {self.Conn close}
			   end
			else
			   TId={self.Env get(id $)}
			in
			   try
			      {Parent.Conn asend(Parent.Id rf(TId {self.Env get(proxy $)} {self.Env get(placementInstructions $)}))}
			   catch error(comError(notConnected ...) ...) then skip end
			end
		     [] rf(M ProxyRef PlacementInstructions) then
			Ob={Dictionary.condGet self.Children M unit}
		     in
			if Ob\=unit then
			   {Dictionary.remove self.Children M}
			   {self.Handle remove({Ob getWidget($)})}
			   thread
			      {Ob.Conn close}
			   end
			   {Wait Ob.Closed}
			   {self ImportHere(M ProxyRef PlacementInstructions)}
			end
		     [] t(M P V) then
			R X
		     in
			try
			   R={P self.Env V}
			   X=true
			catch Z then X=Z end
			thread
			   {Wait X}
			   try
			      if X==true then
				 {self.Conn asend(m t(M ok(R)))}
			      else
				 {self.Conn asend(m t(M error(X)))}
			      end
			   catch error(comError(notConnected ...) ...) then skip end
			end
		     [] e(P V) then
			try
			   {P self.Env V}
			catch X then
			   {self reportError(oz:exec(P V)
					     error:X)}
			end
		     else
			{self reportError(oz:self.Id#M
					  string:"A message was ignored")}
		     end
		  elsecase M
		  of message(_ rf(M ProxyRef PlacementInstructions)) then
		     Ob={Dictionary.condGet self.Children M unit}
		  in
		     if Ob\=unit then
			{Dictionary.remove self.Children M}
			{self.Handle remove({Ob getWidget($)})}
			thread
%		     {Ob destroy}
			   {Ob.Conn close}
			end
			{Wait Ob.Closed}
			{self ImportHere(M ProxyRef PlacementInstructions)}
		     end
		  else
		     {self reportError(oz:self.Id#M
				       string:"A message was ignored")}
		  end
	       end
	    end
	    meth reportError(string:String<=""
			     error:Error<=eblError
			     oz:Oz<=unit)
	       {self.Conn asend(m err(String Error Oz))}
	    end
	    meth ImportHere(M ProxyRef PlacementInstructions)
	       E={New RemoteEnv Init}
	       {self.Handle setChildEnvironment(E PlacementInstructions)}
	       {E put(placementInstructions PlacementInstructions)}
	       {E put(id M)}
	    in
	       try
		  Ob={{self.Env get(createRemoteHere $)} E ProxyRef}
	       in
		  {Wait {Ob getWidget($)}}
		  {Dictionary.put self.Children M Ob}
		  {self.Handle importHere({Ob getWidget($)} PlacementInstructions)}
	       catch X then
		  {self reportError(oz:importHere(M ProxyRef PlacementInstructions)
				    error:X)}
		  {self.Conn asend(m d(M))}
	       end
	    end
	    meth createRemoteHere(E render:R<=_)
	       Ob={{self.Env get(createRemoteHere $)} E {E get(proxy $)}}
	       {Wait {Ob getWidget($)}}
	    in
	       {Dictionary.put self.Children {NewName} Ob}
	       R=Ob
	    end
	    meth !ExecEvent(A Args)
	       P=if {Procedure.is A} then proc{$} {Procedure.apply A Args} end
		 elsecase A of L#R then
		    if {Port.is L} then
		       proc{$} {Port.send L {List.toTuple R Args}} end
		    elseif {Object.is L} then
		       proc{$} {L {List.toTuple R Args}} end
		    else unit end
		 else unit end
	    in
	       if P\=unit then
		  {P}
	       end
	    end
	    meth build(Desc V)
	       {Wait self.Build}
	       V={self.Build.build Desc}
	    end
	    meth createRemoteEnvironment($)
	       {New RemoteEnv Init}
	    end
	    meth importHere(R P)
	       %% asks the proxy site to import
	       {self.Conn asend(m rih(R p))}
	    end
	    meth displayHere(R P)
	       {self ImportHere({NewName} R P)}
	    end
	 end
      end

      fun{FNewWidgetRepository1 Source}
	 Repository={Dictionary.new}
	 Alias={Dictionary.new}
	 DefaultLook={NewLook}
	 proc{RegisterAs WidgetName Class Fun}
	    {Dictionary.put Repository WidgetName Class#Fun}
	 end
	 proc{Register Class Fun}
	    {RegisterAs Class.widgetName Class Fun}
	 end
	 proc{RegisterAlias WidgetName Fun}
	    {Dictionary.put Alias WidgetName Fun}
	 end
	 RenderClassCache={Dictionary.new}
	 fun{GetRenderClass WidgetName RenderContext}
	    if Source==unit then
	       {CondSelect {Dictionary.condGet RenderClassRepository WidgetName r} RenderContext unit}
	    else
	       O N
	       {Dictionary.condExchange RenderClassCache WidgetName unit O N}
	       if O==unit then
		  N={Dictionary.new}
	       else
		  N=O
	       end
	       O1 N1
	       {Dictionary.condExchange N RenderContext unit O1 N1}
	       if O1==unit then
		  C={New Com.com init({NewName} slave
				      proc{$ M}
					 case M
					 of disconnected then
					    try N1=unit catch _ then skip end
					 [] message(b r(_ _ R)) then
					    N1=R
					    thread {C close}
					    end
					 else skip end
				      end)}
		  {C open(Source)}
		  {C asend(b r(WidgetName RenderContext))}
	       in
		  thread
		     {Delay 30000}
		     try {C close} catch _ then skip end
		     try N1=unit catch _ then skip end	       
		  end
	       else
		  N1=O1
	       end
	    in
	       N1
	    end
	 end
	 fun{GetClassFun D}
	    if Source==unit then
	       {Dictionary.condGet Repository D unit#unit}
	    else
	       O N
	       {Dictionary.condExchange Repository D missing O N}
	    in
	       if O==missing then
		  %% we need to ask Source for the answer
		  C={New Com.com init({NewName} slave
				      proc{$ M}
					 case M
					 of disconnected then
					    try N=unit#unit catch _ then skip end
					 [] message(b c(_ R)) then
					    N=R
					    thread {C close}
					    end
					 else skip end
				      end)}
	       in
		  {C open(Source)}
		  {C asend(b c(D))}
		  thread
		     {Delay 30000}
		     try {C close} catch _ then skip end
		     try N=unit#unit catch _ then skip end	       
		  end
	       else
		  N=O
	       end
	       {Wait N} N
	    end
	 end
	 fun{GetAlias D}
	    if Source==unit then
	       {Dictionary.condGet Alias D unit}
	    else
	       O N
	       {Dictionary.condExchange Alias D missing O N}
	    in
	       if O==missing then
		  %% we need to ask Source for the answer
		  C={New Com.com init({NewName} slave
				      proc{$ M}
					 case M
					 of disconnected then
					    try N=unit#unit catch _ then skip end
					 [] message(b a(_ R)) then
					    N=R
					    thread {C close}
					    end
					 else skip end
				      end)}
	       in
		  {C open(Source)}
		  {C asend(b a(D))}
		  thread
		     {Delay 30000}
		     try {C close} catch _ then skip end
		     try N=unit#unit catch _ then skip end	       
		  end
		  {Wait N}
	       else
		  N=O
	       end
	       {Wait N} N
	    end
	 end
	 GathererClass={NewCell
			class $ end}
	 CurrentBuilders={NewCell nil}
	 proc{RegisterBuilder ThId C}
	    O N
	    {Cell.exchange CurrentBuilders O N}
	 in
	    N=ThId#C|O
	 end
	 proc{UnregisterBuilder ThId}
	    O N
	    {Cell.exchange CurrentBuilders O N}
	 in
	    N={List.filter O fun{$ K#_} K\=ThId end}
	 end
	 proc{NotifyImportHere Manager Ref P}
	    ThId={Thread.this}
	    proc{Loop L}
	       case L
	       of nil then skip
	       [] !ThId#C|_ then
		  O N
	       in {Cell.exchange C O N}
		  N=Manager#Ref#P|O
	       else {Loop L.2}
	       end
	    end
	 in
	    {Loop {Access CurrentBuilders}}
	 end
	 GetAttr={NewName}
	 fun{Build Desc}
	    EventPort
	    thread
	       {ForAll {NewPort $ EventPort}
		proc{$ P} {P} end}
	    end
	    Ids={Dictionary.new}
	    Aliases={Dictionary.new}
	    DefaultLook={NewLook}
	    fun{Flatten Desc}
	       F={GetAlias {Label Desc}}
	    in
	       if F==unit then Desc else
		  {Flatten {F Desc}}
	       end
	    end
	    ThId={Thread.this}
	    InitialGeometry={NewCell nil}
	    {RegisterBuilder ThId InitialGeometry}
	    ParentClass={Access GathererClass}
	    TempGatherer={New
			  class $ from ParentClass
			     meth !Init skip end
			     meth !GetAttr(K $) @K end
			  end
			  Init}
	    try {TempGatherer init} catch _ then skip end
	    fun{SubBuild Desc1}
	       Desc={Flatten Desc1}
	       Class#Fun={GetClassFun {Label Desc}}
	       if Class==unit then
		  {Exception.raiseError eblError(unknownWidget({Label Desc}) hint:"Unknown widget "#{Label Desc})}
	       end
	       Id={NewName}
	       Handle={New Class init}
	       {Dictionary.put Ids Id Handle}
	       if {HasFeature Class LookPort} then
		  {Handle setLook(DefaultLook)}
	       end
	       D1={Record.filterInd Desc
		   fun{$ K V}
		      case K
		      of handle then
			 V=Handle
			 false
		      [] id then
			 V=Id
			 false
		      [] name then
			 {Dictionary.put Aliases V Handle}
			 false
		      [] look then
			 if {HasFeature Class LookPort} then
			    {Handle setLook(V)}
			    false
			 else
			    true
			 end
		      else
			 true
		      end
		   end}
	    in
	       {Fun e(build:SubBuild
		      builder:Builder
		      handle:Handle
		      gatherer:TempGatherer
		      eventPort:EventPort
		      id:Id
		      desc:D1)}
	       Handle
	    end
	    {SubBuild Desc _}
	    class Gatherer from ParentClass
	       feat Constraints
	       meth !Init skip end
	       meth getAllIds($)
		  {Dictionary.keys Ids}
	       end
	       meth getAllItems($)
		  {Dictionary.items Ids}
	       end
	       meth getAllNames($)
		  {Dictionary.keys Aliases}
	       end
	       meth getDefaultLook($)
		  DefaultLook
	       end
	       meth restoreInitialGeometry
		  {ForAll {Access InitialGeometry}
		   proc{$ O#Ref#P}
		      {O restoreHere(Ref P)}
		   end}
	       end
	    end
	    Cl={Class.new [Gatherer]
		{Record.mapInd ParentClass.`ooAttr` 
		 fun{$ K _} {TempGatherer GetAttr(K $)} end}
		{Record.adjoin {Record.mapInd ParentClass.`ooFeat`
				fun{$ K _} TempGatherer.K end}
		 {Record.adjoin {Dictionary.toRecord f Aliases} {Dictionary.toRecord f Ids}}}
		[final sited]}
	 in
	    {UnregisterBuilder ThId}
	    {New Cl Init}
	 end
	 proc{Rcv M}
	    case M
	    of message(Id c(D)) then
	       {Conn asend(Id c(D {GetClassFun D}))}
	    [] message(Id a(D)) then
	       {Conn asend(Id a(D {GetAlias D}))}
	    [] message(Id r(W R)) then
	       {Conn asend(Id r(W R {GetRenderClass W R}))}
	    else skip end
	 end
	 Conn={New Com.com init(b master Rcv)}
	 GetProxyClass=fun{$ C}
			  {Dictionary.get Repository C}.1
		       end
	 Builder=r(register:Register
		   registerAs:RegisterAs
		   registerAlias:RegisterAlias
		   getWidgets:fun{$}
				 {Dictionary.keys Repository}
			      end
		   getWidgetClass:GetProxyClass
		   getProxyClass:GetProxyClass
		   getBuildFun:fun{$ C}
				  {Dictionary.get Repository C}.2
			       end
		   setGathererClass:proc{$ C}
				       if {Class.is C} then
					  {Assign GathererClass C}
				       else
					  {Exception.raiseError eblError(notClass(C)
									 hint:"Could not setGathererClass")}
				       end
				    end
		   setRenderContextClass:SetRenderContextClass
		   build:Build
		   defaultLook:DefaultLook
		   getRenderClass:GetRenderClass
		   notifyImportHere:NotifyImportHere
		   ref:{Conn getRef($)})
      in
	 Builder
      end
   in
      FNewWidgetRepository=FNewWidgetRepository1
      fun{NewEBLProxyManager Name} {New EBLProxyManager Init(Name {SiteProperty.get com})} end
   end
   
   fun{CheckType TypeChecker X V}
      Z={CondSelect TypeChecker X InvalidType}
      P=case Z of A#_ then A else Z end
   in
      {P V}
   end

   fun{GetType Parameters K}
      {CondSelect Parameters K invalid}
   end
   
   fun{GetTypeInfo TypeChecker X}
      Z={CondSelect TypeChecker X InvalidType}
   in
      case Z of _#B then B else "Invalid Type" end      
   end

%    fun{XMarshall Code Marshaller Type V}
%       P={CondSelect {CondSelect Marshaller Type r} Code unit}
%    in
%       if P==unit then V
%       else
% 	 case {Procedure.arity P}
% 	 of 0 then {P V}
% 	 else {Exception.raiseError eblError(cannotMarshall(V)
% 					     hint:"Cannot marshall")}
% 	    unit
% 	 end
%       end
%    end
   
%    fun{Marshall Marshaller Type V}
%       {XMarshall u2s Marshaller Type V}
%    end

%    fun{UnMarshall Marshaller Type V}
%       {XMarshall s2u Marshaller Type V}
%    end

   fun{NewWidgetLook}
      Data={NewCell look}
      Clients={Dictionary.new}
      Lock={NewLock}
      fun{Register P}
	 lock Lock then
	    Id={NewName}
	    {Dictionary.put Clients Id P}
	    proc{Unregister}
	       lock Lock then
		  {Dictionary.remove Clients Id}
	       end
	    end
	 in
	    {Port.send P {Access Data}}
	    r(unregister:Unregister)
	 end
      end
      proc{Set V}
	 lock Lock then
	    {ForAll {Dictionary.items Clients}
	     proc{$ P}
		{Port.send P V}
	     end}
	    {Assign Data V}
	 end
      end
      fun{Get}
	 {Access Data}
      end
   in
      r(register:Register
	set:Set
	get:Get)
   end

   fun{NewLook}
      D={Dictionary.new}
      proc{Set V}
	 {{GetWidgetLook V}.set V}
      end
      fun{Get V}
	 {{GetWidgetLook V}.get}
      end
      fun{GetWidgetLook V}
	 L={Label V}
	 O N
      in
	 {Dictionary.condExchange D L unit O N}
	 if O==unit then
	    N={NewWidgetLook}
	 else
	    N=O
	 end      
      end
   in
      r(set:Set
	get:Get
	getWidgetLook:GetWidgetLook)
   end

   LookPort={NewName}

   fun{AddLookSupport Class}
      class $ from Class
	 attr
	    LookState
	    LookSource
	 feat
	    !LookPort
	    Def
	 meth init(...)=M
	    LookState<-s
	    LookSource<-unit
	    self.Def={Dictionary.new}
	    thread
	       {ForAll {NewPort $ self.LookPort}
		proc{$ S}
		   {self ChgState(S)}
		end}
	    end
	    Class,M
	 end
	 meth set(K V)
	    {Dictionary.put self.Def K unit}
	    Class,set(K V)
	 end
	 meth unset(K)
	    O N
	 in
	    O=LookState<-N
	    {Dictionary.remove self.Def K}
	    if {HasFeature O K} then
	       Class,set(K O.K)
	    else
	       Class,unset(K)
	    end
	    N=O
	 end
	 meth isset(K $)
%	 K
%      in
%	 K=if {HasFeature self synonyms} then self.synonyms.K1 else K1 end
	    {Dictionary.member self.Def K}
	 end
	 meth ChgState(New1)
	    O N
	    New
	 in
	    if {HasFeature self synonyms} then
	       D={Dictionary.new}
	    in
	       {Record.forAllInd New1
		proc{$ K V}
		   {Dictionary.put D {CondSelect self.synonyms K K} V}
		end}
	       New={Dictionary.toRecord r D}
	    else
	       New=New1
	    end
	    O=LookState<-N
	    {Record.forAllInd O
	     proc{$ K _}
		if {Not {self isset(K $)}} then
		   if {HasFeature New K} then
		      Class,set(K New.K)
		   else
		      Class,unset(K)
		   end
		end
	     end}
	    {Record.forAllInd New
	     proc{$ K V}
		if {Not {HasFeature O K}} andthen {Not {self isset(K $)}} then
		   Class,set(K V)
		end
	     end}
	    N=New
	 end
	 meth setLook(L1)
	    L=if {HasFeature L1 getWidgetLook} then
		 {L1.getWidgetLook self.widgetName}
	      else
		 L1
	      end
	    O N
	 in
	    O=LookSource<-N
	    if O\=unit then
	       {O.unregister}
	    end
	    N={L.register self.LookPort}
	 end
	 meth destroy
	    LookState<-unit
	    LookSource<-unit
	    {Dictionary.removeAll self.Def}
	    Class,destroy
	 end
      end
   end

   fun{AddSynonymSupport Class Synonyms}
      class $ from Class
	 feat synonyms
	 meth init(...)=M
	    self.synonyms=Synonyms
	    Class,M
	 end
	 meth set(K V)
	    try
	       Class,set({CondSelect Synonyms K K} V)
	    catch error(kernel('.' synonyms(...) ...) ...) then
	       {Exception.raiseError eblError(unknownSynonym(K) hint:"Unknown parameter "#K#" (no synonym defined)")}
	    end
	 end
	 meth unset(K)
	    Class,unset({CondSelect Synonyms K K})
	 end
	 meth isset(K V)
	    Class,isset({CondSelect Synonyms K K} V)
	 end
	 meth get(K V)
	    Class,get({CondSelect Synonyms K K} V)
	 end
      end
   end

   fun{AddMultiSetGetSupport Class}
      class $ from Class
	 meth set(...)=M
	    E
	 in
	    {Record.forAllInd M
	     proc{$ K V}
		try
		   Class,set(K V)
		catch X then if {IsFree E} then E=X end end
	     end}
	    if {IsDet E} then raise E end end
	 end
	 meth get(...)=M
	    E
	 in
	    {Record.forAllInd M
	     proc{$ K V}
		try
		   Class,get(K V)
		catch X then if {IsFree E} then E=X end end
	     end}
	 end
      end
   end

   fun{CreateWidgetClass D}
%    window(proxy:WindowProxy
% 		     synonyms:Synonyms
% 		     defaultRenderClass:WindowRender)
      WidgetName={CondSelect D.proxy widgetName {Label D}}
   in
      {SetRenderContextClass D.rendererClass WidgetName default
       D.defaultRenderClass}
      {Record.forAllInd {CondSelect D renderers r}
       proc{$ K V}
	  {SetRenderContextClass D.rendererClass WidgetName K V}
       end}
      {AddMultiSetGetSupport
       {AddLookSupport
	{AddSynonymSupport
	 D.proxy
	 {CondSelect D synonyms synonym}}
       }
      }
   end


   NoGlue=r(w:false e:false s:false n:false exph:false expv:false)

   fun{GetGlue D}
      %% transforms a glue record parameter into a record
      %% (see what function returns)
      CG={CondSelect D glue ''}
   in
      if {Atom.is CG} then
	 St={VirtualString.toString CG}
	 W={List.member &w St}
	 E={List.member &e St}
	 N={List.member &n St}
	 S={List.member &s St}
      in
	 r(w:W e:E n:N s:S exph:W andthen E expv:N andthen S)
      else
	 CG
      end
   end

   fun{ToDescGlue G}
      {VirtualString.toAtom
       if G.n then "n" else "" end#
       if G.s then "s" else "" end#
       if G.w then "w" else "" end#
       if G.e then "e" else "" end}
   end

   fun{ToArray Rec}
      %% splits a container record into a list of lists
      %% splitting at newline .
      fun{ParseLine Line Remaining}
	 case Line
	 of newline(...)|Xs then
	    Remaining=Xs nil
	 [] X1|Xs then
	    X={Record.adjoinAt X1 glue {GetGlue X1}}
	 in
	    X|{ParseLine Xs Remaining}
	 else
	    Remaining=nil nil
	 end
      end
      fun{Loop L}
	 Rs
	 R={ParseLine L Rs}
      in
	 if R==nil then nil
	 else R|{Loop Rs}
	 end
      end
      Raw={Loop {List.map
		 {List.filter
		  {Record.toListInd Rec}
		  fun{$ I#_} {IsInt I} end}
		 fun{$ _#E} E end}}
      %% Make all lines the same length
      Len={List.foldL Raw fun{$ Old Line} {Max Old {Length Line}} end 0}
   in
      {List.map Raw
       fun{$ Line}
	  {List.append Line
	   {List.map {List.make Len-{Length Line}}
	    fun{$ E} E=empty(glue:NoGlue) end}}
       end}
   end

   fun{CalcLR Data Horiz}
      %% calculate rows and columns weight
      %% (i.e. when container is resized : either if a row/column must be resized or not)
      if Data==nil then r(h:nil v:nil horiz:Horiz)
      else
	 XD#YD=if Horiz then exph#expv else expv#exph end
	 %% if at least a widget exapnds itselfs in a direction :
	 %% all row/column containing at least a widget expanding itself
	 %% => row/column expand too, otherwise don't expand
	 fun{GetXExpand Data}
	    X1={List.make {Length {List.nth Data 1}}}
	    proc{ParseLine Line X}
	       case Line of E|Es then
		  case X of XX|XXs then
		     if E.glue.XD then XX=true end
		     {ParseLine Es XXs}
		  end
	       else skip end
	    end
	 in
	    {ForAll Data proc{$ Line} {ParseLine Line X1} end}
	    {ForAll X1 proc{$ XX} if {IsFree XX} then XX=false end end}
	    X1
	 end
	 fun{GetYExpand Data}
	    {List.map Data
	     fun{$ Line}
		{List.some Line
		 fun{$ E} E.glue.YD end}
	     end}
	 end
	 %% when no widget expands => If there are constraints on both edges
	 %% of a row/column, it must NOT expand itself (it would be unable to satisfy constraints)
	 %% in other cases, it must expands itself to take all available space of the window.
	 fun{CalcXExpand Data}
	    X1={List.make {Length {List.nth Data 1}}+1}
	    proc{Loop1 Line X}
	       case Line of E|Es then
		  XL|XR|_=X
		  _|XXs=X
	       in
		  if (Horiz andthen (E.glue).w)
		     orelse ({Not Horiz} andthen (E.glue).n) then
		     XL=unit
		  end
		  if (Horiz andthen E.glue.e)
		     orelse ({Not Horiz} andthen E.glue.s) then
		     XR=unit
		  end
		  {Loop1 Es XXs}
		  skip
	       else skip end
	    end
	    fun{Loop2 L}
	       case L
	       of X1|X2|Xs then
		  {Not ({IsDet X1} andthen {IsDet X2})}|{Loop2 X2|Xs}
	       else nil end
	    end
	 in
	    {ForAll Data proc{$ Line} {Loop1 Line X1} end}
	    {Loop2 X1}
	 end
	 fun{CalcYExpand Data}
	    {List.map Data
	     fun{$ Line}
		if Horiz then
		   {List.some Line fun{$ E} E.glue.n end} andthen 
		   {List.some Line fun{$ E} E.glue.s end}
		else
		   {List.some Line fun{$ E} E.glue.w end} andthen 
		   {List.some Line fun{$ E} E.glue.e end}
		end
	     end}
% 	 Y1={List.make {Length Data}+1}
% 	 proc{Loop1 Lines Y}
% 	    case Lines of Line|Ls then
% 	       YT|YB|_=Y
% 	       _|YYR=Y
% 	    in
% 	       if Horiz then
% 		  if {List.some Line fun{$ E} E.glue.n end} then YT=unit end
% 		  if {List.some Line fun{$ E} E.glue.s end} then YB=unit end
% 	       else
% 		  if {List.some Line fun{$ E} E.glue.w end} then YT=unit end
% 		  if {List.some Line fun{$ E} E.glue.e end} then YB=unit end
% 	       end
% 	       {Loop1 Ls YYR}
% 	    else skip end
% 	 end
% 	 fun{Loop2 L}
% 	    case L
% 	    of X1|X2|Xs then
% 	       {Not ({IsDet X1} andthen {IsDet X2})}|{Loop2 X2|Xs}
% 	    else nil end
% 	 end
%       in
% 	 {Loop1 Data Y1}
%	 {Loop2 Y1}
	 end	
	 X1={GetXExpand Data}
	 Y1={GetYExpand Data}
	 X=if {List.all X1 Not} then
	      {CalcXExpand Data} else X1 end
	 Y=if {List.all Y1 Not} then
	      {CalcYExpand Data} else Y1 end
	 Result=if Horiz then r(h:X
				v:Y
				horiz:Horiz)
		else r(h:Y
		       v:X
		       horiz:Horiz)
		end
      in
	 Result
      end
   end

   fun{ContinueLength R}
      %% returns the number of continue in the R list
      case R of continue(...)|Rs then {ContinueLength Rs}+1 else 0 end
   end

   fun{NewWidgetRepository}
      {FNewWidgetRepository unit}
   end

   fun{NewRadioListeners}
      Data={Dictionary.new}
      proc{Register Name Obj Proc}
	 O N
      in
	 {Dictionary.condExchange Data Name nil O N}
	 N=Obj#Proc#{NewCell unit}|O
      end
      proc{Unregister Name Obj}
	 O N
      in
	 {Dictionary.condExchange Data Name nil O N}
	 N={List.filter O
	    fun{$ E#_#_} E\=Obj end}
      end
      proc{SetActive Name Obj}
	 O={Dictionary.condGet Data Name nil}
      in
	 {ForAll O
	  proc{$ E#P#C}
	     if E\=Obj then
		OC NC
	     in
		{Exchange C OC NC}
		thread
		   %% using a thread so that SetActive doesn't block on widgets that need
		   %% to be connected
		   %% the cell is used to order the updates
		   OD ON
		in
		   {Wait OC}
		   {Dictionary.condExchange Data Name nil OD ON}
		   if {List.some OD
		       fun{$ Ei#_#_} Ei==E end} then
		      %% still a member of this radioset
		      {P}
		      NC=unit
		   end
		   ON=OD
		end
	     end
	  end}
      end
   in
      r(register:Register
	unregister:Unregister
	setActive:SetActive)
   end

   fun{NewPublisher P}
      proc{Recv M}
	 case M
	 of message(Id c) then
	    {Conn asend(Id {Dictionary.items Content})}
	 else skip end
      end
      Conn={New Com.com init(m master Recv)}
      Gate={New SC.gate initOn({Conn getRef($)} P)}
      Content={Dictionary.new}
      fun{GetIP}
	 {Gate getIP($)}
      end
      fun{GetPN}
	 {Gate getPN($)}
      end
      proc{Close}
	 {Gate close}
	 {Conn close}
      end
      proc{Subscribe Key Value Desc}
	 {Dictionary.put Content Key Value#Desc}
      end
      proc{UnSubscribe Key}
	 {Dictionary.remove Content Key}
      end
   in
      p(getIP:GetIP
	getPN:GetPN
	close:Close
	subscribe:Subscribe
	unSubscribe:UnSubscribe)
   end

   fun{GetFromPublisher IP P}
      Break
      thread
	 {Delay 30000}
	 Break=unit
      end
      ThId Conn Err
      Result
      thread
	 try
	    {Thread.this}=ThId
	    Ref={SC.take IP P}
	    proc{Recv M}
	       case M
	       of add(m) then
		  {Conn asend(m c)}
	       [] message(m L) then
		  Result=L
	       else skip end
	    end
	 in
	    Conn={New Com.com init({NewName} slave Recv)}
	    {Conn open(Ref)}
	 catch X then Err=X end
	 {WaitOr Result Break}
	 try Err=ok catch _ then skip end
      end
   in
      {WaitOr Break Err}
      thread if {IsDet Conn} then try {Conn close} catch _ then skip end end end
      if {IsDet Result} then
	 Result
      elseif {IsDet Break} then
	 {Exception.raiseError eblError(getPublic(timeOut IP P) hint:"Timed out when trying to GetPublic")}
	 unit
      else
	 {Exception.raiseError eblError(getPublic(Err) hint:"Error when trying to GetPublic")}
	 unit
      end
   end

\ifndef OPI
   
end

\endif