return {
    location = {
        center = vector3(1692.83, 2470.49, 45.61),
        radius = 300.0,
        spawnPoint = vector3(1692.83, 2470.49, 45.61), 
    },

    tasks = {
        {
            label = 'Clean the floor',
            duration = 1000,
            animation = {
                dict = 'anim@amb@drug_field_workers@rake@male_a@base',
                clip = 'base',
                flag = 49
            },
            prop = {
                model = 'prop_tool_broom',
                bone = 28422,
                pos = vec3(-0.01, 0.04, -0.03),
                rot = vec3(0.00, 0.00, 0.00)
            }
        },
    },

    penalties = {
        enabled = true,
        tasks = 2
    }
}
    