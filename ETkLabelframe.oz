class LabelframeRender from TkRender
   meth init(M)
      TkRender,init(M)
      C={(self.tk).newWidgetClass noCommand labelframe}
   in
      self.handle={New C tkInit(parent:self.parent.handle)}
      {self.tk.send grid(columnconfigure self.handle 0 weight:100)}
      {self.tk.send grid(rowconfigure self.handle 0 weight:100)}
      {self initState}
   end
   meth importHere(Ob PlacementInstructions)
      {self.tk.send grid(Ob.handle column:0 row:0 sticky:nswe)}
   end
   meth remove(Ob)
      {self.tk.send grid(forget Ob.handle)}
   end   
end

class LabelframeProxy from TkProxy
   feat widgetName:labelframe
   meth display(Widget)
      {ForAll {self.Manager getChildrenIds($)}
       proc{$ Id}
	  {self.Manager dropClient(Id)}
       end}
      if {Object.is Widget} then
	 {self.Manager importHere({Widget.Manager getRef($)} unit)}
      else
	 {self.Manager importHere(Widget unit)}
      end
   end      
end

LabelframeWidget={CreateWidgetClass
		  labelframe(proxy:LabelframeProxy
			     synonyms:Synonyms
			     defaultRenderClass:LabelframeRender
			     rendererClass:TCLTK
			    )}



{QTk.register LabelframeWidget proc{$ Env}
				  if {HasFeature Env.desc 1} then
				     SH={Env.build Env.desc.1}
				  in
				     {Env.handle display(SH)}
				  end
				  {QTkBuild {Record.adjoinAt Env desc {Record.subtract Env.desc 1}}}
			       end}

