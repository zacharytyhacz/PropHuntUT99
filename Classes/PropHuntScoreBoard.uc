// show time for both teams 
// show dead or alive through score ( 1 is alive, 0 is dead )
// only teammates can see each other Health 
// maybe hiders can see name of prop teammates using?
// show remainging players on each side ( usable through teaminfo.score, combines all teams scores )
// show deaths and kills 
// show which team are hunters and hiders
class PropHuntScoreBoard extends TeamScoreBoard;

function ShowScores( canvas Canvas )
{
	local PlayerReplicationInfo PRI;
	local int PlayerCount, i;
	local float LoopCountTeam[4];
	local float XL, YL, XOffset, YOffset, XStart;
	local int PlayerCounts[4];
	local int LongLists[4];
	local int BottomSlot[4];
	local font CanvasFont;
	local bool bCompressed;
	local float r;

	OwnerInfo = Pawn(Owner).PlayerReplicationInfo;
	OwnerGame = TournamentGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);	
	Canvas.Style = ERenderStyle.STY_Normal;
	CanvasFont = Canvas.Font;

	// Header
	DrawHeader(Canvas);

	for ( i=0; i<32; i++ )
		Ordered[i] = None;

	for ( i=0; i<32; i++ )
	{
		if (PlayerPawn(Owner).GameReplicationInfo.PRIArray[i] != None)
		{
			PRI = PlayerPawn(Owner).GameReplicationInfo.PRIArray[i];
			if ( !PRI.bIsSpectator || PRI.bWaitingPlayer )
			{
				Ordered[PlayerCount] = PRI;
				PlayerCount++;
				PlayerCounts[PRI.Team]++;
			}
		}
	}

	SortScores(PlayerCount);
	Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
	Canvas.StrLen("TEXT", XL, YL);
	ScoreStart = Canvas.CurY + YL*2;
	if ( ScoreStart + PlayerCount * YL + 2 > Canvas.ClipY )
	{
		bCompressed = true;
		CanvasFont = Canvas.Font;
		Canvas.Font = font'SmallFont';
		r = YL;
		Canvas.StrLen("TEXT", XL, YL);
		r = YL/r;
		Canvas.Font = CanvasFont;
	}
	for ( I=0; I<PlayerCount; I++ )
	{
		if ( Ordered[I].Team < 4 )
		{
			if ( Ordered[I].Team % 2 == 0 )
				XOffset = (Canvas.ClipX / 4) - (Canvas.ClipX / 8);
			else
				XOffset = ((Canvas.ClipX / 4) * 3) - (Canvas.ClipX / 8);

			Canvas.StrLen("TEXT", XL, YL);
			Canvas.DrawColor = AltTeamColor[Ordered[I].Team];
			YOffset = ScoreStart + (LoopCountTeam[Ordered[I].Team] * YL) + 2;
			if (( Ordered[I].Team > 1 ) && ( PlayerCounts[Ordered[I].Team-2] > 0 ))
			{
				BottomSlot[Ordered[I].Team] = 1;
				YOffset = ScoreStart + YL*11 + LoopCountTeam[Ordered[I].Team]*YL;
			}

			// Draw Name and Ping
			if ( (Ordered[I].Team < 2) && (BottomSlot[Ordered[I].Team] == 0) && (PlayerCounts[Ordered[I].Team+2] == 0))
			{
				LongLists[Ordered[I].Team] = 1;
				DrawNameAndPing( Canvas, Ordered[I], XOffset, YOffset, bCompressed);
			} 
			else if (LoopCountTeam[Ordered[I].Team] < 8)
				DrawNameAndPing( Canvas, Ordered[I], XOffset, YOffset, bCompressed);
			if ( bCompressed )
				LoopCountTeam[Ordered[I].Team] += 1;
			else
				LoopCountTeam[Ordered[I].Team] += 2;
		}
	}

	for ( i=0; i<2; i++ )
	{
		Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
		if ( PlayerCounts[i] > 0 )
		{
			if ( i % 2 == 0 )
				XOffset = (Canvas.ClipX / 4) - (Canvas.ClipX / 8);
			else
				XOffset = ((Canvas.ClipX / 4) * 3) - (Canvas.ClipX / 8);
			YOffset = ScoreStart - YL + 2;

			if ( i > 1 )
				if (PlayerCounts[i-2] > 0)
					YOffset = ScoreStart + YL*10;

			Canvas.DrawColor = TeamColor[i];
			Canvas.SetPos(XOffset, YOffset);
			if(i == PropHuntGRI(OwnerGame).CurrentHunterTeam)
			{
				Canvas.StrLen("Hunters", XL, YL);
				Canvas.DrawText("Hunters", false);
			}
			else {
				Canvas.StrLen("Hiders", XL, YL);
				Canvas.DrawText("Hiders", false);
			}	
			Canvas.StrLen(int(OwnerGame.Teams[i].Score), XL, YL);
			Canvas.SetPos(XOffset + (Canvas.ClipX/4) - XL - 25, YOffset);
			if(int(OwnerGame.Teams[i].Score) == 1)
				Canvas.DrawText(PropHuntGRI(OwnerGame).TeamWins[i], false);
			else
				Canvas.DrawText(PropHuntGRI(OwnerGame).TeamWins[i], false);
			if ( PlayerCounts[i] > 4 )
			{
				if ( i < 2 )
					YOffset = ScoreStart + YL*8;
				else
					YOffset = ScoreStart + YL*19;
				Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
				Canvas.SetPos(XOffset, YOffset);
				if (LongLists[i] == 0)
					Canvas.DrawText(PlayerCounts[i] - 4 @ PlayersNotShown, false);
			}
		}
	}

	// Trailer
	if ( !Level.bLowRes )
	{
		Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
		DrawTrailer(Canvas);
	}
	Canvas.Font = CanvasFont;
	Canvas.DrawColor = WhiteColor;
}

