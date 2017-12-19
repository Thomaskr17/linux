"# ====================================================================== 
"#
"# VIM Key Info
"#
"# < Auto complete >
"#	입력모드에서 Ctrl+p or Ctrl+n
"#
"# < Undo >
"#	u	    : undo
"#	Ctrl+r	    : ReDo
"#
"# < input >
"#	a : after cursor,		    A : after line
"#	i : before cursor,		    I : before line
"#	o : below the cursor,		    O : above the cursor 
"#
"# < move > (커서 이동 명령)
"#	h : 왼쪽으로 커서 한 칸 이동,	    H : 화면의 처음으로 이동
"#	l : 오른쪽으로 한 칸 이동,	    L : 화면 끝으로 이동
"#	e : 다음 단어의 마지막으로 이동,    E : 커서를 공백으로 구분된 다음 단어 끝으로 이동
"#	b : 한 단어 뒤로,		    B : 커서를 공백으로 구분된 이전 단어로 이동
"#	w : 커서를 한 단어 뒤로,	    W : 커서를 공백으로 구분된 다음 단어로 이동
"#	k : 커서를 한 라인 위로,	    j : 커서를 한 라인 아래로 이동
"#	0 : 커서를 라인의 시작으로 이동,    $ : 커서를 라인의 끝으로 이동
"#
"#	Ctrl + f : 다음 화면으로 이동
"#	Ctrl + d : 화면의 반만 앞으로 이동
"#	Ctrl + b : 전 화면으로 이동
"#	Ctrl + u : 화면의 반만 뒤로 이동
"#
"#	G : 커서를 텍스트 마지막 라인으로.  숫자G : 커서를 숫자 라인만큼 이동
"#	M : 커서를 화면 중간 라인으로 이동
"#	( : 문장의 시작으로 이동	    ) : 문장 끝으로 이동하여 다음 단어의 시작으로 커서 이동
"#	{ : 문단의 시작으로 이동	    } : 문단 끝으로 이동 
"#	[[: 현재 함수의 처음으로 커서 이동  ]]: 다음 함수의 처음으로 커서 이동
"#
"#	% : { 에서 % 를 누르면 해당하는 } 로 이동한다.
"# 
"# < folding / unfolding >
"#	zf : 선택부분 접기
"#	zi : 접는기능 토글(누를 때마다 접기/펴기가 토글됨)
"#	zv : 커서 줄 보기
"#	zo : 부분 펴기 (open)
"#	zc : 부분 접기 (close)
"#	zM : 모두 접기
"#	zR : 모두 펴기
"#	zd : 접은 부분 삭제
"#
"# < delete >
"#	x  : 커서가 있는 문자 삭제	    X  : 커서가 있는 문자 앞에 있는 문자 삭제
"#	dw : 커서가 있는 단어 삭제	    dd : 커서가 있는 라인 삭제
"#
"# < copy >
"#	yy : 커서가 있는 라인을 복사, 커서가 가리키는 곳으로 라인을 이동
"#	y} : 문단의 나머지 복사
"#	yG : 파일의 나머지 복사
"#
"# < search >
"#	/pattern : 텍스트에서 앞으로 패턴 검색
"#	>pattern : 텍스트에서 뒤로 패턴 검색
"#	n : 앞 또는 뒤로 이전 검색 반복	    N : 반대 방향으로 이전 검색 반복
"#	/ : 전 검색을 앞으로 반복	    ? : 전 검색을 뒤로 반복
"#
"# < replace a character >
"#	r : 커서에 있는 문자 대치
"#	R : 입력 모드로 한 문자씩 덮어씀
"#
"# < replace string >
"#	:s/old/new : 현재 행의 처음 old를 new로 교체
"#	:s/old/new/g : 현재 행의 모든 old를 new로 교체
"#	:%s/old/new/gc : 문서전체(g)에서 old를 new로 확인(c)하며 교체
"#
"# < mark position >
"#	mx : 현재 위치를 x 이름의 마크로 저장
"#	`` : 이전에 마크한 위치로 이동
"#	`x : 마크한 위치(행, 열)로 이동
"#	'' : 이전에 마크한 줄로 이동
"#	'x : 마크한 줄로 이동
"#
"# < Window Split >
"#	:sp : 상하분할
"#	:vsp : 좌우분할
"#	Ctrl + w, [ H J K L ] : 커서창의 이동
"#	Ctrl + w, W : 커서 이동
"#	창 너비 변경 -> 화살표 키 맵핑 참조
"# < arrow key > 
	nmap <C-Left> <C-W><<C-W><
	nmap <C-Right> <C-W>><C-W>>
	nmap <C-Up> <C-W>-<C-W>-
	nmap <C-Down> <C-W>+<C-W>+
"#
"# < column mode >
"#	Ctrl+v > move down > Shift+i > type something > ESC > ESC
"#
"# < open file >
"#	:n
"#	:e#	<- open previous file
"#
"# < close all window >
"#	:qa
"#
"# < scroll up / down >
	nmap <C-J> <C-E>	// a line up
	nmap <C-K> <C-Y>	// a line down
