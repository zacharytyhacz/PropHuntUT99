class PropHunt_SpawnNotify extends SpawnNotify;


simulated event Actor SpawnNotification(Actor A)
{
	if( A.Owner == None ) return A;
	if( !A.Owner.IsA( 'PlayerPawn' ) && !A.Owner.IsA( 'Bot' ) ) return A;
	if( !Pawn( A.Owner ).bIsPlayer ) return A;
	
	Spawn(class'PropHuntPRI', A);
	return A;
}

defaultproperties
{
}