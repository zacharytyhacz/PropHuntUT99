class PropHunt_Prop extends Actor;

defaultproperties
{
	bCollideWorld=false
	bCollideActors=false
	bBlockActors=false
	bOnlyOwnerSee=false //this is true because start of game. only the individual player's prop is visible to them.
	bOwnerNoSee=false  // this reassures that there is no swip swapping of the behindview altfire.
	bBlockPlayers=false
	bStatic=false
	bStasis=false
	DrawType=DT_Mesh
	DrawScale=1.0
	Mesh=LodMesh'UnrealShare.vaseM'
	Skin=Texture'UnrealShare.Skins.Jvase1'
	Texture=None
	CollisionHeight=28.0000000
	CollisionRadius=22.0000000
	Role=ROLE_Authority
	//RemoteRole=ROLE_SimulatedProxy
	bShadowCast=true
	NetPriority=3.0
	bNetInitial=true
	bNetRelevant=true
	bAlwaysRelevant=false
	bOwnerNoSee=true
}