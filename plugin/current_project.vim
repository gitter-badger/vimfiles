" file_path:h => project_info
let s:project_cache = {}
function! Vimrc_project_info(file_path) abort " {{{
	if a:file_path == ''
		return {
		\  'name': '',
		\  'main_name': '',
		\  'sub_name': '',
		\  'path': '',
		\  'main_path': '',
		\  'sub_path': '',
		\}
	endif
	if has_key(s:project_cache, a:file_path)
		return s:project_cache[a:file_path]
	endif
	let dir = fnamemodify(a:file_path, ':p:h')
	if has_key(s:project_cache, dir)
		let s:project_cache[a:file_path] = s:project_cache[dir]
		return s:project_cache[dir]
	endif
	let project_root = s:project_root(a:file_path)
	let sub_project_name = s:subproject_name(project_root, a:file_path)
	let main_project_name = fnamemodify(project_root, ':t')
	let name = main_project_name
	let path = project_root
	if !empty(sub_project_name)
		let name .= '/'.sub_project_name
		let path .= '/'.sub_project_name
	endif
	let info = {
	\  'name': name,
	\  'main_name': main_project_name,
	\  'sub_name': sub_project_name,
	\  'path': path,
	\  'main_path': project_root,
	\  'sub_path': path,
	\}
	let s:project_cache[dir] = info
	let s:project_cache[a:file_path] = info
	return info
endfunction " }}}

function! Vimrc_current_project_info() abort " {{{
	return Vimrc_project_info(expand('%:p'))
endfunction " }}}
function! s:current_project_dir() abort " {{{
	return Vimrc_project_info(expand('%')).main_path
endfunction " }}}

function! s:project_root(file_path) abort abort " {{{
	let project_marker_dirs = ['lib', 'ext', 'test', 'spec', 'bin', 'autoload', 'plugins', 'plugin', 'src']
	let project_replace_pattern = '\(.*\)/\('.join(project_marker_dirs,'\|').'\)\(/.\{-}\)\?$'
	let dir = fnamemodify(a:file_path, ':p:h')
	if exists('b:rails_root')
		return b:rails_root
	endif
	let git_project_dir = s:current_project_dir_by_git(dir)
	if !empty(git_project_dir)
		return git_project_dir
	elseif dir =~ '/projects/'
		return substitute(dir, '\v(.*\/projects\/[-_a-zA-Z0-9])\/.*', '\1', '')
	elseif dir =~ project_replace_pattern && dir !~ '/usr/.*'
		return substitute(dir, project_replace_pattern, '\1', '')
	endif
	return ''
endfunction " }}}

function! s:subproject_name(root, path) abort abort " {{{
	let project_marker_dirs = ['lib', 'ext', 'test', 'spec', 'bin', 'autoload', 'plugins', 'plugin', 'src']
	let name = matchstr(fnamemodify(a:path, ':p'), '^'.a:root.'/\zs[^/]\+\ze/.*')
	if name != -1 && !empty(name) && index(project_marker_dirs, name) == -1
		for suffix in project_marker_dirs
			if getftype(a:root.'/'.name.'/'.suffix) == 'dir'
				return name
			endif
		endfor
	endif
	return ''
endfunction " }}}

function! s:current_project_dir_by_git(dir) abort " {{{
	let i = 0
	let d = a:dir
	while i < 10
		if d == '/'
			return ''
		endif
		if !empty(globpath(d, '/.git'))
			return d
		endif
		let d = fnamemodify(d, ':h')
		let i += 1
	endwhile
	return ''
endfunction " }}}

" e-in-current-project
command! -complete=customlist,Vimrc_complete_current_project_files -nargs=1 Pe :exec ':e '.<SID>current_project_dir().'/'."<args>"
function! Vimrc_complete_current_project_files(ArgLead, CmdLine, CursorPos) abort " {{{
	let prefix = s:current_project_dir() . '/'
	if prefix == '/'
		return []
	endif
	let candidates = glob(prefix.a:ArgLead.'*', 1, 1)
	let result = []
	for c in candidates
		if isdirectory(c)
			call add(result, substitute(c, prefix, '', '').'/')
		else
			call add(result, substitute(c, prefix, '', ''))
		endif
	endfor
	return result
endfunction " }}}
