%% The SocketConnection functor provides functionality equivalent to the Connection functor
%%   but it uses a pair ip/socket instead of a regular ticket.
%% It can be configured to use non-blocking connections, or blocking ones, or a mix of both :
%%   {Property.put 'socketConnection.takeMechanism' V} with V one of blocking (default), nonBlocking, mixed.
%%   in case of nonBlocking or mixed, the following properties can also be set :
%%   {Property.put 'socketConnection.retryTimes' V} default V=15
%%   {Property.put 'socketConnection.waitTime' V} default V=200
%%   {Property.put 'socketConnection.openConTimeOut' V} default V=10000
%% As the Connection module sometimes has a hard time opening a connection,
%%   this module can try to open the connection in a certain direction or both directions simultaneously
%%   {Property.put 'socketConnection.takeDirection' V} with V one of taker, offerer, both (default).
%% Original author : Donatien Grolaux, Contributor : Valentin Mesaros

functor
   
import
   Connection
   Error
   OS   % for the use of OS sockets % added by V
   System
   Property
   DPInit

export
   Offer
   OfferOn
   OfferUnlimited
   OfferUnlimitedOn
   Take
   Gate
   ThisIP % added by V
   
define
   {Property.put 'dp.openTimeout' 32000}
   {Property.put 'socketConnection.takeDirection' bidi}
   
   %{Property.put 'print.width' 100}
   %{Property.put 'print.depth' 100}
   
   % variables used in the new procedure Take % added by V, modded by D
   RetryCount     = {Property.condGet 'socketConnection.retryTimes' 15}       % retry times for connection open, if the case
   RetryDelay     = {Property.condGet 'socketConnection.waitTime' 200}         % time to wait between two retries for conn open (ms)
   OpenConTimeOut = {Property.condGet 'socketConnection.openConTimeOut' 10000} % open connection time out (ms)

   Show=if {Property.condGet 'socketConnection.debug' false}==true then
	   System.show else proc{$ _} skip end end
	   
   {Show socketConnectionStart}

   {Error.registerFormatter socketConnection
    fun{$ E}
       T='Error: SocketConnection module'
    in
       case E
       of socketConnection(unableToBindSocket Pt PN) then
	  error(kind:T
		msg:"Unable to bind the socket to a port"
		items:[hint(l:'Entity'
			    m:oz(Pt))
		       hint(l:'Socket'
			    m:oz(PN))])
       [] socketConnection(unableToGetPort IP PN) then
	  error(kind:T
		msg:"Unable to get an Oz connection (site dead ?)"
		items:[hint(l:'IP'
			    m:IP)
		       hint(l:'Socket'
			    m:oz(PN))])	  
       [] socketConnection(invalidPortNumber PN) then
	  error(kind:T
		msg:"Invalid socket number (must be an integer)"
		items:[hint(l:'Socket'
			    m:oz(PN))])	  
       end
    end}

   Lock={NewLock}
   Count={NewCell 0}

   fun{GetN}
      lock Lock then
	 V={Access Count}
      in
	 {Assign Count V+1}
	 V
      end
   end

   AckD={NewDictionary}

   proc{SendBuffer S H P M}
      {Show sending#S#H#P#M}
      try
	 {OS.sendTo S M nil H P _}
      catch _ then skip end
   end
   
   fun{GetS S}
      H P Buf
   in
      {OS.readSelect S}
      try
	 Buf={OS.receiveFrom S 1000 nil $ nil H P _}
      catch _ then Buf=nil end
      {Show got#{VirtualString.toAtom Buf}}
      if {Length Buf}>2 andthen
	 {List.take Buf 1}=="#" andthen
	 {List.last Buf}==&& then
	 %% what is between # and & is being acked
	 try
	    {Dictionary.condGet AckD
	     {String.toInt {List.drop {List.take Buf {Length Buf}-1} 1}} _}=unit
	 catch _ then skip end
	 {GetS S}
      elseif {Length Buf}>2 andthen
	 {List.take Buf 1}=="!" andthen
	 {List.last Buf}==&& then
	 %% what is between ! and \& is a connection attempt from H P
	 AckNu={List.takeWhile {List.drop Buf 1}
		fun{$ C} C\=&z andthen C\=&& end}
	 {SendBuffer S H P {VirtualString.toString "#"#AckNu#"\&"}}
      in
	 if {List.member &z Buf} then
	    %% there is a ticket also
	    Tkt={List.takeWhile {List.drop {List.dropWhile Buf fun{$ C} C\=&z end} 1}
		 fun{$ C} C\=&& end}
	 in
	    {Show gets#Tkt#H#P}
	    Tkt#H#P
	 else
	    {Show gets#nil#H#P}
	    nil#H#P
	 end
      else
	 {GetS S} %% ignore garbage
      end
   end

   proc{SendS S H P M}
      A={GetN} Stop
      Buffer={VirtualString.toString "!"#{Int.toString A}#"z"#M#"\&"}
      {Show sends#S#H#P#M#{VirtualString.toAtom Buffer}}
      proc{Loop N}
	 {SendBuffer S H P Buffer}
	 {Delay RetryDelay}
	 if {IsFree Stop} andthen (N>0) then {Loop N-1}
	 else
	    %% not acked
	    {Show H#P#didNotAcked}
	    {Dictionary.remove AckD A}
	 end
      end
   in
      {Dictionary.put AckD A Stop}
      {Loop RetryCount}
   end
   
   fun{OfferGU Time Pt What}
      S={OS.socket 'PF_INET' 'SOCK_DGRAM' "udp"}
      try
	 {OS.bind S Pt}
      catch system(os(...) ...) then
	 raise socketConnection(unableToBindSocket What Pt) end
      end
      Tkt=case Time
	  of once then {Connection.offer What}
	  [] inf then {Connection.offerUnlimited What}
	  end
      ThId
   in
      thread
	 proc{Loop}
	    M#H#P={GetS S}
	 in
	    %% port P of host H sent me the message M
	    thread
	       %% maybe M is a ticket we can take ?
	       if M\=nil then
		  X
	       in
		  try
		     X={Connection.take M}
		     X=o(What)
		  catch _ then skip end
	       end
	    end
	    thread
	       %% send this guy the ticket for the entity here
	       {SendS S H P Tkt}
	    end
	    case Time
	    of inf then {Loop} else
	       try
		  {OS.shutDown S 2}
		  {OS.deSelect S}
		  {OS.close S}
	       catch _ then skip end
	    end
	 end
      in
	 ThId={Thread.this}
	 {Loop}
      end
      {Wait ThId}
      (ThId#S)#{OS.getSockName S}
   end

   fun{OfferG Time Pt What}
      {OfferGU Time Pt What}.2
   end
   
   fun{Offer X}
      R={OfferG once 0 X}
   in
      !!R
   end

   proc{OfferOn PN X}
      if {Not {Int.is PN}} then
	 raise socketConnection(invalidPortNumber PN) end
      end
      {OfferG once PN X _}
   end

   fun{OfferUnlimited X}
      R={OfferG inf 0 X}
   in
      !!R
   end

   proc{OfferUnlimitedOn PN X}
      if {Not {Int.is PN}} then
	 raise socketConnection(invalidPortNumber PN) end
      end
      {OfferG inf PN X _}
   end 

   fun{Take IP PN}
      if {IsFree PN} orelse {Not {Int.is PN}} then
	 raise socketConnection(invalidPortNumber PN) end
      end      
      {Show taking#IP#PN}
      S={OS.socket 'PF_INET' 'SOCK_DGRAM' "udp"}
      {OS.bind S 0} % pick a random free port
      What
      Tkt={Connection.offer What}
      Success
      ThId
   in
      thread
	 {Delay OpenConTimeOut}
	 try Success=f catch _ then skip end
      end
      thread
	 {Thread.this}=ThId
	 M#_#_={GetS S}
      in
	 %% port P of host H sent me the message M
	 thread
	    %% maybe M is a ticket we can take ?
	    if M\=nil then
	       X
	    in
	       try
		  X={Connection.take M}
		  {Show couldTakeFromOther}
		  Success=i(X)
	       catch _ then skip end
	    end
	 end
      end
      {Wait ThId}
      thread
	 try
	    {Wait What}
	    {Show otherTookFromMe}
	    Success=What
	 catch _ then skip end
      end
      {Show tk#S#IP#PN#Tkt}
      {SendS S IP PN Tkt}
      {Wait Success}
      try
	 {Thread.terminate ThId}
      catch _ then skip end
      try
	 {OS.shutDown S 2}
	 {OS.deSelect S}
	 {OS.close S}
      catch _ then skip end
      {Show Success}
      if {HasFeature Success 1} then
	 Success.1
      else
	 %% timeout
	 raise socketConnection(unableToGetPort IP PN) end
      end
   end

   ThisIP={ByNeed
	   fun{$}
	      {Wait Connection} % force the init of DP if not already done
	      {VirtualString.toString {DPInit.getSettings}.ip}
	   end}
		      
   
   class Gate

      feat
	 ThId
	 CPN
	 Socket

      meth initOn(X PN)
	 {Wait PN}
	 {self Init(X PN)}
      end

      meth init(X)
	 {self Init(X 0)}
      end
	 
      meth Init(X PN)
	 (self.ThId#self.Socket)#self.CPN={OfferGU inf PN X}
      end
      
      meth getIP($)
	 ThisIP
      end

      meth getPN($)
	 self.CPN
      end

      meth close()
	 try
	    {Thread.terminate self.ThId}
	 catch _ then skip end
	 try
	    {OS.shutDown self.Socket 2}
	    {OS.deSelect self.Socket}
	    {OS.close self.Socket}
	 catch _ then skip end	 
      end
      
   end
   
end
