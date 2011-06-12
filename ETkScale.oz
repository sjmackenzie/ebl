class ScaleRender from TkRender
   feat
      var
   meth init(M)
      Id={NewName}
      C
   in
      TkRender,init(M)
      self.var={New (self.tk).variable tkInit(0.0)}
      C={self.store createEvent(args:nil
				action:proc{$}
					  N={self.var tkReturnFloat($)}
				       in
					  {self.manager set(value value N)}
					  {self.store triggerVirtualEvent(default a(value:N))}
				       end
				code:$)}
      {self.store registerVirtualEvent(Id C)}
      self.handle={New (self.tk).scale tkInit(parent:self.parent.handle
					      variable:self.var
					      'from':0.0
					      to:1.0
					      action:self.eventPort#v(store:self.store
								      obj:self
								      event:Id))}
      {self initState}
   end
   meth set(I K V)
      case I#K of value#value then
	 {self.var tkSet(V)}
      else
	 TkRender,set(I K V)
      end
   end
   meth ask(Q R)
      case Q
      of coords(V) then
	 R={TkStringTo.listInt {TkReturn self.tk [self.handle coords V]}}
      [] get(X Y) then
	 R={TkStringTo.float {TkReturn self.tk [self.handle get X Y]}}
      [] identify(X Y) then
	 R={TkStringTo.atom {TkReturn self.tk [self.handle identify X Y]}}
      end
   end
end

class ScaleProxy from TkProxy
   feat widgetName:scale
   meth init(...)=M
      TkProxy,M
      local
	 Value={self.Manager getStore(value $)}
      in
	 {Value setParametersType(t(value:'From'))}
	 {Value setTypeChecker(t('From':TkTypeChecker.'From'))}
	 {Value setDefaults(t(value:0.0))}
	 {Value set(value 0.0)}
      end
   end
   meth set(K V)
      case K of value then
	 {self.Manager set(value value V)}
      else
	 TkProxy,set(K V)
      end
   end
   meth get(K V)
      case K of value then
	 {self.Manager get(value K V)}
      else
	 TkProxy,get(K V)
      end
   end
   meth coords(V $)
      {self.Manager ask(coords(V) $)}
   end
   meth getScale(X Y $)
      {self.Manager ask(get(X Y) $)}
   end
   meth identify(X Y $)
      {self.Manager ask(identify(X Y) $)}
   end
end

ScaleWidget={CreateWidgetClass
	     scale(proxy:ScaleProxy
		   synonyms:Synonyms
		   defaultRenderClass:ScaleRender
		   rendererClass:TCLTK
		  )}

{QTk.register ScaleWidget QTkBuild}
