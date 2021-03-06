-- "PREVIEW" news are blocked from C++ code in SendNews(), even if their logic is still kept in Lua code. So, they no longer get sent.

function SeasonPreviewJobChanged()
	local storyId1 = "PREVIEW"
	local storyId2 = "PREVIEWSTART"
	if( Engine.IsStoryIDActive( storyId1 ) ) then
		Engine.EndStoryId( storyId1 )
	end
	if( Engine.IsStoryIDActive( storyId2 ) ) then
		Engine.EndStoryId( storyId2 )
	end
	Engine.ForceLeagueTeamNameCacheRefresh()
end

function SeasonPreviewPostLoad()
	local storyId = "PREVIEW"
	local storyActive = Engine.IsStoryIDActive( storyId )
	if( storyActive == true ) then	
		local userTeam = Engine.GetUserTeam()
		local numTeams = Engine.GetNumberOfTeamsInLeague()	-- Quick hack
		Engine.SortLeagueTableByAlphabet()
	end
end

function Start_SeasonPreview()
	local userTeam = Engine.GetUserTeam()
	local currDate = Engine.GetCurrentDate()
	local fixtureDate = Engine.GetDateOfNextFixtureOfType( userTeam, "LEAGUE" )
	Engine.MarkDate( fixtureDate )	
		
	local numTeams = Engine.GetNumberOfTeamsInLeague()	-- Quick hack
	Engine.SortLeagueTableByAlphabet()
	local currDate = Engine.GetCurrentDate()
	local markDate = Engine.GetMarkedDate()	
	local daysBetween = Engine.GetNumDaysBetween( currDate, markDate )
	local startPreviewInDays = daysBetween - numTeams
	local storyId = "PREVIEW"
	
	Engine.AddDaysToDate( currDate, startPreviewInDays )
	Engine.AddDateEvent( "SSNPRV", startPreviewInDays, storyId )	
	local category = "SEASPREV"	
	local storyActive = Engine.IsStoryIDActive( storyId )
	if( storyActive == false ) then
		Engine.MarkPlayerForStory( Engine.GetUserTeam(), 0, category, storyId )
	end
end

function SeasonPreviewDynamicEvent( eventId )
	if( eventId == "SSNPRVDAY1" ) then
		Start_SeasonPreview()
	elseif( eventId == "SSNPRV" ) then
		local storyId = "PREVIEWSTART"
		local category = "SEASPREV"
		local storyActive = Engine.IsStoryIDActive( storyId )		
		if( storyActive == false ) then
			Engine.MarkPlayerForStory( Engine.GetUserTeam(), 0, category, storyId )
		end
		
		local currDate = Engine.GetCurrentDate()		
		local currentStory = Engine.GetStoryByIdAndIndex( storyId, 1 )
		local storyDate = Engine.GetStoryStartDate( currentStory )
		local daysBetween = Engine.GetNumDaysBetween( currDate, storyDate ) + 1
		local team = Engine.GetSortedTeamByIndex( daysBetween )
		DoSeasonPreview( team )
	end --if( eventId == "SSNPRV" ) then
end

