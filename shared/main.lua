local bridgeResources = {
    ['es_extended'] = 'esx', 
    ['ND_Core'] = 'nd',
    ['ox_core'] = 'ox',
    ['qbx_core'] = 'qbx', 
    ['qb-core'] = 'qb', 
}

local function getBridge()
    if GetResourceState('qbx_core'):find('start') then
        return ('modules.bridge.%s.%s'):format('qbx', lib.context)
    end

    for resource, framework in pairs(bridgeResources) do
        if GetResourceState(resource):find('start') then
            return ('modules.bridge.%s.%s'):format(framework, lib.context)
        end
    end
end

bridge = require(getBridge())
