fun{TDLR LR}
   proc{$ P}
      Desc=P.desc
      Handle=P.handle
      Tab={ToArray Desc}
      Remain={Record.filterInd Desc fun{$ I _} {Not {Int.is I}} andthen I\=glue end}
      {QTkBuild {Record.adjoinAt P desc Remain}}
      Array={List.map Tab
	     fun{$ Line}
		{List.map Line
		 fun{$ Elem}
		    case {Label Elem}
		    of continue then continue
		    [] empty then empty
		    else
		       Child={P.build {Record.subtract Elem glue}}
		    in
		       r(glue:Elem.glue
			 child:Child)
		    end
		 end}
	     end}
      TblInfo={CalcLR Tab LR}
      C
   in
      {List.forAllInd Array
       proc{$ I X}
	  proc{Loop J Elems}
	     case Elems
	     of continue|Ls then
		{Loop J+1 Ls}
	     [] empty|Ls then
		{Loop J+1 Ls}
	     [] Elem|Ls then
		Line=if LR then I else J end
		Col=if LR then J else I end
		Span=if LR then columnspan else rowspan end
	     in
		{Handle display(Elem.child
				o(sticky:{ToDescGlue Elem.glue}
				  row:Line-1
				  column:Col-1
				  Span:1+{ContinueLength Ls}))}
		{Loop J+1 Ls}
	     else skip
	     end
	  end
       in
	  {Loop 1 X}
       end}
      {Handle bind(event:'connect' unbind:C
		   action:proc{$}
			     {List.forAllInd TblInfo.h
			      proc{$ I X}
				 {Handle columnconfigure(I-1 weight:if X then 100 else 0 end)}
			      end}
			     {List.forAllInd TblInfo.v
			      proc{$ I X}
				 {Handle rowconfigure(I-1 weight:if X then 100 else 0 end)}
			      end}
			     {C}
			  end)}

   end
end

class TableRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).frame tkInit(parent:self.parent.handle)}
      {self initState}
      {ForAll {{self.manager getStore(col $)} getState($)}
       proc{$ K#V}
	  {self set(col K V)}
       end}
      {ForAll {{self.manager getStore(row $)} getState($)}
       proc{$ K#V}
	  {self set(row K V)}
       end}
   end
   meth importHere(Ob PlacementInstructions)
      {self.tk.send {Record.adjoin PlacementInstructions grid(Ob.handle)}}
   end
   meth set(Id K V)=M
      case Id
      of col then
	 {TkExec self.tk [grid columnconfigure self.handle K d(V)]}
      [] row then
	 {TkExec self.tk [grid rowconfigure self.handle K d(V)]}
      else
	 TkRender,M
      end
   end
   meth remove(Ob)
      {self.tk.send grid(forget Ob.handle)}
   end
end

class TableProxy from TkProxy
   feat
      widgetName:frame
      Columns
      Rows
   prop locking
   meth init
      TkProxy,init
      {self.Manager setRenderContextClass(default TableRender)}
      self.Columns={self.Manager getStore(col $)}
      self.Rows={self.Manager getStore(row $)}
   end
   meth display(Widget PlacementInstructions)
      lock
	 fun{ToCode PlacementInstructions}
	    Row=PlacementInstructions.row
	    Column=PlacementInstructions.column
	 in
	    {VirtualString.toAtom Row#":"#Column}
	 end
	 Ref=if {Object.is Widget} then
		{Widget.Manager getRef($)}
	     else
		Widget
	     end
	 Code={ToCode PlacementInstructions}
      in
	 {ForAll {self.Manager getChildrenIds($)}
	  proc{$ K}
	     if {ToCode {self.Manager getChildInfo(K $)}.2}==Code then
		{self.Manager dropClient(K)}
	     end
	  end}
	 {self.Manager importHere(Ref PlacementInstructions)}
      end
   end
   meth columnconfigure(I ...)=M
      {Wait {self.Columns remoteSet(I {Record.subtract M 1} $)}}
   end
   meth rowconfigure(I ...)=M
      {Wait {self.Rows remoteSet(I {Record.subtract M 1} $)}}      
   end
end

TableWidget={CreateWidgetClass
	     table(proxy:TableProxy
		   synonyms:Synonyms
		   defaultRenderClass:TableRender
		   rendererClass:TCLTK)}

{QTk.registerAs td TableWidget {TDLR false}}
{QTk.registerAs lr TableWidget {TDLR true}}
