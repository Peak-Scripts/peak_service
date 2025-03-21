return {
    confiscateItems = true,

    taskSpots = {
        vector3(1628.29, 2500.48, 45.6),
        vector3(1640.58, 2513.49, 45.6),
        vector3(1656.20, 2520.62, 45.6),
        vector3(1669.09, 2517.21, 45.6),
        vector3(1657.43, 2505.08, 45.6),
        vector3(1643.33, 2498.08, 45.6),
        vector3(1677.58, 2494.06, 45.6),
        vector3(1692.81, 2484.77, 45.6),
        vector3(1701.06, 2497.13, 45.6),
        vector3(1699.95, 2516.41, 45.6),
        vector3(1714.22, 2509.12, 45.6),
        vector3(1720.01, 2495.60, 45.6),
        vector3(1703.98, 2486.41, 45.6),
        vector3(1687.74, 2502.53, 45.6),
        vector3(1664.87, 2499.19, 45.6)
    },

    logging = {
        enabled = false,
        system = 'ox_lib', -- ox_lib (recommended) or discord (not recommended)
    
        name = 'Peak Scripts',
        image = 'https://r2.fivemanage.com/mRGMLnWSeQJ90gOfps6Wt/peakscripts.png',
        webhookUrl = ''

        logIP = false
    },

    commands = {
        services = {
            name = 'services',
            help = 'View and manage players in community service',
            restricted = 'group.admin'
        },
        
        comserv = {
            name = 'comserv',
            help = 'Assign community service to a player',
            restricted = 'group.admin'
        },
        
        removecomserv = {
            name = 'removecomserv',
            help = 'Remove a player from community service',
            restricted = 'group.admin'
        }
    }
}
