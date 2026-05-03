local repo = "BongBingBing/Typhon_Inc_OS"
local branch = "main"
local folderInRepo = "CCtweaked"
local scriptName = shell.getRunningProgram() -- Don't delete the script currently running!

-- GitHub API requires a User-Agent
local headers = { ["User-Agent"] = "CC-Tweaked-Auto-Sync" }

-- Function to wipe the local directory
local function clearLocalFiles()
    print("Performing clean wipe...")
    local files = fs.list("/")
    for _, file in ipairs(files) do
        -- We don't delete the sync script itself or the rom
        if file ~= scriptName and file ~= "rom" then
            fs.delete(file)
        end
    end
end

local function downloadFile(url, localPath)
    local res = http.get(url, headers)
    if res then
        local file = fs.open(localPath, "w")
        file.write(res.readAll())
        file.close()
        res.close()
        return true
    end
    return false
end

local function sync(repoPath)
    local apiUrl = ("https://api.github.com/repos/%s/contents/%s?ref=%s"):format(repo, repoPath, branch)
    local res = http.get(apiUrl, headers)
    
    if not res then
        print("Error: Could not reach GitHub API.")
        return
    end

    local contents = textutils.unserializeJSON(res.readAll())
    res.close()

    for _, item in ipairs(contents) do
        -- Remove the 'CCtweaked/' prefix for local saving
        local localPath = item.path:sub(#folderInRepo + 2)
        if localPath == "" then localPath = item.name end

        if item.type == "file" then
            print("Installing: " .. localPath)
            downloadFile(item.download_url, localPath)
        elseif item.type == "dir" then
            if not fs.exists(localPath) then fs.makeDir(localPath) end
            sync(item.path) -- Recursive call for subfolders
        end
    end
end

-- Execution
clearLocalFiles()
print("Starting auto-detection sync...")
sync(folderInRepo)
print("System Updated Successfully!")