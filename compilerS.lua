------------------------------------------------------------------------------------------------
--
--  PROJECT:         Trident Sky Company
--  VERSION:         3.0
--  FILE:            compilerS.lua
--  PURPOSE:         Automatic Compilation Tool
--  DEVELOPERS:      [BranD] - Lead Developer
--  CONTACT:         tridentskycompany@gmail.com | Discord: BrandSilva
--  COPYRIGHT:       © 2026 Brando Silva All rights reserved.
--                   This software is protected by copyright laws.
--                   Unauthorized distribution or modification is strictly prohibited.
--
------------------------------------------------------------------------------------------------

local compilationQueue = {}
local isCompiling = false
local currentCompilation = nil
local resourcesToRestart = {}
local permissionACL = "Admin" --[[you admin ACL here]]

function isPlayerInACLGroup(player, ...)
	if (not player or not ...) then 
        return false 
    end
	if (not isElement(player) or getElementType(player) ~= "player") then 
        return false 
    end
	local account = getPlayerAccount(player)
	if (isGuestAccount(account)) then return false end
	
	local acl = {...}
	if (#acl == 1) then	
		return isObjectInACLGroup("user."..getAccountName(account), aclGetGroup(acl[1])) or false
	else
		for i,acl in ipairs(acl) do
			if (isObjectInACLGroup("user."..getAccountName(account), aclGetGroup(acl))) then
				return true
			end
		end
		return false
	end
end

function hasPermission(player)
    if (not player or not isElement(player)) then 
        return false 
    end
    local admin = isPlayerInACLGroup(player, permissionACL)
    if (admin) then
        return true
    end
    return false
end

function isPlayerOnline(player)
    return player and isElement(player) and getElementType(player) == "player"
end

local spamTimers = {}

function isSpamming(player, key, cooldown)
    cooldown = cooldown or 500
    if (not isElement(player)) then
        return true
    end
    if (not spamTimers[player]) then
        spamTimers[player] = {}
    end
    local now = getTickCount()
    local last = spamTimers[player][key]
    if (last and (now - last) < cooldown) then
        return true
    end
    spamTimers[player][key] = now
    return false
end

function onCompilerPlayerQuit()
    if (spamTimers[source]) then
        spamTimers[source] = nil
    end
end
addEventHandler("onPlayerQuit", root, onCompilerPlayerQuit)

function getResourceScripts(resourceName, includeServer)
    local resource = getResourceFromName(resourceName)
    if (not resource) then return nil end
    
    local scripts = { clientFiles = {}, serverFiles = {}, hasProtection = false, clientCompiled = true, companions = {} }
    local metaFile = xmlLoadFile(":" .. resourceName .. "/meta.xml")
    if (not metaFile) then return scripts end

    for i, node in ipairs(xmlNodeGetChildren(metaFile)) do
        if (xmlNodeGetName(node) == "script") then
            local scriptPath = xmlNodeGetAttribute(node, "src")
            local scriptType = xmlNodeGetAttribute(node, "type") or "server"
            local isProtected = xmlNodeGetAttribute(node, "protected")
            local hasCache = xmlNodeGetAttribute(node, "cache")

            if (scriptPath) then
                local included = false
                if (scriptType == "client") then
                    table.insert(scripts.clientFiles, scriptPath)
                    if (isProtected == "true" or hasCache == "false") then scripts.hasProtection = true end
                    if (not string.find(scriptPath, "c$")) then
                        scripts.clientCompiled = false
                    end
                    included = true
                elseif (scriptType == "server" and includeServer) then
                    table.insert(scripts.serverFiles, scriptPath)
                    included = true
                end

                if (included and string.find(scriptPath, "c$")) then
                    local sourcePath = string.sub(scriptPath, 1, -2)
                    if (sourcePath ~= scriptPath and fileExists(":" .. resourceName .. "/" .. sourcePath)) then
                        scripts.companions[scriptPath] = sourcePath
                    end
                end
            end
        end
    end
    
    xmlUnloadFile(metaFile)
    return scripts
end

function getAllResourcesData()
    local resourcesData = {}
    for i, resource in ipairs(getResources()) do
        local resourceName = getResourceName(resource)
        if (resourceName) then
            local scriptData = getResourceScripts(resourceName, true)
            if (scriptData and (#scriptData.clientFiles > 0 or #scriptData.serverFiles > 0)) then
                scriptData.name = resourceName
                table.insert(resourcesData, scriptData)
            end
        end
    end
    return resourcesData
end

function requestScriptsList()
    if (not client) then
        return
    end
    if (isSpamming(client, "scriptsList", 1000)) then
        return
    end
    if (not hasPermission(client)) then
        outputChatBox("Access denied: Insufficient permissions", client, 255, 0, 0)
        return
    end
    local scriptsData = getAllResourcesData()
    triggerClientEvent(client, "TScompiler.loadScripts", client, scriptsData)
end
addEvent("TScompiler.requestScriptsList", true)
addEventHandler("TScompiler.requestScriptsList", root, requestScriptsList)

function runCompilation(player, compilationTasks)
    if (isCompiling) then
        outputChatBox("Cannot start compilation: Another compilation process is already running. Please wait for it to finish.", player, 255, 165, 0)
        return
    end

    if (not compilationTasks or type(compilationTasks) ~= "table" or #compilationTasks == 0) then
        outputChatBox("Error: Invalid compilation tasks", player, 255, 0, 0)
        return
    end

    isCompiling = true
    compilationQueue = {}
    resourcesToRestart = {}

    for _, task in ipairs(compilationTasks) do
        if (task.resourceName == "ALL_SERVER_SCRIPTS") then
            local allResources = getAllResourcesData()
            for _, resourceData in ipairs(allResources) do
                if (task.compileClient and #resourceData.clientFiles > 0) then
                    for _, scriptPath in ipairs(resourceData.clientFiles) do
                        table.insert(compilationQueue, {
                            player = player,
                            resourceName = resourceData.name,
                            scriptPath = scriptPath,
                            scriptType = "client",
                            enableProtection = task.enableProtection,
                            restartAfterCompile = task.restartAfterCompile
                        })

                        if (task.restartAfterCompile and not resourcesToRestart[resourceData.name]) then
                            resourcesToRestart[resourceData.name] = true
                        end
                    end
                end

                if (task.compileServer and #resourceData.serverFiles > 0) then
                    for _, scriptPath in ipairs(resourceData.serverFiles) do
                        table.insert(compilationQueue, {
                            player = player,
                            resourceName = resourceData.name,
                            scriptPath = scriptPath,
                            scriptType = "server",
                            enableProtection = false,
                            restartAfterCompile = task.restartAfterCompile
                        })

                        if (task.restartAfterCompile and not resourcesToRestart[resourceData.name]) then
                            resourcesToRestart[resourceData.name] = true
                        end
                    end
                end
            end
        elseif (task.resourceName and (task.compileClient or task.compileServer)) then
            local scriptData = getResourceScripts(task.resourceName, task.compileServer)
            if (scriptData) then
                if (task.compileClient and #scriptData.clientFiles > 0) then
                    for _, scriptPath in ipairs(scriptData.clientFiles) do
                        table.insert(compilationQueue, {
                            player = player,
                            resourceName = task.resourceName,
                            scriptPath = scriptPath,
                            scriptType = "client",
                            enableProtection = task.enableProtection,
                            restartAfterCompile = task.restartAfterCompile
                        })

                        if (task.restartAfterCompile and not resourcesToRestart[task.resourceName]) then
                            resourcesToRestart[task.resourceName] = true
                        end
                    end
                end

                if (task.compileServer and #scriptData.serverFiles > 0) then
                    for _, scriptPath in ipairs(scriptData.serverFiles) do
                        table.insert(compilationQueue, {
                            player = player,
                            resourceName = task.resourceName,
                            scriptPath = scriptPath,
                            scriptType = "server",
                            enableProtection = false,
                            restartAfterCompile = task.restartAfterCompile
                        })

                        if (task.restartAfterCompile and not resourcesToRestart[task.resourceName]) then
                            resourcesToRestart[task.resourceName] = true
                        end
                    end
                end
            end
        end
    end

    if (#compilationQueue == 0) then
        isCompiling = false
        outputChatBox("No files to compile", player, 255, 165, 0)
        return
    end

    if (isPlayerOnline(player)) then
        triggerClientEvent(player, "TScompiler.updateStatus", player, {
            type = "status",
            message = "Starting compilation of " .. #compilationQueue .. " files..."
        })
    end

    processNextCompilation()
end

function startCompilation(compilationTasks)
    if (not client) then
        return
    end
    if (isSpamming(client, "compile", 1500)) then
        return
    end
    if (not hasPermission(client)) then
        outputChatBox("Access denied: Insufficient permissions", client, 255, 0, 0)
        return
    end
    runCompilation(client, compilationTasks)
end
addEvent("TScompiler.startCompilation", true)
addEventHandler("TScompiler.startCompilation", root, startCompilation)

function processNextCompilation()
    if (#compilationQueue == 0) then
        if (currentCompilation and currentCompilation.player and isPlayerOnline(currentCompilation.player)) then
            triggerClientEvent(currentCompilation.player, "TScompiler.updateStatus", currentCompilation.player, {
                type = "complete",
                message = "All files compiled successfully"
            })
            outputChatBox("Compilation completed successfully", currentCompilation.player, 0, 255, 0)
            
            setTimer(function()
                local currentResourceName = getResourceName(getThisResource())
                for resourceName, _ in pairs(resourcesToRestart) do
                    if (resourceName == currentResourceName) then
                        if (currentCompilation and currentCompilation.player and isPlayerOnline(currentCompilation.player)) then
                            outputChatBox("Compiler script compiled but will not restart to avoid interrupting the process", currentCompilation.player, 255, 255, 0)
                        end
                    else
                        local resource = getResourceFromName(resourceName)
                        if (resource and getResourceState(resource) == "running") then
                            if (currentCompilation and currentCompilation.player and isPlayerOnline(currentCompilation.player)) then
                                outputChatBox("Script " .. resourceName .. " restarting automatically", currentCompilation.player, 0, 255, 255)
                            end
                            restartResource(resource)
                        end
                    end
                end
                resourcesToRestart = {}
            end, 1000, 1)
        end
        isCompiling = false
        currentCompilation = nil
        return
    end
    
    currentCompilation = table.remove(compilationQueue, 1)
    compileScript(currentCompilation)
end

function compileScript(compilationData)
    local player = compilationData.player
    local resourceName = compilationData.resourceName
    local scriptPath = compilationData.scriptPath

    if (not getResourceFromName(resourceName) or string.find(scriptPath, "%.%.")) then
        if (isPlayerOnline(player)) then
            outputChatBox("Error: Invalid resource or path - " .. tostring(resourceName), player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 100, 1)
        return
    end

    local fullPath = ":" .. resourceName .. "/" .. scriptPath

    local actualPath = fullPath
    if (string.find(scriptPath, "c$")) then
        local pathParts = split(scriptPath, ".")
        local nameWithoutExt = table.concat(pathParts, ".", 1, #pathParts - 1)
        local extension = pathParts[#pathParts]
        local originalExtension = string.sub(extension, 1, -2)
        local originalPath = nameWithoutExt .. "." .. originalExtension
        local originalFullPath = ":" .. resourceName .. "/" .. originalPath
        
        if (fileExists(originalFullPath)) then
            actualPath = originalFullPath
            if (isPlayerOnline(player)) then
                outputChatBox("Found updated source file: " .. originalPath .. ", compiling from source", player, 0, 255, 255)
            end
        end
    end
    
    if (not fileExists(actualPath)) then
        if (isPlayerOnline(player)) then
            outputChatBox("Error: File does not exist - " .. (actualPath == fullPath and scriptPath or string.match(actualPath, "([^/]+)$")), player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 100, 1)
        return
    end
    
    local fileHandle = fileOpen(actualPath, true)
    if (not fileHandle) then
        if (isPlayerOnline(player)) then
            outputChatBox("Error: Cannot open file - " .. (actualPath == fullPath and scriptPath or string.match(actualPath, "([^/]+)$")), player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 100, 1)
        return
    end
    
    local fileContent = fileRead(fileHandle, fileGetSize(fileHandle))
    fileClose(fileHandle)
    
    if (string.byte(fileContent, 1) == 28) then
        if (isPlayerOnline(player)) then
            outputChatBox("File already compiled: " .. scriptPath, player, 255, 165, 0)
        end
        setTimer(processNextCompilation, 100, 1)
        return
    end
    
    if (isPlayerOnline(player)) then
        triggerClientEvent(player, "TScompiler.updateStatus", player, {
            type = "progress",
            current = 1,
            total = #compilationQueue + 1,
            message = "Compiling: " .. scriptPath
        })
    end
    
    local success = fetchRemote("https://luac.mtasa.com/?compile=1&debug=0&obfuscate=3", onCompilationResponse, fileContent, true, compilationData)
    
    if (not success and isPlayerOnline(player)) then
        outputChatBox("Error: Failed to start compilation for " .. scriptPath, player, 255, 0, 0)
        setTimer(processNextCompilation, 150, 1)
    end
end

function onCompilationResponse(responseData, errno, compilationData)
    local player = compilationData.player
    local resourceName = compilationData.resourceName
    local scriptPath = compilationData.scriptPath
    local scriptType = compilationData.scriptType
    local enableProtection = compilationData.enableProtection
    
    if (errno ~= 0 or not responseData) then
        if (isPlayerOnline(player)) then
            outputChatBox("Error: Compilation failed for " .. scriptPath, player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 150, 1)
        return
    end
    
    if (string.find(responseData, "ERROR")) then
        if (isPlayerOnline(player)) then
            outputChatBox("Compilation error in " .. scriptPath .. ": " .. responseData, player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 150, 1)
        return
    end
    
    local pathParts = split(scriptPath, ".")
    local nameWithoutExt = table.concat(pathParts, ".", 1, #pathParts - 1)
    local extension = pathParts[#pathParts]
    
    local compiledExtension = extension .. "c"
    if (string.find(extension, "c$")) then
        compiledExtension = extension
    end
    
    local compiledPath = nameWithoutExt .. "." .. compiledExtension
    local fullCompiledPath = ":" .. resourceName .. "/" .. compiledPath
    
    if (fileExists(fullCompiledPath)) then fileDelete(fullCompiledPath) end
    
    local compiledFile = fileCreate(fullCompiledPath)
    if (not compiledFile) then
        if (isPlayerOnline(player)) then
            outputChatBox("Error: Cannot create compiled file - " .. compiledPath, player, 255, 0, 0)
        end
        setTimer(processNextCompilation, 150, 1)
        return
    end
    
    fileWrite(compiledFile, responseData)
    fileClose(compiledFile)
    
    if (not updateMetaXML(resourceName, scriptPath, compiledPath, scriptType, enableProtection) and isPlayerOnline(player)) then
        outputChatBox("Warning: Failed to update meta.xml for " .. scriptPath, player, 255, 165, 0)
    end
    
    if (isPlayerOnline(player)) then
        outputChatBox("Successfully compiled: " .. resourceName .. ":" .. scriptPath, player, 0, 255, 0)
    end
    
    setTimer(processNextCompilation, 150, 1)
end

function updateMetaXML(resourceName, oldFileName, newFileName, scriptType, enableProtection)
    local metaFile = xmlLoadFile(":" .. resourceName .. "/meta.xml")
    if (not metaFile) then return false end
    
    for i, node in ipairs(xmlNodeGetChildren(metaFile)) do
        if (xmlNodeGetName(node) == "script") then
            local scriptSrc = xmlNodeGetAttribute(node, "src")
            local nodeType = xmlNodeGetAttribute(node, "type")
            
            if (scriptSrc == oldFileName and nodeType == scriptType) then
                xmlNodeSetAttribute(node, "src", newFileName)
                
                if (scriptType == "client") then
                    local currentProtected = xmlNodeGetAttribute(node, "protected")
                    local currentCache = xmlNodeGetAttribute(node, "cache")
                    
                    if (enableProtection) then
                        if (currentProtected) then xmlNodeSetAttribute(node, "protected", nil) end
                        xmlNodeSetAttribute(node, "cache", "false")
                    else
                        if (currentProtected) then xmlNodeSetAttribute(node, "protected", nil) end
                        if (currentCache) then xmlNodeSetAttribute(node, "cache", nil) end
                    end
                end
                
                xmlSaveFile(metaFile)
                xmlUnloadFile(metaFile)
                return true
            end
        end
    end
    
    xmlUnloadFile(metaFile)
    return false
end

-- /compiler                                  -> opens the panel (no arguments)
-- /compiler <resource> [restart] [protect] [server]
--     restart  : 1 = restart the resource after compiling (default 0)
--     protect  : 1 = mark client scripts as protected/no-cache (default 0)
--     server   : 1 = also compile server-side scripts (default 0)
-- Example: /compiler TSchat 1 0 0   |   /compiler all 1 1 1
function compilerCommand(player, cmd, resourceName, restartArg, protectArg, serverArg)
    if (not hasPermission(player)) then
        outputChatBox("Access denied: Insufficient permissions", player, 255, 0, 0)
        return
    end

    if (not resourceName or resourceName == "") then
        local scriptsData = getAllResourcesData()
        triggerClientEvent(player, "TScompiler.openPanel", player, scriptsData)
        return
    end

    if (isCompiling) then
        outputChatBox("A compilation is already running. Please wait for it to finish.", player, 255, 165, 0)
        return
    end

    local doRestart = (restartArg == "1")
    local doProtect = (protectArg == "1")
    local doServer = (serverArg == "1")

    local task
    if (string.lower(resourceName) == "all") then
        task = {
            resourceName = "ALL_SERVER_SCRIPTS",
            compileClient = true,
            compileServer = doServer,
            enableProtection = doProtect,
            restartAfterCompile = doRestart
        }
    else
        if (not getResourceFromName(resourceName)) then
            outputChatBox("Resource not found: " .. resourceName, player, 255, 0, 0)
            return
        end

        task = {
            resourceName = resourceName,
            compileClient = true,
            compileServer = doServer,
            enableProtection = doProtect,
            restartAfterCompile = doRestart
        }
    end

    outputChatBox("Compiling '" .. resourceName .. "' | restart: " .. (doRestart and "yes" or "no") .. " | protect: " .. (doProtect and "yes" or "no") .. " | server: " .. (doServer and "yes" or "no"), player, 0, 200, 255)
    runCompilation(player, { task })
end
addCommandHandler("compiler", compilerCommand)