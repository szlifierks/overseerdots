return {
  "stevearc/overseer.nvim",
  opts = function(_, opts)
    local overseer = require("overseer")

    opts = vim.tbl_deep_extend("force", opts or {}, {
      task_list = {
        default_detail = 1,
        direction = "bottom",
        min_height = 12,
      },
      templates = {
        {
          name = "Generate CMakeLists",
          desc = "Auto-generate CMake for C++ projects",
          builder = function()
            return {
              cmd = "sh",
              args = {
                "-c",
                [[
                cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(${PROJECT_NAME:-MyProject})
set(CMAKE_CXX_STANDARD 20)
file(GLOB_RECURSE SRC_FILES *.cpp *.hpp)
add_executable(${PROJECT_NAME:-main} ${SRC_FILES})
EOF
                ]],
              },
              condition = {
                callback = function()
                  local dir = vim.fn.expand("%:p:h")
                  return vim.fn.filereadable(dir .. "/CMakeLists.txt") == 0
                    and #vim.fn.glob(dir .. "/*.cpp", false, true) > 0
                end,
                filetype = { "cpp", "c" },
              },
            }
          end,
        },
        {
          name = "CMake Configure",
          desc = "Configure CMake project",
          builder = function()
            return {
              cmd = "cmake",
              args = { "-B", "build", "-DCMAKE_BUILD_TYPE=Release" },
              components = {
                "default",
                "on_output_quickfix",
                { "on_complete_notify", timeout = 1 },
              },
              condition = {
                filetype = { "cpp", "c" },
                callback = function()
                  return vim.fn.filereadable("CMakeLists.txt") == 1
                end,
              },
            }
          end,
        },
        {
          name = "CMake Build + Run",
          desc = "Build and run C++ project",
          builder = function()
            return {
              cmd = "sh",
              args = {
                "-c",
                "cmake --build build --parallel 4 && ./build/main",
              },
              components = {
                "default",
                "on_output_quickfix",
                { "on_complete_notify", timeout = 3 },
              },
              condition = {
                filetype = { "cpp", "c" },
                callback = function()
                  return vim.fn.filereadable("build/Makefile") == 1 or vim.fn.filereadable("build/build.ninja") == 1
                end,
              },
            }
          end,
        },
      },
    })

    overseer.register_template({
      name = "Debug C++",
      desc = "Debug with gdb",
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
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*.cpp,*.hpp,*.c,*.h",
      group = vim.api.nvim_create_augroup("LazyVimCMake", { clear = true }),
      callback = function()
        local dir = vim.fn.expand("%:p:h")
        vim.cmd("silent! cd " .. dir)

        local tasks = {
          "Generate CMakeLists",
          "CMake Configure",
          "CMake Build + Run",
        }

        for _, task in ipairs(tasks) do
          vim.schedule(function()
            overseer.run_template({ name = task })
          end)
        end
      end,
    })

    return opts
  end,
}
