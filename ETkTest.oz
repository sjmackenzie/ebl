\define OPI
declare
\insert 'ETkMisc.oz'
\insert 'EBL.oz'
\insert 'ParametersGatherer.oz'
\insert 'ETk.oz'

{Browse QTk}

%declare 
%QTk={Module.link ["ETk.ozf"]}.1.etk

% W={QTk.build window(name:top
% 		    panedwindow(name:p))}
% {W.top show}
% R1={W.p addPane($)}
% {R1 display({QTk.build label(name:l text:"Coucou")}.l)}
% R2={W.p addPane($)}
% {R2 display({QTk.build label(name:l text:"Coucou")}.l)}
% %{R1 set(minsize:100)}
% %{R2 set(minsize:100)}
% {R1 setWidth(150)}

% {Browse {R1 getSash($)}}
% {R1 setSash(60)}

% W={QTk.build window(name:top
% 		    menubutton(name:menu text:"Menu"
% 			       menu:{QTk.newMenu menu(command(label:"Exit")
% 						      radiobutton(group:g1 label:"Group 1")
% 						      cascade(label:"Cascade"
% 							      menu:menu(radiobutton(group:g1
% 										    label:"Group 1"))))}))}
% {W.top show}

% {Pickle.save {W.menu getRef($)} "ticket"}

% MyFont={QTk.newFont font(family:"Courier")}
% {MyFont set(bold:true)}

% %{Browse {QTk.font families($)}}
% W={QTk.build window(name:top
% 		    lr(td(name:jean
% 			  menubutton(name:filemenu text:"File"
% 				     menu:{QTk.newMenu menu(command(label:"Exit")
% 							    radiobutton(group:g1 label:"Group 1")
% 							    cascade(label:"Cascade"
% 								    menu:menu(radiobutton(group:g1
% 											  label:"Group 1"))))}
% 				    )
% 			  entry(name:e
% 				action:proc{$}
% 					  T={W.e get(text:$)}
% 				       in
% 					  {W.l set(text:T)}
% 				       end)
% 			  label(text:"éö\ncaca" name:l font:MyFont)
% 			  checkbutton(text:"Coucou" selected:true)
% 			  lr(listbox(name:listbox) scrollbar(glue:ns orient:vertical name:vscroll))
% 			  message(text:"Message")
% 			  radiobutton(text:"Group 1" group:g1))
% 		       scale(orient:vertical glue:ns 'from':0.0 'to':100.0 name:scale)
% 		       labelframe(glue:nswe text:"Frame"
% 				  td(spinbox('from':0.0 'to':100.0)
% 				     panedwindow(name:paned glue:nswe)
% 				    ))
% 		       lr(text(name:text wrap:none glue:nswe) scrollbar(glue:ns orient:vertical name:tsv) newline
% 			  scrollbar(glue:we orient:horizontal name:tsh))
% 		       newline
% 		       canvas(name:canvas glue:nswe background:QTk.color.green height:100)
% 		       continue continue continue
% 		      ))}
% {W.top display(W.canvas)}
% {W.top show}
% {W.l set(foreground:QTk.color.red)}
% {W.vscroll addYLink(W.listbox)}
% {W.tsv addYLink(W.text)}
% {W.tsh addXLink(W.text)}

% {W.e bind(event:default action:proc{$} {System.show key} end)}
% {W.e set(text:"Coucou")}
% {W.listbox insert('end' ["Option 1" "Optioné 2" a b c d e f g h i j k l m n])}
% {{W.listbox getItem(0 $)} set(background:QTk.color.blue)}
% P1={W.paned addPane($)}
% P2={W.paned addPane($)}
% Img={QTk.newImage image(file:"test.gif" format:"gif")}
% {P1 display({QTk.build label(name:l image:Img)}.l)}
% {P2 display({QTk.build label(name:l bitmap:QTk.bitmap.error)}.l)}
% {P1 set(sticky:n minsize:100)}

% H1={W.canvas create(handle:$ rectangle [10.0 10.0 100.0 100.0])}
% H2={W.canvas create(handle:$ line [10.0 10.0 100.0 100.0])}
% H3={W.canvas create(handle:$ oval [10.0 10.0 100.0 100.0])}

% {H1 move(100 0)}
% {H1 set(fill:QTk.color.white)}

% {W.canvas create(window anchor:w [200.0 50.0] window:button(text:"Coucou"
% 							    action:proc{$} {Show coucou} end
% 							   ))}
% {W.canvas create(bitmap [10.0 10.0] bitmap:QTk.bitmap.error)}
% {W.canvas create(image [100.0 50.0] image:Img)}

% {H1 bind(event:"1" action:proc{$} {Show click} end)}

% {Pickle.save {W.jean getRef($)} "ticket"}

% {Show 1}
% W={ETk.build window(name:top
% 		    td(label(text:"éö\ncaca" name:l)))}
% {Show 2}
% {W.top show}
% {Show 3}
% {W.l set(foreground:ETk.color.red)}


% declare

% fun{Ref2Id Ref}
%    {Pickle.unpack Ref}.1
% end

% {Show aa0}
% ETk={Module.link ["ETk.ozf"]}.1.etk
% {Show a0}
% {Show a1}
% MyFont={ETk.newFont font(family:"Arial")}
% {Show a2}
% {MyFont set(size:20 bold:false underline:false overstrike:true family:"Courier")}

% {Show 1}

% W={ETk.build window(name:top
% 		    action:W#destroyAll
% 		    td(label(name:label text:"Coucou monde" font:MyFont)
% 		       canvas(name:canvas bg:ETk.color.blue)))}
% {Show 2}
% {W.top show}
% {Show 3}
% Img={ETk.newImage image(file:"test.gif" format:"gif")}
% {W.canvas create(image [100 100] image:Img)}
% {Show 4#{Ref2Id {Img getRef($)}}}
% L={ETk.build label(text:"Coucou" font:MyFont name:label)}.label
% {Show 5}
% {W.canvas create(window [200 200] window:L)}
% {Show 6}
% %{W.label set(text:"Hello" font:MyFont)}

% %{W.canvas create(text [10 10] text:"Hello world" anchor:nw font:MyFont)}
% %{W.top display(L)}
% %{Show ici#MyFont}
% %{L set(font:MyFont)}

% %{W.canvas create(bitmap [100 100] bitmap:ETk.bitmap.error)}

% {Show ETk.bitmap.error}

% %{Show h1} {W.top destroy} {Show h2}

% %{W.top set(bg:ETk.color.black)}

% %{W destroyAll}

% {W setContext(default)}

