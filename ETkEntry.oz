class EntryRender from TkRender
   feat entry
   attr t
   meth createEntry(Parent Entry)
      C T
      T={self.manager getStore(text $)}
   in
      Entry={New (self.tk).entry tkInit(parent:Parent)}

      C={self.store createEvent(event:'<KeyPress>'
				args:nil
				action:proc{$}
					  N={Entry tkReturn(get $)}
				       in
					  if N\=@t then
					     t<-N
					     {T set(text N)}
					  end
				       end
				code:$)}
      
      {self bind(main C '<KeyPress>'#nil)}
   end
   meth createHandle
      {self createEntry(self.parent.handle self.handle)}
      self.entry=self.handle
   end
   meth init(M)
      TkRender,init(M)
   in
      t<-""
      {self createHandle}
      {self initState}
      {self set(text text {M get(text text $)})}
   end
   meth set(I K V)=M
      case I#K of text#text then
	 {self.entry tk(delete 0 'end' v(";") self.entry insert 0 V)}
      else
	 TkRender,M
      end
   end
   meth ask(Q R)=M
      case Q
      of bbox(Id) then
	 R={TkStringTo.listFloat {TkReturn self.tk [self.entry bbox Id]}}
      [] index(Id) then
	 R={TkStringTo.int {TkReturn self.tk [self.entry index Id]}}
      [] delete(...) then
	 {TkExec self.tk [self.entry Q]}
	 R={TkReturn self.tk [self.entry get]}
      [] insert(...) then
	 {TkExec self.tk [self.entry Q]}
	 R={TkReturn self.tk [self.entry get]}
      else
	 TkRender,M
      end
   end
   meth send(M)
      case M
      of icursor(_) then
	 {TkExec self.tk [self.entry M]}
      else
	 TkRender,send(M)
      end
   end
end

class EntryVirtualKBRender from EntryRender
   feat
      entry
      buttons
      vkframe del toggle bottom shift space
   attr shown
   meth createHandle
      Tk=self.tk
      Class={(self.tk).newWidgetClass command entry}
   in
      self.handle={New Tk.frame tkInit(parent:self.parent.handle)}
      {self createEntry(self.handle self.entry)}
      {TkExec self.tk [grid(columnconfigure self.handle 0 weight:1)]}
      {TkExec self.tk [grid(configure self.entry row:0 column:0 sticky:we)]}
      self.vkframe={New Tk.frame tkInit(parent:self.handle)}
      self.toggle={New Tk.button tkInit(parent:self.handle text:"v" action:self#toggle)}
      shown<-false
      {TkExec self.tk [grid(configure self.toggle row:0 column:1)]}
      local
	 ItemsLow=["1234567890-+"
		   "abcdefghijkl"
		   "mnopqrstuvwx"
		   "yz`#;'[],./|"]
	 ItemsHigh=["!\" $%^&*()_="
		    "ABCDEFGHIJKL"
		    "MNOPQRSTUVWX"
		    "YZ\\~:@{}<>? "]
	 fun{Char Lo Hi}
	    case Lo of Lx|Ls then
	       B=Lx#Hi.1#{New Tk.button tkInit(parent:self.vkframe
					       text:[Lx]
					       action:proc{$}
							 {self click({B.3 tkReturn(cget("-text") $)})}
						      end)}
	    in
	       B|{Char Ls Hi.2}
	    else nil end
	 end
	 fun{Line Lo Hi}
	    case Lo of Lx|Ls then
	       {Char Lx Hi.1}|{Line Ls Hi.2}
	    else nil end
	 end
	 Buttons={Line ItemsLow ItemsHigh}
	 Shift={NewCell false}
      in
	 {List.forAllInd Buttons
	  proc{$ X L}
	     {List.forAllInd L
	      proc{$ Y B}
		 {TkExec self.tk [grid(configure B.3 row:X-1 column:Y-1 sticky:nswe)]}
	      end}
	  end}
	 self.buttons={List.flatten Buttons}
	 self.bottom={New Tk.button tkInit(parent:self.vkframe)}
	 {TkExec self.tk [grid(configure self.bottom row:4 column:0 columnspan:12 sticky:nswe)]}
	 self.shift={New Tk.button tkInit(parent:self.bottom
					  text:"Shift"
					  action:proc{$}
						    if {Access Shift} then
						       {ForAll self.buttons proc{$ B}
									       {B.3 tk(configure text:[B.1])}
									    end}
						    else
						       {ForAll self.buttons proc{$ B}
									       {B.3 tk(configure text:[B.2])}
									    end}						       
						    end
						    {Assign Shift {Not {Access Shift}}}
						 end)}
	 self.space={New Tk.button tkInit(parent:self.bottom
					  text:" "
					  action:proc{$} {self click(" ")} end)}
	 self.del={New Tk.button tkInit(parent:self.bottom
					text:"<-"
					action:proc{$}
						  {self remove}
					       end)}
	 {TkExec self.tk [grid(columnconfigure self.bottom 1 weight:1)]}
	 {TkExec self.tk [grid(configure self.shift row:0 column:0 sticky:nswe)]}
	 {TkExec self.tk [grid(configure self.space row:0 column:1 sticky:nswe)]}
	 {TkExec self.tk [grid(configure self.del row:0 column:2 sticky:nswe)]}
      end
      
	     



	 
%       self.buttons={List.toTuple o {List.mapInd {List.make 10} fun{$ I _}
% 								  {New Tk.button tkInit(parent:self.vkframe
% 											text:I-1
% 											action:proc{$}
% 												  {self click(I-1)}
% 											       end)}
% 							       end}}
%       self.del={New Tk.button tkInit(parent:self.vkframe
% 				     text:"<"
% 				     action:proc{$}
% 					       {self remove}
% 					    end)}
%       {TkExec self.tk [pack(self.buttons self.del side:left)]}
   end
   meth toggle
      if @shown then
	 {TkExec self.tk [grid forget self.vkframe]}
      else
	 {TkExec self.tk [grid(configure self.vkframe row:1 column:0 columnspan:2)]}
      end
      shown<-{Not @shown}
   end
   meth click(I)
      {TkExec self.tk [self.entry insert 'end' I]}
   end
   meth remove
      Z={String.toInt {TkReturn self.tk [self.entry index 'end']}}
   in
      if Z>0 then
	 {TkExec self.tk [self.entry delete Z-1]}
      end
   end
   meth set(I K V)=M
      case I
      of main then
	 if {Atom.is K} then
	    {TkExec self.tk [self.entry configure "-"#K V]}
	 end
      [] text then
	 case K of text then
	    {self.entry tk(delete 0 'end' v(";") self.entry insert 0 V)}
	 else
	    EntryRender,M
	 end
      else
	 EntryRender,M
      end
   end
   meth remoteGet(_ K R)
      if {Atom.is K} then
	 R={TkReturn self.tk [self.entry cget "-"#K]}
      end
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
      if {CheckBind self.entry E} then R=true
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
	 Unbind={Bind self.tk self.entry unit E Args Proc}
      in
	 {Dictionary.put self.iEventDict E Unbind#ON}
      end
   end
end


class EntryProxy from XTkProxy feat widgetName:entry
   meth init(...)=M
      XTkProxy,M
      T={self.Manager getStore(text $)}
      {T setParametersType(t(text:'Text'))}
      {T setTypeChecker(t('Text':TkTypeChecker.'Text'))}
      {T setDefaults(t(text:""))}
      {T setRenderMarshaller(t('Text':TkRenderMarshaller.'Text'))}
      {T set(text "")}
      C={T createEvent(args:nil
		       action:proc{$}
				 {self.Store triggerVirtualEvent(default a(value:{T get(text $)}))}
			      end
		       code:$)}
   in
      {T registerVirtualEvent(text C)}
   end
   meth bind(...)=M
      if {CondSelect M event unit}==default then
	 Event={self.Store createEvent(args:nil action:M.action unbind:{CondSelect M unbind _} code:$)}
      in
	 {self.Store registerVirtualEvent(default Event)}
      elseif {CondSelect M 'attr' unit}==text then
	 T={self.Manager getStore(text $)}
	 Event={T createEvent(args:{CondSelect M args nil}
			      action:M.action
			      unbind:{CondSelect M unbind _}
			      code:$)}
      in
	 {T registerVirtualEvent(text Event)}
      else
	 TkProxy,M
      end
   end
   meth set(K V)=M
      case K of text then
	 {self.Manager set(text text V)}
      else
	 TkProxy,M
      end
   end
   meth get(K V)=M
      case K of text then
	 {self.Manager get(text text V)}
      else
	 TkProxy,M
      end
   end
   meth bbox(Index $)
      {self.Manager ask(bbox(Index) $)}
   end
   meth delete(First Last)
      {self.Manager set(text text {self.Manager ask(delete(First Last) $)})}
   end
   meth icursor(Index)
      {self.Manager send(icursor(Index))}
   end
   meth index(Index $)
      {self.Manager ask(index(Index) $)}
   end
   meth insert(Index String)
      {self.Manager set(text text {self.Manager ask(insert(Index String) $)})}
   end
%    meth scan(...)=M
%    end
%    meth selection(...)=M
%    end

end

EntryWidget={CreateWidgetClass
	     entry(proxy:EntryProxy
		   synonyms:Synonyms
		   defaultRenderClass:EntryRender
		   rendererClass:TCLTK
		   renderers:r(virtualkb:EntryVirtualKBRender)
		  )}

{QTk.register EntryWidget QTkBuild}
