fun{TkFont2ETkFont F}
   {Record.adjoin
    r(family:F.family
      overstrike:F.overstrike==1
      size:F.size
      italic:F.slant=="italic"
      bold:F.weight=="bold"
      underline:F.underline==1) {Label F}}
end

class FontClass
   meth !Init skip end
   meth actual('at':Ob<=unit F $)
      {TkFont2ETkFont {TkStringTo.guessParams actual {RReturn Ob
						      fun{$ E F1}
							 F={Marshall TkRenderMarshaller 'Font' s2u(F1)}
						      in
							 {TkReturn {E get(tk $)} [font actual F]}
						      end
						      {Marshall TkProxyMarshaller 'Font' u2s(F)}}}}
   end
   meth families('at':Ob<=unit $)
      {TkStringTo.guessParams families {RReturn Ob
					fun{$ E _}
					   {TkReturn {E get(tk $)} [font families]}
					end _}}
   end
   meth measure('at':Ob<=unit F T $)
      {TkStringTo.guess {RReturn Ob
			 fun{$ E F1#T}
			    F={Marshall TkRenderMarshaller 'Font' s2u(F1)}
			 in		 
			    {TkReturn {E get(tk $)} [font measure F T]}
			 end {Marshall TkProxyMarshaller 'Font' u2s(F)}#T}}
   end
   meth metrics('at':Ob<=unit F $)
      {TkStringTo.guessParams metrics {RReturn Ob
				       fun{$ E F1}
					  F={Marshall TkRenderMarshaller 'Font' s2u(F)}
				       in
					  {TkReturn {E get(tk $)} [font metrics F]}
				       end {Marshall TkProxyMarshaller 'Font' u2s(F)}}}
   end
end


class FontRender from TkRender
   meth init(M)
      TkRender,init(M)
      S={M getStore(main $)}
   in
      self.handle={TkReturn self.tk [font create]}
      {ForAll {S getState($)}
       proc{$ K#V}
	  {self set(main K V)}
       end}
   end
   meth set(I K V)=M
      case I
      of main then
	 case K
	 of bold then {TkExec self.tk [font configure self.handle o(weight:if V then bold else normal end)]}
	 [] italic then {TkExec self.tk [font configure self.handle o(slant:if V then italic else roman end)]}
	 else
	    {TkExec self.tk [font configure self.handle o(K:V)]}
	 end
      else TkRender,M
      end
   end
   meth destroy
      {TkExec self.tk [font delete self.handle]}
   end
end

class FontProxy from TkMultiProxy
   feat widgetName:font
   meth init(...)=M
      TkMultiProxy,M
      {self.Store setParametersType(o(family:'Family'
				      size:'Size'
				      bold:'Bold'
				      italic:'Italic'
				      underline:'Underline'
				      overstrike:'Overstrike'))}
      {self.Store setTypeChecker(t('Family':TypeDef.vString
				   'Size':TypeDef.integer
				   'Bold':TypeDef.boolean
				   'Italic':TypeDef.boolean
				   'Underline':TypeDef.boolean
				   'Overstrike':TypeDef.boolean))}
      {self.Store setDefaults(o(family:""
				size:0
				bold:false
				italic:false
				underline:false
				overstrike:false))}
   end
end


FontWidget={CreateWidgetClass
	    font(proxy:FontProxy
		 synonyms:s
		 defaultRenderClass:FontRender
		 rendererClass:TCLTK)}

fun{NewFont P}
   F={New FontWidget init}
in
   {F {Record.adjoin P set}}
   F
end