function DoSeasonPreview( teamId )
	teamId = Engine.StackRankTeamByOverall( teamId )	
	local playerAttribsAttack = {}
	local playerAttribsCreative = {}
	local playerAttribsDefensive = {}
	local youngPlayers = {}
	
	GeneratePlayerLists( teamId, playerAttribsAttack, playerAttribsCreative, playerAttribsDefensive, youngPlayers )
	
	table.sort( playerAttribsAttack, SortPlayerAttribTable )
	local attackPlayer = GetRatedPlayerId( teamId, playerAttribsAttack, 0 )
	
	if( attackPlayer > 0 ) then
		ClearRatedPlayer( teamId, attackPlayer, playerAttribsCreative )
		table.sort( playerAttribsCreative, SortPlayerAttribTable )
		local creativePlayer = GetRatedPlayerId( teamId, playerAttribsCreative, 0 )	
		
		if( creativePlayer > 0 ) then
			ClearRatedPlayer( teamId, attackPlayer, playerAttribsDefensive  )
			ClearRatedPlayer( teamId, creativePlayer, playerAttribsDefensive )
			table.sort( playerAttribsDefensive, SortPlayerAttribTable )
			local defensivePlayer = GetRatedPlayerId( teamId, playerAttribsDefensive, 0 )
			
			if( defensivePlayer > 0 ) then
				ClearYoungPlayer( teamId, attackPlayer, youngPlayers )
				ClearYoungPlayer( teamId, creativePlayer, youngPlayers  )
				ClearYoungPlayer( teamId, defensivePlayer, youngPlayers )
				table.sort( youngPlayers, SortPlayerOverall )
				local youngPlayer = GetRatedPlayerId( teamId, youngPlayers, 2 )

				local keyOverall = Engine.GetPlayerOverall( attackPlayer )
				keyPlayer = attackPlayer
				if( Engine.GetPlayerOverall( creativePlayer ) > keyOverall ) then
						keyPlayer = creativePlayer
				end
				if( Engine.GetPlayerOverall( defensivePlayer ) > keyOverall ) then
					keyPlayer = defensivePlayer
				end
				
				for stringCount = 1, 5 do
					Engine.SetStringPlayer( -1, stringCount )
				end
				if( attackPlayer > 0 ) then
					Engine.SetStringPlayer( attackPlayer, 1 )
				end
				if( creativePlayer > 0 ) then
					Engine.SetStringPlayer( creativePlayer, 2 )
				end
				if( defensivePlayer > 0 ) then
					Engine.SetStringPlayer( defensivePlayer, 3 )
				end
				if( keyPlayer > 0 ) then
					Engine.SetStringPlayer( keyPlayer, 5 )
				end
				
				local locMeStr = ""
				local locString = "news_body_seasonpreview_young_"
				local randNo = Engine.GetRandomNumber( 1, 20 )
				if( youngPlayer > 0 ) then
					locMeStr = "locme_"..locString..randNo
					Engine.SetStringPlayer( youngPlayer, 4 )				
				end
				
				Engine.SetStringTeam( teamId )
				local leagueObj = Engine.GetCurrentTeamLeagueObjective( teamId )
				local prediction = Engine.GetTeamSeasonPrediction( teamId )
				if( leagueObj == "CHAMPION" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_champion_", 1, 10, "news_body_seasonpreview_champion_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "CHAMPIONS_CUP" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_championscup_", 1, 10, "news_body_seasonpreview_championscup_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "EURO_LEAGUE" ) then
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_euroleague_", 1, 10, "news_body_seasonpreview_euroleague_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "MID_TABLE" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_midtable_", 1, 10, "news_body_seasonpreview_midtable_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "AVOID_RELEGATION" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_avoidrelegation_", 1, 10, "news_body_seasonpreview_avoidrelegation_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "AVOID_LOWLY_FINISH" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_avoidlowlyfinish_", 1, 10, "news_body_seasonpreview_avoidlowlyfinish_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "PROMOTION" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_promotion_", 1, 10, "news_body_seasonpreview_promotion_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "FIGHT_FOR_PROMOTION" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_fightforpromotion_", 1, 10, "news_body_seasonpreview_fightforpromotion_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "HIGH_FINISH" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_highfinish_", 1, 10, "news_body_seasonpreview_highfinish_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "FIGHT_FOR_TITLE" ) then 
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_fightforthetitle_", 1, 10, "news_body_seasonpreview_fightforthetitle_", 1, 10, NIL, prediction, locMeStr )
				elseif( leagueObj == "QUALIFY_FOR_EUROPE" ) then
					Engine.SetNewsTeam( teamId )
					Engine.SetNewsImportance( "SEASONPREVIEW" )
					Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
					Engine.SetNewsBackgroundImage( "SEASON_PREVIEW" )
					TriggerNews( "news_title_seasonpreview_qualifyforeurope_", 1, 10, "news_body_seasonpreview_qualifyforeurope_", 1, 10, NIL, prediction, locMeStr )
				end
			end --if( defensivePlayer > 0 ) then
		end -- if( creativePlayer > 0 ) then
	end -- if( attackPlayer > 0 ) then
	
	local currDate = Engine.GetCurrentDate()
	local storyId = "PREVIEWSTART"
	local currentStory = Engine.GetStoryByIdAndIndex( storyId, 1 )
	local storyDate = Engine.GetStoryStartDate( currentStory )
	local daysBetween = Engine.GetNumDaysBetween( currDate, storyDate ) + 1
	local numTeams = Engine.GetNumberOfTeamsInLeague()
	if( daysBetween < numTeams ) then
		Engine.AddDateEvent( "SSNPRV", 1, storyId )
	else
		local category = "SEASPREV"
		Engine.ForceLeagueTeamNameCacheRefresh()
		Engine.EndStoryCategory( category )
	end --if( daysBetween < numTeams ) then
