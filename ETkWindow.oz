fun{Geometry2String M}
   W={CondSelect M width unit}
   H={CondSelect M height unit}
   X={CondSelect M x unit}
   Y={CondSelect M y unit}
   if (W==unit andthen H\=unit) orelse (W\=unit andthen H==unit) then
      raise error(bothWidthAndHeightMustBeSpecified M) end
   end
   if (X==unit andthen Y\=unit) orelse (X\=unit andthen Y==unit) then
      raise error(bothXandYMustBeSpecified M) end
   end
   if {Not {List.all [W H X Y] fun{$ C} C==unit orelse {Int.is C} end}} then
      raise error(expectedIntegerParameters M) end
   end
   fun{Sign S}
      if S>=0 then "+"#S else "-"#(0-S) end
   end
   F=if {HasFeature M width} then
	M.width#"x"#M.height else ""
     end
   E=if {HasFeature M x} then
	{Sign M.x}#{Sign M.y}
     else "" end
in
   F#E
end

fun{WindowMarshall Handle K V}
   case K
   of disabled then [attributes Handle "-"#K V]
   [] toolwindow then [attributes Handle "-"#K V]
   [] topmost then [attributes Handle "-"#K V]
   [] client then [K Handle V]
   [] colormapwindows then [K Handle V]
   [] focusmodel then [K Handle V]
   [] geometry then [K Handle {Geometry2String V}]
   [] grid then [K Handle V] %% o(BaseWidth baseHeight widthInc heightInc)
   [] group then [K Handle V]
   [] iconbitmap then
      E={Handle.manager getEnv($)}
      G={E get(global $)}
   in
      [K Handle {G E V}]
   [] iconmask then
      E={Handle.manager getEnv($)}
      G={E get(global $)}
   in
      [K Handle {G E V}]
   [] iconname then [K Handle V]
   [] iconposition then [K Handle V]
   [] iconwindow then [K Handle V]
   [] maxsize then [K Handle V]
   [] minsize then [K Handle V]
   [] overrideredirect then [K Handle V]
   [] positionfrom then [K Handle V]
   [] resizable then [K Handle V]
   [] sizefrom then [K Handle V]
   [] stackorder then [K Handle V]
   [] state then [K Handle V]
   [] title then [K Handle V]
   [] transient then [K Handle V]
   end
end

class WindowRender from TkRender
   meth init(M)
      TkRender,init(M)
      self.handle={New (self.tk).toplevel tkInit(withdraw:true
						 delete:self.eventPort#v(store:self.store
									 obj:self
									 event:default))}
      {self.tk.send grid(columnconfigure self.handle 0 weight:100)}
      {self.tk.send grid(rowconfigure self.handle 0 weight:100)}
      {self initState}
      {ForAll {self.manager getState(wm $)}
       proc{$ K#V}
	  {self set(wm K V)}
       end}
   end
   meth importHere(Ob PlacementInstructions)
      {self.tk.send grid(Ob.handle column:0 row:0 sticky:nswe)}
   end
   meth set(I K V)=M
      case I of wm then
	 {TkExec self.tk wm|{WindowMarshall self.handle K V}}
      else
	 TkRender,M
      end
   end
   meth remove(Ob)
      {self.tk.send grid(forget Ob.handle)}
   end
end

class ShakyWindowRender from WindowRender
   feat ThId
   meth init(M)
      WindowRender,init(M)
      thread
	 self.ThId={Thread.this}
	 proc{Loop}
	    {self.tk.send wm(attributes self.handle toolwindow:true)}
	    {Delay 500}
	    {self.tk.send wm(attributes self.handle toolwindow:false)}
	    {Delay 500}
	    {Loop}
	 end
      in
	 {Loop}
      end
   end
   meth destroy
      try {Thread.terminate self.ThId} catch _ then skip end
      WindowRender,destroy
   end
end



class WindowProxy from TkProxy
   feat widgetName:toplevel
   meth init
      TkProxy,init
%      {self.Manager setRenderContextClass(default WindowRender)}
%      {self.Manager setRenderContextClass(shaky ShakyWindowRender)}
      Env={self.Manager createRemoteEnvironment($)}
      {Env put(tk Tk)}
      {Env put(global Globalizer)}
      {Env put(system System)}
   in
      {self.Manager createRemoteHere(Env)}
   end
   meth wm(...)=M
      Store={self.Manager getStore(wm $)}
   in
      {Record.forAllInd M
       proc{$ K V}
	  R
       in
	  {Store remoteSet(K V R)}
	  try {Wait R} catch X then
	     raise eblError(couldNotWm(X) hint:"Could not set wm "#K#" to "#V info:X) end
	  end
	  if R==false then
	     raise eblError(couldNotWm(K) hint:"Could not set wm "#K#" to "#V) end
	  end
       end}
   end
   meth show
      {self wm(state:normal)}
   end
   meth hide
      {self wm(state:withdrawn)}
   end
   meth iconify
      {self wm(state:iconic)}
   end
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
   meth getRef($)
      raise error end
   end
end

WindowWidget={CreateWidgetClass
	      w(proxy:WindowProxy
		synonyms:Synonyms
		defaultRenderClass:WindowRender
		rendererClass:TCLTK
		renderers:r(shaky:ShakyWindowRender)
	       )}


{QTk.registerAs window WindowWidget
 proc{$ Env}
    {QTkBuild {Record.adjoinAt Env desc {Record.subtract Env.desc 1}}}
    if {HasFeature Env.desc 1} then
       SH={Env.build Env.desc.1}
    in
       {Env.handle display(SH)}
    end
 end}
