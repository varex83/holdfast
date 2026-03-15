local Constants = require("data.constants")

local Classes = {}

Classes.order = {
    Constants.CLASS.WARRIOR,
    Constants.CLASS.ARCHER,
    Constants.CLASS.ENGINEER,
    Constants.CLASS.SCOUT,
}

Classes.definitions = {
    [Constants.CLASS.WARRIOR] = {
        id = Constants.CLASS.WARRIOR,
        label = "Warrior",
        summary = "Frontline melee, high health, heavy armor.",
        stats = {
            maxHp = 200,
            armor = 10,
            speed = 80,
            attack = 25,
            attackRange = 50,
            attackSpeed = 1.0,
            carryCapacity = 50,
        },
        ability = {
            id = "shield_bash",
            label = "Shield Bash",
            cooldown = 8.0,
            cost = 0,
        },
        visuals = {
            appearance = "knight_swordman",
            tint = {1.0, 1.0, 1.0, 1.0},
        },
        permissions = {
            canAttack = true,
            canBuild = false,
        },
    },
    [Constants.CLASS.ARCHER] = {
        id = Constants.CLASS.ARCHER,
        label = "Archer",
        summary = "Ranged pressure with medium speed and low health.",
        stats = {
            maxHp = 100,
            armor = 5,
            speed = 150,
            attack = 15,
            attackRange = 300,
            attackSpeed = 0.8,
            carryCapacity = 75,
        },
        ability = {
            id = "volley",
            label = "Volley",
            cooldown = 10.0,
            cost = 0,
        },
        visuals = {
            appearance = "knight_archer",
            tint = {1.0, 0.96, 0.90, 1.0},
        },
        permissions = {
            canAttack = true,
            canBuild = false,
        },
    },
    [Constants.CLASS.ENGINEER] = {
        id = Constants.CLASS.ENGINEER,
        label = "Engineer",
        summary = "Fast utility specialist focused on building and repair.",
        stats = {
            maxHp = 80,
            armor = 3,
            speed = 180,
            attack = 0,
            attackRange = 0,
            attackSpeed = 0,
            carryCapacity = 100,
        },
        ability = {
            id = "construct",
            label = "Construct",
            cooldown = 0,
            cost = 0,
        },
        visuals = {
            appearance = "knight_templar",
            tint = {0.90, 0.92, 1.0, 1.0},
        },
        permissions = {
            canAttack = false,
            canBuild = true,
        },
    },
    [Constants.CLASS.SCOUT] = {
        id = Constants.CLASS.SCOUT,
        label = "Scout",
        summary = "Fast stealth flanker with light melee damage.",
        stats = {
            maxHp = 120,
            armor = 3,
            speed = 200,
            attack = 8,
            attackRange = 40,
            attackSpeed = 1.2,
            carryCapacity = 120,
        },
        ability = {
            id = "cloak",
            label = "Cloak",
            cooldown = 15.0,
            cost = 0,
        },
        visuals = {
            appearance = "knight_spearman",
            tint = {0.82, 1.0, 0.90, 1.0},
        },
        permissions = {
            canAttack = true,
            canBuild = false,
        },
    },
}

function Classes.get(classType)
    return Classes.definitions[classType]
end

function Classes.getStats(classType)
    local classDef = Classes.get(classType)
    return classDef and classDef.stats or nil
end

function Classes.getAbility(classType)
    local classDef = Classes.get(classType)
    return classDef and classDef.ability or nil
end

function Classes.getVisuals(classType)
    local classDef = Classes.get(classType)
    return classDef and classDef.visuals or nil
end

return Classes
