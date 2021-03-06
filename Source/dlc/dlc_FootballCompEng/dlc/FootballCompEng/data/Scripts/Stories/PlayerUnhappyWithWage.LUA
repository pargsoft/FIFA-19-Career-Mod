-- IMPORTANT NOTE
--  Player unhappy with wage feature currently removed in its entirety as a design choice.
--  The code here currently has incompatibilities with the transfer system added for FIFA18.
---------------------------------------------------------------------------------------------

-- v2k4 - Since this was removed. Try and make it work again??
require "logging.file"

local logger = logging.file("v2k4test%s.log", "%Y-%m-%d")

logger:info("logging.file test")
logger:debug("debugging...")
logger:error("error!")

function ExamineFor_UnhappyWithWage( teamId, playerId )
	local category = "WAGE"
	local numStories = Engine.GetNumStoriesByCategory( category )
	if( numStories < Tuning.UWW.numStoriesLimit ) then
		local userTeam = Engine.GetUserTeam()
		if( teamId == userTeam ) then
			local involved = Engine.IsPlayerInvolvedInStoryCategory( playerId, category )
			if( involved == false ) then
				local playerTier = Engine.GetPlayerTier( teamId, playerId )
				if( playerTier < Tuning.UWW.playerTierLimit ) then
					local isListed = Engine.IsPlayerOnTransferList( playerId )
					local loanListed = Engine.IsPlayerOnLoanList( playerId )
					local yearsRemaining = Engine.GetRemainingContractYears( teamId, playerId )
					if( isListed == false and loanListed == false and yearsRemaining < Tuning.UWW.yearsRemainingLimit ) then
						StartStory_UnhappyWithWage( teamId, playerId )
					end
				end
			end
		end
	end
end

function StartStory_UnhappyWithWage( teamId, playerId )
	local storyId = "UNHAPPYWAGE"
	local category = "WAGE"
	local numStories = Engine.GetNumStoriesByCategory( category )
	-- storyId = storyId .. "_" .. numStories
	-- if( Engine.MarkPlayerForStory( teamId, playerId, category, storyId, 21 ) == true ) then
	-- 	local delay = Engine.GetRandomNumber( Tuning.UWW.minDelay, Tuning.UWW.maxDelay )
	-- 	Engine.AddDateEvent( "STARTDELAY", delay, storyId )
	-- end
	
	storyId = storyId .. "_" .. numStories
	if( Engine.MarkPlayerForStory( teamId, playerId, category, storyId, 21 ) == true ) then
	 	Engine.AddDateEvent( "STARTDELAY", 1, storyId )
	 end
end

function UnhappyWithWage_DynamicEvent( eventId, storyId )
	if( eventId == "STARTDELAY" ) then
		UnhappyWithWage_Stage1( storyId )
	elseif( eventId == "REQUESTWAGE" ) then
	 	UnhappyWithWage_Stage2( storyId )
	elseif( eventId == "WAGEBOARD" ) then
	 	UnhappyWithWage_Stage2_Board( storyId )
	end
end

function UnhappyWithWage_Stage1( storyId )
	local currentStory = Engine.GetStoryById( storyId )
	local storyPlayer = Engine.GetStoryPlayer( currentStory )
	local storyTeam = Engine.GetStoryTeam( currentStory )
	Engine.SetStringTeams( storyTeam )
	Engine.SetStringPlayers( storyPlayer )
	Engine.SetStoryMoraleOverride( currentStory, 4 )
	Engine.AddConversation( storyPlayer, "popup_unhappywage_stage1_", 1, 4, "popup_unhappywage_stage1_subject", currentStory )
	local delay = Tuning.UWW.Stage1_BaseDelay
	local inWindow = Engine.IsWithinTransferWindow()
	if( inWindow == true ) then
		local numDays = Engine.GetNumDaysRemainingInTransferWindow()
		if( numDays <= 30 and numDays > 20 ) then
			delay = numDays - Tuning.UWW.Stage1_DelayStep
		end
	else
		local numDays = Engine.GetNumDaysUntilNextTransferWindow()
		if( numDays < 30 ) then
			delay = numDays + Tuning.UWW.Stage1_DelayStep
		end
	end
	Engine.AddDateEvent( "REQUESTWAGE", delay, storyId )
	Engine.SetStoryStage( currentStory, 1 )
end

function UnhappyWithWage_Stage2( storyId )
	local currentStory = Engine.GetStoryById( storyId )
	local storyPlayer = Engine.GetStoryPlayer( currentStory )
	local storyTeam = Engine.GetStoryTeam( currentStory )
	local wouldLeave = WouldPlayerEvenLeaveClub( storyTeam, storyPlayer )
	if( wouldLeave == true ) then
		Engine.SetStringTeams( storyTeam )
		Engine.SetStringPlayers( storyPlayer )
		Engine.AddConversation( storyPlayer, "popup_unhappywage_stage2_", 1, 4, "popup_unhappywage_stage2_subject", currentStory )
		Engine.AddDateEvent( "WAGEBOARD", 2, storyId )
	else
		Engine.EndStoryId( storyId )
	end
end

function UnhappyWithWage_Stage2_Board( storyId )
	local currentStory = Engine.GetStoryById( storyId )
	local storyPlayer = Engine.GetStoryPlayer( currentStory )
	local storyTeam = Engine.GetStoryTeam( currentStory )
	local userName = Engine.GetUsername()
	Engine.SetStringTeams( storyTeam )
	Engine.SetStringPlayers( storyPlayer )
	TriggerEmail( false, userName, "CM_Inbox_Sender_Board", "CM_Email_Subject_unhappywage_", 1, 4, "CM_Email_Body_unhappywage_", 1, 4 )
	Engine.ForceUserPlayerOntoTransferList( storyPlayer )
	Engine.SetStorySellPlayersOverride( currentStory, 1 )
	Engine.SetStoryContractOverride( currentStory, 7 )
end

function UnhappyWithWage_ContractAccept( teamId, playerId )
	local category = "WAGE"
	local numStories = Engine.GetNumStoriesByCategory( category )
	if( numStories > 0 ) then
		for storyCount = numStories, 1, -1 do
			local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
			local storyPlayer = Engine.GetStoryPlayer( currentStory )
			if( storyPlayer == playerId ) then
				local storyId = Engine.GetStoryId( currentStory )
				Engine.EndStoryId( storyId )
			end
		end
	end
end