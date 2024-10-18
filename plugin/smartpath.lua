local SmartPath = function()
    local loop = vim.loop
    local res = {}
    local stdout = loop.new_pipe(false)
    local stderr = loop.new_pipe(false)

    local onread = function(err, data)
        if err then
            print("ERROR: ", err)
        end

        if data then
            local vals = vim.split(data, "\n")
            for _, d in pairs(vals) do
                if d == "" then
                    goto continue
                end
                table.insert(res, d)
                ::continue::
            end
        end
    end

    local setpath = function()
        local paths = { ".," }
        for _, v in pairs(res) do
            table.insert(paths, v .. "/**")
        end

        vim.api.nvim_set_option_value("path", table.concat(paths, ","), {})
    end

    local handle
    handle = loop.spawn(
        "fd",
        {
            args = {
                "--max-depth",
                "2",
                "-t",
                "d",
            },
            stdio = { stdout, stderr },
        },
        vim.schedule_wrap(function()
            stdout:read_stop()
            stderr:read_stop()
            stdout:close()
            stderr:close()
            handle:close()
            setpath()
        end)
    )
    loop.read_start(stdout, onread)
    loop.read_start(stderr, onread)
end

vim.api.nvim_create_autocmd("VimEnter", {
    desc = "set path using fd",
    group = vim.api.nvim_create_augroup("plugin/smart_path", { clear = true }),
    callback = function()
        SmartPath()
    end,
})
