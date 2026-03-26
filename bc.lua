-- 냥코 대전쟁 VVIP 최적화 모드 메뉴 (통합 완전 해제 버전)
-- 파일명: bc.lua

local SCRIPT_VERSION = "1.2"
-- 깃허브 Raw 주소 (끝에 / 포함)
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/KILX07/BC.lua.koris/refs/heads/main/"

-- ===========================================
-- 🔑 키 로그인 시스템 (로컬 프리패스 방식)
-- ===========================================
function KeyLogin()
    -- 내 IP 확인 (참고용)
    local ipRes = gg.makeRequest("https://api.ipify.org")
    local myIP = (ipRes and ipRes.content) and ipRes.content or "Unknown IP"
    
    local authFilePath = "/sdcard/.nyanko_auth_key"
    local cacheBuster = "?t=" .. os.time() -- 깃허브 캐시 무시용
    
    -- 1. 로컬 프리패스 확인
    local file = io.open(authFilePath, "r")
    if file then
        local savedKey = file:read("*a")
        file:close()
        
        if savedKey then
            savedKey = savedKey:match("^%s*(.-)%s*$") -- 공백 제거
            if savedKey ~= "" then
                -- 저장된 키가 깃허브 서버에서도 여전히 유효한지 확인 (정지당한 키 걸러내기)
                local keysRes = gg.makeRequest(GITHUB_RAW_URL .. "keys.txt" .. cacheBuster)
                if keysRes and keysRes.content then
                    -- [핵심 수정] 비슷한 키(예: VIP1, VIP12)가 뚫리는 것을 막기 위해 정확히 일치하는 줄만 찾음
                    local paddedContent = "\n" .. keysRes.content:gsub("\r", "") .. "\n"
                    local paddedKey = "\n" .. savedKey .. "\n"
                    
                    if string.find(paddedContent, paddedKey, 1, true) then
                        gg.toast("✅ 자동 로그인 성공! (IP: " .. myIP .. ")")
                        return true
                    else
                        gg.alert("⚠️ 인증이 만료되었거나 키가 변경/삭제되었습니다.\n다시 로그인해주세요.")
                        os.remove(authFilePath) -- 무효화된 로컬 키 삭제
                    end
                end
            end
        end
    end

    -- 2. 프리패스 실패 시 키 입력 요구
    local prompt = gg.prompt(
        {"[보안 시스템]\nAPI 키를 입력하세요.\n(현재 접속 IP: " .. myIP .. ")"}, 
        {""}, 
        {"text"}
    )
    
    if not prompt or prompt[1] == "" then
        gg.alert("❌ 로그인이 취소되었습니다.")
        os.exit()
    end
    
    local inputKey = prompt[1]:match("^%s*(.-)%s*$")
    
    -- 3. 깃허브 서버에서 키 검증
    gg.toast("키 검증 중...")
    local keysRes = gg.makeRequest(GITHUB_RAW_URL .. "keys.txt" .. cacheBuster)
    
    if keysRes and keysRes.content then
        -- [핵심 수정] 입력한 키도 정확히 일치하는 줄만 찾음
        local paddedContent = "\n" .. keysRes.content:gsub("\r", "") .. "\n"
        local paddedKey = "\n" .. inputKey .. "\n"
        
        if string.find(paddedContent, paddedKey, 1, true) then
            -- 인증 성공: 로컬에 키 저장 (다음부터 프리패스)
            local fw = io.open(authFilePath, "w")
            if fw then
                fw:write(inputKey)
                fw:close()
            end
            gg.alert("🎉 인증 성공!\n다음부터는 자동으로 로그인됩니다.")
            return true
        end
    end
    
    gg.alert("❌ 유효하지 않은 API 키입니다.")
    os.exit()
end

-- 스크립트 시작 시 무조건 실행
KeyLogin()

gg.setVisible(false)
local isMenuAlive = true
local autoCloseUI = true
local shouldCloseMenu = false

