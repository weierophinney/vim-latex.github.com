" ============================================================================
" 	     File: texviewer.vim
"      Author: Mikolaj Machowski
"     Created: Sun Jan 26 06:00 PM 2003
" Description: make a viewer for various purposes: \cite{, \ref{
"     License: Vim Charityware License
"              Part of vim-latexSuite: http://vim-latex.sourceforge.net
" ============================================================================

if exists("g:Tex_Completion")
	finish
endif

inoremap <silent> <Plug>Tex_Completion <Esc>:call Tex_completion("default","text")<CR>

if !hasmapto('<Plug>Tex_Completion', 'i')
	imap <buffer> <silent> <F9> <Plug>Tex_Completion
endif

command -nargs=1 TLook call <SID>Tex_look(<q-args>)
command -nargs=1 TLookAll call <SID>Tex_lookall(<q-args>)
command -nargs=1 TLookBib call <SID>Tex_lookbib(<q-args>)

function! s:Tex_lookall(what)
	call Tex_completion(a:what, "all")
endfunction

function! s:Tex_lookbib(what)
	call Tex_completion(a:what, "bib")
endfunction

function! s:Tex_look(what)
	call Tex_completion(a:what, "tex")
endfunction

if getcwd() != expand("%:p:h")
	let s:search_directory = expand("%:h") . '/'
else
	let s:search_directory = ''
endif

" CompletionVars: similar variables can be set in package files {{{
let g:Tex_completion_bibliographystyle = 'abbr,alpha,plain,unsrt'
let g:Tex_completion_addtocontents = 'lof}{,lot}{,toc}{'
let g:Tex_completion_addcontentsline = 'lof}{figure}{,lot}{table}{,toc}{chapter}{,toc}{part}{,'.
									\ 'toc}{section}{,toc}{subsection}{,toc}{paragraph}{,'.
									\ 'toc}{subparagraph}{'
" }}}

