ItemProxyMarshaller=t('Bitmap':TkProxyMarshaller.'Bitmap'
		      'Image':TkProxyMarshaller.'Image'
		      'Font':TkProxyMarshaller.'Font'
		      'Text':TkProxyMarshaller.'Text'
		      'Pixel':TkProxyMarshaller.'Pixel'
		      'Foreground':TkProxyMarshaller.'Foreground'
		      'Background':TkProxyMarshaller.'Background'
		      'Window':m(u2s:fun{$ V}
					if {Object.is V} then
					   {V getRef($)}
					elseif {ByteString.is V} then
					   V
					elseif {Record.is V} then
					   H={CondSelect V handle _}
					in
					   {QTk.build {Record.adjoinAt V handle H} _}
					   {H getRef($)}
					else
					   raise invalidWindow(V) end
					   unit
					end
				     end))

ItemRenderMarshaller=t('Bitmap':TkRenderMarshaller.'Bitmap'
		       'Image':TkRenderMarshaller.'Image'
		       'Font':TkRenderMarshaller.'Font'
		       'Text':TkRenderMarshaller.'Text'
		       'Pixel':TkRenderMarshaller.'Pixel'
		       'Window':m(s2u:fun{$ O M}
					 %% windows have to preserve widget hierarchy =>
					 %% each window has to be defined uniquely each time its met
					 Manager={M getManager($)}
					 E={Manager createRemoteEnvironment($)}
					 {{Manager getWidget($)} setChildEnvironment(E unit)}
					 {E put(proxy O)}
				      in
					 {{Manager createRemoteHere(E render:$)} getWidget($)}.handle
				      end))

ItemRefToHandle=m(s2u:fun{$ O M}
			 E={M getEnv($)}
		      in
			 {{E get(global $)} E O}.handle
		      end)


ItemCreateRenderMarshaller=t('Window':m(s2u:fun{$ _ _} '' end)
			     'Font':ItemRefToHandle
			     'Image':ItemRefToHandle
			     'Bitmap':ItemRefToHandle
			    )

ItemParametersType=t('...':'...'
		     1:'Type'
		     2:'Coords'
		     activestipple:'Bitmap'
		     outlinestipple:'Bitmap'
		     activeoutlinestipple:'Bitmap'
		     disabledoutlinestipple:'Bitmap'
		     stipple:'Bitmap'
		     disabledstipple:'Bitmap'
		     activebackground:'Bitmap'
		     disabledbackground:'Bitmap'
		     bitmap:'Bitmap'
		     activebitmap:'Bitmap'
		     disabledbitmap:'Bitmap'
		     activeforeground:'Bitmap'
		     disabledforeground:'Bitmap'
		     image:'Image'
		     activeimage:'Image'
		     disabledimage:'Image'
		     font:'Font'
		     text:'Text'
		     window:'Window'
		     fill:'Foreground'
		     activefill:'Foreground'
		     disabledfill:'Foreground'
		     outline:'Foreground'
		     activeoutline:'Foreground'
		     disabledoutline:'Foreground'
		     background:'Background'
		     foreground:'Foreground'
		     activewidth:'Pixel'
		     disabledwidth:'Pixel'
		     height:'Pixel'
		     width:'Pixel')

ItemTypeChecker=t('Type':{TypeDef.elementOf [arc bitmap image line oval polygon rectangle text window]}
		  'Coords':fun{$ L}
			      {List.is L} andthen
			      {List.all L Float.is} andthen
			      ({Length L} mod 2)==0
			   end#"A list composed of an even number of floats"
		  'Bitmap':TkTypeChecker.'Bitmap'
		  'Image':TkTypeChecker.'Image'
		  'Font':TkTypeChecker.'Font'
		  'Text':TkTypeChecker.'Text'
		  'Pixel':TkTypeChecker.'Pixel'
		  'Foreground':TkTypeChecker.'Foreground'
		  'Background':TkTypeChecker.'Background'
		  'Window':fun{$ V}
			      {Object.is V} orelse {ByteString.is V} orelse {Record.is V}
			   end#"A widget, a reference to a widget or a record representing a widget"
		  '...':RemoteType)

