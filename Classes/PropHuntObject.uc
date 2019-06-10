class PropHuntObject extends TournamentWeapon;
// TournamentPlayer(UT) height = 78uu
var Decoration Prop;
var class<Decoration> PropClass;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	//Prop = None;
}

function Timer()
{
	if(Owner.Velocity != vect(0,0,0) && Pawn(Owner).Health > 10) // to even the playing field, hiders take a small damage amount every so often
	{
		Pawn(Owner).Health -= 1;
	}
	if(Prop.Location != Owner.Location && Prop != None)
	{
		//Prop.SetRotation(rotator(0,0,Owner.Rotation.Yaw));
		//Prop.SetLocation(Owner.Location);
	}
	if(Pawn(Owner).Health < 1)
	{
		SetTimer(0.0,false);
		Prop.Destroy();
		Prop = None;
	}
	// debug 
	Log("))))))))))))))))))))))))))))))))))))))))))))))))))))))))"@Owner@Prop);
}

// i know, tick is not good to use but PHYS_Trailer is buggy
function Tick(float DeltaTime)
{
	if(Prop != None && Pawn(Owner) != None && Pawn(Owner).Health > 0) // adding as many checks to reduce lag
	{
		if(Owner.Location != Prop.Location)
		{
			Prop.SetLocation(Owner.Location);
			//Prop.Rotation.Yaw = Owner.Rotation.Yaw;
		}	
	}
	else
	{
		Prop = None;
		Prop.Destroy();
	}
}

function SetProp(class<Decoration> decor)
{
	PropClass = decor;
}

function setHand(float Hand)
{
	Super.setHand(Hand);
	SetTimer(4.5,true);
	if(Prop == None)
	{
		Prop = Spawn(class'PropHuntToolBox',Owner,,Owner.Location);
		Prop.SetCollision(true,true,false);
		/*Prop.bFixedRotationDir = true;
		Prop.SetPhysics(PHYS_Trailer);
		Prop.bTrailerSameRotation = false;
		Prop.bTrailerPrePivot = true;
		Prop.PrePivot = vect(0,0,64);*/
		//Prop.bStatic = false;
	}
	
	
}

defaultproperties
{
	PickupAmmoCount=999
	Icon=Texture'Icons.UseMini'
}
