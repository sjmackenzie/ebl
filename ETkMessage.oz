class MessageRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).message tkInit(parent:self.parent.handle)}
      {self initState}
   end
end

class MessageProxy from TkProxy feat widgetName:message end

MessageWidget={CreateWidgetClass
	       message(proxy:MessageProxy
		       synonyms:Synonyms
		       defaultRenderClass:MessageRender
		       rendererClass:TCLTK
		      )}

{QTk.register MessageWidget QTkBuild}