" Tex_completion: main function {{{
" Description:
"
function! Tex_completion(what, where)

	" Get info about current window and position of cursor in file
	let s:winnum = winnr()
	let s:pos = line('.').' | normal! '.virtcol('.').'|'
	let s:col = col('.')

	if a:where == "text"
		" What to do after <F9> depending on context
		let s:curfile = expand("%:p")
		let s:curline = strpart(getline('.'), col('.') - 40, 40)
		let s:prefix = matchstr(s:curline, '.*{\zs.\{-}$')
		" a command is of the type
		" \includegraphics[0.8\columnwidth]{}
		" Thus
		" 	s:curline = '\includegraphics[0.8\columnwidth]{'
		" (with possibly some junk before \includegraphics)
		" from which we need to extract
		" 	s:type = 'includegraphics'
		" 	s:typeoption = '[0.8\columnwidth]'
		let pattern = '.*\\\(\w\{-}\)\(\[.\{-}\]\)\?{$'
		let s:type = substitute(s:curline, pattern, '\1', 'e')
		let s:typeoption = substitute(s:curline, pattern, '\2', 'e')

		if exists("s:type") && s:type =~ 'ref'
			exe "silent! grep! '\\label{".s:prefix."' ".s:search_directory.'*.tex'
			call <SID>Tex_c_window_setup()

		elseif exists("s:type") && s:type =~ 'cite'
			silent! grep! nothing %
			let bibfiles = <SID>Tex_FindBibFiles()
			let bblfiles = <SID>Tex_FindBblFiles()
			if bibfiles != ''
				exe "silent! grepadd! '@.*{".s:prefix."' ".bibfiles
				let g:bbb = "silent! grepadd! '@.*{".s:prefix."' ".bibfiles
			endif
			if bblfiles != ''
				exe "silent! grepadd! 'bibitem{".s:prefix."' ".bblfiles
			endif
			call <SID>Tex_c_window_setup()

		elseif exists("s:type") && s:type =~ 'includegraphics'
			let s:storehidefiles = g:explHideFiles
			let g:explHideFiles = '^\.,\.tex$,\.bib$,\.bbl$,\.zip$,\.gz$'
			exe 'silent! Sexplore '.s:search_directory.g:Tex_ImageDir
			call <SID>Tex_explore_window("includegraphics")
			
		elseif exists("s:type") && s:type == 'bibliography'
			let s:storehidefiles = g:explHideFiles
			let g:explHideFiles = '^\.,\.[^b]..$'
			exe 'silent! Sexplore '.s:search_directory
			call <SID>Tex_explore_window("bibliography")

		elseif exists("s:type") && s:type =~ 'include\(only\)\='
			let s:storehidefiles = g:explHideFiles
			let g:explHideFiles = '^\.,\.[^t]..$'
			exe 'silent! Sexplore '.s:search_directory
			call <SID>Tex_explore_window("includefile")

		elseif exists("s:type") && s:type == 'input'
			exe 'silent! Sexplore '.s:search_directory
			call <SID>Tex_explore_window("input")

		elseif exists("g:Tex_completion_{s:type}")
			call <SID>CompleteName('plugin_'.s:type)

		elseif exists("s:type") && g:Tex_completion_explorer =~ ','.s:type
			exe 'silent! Sexplore '.s:search_directory
			call <SID>Tex_explore_window("plugintype")

		else
			let s:word = matchstr(s:curline, '\zs\k\{-}$')
			if s:word == ''
				if col('.') == strlen(getline('.'))
					startinsert!
					return
				else
					normal! l
					startinsert
					return
				endif
			endif
			exe "silent! grep! '\<".s:word."' ".s:search_directory.'*.tex'
			call <SID>Tex_c_window_setup()

		endif
		
	elseif a:where == 'tex'
		" Process :TLook command
		exe "silent! grep! '".a:what."' ".s:search_directory.'*.tex'
		call <SID>Tex_c_window_setup()

	elseif a:where == 'bib'
		" Process :TLookBib command
		exe "silent! grep! '".a:what."' ".s:search_directory.'*.bib'
		exe "silent! grepadd! '".a:what."' ".s:search_directory.'*.bbl'
		call <SID>Tex_c_window_setup()

	elseif a:where == 'all'
		" Process :TLookAll command
		exe "silent! grep! '".a:what."' ".s:search_directory.'*'
		call <SID>Tex_c_window_setup()

	endif
endfunction " }}}
" Tex_c_window_setup: set maps and local settings for cwindow {{{
" Description: Set local maps jkJKq<cr> for cwindow. Also size and basic
" settings
"
function! s:Tex_c_window_setup()

	cclose
	exe 'copen '. g:Tex_ViewerCwindowHeight
	setlocal nonumber
	setlocal nowrap

	call <SID>UpdateViewerWindow()

    nnoremap <buffer> <silent> j j:call <SID>UpdateViewerWindow()<CR>
    nnoremap <buffer> <silent> k k:call <SID>UpdateViewerWindow()<CR>
    nnoremap <buffer> <silent> <up> <up>:call <SID>UpdateViewerWindow()<CR>
    nnoremap <buffer> <silent> <down> <down>:call <SID>UpdateViewerWindow()<CR>

	" Change behaviour of <cr> only for 'ref' and 'cite' context. 
	if exists("s:type") && s:type =~ 'ref'
		nnoremap <buffer> <silent> <cr> :silent! call <SID>CompleteName("ref")<CR>

	elseif exists("s:type") && s:type =~ 'cite'
		nnoremap <buffer> <silent> <cr> :silent! call <SID>CompleteName("cite")<CR>

	else
		" In other contexts jump to place described in cwindow and close small
		" windows
		nnoremap <buffer> <silent> <cr> :call <SID>GoToLocation()<cr>

	endif

	nnoremap <buffer> <silent> J :wincmd j<cr><c-e>:wincmd k<cr>
	nnoremap <buffer> <silent> K :wincmd j<cr><c-y>:wincmd k<cr>

	exe 'nnoremap <buffer> <silent> q :call Tex_CloseSmallWindows()<cr>'

endfunction " }}}
" Tex_CloseSmallWindows: {{{
" Description:
"
function! Tex_CloseSmallWindows()
	exe s:winnum.' wincmd w'
	pclose!
	cclose
	exe s:pos
