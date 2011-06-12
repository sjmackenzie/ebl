RegisterXLink={NewName}
RegisterYLink={NewName}

fun{XView Class}
   class $ from Class
      attr XLink
      meth init(...)=M
	 Class,M
	 {{self.Manager getStore(scrollview $)} setTypeChecker(t('...':TkTypeChecker.'Any'))}
	 XLink<-unit
      end
      meth getXView($)
	 {self.Manager ask(xview $)}
      end
      meth xview(...)=M
	 {self.Manager send(M)}
      end
      meth XView(...)=M
	 O=@XLink
      in
	 if O\=unit then
	    {O.1 {Record.adjoin M setPos}}
	 end
      end
      meth !RegisterXLink(L)
	 O N
	 O=XLink<-N
	 if O\=unit then
	    {O.2}
	 end
	 C U
      in
	 if L==unit then
	    {{self.Manager getStore(scrollview $)} set(yview false)}
	    N=unit
	 else
	    Store={self.Manager getStore(scrollview $)}
	 in
	    C={Store createEvent(args:[1 2 3 4 5]
				 action:self#XView
				 code:$
				 unbind:U)}
	    {Store registerVirtualEvent(xview C)}
	    {Store set(xview true)}
	    N=L#U
	 end
      end
   end
end

fun{YView Class}
   class $ from Class
      attr YLink
      meth init(...)=M
	 Class,M
	 {{self.Manager getStore(scrollview $)} setTypeChecker(t('...':TkTypeChecker.'Any'))}
	 YLink<-unit
      end
      meth getYView($)
	 {self.Manager ask(yview $)}
      end
      meth yview(...)=M
	 {self.Manager send(M)}
      end
      meth YView(...)=M
	 O=@YLink
      in
	 if O\=unit then
	    {O.1 {Record.adjoin M setPos}}
	 end
      end
      meth !RegisterYLink(L)
	 N
	 O=YLink<-N
	 if O\=unit then
	    {O.2}
	 end
	 C U
      in
	 if L==unit then
	    {{self.Manager getStore(scrollview $)} set(yview false)}
	    N=unit
	 else
	    Store={self.Manager getStore(scrollview $)}
	 in
	    C={Store createEvent(args:[1 2 3 4 5]
				 action:self#YView
				 code:$
				 unbind:U)}
	    {Store registerVirtualEvent(yview C)}
	    {Store set(yview true)}
	    N=L#U
	 end
      end
   end
end

class ScrollbarRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).scrollbar tkInit(parent:self.parent.handle
						  action:self.eventPort#v(store:self.store
									  obj:self
									  event:default))}
      {self initState}
   end
   meth send(M)
      case M
      of set(F L) then
	 {TkExec self.tk [self.handle set F L]}
      else TkRender,M
      end
   end
end

class ScrollbarProxy from TkProxy
   feat
      widgetName:scrollbar
   attr
      XLink
      YLink
   meth init(...)=M
      C
   in
      TkProxy,M
      XLink<-nil
      YLink<-nil
      C={self.Store createEvent(args:[1 2 3 4 5]
				action:self#Set
				code:$)}
      {self.Store registerVirtualEvent(default C)}
   end
   meth Set(...)=M
      M1={Record.adjoin M xview}
      M2={Record.adjoin M yview}
   in
      {ForAll @XLink
       proc{$ O}
	  {O M1}
       end}
      {ForAll @YLink
       proc{$ O}
	  {O M2}
       end}
   end
   meth setPos(...)=M
      case M of setPos(F L) then
	 {self.Manager send(set(F L))}
      else skip end
   end
   meth addXLink(M)
      O N
   in
      O=XLink<-N
      N=M|O
      {M RegisterXLink(self)}
   end
   meth addYLink(M)
      O N
   in
      O=YLink<-N
      N=M|O
      {M RegisterYLink(self)}
   end
   meth dropXLink(M)
      O N
   in
      O=XLink<-N
      N={List.subtract O M}
      {M RegisterXLink(unit)}
   end
   meth dropYLink(M)
      O N
   in
      O=YLink<-N
      N={List.subtract O M}
      {M RegisterYLink(unit)}
   end
end

ScrollbarWidget={CreateWidgetClass
		 scrollbar(proxy:ScrollbarProxy
			   synonyms:Synonyms
			   defaultRenderClass:ScrollbarRender
			   rendererClass:TCLTK
			  )}

{QTk.register ScrollbarWidget QTkBuild}

XYTkProxy={XView {YView TkProxy}}
XTkProxy={XView TkProxy}
