class SelectorRender from TkRender
   attr
      items
      current
   meth init(M)
      TkRender,init(M)
      items<-nil
      current<-{self.manager get(main curselection $)}
   end
   meth setItems(_) skip end
   meth set(I K V)=M
      case I#K
      of main#items then
	 {self setItems(V)}
      [] main#text then
	 {self setText(V)}
      [] main#curselection then
	 {self select(V)}
      [] main#background then
	 TkRender,M
	 {self setBackground(V)}
      else
	 TkRender,M
      end
   end
   meth select(V)
      current<-V
   end
   meth setBackground(_) skip end
   meth setText(_) skip end
   meth triggerMainEvent(V)
      {self.manager set(main curselection V)}
      {self.store triggerVirtualEvent(default a(value:V))}
      current<-V
   end
end   


class SelectorDefaultRender
   %% use radiobuttons
   from SelectorRender
   feat var
   meth init(M)
      SelectorRender,init(M)
      self.var={New (self.tk).variable tkInit(0)}
      C={(self.tk).newWidgetClass noCommand labelframe}
   in
      self.handle={New C tkInit(parent:self.parent.handle)}
      {TkExec self.tk [grid(columnconfigure self.handle 0 weight:1)]}
      {self initState}
%      {self setItems({self.manager get(main items $)})}
%      {self setText({self.manager get(main text $)})}
   end
   meth setItems(V)
      Background=try {self.store get(background $)} catch _ then unit end
   in
      {ForAll @items
       proc{$ I}
	  {TkExec self.tk [grid(forget I)]}
	  {TkExec self.tk [destroy I]}
       end}
      items<-{List.mapInd V
	      fun{$ I E}
		 O={New (self.tk).radiobutton tkInit(parent:self.handle
						     text:E
						     value:I
						     variable:self.var
						     action:proc{$}
							       {self triggerMainEvent(I)}
							    end)}
		 if Background\=unit then {O tk(configure background:Background)} end
	      in
		 {TkExec self.tk [grid(configure O row:(I-1) column:0 sticky:w)]}
		 O
	      end}
   end
   meth select(V)
      {self.var tkSet(V)}
   end
   meth setText(V)
      {self.handle tk(configure text:V)}
   end
   meth setBackground(V)
      {ForAll @items proc{$ I} {TkExec self.tk [I configure(background:V)]} end}
   end
			       
end

class SelectorListboxRender
   %% use a listbox
   from SelectorRender
   feat listbox hscroll vscroll label
   meth init(M)
      SelectorRender,init(M)
      self.handle={New (self.tk).frame tkInit(parent:self.parent.handle)}
      self.listbox={New (self.tk).listbox tkInit(parent:self.handle selectmode:browse exportselection:false)}
      self.hscroll={New (self.tk).scrollbar tkInit(parent:self.handle orient:horizontal)}
      self.vscroll={New (self.tk).scrollbar tkInit(parent:self.handle orient:vertical)}
      self.label={New (self.tk).label tkInit(parent:self.handle)}
      {TkExec self.tk [grid(rowconfigure self.handle 1 weight:1)]}
      {TkExec self.tk [grid(columnconfigure self.handle 0 weight:1)]}
      {TkExec self.tk [grid(configure self.label column:0 row:0 sticky:w padx:0 pady:0)]}
      {TkExec self.tk [grid(configure self.listbox column:0 row:1 sticky:nswe padx:0 pady:0)]}
      {TkExec self.tk [grid(configure self.vscroll column:1 row:1 sticky:ns padx:0 pady:0)]}
      {TkExec self.tk [grid(configure self.hscroll column:0 row:2 sticky:we padx:0 pady:0)]}
      {(self.tk).addXScrollbar self.listbox self.hscroll}
      {(self.tk).addYScrollbar self.listbox self.vscroll}
      {self.listbox tkBind(event:'<<ListboxSelect>>'
			   action:proc{$}
				     R={TkStringTo.listInt {TkReturn self.tk [self.listbox curselection]}}
				  in
				     if R==nil then
					{self triggerMainEvent(0)}
				     else
					{self triggerMainEvent(R.1+1)}
				     end
				  end)}
      {self initState}
   end
   meth setItems(V)
      {TkExec self.tk [self.listbox delete 0 'end']}
      {ForAll V
       proc{$ E}
	  {TkExec self.tk [self.listbox insert 'end' E]}
       end}
   end
   meth select(V)
      {TkExec self.tk [self.listbox selection clear 0 'end']}
      {TkExec self.tk [self.listbox selection set V-1]}
   end
   meth setText(V)
      {TkExec self.tk [self.label configure(text:V)]}
   end
   meth setBackground(V)
      {TkExec self.tk [self.label configure(background:V)]}
   end

end

class SelectorMenubuttonRender
   from SelectorDefaultRender
   feat
      menu var
   meth init(M)
      SelectorRender,init(M)
      self.var={New (self.tk).variable tkInit(0)}
      self.handle={New (self.tk).menubutton tkInit(parent:self.parent.handle)}
      self.menu={New (self.tk).menu tkInit(parent:self.handle)}
      {self.handle tk(configure menu:self.menu)}
      {self initState}
   end
   meth setItems(V)
      {TkExec self.tk [self.menu delete 0 'end']}
      {List.forAllInd V
       proc{$ I E}
	  _={New (self.tk).menuentry.radiobutton tkInit(parent:self.menu
							label:E
							value:I
							variable:self.var
							action:proc{$}
								  {self triggerMainEvent(I)}
							       end)}
       end}
   end
   meth select(V)
      {self.var tkSet(V)}
   end
   meth setText(V)
      {TkExec self.tk [self.handle configure(text:V)]}
   end
   meth setBackground(V)
      {TkExec self.tk [self.menu configure(background:V)]}
   end
   
end

class SelectorProxy from TkProxy
   feat widgetName:selector
   meth init(...)=M
      TkProxy,M
      {{self.Manager getStore(main $)} setTypeChecker(t('...':TkTypeChecker.'Any'))}
      {self.Store setProxyMarshaller(TkProxyMarshaller)}
      {self.Store setRenderMarshaller(TkRenderMarshaller)}
      {self.Store setTypeChecker(TkTypeChecker)}
      {self.Store setParametersType(o(items:'ListString'
				      text:'Text'
				      curselection:'Int'
				      background:'Background'))}
      {self.Store setDefaults(o(items:nil
				text:nil
				curselection:0
				background:TkDefaults.frame.background))}
      {self.Store set(items nil)}
      {self.Store set(text nil)}
      {self.Store set(curselection 0)}
   end
end

SelectorWidget={CreateWidgetClass
	       listbox(proxy:SelectorProxy
		       synonyms:Synonyms
		       defaultRenderClass:SelectorDefaultRender
		       renderers:r(listbox:SelectorListboxRender menu:SelectorMenubuttonRender)
		       rendererClass:TCLTK
		      )}

{QTk.register SelectorWidget QTkBuild}
