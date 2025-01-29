return {
  "stevearc/overseer.nvim",
  config = function()
    local overseer = require("overseer")

    overseer.setup({
      task_list = {
        default_detail = 1,
        direction = "bottom",
        min_height = 10,
      },
    })

    local tasks = {
      {
        name = "Generate CMakeLists",
        builder = function()
          return {
            cmd = "sh",
            args = {
              "-c",
              [[cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(MyProject)
set(CMAKE_CXX_STANDARD 20)
file(GLOB SRC_FILES *.cpp)
add_executable(main ${SRC_FILES})
EOF
              ]],
            },
            condition = {
              callback = function()
                return vim.fn.filereadable("CMakeLists.txt") == 0 and vim.fn.glob("*.cpp") ~= ""
              end,
            },
          }
        end,
      },

      {
        name = "CMake Configure",
        builder = function()
          return {
            cmd = "cmake",
            args = { "-B", "build", "-DCMAKE_BUILD_TYPE=Release" },
            components = { "default", "on_output_quickfix" },
            condition = {
              filetype = { "cpp", "c" },
            },
          }
        end,
      },

      {
        name = "CMake Build + Run",
        builder = function()
          return {
            cmd = "sh",
            args = {
              "-c",
              "cmake --build build --parallel 4 && ./build/main",
            },
            components = { "default", "on_output_quickfix" },
            condition = {
              filetype = { "cpp", "c" },
            },
          }
        end,
      },

      {
        name = "Debug C++",
        builder = function()
          return {
            cmd = "gdb",
            args = { "-ex", "run", "build/main" },
            components = { "default" },
            condition = {
              filetype = { "cpp", "c" },
            },
          }
        end,
      },

      -- C# - Build + Run
      {
        name = "Build & Run C#",
        builder = function()
          return {
            cmd = "dotnet",
            args = { "build", "&&", "dotnet", "run" },
            components = { "default" },
            condition = {
              filetype = { "cs" },
            },
          }
        end,
      },

      {
        name = "Debug C#",
        builder = function()
          return {
            cmd = "dotnet",
            args = { "build", "&&", "dotnet", "run", "--configuration", "Debug" },
            components = { "default" },
            condition = {
              filetype = { "cs" },
            },
          }
        end,
      },

      -- PHP
      {
        name = "Run PHP",
        builder = function()
          return {
            cmd = "php",
            args = { vim.fn.expand("%") },
            components = { "default" },
            condition = {
              filetype = { "php" },
            },
          }
        end,
      },

      -- JavaScript
      {
        name = "Run JavaScript",
        builder = function()
          return {
            cmd = "node",
            args = { vim.fn.expand("%") },
            components = { "default" },
            condition = {
              filetype = { "javascript" },
            },
          }
        end,
      },

      -- HTML
      {
        name = "Serve HTML",
        builder = function()
          return {
            cmd = "live-server",
            args = { vim.fn.expand("%:p:h") },
            components = { "default" },
            condition = {
              filetype = { "html" },
            },
          }
        end,
      },

      {
        name = "Run Python",
        builder = function()
          return {
            cmd = "python",
            args = { vim.fn.expand("%") },
            components = { "default" },
            condition = {
              filetype = { "python" },
            },
          }
        end,
      },

      {
        name = "Debug Python",
        builder = function()
          return {
            cmd = "python",
            args = { "-m", "pdb", vim.fn.expand("%") },
            components = { "default" },
            condition = {
              filetype = { "python" },
            },
          }
        end,
      },
    }

    for _, task in ipairs(tasks) do
      overseer.register_template(task)
    end

    vim.keymap.set("n", "<leader>cc", "<cmd>OverseerRun<CR>", { desc = "Run task" })
    vim.keymap.set("n", "<leader>ct", "<cmd>OverseerToggle<CR>", { desc = "Toggle tasks" })
    vim.keymap.set("n", "<leader>cb", "<cmd>OverseerBuild<CR>", { desc = "Build task" })
    vim.keymap.set("n", "<leader>cd", "<cmd>OverseerDebug<CR>", { desc = "Debug task" })

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        local ft = vim.bo.filetype
        local file_tasks = {
          cpp = { "Generate CMakeLists", "CMake Configure", "CMake Build + Run" },
          c = { "Generate CMakeLists", "CMake Configure", "CMake Build + Run" },
          cs = { "Build & Run C#" },
          php = { "Run PHP" },
          javascript = { "Run JavaScript" },
          html = { "Serve HTML" },
          python = { "Run Python" },
        }

        if file_tasks[ft] then
          for _, task in ipairs(file_tasks[ft]) do
            vim.cmd(string.format("OverseerRun '%s'", task))
          end
        end
      end,
    })
  end,
}
