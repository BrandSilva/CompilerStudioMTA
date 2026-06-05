------------------------------------------------------------------------------------------------
--
--  PROJECT:         Trident Sky Company
--  VERSION:         3.0
--  FILE:            compilerC.lua
--  PURPOSE:         Automatic Compilation Tool
--  DEVELOPERS:      [BranD] - Lead Developer
--  CONTACT:         tridentskycompany@gmail.com | Discord: BrandSilva
--  COPYRIGHT:       © 2026 Brando Silva All rights reserved.
--                   This software is protected by copyright laws.
--                   Unauthorized distribution or modification is strictly prohibited.
--
------------------------------------------------------------------------------------------------

local compilationBrowser = nil
local compilationGui = nil
local isMinimized = false
local browserReady = false
local lastScriptsData = nil
local savedLanguage = "en"

function applyLanguageToBrowser()
    if (compilationBrowser and isElement(compilationBrowser) and browserReady) then
        executeBrowserJavascript(compilationBrowser, 'loadLanguage("' .. savedLanguage .. '");')
    end
end

function onSetLanguage(lang)
    if (type(lang) == "string" and lang ~= "") then
        savedLanguage = lang
    end
end
addEvent("TScompiler.setLanguage", true)
addEventHandler("TScompiler.setLanguage", root, onSetLanguage)

function buildScriptsJsArray(scripts)
    local jsArray = "["
    for i, script in ipairs(scripts) do
        if (i > 1) then
            jsArray = jsArray .. ","
        end

        local clientFiles = "["
        if (script.clientFiles) then
            for j, file in ipairs(script.clientFiles) do
                if (j > 1) then
                    clientFiles = clientFiles .. ","
                end
                clientFiles = clientFiles .. '"' .. tostring(file) .. '"'
            end
        end
        clientFiles = clientFiles .. "]"

        local serverFiles = "["
        if (script.serverFiles) then
            for j, file in ipairs(script.serverFiles) do
                if (j > 1) then
                    serverFiles = serverFiles .. ","
                end
                serverFiles = serverFiles .. '"' .. tostring(file) .. '"'
            end
        end
        serverFiles = serverFiles .. "]"

        local companions = "{"
        local firstCompanion = true
        if (script.companions) then
            for compiledPath, sourcePath in pairs(script.companions) do
                if (not firstCompanion) then
                    companions = companions .. ","
                end
                firstCompanion = false
                companions = companions .. '"' .. tostring(compiledPath) .. '":"' .. tostring(sourcePath) .. '"'
            end
        end
        companions = companions .. "}"

        jsArray = jsArray .. '{'
        jsArray = jsArray .. 'name:"' .. tostring(script.name) .. '",'
        jsArray = jsArray .. 'clientFiles:' .. clientFiles .. ','
        jsArray = jsArray .. 'serverFiles:' .. serverFiles .. ','
        jsArray = jsArray .. 'companions:' .. companions .. ','
        jsArray = jsArray .. 'hasProtection:' .. (script.hasProtection and "true" or "false") .. ','
        jsArray = jsArray .. 'clientCompiled:' .. (script.clientCompiled and "true" or "false")
        jsArray = jsArray .. '}'
    end
    jsArray = jsArray .. "]"
    return jsArray
end

function pushScriptsToBrowser()
    if (not compilationBrowser or not browserReady) then
        return
    end

    if (not isElement(compilationBrowser)) then
        return
    end

    if (not lastScriptsData) then
        return
    end

    local jsArray = buildScriptsJsArray(lastScriptsData)
    executeBrowserJavascript(compilationBrowser, "loadScriptsData(" .. jsArray .. ");")
end

function createCompilationPanel()
    if (compilationGui) then
        return true
    end

    local screenW, screenH = guiGetScreenSize()
    compilationGui = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)

    if (compilationGui) then
        compilationBrowser = guiGetBrowser(compilationGui)
        addEventHandler("onClientBrowserCreated", compilationGui, onBrowserCreated)
        addEventHandler("onClientBrowserDocumentReady", compilationGui, onBrowserDocumentReady)
        guiSetVisible(compilationGui, true)
        guiBringToFront(compilationGui)
        showCursor(true)
        return true
    end

    return false
end

function onBrowserCreated()
    if (compilationBrowser) then
        loadBrowserURL(compilationBrowser, "http://mta/local/index.html")
        focusBrowser(compilationBrowser)
    end
end

