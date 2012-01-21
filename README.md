#QName modification

VIM plugin for CTRLP like fast file and functions switching, based on original qname plugin (http://www.vim.org/scripts/script.php?script_id=2317)

#Usage:

  <F4> - open file search, <Tab> - open file in new tag, <CR> - open in current window

  <F8> - open functions search in current buffer

You can remap this functions by declare global variables:

	let g:qname_base_hotkey = "<F4>"

AND

	let g:qname_func_hotkey = "<F8>"

By default this plugin using git to fetch list of files, if ".git" directory located in current path, and "find . -type -f" otherwise.

You can customise this behavior by declaring:

	let g:qname_command = 'if [ -d "./.git" ]; then git ls-files '.g:qname_filter.'; else find . -type f '.g:qname_filter.'; fi'

Also, you can set g:qname_filter option, for example I use

  let g:qname_filter = '| grep ".\(php\|js\|css\)$"'
