#QName modification

VIM plugin for CTRLP like fast file and functions switching, based on original qname plugin (http://www.vim.org/scripts/script.php?script\_id=2317)

<img src="http://cs10116.vkontakte.ru/u66748/-3/y_2971b7e2.jpg">

#Usage:

  F4 - open file search, Tab - open file in new tag, CR - open in current window

  F8 - open functions search in current buffer

You can remap this functions by declare global variables:

	let g:qname\_base\_hotkey = "<F4>"

AND

	let g:qname\_func\_hotkey = "<F8>"

By default this plugin using git to fetch list of files, if ".git" directory located in current path, and "find . -type -f" otherwise.

You can customise this behavior by declaring:

	let g:qname\_command = 'if [ -d "./.git" ]; then git ls-files '.g:qname\_filter.'; else find . -type f '.g:qname\_filter.'; fi'

Also, you can set g:qname\_filter option, for example I use:

  let g:qname\_filter = '| grep ".\\(php\|js\|css\\)$"'
