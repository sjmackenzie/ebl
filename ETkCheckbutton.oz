class CheckbuttonRender from ButtonRender
   feat select
   meth init(M)
      Id={NewName}
      C
   in
      TkRender,init(M)
      self.select={M getStore(sel $)}
      C={self.store createEvent(args:nil
				action:proc{$}
					  N={Not {self.select get(selected $)}}
				       in
					  {self.select set(selected N)}
					  {self.store triggerVirtualEvent(default a(value:N))}
				       end
				code:$)}
      {self.store registerVirtualEvent(Id C)}
      self.handle={New (self.tk).checkbutton tkInit(parent:self.parent.handle
						    action:self.eventPort#v(store:self.store
									    obj:self
									    event:Id))}
      {self initState}
      {self set(sel selected {self.select get(selected $)})}
   end
   meth set(I K V)=M
      case I#K of sel#selected then
	 if V then
	    {self.handle tk(select)}
	 else
	    {self.handle tk(deselect)}
	 end
      else
	 ButtonRender,M
      end
   end
end

class CheckbuttonProxy from ButtonProxy feat widgetName:checkbutton
   meth init(...)=M
      ButtonProxy,M
      local
	 Sel={self.Manager getStore(sel $)}
      in
	 {Sel setParametersType(t(selected:'Boolean'))}
	 {Sel setTypeChecker(t('Boolean':TkTypeChecker.'Boolean'))}
	 {Sel setDefaults(t(selected:false))}
	 {Sel set(selected false)}
      end
   end
   meth set(K V)
      case K of selected then
	 {self.Manager set(sel K V)}
      else
	 ButtonProxy,set(K V)
      end
   end
   meth get(K V)=M
      case K of selected then
	 {self.Manager get(sel K V)}
      else
	 ButtonProxy,get(K V)
      end
   end
   meth select
      {self.Manager set(sel selected true)}
   end
   meth deselect
      {self.Manager set(sel selected false)}
   end
   meth toggle
      {self.Manager set(sel selected {Not {self.Manager get(sel $)}})}
   end
end

CheckbuttonWidget={CreateWidgetClass
		   checkbutton(proxy:CheckbuttonProxy
			       synonyms:Synonyms
			       defaultRenderClass:CheckbuttonRender
			       rendererClass:TCLTK
			      )}

{QTk.register CheckbuttonWidget QTkBuild}