function onBrowserDocumentReady()
    browserReady = true
    applyLanguageToBrowser()
    pushScriptsToBrowser()
end

function openCompilationPanel(scripts)
    if (scripts and #scripts > 0) then
        lastScriptsData = scripts
    end

    if (not compilationGui) then
        createCompilationPanel()
    else
        guiSetVisible(compilationGui, true)
        guiBringToFront(compilationGui)
        showCursor(true)
        focusBrowser(compilationBrowser)
        isMinimized = false
        applyLanguageToBrowser()
        pushScriptsToBrowser()
    end
end

function closePanel()
    if (compilationGui) then
        guiSetVisible(compilationGui, false)
        showCursor(false)
        isMinimized = true
    end
end
addEvent("TScompiler.closePanel", true)
addEventHandler("TScompiler.closePanel", root, closePanel)

function minimizePanel()
    if (compilationGui and guiGetVisible(compilationGui)) then
        guiSetVisible(compilationGui, false)
        showCursor(false)
        isMinimized = true
    end
end
addEvent("TScompiler.minimizePanel", true)
addEventHandler("TScompiler.minimizePanel", root, minimizePanel)

function restoreCompilationPanel()
    if (compilationGui and isMinimized) then
        guiSetVisible(compilationGui, true)
        guiBringToFront(compilationGui)
        showCursor(true)
        focusBrowser(compilationBrowser)
        isMinimized = false
    end
end

function refreshScriptsList()
    triggerServerEvent("TScompiler.requestScriptsList", localPlayer)
end
addEvent("TScompiler.refreshScriptsList", true)
addEventHandler("TScompiler.refreshScriptsList", root, refreshScriptsList)

function requestScriptsList()
    triggerServerEvent("TScompiler.requestScriptsList", localPlayer)
end
addEvent("TScompiler.requestScriptsList", true)
addEventHandler("TScompiler.requestScriptsList", root, requestScriptsList)

function parseCompilationTasks(data)
    local compilationTasks = {}

    if (not data or type(data) ~= "string") then
        return compilationTasks
    end

    for taskStr in string.gmatch(data, "{(.-)}") do
        local task = {}

        for key, value in string.gmatch(taskStr, '"([%w_]+)"%s*:%s*([^,}]+)') do
            value = string.gsub(value, "^%s*(.-)%s*$", "%1")
            value = string.gsub(value, '"', "")
            if (value == "true") then
                task[key] = true
            elseif (value == "false") then
                task[key] = false
            else
                task[key] = value
            end
        end

        if (task.resourceName) then
            table.insert(compilationTasks, task)
        end
    end

    return compilationTasks
end

function startCompilation(data)
    local compilationTasks = parseCompilationTasks(data)

    if (#compilationTasks > 0) then
        triggerServerEvent("TScompiler.startCompilation", localPlayer, compilationTasks)
    end
end
addEvent("TScompiler.startCompilation", true)
addEventHandler("TScompiler.startCompilation", root, startCompilation)

function loadScriptsFromServer(scripts)
    if (scripts and #scripts > 0) then
        lastScriptsData = scripts
    end
    pushScriptsToBrowser()
end

function updateCompilationStatus(statusData)
    if (not compilationBrowser or not isElement(compilationBrowser) or not guiGetVisible(compilationGui)) then
        return
    end

    if (type(statusData) ~= "table") then
        return
    end

    local statusType = tostring(statusData.type or "")
    local message = tostring(statusData.message or "")
    message = message:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "")
    local total = tonumber(statusData.total) or 0
    local current = tonumber(statusData.current) or 0

    local js = 'updateCompilationProgress({type:"' .. statusType .. '",message:"' .. message .. '",total:' .. total .. ',current:' .. current .. '});'
    executeBrowserJavascript(compilationBrowser, js)
end

function onOpenPanel(scripts)
    openCompilationPanel(scripts)
end
addEvent("TScompiler.openPanel", true)
addEventHandler("TScompiler.openPanel", localPlayer, onOpenPanel)

function onScriptsReceived(scripts)
    loadScriptsFromServer(scripts)
end
addEvent("TScompiler.loadScripts", true)
addEventHandler("TScompiler.loadScripts", localPlayer, onScriptsReceived)

function onStatusUpdate(statusData)
    updateCompilationStatus(statusData)
end
addEvent("TScompiler.updateStatus", true)
addEventHandler("TScompiler.updateStatus", localPlayer, onStatusUpdate)
