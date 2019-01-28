class PropHuntWeapon extends Minigun2;

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	Super.ProcessTraceHit(Other,HitLocation,HitNormal,X,Y,Z);
	if(Pawn(Other) == None){
		Pawn(Owner).TakeDamage(8,Pawn(Owner),Pawn(Owner).Location,vect(0,0,0),MyDamageType);
	}
}

function BecomePickup()
{
	//self.Destroy();
}

defaultproperties
{
	
}