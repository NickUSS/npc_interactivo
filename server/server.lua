local storedNPCs = {}

-- Inicialización de la base de datos
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `npc_management` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) DEFAULT NULL,
            `data` longtext DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        )
    ]], {}, function(success)
        if success then
            print('^2NPC Management: Base de datos inicializada^7')
            LoadAllNPCs()
        end
    end)
end)

-- Cargar todos los NPCs
function LoadAllNPCs()
    MySQL.Async.fetchAll('SELECT * FROM npc_management', {}, function(results)
        if results then
            for _, v in ipairs(results) do
                storedNPCs[v.id] = json.decode(v.data)
            end
            TriggerClientEvent('npc:updateAll', -1, storedNPCs)
        end
    end)
end

-- Crear NPC
RegisterServerEvent('npc:create')
AddEventHandler('npc:create', function(npcData)
    local source = source
    MySQL.Async.insert('INSERT INTO npc_management (identifier, data) VALUES (@identifier, @data)', {
        ['@identifier'] = GetPlayerIdentifier(source, 0),
        ['@data'] = json.encode(npcData)
    }, function(id)
        if id then
            storedNPCs[id] = npcData
            TriggerClientEvent('npc:updateSingle', -1, id, npcData)
            TriggerClientEvent('npc:notify', source, 'NPC creado correctamente')
        end
    end)
end)

-- Eliminar NPC
RegisterServerEvent('npc:delete')
AddEventHandler('npc:delete', function(id)
    local source = source
    MySQL.Async.execute('DELETE FROM npc_management WHERE id = @id', {
        ['@id'] = id
    }, function(rowsChanged)
        if rowsChanged > 0 then
            storedNPCs[id] = nil
            TriggerClientEvent('npc:removeNPC', -1, id)
            TriggerClientEvent('npc:notify', source, 'NPC eliminado correctamente')
        end
    end)
end)

-- Actualizar NPC
RegisterServerEvent('npc:update')
AddEventHandler('npc:update', function(id, npcData)
    local source = source
    MySQL.Async.execute('UPDATE npc_management SET data = @data WHERE id = @id', {
        ['@id'] = id,
        ['@data'] = json.encode(npcData)
    }, function(rowsChanged)
        if rowsChanged > 0 then
            storedNPCs[id] = npcData
            TriggerClientEvent('npc:updateSingle', -1, id, npcData)
            TriggerClientEvent('npc:notify', source, 'NPC actualizado correctamente')
        end
    end)
end)

-- Verificar permisos (ahora siempre devuelve true)
RegisterServerEvent('npc:checkPermission')
AddEventHandler('npc:checkPermission', function()
    local source = source
    TriggerClientEvent('npc:permissionResponse', source, true)
end)