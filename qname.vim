if v:version < 700
	finish
endif

if !exists("g:qname_base_hotkey") || g:qname_base_hotkey == ""
	let g:qname_base_hotkey = "<F4>"
endif
if !exists("g:qname_func_hotkey") || g:qname_func_hotkey == ""
	let g:qname_func_hotkey = "<F8>"
endif
if !exists("g:qname_filter")
	let g:qname_filter = ''
endif
if !exists("g:qname_command") || g:qname_command == ''
	let g:qname_command = 'if [ -d "./.git" ]; then git ls-files '.g:qname_filter.'; else find . -type f '.g:qname_filter.'; fi'
endif
exe "nmap" g:qname_base_hotkey ":cal QNameInit(1)<cr>:~"
exe "imap" g:qname_base_hotkey "<Esc>:cal QNameInit(1)<cr>:~"
exe "vmap" g:qname_base_hotkey "<Esc>:cal QNameInit(1)<cr>:~"
exe "nmap" g:qname_func_hotkey ":cal QNameInit(2)<cr>:~"
exe "imap" g:qname_func_hotkey "<Esc>:cal QNameInit(2)<cr>:~"
exe "vmap" g:qname_func_hotkey "<Esc>:cal QNameInit(2)<cr>:~"
let s:qname_base_hotkey = eval('"\'.g:qname_base_hotkey.'"')
let s:qname_func_hotkey = eval('"\'.g:qname_func_hotkey.'"')
let s:last_match = 0

if exists("g:qname_loaded") && g:qname_loaded
	finish
endif
let g:qname_loaded = 1

function! QNameRun()
	cal s:colPrinter.print()
  echo "\r:".s:inp

  call inputsave()
	let _key = getchar()

  while !empty(_key)
    if !type(_key)
      let _key = nr2char(_key)
    endif

    let s:_key = _key

    if _key == "\<BS>"
      let s:inp = s:inp[:-2]
    elseif _key == "\<C-U>"
      let s:inp = ""
    elseif strlen(_key) == 1 && char2nr(_key) > 31
      let s:inp = s:inp._key
    endif

    if _key == "\<ESC>"
      let _sel = s:colPrinter.sel
      cal QNameInit(0)
      if s:type == 2
        call setpos('.', s:start_pos)
      endif
      break

    elseif _key == "\<CR>" || _key == "\<S-CR>" || _key == "\<Tab>"
      let _sel = s:colPrinter.sel
      if _sel < len(s:s) && _sel >= 0

        if _key == "\<S-CR>"
          :split
        endif
        cal QNameInit(0)
        if s:type != 2
          cal s:act(1)
        endif
      else
        cal QNameInit(0)
      endif
      break
    elseif _key == "\<Up>"
      cal s:colPrinter.vert(-1)
      cal s:act(0)
    elseif _key == "\<Down>"
      cal s:colPrinter.vert(1)
      cal s:act(0)
    elseif _key == "\<Left>"
      cal s:colPrinter.horz(-1)
      cal s:act(0)
    elseif _key == "\<Right>"
      cal s:colPrinter.horz(1)
      cal s:act(0)
    elseif _key == s:qname_base_hotkey || _key == s:qname_func_hotkey
      cal QNameInit(0)
      break
    else
      cal s:build()
      cal s:act(0)
    endif
    let _key = getchar(0)
  endwhile
  redraws
	call inputrestore()
endfunc

function! QNameInit(type)
	if a:type
		cmap ~ cal QNameRun()<CR>:~
		let s:pro = "Prompt: "
		let s:cmdh = &cmdheight
    let s:type = a:type
		if a:type != -1
			let s:inp = ""
		endif
    echo "\r:"
    if a:type == 1
      call s:baselist()
    elseif a:type == 2
      let s:start_pos = getpos('.')
      call s:funclist()
    endif
		call s:build()
		exe "set cmdheight=".(s:colPrinter.trow+1)
    if a:type == 2
      call s:act(1)
    endif
	else
		cmap ~ exe "cunmap \x7E"<cr>
		exe "set cmdheight=".s:cmdh
    if s:last_match
      call matchdelete(s:last_match)
      let s:last_match = 0
    endif
	endif
endfunc

function! s:act(cr)
  if s:type == 2 || a:cr == 1
    let _sel = s:colPrinter.sel
    if _sel < len(s:s) && _sel >= 0
      let val = s:s[_sel]

      let lnum = get(val, 2)
      let lcol = get(val, 3)

      if s:type == 2
        call setpos('.', [0, lnum, lcol])
        if s:last_match
          call matchdelete(s:last_match)
        endif
        let s:last_match = matchadd("IncSearch", '\%<'.(lnum + 1).'l'.val[0].'\%>'.(lnum - 1).'l')
      else
        if lnum
          call s:swb(str2nr(lnum))
        elseif s:_key == "\<Tab>"
          exe 'tabnew '.get(val, 1).'/'.get(val, 0)
        else
          exe 'e '.get(val, 1).'/'.get(val, 0)
        endif
      endif
    endif
  endif
endfunc

function! s:build()
	let s:s = []
	let s:blen = 0
	let _cmp = tolower(tr(s:inp, '\', '/'))

  let priority = {}

  let _cmp = substitute(_cmp, '.\zs', '.*', 'g')
  let _cmp = substitute(_cmp, '[\-_]', '[\\-_]', 'g')
  let g:_cmp = _cmp

	for _line in s:ls
    if s:type == 2
      let matchstr = _line[0]
    else
      let matchstr = _line[1].'/'._line[0]
    endif
    let pos = matchend(tolower(matchstr), _cmp)
		if pos >= 0
      let cpos = pos
      let ind = get(priority, cpos)
      while cpos > 0 && !ind
        let cpos -= 1
        let ind = get(priority, cpos)
      endwhile
			cal insert(s:s, _line, ind)
      let priority[pos] = ind + 1
		endif
	endfor
	if len(s:s) > s:colPrinter.trow || s:type == 2
		cal s:colPrinter.put(s:s, 0)
	else
		cal s:colPrinter.put(s:s, 1)
	endif
endfunc

function! s:swb(bno)
	if bufwinnr(a:bno) == -1
		exe "hid b" a:bno
	else
		exe bufwinnr(a:bno) . "winc w"
	endif
endfunc

function! s:baselist()
  if exists("g:qname_ls")
    let s:ls = copy(g:qname_ls)
  else
    let s:ls = []

    call s:extlist()

    let g:qname_ls = copy(s:ls)
  endif
endfunc

function! s:buflist()
  redir @y | silent ls! | redir END
  for _line in split(@y,"\n")
    if _line[3]!='u' || _line[6]!='-'
      let _bno = matchstr(_line, '^ *\zs\d*')+0
      let _fname = substitute(expand("#"._bno.":p"), '\', '/', 'g')
      if _fname == ""
        let _fname = "|".matchstr(_line, '"\[\zs[^\]]*')."|"
      endif
      let _name = fnamemodify(_fname,":t")
      cal add(s:ls, [_name, fnamemodify(_fname,":h"), _bno, 0])
    endif
  endfor
endfunction

function! s:extlist()
  let lines = split(system(g:qname_command), "\n")
  for line in lines
    let parts = split(line, '\zs\/\ze[^\/]*$')
    let _name = get(parts, 1)
    let path = get(parts, 0)
    if empty(_name)
      let _name = path
      let path = '.'
    endif

    cal add(s:ls, [_name, path, 0, 0])
  endfor
endfunction

function! s:funclist()
	let s:ls = []

  try
    exe "vimgrep /function/j %"
  catch /E480/
  catch /E499/
  endtry
  let bname  = buffer_name('%')
  for d in getqflist()
    let pattern = 'function[ !]\+\zs\([a-zA-z_\-:\.]\+\)\ze'
    let info = matchlist(d.text, pattern)
    if !empty(info)
      let col = match(d.text, pattern)
      let l = get(info, 1)
      cal add(s:ls, [l, bname, d.lnum, col + 1])
      continue
    endif
    let pattern = '\zs\([a-zA-z_\-:\.]\+\)\ze[ ]*:[ ]*function[ ]*('
    let info = matchlist(d.text, pattern)
    if !empty(info)
      let col = match(d.text, pattern)
      let l = get(info, 1)
      cal add(s:ls, [l, bname, d.lnum, col + 1])
      continue
    endif

  endfor

	"cal sort(s:ls, 1)
endfunc

let s:colPrinter = {"trow": 4}
function! s:colPrinter.put(its, type) dict
	let _cols = []
	let _trow = self.trow

	let _its = copy(a:its)
	let _len = len(_its)
	let _i = 0
	while _i < _len
		if _i+_trow <= _len
			cal add(_cols, remove(_its, 0, _trow - 1))
		else
			cal add(_cols, _its)
		endif
		let _i += _trow
	endwhile

	let _cpos = [0]
	let _cw = []
	let _t = 0
	for _li in _cols
		let _w = max(map(copy(_li), 'strlen(v:val[0])'))+4
		let _t += _w
		cal add(_cpos,_t)
		cal add(_cw, _w)
	endfor

	let _rows = []
	for _i in range(_trow)
		let _row = []
		for _j in range(len(_cols))
			if _j*_trow+_i < _len
				cal add(_row, _cols[_j][_i])
			endif
		endfor
		cal add(_rows, _row)
	endfor

	let self.cols = _cols
	let self.cw = _cw
  let self.type = a:type
	let self.rows = _rows
	let self.cpos = _cpos
	let self.len = _len
	let self.lcol = 0
	let self.sel = 0
endfunc

function! s:colPrinter.horz(mv) dict
	let _t = self.sel + a:mv*self.trow
	if _t >= 0 && _t < self.len
		let self.sel = _t
	endif
endfunc

function! s:colPrinter.vert(mv) dict
	let _t = self.sel + a:mv
	let _len = self.len
	if _t < 0 && _len > 0
		let self.sel = _len-1
	elseif _t >= _len
		let self.sel = 0
	else
		let self.sel = _t
	endif
endfunc

function! s:colPrinter.print() dict
	let _len = self.len
	let _trow = self.trow
	if !_len
		echo " [ No match ] " repeat("\n", _trow)
		return
	endif
	let _sel = self.sel
	let _t = _sel/_trow
	let _cpos = self.cpos
	let _lcol = self.lcol
	let _tcol = &columns
	if _cpos[_lcol]+_tcol < _cpos[_t+1]
		let _rcol = _t
		let _pos = _cpos[_t+1]-_tcol-2
		while _cpos[_lcol] < _pos
			let _lcol += 1
		endwhile
		let _lcol -= _lcol > _t
	else
		if _t < _lcol
			let _lcol = _t
		endif
		let _rcol = len(_cpos)-1
		let _pos = _cpos[_lcol]+_tcol+2
		while _cpos[_rcol] > _pos
			let _rcol -= 1
		endwhile
		let _rcol -= _rcol > _lcol
	endif
	let _cw = self.cw
	let _pos = _cpos[_lcol]+_tcol
	let self.lcol = _lcol
	for _i in range(_trow)
		let _row = self.rows[_i]
		for _j in range(_lcol,_rcol)
			if _j*_trow+_i < _len
        if self.type
          let _txt = " " . _row[_j][1] . '/' . _row[_j][0]
        else
          let _txt = " " . _row[_j][0]
        endif
				let _txt .= repeat(" ", _cw[_j] - strlen(_txt))
				let _txt = _txt[:_pos-_cpos[_j]-2]
				if _j*_trow + _i == _sel
					echoh Search|echon _txt|echoh None
				else
					echon _txt
				endif
			endif
		endfor
		echon "\n"
	endfor
endfunc
