class TkImageRender from TkRender
   meth ask(Q R)
      case Q
      of width then
	 R={Marshall TkRenderMarshaller 'Pixel'
	    u2s({TkReturn self.tk [image width self.handle]})}
      [] height then
	 R={Marshall TkRenderMarshaller 'Pixel'
	    u2s({TkReturn self.tk [image height self.handle]})}	 
      else
	 TkRender,ask(Q R)
      end
   end
end

class ImageRender from TkImageRender
   meth init(M)
      TkImageRender,init(M)
      S={M getStore(main $)}
      P=case {S get(palette $)}
	of A#B#C then
	   A#"/"#B#"/"#C
	[] X then X end
   in
      self.handle={New (self.tk).image tkInit(type:photo
					      data:{S get(data $)}
					      format:{S get(format $)}
					      gamma:{S get(gamma $)}
					      height:{S get(height $)}
					      width:{S get(width $)}
					      palette:P)}
   end
end

ImageDefaults=o(data:{ByteString.make ""}
		gamma:1.0
		format:"jpg"
		height:0
		palette:255#255#255
		width:0)

class ImageProxy from TkMultiProxy
   feat widgetName:image
   meth init(...)=M
      TkMultiProxy,M
      {self.Store setParametersType(o(data:'Data'
				      format:'Format'
				      gamma:'Gamma'
				      height:'Height'
				      palette:'Palette'
				      width:'Width'))}
      {self.Store setTypeChecker(t('Data':ByteString.is#"A bytestring"
				   'Format':fun{$ L} {List.member L ["gif" "jpeg" "jpg"]} end#"On of \"gif\", \"jpeg\" or \"jpg\""
				   'Gamma':Float.is#"A float"
				   'Height':TypeDef.pixel
				   'Width':TypeDef.pixel
				   'Palette':fun{$ E} case E of A#B#C then
							 {Int.is A} andthen {Int.is B} andthen {Int.is C}
						      else {Int.is E} end
					     end#"A single integer or a triplet A#B#C where A, B and C are integers"
				  ))}
      {self.Store setDefaults(ImageDefaults)}
   end
   meth getWidth($)
      {self.Manager ask(width $)}
   end
   meth getHeight($)
      {self.Manager ask(height $)}      
   end
end


ImageWidget={CreateWidgetClass
	     image(proxy:ImageProxy
		   synonyms:s
		   defaultRenderClass:ImageRender
		   rendererClass:TCLTK)}

CArray={NewArray 0 63 0}
{List.forAllInd "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 proc{$ I C}
    {Array.put CArray I-1 C}
 end}

ToByteString=VirtualString.toByteString

fun{Encode File}
   Handler Dump
in
   Handler={New Open.file init(url:File
			       flags:[read])}
   local T in
      T={Handler read(list:$ size:all)}
      case ({Length T} mod 3)
      of 0 then Dump=T
      [] 1 then Dump={List.append T [255 255]}
      [] 2 then Dump={List.append T [255]}
      end
   end
   {Handler close}
   local
      proc{ByteToBit B B0 B1 B2 B3 B4 B5 B6 B7}
	 fun {GetBit V B}
	    B=V mod 2
	    V div 2
	 end
      in
	 _={List.foldL [B0 B1 B2 B3 B4 B5 B6 B7] GetBit B}
      end
      fun{TB A0 A1 A2 A3 A4 A5}
	 {Array.get CArray A5*32+A4*16+A3*8+A2*4+A1*2+A0}
      end
      fun{Loop X N}
	 case X of A|B|C|Xs then
	    local
	       A0 A1 A2 A3 A4 A5 A6 A7
	       B0 B1 B2 B3 B4 B5 B6 B7
	       C0 C1 C2 C3 C4 C5 C6 C7
	    in
	       {ByteToBit A A0 A1 A2 A3 A4 A5 A6 A7}
	       {ByteToBit B B0 B1 B2 B3 B4 B5 B6 B7}
	       {ByteToBit C C0 C1 C2 C3 C4 C5 C6 C7}
	       if N>=68 then
		  {TB A2 A3 A4 A5 A6 A7}|{TB B4 B5 B6 B7 A0 A1}|{TB C6 C7 B0 B1 B2 B3}|{TB C0 C1 C2 C3 C4 C5}|10|32|32|32|32|{Loop Xs 0}
	       else
		  {TB A2 A3 A4 A5 A6 A7}|{TB B4 B5 B6 B7 A0 A1}|{TB C6 C7 B0 B1 B2 B3}|{TB C0 C1 C2 C3 C4 C5}|{Loop Xs N+4}
	       end
	    end
	 else if N>0 then 10|nil else nil end
	 end
      end
   in
      {ToByteString 32|32|32|32|{Loop Dump 0}}
   end
