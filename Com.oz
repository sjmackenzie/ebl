functor

   %% todo
   %%  X fault support: automatically disconnect if there is a tempFail/permFail when sending a message
   %%    test fault support
   
import System(show:Show)
   Pickle
   Connection
   Fault
   Error
   
export
   Com
   Ref2Id

define

   fun{Ref2Id Ref}
      {Pickle.unpack Ref}.1
   end
   
   {Error.registerFormatter comError
    fun {$ E}
       T = 'Error: Com module'
    in
       case E
       of comError(C hint:S info:X) then
	  error(kind:T
		msg:S
		items:[hint(l:'Type'
			    m:oz(C))
		       hint(l:'Information'
			    m:oz(X))
		      ])
       []  comError(C hint:S) then
	  error(kind:T
		msg:S
		items:[hint(l:'Type'
			    m:oz(C))])
       end
    end}

   class Com
      prop locking sited
      feat
	 Evt
	 Id
	 Master
	 Pt
	 Main
	 MainId
	 Acks
	 Opened
	 Closed
	 LockAck
	 Gate
	 Buffers
	 ReadWrite
	 Ref
      attr
	 Peers
	 MainBuffer
      meth init(I Role EventProc)
	 self.Evt=EventProc
	 self.Id=I
	 self.Acks={Dictionary.new}
	 self.LockAck={NewLock}
	 self.Buffers={Dictionary.new}
	 case Role
	 of readOnly(master) then
	    self.ReadWrite=false
	    self.Master=true
	 [] readOnly(slave) then
	    self.ReadWrite=false
	    self.Master=false
	 [] master then
	    self.ReadWrite=true
	    self.Master=true
	 [] slave then
	    self.ReadWrite=true
	    self.Master=false
	 [] readWrite(master) then
	    self.ReadWrite=true
	    self.Master=true
	 [] readWrite(slave) then
	    self.ReadWrite=true
	    self.Master=false
	 end
	 if self.Master then self.Opened=unit self.Main=self.Pt self.MainId=self.Id end
	 Peers<-r
	 thread
	    {ForAll {NewPort $ self.Pt}
	     proc{$ M}
		fun{Known I}
		   I==self.Id orelse {HasFeature @Peers I}
		end
		proc{SendTo I M}
		   if I==self.Id then
		      {Port.send self.Pt M}
		   else
		      {self Send(I M)}
		   end
		end
	     in
		case M
		of o(I P) then %% client trying to open with myself
		   lock
		      if {HasFeature @Peers I} then
			 thread
			    try 
			       {Port.send P d}
			    catch _ then skip end
			 end
		      else
			 L={Arity @Peers}
		      in
			 Peers<-{Record.adjoinAt @Peers I P#_}
			 {self Send(I c(self.Id|L))}
			 {Record.forAllInd @Peers
			  proc{$ J _}
			     if I\=J then
				{self Send(J a(I))}
			     end
			  end}
			 {self.Evt add(I)}
		      end
		   end
		[] d then %% disconnected
		   lock
		      proc{Loop L}
			 case L of J#(_#S)|Ls then
			    S=unit
			    Peers<-{Record.subtract @Peers J}
			    {self.Evt remove(J)}
			    {Dictionary.condGet self.Buffers J _}=nil
			    {Dictionary.remove self.Buffers J}
			    {Loop Ls}
			 else Peers<-nil end
		      end
		   in
		      if self.Master then
			 {Record.forAllInd @Peers
			  proc{$ I _}
			     {self Send(I d)}
			  end}
		      end
		      if self.Gate\=unit then
			 {self.Gate close}
		      end
		      {Loop {Record.toListInd @Peers}}
		      self.Closed=unit
		      {self.Evt disconnected}
		      lock self.LockAck then
			 {ForAll {Dictionary.items self.Acks}
			  proc{$ V}
			     {ForAll V proc{$ I} I=false end}
			  end}
			 {Dictionary.removeAll self.Acks}
		      end
		      @MainBuffer=nil
		      {Dictionary.removeAll self.Buffers}
		      {Thread.terminate {Thread.this}}
		   end
		[] c(LI) then % connected
		   lock
		      {self.Evt connected}
		      {ForAll LI proc{$ I}
				    Peers<-{Record.adjoinAt @Peers I unit#_}
				    {self.Evt add(I)}
				 end}
		   end
		[] a(I) then % add peer
		   lock
		      Peers<-{Record.adjoinAt @Peers I unit#_}
		      {self.Evt add(I)}
		   end
		[] d(I) then % remove peer
		   lock
		      if {HasFeature @Peers I} then
			 @Peers.I.2=unit
			 Peers<-{Record.subtract @Peers I}
			 {self.Evt remove(I)}
			 {Dictionary.condGet self.Buffers I _}=nil
			 {Dictionary.remove self.Buffers I}
			 if self.Master then
			    {Record.forAllInd @Peers
			     proc{$ J _}
				{self Send(J d(I))}
			     end}
			 end
		      end
		   end
		[] e(I) then % error while talking to I
		   if {HasFeature @Peers I} then
		      {self.Evt error(I)}
		      if self.Master then
			 {Port.send self.Pt d(I)}
		      else
			 {Port.send self.Pt d}
		      end
		   end
		[] m(I T M) then % message M from I to T
		   if {Known I} andthen {Known T} then
		      {SendTo T m(I M)}
%		      {Port.send {GetPort T} m(I M)}
		   else
		      skip % {Show ignored#I#T#M}
		   end
		[] m(I M) then % message M from I
		   {self.Evt message(I M)}
		[] r(I T M) then % message M from I to T with ack request
		   if {Known I} andthen {Known T} then
		      {SendTo T r(I M)}
%		      {Port.send {GetPort T} r(I M)}
		   else
		      {Port.send self.Pt nk(T)}
		   end
		[] r(I M) then % message M from I with ack request
		   {self.Evt message(I M)}
		   {self SendMain(k(self.Id I))}
%		   {Port.send self.Main k(self.Id I)}
		[] k(I T) then % ack for a message sent by Tgt to I
		   if {Known T} then
		      {SendTo T k(I)}
%		      {Port.send {GetPort T} k(I)}
		   end
		[] k(I) then % ack for a message sent to I
		   lock self.LockAck then
		      TO={Reverse {Dictionary.condGet self.Acks I _|nil}}
		   in
		      TO.1=true
		      if TO.2==nil then
			 {Dictionary.remove self.Acks I}
		      else
			 {Dictionary.put self.Acks I {Reverse TO.2}}
		      end
		   end		
		[] nk(I) then % negative ack for a message sent to I
		   lock self.LockAck then
		      TO={Reverse {Dictionary.condGet self.Acks I _|nil}}
		   in
		      TO.1=false
		      if TO.2==nil then
			 {Dictionary.remove self.Acks I}
		      else
			 {Dictionary.put self.Acks I {Reverse TO.2}}
		      end
		   end
		[] b(I M) then % broadcast from peer I
		   if {Known I} then
		      {self.Evt broadcast(I M)}
		      if self.Master then
			 {Record.forAllInd @Peers
			  proc{$ J _}
			     {self Send(J b(I M))}
%			     {Port.send P b(I M)}
			  end}
		      end
		   end
		[] bs(I M) then % broadcast from peer I, with ack
		   lock self.LockAck then
		      if {Known I} then
			 {self.Evt broadcast(I M)}
			 if I==self.Id then
			    {Port.send self.Pt k(I)}
			 end
			 if self.Master then
			    {Record.forAllInd @Peers
			     proc{$ J _}
				{self Send(J bs(I M))}
%				{Port.send P bs(I M)}
			     end}
			 end
		      end
		   end
		end
	     end}
	 end
	 if self.Master then
	    self.Gate={New Connection.gate init(self.Pt)}
	    self.Ref={Pickle.pack self.Id#{self.Gate getTicket($)}}
	 else
	    self.Gate=unit
	    self.Ref=unit
	 end
      end
      meth Send(I M)
	 lock
	    P={CondSelect @Peers I unit#_}.1
	 in
	    if P\=unit then
	       O N
	    in
	       {Dictionary.condExchange self.Buffers I unit O N}
	       if {IsFree O} then
		  %% a listener thread is already there
		  O=M|N
	       else

		  %% create a listener thread
		  thread
		     proc{Loop L}
			Ok
		     in
			{WaitOr L self.Closed}
			if {IsDet L} then
			   if L==nil then Ok=false else
			      try
				 {Port.send P L.1}
				 Ok=true
			      catch _ then
				 {Port.send self.Pt e(i)}
				 Ok=false
			      end
			   end
			else
			   Ok=false
			end
			if Ok then {Loop L.2}  end
		     end
		  in
		     {Fault.enable P 'thread'(this) [tempFail permFail] _}
		     {Loop N}
		     {Fault.disable P 'thread'(this) _}
		  end
		  {self Send(I M)}
	       end
	    end
	 end
      end
      meth SendMain(M)
	 if self.Master then
	    {Port.send self.Main M}
	 else
	    O N
	 in
	    O=MainBuffer<-N
	    O=M|N
	 end
      end
      meth getRef($)
	 if self.Master then
	    self.Ref
	 else
	    {Exception.raiseError comError(notMaster hint:"Cannot getRef on a non master node")}
	    unit
%	    raise error(notMaster) end
	 end
      end
      meth getIdFromRef(Ref $)
	 {Pickle.unpack Ref}.1
      end
      meth getPeers($)
	 {List.map {Record.toListInd @Peers} fun{$ I#_} I end}
      end
      meth bindOnDisconnect(Id $)
	 !!({CondSelect @Peers Id unit#unit}.2)
      end
      meth open(Ref)
	 lock
	    S=@MainBuffer
	 in
	    if {IsDet self.Opened} then raise error(alreadyOpened) end end
	    self.Opened=unit
	    self.Main={Connection.take {Pickle.unpack Ref}.2}
	    self.MainId={Pickle.unpack Ref}.1
	    {self.Evt opening}
	    thread
	       proc{Loop M}
		  {WaitOr self.Closed M}
		  Ok
	       in
		  if {IsDet M} then
		     if M==nil then
			Ok=false
		     else
			try
			   {Port.send self.Main M.1}
			   Ok=true
			catch _ then
			   Ok=false
			   {Port.send self.Pt e(self.MainId)}
			end
		     end
		  else
		     Ok=false
		  end
		  if Ok then {Loop M.2} end
	       end
	    in
	       {Fault.enable self.Main 'thread'(this) [tempFail permFail] _}
	       {Loop S}
	       {Fault.disable self.Main 'thread'(this) _}
	    end
	    {self SendMain(o(self.Id self.Pt))}
	 end
      end
      meth eject(Id)
	 lock
	    if {IsFree self.Opened} then raise error(notYetOpened) end end
	    if {IsFree self.Closed} then
	       if self.Master then
		  if {HasFeature @Peers Id} then
		     {self Send(Id d)}
		     {self SendMain(d(Id))}
		  end
	       else
		  raise error(notMaster) end
	       end
	    end
	 end
      end
      meth close(Sync<=unit)
	 lock
	    if {IsFree self.Opened} then raise error(notYetOpened) end end
	    if {IsFree self.Closed} then
	       {self SendMain(d(self.Id))}
%	       self.Closed=unit
	       {Port.send self.Pt d}
	    end
	 end
	 if {IsFree Sync} then
	    Sync=!!self.Closed
	 else
	    {Wait self.Closed}
	 end
      end
      meth asend(Tgt Msg) % asynchronous send
	 if {IsFree self.Opened} then
	    {Exception.raiseError comError(notConnected
					   hint:"Cannot asend using a not connected node"
					   info:asend(Tgt Msg))}
	 end
	 if {IsDet self.Closed} then
	    {Exception.raiseError comError(notConnected
					   hint:"Cannot asend using an already disconnected node"
					   info:asend(Tgt Msg))}
	 end
	 if self.ReadWrite then
	    {self SendMain(m(self.Id Tgt Msg))}
	 else
	    {Exception.raiseError comError(readOnly
					   hint:"Cannot asend using a read-only  node"
					   info:asend(Tgt Msg))}
	 end
      end
      meth nsend(Tgt Msg R) % notify send, R is bound to true when the message has been processed
	 lock self.LockAck then
	    if {IsFree self.Opened} orelse {IsDet self.Closed} then
	       {Exception.raiseError comError(notConnected
					      hint:"Cannot nsend using a not connected node"
					      info:nsend(Tgt Msg))}
	    end
	    if self.ReadWrite then
	       S
	    in
	       R=!!S
	       {Dictionary.put self.Acks Tgt S|{Dictionary.condGet self.Acks Tgt nil}}
%	    {Port.send self.Main r(self.Id Tgt Msg)}
	       {self SendMain(r(self.Id Tgt Msg))}
	    else
	       {Exception.raiseError comError(readOnly
					      hint:"Cannot nsend using a read-only  node"
					      info:nsend(Tgt Msg))}
	    end
	 end
      end
      meth broadcast(Msg) % broadcast
	 if {IsFree self.Opened} orelse {IsDet self.Closed} then
	    {Exception.raiseError comError(notConnected
					   hint:"Cannot broadcast using a not connected node"
					   info:broadcast(Msg))}
	 end
%	 {Port.send self.Main b(self.Id Msg)}
	 if self.ReadWrite then
	    {self SendMain(b(self.Id Msg))}
	 else
	    {Exception.raiseError comError(readOnly
					   hint:"Cannot broadcast using a read-only  node"
					   info:broadcast(Msg))}
	 end
      end
      meth nbroadcast(Msg R) % notify broadcast, R is bound to true when the message has been processed *here*
	 lock self.LockAck then
	    if {IsFree self.Opened} orelse {IsDet self.Closed} then
	       {Exception.raiseError comError(notConnected
					      hint:"Cannot nbroadcast using a not connected node"
					      info:nbroadcast(Msg))}
	    end
	    if self.ReadWrite then
	       S
	    in
	       R=!!S
	       {Dictionary.put self.Acks self.Id S|{Dictionary.condGet self.Acks self.Id nil}}
	       {self SendMain(bs(self.Id Msg))}
%	    {Port.send self.Main bs(self.Id Msg)}
	    else
	       {Exception.raiseError comError(readOnly
					      hint:"Cannot nbroadcast using a read-only  node"
					      info:nbroadcast(Msg))}
	    end
	 end
      end
   end
   
end

% fun{MyShow M}
%    proc{$ S}
%       {Show M#S}
%    end
% end

% proc{WaitShow M}
%    {Wait M} {Show M}
% end

% {Show 1}
% M={New Com init(m0 master {MyShow m0})}
% {Show 2}
% C1={New Com init(s1 slave {MyShow s1})}
% {Show 3}
% C2={New Com init(s2 slave {MyShow s2})}
% {Show 4}
% Ref={M getRef($)}
% {C1 open(Ref)}
% {C2 open(Ref)}
% {Show {C2 getPeers($)}}
% {M asend(s2 test)}
% {WaitShow {M rsend(s2 test $)}}
% {C1 broadcast(bc)}
% {C1 close}