let npcs = {};

window.addEventListener('message', function(event) {
    switch (event.data.type) {
        case 'show':
            document.getElementById('npc-manager').style.display = 'flex';
            break;
        case 'hide':
            document.getElementById('npc-manager').style.display = 'none';
            break;
        case 'updateNPCs':
            console.log('Datos recibidos (raw):', event.data.npcs);
            if (event.data.npcs) {
                // Convertir los datos a un objeto manejable
                npcs = {};
                Object.entries(event.data.npcs).forEach(([key, value]) => {
                    if (value && value.name) {
                        npcs[key] = {
                            name: value.name,
                            model: value.model,
                            scenario: value.scenario,
                            coords: value.coords
                        };
                    }
                });
                console.log('NPCs procesados:', npcs);
                updateNPCList();
            }
            break;
    }
});

// Botón cerrar
document.getElementById('closeMenu').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
});

// Botones del menú principal
document.getElementById('createNPC').addEventListener('click', () => {
    document.getElementById('mainMenu').style.display = 'none';
    document.getElementById('createMenu').style.display = 'block';
});

document.getElementById('listNPCs').addEventListener('click', () => {
    document.getElementById('mainMenu').style.display = 'none';
    document.getElementById('listMenu').style.display = 'block';
    updateNPCList();
});

// Botones de volver
document.getElementById('backFromCreate').addEventListener('click', () => {
    document.getElementById('createMenu').style.display = 'none';
    document.getElementById('mainMenu').style.display = 'block';
    // Limpiar el campo de nombre
    document.getElementById('npcName').value = '';
});

document.getElementById('backFromList').addEventListener('click', () => {
    document.getElementById('listMenu').style.display = 'none';
    document.getElementById('mainMenu').style.display = 'block';
});

// Crear NPC
document.getElementById('confirmCreate').addEventListener('click', () => {
    const model = document.getElementById('npcModel').value;
    const scenario = document.getElementById('npcScenario').value;
    const name = document.getElementById('npcName').value;

    if (!name) {
        return;
    }

    const npcData = {
        model: model,
        scenario: scenario,
        name: name
    };

    console.log('Creando NPC:', JSON.stringify(npcData, null, 2));

    fetch(`https://${GetParentResourceName()}/createNPC`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(npcData)
    });

    document.getElementById('npcName').value = '';
    document.getElementById('createMenu').style.display = 'none';
    document.getElementById('mainMenu').style.display = 'block';
});

// Actualizar lista de NPCs
function updateNPCList() {
    const listContainer = document.getElementById('npcList');
    listContainer.innerHTML = '';

    console.log('Actualizando lista de NPCs:', JSON.stringify(npcs, null, 2));

    if (!npcs || Object.keys(npcs).length === 0) {
        listContainer.innerHTML = '<div class="npc-item"><span>No hay NPCs creados</span></div>';
        return;
    }

    Object.entries(npcs).forEach(([id, npc]) => {
        if (!npc || !npc.name) return;

        console.log('Procesando NPC:', id, JSON.stringify(npc, null, 2));

        const npcElement = document.createElement('div');
        npcElement.className = 'npc-item';
        npcElement.innerHTML = `
            <span>${npc.name}</span>
            <div class="npc-item-buttons">
                <button class="npc-item-btn tp-btn" onclick="teleportToNPC(${id})">
                    <i class="fas fa-location-arrow"></i>
                </button>
                <button class="npc-item-btn delete-btn" onclick="deleteNPC(${id})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
        listContainer.appendChild(npcElement);
    });
}

// Funciones de NPC
function teleportToNPC(id) {
    console.log('Teleportando a NPC:', id);
    fetch(`https://${GetParentResourceName()}/teleportToNPC`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            id: parseInt(id)
        })
    });
}

function deleteNPC(id) {
    console.log('Eliminando NPC:', id);
    fetch(`https://${GetParentResourceName()}/deleteNPC`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            id: parseInt(id)
        })
    });
}

// Cerrar con Escape
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});