# CodePlus

> This a vim plugin to speed up coding with language C.

## How to install?

Copy codeplus.vim to your vim plugin directory:

`cp codeplus.vim ~/.vim/plugin`

## How to use?

Move your pointer to a line like this:

`struct rect_t rect;`

and press `<F7>`, I will generate some code like this for you:
```
	rect.left   = ;
	rect.top    = ;
	rect.right  = ;
	rect.bottom = ;
```
If I could do nothing for you, I will show message bellow.

## Notice

This plugin depends on tag files, run `ctags -R .` before using me.





