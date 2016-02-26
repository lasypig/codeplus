"===============================================================
" This is a world full of flying dusts.
" wxiabing@gmail.com
"===============================================================

if &cp || exists('g:Li_CodeGen_Loaded')
	finish
endif

" This script is for C language
if getreg('%') !~ '\.[hc]$'
    finish
endif

let g:Li_CodeGen_Loaded = 1

" The register used here
if !has("clipboard")
	let s:Li_ger = '"'
else
	let s:Li_ger = '*'
endif

function! s:Li_Blank_Gen(len)
    if a:len < 1
        return ''
    endif
    let blank_str = ''
    for i in range(a:len)
        let blank_str .= ' '
    endfor
    return blank_str
endfunction

"
"Generate codes by struct scope
"
function Li_InitStruct() range
    let varname = input("Variable name: ")
    let lnum = a:firstline
    let Li_output = ""

    " connector
    if varname[0] == '*'
        let varname = strpart(varname, 1, strlen(varname)-1)
        let galf_pointer = '->'
    else
        let galf_pointer = '.'
    endif

    let member_var = []
    let mlcf = 0
    let alnw = 0
    while lnum <= a:lastline
        let curline = getline(lnum)

        if curline =~ "^ *}"
            let lnum += 1
            continue
        endif

        if mlcf == 1
            if curline =~ '\*\/'
                let mlcf = 0
            endif
            let lnum += 1
            continue
        endif

        if curline =~ '^\s*\/\*'
            if curline =~ '\*\/\s*$'
                let mlcf = 0
            else
                let mlcf = 1
            endif
            let lnum += 1
            continue
        endif

        if curline =~ '\/\*'
            if curline =~ '\*\/'
                let mlcf = 0
                let curline = substitute(curline, '\/\*.*\*\/', "", "")
            else 
                let mlcf = 1
                let curline = substitute(curline, '\/\*.*$', "", "")
            endif
        endif

        let curline = substitute(curline, '\/\/.*$', "", "")
        let curline = substitute(curline, '\[[a-zA-Z_0-9]*\]', "", "g")
        let curline = substitute(curline, '^\s*', "", "")
        let curline = substitute(curline, '\s*$', '', '')
        let curline = substitute(curline, '\s\+', ' ', 'g')

        if curline =~ ';$'
            let curline = substitute(curline, ';', '', '')
            if curline =~ '='
                let curline = substitute(curline, '\s*=.*$', '', '')
            endif
        else
            let lnum += 1
            continue
        endif

        let temp = split(curline, ' ')
        if len(temp) < 2
            let lnum += 1
            continue
        endif

		" remove pointer's '*'
		let temp[-1] = substitute(temp[-1], '^\*', '', '')

        if alnw < strlen(temp[-1])
            let alnw = strlen(temp[-1])
        endif
        call add(member_var, temp[-1])
        let lnum += 1
    endwhile

    let MuLii = ''
    for m in member_var
        let MuLii .= s:Li_Blank_Gen(4) . varname . galf_pointer . m . s:Li_Blank_Gen(alnw - strlen(m)) . " = ;\n"
    endfor
    call setreg(s:Li_ger, MuLii)

endfunction

