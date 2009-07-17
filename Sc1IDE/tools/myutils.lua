-- Set property value from the system environment
-- [qhs] 07/17/2009

local function SetKeyFromEnv(key)
    if not key or key=='' then return end
    local value=os.getenv(key)
    if not value then return end
    props[key]=value
end

if tonumber(props['USE_MTEX'])==1 then
    SetKeyFromEnv('MTEX')
else
    SetKeyFromEnv('MICTEX')
end