function string TwoDigitString(int Num)
{
    if ( Num < 10 )
        return "0"$Num;
    else
        return string(Num);
}

function DrawNameAndPing(Canvas Canvas, PlayerReplicationInfo PRI, float XOffset, float YOffset, bool bCompressed)
{
	local float XL, YL, XL2, YL2, YB;
	local BotReplicationInfo BRI;
	local String S, O, L;
	local Font CanvasFont;
	local bool bAdminPlayer;
	local PlayerPawn PlayerOwner;
	local int Time;
	local PropHuntPRI ph_pri;

	PlayerOwner = PlayerPawn(Owner);

	bAdminPlayer = PRI.bAdmin;

	// Draw Name
	if (PRI.PlayerName == PlayerOwner.PlayerReplicationInfo.PlayerName)
		Canvas.DrawColor = GoldColor;

	if ( bAdminPlayer )
		Canvas.DrawColor = WhiteColor;

	Canvas.SetPos(XOffset, YOffset);
	Canvas.DrawText(PRI.PlayerName, False);
	Canvas.StrLen(PRI.PlayerName, XL, YB);

	if ( Canvas.ClipX > 512 ){
		CanvasFont = Canvas.Font;
		Canvas.Font = Font'SmallFont';
		Canvas.DrawColor = WhiteColor;
		if (Level.NetMode != NM_Standalone){
			if ( !bCompressed || (Canvas.ClipX > 640) ){
				// Draw Time
				Time = Max(1, (Level.TimeSeconds + PlayerOwner.PlayerReplicationInfo.StartTime - PRI.StartTime)/60);
				Canvas.StrLen(TimeString$":     ", XL, YL);
				Canvas.SetPos(XOffset - XL - 6, YOffset);
				Canvas.DrawText(TimeString$":"@Time, false);
			}
			// Draw Ping
			Canvas.StrLen(PingString$":     ", XL2, YL2);
			Canvas.SetPos(XOffset - XL2 - 6, YOffset + (YL+1));
			Canvas.DrawText(PingString$":"@PRI.Ping, false);
		}
		Canvas.Font = CanvasFont;
	}

	// Draw Score
	if (PRI.PlayerName == PlayerOwner.PlayerReplicationInfo.PlayerName)
		Canvas.DrawColor = GoldColor;
	else
		Canvas.DrawColor = TeamColor[PRI.Team];
	DrawScore(Canvas, PRI.Score, XOffset, YOffset);
	if(PlayerPawn(PRI.Owner) != None){
		
		ph_pri = PropHunt(Level.Game).GetStats( PlayerPawn(PRI.Owner) );
		log(pri.PlayerName@" has "@ph_pri);
		if( ph_pri != None ){
			CanvasFont = Canvas.Font;
			Canvas.Font = Font'SmallFont';
			Canvas.SetPos(XOffset+10, YOffset + YB);
			Canvas.DrawText("HF:" @ ph_pri.HidersFound, False);
			Canvas.SetPos(XOffset+20, YOffset + YB);
			Canvas.DrawText("D:" @ PRI.Deaths, False);
			Canvas.SetPos(XOffset+30, YOffset + YB);
			Canvas.DrawText("HID:" @ ph_pri.HideSec, False);
		}
	}
	if ( !bCompressed && (PRI.Team == OwnerInfo.Team) && PRI.Score > 0){ // only display health for teammates if they are alive.
		L = "Health:"@Pawn(PRI.Owner).Health;
        CanvasFont = Canvas.Font;
        Canvas.Font = Font'SmallFont';
		Canvas.SetPos(XOffset, YOffset + YB);
		Canvas.DrawText(L, False);
		Canvas.Font = CanvasFont;
    }
	
	Canvas.Font = CanvasFont;
	if (Canvas.ClipX < 512)
		return;
}