"#
"# ====================================================================== 
"#
"# < MACRO >
"#
"#	1. q + a    (a키에 recording 시작)
"#	2. ~	    (반복할 작업)
"#	3. q	    (recoding 종료)
"#	4. @a	    (매크로 실행)
"#	5. 10@a	    (매크로 10회 실행)
"#
"#	Ctrl + a    -> 숫자에 포커스 있는 상태에서 누르면 숫자 증가함.
"#	Ctrl + x    -> 숫자 감소
"#	@@	    -> 마지막으로 실행한 매크로 재실행
"#
"#	let @q='~'  -> Ctrl + R > Ctrl + R > b
"#	:reg q	    -> you can see a recorded macro.
"#
"# ====================================================================== 
"
"# < Vundle >
	" git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

	set nocompatible		    " be iMproved, required (Vi 와의 호환성을 없애고, Vim 만의 기능을 쓸 수 있게 함) 
	filetype off			    " required (파일의 종류를 자동으로 인식X)
	
	
	set rtp+=~/.vim/bundle/Vundle.vim   " set the runtime path to include Vundle and initialize 
	call vundle#begin()		    " <<< BEGIN >>> 설치할 플러그인을 call vundle#begin()과 call vundle#end 사이에 작성한다. 
	" ---------------------------------------------------------------------	

	Plugin 'VundleVim/Vundle.vim'	    " Vundle 플러그인을 Vundle로 관리하기 위해 Plugin 'VundleVim/Vundle.vim을 작성한 것을 볼 수 있다.

	Plugin 'scrooloose/nerdtree'

	Plugin 'vim-airline/vim-airline'

	Plugin 'nanotech/jellybeans.vim' 

	Plugin 'kchmck/vim-coffee-script'

	" ---------------------------------------------------------------------	
	call vundle#end()		    " <<< ENG >>>
	filetype plugin indent on	    " required 

	" :PluginList       - lists configured plugins 
	" :PluginInstall    - 설정 파일에 작성한 플러그인들이 모두 설치된다 
	" :PluginSearch foo - searches for foo; append `!` to refresh local cache 
	" :PluginClean      - 플러그인을 삭제하려면 ~/.vimrc에서 삭제한 뒤에 Vim을 열어서 :PluginClean 명령을 실행하면 된다.
	" 
	" see :h vundle for more details or wiki for FAQ 
	" Put your non-Plugin stuff after this line
"#
"# ====================================================================== 
"#
"# < ctags >
"#
"#
"#	$ ctags -R	-> make tags
"#	:tj fnName	-> tags jump
"#	Ctrl + wf	-> 창이 수평 분할되어 헤더파일이 열립니다.
"#
"# ====================================================================== 
"#
"# < cscope >
"#
"#	지역변수나 전역변수가 사용된곳을 찾을 때 편리하다.
"#	우선 mkcscope.sh 파일을 만들어야 한다. 
"#	============ mkcscope.sh 파일 내용 ================
"#	#!/bin/sh
"#	rm -rf cscope.files cscope.files
"#	find . \( -name '*.c' -o -name '*.cpp' -o -name '*.cc' -o -name '*.h' -o -name '*.s' -o -name '*.S' \) -print > cscope.files
"#	cscope -i cscope.files
"#	============================================
"#	파일 생성 후 파일 퍼미션 설정
"#	$chmod 755 mkcscope.sh
"#	$mv mkcscope.sh /usr/bin
"#	디렉토리 이동 
"#	$cd ~/work/linux (심볼릭 링크 아닐시 전체 경로)
"#	mkcscope.sh 실행  하면 빌드 돼면서 데이터가 만들어 집니다 
"#	빌드 종료시 값을 입력 하는게 나오는데 Ctrl+d를 눌러서 종료 합니다.
"#	이후 .vimrc 파일에 다음 내용을 추가 합니다 
"#	=============================================
	set tags=./tags,~/work/linux/tags
	set csprg=/usr/bin/cscope
	set csto=0
	set cst
	set nocsverb
	if filereadable("./cscope.out") 
	    cs add ./cscope.out
	else
	    cs add ~/work/linux/cscope.out
	    cs add ~/work/Thomaskr17/OpenAvnu/cscope.out 
	endif
	set csverb
	
	"nmap <C-C>s :cs find s <C-R>=expand("<cword>")<CR><CR>
	"nmap <C-C>g :cs find g <C-R>=expand("<cword>")<CR><CR>
	"nmap <C-C>c :cs find c <C-R>=expand("<cword>")<CR><CR>
	"nmap <C-C>t :cs find t <C-R>=expand("<cword>")<CR><CR>
	"nmap <C-C>e :cs find e <C-R>=expand("<cword>")<CR><CR>
	"nmap <C-C>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
	"nmap <C-C>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
	"nmap <C-C>d :cs find d <C-R>=expand("<cword>")<CR><CR>
