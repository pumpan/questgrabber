questgrabberframe = CreateFrame("Frame")
questgrabberframeAccept = CreateFrame("Frame")
questgrabberframeHide = CreateFrame("Frame")
questgrabberframeLoadingDone = CreateFrame("Frame")

questgrabberframe:RegisterEvent("QUEST_GREETING")
questgrabberframeAccept:RegisterEvent("QUEST_DETAIL")
questgrabberframeHide:RegisterEvent("QUEST_FINISHED")
questgrabberframeLoadingDone:RegisterEvent("ADDON_LOADED")

local questgrabberMaxQuestsShown = 0
local questsToAutoAccept = {}

questgrabberMasterFrame1 = CreateFrame("Frame", "questgrabberMasterFrame1", UIParent)

questgrabberMasterFrame1:SetWidth(200) -- Initial width
questgrabberMasterFrame1:SetHeight(600)
questgrabberMasterFrame1:SetPoint("CENTER", 0, 0)
questgrabberMasterFrame1:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 1,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
questgrabberMasterFrame1:SetBackdropColor(.01, .01, .01, 1)

questgrabberMasterFrame1:SetMovable(true)
questgrabberMasterFrame1:EnableMouse(true)
questgrabberMasterFrame1:SetClampedToScreen(true)
questgrabberMasterFrame1:RegisterForDrag("LeftButton")

questgrabberMasterFrame1:SetMovable(true)
questgrabberMasterFrame1:EnableMouse(true)
questgrabberMasterFrame1:SetClampedToScreen(false)
questgrabberMasterFrame1:RegisterForDrag("RightButton")
questgrabberMasterFrame1:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" and not this.isMoving then
        this:StartMoving();
        this.isMoving = true;
    end
end)
questgrabberMasterFrame1:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" and this.isMoving then
        this:StopMovingOrSizing();
        this.isMoving = false;
    end
end)
questgrabberMasterFrame1:SetScript("OnHide", function()
    if this.isMoving then
        this:StopMovingOrSizing();
        this.isMoving = false;
    end
end)

questgrabberMasterFrame1:Hide()

function OpenQuestGrabber()
    if questgrabberMasterFrame1:IsShown() then
        questgrabberMasterFrame1:Hide()
    else
        questgrabberMasterFrame1:Show()
    end
end

function CalculateTotalHeight(numQuests)
    local contentHeight = 25 -- Height for each quest item
    local spacing

    if numQuests < 8 then
        spacing = 5
    elseif numQuests > 14 then
        spacing = 1
	else
        spacing = 2	
    end

    return numQuests * contentHeight + (numQuests - 1) * spacing
end


function CalculateMaxWidth()
    local maxWidth = 0
    local fontString = questgrabberMasterFrame1:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    fontString:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")

    for i = 1, GetNumAvailableQuests() do
        local title = GetAvailableTitle(i)
        fontString:SetText(title)
        local width = fontString:GetStringWidth()
        maxWidth = math.max(maxWidth, width)
    end
    fontString:Hide()
    return maxWidth
end

function UpdateFrameSize()
    local countAvlQuests = GetNumAvailableQuests()
    local totalHeight = CalculateTotalHeight(countAvlQuests)
    local maxWidth = CalculateMaxWidth()
    questgrabberMasterFrame1:SetHeight(totalHeight)
    questgrabberMasterFrame1:SetWidth(maxWidth + 60) 
end


questgrabberMasterFrame1.header = questgrabberMasterFrame1:CreateTexture(nil, 'ARTWORK')
questgrabberMasterFrame1.header:SetWidth(320)
questgrabberMasterFrame1.header:SetHeight(64)
questgrabberMasterFrame1.header:SetPoint('TOP', questgrabberMasterFrame1, 0, 18)
questgrabberMasterFrame1.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
questgrabberMasterFrame1.header:SetVertexColor(.2, .2, .2)

questgrabberMasterFrame1.headerText = questgrabberMasterFrame1:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
questgrabberMasterFrame1.headerText:SetPoint('TOP', questgrabberMasterFrame1.header, 0, -14)
questgrabberMasterFrame1.headerText:SetText('QuestGrabber Settings')

questgrabberMasterFrame1.closeButton = CreateFrame('Button', 'questgrabberMasterFrame1CloseButton', questgrabberMasterFrame1, 'UIPanelCloseButton')
questgrabberMasterFrame1.closeButton:SetPoint('TOPRIGHT', 0, 0)
questgrabberMasterFrame1.closeButton:SetScript('OnClick', function()
    questgrabberMasterFrame1:Hide()
end)