endfunction " }}}
" Tex_explore_window: settings for completion of filenames {{{
" Description: 
"
function! s:Tex_explore_window(type) 

	exe g:Tex_ExplorerHeight.' wincmd _'

	if a:type =~ 'includegraphics\|bibliography\|includefile'
		nnoremap <silent> <buffer> <cr> :silent! call <SID>CompleteName("expl_noext")<CR>
	elseif a:type =~ 'input\|plugintype'
		nnoremap <silent> <buffer> <cr> :silent! call <SID>CompleteName("expl_ext")<CR>
	endif

	nnoremap <silent> <buffer> q :wincmd q<cr>

endfunction " }}}
" UpdateViewerWindow: update error and preview window {{{
" Description: Usually quickfix engine takes care about most of these things
" but we discard it for better control of events.
"
function! s:UpdateViewerWindow()

	let viewfile = matchstr(getline('.'), '^\f*\ze|\d')
	let viewline = matchstr(getline('.'), '|\zs\d\+\ze|')

	" Hilight current line in cwindow
	" Normally hightlighting is done with quickfix engine but we use something
	" different and have to do it separately
	syntax clear
	runtime syntax/qf.vim
	exe 'syn match vTodo /\%'. line('.') .'l.*/'
	hi link vTodo Todo

	" Close preview window and open it again in new place
    pclose
	exe 'silent! bot pedit +'.viewline.' '.viewfile

	" Vanilla 6.1 has bug. This additional setting of cwindow height prevents
	" resizing of this window
	exe g:Tex_ViewerCwindowHeight.' wincmd _'
	
	" Handle situation if there is no item beginning with s:prefix.
	" Unfortunately, because we know it late we have to close everything and
	" return as in complete process 
	if v:errmsg =~ 'E32\>'
		exe s:winnum.' wincmd w'
		pclose!
		cclose
		if exists("s:prefix")
			echomsg 'No bibkey, label or word beginning with "'.s:prefix.'"'
		endif
		if col('.') == strlen(getline('.'))
			startinsert!
		else
			normal! l
			startinsert
		endif
		let v:errmsg = ''
		return 0
	endif

	" Move to preview window. Really is it under cwindow?
	wincmd j

	" Settings of preview window
	exe g:Tex_ViewerPreviewHeight.' wincmd _'
	setlocal foldlevel=10

	if exists('s:type') && s:type =~ 'cite'
		" In cite context place bibkey at the top of preview window.
		setlocal scrolloff=0
		normal! zt
	else
		" In other contexts in the middle. Highlight this line?
		setlocal scrolloff=100
		normal! z.
	endif

	" Return to cwindow
	wincmd p

endfunction " }}}
" CompleteName: complete/insert name for current item {{{
" Description: handle completion of items depending on current context
"
function! s:CompleteName(type)

	if a:type =~ 'cite'
		if getline('.') =~ '\\bibitem{'
			let bibkey = matchstr(getline('.'), '\\bibitem{\zs.\{-}\ze}')
		else
			let bibkey = matchstr(getline('.'), '{\zs.\{-}\ze,')
		endif
		let completeword = strpart(bibkey, strlen(s:prefix))

	elseif a:type =~ 'ref'
		let label = matchstr(getline('.'), '\\label{\zs.\{-}\ze}')
		let completeword = strpart(label, strlen(s:prefix))

	elseif a:type =~ 'expl_ext\|expl_noext'
		let line = substitute(strpart(getline('.'),0,b:maxFileLen),'\s\+$','','')
		if isdirectory(b:completePath.line)
			call EditEntry("", "edit")
			exe 'nnoremap <silent> <buffer> <cr> :silent! call <SID>CompleteName("'.a:type.'")<CR>'
			nnoremap <silent> <buffer> q :wincmd q<cr>
			return

		else
			if a:type == 'expl_noext'
				let ifile = substitute(line, '\..\{-}$', '', '')
			else
				let ifile = line
			endif
			let filename = b:completePath.ifile
			
			if g:Tex_ImageDir != '' && s:type =~ 'includegraphics'
				let imagedir = s:curfile . g:Tex_ImageDir
				let completeword = <SID>Tex_RelPath(filename, imagedir)
			else
				let completeword = <SID>Tex_RelPath(filename, s:curfile)
			endif

			let g:explHideFiles = s:storehidefiles
		endif

	elseif a:type =~ '^plugin_'
		let type = substitute(a:type, '^plugin_', '', '')
		let completeword = <SID>Tex_DoCompletion(type)
		
	endif

	" Return to proper place in main window, close small windows
	if s:type =~ 'cite\|ref' 
		exe s:winnum.' wincmd w'
		pclose!
		cclose
	elseif a:type =~ 'expl_ext\|expl_noext'
		q
	endif

	exe s:pos


	" Complete word, check if add closing }
	exe 'normal! a'.completeword."\<Esc>"

	if getline('.')[col('.')-1] !~ '{' && getline('.')[col('.')] !~ '}'
		exe "normal! a}\<Esc>"
	endif

	" Return to Insert mode
	if col('.') == strlen(getline('.'))
		startinsert!

	else
		normal! l
		startinsert

	endif

