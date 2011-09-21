"=============================================================================
" Name: floodit.vim
" Author: taruta
" Email: taruta0811@gmail.com
" Version: 0.0.1

if exists('g:loaded_floodit_vim')
	finish
endif
let g:loaded_floodit_vim= 1

let s:save_cpo = &cpo
set cpo&vim
set maxfuncdepth=1000

" ----------------------------------------------------------------------------

let s:FloodIt = {
            \ 'board'  : [],
            \ 'checked' : [],
            \ 'width'  : 0,
            \ 'height' : 0,
            \ 'status' : 0,
            \ 'change_cell' : [],
            \ 'change_count' : 0,
            \ 'limit_count' : 0,
            \}

let s:rand_num = 1
function! s:rand()
	if has('reltime')
		let match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
		return reltimestr(reltime())[l:match_end : ]
	else
		" awful
		let s:rand_num += 1
		return s:rand_num
	endif
endfunction

" y行目x列目の文字をcに変更する
function! s:update(x, y, c)
    let s = getline(a:y)              
    let o = ''
    if a:x > 0                        
        let o .= s[:a:x-1]              
    elseif a:x < 0
        let o .= a:c[-a:x :]
    endif
    let o .= a:c
    let o .= s[a:x+(len(a:c)+1)-1:]
    call setline(a:y, o)
endfunction

function! s:FloodIt.run(width,height,limit)
    edit `='==FloodIt=='`
    let self.width = a:width
    let self.height = a:height
    let self.limit_count = a:limit

    call self.initialize_board()
    call self.draw()

    if has('conceal')
        syn match FloodItStatusBar contained '|' conceal
    else
        syn match FloodItStatusBar contained '|'
    endif

    syn match FloodItStatus '.*' contains=FloodItStatusBar
    syn match FloodItBlue    '0 '
    syn match FloodItRed     '1 '
    syn match FloodItGreen   '2 '
    syn match FloodItYellow  '3 '
    syn match FloodItMagenta '4 '
    syn match FloodItCyan    '5 '
	hi FloodItStatus  ctermfg=darkyellow guifg=darkyellow
    hi FloodItBlue    ctermbg=blue    ctermfg=blue guibg=blue    ctermfg=blue
    hi FloodItRed     ctermbg=red 	  ctermfg=red guibg=red     ctermfg=red
    hi FloodItGreen   ctermbg=DarkGreen   ctermfg=DarkGreen guibg=DarkGreen   ctermfg=DarkGreen
    hi FloodItYellow  ctermbg=yellow  ctermfg=yellow guibg=yellow  ctermfg=yellow
    hi FloodItMagenta ctermbg=magenta ctermfg=magenta guibg=magenta ctermfg=magenta
    hi FloodItCyan    ctermbg=cyan    ctermfg=cyan guibg=cyan    ctermfg=cyan

	nnoremap <silent> <buffer> w :call <SID>_change('0 ')<CR>
	nnoremap <silent> <buffer> e :call <SID>_change('1 ')<CR>
	nnoremap <silent> <buffer> r :call <SID>_change('2 ')<CR>
	nnoremap <silent> <buffer> t :call <SID>_change('3 ')<CR>
	nnoremap <silent> <buffer> y :call <SID>_change('4 ')<CR>
	nnoremap <silent> <buffer> u :call <SID>_change('5 ')<CR>
    nnoremap <silent> <buffer> x :call <SID>_change('x')<CR>
    nnoremap <silent> <buffer> h hh
    nnoremap <silent> <buffer> l ll

    setl conceallevel=2
    setl nonumber
    setl nomodified
    setl nomodifiable
    setl buftype=nowrite
    setl noswapfile
    setl bufhidden=wipe
    setl buftype=nofile
    setl nonumber
    setl nolist
    setl nowrap
    setl nocursorline
    setl nocursorcolumn

endfunction

function! s:FloodIt.change(color)
    if self.status!=0
        return
    endif

    let color=a:color
    let pos = getpos('.')
    if color == 'x'
        let c = matchstr(getline('.'),'.',col('.')-1)
        if c == ' '
            let c = matchstr(getline('.'),'.',col('.')-2)
        endif
        if c != '0' && str2nr(c) == 0
            return
        endif
        let color = c." "
    endif
    if self.board[0][0]==color
        return
    endif

    let self.checked=[]
    for y in range(self.height)
        call add(self.checked,[])
        for x in range(self.width)
            call add(self.checked[y],0)
        endfor
    endfor

    let self.change_count += 1
    let self.change_cell = [[0,0,color]]
    let self.checked[0][0]=1
    while self.change_cell != []
        call self.change_color()
    endwhile
    let flag = 0
    for y in range(self.height)
        for x in range(self.width)
            if self.board[y][x] != color
                let flag = -1
                break
            endif
        endfor
        if flag == -1
            break
        endif
    endfor
    if flag == 0
        let self.status=2
    elseif flag == -1 && self.change_count == self.limit_count
        let self.status=1
    endif
    call self.draw()
	call setpos('.',pos)
endfunction

function! s:FloodIt.change_color()
    let [x,y,color]=self.change_cell[0]    
    if len(self.change_cell)==1
        let self.change_cell=[]
    else
        let self.change_cell=self.change_cell[1:]
    endif
    let current=self.board[y][x]
    let self.board[y][x]=color
    for [dx,dy] in [[0,-1],[-1,0],[1,0],[0,1]]
        if x+dx < 0 || x+dx >= self.width || y+dy < 0 || y+dy >= self.height
            continue
        endif
        if self.board[y+dy][x+dx] == current && self.checked[y+dy][x+dx] == 0
            call add(self.change_cell,[x+dx,y+dy,color])
            let self.checked[y+dy][x+dx]=1
        endif
    endfor
endfunction

function! s:FloodIt.initialize_board()
    let self.status = 0
    let self.change_count=0
    let self.board = []
    for y in range(self.height)
        call add(self.board,[])
        for x in range(self.width)
            call add(self.board[y],'0 ')
        endfor
    endfor
    call s:FloodIt.shuffle()
endfunction

function! s:FloodIt.shuffle()
    for y in range(self.height)
        for x in range(self.width)
            let self.board[y][x] = string(s:rand()%6)." "
        endfor
    endfor

    while self.board[0][0] == self.board[0][1] || self.board[0][0] == self.board[1][0]
        let self.board[0][0]=string(s:rand()%6)." "
    endwhile
endfunction

function! s:FloodIt.draw()
    setl modifiable
    let status=['',"GameOver!!","Clear!!"]
    silent %d _

    let str=printf("| %2d/%2d %s |",
                \self.change_count,self.limit_count,status[self.status])
    call setline(1,str)

    for y in range(self.height)
        let str=join(self.board[y],'')
        call append(line('$'),str)
    endfor

    call append(line('$'),'')
    call append(line('$'),'w e r t y u ')
    call append(line('$'),'0 1 2 3 4 5 ')
    call append(line('$'),'')
    call append(line('$'),'x:カーソル下の色に変更')

    setl nomodified
    setl nomodifiable
endfunction

function! s:_floodit(...)
    if a:0 == 0
        call s:FloodIt.run(12,12,22)
    elseif a:1 == "small"
        call s:FloodIt.run(12,12,22)
    elseif a:1 == "middle"
        call s:FloodIt.run(17,17,30)
    elseif a:1 == "learge"
        call s:FloodIt.run(22,22,36)
    endif
endfunction

function! s:_change(color)
    call call(s:FloodIt.change,[a:color,],s:FloodIt)
endfunction


command! -nargs=* -complete=customlist,s:level FloodIt call s:_floodit(<f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo


