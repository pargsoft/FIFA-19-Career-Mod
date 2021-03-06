function ExamineFor_StarInPoorForm( matchResult, gametype, playType )
	if( Engine.WasMatchForfeited( matchResult ) == false ) then
		if( gametype ~= "FRIENDLY" and string.find( gametype, "INTERNATIONAL" ) == nil ) then
			local storyId = "NOGOAL"
			local category = "POORFORM"
			local numStories = Engine.GetNumStoriesByCategory( category )
			if( numStories <= 2 ) then
				for storyCount = 1, 2 do
					if( storyCount == 2 ) then
						storyId = "POORRUN"
					end
					if( Engine.IsStoryIDActive( storyId ) == false ) then
						local numPlayers = Tuning.POORFORM.playersToCheck
						local teamId = Engine.GetUserTeam()
						teamId = Engine.StackRankTeamByOverall( teamId )
						local success = false
						local noGoal = false
						local poorForm = false
						for playerCount = 1, numPlayers do
							local storyPlayer = Engine.GetPlayer( teamId, playerCount )
							local playerTier = Engine.GetPlayerTier( teamId, storyPlayer )
							if( playerTier == 1 ) then
								-- Poor Form
								local playerPlayed = Engine.DidPlayerPlay( teamId, storyPlayer, matchResult )
								if( playerPlayed == true ) then
									-- No Goal
									local area = Engine.GetPlayerPitchArea( teamId, storyPlayer )
									if( storyId == "NOGOAL" ) then
										if( area == "ATT" ) then
											local scored = DidPlayerScore( matchResult, storyPlayer )
											if( scored == false ) then
												noGoal = true
												success = true
											end
										end
									else
										local playerRating = Engine.GetPlayerMatchRating( teamId, storyPlayer, matchResult )
										if( area ~= "ATT" ) then
											if( playerRating < Tuning.POORFORM.poorRating ) then
												if( RollPercentageDice( 100 ) == true ) then
													poorForm = true
													success = true
												end
											end
										end
									end
									
									if( success == true ) then
										if( StartStory_PlayerInPoorForm( teamId, storyPlayer, storyId ) == true ) then
											local currentStory = Engine.GetStoryById( storyId )
											Engine.SetStoryStage( currentStory, 1 )
										end
									end
								end
							end
						end
					else
						ExamineFor_StarContinuesPoorForm( matchResult, gametype, playType, storyId )
					end
				end
			end
		end
	end
end

function StartStory_PlayerInPoorForm( teamId, playerId, storyId )
	local category = "POORFORM"
	local success = false
	if( Engine.MarkPlayerForStory( teamId, playerId, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.SetStoryPriority( currentStory, Tuning.POORFORM.storyPriority )
		success = true
	end
	return success
end

function ExamineFor_StarContinuesPoorForm( matchResult, gametype, playType, storyId )
	local category = "POORFORM"
	local currentStory = Engine.GetStoryById( storyId )
	local storyTeam = Engine.GetStoryTeam( currentStory )
	local storyPlayer = Engine.GetStoryPlayer( currentStory )
	local stage = Engine.GetStoryStage( currentStory )
	local compAssetId = Engine.GetCompetitionAssetIdFromResult( matchResult )
	local success = false
	local noGoal = false
	local poorForm = false
	local playerPlayed = Engine.DidPlayerPlay( storyTeam, storyPlayer, matchResult )
	if( playerPlayed == true ) then
		if( storyId == "NOGOAL" ) then
			local scored = DidPlayerScore( matchResult, storyPlayer )
			if( scored == false ) then
				Engine.SetStoryStage( currentStory, stage + 1 )
				if( stage >= Tuning.POORFORM.minStreak ) then
					if( stage == Tuning.POORFORM.minStreak ) then
						Engine.SetStoryMoraleOverride( currentStory, Tuning.POORFORM.moraleOverride )
						success = true
					elseif( stage == Tuning.POORFORM.minStreakForPlayerMorale ) then
						Engine.ModifyPlayerMorale( storyTeam, storyPlayer, -Tuning.POORFORM.moraleModifier )
						success = true
					elseif( stage == 15 ) then
						success = true
					else
						local chancePressCovers = RollPercentageDice( Tuning.POORFORM.chancePressCoversPerc )
						if( chancePressCovers == true ) then
							success = true
						end
					end
					noGoal = true
				end
			else
				if( stage >= Tuning.POORFORM.minStreak ) then
					success = true
				else
					Engine.EndStoryId( storyId, false )
				end
			end
		else
			local playerRating = Engine.GetPlayerMatchRating( storyTeam, storyPlayer, matchResult )
			if( playerRating < Tuning.POORFORM.poorRating ) then
				Engine.SetStoryStage( currentStory, stage + 1 )
				if( stage >= Tuning.POORFORM.minStreak ) then
					poorForm = true
					if( stage == Tuning.POORFORM.minStreak ) then
						success = true
						Engine.SetStoryMoraleOverride( currentStory, Tuning.POORFORM.moraleOverride )
					elseif( stage == Tuning.POORFORM.minStreakForPlayerMorale ) then
						success = true
						Engine.ModifyPlayerMorale( storyTeam, storyPlayer, -Tuning.POORFORM.moraleModifier )
					elseif( stage == 15 ) then
						success = true
					else
						local chancePressCovers = RollPercentageDice( Tuning.POORFORM.chancePressCoversPerc )
						if( chancePressCovers == true ) then
							success = true
						end
					end
				end
			else
				if( stage >= Tuning.POORFORM.minStreak ) then
					success = true
				else
					Engine.EndStoryId( storyId, false )
				end
			end
		end
	end
	
	if( success == true ) then
		stage = Engine.GetStoryStage( currentStory )
		local newNews = nil
		local reviewWeight = Tuning.POORFORM.postMatchReviewWeight
		if( storyId == "NOGOAL" ) then
			if( noGoal == true ) then
				local goals = Engine.GetPlayerStat( storyTeam, storyPlayer, "GOALS" )
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				local newsStage = stage - 4
				if( newsStage > 15 ) then
					newsStage = Engine.GetRandomNumber( 11, 15 )
				end
				PublishToReview( currentStory, "news_body_poorrun_nogoal_postmatch_", newsStage, reviewWeight, stage ) -- Dynamic Variations
				local review = Engine.GetNewsById( "REVIEW" )
				Engine.SetNewsCompetitionAssetId( compAssetId )
				Engine.SetNewsHeadlineByObject( review, "news_title_poorrun_nogoal_postmatch_", newsStage, stage )
				Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", storyPlayer, review )
				Engine.SetNewsBackgroundImage( "GRAPH_DROPPING", review )
				Engine.SetNewsCinematic ( "CM_News_PlayerActionNegative", review )
				Engine.SetNewsPlayer( review, storyPlayer )
				if( goals == 0 ) then
					Engine.SetStringCurrency( fee )
					Engine.SetStringPlayer( storyPlayer )
					PublishToReview( nil, "news_body_poorrun_postmatch_nogoals_", 2, reviewWeight - 1, stage )
				end
			else
				local goalCount = 0
				local numIncidents = Engine.GetNumberOfIncidents( matchResult )
				for incidentCount = 1, numIncidents do
					local type = Engine.GetIncidentTypeByIndex( matchResult, incidentCount )
					if( type == "GOAL" ) then
						local incident = Engine.GetMatchIncidentByIndex( matchResult, incidentCount )
						local teamId, playerId, incidentTime = Engine.GetIncidentTeamPlayerAndTime( matchResult, incident )
						if(  playerId == storyPlayer ) then
							goalCount = goalCount + 1
						end
					end
				end
				local goals = Engine.GetPlayerStat( storyTeam, storyPlayer, "GOALS" )
				if( ( goals - goalCount ) <= 0 ) then
					Engine.SetStringPlayer( storyPlayer )
					Engine.SetStringTeams( storyTeam )
					PublishToReview( nil, "news_body_poorrun_postmatch_nogoals_scored_", 2, reviewWeight - 2, stage )
				end
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				Engine.ModifyPlayerMorale( storyTeam, storyPlayer, Tuning.POORFORM.moraleModifier )
				PublishToReview( currentStory, "news_body_poorrun_postmatch_goalscored_", 2, reviewWeight - 1, stage )
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				local review = Engine.GetNewsById( "REVIEW" )
				Engine.SetNewsHeadlineByObject( review, "news_title_poorrun_postmatch_goalscored_", 4, stage )
				Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", storyPlayer, review )
				Engine.SetNewsBackgroundImage( "GRAPH_DROPPING", review )
				Engine.SetNewsPlayer( review, storyPlayer )
				Engine.EndStoryId( storyId )
			end
		else
			if( poorForm == true ) then
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				local newsStage = stage - 4
				if( newsStage > 4 ) then
					newsStage = Engine.GetRandomNumber( 1, 4 )
				end
				PublishToReview( currentStory, "news_body_poorrun_poorform_postmatch_", newsStage, reviewWeight, stage )
				local review = Engine.GetNewsById( "REVIEW" )
				Engine.SetNewsCompetitionAssetId( compAssetId )
				Engine.SetNewsHeadlineByObject( review, "news_title_poorrun_poorform_postmatch_", newsStage, stage )
				Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", storyPlayer, review )
				Engine.SetNewsBackgroundImage( "GRAPH_DROPPING", review )
				Engine.SetNewsCinematic ( "CM_News_PlayerActionNegative", review )
				Engine.SetNewsPlayer( review, storyPlayer )
			else
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				Engine.ModifyPlayerMorale( storyTeam, storyPlayer, Tuning.POORFORM.moraleModifier )
				PublishToReview( currentStory, "news_body_poorrun_postmatch_poorrunends_", 2, reviewWeight, stage )
				local review = Engine.GetNewsById( "REVIEW" )
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam )
				Engine.SetNewsHeadlineByObject( review, "news_title_poorrun_poorrunends_postmatch_", 2, stage )
				Engine.SetNewsPlayer( review, storyPlayer )
				Engine.EndStoryId( storyId )
			end
		end
		local involved = Engine.IsPlayerInvolvedInStoryCategory( storyPlayer, "SIGNING" )
		if( involved == true ) then
			local status, fee, wage, sellingTeam = Engine.GetPlayerTransferInfo( storyTeam, storyPlayer )
			if( sellingTeam ~= 111592 ) then
				Engine.SetStringCurrency( fee )
				Engine.SetStringPlayer( storyPlayer )
				Engine.SetStringTeams( storyTeam, sellingTeam )
				PublishToReview( nil, "news_body_poorrun_newsigning_", 4, Tuning.POORFORM.newSigningReviewWeight, stage )
			end
		end
		if( gametype == "LEAGUE" ) then
			PoorRun_EndOfSeason()
		end
	end
end

function StarInPoorForm_PreMatch( numDays, gametype, fixture )
	if( numDays == 0 ) then
		local category = "POORFORM"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			if( gametype ~= "FRIENDLY" and string.find( gametype, "INTERNATIONAL" ) == nil ) then
				for storyCount = 1, numStories do
					local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
					local storyId = Engine.GetStoryId( currentStory )
					local storyTeam = Engine.GetStoryTeam( currentStory )
					local storyPlayer = Engine.GetStoryPlayer( currentStory )
					local inStarting11 = Engine.IsPlayerInStartingLineup( storyTeam, storyPlayer )
					local bench = Engine.IsPlayerOnBench( storyTeam, storyPlayer )
					if( bench == true or inStarting11 == true ) then
						local stage = Engine.GetStoryStage( currentStory )
						local newNews = nil
						if( stage >= Tuning.POORFORM.minStreak ) then
							local ableToPlay = IsAbleToPlay( storyTeam, storyPlayer )
							if( ableToPlay == true ) then
								local playedLast = Engine.DidPlayInLastGame( storyTeam, storyPlayer )
								if( playedLast == true ) then
									local success = false
									if( stage == Tuning.POORFORM.minStreak ) then
										success = true
									elseif( stage == Tuning.POORFORM.minStreakForPlayerMorale ) then
										success = true
									elseif( stage == 15 ) then
										success = true
									else
										local chancePressCovers = RollPercentageDice( Tuning.POORFORM.chancePressCoversPerc )
										if( chancePressCovers == true ) then
											success = true
										end
									end
									if( success == true ) then
										Engine.SetStringPlayer( storyPlayer )
										Engine.SetStringTeams( storyTeam )
										local newsStage = stage - 4
										if( storyId == "NOGOAL" ) then
											if( newsStage > 15 ) then
												newsStage = Engine.GetRandomNumber( 11, 15 )
											end
											newNews = Engine.CreateNews( "POORRUN", "news_title_poorrun_nogoal_prematch_", newsStage, stage )
											Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", storyPlayer, newNews )
											Engine.SetNewsBackgroundImage( "GRAPH_DROPPING", newNews )
											Engine.SetNewsCinematic ( "CM_News_PlayerActionNegative", newNews )
											Engine.SetStringPlayer( storyPlayer )
											Engine.SetStringTeams( storyTeam )
											Engine.AddParagraph( newNews, Tuning.POORFORM.noGoalPreMatchNewsWeight, "news_body_poorrun_nogoal_prematch_", newsStage, stage )
										else
											if( newsStage > 4 ) then
												newsStage = Engine.GetRandomNumber( 1, 4 )
											end
											newNews = Engine.CreateNews( "POORRUN", "news_title_poorrun_poorform_prematch_", newsStage, stage )
											Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", storyPlayer, newNews )
											Engine.SetNewsBackgroundImage( "GRAPH_DROPPING", newNews )
											Engine.SetStringPlayer( storyPlayer )
											Engine.SetStringTeams( storyTeam )
											Engine.AddParagraph( newNews, Tuning.POORFORM.poorFormPreMatchNewsWeight, "news_body_poorrun_poorform_prematch_", newsStage, stage )
										end
										local involved = Engine.IsPlayerInvolvedInStoryCategory( storyPlayer, "SIGNING" )
										if( involved == true ) then
											local status, fee, wage, sellingTeam = Engine.GetPlayerTransferInfo( storyTeam, storyPlayer )
											if( sellingTeam ~= 111592 ) then
												Engine.SetStringCurrency( fee )
												Engine.SetStringPlayer( storyPlayer )
												Engine.SetStringTeams( storyTeam, sellingTeam )
												Engine.AddParagraph( newNews, Tuning.POORFORM.newSigningNewsWeight, "news_body_poorrun_newsigning_", 4, stage )
											end
										end
										if( storyId == "NOGOAL" ) then
											local goals = Engine.GetPlayerStat( storyTeam, storyPlayer, "GOALS" )
											if( goals == 0 ) then
												Engine.SetStringPlayer( storyPlayer )
												Engine.SetStringTeams( storyTeam )
												Engine.AddParagraph( newNews, Tuning.POORFORM.preMatchNoGoalsNewsWeight, "news_body_poorrun_prematch_nogoals_", 2, stage )
											end
										end
										PublishArticle( currentStory, newNews, "MAJOR", storyTeam, storyPlayer )
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

function PoorRun_TransferListed( teamId, playerId, leagueId, marketValue, currency )
	local userTeam = Engine.GetUserTeam()
	if( teamId == userTeam ) then
		local category = "POORFORM"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			for storyCount = numStories, 1, -1 do
				local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
				local storyPlayer = Engine.GetStoryPlayer( currentStory )
				local storyTeam = Engine.GetStoryTeam( currentStory )
				local storyId = Engine.GetStoryId( currentStory )
				if( playerId == storyPlayer ) then
					local stage = Engine.GetStoryStage( currentStory )
					if( stage >= Tuning.POORFORM.minStreak ) then
						if( Engine.IsPlayerInvolvedInStoryCategory( playerId, "TRANSREQ" ) == false and Engine.IsPlayerInvolvedInStoryCategory( playerId, "REQTRANS" ) == false ) then
							Engine.SetStringPlayers( playerId )
							Engine.SetStringTeams( teamId )
							local newNews = Engine.CreateNews( "LOSTPLAYERS", "news_title_poorrun_TransferListed_", 2, stage )
							Engine.AddParagraph( newNews, Tuning.POORFORM.transferListedNewsWeight, "news_body_poorrun_TransferListed_", 2, stage )
							PublishArticle( currentStory, newNews, "MAJOR", userTeam, playerId )
						end
						Engine.EndStoryId( storyId )
						break
					end
				end
			end
		end
	end
end

function PoorRun_LoanListed( teamId, playerId, leagueId )
	local userTeam = Engine.GetUserTeam()
	if( teamId == userTeam ) then
		local category = "POORFORM"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			for storyCount = numStories, 1, -1 do
				local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
				local storyPlayer = Engine.GetStoryPlayer( currentStory )
				local storyTeam = Engine.GetStoryTeam( currentStory )
				local storyId = Engine.GetStoryId( currentStory )
				if( playerId == storyPlayer ) then
					local stage = Engine.GetStoryStage( currentStory )
					if( stage >= Tuning.POORFORM.minStreak ) then
						Engine.SetStringPlayers( playerId )
						Engine.SetStringTeams( teamId )
						local newNews = Engine.CreateNews( "LOSTPLAYERS", "news_title_poorrun_LoanListed_", 2, stage )
						Engine.AddParagraph( newNews, Tuning.POORFORM.loanListedNewsWeight, "news_body_poorrun_LoanListed_", 2, stage )
						PublishArticle( currentStory, newNews, "MAJOR", userTeam, playerId )
						Engine.EndStoryId( storyId )
					end
				end
			end
		end
	end
end

function PoorRun_Released( teamId, playerId )
	local userTeam = Engine.GetUserTeam()
	if( teamId == userTeam ) then
		local category = "POORFORM"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			for storyCount = numStories, 1, -1 do
				local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
				local storyPlayer = Engine.GetStoryPlayer( currentStory )
				local storyTeam = Engine.GetStoryTeam( currentStory )
				local storyId = Engine.GetStoryId( currentStory )
				if( playerId == storyPlayer ) then
					local stage = Engine.GetStoryStage( currentStory )
					if( stage >= Tuning.POORFORM.minStreak ) then
						Engine.SetStringPlayers( playerId )
						Engine.SetStringTeams( teamId )
						local newNews = Engine.CreateNews( "LOSTPLAYERS", "news_title_poorrun_Released_", 2, stage )
						Engine.AddParagraph( newNews, Tuning.POORFORM.releasedNewsWeight, "news_body_poorrun_Released_", 2, stage )
						PublishArticle( currentStory, newNews, "MAJOR", userTeam, playerId )
					end
				end
			end
		end
	end
end

function PoorRun_EndOfSeason()
	local category = "POORFORM"
	local numStories = Engine.GetNumStoriesByCategory( category )
	if( numStories > 0 ) then
		local fixture = Engine.GetCurrentGameFixtureData()
		local numGamesPlayed = Engine.GetNumberOfFixturesPlayedFromFixture( fixture )
		local numTotalGames = Engine.GetTotalFixturesPlayedFromFixture( fixture )
		local numGamesRemaining = numTotalGames - numGamesPlayed
		if( numGamesRemaining == 0 ) then
			Engine.EndStoryCategory( category, false )
		end
	end
end