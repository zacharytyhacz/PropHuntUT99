class PropHuntStartMessage extends CriticalEventLowPlus;

static function float GetOffset(int Switch, float YL, float ClipY )
{
    return (Default.YPos/768.0) * ClipY + 2*YL;
}


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if (RelatedPRI_1 == None)
        return "";
    if (RelatedPRI_1.PlayerName == "")
        return "";
	if(PropHunt(OptionalObject) != None)
	{
		if(RelatedPRI_1.Team == PropHunt(OptionalObject).CurrentHiderTeam)
			return PropHunt(OptionalObject).StartupTeamMessage@"HIDER"$PropHunt(OptionalObject).StartupTeamTralier;
		else 
			return PropHunt(OptionalObject).StartupTeamMessage@"HUNTER"$PropHunt(OptionalObject).StartupTeamTralier;
	}
	
    return "";
}

defaultproperties
{
    bBeep=False
	bIsConsoleMessage=true
    DrawColor=(R=255,G=255,B=255)
}