endfunction " }}}
" GoToLocation: Go to chosen location {{{
" Description: Get number of current line and go to this number
"
function! s:GoToLocation()

	exe 'cc ' . line('.')
	pclose!
	cclose

endfunction " }}}
" Tex_FindBibFiles: find *.bib files {{{
" Description: scan files looking for \bibliography entries 
"
function! s:Tex_FindBibFiles()

	if g:projFiles != ''
		let bibfiles = ''
		let i = 1
		while Tex_Strntok(g:projFiles, ',', i) != ''
			let curfile = Tex_Strntok(g:projFiles, ',', i)
			if curfile =~ '\.bib'
				let curfile = substitute(curfile, '.*', s:search_directory.'\0', '')
				let bibfiles = bibfiles.'"'.curfile.'" '
			endif
			let i = i + 1
		endwhile

		let g:bibf = bibfiles
		return bibfiles

	else
		let bibnames = ''
		let bibfiles = ''
		let bibfiles2 = ''

		if search('\\bibliography{', 'w')
			let bibnames = matchstr(getline('.'), '\\bibliography{\zs.\{-}\ze}')
			let bibnames = substitute(bibnames, '\(,\|$\)', '.bib ', 'ge')
		endif

		let dirs = expand("%:p:h") . ":" . expand("$BIBINPUTS")
		let dirs = substitute(dirs, ':\+', ':', 'g')

		let i = 1
		while Tex_Strntok(dirs, ':', i) != ''
			let curdir = Tex_Strntok(dirs, ':', i) 
			let curdir = substitute(curdir, ' ', "\\", 'ge')
			let tmp = ''

			if bibnames != ''
				let j = 1
				while Tex_Strntok(bibnames, ' ', j) != ''
					let fname = curdir.'/'.Tex_Strntok(bibnames, ' ', j)
					if filereadable(fname)
						let tmp = tmp . ' ' . fname
					endif
					let j = j + 1
				endwhile
			else
				let tmp = glob(curdir.'/*.bib')
				let tmp = substitute(tmp, "\n", ' ', 'ge')
			endif

			let bibfiles = bibfiles . ' ' . tmp
			let i = i + 1
		endwhile

		if Tex_GetMainFileName() != ''
			let mainfname = Tex_GetMainFileName()
			let mainfdir = fnamemodify(mainfname, ":p:h")
                        let curdir = expand("%:p:h")
                        let curdir = substitute(curdir, ' ', "\\", 'ge')
			exe 'bot 1 split '.mainfname
			if search('\\bibliography{', 'w')
				let bibfiles2 = matchstr(getline('.'), '\\bibliography{\zs.\{-}\ze}')
				let bibfiles2 = substitute(bibfiles2, '\(,\|$\)', '.bib ', 'ge')
				let bibfiles2 = substitute(bibfiles2, '\(^\| \)', ' '.curdir.'/', 'ge')
			elseif mainfdir != curdir
				let bibfiles2 = glob(mainfdir.'/*.bib')
				let bibfiles2 = substitute(bibfiles2, '\n', ' ', 'ge')
			endif
			wincmd q
		endif

		return bibfiles.' '.bibfiles2
	endif