questgrabberframe:SetScript(
    "OnEvent",
    function(self, event, ...)
        local countAvlQuests = GetNumAvailableQuests()
        local tableSize = table.getn(questsToAutoAccept)		
        local _, numQuests = GetNumQuestLogEntries() 
        local MAX_QUEST_LOG_ENTRIES = 20
        local createButtonsYCoords = 0


        if numQuests >= MAX_QUEST_LOG_ENTRIES and IsShiftKeyDown() then
            print("Quest Log is full: " .. numQuests)
			print("Trying to complete a quest")
            return
        end

        for i = 1, questgrabberMaxQuestsShown do
            createCheckBoxName = ("questgrabber_CheckButton_" .. i);
            createCheckBoxNameText = ("questgrabber_CheckButton_Text_" .. i);
            getglobal(createCheckBoxName):Hide()
            getglobal(createCheckBoxNameText):Hide()
        end

        for i = 1, countAvlQuests do
            createCheckBoxName = ("questgrabber_CheckButton_" .. i);
            createCheckBoxNameText = ("questgrabber_CheckButton_Text_" .. i);
            local currentQuest;            
            currentQuest = GetAvailableTitle(i)                    

            if (getglobal(createCheckBoxName))  then
                function functionToAdd()
                    local questIsAdded = false
                    local questPosition = 0
                    for r=1, table.getn(questsToAutoAccept) do
                        if questsToAutoAccept[r] == currentQuest then
                            questIsAdded = true
                            questPosition = r
                        end
                    end
                    if questIsAdded then
                        tremove(questsToAutoAccept, questPosition);
                        UIErrorsFrame:AddMessage("Removing " .. currentQuest);
                    else
                        tinsert(questsToAutoAccept, currentQuest)
                        questgrabber_QuestsToAutoHandle = questsToAutoAccept
                        UIErrorsFrame:AddMessage("Adding " .. currentQuest);                      
                    end
                end
                getglobal(createCheckBoxNameText):SetText(GetAvailableTitle(i));
                getglobal(createCheckBoxName):SetScript("OnClick", functionToAdd);
                getglobal(createCheckBoxName):Show()
                getglobal(createCheckBoxNameText):Show()
                local questIsAdded = false
                for r=1, table.getn(questsToAutoAccept) do
                    if questsToAutoAccept[r] == currentQuest then
                        questIsAdded = true
                        questPosition = r
                    end
                end
                if questIsAdded then
                    getglobal(createCheckBoxName):SetChecked(true)                
                else
                    getglobal(createCheckBoxName):SetChecked(false)                
                end
                createButtonsYCoords = createButtonsYCoords - 25
            else
                createCheckBox = CreateFrame("CheckButton", createCheckBoxName, questgrabberMasterFrame1 ,"UICheckButtonTemplate")
                createCheckBox:SetWidth(35)
                createCheckBox:SetHeight(35)
                createCheckBox:SetPoint("TOPLEFT", 0, createButtonsYCoords - 10)
                createCheckBox:SetText(GetAvailableTitle(i))
                createCheckBox.tooltipTitle = GetAvailableTitle(i)            
                createCheckBox.tooltipText = GetAvailableTitle(i)
                local currentQuest;            
                currentQuest = GetAvailableTitle(i)                    
                function functionToAdd()
                    local questIsAdded = false
                    local questPosition = 0
                    for r=1, table.getn(questsToAutoAccept) do
                        if questsToAutoAccept[r] == currentQuest then
                            questIsAdded = true
                            questPosition = r
                        end
                    end
                    if questIsAdded then
                        tremove(questsToAutoAccept, questPosition);
                        UIErrorsFrame:AddMessage("Removing " .. currentQuest);
                    else
                        tinsert(questsToAutoAccept, currentQuest)
                        questgrabber_QuestsToAutoHandle = questsToAutoAccept
                        UIErrorsFrame:AddMessage("Adding " .. currentQuest);                      
                    end
                end
                createCheckBox:SetScript("OnClick", functionToAdd);
                createCheckBoxString = createCheckBox:CreateFontString(createCheckBoxNameText, "OVERLAY", "GameTooltipText")
                createCheckBoxString:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
                createCheckBoxString:SetPoint("LEFT", 30, 0)
                createCheckBoxString:SetText(GetAvailableTitle(i))    
                local questIsAdded = false
                for r=1, table.getn(questsToAutoAccept) do
                    if questsToAutoAccept[r] == currentQuest then
                        questIsAdded = true
                        questPosition = r
                    end
                end
                if questIsAdded then
                    createCheckBox:SetChecked(true)
                else
                    createCheckBox:SetChecked(false)
                end            
                createButtonsYCoords = createButtonsYCoords - 25
                questgrabberMaxQuestsShown = i
            end        
        end
        UpdateFrameSize()
        questgrabberMasterFrame1:Show()
        if(tableSize > 0) then
            for i = 1, countAvlQuests do
                for x = 1, tableSize do    
                    if(GetAvailableTitle(i) == questsToAutoAccept[x] and IsShiftKeyDown()) then
                        SelectAvailableQuest(i)
                    end
                end
            end
        end
    end
)
questgrabberframeAccept:SetScript(
    "OnEvent",
    function(self, event, ...)
        if (IsShiftKeyDown()) then        
            AcceptQuest()        
        end
    end
)

questgrabberframeHide:SetScript(
    "OnEvent",
    function(self, event, ...)
        questgrabberMasterFrame1:Hide()
    end
)

questgrabberframeLoadingDone:SetScript(
    "OnEvent",
    function(self, event, ...)
        if(arg1 ~= nil and arg1 == "QuestGrabber_1.12.1") then
            if(questgrabber_QuestsToAutoHandle ~= nil) then
                questsToAutoAccept = questgrabber_QuestsToAutoHandle        
            end
        end
    end
)
