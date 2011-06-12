class ButtonRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).button tkInit(parent:self.parent.handle
					       action:self.eventPort#v(store:self.store obj:self event:default)
					      )}
      {self initState}
   end
   meth send(M)
      case M of flash then {self.handle tk(flash)}
      end
   end
end

class ButtonProxy from TkProxy
   feat widgetName:button
   meth flash
      {self.Manager send(flash)}
   end
   meth invoke
      {self.Manager triggerVirtualEvent(default a)}
   end
end

ButtonWidget={CreateWidgetClass
	      button(proxy:ButtonProxy
		     synonyms:Synonyms
		     defaultRenderClass:ButtonRender
		     rendererClass:TCLTK
		    )}

{QTk.register ButtonWidget QTkBuild}
