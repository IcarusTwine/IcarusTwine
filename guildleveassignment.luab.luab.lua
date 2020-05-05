(function()
  GuildleveAssignment.TALK_ACCEPTABLE = 0
  GuildleveAssignment.TALK_UNRELEASED = 1
  GuildleveAssignment.TALK_MISSION = 2
  GuildleveAssignment.TALK_LOCK = 3
  GuildleveAssignment.TALK_REWARD = 4
  GuildleveAssignment.TALK_NOT_BELONG_GC = 5
  GuildleveAssignment.TALK_NOT_REACHED_GC_RANK = 6
  GuildleveAssignment.TALK_EVENT_CLEAR = 7
  function GuildleveAssignment:OnScene00000(pc, target, ...)
    local isReturnNest = (...)
    if isReturnNest ~= 1 then
      self:GuildleveAssignmentTalk(self.TALK_ACCEPTABLE)
    end
    while true do
      local res = self:selectMenu(pc, target)
      if res == self.TOP_MENU_REWARD then
        self:getReward(pc, target)
      elseif res == self.TOP_MENU_BATTLE or res == self.TOP_MENU_CRAFT or res == self.TOP_MENU_GATHERING or res == self.TOP_MENU_MAELSTROM or res == self.TOP_MENU_ORDER_OF_TWIN_ADDER or res == self.TOP_MENU_IMMORTAL_FLAMES then
        self:checkHowTo(pc, res)
        self:selectList(res)
      elseif res == self.TOP_MENU_EXPLAIN then
        if self:HaveCompanyLeve() then
          self:explainCompanyleve(pc, target)
        else
          self:explainGuildleve(pc, target)
        end
      else
        if res == self.TOP_MEMU_GC_SUPPLY_DUTY then
          return 1
        end
        break
      end
    end
  end
  function GuildleveAssignment:selectMenu(pc, target)
    local selectMenuText = {}
    local selectMenuIndex = {}
    if self:HasNextReward() then
      table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_REWARD)
      table.insert(selectMenuIndex, self.TOP_MENU_REWARD)
    end
    if self:HaveCompanyLeve() then
      if self:HaveMaelstromLeve() then
        table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_08)
        table.insert(selectMenuIndex, self.TOP_MENU_MAELSTROM)
      end
      if self:HaveTwinAdderLeve() then
        table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_09)
        table.insert(selectMenuIndex, self.TOP_MENU_ORDER_OF_TWIN_ADDER)
      end
      if self:HaveImmortalLeve() then
        table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_10)
        table.insert(selectMenuIndex, self.TOP_MENU_IMMORTAL_FLAMES)
      end
      table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_11)
      table.insert(selectMenuIndex, self.TOP_MEMU_GC_SUPPLY_DUTY)
    else
      table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_00)
      table.insert(selectMenuIndex, self.TOP_MENU_BATTLE)
      table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_01)
      table.insert(selectMenuIndex, self.TOP_MENU_GATHERING)
      table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_02)
      table.insert(selectMenuIndex, self.TOP_MENU_CRAFT)
    end
    table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_06)
    table.insert(selectMenuIndex, self.TOP_MENU_EXPLAIN)
    table.insert(selectMenuText, self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_07)
    table.insert(selectMenuIndex, self.TOP_MENU_CLOSED)
    local res = self:Menu(self.TEXT_GUILDLEVEASSIGNMENT_SELECT_MENU_TITLE, unpack(selectMenuText))
    return selectMenuIndex[res]
  end
  function GuildleveAssignment:getReward(pc, target)
    while self:HasNextReward() do
      self:GuildleveAssignmentTalk(self.TALK_REWARD)
      self:talkAdditionalRewards()
      self:talkRewardPenalty()
      local rewardResult = self:GuildleveRewardMenu()
      if rewardResult then
        self:LeveCompleted()
      else
        self:AdvanceReward()
      end
    end
    self:ResetReward()
  end
  function GuildleveAssignment:talkAdditionalRewards()
    local difficulty, earlyClear, eventClear, sameCompany, gatheringEvaluation, companyLeveAdditionalEvaluation = self:HaveAdditionalRewards()
    if gatheringEvaluation ~= self.GATHERING_LEVE_EVALUATION_RANK_NONE then
      local bonus = 0
      if gatheringEvaluation == self.GATHERING_LEVE_EVALUATION_RANK_A then
        bonus = self.GL_GATHERING_EVAL_VALUE_A
      elseif gatheringEvaluation == self.GATHERING_LEVE_EVALUATION_RANK_B then
        bonus = self.GL_GATHERING_EVAL_VALUE_B
      elseif gatheringEvaluation == self.GATHERING_LEVE_EVALUATION_RANK_C then
        bonus = self.GL_GATHERING_EVAL_VALUE_C
      elseif gatheringEvaluation == self.GATHERING_LEVE_EVALUATION_RANK_D then
        bonus = self.GL_GATHERING_EVAL_VALUE_D
      elseif gatheringEvaluation == self.GATHERING_LEVE_EVALUATION_RANK_E then
        bonus = self.GL_GATHERING_EVAL_VALUE_E
      end
      local isPlus = 1
      if bonus < 0 then
        bonus = -bonus
        isPlus = 0
      end
      if bonus ~= 0 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_ADD_REWARD_BY_GATHERING, true, bonus, isPlus)
      end
    end
    local isCompanyBonus = 0
    if sameCompany > 0 or companyLeveAdditionalEvaluation > 0 then
      self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_ADD_REWARD_BY_GCLEVE, true, sameCompany, companyLeveAdditionalEvaluation)
      isCompanyBonus = 1
    end
    local isDifficultyBonus = 0
    if difficulty > 0 then
      local addLevel = difficulty
      self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_ADD_REWARD_BY_DIFFICULTY, true, difficulty, 0, 0, addLevel, isCompanyBonus)
      isDifficultyBonus = 1
    end
    if earlyClear > 0 or eventClear > 0 then
      local isAdditional = 0
      if isCompanyBonus > 0 or isDifficultyBonus > 0 then
        isAdditional = 1
      end
      self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_ADD_REWARD_BY_BONUS, true, isAdditional, earlyClear, eventClear)
    end
    if eventClear > 0 then
      self:GuildleveAssignmentTalk(self.TALK_EVENT_CLEAR)
    end
  end
  function GuildleveAssignment:talkRewardPenalty()
    local cantGetExpClass = self:GetRewardPenalty()
    if cantGetExpClass then
      self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_NOT_GET_REWARD_BATTLE, true)
    end
  end
  function GuildleveAssignment:OnScene00001(pc, target)
    self:GuildleveAssignmentTalk(self.TALK_MISSION)
  end
  function GuildleveAssignment:OnScene00002(pc, target)
    self:GuildleveAssignmentTalk(self.TALK_UNRELEASED)
  end
  function GuildleveAssignment:OnScene00003(pc, target)
    self:GuildleveAssignmentList(self.TOP_MENU_BATTLE, true)
  end
  function GuildleveAssignment:OnScene00004(pc, target)
    self:GuildleveAssignmentTalk(self.TALK_LOCK)
  end
  function GuildleveAssignment:OnScene00005(pc, target, leveId)
    self:SetReward(leveId)
    self:talkAdditionalRewards()
    self:talkRewardPenalty()
    local rewardResult = self:GuildleveRewardMenu()
    if rewardResult then
      self:LeveCompleted()
    end
  end
  function GuildleveAssignment:OnScene00006(pc, target)
    self:GuildleveAssignmentTalk(self.TALK_NOT_BELONG_GC)
  end
  function GuildleveAssignment:OnScene00007(pc, target)
    self:GuildleveAssignmentTalk(self.TALK_NOT_REACHED_GC_RANK)
  end
  function GuildleveAssignment:selectList(menuIndex)
    self:GuildleveAssignmentList(menuIndex, false)
  end
  function GuildleveAssignment:historyEvaluation(pc, target)
  end
  function GuildleveAssignment:explainGuildleve(pc, target)
    while true do
      local res = self:Menu(self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_TITLE, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_00, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_01, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_02, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_03, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_04, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_05, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_06, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_07, self.TEXT_GUILDLEVEASSIGNMENT_EXPLAIN_MENU_10)
      if res == 1 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_GUILDLEVE_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_GUILDLEVE_01, true)
      elseif res == 2 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_TICKET_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_TICKET_01, true)
      elseif res == 3 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_LEVE_LINK_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_LEVE_LINK_01, true)
      elseif res == 4 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_BATTLE_LEVE_00, true)
      elseif res == 5 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_GATHERING_LEVE_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_GATHERING_LEVE_01, true)
      elseif res == 6 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_CRAFT_LEVE_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_CRAFT_LEVE_01, true)
      elseif res == 7 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_WANTED_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_WANTED_01, true)
      elseif res == 8 then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_TREASURE_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_TREASURE_01, true)
      else
        break
      end
    end
  end
  function GuildleveAssignment:explainCompanyleve(pc, target)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE00)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE01)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE02)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE03)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE04)
    self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_EXPLAIN_COMPANY_LEVE05, true)
  end
  function GuildleveAssignment:checkHowTo(pc, category)
    if category == self.TOP_MENU_CRAFT then
      local howToId = self.EXD_HOWTO_CRAFT_LEVE_ACCEPT
      if pc:IsHowTo(howToId) == false then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_CRAFT_LEVE_HOWTO_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_CRAFT_LEVE_HOWTO_01, true)
        self:HowTo(howToId)
      end
    elseif category == self.TOP_MENU_GATHERING then
      local howToId = self.EXD_HOWTO_GATHERING_LEVE_ACCEPT
      if pc:IsHowTo(howToId) == false then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_GATHERING_LEVE_HOWTO_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_GATHERING_LEVE_HOWTO_01, true)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_GATHERING_LEVE_HOWTO_02, true)
        self:HowTo(howToId)
      end
    elseif category == self.TOP_MENU_MAELSTROM or category == self.TOP_MENU_ORDER_OF_TWIN_ADDER or category == self.TOP_MENU_IMMORTAL_FLAMES then
      local howToId = self.GL_HOW_TO_GC_LEVE
      if pc:IsHowTo(howToId) == false then
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_COMPANY_LEVE_HOWTO_00)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_COMPANY_LEVE_HOWTO_01)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_COMPANY_LEVE_HOWTO_02)
        self:SystemTalk(self.TEXT_GUILDLEVEASSIGNMENT_TALK_COMPANY_LEVE_HOWTO_03, true)
        self:HowTo(howToId)
      end
    end
  end
end)()
;(function()
  function GuildleveAssignment:OnInitialize()
    self:AddNestEventHandler(self.GC_SUPPLY_CUSTOMTALK)
  end
end)()
