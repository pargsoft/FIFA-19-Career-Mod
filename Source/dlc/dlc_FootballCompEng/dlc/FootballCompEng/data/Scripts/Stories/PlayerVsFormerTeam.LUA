-- "PREVIEW" news are blocked from C++ code in SendNews(), even if their logic is still kept in Lua code. So, they no longer get sent.

function ExamineFor_PlayerVsFormerTeam( numDays, gametype, fixture )
	local numDaysBefore = Tuning.FORMERTEAM.numDaysBefore
	if( numDays == numDaysBefore ) then
		local topPlayer = 0
		local topTeam = 0
		local topStory = nil
		local topVar = 0
		local lostPlayerId, lostTeam, lostStoryId, lostVar = CompareStory_PlayerVsFormerTeam( "LOST" )
		local newPlayerId, newTeam, newStoryId, newVar = CompareStory_PlayerVsFormerTeam( "SIGNING" )
		if( lostPlayerId > 0 and newPlayerId > 0 ) then
			local lostOvr = Engine.GetPlayerOverall( lostPlayerId )
			local newOvr = Engine.GetPlayerOverall( newPlayerId )
			if( lostOvr - newOvr > 5 ) then
				topPlayer = lostPlayerId
				topTeam = lostTeam
				topStory = lostStoryId
				topVar = lostVar
			else
				topPlayer = newPlayerId
				topTeam = newTeam
				topStory = newStoryId
				topVar = newVar
			end
		elseif( lostPlayerId == 0 and newPlayerId > 0 ) then
			topPlayer = newPlayerId
			topTeam = newTeam
			topStory = newStoryId
			topVar = newVar
		elseif( newPlayerId == 0 and lostPlayerId > 0 ) then
			topPlayer = lostPlayerId
			topTeam = lostTeam
			topStory = lostStoryId
			topVar = lostVar
		end
		if( topPlayer > 0 ) then
			local storyActive = Engine.IsStoryIDActive( topStory )
			if( storyActive == true ) then
				local currentStory = Engine.GetStoryById( topStory )
				local fixture = Engine.GetCurrentGameFixtureData()
				local team1, team2 = Engine.GetTeamsFromFixtureData( fixture )
				NewsPlayerVsFormerTeam( team1, team2, topPlayer, topTeam, topVar, topStory )
			end
		end
	end
end

function CompareStory_PlayerVsFormerTeam( category )
	local numStories = Engine.GetNumStoriesByCategory( category )
	local topPlayer = 0
	local topTeam = 0
	local topStoryId = nil
	local topVar = nil
	if( numStories > 0 ) then
		local fixture = Engine.GetCurrentGameFixtureData()
		local team1, team2 = Engine.GetTeamsFromFixtureData( fixture )
		local userTeam, cpuTeam = GetUserCpuTeamFromIds( team1, team2 )
		local success = false
		for storyCount = 1, numStories do
			success = false
			local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
			local storyId = Engine.GetStoryId( currentStory )
			if( string.find( storyId, "CPU" ) == nil ) then
				if( Engine.GetStoryStage( currentStory ) ~= 2 ) then
					local storyTeam = Engine.GetStoryTeam( currentStory )
					local storyVar = 0
					if( category == "LOST" ) then
						storyVar = tonumber( Engine.GetStoryVariable( currentStory ) )
						if( cpuTeam == storyTeam ) then
							success = true
						end
					elseif( category == "SIGNING" ) then
						local storyPlayer = Engine.GetStoryPlayer( currentStory )
						local status, fee, wage, sellingTeam = Engine.GetPlayerTransferInfo( storyTeam, storyPlayer )
						storyVar = sellingTeam
						if( cpuTeam == storyVar ) then
							success = true
						end
					end
					if( success == true ) then
						local storyPlayer = Engine.GetStoryPlayer( currentStory )
						local storySuccess, newsStoryId = StartStory_PlayerVsFormerTeam( storyTeam, storyVar, storyPlayer, storyTeam )
						if( storySuccess == true ) then
							local playerTier = Engine.GetPlayerTier( storyTeam, storyPlayer )
							if( playerTier < 4 ) then
								local injured = Engine.IsInjured( storyTeam, storyPlayer )
								if( injured == false ) then
									if( topPlayer == 0 ) then
										topPlayer = storyPlayer
										topTeam = storyTeam
										topStoryId = newsStoryId
										topVar = storyVar
									else
										local Ovr = Engine.GetPlayerOverall( storyPlayer )
										local topOvr = Engine.GetPlayerOverall( topPlayer )
										if( Ovr > topOvr ) then
											topPlayer = storyPlayer
											topTeam = storyTeam
											topStoryId = newsStoryId
											topVar = storyVar
										end									
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return topPlayer, topTeam, topStoryId, topVar
end