-- 동적 세션용 캐시 베이스
local SESSION_BASE = nil
local lastUsedValues = {}
local CF_OFFSET = -0x4098E8
local XP_OFFSET = -0x409790
-- 자동 승리(상대 성 체력) 오프셋
local AW_OFFSET = -0x387548

-- ===========================================
-- 1. 메인 메뉴
-- ===========================================
function Main()
    shouldCloseMenu = false
    local title = "🔥 냥코 대전쟁 모드 메뉴 [v1.1]\nMade by koris"
    local menu = gg.choice({
        "1. 💎 재화",
        "2. ⚔️ 유틸",
        "3. 🛠️ 개발자 기능",
        "4. ⚙️ 설정",
        "5. ❌ 스크립트 종료"
    }, nil, title)

    if menu == 1 then ResourceMenu() end
    if menu == 2 then UtilityMenu() end
    if menu == 3 then DeveloperMenu() end
    if menu == 4 then SettingsMenu() end
    if menu == 5 then Exit() end
end

-- ===========================================
-- 2. 설정 메뉴
-- ===========================================
function SettingsMenu()
    while true do
        if shouldCloseMenu then return end
        local status = autoCloseUI and "켜짐 (ON)" or "꺼짐 (OFF)"
        local setMenu = gg.choice({
            "1. 🔄 조작 후 UI 자동 닫기 : " .. status,
            "2. 🔙 메인 메뉴로 돌아가기"
        }, nil, "⚙️ [환경 설정] ⚙️\n기능 사용 후 메뉴 창을 자동으로 닫을지 설정합니다.")

        if setMenu == 1 then
            autoCloseUI = not autoCloseUI
            gg.toast("UI 자동 닫기가 " .. (autoCloseUI and "켜졌습니다." or "꺼졌습니다."))
        end
        if setMenu == 2 then return Main() end
        if setMenu == nil then break end
    end
end

-- ===========================================
-- 3. 재화 & 유틸리티 서브 메뉴
-- ===========================================
function ResourceMenu()
    while true do
        if shouldCloseMenu then return end
        local resMenu = gg.choice({
            "1. ⚡ 통조림",
            "2. ⚡ XP & NP",
            "3. 🎟️ 티켓",
            "4. 🍹 고양이 드링크C",
            "5. 🎒 전투 아이템",
            "6. 🍇 개다래 & 수석",
            "7. 🔙 메인 메뉴로 돌아가기"
        }, nil, "💎 [재화 컨트롤 패널] 💎")

        if resMenu == 1 then AutoEdit("CatFood") end
        if resMenu == 2 then XpNpMenu() end
        if resMenu == 3 then TicketMenu() end
        if resMenu == 4 then AutoEditGeneric(0x13784, "고양이 드링크C", 99) end
        if resMenu == 5 then ItemMenu() end
        if resMenu == 6 then CatfruitMenu() end
        if resMenu == 7 then return Main() end
        if resMenu == nil then break end
    end
end

function XpNpMenu()
    while true do
        if shouldCloseMenu then return end
        local menu = gg.choice({
            "1. ⚡ XP",
            "2. 🧬 NP",
            "3. 🔙 이전 메뉴로 돌아가기"
        }, nil, "⚡ [XP & NP 패널] ⚡")

        if menu == 1 then AutoEdit("XP") end
        if menu == 2 then AutoEditGeneric(-0x409788, "NP", 999, nil, 500) end
        if menu == 3 then return end
        if menu == nil then break end
    end
end

function TicketMenu()
    while true do
        if shouldCloseMenu then return end
        local menu = gg.choice({
            "1. 🎟️ 레어티켓",
            "2. 🎟️ 냥코티켓",
            "3. 🎫 플레티넘 티켓",
            "4. 🔙 이전 메뉴로 돌아가기"
        }, nil, "🎟️ [티켓 패널] 🎟️")

        if menu == 1 then AutoEditGeneric(-0xfc7a4, "레어티켓", 49) end
        if menu == 2 then AutoEditGeneric(-0xfc7ac, "냥코티켓", 99) end
        if menu == 3 then AutoEditGeneric(-0x412fd8, "플레티넘 티켓", 10, "※ 안전을 위해 3개 이하를 권장합니다.") end
        if menu == 4 then return end
        if menu == nil then break end
    end
