class PropHuntSettingsCWindow extends UMenuGameSettingsBase;

// AirControl
var UWindowHSliderControl AirControlSlider;
var localized string AirControlText;
var localized string AirControlHelp;

function Created()
{
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

	// Air Control
	AirControlSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', CenterPos, ControlOffset, CenterWidth, 1));
	AirControlSlider.SetRange(5, 100, 5);
	AirControlSlider.SetHelpText(AirControlHelp);
	AirControlSlider.SetFont(F_Normal);
	ControlOffset += 25;
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

	AirControlSlider.SetSize(CenterWidth, 1);
	AirControlSlider.SliderWidth = 90;
	AirControlSlider.WinLeft = CenterPos;
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
		case AirControlSlider:
			AirControlChanged();
			break;
		}
	}
}

function AirControlChanged()
{
	Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.AirControl = AirControlSlider.GetValue() / 100;
	AirControlSlider.SetText(AirControlText$" ["$Int(AirControlSlider.GetValue())$"%]:");
}

// Replaces UMenuGameSettingsCWindow's version
function LoadCurrentValues()
{
	local int S;
	local int AC;

	AC = Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.AirControl * 100.0;
	AirControlSlider.SetValue(AC);
	AirControlSlider.SetText(AirControlText$" ["$AC$"%]:");

	if ( Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bMegaSpeed )
		StyleCombo.SetSelectedIndex(2);
	else if ( Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bHardcoreMode )
		StyleCombo.SetSelectedIndex(1);
	else
		StyleCombo.SetSelectedIndex(0);

	S = Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.GameSpeed * 100.0;
	SpeedSlider.SetValue(S);
	SpeedSlider.SetText(SpeedText$" ["$S$"%]:");
}

// Replaces UMenuGameSettingsCWindow's version
function StyleChanged()
{
	switch (StyleCombo.GetSelectedIndex())
	{
		case 0:
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bMegaSpeed = false;
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bHardCoreMode = false;
			AirControlSlider.SetValue(35);
			break;
		case 1:
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bMegaSpeed = false;
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bHardCoreMode = true;
			AirControlSlider.SetValue(35);
			break;
		case 2:
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bMegaSpeed = true;
			Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.bHardCoreMode = true;
			AirControlSlider.SetValue(65);
			break;
	}
}

// Replaces UMenuGameSettingsCWindow's version
function SpeedChanged()
{
	local int S;

	S = SpeedSlider.GetValue();
	SpeedSlider.SetText(SpeedText$" ["$S$"%]:");
	Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.GameSpeed = float(S) / 100.0;
}

defaultproperties
{
    AirControlText="Air Control"
    AirControlHelp="Use this slider to specify how much control you have over your player's movement whilst in the air."
}
