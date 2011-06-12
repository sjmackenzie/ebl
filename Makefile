foo:ETk.ozf Calendar.exe UniversalReceiver.exe Discoverer.exe

Com.ozf:Com.oz
	ozc -c Com.oz

SocketConnection.ozf:SocketConnection.oz
	ozc -c SocketConnection.oz

EBL.ozf:EBL.oz
	ozc -c EBL.oz

ETkMisc.ozf:ETkMisc.oz
	ozc -c ETkMisc.oz

ParametersGatherer.ozf:ParametersGatherer.oz
	ozc -c ParametersGatherer.oz

ETkAlone.ozf:ETk.oz ETkButton.oz ETkCanvas.oz ETkCheckbutton.oz ETkDialogbox.oz ETkEntry.oz ETkImage.oz ETkLabel.oz ETkLabelframe.oz ETkListbox.oz ETkMenubutton.oz ETkMessage.oz ETkPanedwindow.oz ETkRadiobutton.oz ETkScale.oz ETkScrollbar.oz ETkSpinbox.oz ETkTable.oz ETkText.oz ETkWindow.oz ETkFont.oz ETkImage.oz ETkText.oz ETkNavigator.oz ETkSelector.oz ETkFlexClock.oz
	ozc -c ETk.oz -o ETkAlone.ozf

ETk.ozf:Com.ozf SocketConnection.ozf EBL.ozf ETkMisc.ozf ETkAlone.ozf ParametersGatherer.ozf
	ozl -o ETk.ozf -z 9 ETkAlone.ozf

Calendar.exe:ETk.ozf EBL.ozf Calendar.ozf
	ozl -x -o Calendar.exe -z 9 Calendar.ozf

Calendar.ozf:Calendar.oz
	ozc -c Calendar.oz

UniversalReceiver.exe:ETk.ozf EBL.ozf UniversalReceiver.ozf
	ozl -x -o UniversalReceiver.exe -z 9 UniversalReceiver.ozf

UniversalReceiver.ozf:UniversalReceiver.oz
	ozc -c UniversalReceiver.oz

Discoverer.exe:ETk.ozf EBL.ozf Discoverer.ozf
	ozl -x -o Discoverer.exe -z 9 Discoverer.ozf

Discoverer.ozf:Discoverer.oz
	ozc -c Discoverer.oz
