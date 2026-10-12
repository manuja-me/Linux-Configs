-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Force correct TERM for Kitty
if vim.env.KITTY_WINDOW_ID then
  vim.env.TERM = "xterm-kitty"
end

-- Cursor shape configuration optimized for Kitty
vim.opt.guicursor = {
  "n-v-c-sm:block-Cursor/lCursor",      -- Normal, visual, command-line: block cursor
  "i-ci-ve:ver20-Cursor/lCursor",       -- Insert: thicker vertical bar cursor (20% width)  
  "r-cr:hor20-Cursor/lCursor",          -- Replace: horizontal bar cursor (20% height)
  "o:hor50-Cursor/lCursor",             -- Operator-pending: horizontal bar cursor (50% height)
  "a:blinkwait700-blinkoff400-blinkon250", -- All modes: blinking settings
}

-- Enhanced cursor shape setup specifically for Kitty
local function setup_kitty_cursors()
  -- Check if we're in Kitty or a compatible terminal
  local term = vim.env.TERM or ""
  local is_kitty = vim.env.KITTY_WINDOW_ID ~= nil
  local is_supported = term:match("kitty") or term:match("xterm") or is_kitty

  if not is_supported then
    return false
  end

  -- More reliable cursor shape function with alternative shapes
  local function set_cursor_shape(shape)
    local seq = ""
    if shape == "block" then
      seq = "\027[1 q"      -- Blinking block cursor (more visible difference)
    elseif shape == "beam" then  
      seq = "\027[5 q"      -- Blinking beam cursor (very thin vertical line)
    elseif shape == "underline" then
      seq = "\027[3 q"      -- Blinking underline cursor
    elseif shape == "steady_block" then
      seq = "\027[2 q"      -- Steady block cursor
    elseif shape == "steady_beam" then
      seq = "\027[6 q"      -- Steady beam cursor
    elseif shape == "steady_underline" then
      seq = "\027[4 q"      -- Steady underline cursor
    end
    
    if seq ~= "" then
      -- Use multiple output methods for better compatibility
      io.write(seq)
      io.flush()
      
      -- Also try stderr for some terminals
      vim.schedule(function()
        vim.api.nvim_err_write("")
      end)
    end
  end

  -- Enhanced test command with more cursor types
  vim.api.nvim_create_user_command('TestCursors', function()
    print("Testing all cursor shapes - watch your cursor carefully!")
    print("1. Steady Block cursor (should be a solid rectangle)...")
    set_cursor_shape("steady_block")
    
    vim.defer_fn(function()
      print("2. Blinking Block cursor...")
      set_cursor_shape("block")
      
      vim.defer_fn(function()
        print("3. Steady Beam cursor (should be a VERY thin vertical line)...")
        set_cursor_shape("steady_beam")
        
        vim.defer_fn(function()
          print("4. Blinking Beam cursor...")
          set_cursor_shape("beam")
          
          vim.defer_fn(function()
            print("5. Steady Underline cursor (horizontal line at bottom)...")
            set_cursor_shape("steady_underline")
            
            vim.defer_fn(function()
              print("6. Blinking Underline cursor...")
              set_cursor_shape("underline")
              
              vim.defer_fn(function()
                print("7. Back to steady block cursor...")
                set_cursor_shape("steady_block")
                print("Test complete! The beam should be MUCH thinner than the block.")
                print("If they still look the same, your terminal might not support thin beams.")
              end, 2000)
            end, 2000)
          end, 2000)
        end, 2000)
      end, 2000)
    end, 2000)
  end, { desc = "Test all cursor shape variations" })

  -- Mode-based cursor switching with more distinct shapes
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*",
    callback = function()
      -- Small delay to ensure mode change is complete
      vim.defer_fn(function()
        local mode = vim.api.nvim_get_mode().mode
        
        if mode == "n" or mode == "no" or mode == "v" or mode == "V" or mode == "\22" then
          set_cursor_shape("steady_block")  -- Normal/Visual: steady block
        elseif mode == "i" or mode == "ic" or mode == "ix" then  
          set_cursor_shape("beam")   -- Insert: blinking beam (should be very thin)
        elseif mode == "R" or mode == "Rc" or mode == "Rv" then
          set_cursor_shape("underline") -- Replace: blinking underline
        elseif mode == "c" then
          set_cursor_shape("steady_underline") -- Command: steady underline
        end
      end, 10)
    end,
  })

  -- Initialize cursor on startup
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function()
        set_cursor_shape("steady_block")
        if vim.env.KITTY_WINDOW_ID then
          print("Kitty cursor shapes loaded! Try :TestCursors to verify.")
          print("Normal mode = steady block, Insert mode = blinking thin beam")
        end
      end, 200)
    end,
  })

  -- Restore cursor when leaving
  vim.api.nvim_create_autocmd({"VimLeave", "VimSuspend"}, {
    callback = function()
      set_cursor_shape("block")
    end,
  })

  return true
end

-- Initialize the cursor system
setup_kitty_cursors()