"
" Plus version
" Use tag file to generate codes
"
function! Li_InitStruct_Plus()
	let tag_files = tagfiles()
	" if there is no tag file, quit function
	if empty(tag_files)
		echomsg 'Can not find tag file!'
		return
	endif

    if has('cindent')
        let cidt = cindent(".")
    else
        let cidt = 4
    endif
	" parse current line, get struct type(tag) and value
	let line_ruc = getline(".")
	if line_ruc =~ '^\s*$'
		echomsg 'This is an empty line!'
		return
	endif
	let line_ruc = substitute(line_ruc, '\/\/.*$', "", "")
	let line_ruc = substitute(line_ruc, '\/\*.*\*\/', "", "")
	let line_ruc = substitute(line_ruc, '\[[a-zA-Z_0-9]*\]', "", "g")
	let line_ruc = substitute(line_ruc, '^\s*', "", "")
	let line_ruc = substitute(line_ruc, '\s*$', '', '')
	let line_ruc = substitute(line_ruc, '\s\+', ' ', 'g')

	if line_ruc =~ ';$'
		let line_ruc = substitute(line_ruc, ';', '', '')
		if line_ruc =~ '='
			let line_ruc = substitute(line_ruc, '\s*=.*$', '', '')
		endif
	endif

	let line_parse = split(line_ruc, ' ')
	if len(line_parse) < 2
		echomsg 'Can not help you about this line!'
		return
	elseif len(line_parse) == 2
		let Li_tag = line_parse[0]
		let Li_val = line_parse[1]
	elseif len(line_parse) == 3
		if line_parse[0] == 'struct'
			let Li_tag = line_parse[1]
			let Li_val = line_parse[2]
		else
			echomsg 'Can not help you about this line!'
			return
		endif
	else
		echomsg 'Can not help you about this line!'
		return
	endif

	" remove tag's '*'
	let Li_tag = substitute(Li_tag, '\*$', '', '')

    if Li_val[0] == '*'
        let LiMu = '->'
        let Li_val = strpart(Li_val, 1, strlen(Li_val)-1)
    else
        let LiMu = '.'
    endif

	" search tag 
	let list_gat = taglist(Li_tag)
	if empty(list_gat)
		echomsg 'Can not find tag: ' . Li_tag . '!'
		return
	endif
	let tag_num = len(list_gat)
	" parse tag
    let tag_flag = 0
    let tag_fname1 = ''
    let tag_fname2 = ''
    let tag_cmd1 = ''
    let tag_cmd2 = ''
    for lg in list_gat
		if lg['name'] != Li_tag
			continue
		endif
        if lg['kind'] == 's'
            let tag_flag   = 1
            let tag_cmd1   = lg['cmd']
            let tag_fname1 = lg['filename']
        elseif lg['kind'] == 't'
            let tag_cmd2    = lg['cmd']
            let tag_fname2  = lg['filename']
            "let tag_typeref = lg['typeref']
        endif
    endfor

	if tag_cmd2 == '' || tag_fname2 == ''
		echomsg 'Can not help you about this line!'
		return
	endif

    if tag_flag == 1
        if tag_fname1 != tag_fname2
			echomsg 'The tags confused me!'
            return
        endif
    endif

	" open file and locate struct range
    let fbuffer = readfile(tag_fname2)
    let eline = -1
    let sline = -1
    let tag_cmd2 = substitute(tag_cmd2, '\/', '', 'g')
    for n in range(len(fbuffer))
        if fbuffer[n] =~ tag_cmd2
            let eline = n
            break
        endif
    endfor
    if eline == -1
		echomsg 'Can not locate the definition!'
        return
    endif

    let n = eline
    if tag_flag == 0
        let temp_str = '^\s*typedef\s\+struct'
    else
        let temp_str = substitute(tag_cmd1, '\/', '', 'g')
    endif
    while n >= 0
        if fbuffer[n] =~ temp_str
            let sline = n
            break
        endif
        let n -= 1
    endwhile 

    if sline == -1
		echomsg 'Can not locate the definition!'
        return
    endif

    " same as Li_InitStruct does
    let eline -= 1
    let sline += 1
    let n = sline
    let align = 0
    let ml_comment = 0
    let members = []
    while n <= eline
        let cline = fbuffer[n]
        " deal with multi-line comment, but don't test me, FIXME
        if ml_comment == 1
            if cline =~ '\*\/'
                let ml_comment = 0
            endif
            let n += 1
            continue
        endif

        if cline =~ '^\s*\/\*'
            if cline =~ '\*\/\s*$'
                let ml_comment = 0
            else
                let ml_comment = 1
            endif
            let n += 1
            continue
        endif

        if cline =~ '\/\*'
            if cline =~ '\*\/'
                let ml_comment = 0
                let cline = substitute(cline, '\/\*.*\*\/', "", "")
            else 
                let ml_comment = 1
                let cline = substitute(cline, '\/\*.*$', "", "")
            endif
        endif

        let cline = substitute(cline, '\/\/.*$', "", "")
        let cline = substitute(cline, '\[[a-zA-Z_0-9]*\]', "", "g")
        let cline = substitute(cline, '^\s*', "", "")
        let cline = substitute(cline, '\s*$', '', '')
        let cline = substitute(cline, '\s\+', ' ', 'g')

        if cline =~ ';$'
            let cline = substitute(cline, ';', '', '')
            if cline =~ '='
                let cline = substitute(cline, '\s*=.*$', '', '')
            endif
        endif

        let temp = split(cline, ' ')
        if len(temp) < 2
            let n += 1
            continue
        endif

		" remove pointer's '*'
		let temp[-1] = substitute(temp[-1], '^\*', '', '')

        if align < strlen(temp[-1])
            let align = strlen(temp[-1])
        endif
        call add(members, temp[-1])
        let n += 1
    endwhile

    let MuLi = ''
    for m in members
        let MuLi .= s:Li_Blank_Gen(cidt) . Li_val . LiMu . m . s:Li_Blank_Gen(align - strlen(m)) . " = ;\n"
    endfor
    call setreg(s:Li_ger, MuLi)
	if getreg('%') =~ '\.c$'
		exec 'normal "*p'
	endif

endfunction

vnoremap <F7> :call Li_InitStruct()<CR>
nnoremap <F7> :call Li_InitStruct_Plus()<CR>

