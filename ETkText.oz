class TextRender from TkRender
   attr t
   meth init(M)
      TkRender,init(M)
      C T
   in
      self.handle={New (self.tk).text tkInit(parent:self.parent.handle)}
      T={M getStore(text $)}
      t<-""
      C={self.store createEvent(event:'<KeyPress>'
				args:nil
				action:proc{$}
					  N={self.handle tkReturn(get('1.0' 'end')$)}
				       in
					  if N\=@t then
					     t<-N
					     {T set(text N)}
					  end
				       end
				code:$)}
      {self bind(main C '<KeyPress>'#nil)}
      {self initState}
      {self set(text text {M get(text text $)})}
   end
   meth set(I K V)=M
      case I#K of text#text then
	 {self.handle tk(delete '1.0' 'end' v(";") self.handle insert '1.0' V)}
      else
	 TkRender,M
      end
   end
   meth ask(Q R)=M
      case Q
      of bbox(Id) then
	 R={TkStringTo.listFloat {TkReturn self.tk [self.handle bbox Id]}}
      [] index(Id) then
	 R={TkReturn self.tk [self.handle index Id]}
      [] delete(...) then
	 {TkExec self.tk [self.handle Q]}
	 R={TkReturn self.tk [self.handle get]}
      [] insert(...) then
	 {TkExec self.tk [self.handle Q]}
	 R={TkReturn self.tk [self.handle get]}
      else
	 TkRender,M
      end
   end
   meth send(M)
      case M
      of icursor(I) then
	 {TkExec self.tk [self.handle mark set insert I]}
      else
	 TkRender,send(M)
      end
   end
end

class TextProxy from XYTkProxy
   feat widgetName:text
   meth init(...)=M
      XYTkProxy,M
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

TextWidget={CreateWidgetClass
	     text(proxy:TextProxy
		   synonyms:Synonyms
		  defaultRenderClass:TextRender
		  rendererClass:TCLTK
		  )}

{QTk.register TextWidget QTkBuild}
