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
            print('^3Cargados ' .. #results .. ' NPCs^7')
            TriggerClientEvent('npc:updateAll', -1, storedNPCs)
        end
    end)
end

-- Crear NPC
RegisterServerEvent('npc:create')
AddEventHandler('npc:create', function(npcData)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)

    MySQL.Async.insert('INSERT INTO npc_management (identifier, data) VALUES (@identifier, @data)', {
        ['@identifier'] = identifier,
        ['@data'] = json.encode(npcData)
    }, function(id)
        if id then
            storedNPCs[id] = npcData
            print('^2NPC creado con ID: ' .. id .. '^7')
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
            print('^1NPC eliminado con ID: ' .. id .. '^7')
            TriggerClientEvent('npc:removeNPC', -1, id)
            TriggerClientEvent('npc:notify', source, 'NPC eliminado correctamente')
        else
            TriggerClientEvent('npc:notify', source, 'Error al eliminar el NPC')
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
            print('^3NPC actualizado con ID: ' .. id .. '^7')
            TriggerClientEvent('npc:updateSingle', -1, id, npcData)
            TriggerClientEvent('npc:notify', source, 'NPC actualizado correctamente')
        else
            TriggerClientEvent('npc:notify', source, 'Error al actualizar el NPC')
        end
    end)
end)

-- Debug: Comando para recargar NPCs
RegisterCommand('reloadnpcs', function(source, args)
    LoadAllNPCs()
    if source > 0 then
        TriggerClientEvent('npc:notify', source, 'NPCs recargados')
    end
end)

-- Debug: Imprimir NPCs almacenados
RegisterCommand('listnpcs', function(source, args)
    print('^3NPCs almacenados:^7')
    for id, data in pairs(storedNPCs) do
        print(string.format('ID: %s, Nombre: %s, Modelo: %s', id, data.name, data.model))
    end
    if source > 0 then
        TriggerClientEvent('npc:notify', source, 'Lista de NPCs impresa en consola')
    end
end)