function DrawVictoryConditions(Canvas Canvas)
{
	local PropHuntGRI TGRI;
	local float XL, YL;

	TGRI = PropHuntGRI(PlayerPawn(Owner).GameReplicationInfo);
	if ( TGRI == None )
		return;
	Canvas.DrawText(TGRI.GameName);
	Canvas.StrLen("Test", XL, YL);
	Canvas.SetPos(0, Canvas.CurY - YL);
	Canvas.Font = MyFonts.GetMediumFont( Canvas.ClipX );
	Canvas.DrawText("First Team To"@TGRI.RoundsToWin@"wins the game!");
	
	Canvas.bCenter=false;
	Canvas.StrLen("Round Time:"@TGRI.RoundTime$":00", XL, YL);
	Canvas.SetPos(240, 200);
	Canvas.DrawText("Round Time:"@TwoDigitString(TGRI.RoundTime)$":00");
	
	Canvas.SetPos( (Canvas.ClipX/2-( (Canvas.ClipX-200)/4 ) ) + 140 , 200);	
	Canvas.DrawText("Hide Time:"@"00:"$TwoDigitString(TGRI.HideTime));
	Canvas.StrLen("Hide Time:"@"00:"$TGRI.HideTime, XL, YL);
	
	Canvas.SetPos(Canvas.ClipX/2 + 140 , 200);
	Canvas.DrawText("Hunter Health:"@TGRI.HunterHealth);
	Canvas.StrLen("Hunter Health:"@TGRI.HunterHealth, XL, YL);
	
	Canvas.SetPos((Canvas.ClipX/2+( (Canvas.ClipX-200)/4 ) )+ 140 , 200);
	Canvas.DrawText("Hider Health:"@TGRI.HiderHealth);
}

function DrawScore(Canvas Canvas, float Score, float XOffset, float YOffset)
{
	local float XL, YL;

	Canvas.StrLen(string(int(Score)), XL, YL);
	Canvas.SetPos(XOffset + (Canvas.ClipX/4) - XL, YOffset);
	if(int(Score) == 1)
		Canvas.DrawText("Alive", False);
	else
		Canvas.DrawText("Dead", False);
}

defaultproperties
{

}