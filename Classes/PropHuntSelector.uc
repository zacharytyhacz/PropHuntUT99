class PropHuntSelector extends TournamentWeapon;
// allows players to shoot at a model and have that model be their new prop model.


var Actor Prop;
var vector 	   NewLocation;
var vector 	   prop_offset;
var bool 	   bPropSet;


function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	if(Decoration(Other) != None && Carcass(Other) == None)
	{
		//LOG(OTHER);
		SetMyProp(Decoration(Other));
	}
}
// ServerActors=IpServer.UdpServerUplink MasterServerAddress=master0.gamespy.com MasterServerPort=27900
function SetMyProp(Actor Other)
{
	// set the mesh, set the drawscale and skin on our prop to match the prop we picked so theyre the same. trhethadfefaefergergaerg aer g
	Prop.Mesh = Other.Mesh;
	Prop.DrawScale = Other.DrawScale;
	Prop.Skin = Other.Skin;
	Owner.SetCollisionSize(Other.CollisionRadius, Other.CollisionHeight); // setting player's collision to the selected prop 
	
	prop_offset.Z = 4;	
	bPropSet = true;
}

event Timer()
{
	if(Pawn(Owner).Velocity != vect(0,0,0) && Pawn(Owner).Health > 15){
		Pawn(Owner).Health -= 3;
	} else if(Pawn(Owner).Velocity == vect(0,0,0) && Pawn(Owner).Health < 49){
		Pawn(Owner).Health += 1;
	}
	if(Pawn(Owner).Health < 1 || Owner == None){
		SetTimer(0.0,false);
		Prop.Destroy();
		Prop = None;
	}
}

function Tick(float DeltaTime)
{
	if(Prop != None && Pawn(Owner) != None && Pawn(Owner).Health > 0){ // adding as many checks to reduce lag
		NewLocation = Owner.Location - prop_offset;
		Prop.SetLocation(NewLocation);		
	}else if(Prop != None){
		Prop.Destroy();
		Prop = None;
	}
}

simulated function setHand(float Hand)
{	
	Super.setHand(Hand);
	
	if(!bPropSet){
		Prop = Spawn(class'PropHunt_Prop',Owner,,Owner.Location);		
		//Prop.bOwnerNoSee = true;
		SetMyProp(Prop);
	}
	SetTimer(3.0,true);
}

simulated function bool ClientAltFire( float Value )//16384
{
	if(PlayerPawn(Owner) != None && bPropSet){
		PlayerPawn(Owner).bBehindView = !(PlayerPawn(Owner).bBehindView);
		if(PlayerPawn(Owner).bBehindView) {
			Prop.bOwnerNoSee = false;
			Prop.bOnlyOwnerSee = false; // everyoen sees this 
		}
		else {
			Prop.bOwnerNoSee = true;
		}
			
	} 
    return true;
}

function AltFire( float Value )
{
    ClientAltFire(Value);
}

function TraceFire( float Accuracy )
{
    local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
    local actor Other;
    local Pawn PawnOwner;

    PawnOwner = Pawn(Owner);

    GetAxes(PawnOwner.ViewRotation,X,Y,Z);
    StartTrace = Owner.Location + PawnOwner.Eyeheight * Z; 
    AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2*AimError, False, False);   
    X = vector(AdjustedAim);
    EndTrace = StartTrace + 10000 * X; 
    Other = PawnOwner.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
    ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
}

state Idle
{
    function Fire( float Value )
    {
		TraceFire(0.0);
    }
    function BeginState()
    {
        Super.BeginState();
    }
    function EndState()
    {   
        Super.EndState();
    }
    
Begin:
}

function Destroyed()
{
	if(Prop != None){
		Prop.Destroy();
		Prop = None;
	}
	Super.Destroyed();
}

defaultproperties
{
	bPropSet=false
	bDrawMuzzleFlash=false
	//ThirdPersonMesh=Mesh'UnrealI.DiceM'
	PlayerViewMesh=Mesh'BotPack.Rifle2m'
    PickupViewMesh=Mesh'BotPack.RiflePick'
	PlayerViewScale=0.0
	RefireRate=1.0
	bCanThrow=false
	bInstantHit=true
	bHidden=true
    Mesh=Mesh'UnrealI.DiceM'
	FireSound=none
	AutoSwitchPriority=5
	InventoryGroup=10
	ShakeMag=0.0
	ShakeTime=0.0
	ShakeVert=0.0
}