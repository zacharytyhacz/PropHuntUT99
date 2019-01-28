class PropHuntKilledMessage expands CriticalEventPlus;

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
	if(RelatedPRI_2 != RelatedPRI_1)
		return RelatedPRI_2.PlayerName@"was found by"@RelatedPRI_1.PlayerName;
	else 
		return RelatedPRI_2.PlayerName@"was too trigger happy!!";
    return "";
}

defaultproperties
{
    bBeep=False
    DrawColor=(R=255,G=0,B=0)
}