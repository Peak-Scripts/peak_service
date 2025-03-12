return {
    location = {
        center = vector3(1692.83, 2470.49, 45.61),
        radius = 300.0,
        spawnPoint = vector3(1692.83, 2470.49, 45.61), 
    },

    tasks = {
        {
            label = 'Clean the floor',
            duration = 10000,
            animation = {
                dict = 'amb@world_human_janitor@male@base',
                clip = 'base',
                flag = 49
            }
        },
    },

    penalties = {
        enabled = true,
        tasks = 2
    }
}
    