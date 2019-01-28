class PropHuntRCWindow extends UMenuPageWindow;
/*/
i need ...

round time // in minutes, int 
hide time // in seconds, int 
hunter health // int 
hider health // int 
rounds to win // int 

*/
var UMenuBotmatchClientWindow BotmatchParent;

var bool Initialized;

// round time
var UWindowEditControl RTEdit;
var localized string RTText;
var localized string RTHelp;

// rounds to win
var UWindowEditControl RoundsEdit;
var localized string RoundsText;
var localized string RoundsHelp;

// hide time 
var UWindowEditControl HTEdit;
var localized string HTText;
var localized string HTHelp;

// hunter health 
var UWindowEditControl HunterHEdit;
var localized string HunterHText;
var localized string HunterHHelp;

// hider health 
var UWindowEditControl HiderHEdit;
var localized string HiderHText;
var localized string HiderHHelp;

var float ControlOffset;
var bool bControlRight;

function Created()
{
	local int S;
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, ButtonWidth, ButtonLeft;

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	ButtonWidth = WinWidth - 140;
	ButtonLeft = WinWidth - ButtonWidth - 40;

	BotmatchParent = UMenuBotmatchClientWindow(GetParent(class'UMenuBotmatchClientWindow'));
	if (BotmatchParent == None)
		Log("Error: UMenuStartMatchClientWindow without UMenuBotmatchClientWindow parent.");

	// round time 
	RTEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	RTEdit.SetText(RTText);
	RTEdit.SetHelpText(RTHelp);
	RTEdit.SetFont(F_Normal);
	RTEdit.SetNumericOnly(True);
	RTEdit.SetMaxLength(3);
	RTEdit.Align = TA_Right;

	// rounds to win 
	RoundsEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
	RoundsEdit.SetText(RoundsText);
	RoundsEdit.SetHelpText(RoundsHelp);
	RoundsEdit.SetFont(F_Normal);
	RoundsEdit.SetNumericOnly(True);
	RoundsEdit.SetMaxLength(3);
	RoundsEdit.Align = TA_Right;
	ControlOffset += 25;

	// hide time 
	HTEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
	HTEdit.SetText(HTText);
	HTEdit.SetHelpText(HTHelp);
	HTEdit.SetFont(F_Normal);
	HTEdit.SetNumericOnly(True);
	HTEdit.SetMaxLength(3);
	HTEdit.Align = TA_Right;
	ControlOffset += 25;
	
	// hunter health 
	HunterHEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
	HunterHEdit.SetText(HunterHText);
	HunterHEdit.SetHelpText(HunterHHelp);
	HunterHEdit.SetFont(F_Normal);
	HunterHEdit.SetNumericOnly(True);
	HunterHEdit.SetMaxLength(3);
	HunterHEdit.Align = TA_Right;
	ControlOffset += 25;

	// hider health
	HiderHEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
	HiderHEdit.SetText(HiderHText);
	HiderHEdit.SetHelpText(HiderHHelp);
	HiderHEdit.SetFont(F_Normal);
	HiderHEdit.SetNumericOnly(True);
	HiderHEdit.SetMaxLength(3);
	HiderHEdit.Align = TA_Right;
	ControlOffset += 25;
}

function AfterCreate()
{
	Super.AfterCreate();

	DesiredWidth = 270;
	DesiredHeight = ControlOffset;

	LoadCurrentValues();
	Initialized = True;
}

function LoadCurrentValues()
{
	RTEdit.SetValue(string(Class<PropHunt>(BotmatchParent.GameClass).Default.RoundTime));

	RoundsEdit.SetValue(string(Class<PropHunt>(BotmatchParent.GameClass).Default.RoundsToWin));
	
	HTEdit.SetValue(string(Class<PropHunt>(BotmatchParent.GameClass).Default.HideTime));

	HunterHEdit.SetValue(string(Class<PropHunt>(BotmatchParent.GameClass).Default.HunterHealth));
	
	HiderHEdit.SetValue(string(Class<PropHunt>(BotmatchParent.GameClass).Default.HiderHealth));
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, ButtonWidth, ButtonLeft;

	Super.BeforePaint(C, X, Y);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	RTEdit.SetSize(ControlWidth, 1);
	RTEdit.WinLeft = ControlRight;
	RTEdit.EditBoxWidth = 25;
	
	RoundsEdit.SetSize(ControlWidth, 1);
	RoundsEdit.WinLeft = ControlLeft;
	RoundsEdit.EditBoxWidth = 25;

	HTEdit.SetSize(ControlWidth, 1);
	HTEdit.WinLeft = ControlRight;
	HTEdit.EditBoxWidth = 25;
	
	HunterHEdit.SetSize(ControlWidth, 1);
	HunterHEdit.WinLeft = ControlLeft;
	HunterHEdit.EditBoxWidth = 25;

	HiderHEdit.SetSize(ControlWidth, 1);
	HiderHEdit.WinLeft = ControlRight;
	HiderHEdit.EditBoxWidth = 25;
}

function Notify(UWindowDialogControl C, byte E)
{
	if (!Initialized)
		return;

	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch(C)
		{
			case RTEdit:
				RoundTimeChanged();
				break;
			case RoundsEdit:
				RoundsChanged();
				break;
			case HTEdit:
				HideTimeChanged();
				break;
			case HunterHEdit:
				HunterHealthChanged();
				break;
			case HiderHEdit:
				HiderHealthChanged();
				break;
		}
	}
}

function RoundTimeChanged(){
	Class<PropHunt>(BotmatchParent.GameClass).Default.RoundTime = int(RTEdit.GetValue());
}

function RoundsChanged(){
	Class<PropHunt>(BotmatchParent.GameClass).Default.RoundsToWin = int(RoundsEdit.GetValue());
}

function HideTimeChanged(){
	Class<PropHunt>(BotmatchParent.GameClass).Default.HideTime = int(HTEdit.GetValue());
}

function HunterHealthChanged(){
	Class<PropHunt>(BotmatchParent.GameClass).Default.HunterHealth = int(HunterHEdit.GetValue());
}

function HiderHealthChanged(){
	Class<PropHunt>(BotmatchParent.GameClass).Default.HiderHealth = int(HiderHEdit.GetValue());
}

defaultproperties
{
    RTText="Round Time Limit"
    RTHelp="In minutes, this is how long a round is."
    RoundsText="Rounds To Win"
    RoundsHelp="The game ends when a team wins this many rounds."
    HTText="Hide Time"
    HTHelp="In seconds, this is how long the hiders get to freely hide at the beginning. "
    HunterHText="Hunter Health"
    HunterHHelp="The default health for hunters, should be higher than hiders."
    HiderHText="Hider Health"
    HiderHHelp="The default health for hiders."
    ControlOffset=20.00
}