end


function IsAttackPlayer( teamId, playerId )
	local match = false
	local position = Engine.GetPlayerPosition( teamId, playerId )
	if( position == "RW" or position == "RF" or position == "CF" or position == "ST"
		or position == "LF" or position == "LW" ) then
		match = true
	end
	return match
end

function IsCreativePlayer( teamId, playerId )
	local match = false
	local position = Engine.GetPlayerPosition( teamId, playerId )
	if( position == "RWB" or position == "RB" or position == "LB" or position == "LWB"
		or position == "RM" or position == "CDM" or position == "CM" or position == "CAM"
		or position == "LM" or position == "RW" or position == "LW" ) then
		match = true
	end
	return match
end

function IsDefensivePlayer( teamId, playerId )
	local match = false
	local position = Engine.GetPlayerPosition( teamId, playerId )
	if( position == "RWB" or position == "RB" or position == "LB" or position == "LWB"
		or position == "SW" or position == "CB" or position == "LCB" or position == "RCB" ) then
		match = true
	end
	return match
end

function GetRatedPlayerId( teamId, playerAttribs, attribIndex )
	local playerId = 0
	local numPlayersOnTeam = Engine.GetNumPlayers( teamId )
	local validPlayerCount = 1
	for playerCount = 2, numPlayersOnTeam do
		local percentage = GetPercentage( playerAttribs[ 1 ][ attribIndex ], playerAttribs[ playerCount ][ attribIndex ] )
		if( percentage > Tuning.PREVIEW.attributePercentage ) then
			validPlayerCount = validPlayerCount + 1
		else			
			break
		end --if( percentage <= 95 ) then
	end --for playerCount = 1, numPlayersOnTeam do
	local playerSelect = Engine.GetRandomNumber( 1, validPlayerCount )
	playerId = playerAttribs[ playerSelect ][ 1 ]
	return playerId
end

function ClearRatedPlayer( teamId, playerId, playerAttribs )
	local numPlayersOnTeam = Engine.GetNumPlayers( teamId )
	for playerCount = 1, numPlayersOnTeam do
		if( playerAttribs[ playerCount ][ 1 ] == playerId ) then
			playerAttribs[ playerCount ][ 0 ] = 0
		end --if( playerAttribs[ playerCount ][ 1 ] == playerId ) then
	end --for playerCount = 1, numPlayersOnTeam do
end

function ClearYoungPlayer( teamId, playerId, playerAttribs )
	local numPlayersOnTeam = Engine.GetNumPlayers( teamId )
	for playerCount = 1, numPlayersOnTeam do
		if( playerAttribs[ playerCount ][ 1 ] == playerId ) then
			playerAttribs[ playerCount ][ 2 ] = 0
		end --if( playerAttribs[ playerCount ][ 1 ] == playerId ) then
	end --for playerCount = 1, numPlayersOnTeam do
end

function GetPercentage( player1, player2 )
	local percentage = ( player2 / player1 ) * 100
	return percentage
end