endfunction " }}}
" Tex_FindBblFiles: find bibitem entries in tex files {{{
" Description: scan files looking for \bibitem entries 
"
function! s:Tex_FindBblFiles()

	if g:projFiles != ''
		let bblfiles = ''
		let i = 1
		while Tex_Strntok(g:projFiles, ',', i) != ''
			let curfile = Tex_Strntok(g:projFiles, ',', i)
			if curfile =~ '\.tex'
				let curfile = substitute(curfile, '.*', s:search_directory.'\0', '')
				let bblfiles = bblfiles.'"'.curfile.'" '
			endif
			let i = i + 1
		endwhile

		return bblfiles

	else
		let bblfiles = ''
		let bblfiles2 = ''
		let curdir = expand("%:p:h")

		let bblfiles = glob(curdir.'/*.tex')
		let bblfiles = substitute(bblfiles, '\n', ' ', 'ge')

		if Tex_GetMainFileName() != ''
			let mainfname = Tex_GetMainFileName()
			let mainfdir = fnamemodify(mainfname, ":p:h")

			if mainfdir != curdir
				let bblfiles = glob(mainfdir.'/*.tex')
				let bblfiles = substitute(bblfiles, '\n', ' ', 'ge')
			endif

		endif

		return bblfiles.' '.bblfiles2
	endif

endfunction " }}}

" PromptForCompletion: prompts for a completion {{{
" Description: 
function! s:PromptForCompletion(texcommand,ask)

	let common_completion_prompt = 
				\ Tex_CreatePrompt(g:Tex_completion_{a:texcommand}, 2, ',') . "\n" .
				\ 'Enter number or completion: '

	let inp = input(a:ask."\n".common_completion_prompt)
	if inp =~ '^[0-9]\+$'
		let completion = Tex_Strntok(g:Tex_completion_{a:texcommand}, ',', inp)
	else
		let completion = inp
	endif

	return completion
endfunction " }}}
" Tex_DoCompletion: fast insertion of completion {{{
" Description:
"
function! s:Tex_DoCompletion(texcommand)
	let completion = <SID>PromptForCompletion(a:texcommand,'Choose a completion to insert: ')
	if completion != ''
		return completion
	else
		return ''
	endif
endfunction " }}}

" Tex_Common: common part of strings {{{
function! s:Tex_Common(path1, path2)
	" Assume the caller handles 'ignorecase'
	if a:path1 == a:path2
		return a:path1
	endif
	let n = 0
	while a:path1[n] == a:path2[n]
		let n = n+1
	endwhile
	return strpart(a:path1, 0, n)
endfunction " }}}
" Tex_RelPath: ultimate file name {{{
function! s:Tex_RelPath(explfilename,texfilename)
	let path1 = a:explfilename
	let path2 = a:texfilename
	if has("win32") || has("win16") || has("dos32") || has("dos16")
		let path1 = substitute(path1, '\\', '/', 'ge')
		let path2 = substitute(path2, '\\', '/', 'ge')
	endif
	let n = matchend(<SID>Tex_Common(path1, path2), '.*/')
	let path1 = strpart(path1, n)
	let path2 = strpart(path2, n)
	if path2 !~ '/'
		let subrelpath = ''
	else
		let subrelpath = substitute(path2, '[^/]\{-}/', '../', 'ge')
		let subrelpath = substitute(subrelpath, '[^/]*$', '', 'ge')
	endif
	let relpath = subrelpath.path1
	if has("win32") || has("win16") || has("dos32") || has("dos16")
		let relpath = substitute(relpath, '/', "\\", 'ge')
	endif
	return relpath
endfunction " }}}

let g:Tex_Completion = 1
" this statement has to be at the end.
let s:doneOnce = 1

" vim:fdm=marker:nowrap:noet:ff=unix:ts=4:sw=4