function StartStory_PlayerVsFormerTeam( team1, team2, playerId, storyTeam )
	local category = "FORMERTEAM"
	local baseStoryId = "FORMERTEAM"
	local numStories = Engine.GetNumStoriesByCategory( category )
	local success = false
	local storyId = baseStoryId .. numStories
	if( Engine.MarkPlayerForStory( storyTeam, playerId, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.UpdateStoryActivity( currentStory )
		Engine.SetStoryPriority( currentStory, 2 )
		Engine.SetStoryVariable( currentStory, team2 )
		Engine.SetStoryStage( currentStory, 2 )
		success = true
	end
	return success, storyId
end

function NewsPlayerVsFormerTeam( team1, team2, playerId, storyTeam, storyVar, topStory )
	local category = "FORMERTEAM"
	if( Engine.IsStoryIDActive( topStory ) == true ) then
		local currentStory = Engine.GetStoryById( topStory )
		local newNews = nil
		local fixture = Engine.GetCurrentGameFixtureData()
		local comp = Engine.GetCompetitionFromFixture( fixture )
		local preMatchPreviewWeight = Tuning.FORMERTEAM.preMatchPreviewWeight
		local preMatchDerbyPreviewWeight = Tuning.FORMERTEAM.preMatchDerbyPreviewWeight
		Engine.SetStringPlayers( playerId )
		Engine.SetStringTeams( storyTeam, storyVar )
		Engine.SetStringCompetition( comp )
		if( team1 == storyTeam ) then
			PublishToPreview( currentStory, "news_body_player_vs_former_team_prematch_home_", 1, preMatchPreviewWeight )
			newNews = Engine.GetNewsById( "PREVIEW" )
			Engine.SetStringPlayers( playerId )
			Engine.SetStringTeams( storyTeam, storyVar )
			Engine.SetStringCompetition( comp )
			Engine.SetNewsHeadlineByObject( newNews, "news_title_player_vs_former_team_prematch_home_", 2 )
			Engine.SetNewsPlayer( newNews, playerId )
			Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", playerId, newNews )
			Engine.SetNewsBackgroundImage( "FANS_CELEBRATING", newNews )
		else
			PublishToPreview( currentStory, "news_body_player_vs_former_team_prematch_away_", 2, preMatchPreviewWeight )
			newNews = Engine.GetNewsById( "PREVIEW" )
			Engine.SetStringPlayers( playerId )
			Engine.SetStringTeams( storyTeam, storyVar )
			Engine.SetStringCompetition( comp )
			Engine.SetNewsHeadlineByObject( newNews, "news_title_player_vs_former_team_prematch_away_", 2 )
			Engine.SetNewsPlayer( newNews, playerId )
			Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", topPlayer, newNews )
			Engine.SetNewsBackgroundImage( "FANS_CELEBRATING", newNews )
			Engine.SetNewsCinematic( "CM_News_PlayerActionPositive", newNews )
		end
		local isRival = Engine.AreTeamsRivals( team1, team2 )
		local isDerby = Engine.AreTeamsDerby( team1, team2 )
		if( isRival == true or isDerby == true ) then
			Engine.SetStringPlayers( playerId )
			Engine.SetStringTeams( storyTeam, storyVar )
			Engine.SetStringCompetition( comp )
			PublishToPreview( currentStory, "news_body_player_vs_former_team_prematch_rivals_", 2, preMatchDerbyPreviewWeight )
		end
	end
end

function PostMatch_PlayerVsFormerTeam( matchResult, gametype, playType )
	local category = "FORMERTEAM"
	local numStories = Engine.GetNumStoriesByCategory( category )
	if( numStories > 0 ) then
		local fixture = Engine.GetCurrentGameFixtureData()
		local comp = Engine.GetCompetitionFromFixture( fixture )
		local wasGameWon = Engine.WasGameWon( matchResult )
		local matchWinner = Engine.GetMatchWinner( matchResult )
		local fixture = Engine.GetCurrentGameFixtureData()
		local team1, team2 = Engine.GetTeamsFromFixtureData( fixture )
		local topPlayer = 0
		local topTeam = 0
		local topStoryId = nil
		local topVar = nil
		for storyCount = numStories, 1, -1 do
			local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
			local storyId = Engine.GetStoryId( currentStory )
			local storyTeam = Engine.GetStoryTeam( currentStory )
			local storyVar = tonumber( Engine.GetStoryVariable( currentStory ) )
			local storyPlayer = Engine.GetStoryPlayer( currentStory )
			local playerPlayed = Engine.DidPlayerPlay( storyTeam, storyPlayer, matchResult )
			if( playerPlayed == true ) then
				if( topPlayer == 0 ) then
					topPlayer = storyPlayer
					topTeam = storyTeam
					topStoryId = storyId
					topVar = storyVar
				else
					local Ovr = Engine.GetPlayerOverall( storyPlayer )
					local topOvr = Engine.GetPlayerOverall( topPlayer )
					if( Ovr > topOvr ) then
						topPlayer = storyPlayer
						topTeam = storyTeam
						topStoryId = storyId
						topVar = storyVar
					else
						if( matchWinner == storyTeam ) then
							Engine.ModifyPlayerMorale( storyTeam, storyPlayer, Tuning.FORMERTEAM.moraleModifierWinner )
						else
							Engine.ModifyPlayerMorale( storyTeam, storyPlayer, Tuning.FORMERTEAM.moraleModifierLoser )
						end
					end
				end
			end
		end
		if( topPlayer > 0 ) then
			Engine.SetStringPlayers( topPlayer )
			Engine.SetStringTeams( topTeam, topVar )
			Engine.SetStringCompetition( comp )
			local newNews = nil
			local postMatchWeight = Tuning.FORMERTEAM.postMatchWeight
			local postMatchResultWeight = Tuning.FORMERTEAM.postMatchResultWeight
			if( team1 == topTeam ) then
				PublishToReview( currentStory, "news_body_player_vs_former_team_postmatch_home_", 2, postMatchWeight )
				newNews = Engine.GetNewsById( "REVIEW" )
				Engine.SetStringPlayers( topPlayer )
				Engine.SetStringTeams( topTeam, topVar )
				Engine.SetStringCompetition( comp )
				Engine.SetNewsHeadlineByObject( newNews, "news_title_player_vs_former_team_postmatch_home_", 2 )
				Engine.SetNewsPlayer( newNews, topPlayer )
				Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", topPlayer, newNews )
				Engine.SetNewsBackgroundImage( "FANS_CELEBRATING", newNews )
				Engine.SetNewsCinematic( "CM_News_PlayerActionPositive", newNews )
			else
				local reviewReady = Engine.DoesNewsExist( "REVIEW" )
				if( reviewReady == false ) then
					newNews = Engine.CreateNews( "REVIEW", "", 1 )
				else
					newNews = Engine.GetNewsById( "REVIEW" )
				end
				Engine.AddParagraphForceVariation( newNews, postMatchWeight, "news_body_player_vs_former_team_postmatch_away_", 2 )
				Engine.SetStringPlayers( topPlayer )
				Engine.SetStringTeams( topTeam, topVar )
				Engine.SetStringCompetition( comp )
				Engine.SetNewsHeadlineByObject( newNews, "news_title_player_vs_former_team_postmatch_away_", 2 )
				Engine.SetNewsPlayer( newNews, topPlayer )
			end
			Engine.SetStringPlayers( topPlayer )
			Engine.SetStringTeams( topTeam, topVar )
			Engine.SetStringCompetition( comp )
			if( wasGameWon == false ) then
				PublishToReview( nil, "news_body_player_vs_Former_team_postmatch_draw_", 2, postMatchResultWeight )
			else
				if( matchWinner == topTeam ) then
					PublishToReview( nil, "news_body_player_vs_Former_team_postmatch_won_", 2, postMatchResultWeight )
				else
					PublishToReview( nil, "news_body_player_vs_Former_team_postmatch_lost_", 2, postMatchResultWeight )
				end
			end
		end
		Engine.EndStoryCategory( category, false )
	end
end