function GeneratePlayerLists( teamId, playerAttribsAttack, playerAttribsCreative, playerAttribsDefensive, youngPlayers )	
	local numPlayersOnTeam = Engine.GetNumPlayers( teamId )
	for playerCount = 1, numPlayersOnTeam do
		playerAttribsAttack[ playerCount ] = {}
		playerAttribsAttack[ playerCount ][ 0 ] = 0
		playerAttribsAttack[ playerCount ][ 1 ] = 0
		playerAttribsCreative[ playerCount ] = {}
		playerAttribsCreative[ playerCount ][ 0 ] = 0
		playerAttribsCreative[ playerCount ][ 1 ] = 0
		playerAttribsDefensive[ playerCount ] = {}
		playerAttribsDefensive[ playerCount ][ 0 ] = 0
		playerAttribsDefensive[ playerCount ][ 1 ] = 0
		youngPlayers[ playerCount ] = {}
		youngPlayers[ playerCount ][ 0 ] = 0
		youngPlayers[ playerCount ][ 1 ] = 0
		youngPlayers[ playerCount ][ 2 ] = 0

		local currPlayer = Engine.GetPlayer( teamId, playerCount )
		local age = Engine.GetPlayerAge( teamId, currPlayer )
		local playerIndex = Engine.GetPlayerIndexById( teamId, currPlayer )
		local topPlayer = ( playerIndex <= Tuning.PREVIEW.topPlayerLowestIndex )
		if( age <= Tuning.PREVIEW.maxYoungPlayerAge and topPlayer ~= true ) then
			local playerOverall = Engine.GetPlayerOverall( currPlayer )
			youngPlayers[ playerCount ][ 0 ] = age			
			youngPlayers[ playerCount ][ 1 ] = currPlayer
			youngPlayers[ playerCount ][ 2 ] = playerOverall
			LogStringLua( "Young Player " .. playerCount .. " ( " .. currPlayer .. " ) " .. Engine.GetPlayerName( currPlayer ) .. " Player Rank: " .. playerIndex .."\n" )
		end --if( age < = 21 ) then
		
		if( IsAttackPlayer( teamId, currPlayer ) ) then
			playerAttribsAttack[ playerCount ][ 0 ] = AttackAddAttribs( teamId, currPlayer )
			playerAttribsAttack[ playerCount ][ 1 ] = currPlayer
			LogStringLua( "Attack Player " .. playerCount .. " ( " .. currPlayer .. " ) " .. Engine.GetPlayerName( currPlayer ) .. " Player Rank: " .. playerIndex .."\n" )
		end		
		if( IsCreativePlayer( teamId, currPlayer ) ) then
			playerAttribsCreative[ playerCount ][ 0 ] = CreativeAddAttribs( teamId, currPlayer )
			playerAttribsCreative[ playerCount ][ 1 ] = currPlayer
			LogStringLua( "Creative Player " .. playerCount .. " ( " .. currPlayer .. " ) " .. Engine.GetPlayerName( currPlayer ) .. " Player Rank: " .. playerIndex .."\n" )
		end
		if( IsDefensivePlayer( teamId, currPlayer ) ) then
			playerAttribsDefensive[ playerCount ][ 0 ] = DefensiveAddAttribs( teamId, currPlayer )
			playerAttribsDefensive[ playerCount ][ 1 ] = currPlayer	
			LogStringLua( "Defensive Player " .. playerCount .. " ( " .. currPlayer .. " ) " .. Engine.GetPlayerName( currPlayer ) .. " Player Rank: " .. playerIndex .."\n" )
		end	
	end
end

function SortPlayerAttribTable( p1, p2 )
	return p1[ 0 ] > p2[ 0 ]
end

function SortPlayerOverall( p1, p2 )
	return p1[ 2 ] > p2[ 2 ] 
end

function AttackAddAttribs( teamId, playerId )
	local attribTotal = 0
	local playerAttrib1 = Engine.GetPlayerAttribute( teamId, playerId, "SHOT_POWER" )
	local playerAttrib2 = Engine.GetPlayerAttribute( teamId, playerId, "FINISHING" )
	local playerOverall = Engine.GetPlayerOverall( playerId )
	attribTotal = playerAttrib1 + playerAttrib2 + playerOverall
	return attribTotal
end

function CreativeAddAttribs( teamId, playerId )
	local attribTotal = 0
	local playerAttrib1 = Engine.GetPlayerAttribute( teamId, playerId, "VISION" )
	local playerAttrib2 = Engine.GetPlayerAttribute( teamId, playerId, "FINISHING" )
	local playerAttrib3 = Engine.GetPlayerAttribute( teamId, playerId, "BALL_CONTROL" )
	local playerOverall = Engine.GetPlayerOverall( playerId )
	attribTotal = playerAttrib1 + playerAttrib2 + playerAttrib3 + playerOverall
	return attribTotal
end

function DefensiveAddAttribs( teamId, playerId )
	local attribTotal = 0
	local playerAttrib1 = Engine.GetPlayerAttribute( teamId, playerId, "STANDING_TACKLE" )
	local playerAttrib2 = Engine.GetPlayerAttribute( teamId, playerId, "AGGRESSION" )
	local playerAttrib3 = Engine.GetPlayerAttribute( teamId, playerId, "MARKING" )
	local playerOverall = Engine.GetPlayerOverall( playerId )
	attribTotal = playerAttrib1 + playerAttrib2 + playerAttrib3 + playerOverall
	return attribTotal
end
