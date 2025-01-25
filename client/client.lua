local display = false
local npcs = {}

-- Función de debug
function DumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '['..k..'] = ' .. DumpTable(v, nb + 1) .. ',\n'
        end

        for i = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end

-- Función para mostrar/ocultar la UI
function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = bool and "show" or "hide"
    })
end

-- Función para mostrar notificaciones
function ShowNotification(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end

-- Comando para abrir el menú
RegisterCommand('npcmanager', function()
    SetDisplay(true)
end)

-- Callbacks NUI
RegisterNUICallback('closeMenu', function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('createNPC', function(data, cb)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local playerHeading = GetEntityHeading(PlayerPedId())
    
    -- Obtener la altura del suelo
    local ground, groundZ = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, false)
    local finalZ = ground and groundZ or playerCoords.z
    
    local npcData = {
        model = data.model,
        coords = vector4(playerCoords.x, playerCoords.y, finalZ, playerHeading),
        scenario = data.scenario,
        name = data.name
    }

    print('Creando NPC:', json.encode(npcData))
    TriggerServerEvent('npc:create', npcData)
    cb('ok')
end)

RegisterNUICallback('teleportToNPC', function(data, cb)
    local npcData = npcs[tonumber(data.id)]
    if npcData and npcData.coords then
        SetEntityCoords(PlayerPedId(), npcData.coords.x, npcData.coords.y, npcData.coords.z)
    end
    cb('ok')
end)

RegisterNUICallback('deleteNPC', function(data, cb)
    TriggerServerEvent('npc:delete', tonumber(data.id))
    cb('ok')
end)

-- Función para spawnear NPC
function SpawnNPC(id, data)
    if npcs[id] and npcs[id].entity then
        DeleteEntity(npcs[id].entity)
    end

    local hash = GetHashKey(data.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(1) end

    -- Ajustar altura
    local x, y, z = data.coords.x, data.coords.y, data.coords.z
    local ground, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, false)
    local finalZ = ground and groundZ + 1.0 or z + 1.0

    local ped = CreatePed(4, hash, x, y, finalZ, data.coords.w, false, true)
    SetEntityHeading(ped, data.coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if data.scenario then
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
    end

    npcs[id] = {
        name = data.name,
        model = data.model,
        scenario = data.scenario,
        coords = {
            x = x,
            y = y,
            z = finalZ,
            w = data.coords.w
        },
        entity = ped
    }
end

-- Eventos
RegisterNetEvent('npc:updateAll')
AddEventHandler('npc:updateAll', function(serverNPCs)
    print('Datos recibidos del servidor:', json.encode(serverNPCs))
    
    -- Limpiar NPCs existentes
    for id, data in pairs(npcs) do
        if data.entity then
            DeleteEntity(data.entity)
        end
    end

    -- Actualizar NPCs
    npcs = {}
    for id, data in pairs(serverNPCs) do
        if data then
            SpawnNPC(id, data)
        end
    end

    -- Preparar datos para la UI
    local uiData = {}
    for id, data in pairs(npcs) do
        uiData[id] = {
            name = data.name,
            model = data.model,
            scenario = data.scenario,
            coords = data.coords
        }
    end

    -- Enviar datos a la UI
    SendNUIMessage({
        type = "updateNPCs",
        npcs = uiData
    })
end)

RegisterNetEvent('npc:updateSingle')
AddEventHandler('npc:updateSingle', function(id, data)
    if data then
        SpawnNPC(id, data)
        
        -- Preparar datos para la UI
        local uiData = {}
        for npcId, npcData in pairs(npcs) do
            uiData[npcId] = {
                name = npcData.name,
                model = npcData.model,
                scenario = npcData.scenario,
                coords = npcData.coords
            }
        end

        SendNUIMessage({
            type = "updateNPCs",
            npcs = uiData
        })
    end
end)

RegisterNetEvent('npc:removeNPC')
AddEventHandler('npc:removeNPC', function(id)
    if npcs[id] then
        if npcs[id].entity then
            DeleteEntity(npcs[id].entity)
        end
        npcs[id] = nil
        
        -- Preparar datos para la UI
        local uiData = {}
        for npcId, npcData in pairs(npcs) do
            if npcData then
                uiData[npcId] = {
                    name = npcData.name,
                    model = npcData.model,
                    scenario = npcData.scenario,
                    coords = npcData.coords
                }
            end
        end

        SendNUIMessage({
            type = "updateNPCs",
            npcs = uiData
        })
    end
end)

RegisterNetEvent('npc:notify')
AddEventHandler('npc:notify', function(message)
    ShowNotification(message)
end)