"#
"# ====================================================================== 
"#
"# < Taglist >
"#
"#	https://vim.sourceforge.io/scripts/script.php?script_id=273
"#	~/.vim/plugin/taglist.vim
"#	:Tlist	    <-- to show tag list window.
"#
	nmap <F9> :TlistToggle<CR>
	let Tlist_Ctags_Cmd = "/usr/bin/ctags"
	let Tlist_Inc_Winwidth = 0
	let Tlist_Exit_OnlyWindow = 0
	let Tlist_Auto_Open = 0
	let Tlist_Use_Right_Window = 1
"#
"# ====================================================================== 
"#
"# < color >
	color jellybeans
"#
"# ====================================================================== 
"#
"# nmap : display normal mode maps
"# imap : display insert mode maps
"# vmap : display visual and select mode maps
"# smap : display select mode maps
"# xmap : display visual mode maps
"# cmap : display command-line mode maps
"# omap : display operator pending mode maps
"#
"# < short key (hotkey) >
"#
	" <F3>
	nmap <F3> :NERDTreeToggle<CR>

	" <F5>
	map <F5> :call CompileGcc()

	func! CompileGcc()
	    exec "w" 
	    "silent make
	    ! gcc %
	endfunc 

	" <S-F5>
	map <S-F5> :call RunAOut() <CR>

	func! RunAOut()
	    !./a.out
	endfunc

""# Source Explorer
"       nmap <F8> :SrcExplToggle<CR>
"       let g:SrcExpl_winHeight = 8
"       let g:SrcExpl_refreshTime = 1000
"       let g:SrcExpl_jumpKey = "<ENTER>"
"       let g:SrcExpl_gobackKey = "<C-B>"
"       let g:SrcExpl_isUpdateTags = 0
"
"

	" <F9> tag list

	" <F12> make new comment (주석 단축키)
	nmap <F12> i<ESC>O<ESC>0i<CR><CR><UP>/-<BS>*<SPACE>Thomas: <C-R>=strftime("%x %T")<ESC><CR>------------------------------------<CR><CR>*/<UP><SPACE>
	imap <F12>  <ESC>O<ESC>0i<CR><CR><UP>/-<BS>*<SPACE>Thomas: <C-R>=strftime("%x %T")<ESC><CR>------------------------------------<CR><CR>*/<UP><SPACE>

	"# 괄호 자동 완성 후 입력모드로 전환
	map! () ()i
	map! (); ();hi
	map! [] []i
	map! {} {}i
	map! {}; {};iO
	map! <> <>i
	map! '' ''i
	map! "" ""i

	"# 
"	execute pathogen#infect()
"	syntax on		" 자동 문법 강조
"	filetype plugin on
"#
"# ====================================================================== 
"#
"# < macro > q + q (start), q (stop),  paste (Ctrl+R Ctrl+R b)
"#
   let @m='i#include <stdio.h>int main(int argc, char *argv[]) {}ko  '
"#
"# ====================================================================== 
"#
"# < settings >
"#
	set cindent			" C언어 자동 들여쓰기
	"set smartindent			" 자동 들여쓰기
	set background=dark
	set number			" (nu) 줄 번호를 나타나게 함
	set tabstop=8			" (ts) tag stop size 
	set hlsearch			" 검색시 하이라이트(색상강조)
	set showmatch			" 일치하는 괄호 하이라이팅
	set showcmd			" (부분적인)명령어를 상태라인에 보여줌
	"set scrolloff=2
	"set wildmode=longest,list
	"set sts=4			" st select
	"set sw=1			" 스크롤바 너비
	set autowrite			" :next나 :make 같은 명령를 입력하면 자동으로 저장
	"set autoread			" 작업 중인 파일 외부에서 변경됬을 경우 자동으로 불러옴
	set bs=eol,start,indent		" 백스페이스 사용
	set history=500
	set laststatus=2			" 상태바 표시 
	set paste			" 붙여넣기 계단현상 없애기
	set shiftwidth=4			" 자동 들여쓰기 너비 설정
	set smartcase			" 검색시 대소문자 구별
	set smarttab
	set softtabstop=4
	set ruler			" 현재 커서 위치 표시
	set incsearch
	set title			" 제목을 표시
	set visualbell			" (vb) 오류음 대신 비주얼벨 사용
	set statusline=\ %<%l:%v\ [%P]%=%a\ %h%m%r\ %F\ 
	set autoindent			" (ai) 자동 들여쓰기

	"# 마지막으로 수정된 곳에 커서를 위치함
	au BufReadPost * 
	    \ if line("'\"") > 0 && line("'\"") <= line("$") |
	    \ exe "norm g`\"" |
	    \ endif

	"# 파일 인코딩을 한국어로
	if $LANG[0]=='k' && $LANG[1]=='o'
	    set fileencoding=korea
	endif

	set guifont=Monaco:h10 noanti

"#
"# ====================================================================== 
"<EOF>