end

function ItemMenu()
    while true do
        if shouldCloseMenu then return end
        local itemMenu = gg.choice({
            "1. 🎒 전체 아이템 한 번에 수정",
            "2. ⏩ 스피드업",
            "3. 📡 트레저 레이더",
            "4. 🎩 고양이 도령",
            "5. 💻 야옹컴",
            "6. 🎓 고양이 박사",
            "7. 🎯 스냥이퍼",
            "8. 🔙 이전 메뉴로 돌아가기"
        }, nil, "🎒 [전투 아이템 패널] 🎒\n최대 4499개까지 설정 가능합니다.")

        if itemMenu == 1 then AutoEditAllItems() end
        if itemMenu == 2 then AutoEditGeneric(-0x3cb758, "스피드업", 4499) end
        if itemMenu == 3 then AutoEditGeneric(-0x3cb750, "트레저 레이더", 4499) end
        if itemMenu == 4 then AutoEditGeneric(-0x3cb748, "고양이 도령", 4499) end
        if itemMenu == 5 then AutoEditGeneric(-0x3cb740, "야옹컴", 4499) end
        if itemMenu == 6 then AutoEditGeneric(-0x3cb738, "고양이 박사", 4499) end
        if itemMenu == 7 then AutoEditGeneric(-0x3cb730, "스냥이퍼", 4499) end
        if itemMenu == 8 then return end
        if itemMenu == nil then break end
    end
end

local catfruitData = {
    ["보라"] = {
        {name = "보라 개다래나무의 씨앗", offset = -0x16e41b4c},
        {name = "보라 개다래 열매", offset = -0x16e41b24},
        {name = "자수석", offset = -0x16e41abc},
        {name = "자수석 결정", offset = -0x16e41a94}
    },
    ["빨강"] = {
        {name = "빨강 개다래나무의 씨앗", offset = -0x16e41b44},
        {name = "빨강 개다래 열매", offset = -0x16e41b1c},
        {name = "홍수석", offset = -0x16e41ab4},
        {name = "홍수석 결정", offset = -0x16e41a8c}
    },
    ["파랑"] = {
        {name = "파랑 개다래나무의 씨앗", offset = -0x16e41b3c},
        {name = "파랑 개다래 열매", offset = -0x16e41b14},
        {name = "청수석", offset = -0x16e41aac},
        {name = "청수석 결정", offset = -0x16e41a84}
    },
    ["초록"] = {
        {name = "초록 개다래나무의 씨앗", offset = -0x16e41b34},
        {name = "초록 개다래 열매", offset = -0x16e41b0c},
        {name = "녹수석", offset = -0x16e41aa4},
        {name = "녹수석 결정", offset = -0x16e41a7c}
    },
    ["노랑"] = {
        {name = "노랑 개다래나무의 씨앗", offset = -0x16e41b2c},
        {name = "노랑 개다래 열매", offset = -0x16e41b04},
        {name = "황수석", offset = -0x16e41a9c},
        {name = "황수석 결정", offset = -0x16e41a74}
    },
    ["무지개"] = {
        {name = "무지개 개다래나무의 씨앗", offset = -0x16e41ae4},
        {name = "무지개 개다래 열매", offset = -0x16e41afc},
        {name = "무지개 수석", offset = -0x16e41a6c}
    },
    ["악마"] = {
        {name = "악마 개다래나무의 씨앗", offset = -0x16e41ad4},
        {name = "악마 개다래 열매", offset = -0x16e41acc}
    },
    ["고대"] = {
        {name = "고대 개다래나무의 씨앗", offset = -0x16e41af4},
        {name = "고대 개다래 열매", offset = -0x16e41aec}
    },
    ["황금"] = {
        {name = "황금 개다래나무의 씨앗", offset = -0x16e41ac4},
        {name = "황금 개다래 열매", offset = -0x16e41adc}
    }
}

