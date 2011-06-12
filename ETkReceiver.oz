\define OPI
declare
\insert 'ETkMisc.oz'
\insert 'EBL.oz'
\insert 'ParametersGatherer.oz'
\insert 'ETk.oz'

%declare 
%QTk={Module.link ["ETk.ozf"]}.1.etk

W={QTk.build window(name:top)}
{W.top bind(event:lostWidget
	    args:[ref placementInstructions]
	    action:proc{$ R P}
		      {Show lost#R#P}
		   end)}
R={Pickle.load "ticket"}
{W.top display(R)}
{W.top show}