fun{TkStringToFloat S}
   case S of &-|Ls then
      {String.toFloat &~|Ls}
   else
      {String.toFloat S}
   end
end

class CanvasRender from TkItemsRender
   attr
      order
   meth init(M)
      TkItemsRender,init(M)
      self.handle={New (self.tk).canvas tkInit(parent:self.parent.handle)}
      order<-nil
      {self setOrder({self.manager get(order order $)})}
      {self initState}
   end
   meth set(I K V)
      case I#K of order#order then
	 {self setOrder(V)}
      elseif {Name.is I} then
	 H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    case K
	    of 1 then skip
	    [] 2 then
	       {TkExec self.tk [self.handle coords H b(V)]}
	    else
	       {TkExec self.tk [self.handle itemconfigure H "-"#K V]} % {CanvasItemUnMarshaller.ounmarshall self K V}]}
	    end
	 end
      else
	 TkItemsRender,set(I K V)
      end
   end
   meth remoteGet(I K V)
      if {Name.is I} then
	 H={Dictionary.condGet self.items I unit}
      in
	 if H\=unit then
	    case K
	    of 1 then
	       V={TkReturn self.tk [self.handle type H]}
	    [] 2 then
	       V={List.map {String.tokens {TkReturn self.tk [self.handle coords H]} & }
		  TkStringToFloat}
	    else
	       V={TkReturn self.tk [self.handle itemcget H "-"#K]} % {CanvasItemUnMarshaller.ounmarshall self K V}]}
	    end
	 else
	    raise error end
	 end
      else
	 TkItemsRender,remoteGet(I K V)
      end
   end
   meth setOrder(V)
      {ForAll V
       proc{$ I}
	  if {Not {Dictionary.member self.items I}} then
	     Store={self.manager getStore(I $)}
	     State={List.filter {Store getState($)}
		    fun{$ K#_} K\=1 andthen K\=2 end}
	     H
	     if State==nil then
		H={TkReturn self.tk [self.handle create {Store get(1 $)}
				     b({Store get(2 $)})]}
	     else
		H={TkReturn self.tk [self.handle create {Store get(1 $)}
				     b({Store get(2 $)})		
				     {List.toRecord o State}]}
	     end
	  in
	     {Dictionary.put self.items I H}
	     order<-I|@order
	  end
       end}
      RV={List.toRecord o {List.map V fun{$ I} I#I end}}
      order<-{List.filter @order
	      fun{$ I}
		 if {HasFeature RV I} then true else
		    {TkExec self.tk [self.handle delete {Dictionary.get self.items I}]}
		    {Dictionary.remove self.items I}
		    false
		 end
	      end}
      %% order and V are now of the same size, representing the same items
      %% => set them up so that the appear in the same order
   in
      if @order\=V then
	 proc{Loop Parent L}
	    case L of I|Is then
	       H={Dictionary.get self.items I}
	    in
	       if Parent==unit then
		  {TkExec self.tk [self.handle 'raise' H]}
	       else
		  {TkExec self.tk [self.handle lower H Parent]}
	       end
	       {Loop H Is}
	    else skip end
	 end
      in
	 {Loop unit V}
	 order<-V
      end
   end
   meth ask(Q R)=M
      case Q
      of create(Type Coord ...) then
	 P={Record.mapInd {Record.subtract {Record.subtract Q 1} 2}
	    fun{$ K V}
	       {Marshall ItemCreateRenderMarshaller
		{CondSelect ItemParametersType K '...'}
		s2u(V self.manager)}
	    end}
      in
%	 R=true
%	 {self.handle tk(create Type b(Coord) d(P))}
	 R={(self.tk).returnInt set(v("e [catch {set o [") self.handle create Type
				    b(Coord) d(P)
				    v("];") self.handle v("delete $o}]; set e \"$e\""))}==0
	 {Wait R}
      [] bbox(Id) then
	 R={self.handle tkReturnListFloat(bbox({Dictionary.get self.items Id}) $)}
      [] move(Id X Y) then
	 H={Dictionary.get self.items Id}
	 {TkExec self.tk [self.handle move H X Y]}
      in
	 R={TkStringTo.listFloat {TkReturn self.tk [self.handle coord H]}}
      [] scale(Id X Y SX SY) then
	 H={Dictionary.get self.items Id}
	 {TkExec self.tk [self.handle scale H X Y SX SY]}
      in
	 R={TkStringTo.listFloat {TkReturn self.tk [self.handle coord H]}}
      [] canvasx(X) then
	 R={self.handle tkReturnFloat(canvasx(X) $)}
      [] canvasy(Y) then
	 R={self.handle tkReturnFloat(canvasy(Y) $)}
      [] getFocus then
	 R1={self.handle tkReturn(focus $)}
      in
	 if R1=="" then R=''
	 else
	    fun{Loop L}
	       case L of K#!R1|_ then K
	       [] _|Ls then {Loop Ls}
	       else '' end
	    end
	 in
	    R={Loop {Dictionary.entries self.items}}
	 end
      else
	 TkItemsRender,M
      end
   end
   meth send(K)=M
      case K of focus(Id) then
	 {TkExec self.tk [self.handle focus {Dictionary.get self.items Id}]}
      [] focus then
	 {TkExec self.tk [self.handle focus '']}
      else TkItemsRender,M
      end
   end
end

Delete={NewName}
Lower={NewName}
Raise={NewName}

class CanvasItem from TkProxy
   feat Parent Id 
   meth init(P I S)
      self.Manager=P.Manager
      self.Parent=P
      self.Id=I
      self.Store=S
   end
   meth set(...)=M
      W={List.map
	 {Record.toListInd M}
	 fun{$ K#V}
	    {self.Store remoteSet(K V $)}
	 end}
   in
      {ForAll W Wait}
   end
   meth get(...)=M
      {Record.forAllInd M
       proc{$ K V}
	  {self.Store remoteGet(K V)}
       end}
   end
   meth bbox($)
      {self.Manager ask(bbox(self.Id) $)}
   end
   meth setCoords(C)
      {Wait {self.Store remoteSet(2 C $)}}
   end
   meth getCoords($)
      {self.Store get(2 $)}
   end
   meth destroy
      {self.Manager Delete(self.Id)}
      {self.Store destroy}
   end
   meth getFocus
      {self.Manager send(focus(self.Id))}
   end
   meth lower(Below<=r(Id:unit))
      {self.Parent Lower(self.Id Below.Id)}
   end
   meth 'raise'(Above<=r(Id:unit))
      {self.Parent Raise(self.Id Above.Id)}      
   end
   meth move(X Y)
      R={self.Manager ask(move(self.Id X Y) $)}
      {Wait R}
   in
      {self.Store set(2 R)}
   end
   meth scale(X Y SX SY)
      R={self.Manager ask(scale(self.Id X Y SX SY) $)}
      {Wait R}
   in
      {self.Store set(2 R)}
   end
end



class CanvasProxy from XYTkProxy
   feat
      widgetName:canvas
      Items
   attr
      Order
   meth init
      XYTkProxy,init
      self.Items={Dictionary.new}
      Order<-nil
      local
	 T={self.Manager getStore(order $)}
      in
	 {T setTypeChecker(o('...':TkTypeChecker.'Any'))}
	 {T set(order @Order)}
      end
   end
   meth create(Type handle:H<=_ Coords ...)=M
      Id={NewName}
      P={Record.mapInd {Record.subtract M handle}
	 fun{$ K V}
	    {Marshall ItemProxyMarshaller
	     {CondSelect ItemParametersType K '...'}
	     u2s(V)}
	 end}
   in
      if {self.Manager ask(P $)}==true then
	 Store={self.Manager getStore(Id $)}
	 {Store setParametersType(ItemParametersType)}
	 {Store setTypeChecker(ItemTypeChecker)}
	 {Store setProxyMarshaller(ItemProxyMarshaller)}
	 {Store setRenderMarshaller(ItemRenderMarshaller)}
	 O N
      in
	 {Record.forAllInd {Record.subtract M handle}
	  proc{$ K V}
	     {Store set(K V)}
	  end}
	 O=Order<-N
	 {self.Manager set(order order N)}
	 N=Id|O
	 H={New CanvasItem init(self Id Store)}
	 {Dictionary.put self.Items Id H}
      else raise unableToCreate(M) end end
   end
   meth !Delete(I)
      O N N2
   in
      O=Order<-N
      N2={List.subtract O I}
      if O\=N2 then
	 {Dictionary.remove self.Items I}
	 {self.Manager set(order order N)}
	 N=N2
      else N=O
      end
   end
   meth !Lower(ID1 ID2)
      N
      O=Order<-N
      N2
   in
      N2=if ID2==unit then
	    fun{Loop L}
	       case L of !ID1|Ls then
		  {List.append Ls [ID1]}
	       [] Lx|Ls then Lx|{Loop Ls}
	       else nil end
	    end
	 in
	    {Loop O}
	 else
	    fun{Loop L}
	       case L of !ID1|Ls then
		  fun{Loop1 L}
		     case L of !ID2|Ls then
			ID2|ID1|Ls
		     [] Lx|Ls then Lx|{Loop1 Ls}
		     else nil end
		  end
		  Lz={Loop1 Ls}
	       in
		  if Lz==Ls then L
		  else
		     Lz
		  end
	       [] !ID2|Ls then
		  Lz={List.subtract Ls ID1}
	       in
		  if Lz==Ls then L
		  else
		     ID2|ID1|Lz
		  end
	       [] Lx|Ls then
		  Lx|{Loop Ls}
	       else nil end
	    end
	 in
	    {Loop O}
	 end
      if O\=N2 then
	 {self.Manager set(order order N2)}
	 N=N2
      else
	 N=O
      end
   end
   meth !Raise(ID1 ID2)
      N
      O=Order<-N
      N2
   in
      N2=if ID2==unit then
	    Lz={List.subtract O ID1}
	 in
	    if O\=Lz then
	       ID1|Lz
	    else O end
	 else
	    fun{Loop L}
	       case L of !ID1|Ls then
		  fun{Loop1 L}
		     case L of !ID2|Ls then
			ID1|ID2|Ls
		     [] Lx|Ls then Lx|{Loop1 Ls}
		     else nil end
		  end
		  Lz={Loop1 Ls}
	       in
		  if Lz==Ls then L
		  else
		     Lz
		  end
	       [] !ID2|Ls then
		  Lz={List.subtract Ls ID1}
	       in
		  if Lz==Ls then L
		  else
		     ID1|ID2|Lz
		  end
	       [] Lx|Ls then
		  Lx|{Loop Ls}
	       else nil end
	    end
	 in
	    {Loop O}	    
	 end
      if O\=N2 then
	 {self.Manager set(order order N2)}
	 N=N2
      else
	 N=O
      end
   end
   meth canvasx(X $)
      {self.Manager ask(canvasx(X) $)}
   end
   meth canvasy(Y $)
      {self.Manager ask(canvasy(Y) $)}
   end
   meth getFocus($)
      {Dictionary.condGet self.Items {self.Manager ask(getFocus $)} unit}
   end
   meth clearFocus($)
      {self.Manager send(clearFocus)}
   end
%    meth scan(...)=M
%    end
%    meth selection(...)=M
%    end
end

CanvasWidget={CreateWidgetClass
	      canvas(proxy:CanvasProxy
		     synonyms:Synonyms
		     defaultRenderClass:CanvasRender
		     rendererClass:TCLTK
		    )}

{QTk.register CanvasWidget QTkBuild}