function CatfruitMenu()
    while true do
        if shouldCloseMenu then return end
        local menu = gg.choice({
            "1. 🟣 보라",
            "2. 🔴 빨강",
            "3. 🔵 파랑",
            "4. 🟢 초록",
            "5. 🟡 노랑",
            "6. 🌈 무지개",
            "7. 😈 악마",
            "8. 🏺 고대",
            "9. 👑 황금",
            "10. 🔙 이전 메뉴로 돌아가기"
        }, nil, "🍇 [개다래 & 수석 패널] 🍇")

        if menu == 1 then CatfruitSubMenu("보라") end
        if menu == 2 then CatfruitSubMenu("빨강") end
        if menu == 3 then CatfruitSubMenu("파랑") end
        if menu == 4 then CatfruitSubMenu("초록") end
        if menu == 5 then CatfruitSubMenu("노랑") end
        if menu == 6 then CatfruitSubMenu("무지개") end
        if menu == 7 then CatfruitSubMenu("악마") end
        if menu == 8 then CatfruitSubMenu("고대") end
        if menu == 9 then CatfruitSubMenu("황금") end
        if menu == 10 then return end
        if menu == nil then break end
    end
end

function CatfruitSubMenu(color)
    while true do
        if shouldCloseMenu then return end
        local items = catfruitData[color]
        local choices = {}
        for i, item in ipairs(items) do
            table.insert(choices, i .. ". " .. item.name)
        end
        table.insert(choices, #choices + 1 .. ". 🔙 이전 메뉴로 돌아가기")

        local menu = gg.choice(choices, nil, "🍇 [" .. color .. " 개다래 & 수석] 🍇")
        
        if menu == nil then break end
        if menu == #choices then return end
        
        local selectedItem = items[menu]
        if selectedItem then
            AutoEditGeneric(selectedItem.offset, selectedItem.name, 999)
        end
    end
end

function UtilityMenu()
    while true do
        if shouldCloseMenu then return end
        local utilMenu = gg.choice({
            "1.  상대 성 무한 부수기 켜기",
            "2.  상대 성 무한 부수기 끄기",
            "3. 🔙 메인 메뉴로 돌아가기"
        }, nil, "⚔️ [인게임 전투 유틸리티] ⚔️\n※ 반드시 전투 스테이지 진입 후 사용하는 것을 권장합니다.")

        if utilMenu == 1 then AutoWin(true) end
        if utilMenu == 2 then AutoWin(false) end
        if utilMenu == 3 then return Main() end
        if utilMenu == nil then break end
    end
end

-- ===========================================
-- 공통 오토 엔진
-- ===========================================
function GetBaseAddress()
    if SESSION_BASE then
        local check = gg.getValues({{address = SESSION_BASE, flags = gg.TYPE_QWORD}})
        if check[1] and check[1].value == 8589934591 then
            return SESSION_BASE
        end
    end

    gg.toast("최초 1회 구조체 베이스 스캔 중... (잠시만 기다려주세요)")
    gg.clearResults()
    gg.setRanges(gg.REGION_C_BSS)
    gg.searchNumber("8589934591", gg.TYPE_QWORD)
    gg.refineAddress("50", -1, gg.TYPE_QWORD)
    
    local count = gg.getResultsCount()
    if count == 0 then
        return nil
    end
    
    local res = gg.getResults(1)
    SESSION_BASE = res[1].address
    gg.clearResults()
    return SESSION_BASE
end

function AutoEdit(type)
    local baseAddr = GetBaseAddress()
    if not baseAddr then
        gg.alert("❌ 베이스 구조체를 찾지 못했습니다! 게임이 업데이트되었을 수 있습니다.")
        return
    end

    local targetAddress1 = baseAddr
    if type == "CatFood" then
        targetAddress1 = baseAddr + CF_OFFSET
    else
        targetAddress1 = baseAddr + XP_OFFSET
    end
    
    local targetAddress2 = targetAddress1 + 4
    local title = (type == "CatFood") and "통조림" or "XP"
    local maxAmount = (type == "CatFood") and 40000 or 90000000
    local defaultAmount = lastUsedValues[type] or maxAmount

    local prompt = gg.prompt(
        {
            "✔️ 타겟 [" .. title .. "] 자동 추적 완료!\n원하는 개수를 지정하세요.",
            "❄️ 이 수치를 영구적으로 고정 (밴 위험)"
        }, 
        {defaultAmount, false}, 
        {"number", "checkbox"}
    )
    if not prompt then return end
    
    local amount = tonumber(prompt[1])
    lastUsedValues[type] = amount
    local isFreeze = prompt[2]

    local editValues = {}
    if isFreeze then
        editValues[1] = {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount, freeze = true, name = title .. " (VVIP 고정)"}
        editValues[2] = {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0, freeze = true, name = title .. " 암호키 (VVIP 고정)"}
        gg.addListItems(editValues)
        gg.alert("❄️ " .. title .. " 영구 고정 적용 완료!\n서버 정지를 방지하려면 사용 후 꼭 GG 저장 탭에서 고정 체크를 풀어주세요!")
    else
        editValues[1] = {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount}
        editValues[2] = {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0}
        gg.setValues(editValues)
        gg.alert("⚡ " .. title .. " 원터치 주입 완료!\n오프라인 상태에서 수치를 바로 1회 소모해야 정상적으로 세탁됩니다.")
    end
    if autoCloseUI then shouldCloseMenu = true end
end

function AutoEditGeneric(offset, title, maxAmount, extraMsg, defaultAmt)
    local baseAddr = GetBaseAddress()
    if not baseAddr then
        gg.alert("❌ 베이스 구조체를 찾지 못했습니다! 게임이 업데이트되었을 수 있습니다.")
        return
    end

    local targetAddress1 = baseAddr + offset
    local targetAddress2 = targetAddress1 + 4

    local msg = "✔️ 타겟 [" .. title .. "] 자동 추적 완료!\n원하는 개수를 지정하세요. (최대 " .. maxAmount .. "개)"
    if extraMsg then
        msg = msg .. "\n" .. extraMsg
    end

    local defaultAmount = lastUsedValues[title] or defaultAmt or maxAmount

    local prompt = gg.prompt(
        {
            msg,
            "❄️ 이 수치를 영구적으로 고정 (밴 위험)"
        }, 
        {defaultAmount, false}, 
        {"number", "checkbox"}
    )
    if not prompt then return end
    
    local amount = tonumber(prompt[1])
    if amount > maxAmount then
        amount = maxAmount
        gg.toast("최대 수치인 " .. maxAmount .. "개로 자동 조정되었습니다.")
    end
    lastUsedValues[title] = amount

    local isFreeze = prompt[2]

    local editValues = {}
    if isFreeze then
        editValues[1] = {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount, freeze = true, name = title .. " (VVIP 고정)"}
        editValues[2] = {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0, freeze = true, name = title .. " 암호키 (VVIP 고정)"}
        local success, err = pcall(function() gg.addListItems(editValues) end)
        if success then
            gg.alert("❄️ " .. title .. " 영구 고정 적용 완료!\n서버 정지를 방지하려면 사용 후 꼭 GG 저장 탭에서 고정 체크를 풀어주세요!")
        else
            gg.alert("❌ 적용 실패!\n오프셋 주소가 유효하지 않거나 메모리가 변경되었습니다.\n에러: " .. tostring(err))
        end
    else
        editValues[1] = {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount}
        editValues[2] = {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0}
        local success, err = pcall(function() gg.setValues(editValues) end)
        if success then
            gg.alert("⚡ " .. title .. " 원터치 주입 완료!\n오프라인 상태에서 수치를 바로 1회 소모해야 정상적으로 세탁됩니다.")
        else
            gg.alert("❌ 적용 실패!\n오프셋 주소가 유효하지 않거나 메모리가 변경되었습니다.\n에러: " .. tostring(err))
        end
    end
    if autoCloseUI then shouldCloseMenu = true end
end

function AutoEditAllItems()
    local baseAddr = GetBaseAddress()
    if not baseAddr then
        gg.alert("❌ 베이스 구조체를 찾지 못했습니다! 게임이 업데이트되었을 수 있습니다.")
        return
    end

    local maxAmount = 4499
    local defaultAmount = lastUsedValues["AllItems"] or maxAmount
    local prompt = gg.prompt(
        {
            "✔️ 모든 전투 아이템 자동 추적 완료!\n원하는 개수를 지정하세요. (최대 " .. maxAmount .. "개)",
            "❄️ 이 수치를 영구적으로 고정 (밴 위험)"
        }, 
        {defaultAmount, false}, 
        {"number", "checkbox"}
    )
    if not prompt then return end
    
    local amount = tonumber(prompt[1])
    if amount > maxAmount then
        amount = maxAmount
        gg.toast("최대 수치인 " .. maxAmount .. "개로 자동 조정되었습니다.")
    end
    lastUsedValues["AllItems"] = amount

    local isFreeze = prompt[2]
    local items = {
        {offset = -0x3cb758, name = "스피드업"},
        {offset = -0x3cb750, name = "트레저 레이더"},
        {offset = -0x3cb748, name = "고양이 도령"},
        {offset = -0x3cb740, name = "야옹컴"},
        {offset = -0x3cb738, name = "고양이 박사"},
        {offset = -0x3cb730, name = "스냥이퍼"}
    }

    local editValues = {}
    for i, item in ipairs(items) do
        local targetAddress1 = baseAddr + item.offset
        local targetAddress2 = targetAddress1 + 4
        
        if isFreeze then
            table.insert(editValues, {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount, freeze = true, name = item.name .. " (VVIP 고정)"})
            table.insert(editValues, {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0, freeze = true, name = item.name .. " 암호키 (VVIP 고정)"})
        else
            table.insert(editValues, {address = targetAddress1, flags = gg.TYPE_DWORD, value = amount})
            table.insert(editValues, {address = targetAddress2, flags = gg.TYPE_DWORD, value = 0})
        end
    end

    if isFreeze then
        gg.addListItems(editValues)
        gg.alert("❄️ 전체 전투 아이템 영구 고정 적용 완료!\n서버 정지를 방지하려면 사용 후 꼭 GG 저장 탭에서 고정 체크를 풀어주세요!")
    else
        gg.setValues(editValues)
        gg.alert("⚡ 전체 전투 아이템 원터치 주입 완료!\n오프라인 상태에서 수치를 바로 1회 소모해야 정상적으로 세탁됩니다.")
    end
    if autoCloseUI then shouldCloseMenu = true end
end

function AutoWin(turnOn)
    local baseAddr = GetBaseAddress()
    if not baseAddr then
        gg.alert("❌ 베이스 구조체를 찾지 못했습니다!\n이 기능은 전투(스테이지) 화면에 입장한 후 켜보세요.")
        return
    end

    local targetAddress = baseAddr + AW_OFFSET
    
    if turnOn then
        gg.addListItems({{address = targetAddress, flags = gg.TYPE_DWORD, value = 0, freeze = true, name = "Auto Win (상대 성 체력 0 고정)"}})
        gg.alert("🟢 상대 성 체력 0 고정 완료!\n적 기지가 한 대만 맞아도 즉시 파괴됩니다.")
    else
        local list = gg.getListItems()
        local removeList = {}
        for i, v in ipairs(list) do
            if v.name == "Auto Win (상대 성 체력 0 고정)" then
                table.insert(removeList, v)
            end
        end
        if #removeList > 0 then
            gg.removeListItems(removeList)
        end
        gg.alert("🔴 오토 윈 기능이 꺼졌습니다. (체력 고정 해제)")
    end
    if autoCloseUI then shouldCloseMenu = true end
end

-- ===========================================
-- 4. 개발자 메뉴
-- ===========================================
function DeveloperMenu()
    while true do
        if shouldCloseMenu then return end
        local devMenu = gg.choice({
            "1. 📥 [메모리 덤프] 통조림 주변(AOB) 배열 추출기",
            "2. 🧮 [오프셋 계산기] 직접 주소를 입력하여 오프셋 도출",
            "3. 🔙 메인 메뉴로 돌아가기"
        }, nil, "🛠️ [개발자 전용 도구] 🛠️\n게임 업데이트 대비용 도구입니다.")

        if devMenu == 1 then MemoryDumper() end
        if devMenu == 2 then AutoFindOffset() end
        if devMenu == 3 then return Main() end
        if devMenu == nil then break end
    end
end

-- 오프셋 계산기
function AutoFindOffset()
    local prompt = gg.prompt(
        {"계산할 타겟 주소를 입력하세요 (Hex 형식, 예: 1A2B3C4D 또는 0x1A2B3C4D):"},
        {""},
        {"text"}
    )
    if not prompt or prompt[1] == "" then return end
    
    local input = prompt[1]:gsub("0x", ""):gsub("0X", "")
    local targetAddr = tonumber(input, 16)
    
    if not targetAddr then
        gg.alert("❌ 올바른 16진수(Hex) 주소를 입력해주세요.")
        return
    end
    
    local baseAddr = GetBaseAddress()
    if not baseAddr then
        gg.alert("❌ 베이스 구조체(8589934591)를 찾을 수 없어 계산에 실패했습니다.")
        return
    end
    
    local offset = targetAddr - baseAddr
    local function toHexOffset(val)
        if val >= 0 then
            return "+0x" .. string.format("%X", val)
        else
            return "-0x" .. string.format("%X", -val)
        end
    end
    
    gg.alert(
        "🎉 오프셋 추출 성공!\n\n" ..
        "베이스: " .. string.format("%X", baseAddr) .. "\n" ..
        "타겟주소: " .. string.format("%X", targetAddr) .. "\n\n" ..
        "🌟 최종 도출 오프셋:\n" .. toHexOffset(offset) .. "\n\n" ..
        "👇 저에게 이 줄을 그대로 적어주세요! 👇\n\n" ..
        toHexOffset(offset)
    )
    if autoCloseUI then shouldCloseMenu = true end
end

-- 통조림 주변의 고유 AOB 마스터키 추출기
function MemoryDumper()
    local count = gg.getResultsCount()
    if count ~= 2 then
        gg.alert("❌ 현재 GG 검색창에 " .. count .. "개의 메모리가 남아있습니다.\n수동 수치 검색으로 '통조림 주소'를 딱 2개만 좁혀 놓은 상태에서 이 메뉴를 켜주세요!")
        return
    end
    
    local results = gg.getResults(2)
    local cfAddr = results[1].address
    
    local readTable = {}
    for i = -8, 1 do
        table.insert(readTable, {address = cfAddr + (i * 4), flags = gg.TYPE_DWORD})
    end
    
    local values = gg.getValues(readTable)
    if not values[1].value then
        gg.alert("메모리 값을 읽지 못했습니다.")
        return
    end
    
    local resultStr = ""
    for i, v in ipairs(values) do
        local offset = (i - 9) * 4
        local prefix = ""
        if offset == 0 then
            prefix = "⭐️ [통조림]: "
        elseif offset == 4 then
            prefix = "🔑 [암호키]: "
        else
            prefix = "[" .. offset .. "]: "
        end
        resultStr = resultStr .. prefix .. v.value .. "\n"
    end
    
    gg.alert(
        "🎉 마스터키 배열 구조 분석 완료!\n\n" ..
        resultStr .. "\n\n" ..
        "👆 구조 확인을 위해 주변 번호를 덤프했습니다."
    )
    
    gg.clearResults()
    gg.loadResults(results)
    if autoCloseUI then shouldCloseMenu = true end
end

function Exit()
    gg.alert("스크립트를 종료합니다!")
    os.exit()
end

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        isMenuAlive = true
    end
    if isMenuAlive then
        Main()
        isMenuAlive = false
    end
    gg.sleep(100)
end
