local utils = {}

--- @param message string
--- @param type string
function utils.notify(message, type)
    lib.notify({ 
        position = 'top',
        title = 'Community Service',
        description = message, 
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
              color = '#909296'
            }
        },
        type = type 
    })
end

function utils.debugPrint(message)
    print(('^1[DEBUG]^0 %s'):format(message))
end

return utils