class SpinboxRender from EntryRender
   meth createEntry(Parent Spinbox)
      C T
      Class={(self.tk).newWidgetClass command spinbox}
      T={self.manager getStore(text $)}
      Id={NewName}
   in
      Spinbox={New Class tkInit(parent:Parent
				action:self.eventPort#v(store:self.store
							obj:self
							event:Id)
			       )}
      C={self.store createEvent(event:'<KeyPress>'
				args:nil
				action:proc{$}
					  N={Spinbox tkReturn(get $)}
				       in
					  if N\=@t then
					     t<-N
					     {T set(text N)}
					  end
				       end
				code:$)}
      {self bind(main C '<KeyPress>'#nil)}
      {self.store registerVirtualEvent(Id C)}
   end
%   meth createHandle
%      {self createSpinbox(self.parent.handle self.handle)}
%   end
%    meth init(M)
%       TkRender,init(M)
%    in
%       t<-""
%       {self createE}
%       {self initState}
%       {self set(text text {M get(text text $)})}
%    end
end

class SpinboxVirtualKBRender from EntryVirtualKBRender
   feat
      buttons
      vkframe del toggle
   attr shown
   meth createEntry(Parent Spinbox)
      C T
      Class={(self.tk).newWidgetClass command spinbox}
      T={self.manager getStore(text $)}
      Id={NewName}
   in
      Spinbox={New Class tkInit(parent:Parent
				action:self.eventPort#v(store:self.store
							obj:self
							event:Id)
			       )}
      C={self.store createEvent(event:'<KeyPress>'
				args:nil
				action:proc{$}
					  N={Spinbox tkReturn(get $)}
				       in
					  if N\=@t then
					     t<-N
					     {T set(text N)}
					  end
				       end
				code:$)}
      {self bind(main C '<KeyPress>'#nil)}
      {self.store registerVirtualEvent(Id C)}
   end
   meth createHandle
      Tk=self.tk
      Class={(self.tk).newWidgetClass command spinbox}
   in
      self.handle={New Tk.frame tkInit(parent:self.parent.handle)}
      {self createEntry(self.handle self.entry)}
      {TkExec self.tk [grid(columnconfigure self.handle 0 weight:1)]}
      {TkExec self.tk [grid(configure self.entry row:0 column:0 sticky:we)]}
      self.vkframe={New Tk.frame tkInit(parent:self.handle)}
      self.toggle={New Tk.button tkInit(parent:self.handle text:"v" action:self#toggle)}
      shown<-false
      {TkExec self.tk [grid(configure self.toggle row:0 column:1)]}      
      self.buttons={List.toTuple o {List.mapInd {List.make 10} fun{$ I _}
								  {New Tk.button tkInit(parent:self.vkframe
											text:I-1
											action:proc{$}
												  {self click(I-1)}
											       end)}
							       end}}
      self.del={New Tk.button tkInit(parent:self.vkframe
				     text:"<"
				     action:proc{$}
					       {self remove}
					    end)}
      {TkExec self.tk [pack(self.buttons self.del side:left)]}
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
end

class SpinboxProxy from EntryProxy
   feat widgetName:spinbox
end

SpinboxWidget={CreateWidgetClass
	       spinbox(proxy:SpinboxProxy
		       synonyms:Synonyms
		       defaultRenderClass:SpinboxRender
		       rendererClass:TCLTK
		       renderers:r(virtualkb:SpinboxVirtualKBRender)
		      )}

{QTk.register SpinboxWidget QTkBuild}
