class LabelRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).label tkInit(parent:self.parent.handle)}
      {self initState}
   end
end

class InverseLabelRender from LabelRender
   meth init(M)
      LabelRender,init(M)
      F B
   in
      F=LabelRender,remoteGet(main foreground $)
      B=LabelRender,remoteGet(main background $)
      LabelRender,set(main foreground B)
      LabelRender,set(main background F) 
   end
   meth set(I K V)
      case I#K
      of main#background then LabelRender,set(main foreground V)
      [] main#foreground then LabelRender,set(main background V)
      else LabelRender,set(I K V) end
   end
end

class LabelProxy from TkProxy feat widgetName:label end


LabelWidget={CreateWidgetClass
	     label(proxy:LabelProxy
		   synonyms:Synonyms
		   defaultRenderClass:LabelRender
		   renderers:r(inverse:InverseLabelRender)
		   rendererClass:TCLTK
		  )}

{QTk.register LabelWidget QTkBuild}

{QTk.registerAlias funnylabel
 fun{$ Desc}
    {Record.adjoin Desc
     label(foreground:red background:green)}
 end}
