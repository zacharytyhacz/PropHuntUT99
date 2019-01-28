// show time for both teams 
// show dead or alive through score ( 1 is alive, 0 is dead )
// only teammates can see each other Health 
// maybe hiders can see name of prop teammates using?
// show remainging players on each side ( usable through teaminfo.score, combines all teams scores )
// show deaths and kills 
// show which team are hunters and hiders
class PropHuntHUD extends ChallengeTeamHUD;


simulated function PostRender(canvas Canvas)
{
	local int Minutes;
	local int Seconds;

	Super.PostRender(Canvas);
	Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
	Canvas.bCenter = true;
	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = WhiteColor;
	//Canvas.SetPos(4, 50 * Scale);
	Canvas.SetPos(Canvas.ClipX - 105 * Scale, 150 * Scale);
	Minutes = PropHuntGRI(PlayerOwner.GameReplicationInfo).RemainingRoundTime/60;
	Seconds = PropHuntGRI(PlayerOwner.GameReplicationInfo).RemainingRoundTime % 60;
	Canvas.DrawText(TwoDigitString(Minutes)$":"$TwoDigitString(Seconds), true);
	Canvas.bCenter = false;
	Canvas.DrawColor = WhiteColor;
	Canvas.SetPos(Canvas.ClipX - 120 * Scale, 180 * Scale);
	Canvas.DrawText("Round "@(PropHuntGRI(PlayerOwner.GameReplicationInfo).CurrentRound), true);
}

function string TwoDigitString(int Num)
{
    if ( Num < 10 )
        return "0"$Num;
    else
        return string(Num);
}

simulated function bool DrawIdentifyInfo(canvas Canvas)
{
	local float XL, YL, XOffset, X1;
	local Pawn P;
	
	if ( !TraceIdentify(Canvas))
        return false;
		
	Canvas.StrLen("TEST", XL, YL);
	if( PawnOwner.PlayerReplicationInfo.Team == IdentifyTarget.Team && IdentifyTarget.PlayerName != "")
	{
		P = Pawn(IdentifyTarget.Owner);
		Canvas.Font = MyFonts.GetSmallFont(Canvas.ClipX);
		if ( P != None )
			DrawTwoColorID(Canvas,IdentifyHealth,string(P.Health), (Canvas.ClipY - 256 * Scale) + 1.5 * YL);
		
	}
	else{ return false;}
	
	return true;
}

simulated function DrawTeam(Canvas Canvas, TeamInfo TI)
{
    local float XL, YL;

    if ( (TI != None) && (TI.Size > 0) )
    {
        Canvas.Font = MyFonts.GetHugeFont( Canvas.ClipX );
        Canvas.DrawColor = TeamColor[TI.TeamIndex];
        Canvas.SetPos(Canvas.ClipX - 64 * Scale, Canvas.ClipY - (336 + 128 * TI.TeamIndex) * Scale);
        Canvas.DrawIcon(TeamIcon[TI.TeamIndex], Scale);
        Canvas.StrLen(int(TI.Score), XL, YL);
        Canvas.SetPos(Canvas.ClipX - XL - 66 * Scale, Canvas.ClipY - (336 + 128 * TI.TeamIndex) * Scale + ((64 * Scale) - YL)/2 );
        Canvas.DrawText(PropHuntGRI(PlayerOwner.GameReplicationInfo).TeamWins[TI.TeamIndex], false);
    }
}
defaultproperties{
	
}