end
   
fun{NewImage Instruction}
   Data=if {HasFeature Instruction file} then
	   {Encode Instruction.file}
	else
	   {CondSelect Instruction data unit}
	end
   if Data==unit then
      {Exception.raiseError etk(image(missingFile))}
   end
   O={New ImageWidget init}
in
   {O {Record.adjoin ImageDefaults set}}
   {O {Record.adjoin {Record.subtract {Record.subtract Instruction data} file}
       set(data:Data)}}
   O
end

class BitmapRender from TkImageRender
   meth init(M)
      TkImageRender,init(M)
      S={M getStore(main $)}
      P
      try
	 P={S get(predef $)}
      catch _ then P=unit end
   in
      if P==unit then
	 self.handle={New (self.tk).image tkInit(type:bitmap
						 data:{S get(data $)}
						 maskdata:{S get(maskdata $)}
						 foreground:{S get(foreground $)}
						 background:{S get(background $)})}
      else
	 self.handle=P
      end
   end
end

BitmapDefaults=o(data:{ByteString.make ""}
		 maskdata:{ByteString.make ""}
		 foreground:black
		 background:"")

class BitmapProxy from TkMultiProxy
   feat widgetName:bitmap
   meth init(...)=M
      TkMultiProxy,M
      {self.Store setParametersType(o(data:'Data'
				      maskdata:'Data'
				      foreground:'Color'
				      background:'Color'))}
      {self.Store setTypeChecker(t('Data':ByteString.is#"A bytestring"
				   'Color':TypeDef.color))}
      {self.Store setDefaults(BitmapDefaults)}
   end
   meth getWidth($)
      {self.Manager ask(width $)}
   end
   meth getHeight($)
      {self.Manager ask(height $)}      
   end
end

class PredefBitmapProxy from TkProxy
   feat widgetName:bitmap
   meth init(V)
      TkProxy,init
      {self.Store setTypeChecker(t('...':TkTypeChecker.'Any'))}
      {self.Store setParametersType(t('...':'...'))}
      {self.Store set(predef V)}
      {self.Store setParametersType(t)}
   end
end

BitmapWidget={CreateWidgetClass
	      bitmap(proxy:BitmapProxy
		     synonyms:s
		     defaultRenderClass:BitmapRender
		     rendererClass:TCLTK)}

PredefBitmapWidget={CreateWidgetClass
		    bitmap(proxy:PredefBitmapProxy
			   synonyms:s
			   defaultRenderClass:BitmapRender
			   rendererClass:TCLTK)}

fun{Insert File}
   Handler Dump
in
   Handler={New Open.file init(url:File
			       flags:[read])}
   Dump={ToByteString {Handler read(list:$ size:all)}}
   {Handler close}
   Dump
end


fun{NewBitmap Instruction}
   Data=if {HasFeature Instruction file} then
	   {Insert Instruction.file}
	else
	   {CondSelect Instruction data unit}
	end
   if Data==unit then
      {Exception.raiseError etk(image(missingFile))}
   end
   MaskData=if {HasFeature Instruction maskfile} then
	       {Insert Instruction.maskfile}
	    else
	       {CondSelect Instruction maskdata {ByteString.make ""}}
	    end
   O={New BitmapWidget init}
in
   {O {Record.adjoin BitmapDefaults set}}
   {O {Record.adjoin {Record.subtract {Record.subtract {Record.subtract Instruction data} file} maskfile}
       set(data:Data maskdata:MaskData)}}
   O
end

Bitmap={List.toRecord b
	{List.map [error 
		   gray75 
		   gray50 
		   gray25 
		   gray12 
		   hourglass 
		   info 
		   questhead 
		   question 
		   warning 
		   document 
		   stationery 
		   edition 
		   application 
		   accessory 
		   folder 
		   pfolder 
		   trash 
		   floppy 
		   ramdisk 
		   cdrom 
		   preferences 
		   querydoc 
		   stop 
		   note 
		   caution]
	 fun{$ E} E#{New PredefBitmapWidget init(E)} end}}
	 