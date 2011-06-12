class RadiobuttonRender from ButtonRender
   feat
      var
      select
   meth init(M)
      Id={NewName}
      C
   in
      TkRender,init(M)
      self.select={M getStore(sel $)}
      C={self.store createEvent(args:nil
				action:proc{$}
					  N={self.var tkReturn($)}=="1"
				       in
					  {self.select set(selected N)}
					  {self.store triggerVirtualEvent(default a(value:N))}
				       end
				code:$)}
      {self.store registerVirtualEvent(Id C)}
      self.var={New (self.tk).variable tkInit({self.select get(selected $)})}
      self.handle={New (self.tk).radiobutton tkInit(parent:self.parent.handle
						    value:true
						    variable:self.var
						    action:self.eventPort#v(store:self.store
									    obj:self
									    event:Id))}
      {self initState}
   end
   meth set(I K V)=M
      case I#K of sel#selected then
	 {self.var tkSet(V)}
      else
	 ButtonRender,M
      end
   end
   meth send(M)
      case M of flash then {self.handle tk(flash)} end
   end
end

class RadiobuttonProxy from ButtonProxy
   feat widgetName:radiobutton
   attr
      Group
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
      Group<-default
      {RadioListeners.register @Group self
       proc{$} RadiobuttonProxy,set(selected false) end}
      {self bind(event:default
		 args:[value]
		 action:proc{$ V}
			   if V then
			      {RadioListeners.setActive @Group self}
			   end
			end)}
   end
   meth set(K V)
      case K of selected then
	 {self.Manager set(sel K V)}
      [] group then
	 O N
      in
	 O=Group<-N
	 {RadioListeners.unregister O self}
	 {RadioListeners.register V self
	  proc{$} RadiobuttonProxy,set(selected false) end}
	 N=V
      else
	 ButtonProxy,set(K V)
      end
   end
   meth get(K V)=M
      case K of selected then
	 {self.Manager get(sel K V)}
      [] group then V=@Group
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
   meth flash
      {self.Manager send(flash)}
   end
   meth invoke
      {self.Store triggerVirtualEvent(default a)}
   end
   meth destroy
      {RadioListeners.unregister @Group self}
      Group<-unit
      ButtonProxy,destroy
   end
end

RadiobuttonWidget={CreateWidgetClass
		   radiobutton(proxy:RadiobuttonProxy
			       synonyms:Synonyms
			       defaultRenderClass:RadiobuttonRender
			       rendererClass:TCLTK
			      )}

{QTk.register RadiobuttonWidget QTkBuild}

