%declare 
%[ETk EBL]={Module.link ["ETk.ozf" "EBL.ozf"]}

functor
import
   ETk at 'ETk.ozf'
   Application
  
define

   QTk=ETk.etk

   proc{Go}
      {MyWin.listbox delete(0 'end')}
      IP PN
      {List.takeDropWhile {MyWin.text get(text:$)} fun{$ C} C\=&: end IP PN}
   in
      if PN\=nil then
      try
	 L={ETk.getFromPublisher IP {String.toInt PN.2}}
      in
	 {Assign Items L}
	 {MyWin.listbox insert(0 {List.map L fun{$ _#D} D end})}
      catch _ then skip end
      end
   end

   proc{Import}
      C={MyWin.listbox curselection($)}
   in
      if C\=nil then
	 proc{Zoom}
	    W={QTk.build window(name:top
				action:proc{$} {W destroyAll} end
			       )}
	 in
	    {W.top display(I.1)}
	    {W.top bind(event:lostWidget
			action:proc{$} {W destroyAll} end)}
	    {W.top show}
	 end
	 proc{Close}
	    {Pane destroy}
	 end
	 I={List.nth {Access Items} C.1+1}
%      Panes={MyWin.panedwindow getPanes($)}
	 Pane={MyWin.panedwindow addPane($)}
	 Placeholder={QTk.build td(name:top
				   lr(glue:nwe
				      button(glue:w text:"Zoom"
					     action:Zoom)
				      label(text:I.2 glue:we)
				      button(glue:e text:"X"
					     action:Close))
				   td(name:placeholder glue:nswe)
				  )}
	 {Pane display(Placeholder.top)}
      in
	 {Placeholder.placeholder display(I.1 grid(row:0 column:0 sticky:''))}
	 {Placeholder.placeholder bind(event:lostWidget
				       action:proc{$} {Pane destroy} end)}
	 {Pane set(minsize:100)}
      end
   end

   MyWin={QTk.build window(name:top
			   action:proc{$}
				     {MyWin destroyAll}
				     {Application.exit 0}
				  end
			   lr(glue:nswe
			      td(glue:nsw
				 lr(glue:nwe
				    entry(glue:nwe
					  name:text
					  background:QTk.color.white
					  text:"127.0.0.1:15632")
				    button(glue:ne text:"Go"
					   action:Go
					  ))
				 listbox(glue:nswe
					 name:listbox
					 background:QTk.color.white)
				 button(name:'import'
					action:Import
					text:"Import" glue:swe))
			      panedwindow(glue:nswe
					  name:panedwindow)
			     ))}

   Items={NewCell nil}

   try
      Pu={ETk.newPublisher 15633}
   in
      {ForAll {MyWin getAllNames($)}
       proc{$ N}
	  try Ref={MyWin.N getRef($)}
	  in
	     {Pu.subscribe N Ref N}
	  catch _ then skip end
       end}
   catch _ then skip end

   {MyWin sync}
   {MyWin.top show}

end