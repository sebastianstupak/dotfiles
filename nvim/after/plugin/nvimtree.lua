vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 35,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})

require'nvim-tree'.setup{}
vim.cmd(":NvimTreeToggle")

vim.keymap.set('n', '<leader><Tab>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })
