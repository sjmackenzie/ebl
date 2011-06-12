functor

import
   ETk at 'ETk.ozf'
   Application
   Discovery
   Connection

define

   UI={ETk.etk.build window(name:win
			    action:proc{$}
				      {Application.exit 0}
				   end
			    td(glue:nswe
			       selector(name:sel
					action:proc{$}
						  {Select {UI.sel get(curselection:$)}}
					       end
					glue:nswe)
			       button(text:"Refresh"
				      name:refresh
				      action:Refresh)))}

   {UI.win show}
   {UI.sel setContext(listbox)}


   Items={NewCell nil}

   proc{Select S}
      lock RefreshLock then
	 try {{List.nth {Access Items} S}.2 ETk} catch _ then skip end
      end
   end

   RefreshLock={Lock.new}

   proc{Refresh}
      lock RefreshLock then
	 {UI.refresh set(state:disabled)}
	 {Assign Items nil}
	 proc{Map L}
	    case L of nil then skip
	    else
	       if {Not {List.member L.1 {Access Items}}} then
		  {Assign Items L.1|{Access Items}}
	       end
	       {Map L.2}
	    end
	 end
	 Client={New Discovery.client init(port:15633)}
      in
	 {Map {Client getAll(timeOut:2000
			     info:$)}}
	 {Assign Items {List.map {Access Items} fun{$ L} {Connection.take L} end}}
	 {UI.sel set(items:{List.map {Access Items} fun{$ L#_} L end})}
	 {Client close}
	 {UI.refresh set(state:normal)}
      end
   end

   {Refresh}

end